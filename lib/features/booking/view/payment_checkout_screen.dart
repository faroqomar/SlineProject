import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/config/payment_runtime_config.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_pending_store.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/booking/models/payment_return_args.dart';
import 'package:sline_app/features/booking/view/payment_webview_screen.dart';
import 'package:sline_app/features/booking/view/widgets/payment_order_summary_card.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// Payment Checkout Screen — direct booking purchase without slot selection.
class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({
    super.key,
    required this.providerId,
    required this.taskId,
    required this.taskTitle,
    required this.price,
    this.packageTier,
    this.packageData,
    this.deliveryDays,
    this.taskDeadline,
  });

  final String providerId;
  final String taskId;
  final String taskTitle;
  final double price;
  final String? packageTier;
  final Map<String, dynamic>? packageData;
  final int? deliveryDays;
  final DateTime? taskDeadline;

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  /// Delays unpaid draft cleanup so backend payment creation, callbacks, and
  /// reconciliation have time to settle before the UI asks to delete a draft.
  /// The 30-minute window also prevents repeated cleanup attempts during
  /// short-lived user interactions such as returning from the gateway.
  static const Duration _draftCleanupDelay = Duration(minutes: 30);

  final _cardNumberCtrl = TextEditingController(text: '4242 4242 4242 4242');
  final _expiryCtrl = TextEditingController(text: '12/28');
  final _cvvCtrl = TextEditingController(text: '123');
  final _nameCtrl = TextEditingController(text: 'Test User');
  final _noteCtrl = TextEditingController();

  bool _processing = false;
  String? _error;
  bool _paymentSuccess = false;
  bool _awaitingGatewayConfirmation = false;
  bool _paymentFlowInProgress = false;
  String? _draftBookingId;
  BookingViewModel? _vm;
  Timer? _orphanDraftTimer;

  String get _runtimeFinishUrl => buildQiCardFinishUrlForRuntime();

  Set<String> get _callbackHosts =>
      buildQiCardCallbackHosts(finishUrl: _runtimeFinishUrl);

  DateTime? get _estimatedDueAt {
    if (widget.deliveryDays != null) {
      return DateTime.now().toUtc().add(Duration(days: widget.deliveryDays!));
    }
    return widget.taskDeadline?.toUtc();
  }

  String? get _trimmedNote {
    final note = _noteCtrl.text.trim();
    return note.isEmpty ? null : note;
  }

  @override
  void dispose() {
    _orphanDraftTimer?.cancel();
    final draftBookingId = _draftBookingId;
    if (!_paymentSuccess &&
        !_paymentFlowInProgress &&
        !_awaitingGatewayConfirmation &&
        draftBookingId != null &&
        _vm != null) {
      AppLogger.i(
        'Checkout screen disposed with unpaid draft; attempting cleanup',
        tag: 'Payment',
      );
      unawaited(_vm!.cancelBookingDraftIfUnpaid(draftBookingId));
    }
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelDraftIfPossible(String bookingId) async {
    _orphanDraftTimer?.cancel();
    _orphanDraftTimer = null;
    AppLogger.i('Attempting to cancel unpaid booking draft', tag: 'Payment');
    final vm = context.read<BookingViewModel>();
    _vm = vm;
    await vm.cancelBookingDraftIfUnpaid(bookingId);
  }

  Future<void> _launchWebPaymentFlow({
    required Uri paymentUri,
    required QiCardCreatePaymentResult createResult,
  }) async {
    final pendingStore = context.read<PaymentPendingStore>();
    await pendingStore.save(
      PendingPaymentContext(
        bookingId: createResult.bookingId!,
        correlationId: createResult.correlationId,
        provider: 'qicard',
        startedAt: DateTime.now().toUtc(),
        entityType: 'booking',
        callbackHosts: _callbackHosts,
        returnUrl: _runtimeFinishUrl,
      ),
    );

    AppLogger.i(
      'Redirecting booking payment in same browser tab',
      tag: 'Payment',
      json: <String, dynamic>{
        'provider': 'qicard',
        'callback_host_count': _callbackHosts.length,
        'has_correlation': createResult.correlationId != null,
      },
    );

    final launched = await launchUrl(paymentUri, webOnlyWindowName: '_self');
    if (launched) {
      return;
    }

    await pendingStore.clear();
    await _cancelDraftIfPossible(createResult.bookingId!);
    if (!mounted) return;
    setState(() {
      _error = 'Failed to open the payment provider.';
      _processing = false;
      _awaitingGatewayConfirmation = false;
      _paymentFlowInProgress = false;
    });
  }

  Future<void> _handlePaymentReturn({
    required BookingViewModel vm,
    required String bookingId,
    required PaymentReturnArgs? paymentReturn,
  }) async {
    final resultStatus = paymentReturn?.normalizedStatus ?? 'CANCELED';
    if (paymentReturn == null || paymentReturn.isFailure) {
      AppLogger.w(
        'Payment return was not successful',
        tag: 'Payment',
        error: resultStatus,
      );
      await _cancelDraftIfPossible(bookingId);
      if (!mounted) return;
      setState(() {
        _error = 'Payment was not completed. Please try again.';
        _processing = false;
        _awaitingGatewayConfirmation = false;
        _paymentFlowInProgress = false;
      });
      return;
    }

    AppLogger.i(
      'QiCard payment return received',
      tag: 'Payment',
      json: <String, dynamic>{
        'status': resultStatus,
        'has_payment_reference': paymentReturn.paymentId != null,
        'has_correlation': paymentReturn.correlationId != null,
      },
    );

    final recovery = await vm.recoverBookingPaymentWithRetries(
      bookingId: bookingId,
    );
    if (!mounted) return;

    if (!recovery.isSuccess) {
      AppLogger.w(
        'Booking recovery failed after gateway return',
        tag: 'Payment',
        error: recovery.error ?? 'BOOKING_PAYMENT_RECOVERY_FAILED',
      );
      setState(() {
        _error =
            recovery.error ??
            'Payment return was received, but booking recovery failed.';
        _processing = false;
        _awaitingGatewayConfirmation = false;
        _paymentFlowInProgress = false;
      });
      return;
    }

    if (recovery.paymentStatus == 'held') {
      AppLogger.i(
        'Checkout success: booking confirmed and funds held',
        tag: 'Payment',
        json: {'provider': 'qicard', 'payment_status': recovery.paymentStatus},
      );
      _orphanDraftTimer?.cancel();
      _orphanDraftTimer = null;
      await _clearPendingAndRefreshBookingLists(
        vm: vm,
        pendingStore: context.read<PaymentPendingStore>(),
        bookingId: bookingId,
      );
      if (!mounted) return;
      setState(() {
        _processing = false;
        _awaitingGatewayConfirmation = false;
        _paymentSuccess = true;
        _paymentFlowInProgress = false;
      });
      await Future<void>.delayed(AppMotion.dramatic);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    AppLogger.w(
      'Booking recovery returned a non-held status',
      tag: 'Payment',
      error: recovery.paymentStatus ?? 'UNKNOWN_PAYMENT_STATUS',
    );
    setState(() {
      _error =
          recovery.error ??
          'Payment recovery completed but payment status is not held. Please contact support.';
      _processing = false;
      _awaitingGatewayConfirmation = false;
      _paymentFlowInProgress = false;
    });
  }

  Future<void> _clearPendingAndRefreshBookingLists({
    required BookingViewModel vm,
    required PaymentPendingStore pendingStore,
    required String bookingId,
  }) async {
    AppLogger.i(
      'Clearing pending booking payment and refreshing booking lists',
      tag: 'Payment',
      json: <String, dynamic>{'has_booking': bookingId.isNotEmpty},
    );
    await pendingStore.clear();
    await vm.loadBookingsAsClient();
    await vm.loadBookingsAsProvider();
    AppLogger.i(
      'Booking lists refreshed after held payment recovery',
      tag: 'Payment',
      json: <String, dynamic>{'has_booking': bookingId.isNotEmpty},
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _processing = true;
      _error = null;
      _paymentFlowInProgress = true;
    });

    final vm = context.read<BookingViewModel>();
    AppLogger.i(
      'Starting booking checkout',
      tag: 'Payment',
      json: <String, dynamic>{
        'has_package': widget.packageTier != null,
        'delivery_days': widget.deliveryDays,
        'has_note': _trimmedNote != null,
      },
    );

    try {
      final createResult = await vm.createPaymentForBooking(
        taskId: widget.taskId,
        note: _trimmedNote,
        packageId: widget.packageTier,
        requirements: widget.packageData,
        finishUrl: _runtimeFinishUrl,
      );

      if (!createResult.isSuccess || createResult.bookingId == null) {
        AppLogger.w(
          'Booking payment draft creation failed',
          tag: 'Payment',
          error:
              createResult.error ??
              vm.bookingsError ??
              'BOOKING_PAYMENT_CREATE_FAILED',
          json: <String, dynamic>{
            'has_request_correlation':
                createResult.requestCorrelationId != null,
          },
        );
        if (createResult.bookingId != null) {
          await _cancelDraftIfPossible(createResult.bookingId!);
        }
        if (!mounted) return;
        setState(() {
          _error =
              createResult.error ??
              vm.bookingsError ??
              'Failed to create booking payment.';
          _processing = false;
          _paymentFlowInProgress = false;
        });
        return;
      }

      _draftBookingId = createResult.bookingId;
      _orphanDraftTimer?.cancel();
      _orphanDraftTimer = Timer(_draftCleanupDelay, () {
        if (!mounted) return;
        unawaited(_cancelDraftIfPossible(createResult.bookingId!));
      });

      if (createResult.formUrl != null) {
        final uri = Uri.tryParse(createResult.formUrl!);
        if (uri == null) {
          AppLogger.w(
            'Booking payment provider returned an invalid URL',
            tag: 'Payment',
            error: 'INVALID_PAYMENT_URL',
          );
          await _cancelDraftIfPossible(createResult.bookingId!);
          setState(() {
            _error = 'Payment provider returned an invalid URL.';
            _processing = false;
            _paymentFlowInProgress = false;
          });
          return;
        }
        AppLogger.i(
          kIsWeb ? 'Opening browser payment flow' : 'Opening payment webview',
          tag: 'Payment',
          json: <String, dynamic>{
            'provider': 'qicard',
            'callback_host_count': _callbackHosts.length,
            'has_correlation': createResult.correlationId != null,
            'has_request_correlation':
                createResult.requestCorrelationId != null,
          },
        );
        setState(() {
          _awaitingGatewayConfirmation = true;
        });

        final paymentIntentStatusStream = createResult.intentId == null
            ? null
            : vm.streamPaymentIntentStatus(createResult.intentId!);
        if (createResult.intentId != null) {
          AppLogger.i(
            'Wiring booking payment webview to realtime intent status',
            tag: 'Payment',
            json: <String, dynamic>{
              'has_intent': true,
              'has_booking': createResult.bookingId != null,
            },
          );
        }

        if (kIsWeb) {
          await _launchWebPaymentFlow(
            paymentUri: uri,
            createResult: createResult,
          );
          return;
        }

        if (!mounted) return;
        final paymentReturn = await Navigator.of(context)
            .push<PaymentReturnArgs>(
              MaterialPageRoute(
                builder: (_) => PaymentWebViewScreen(
                  initialUrl: uri.toString(),
                  callbackHosts: _callbackHosts,
                  expectedBookingId: createResult.bookingId,
                  expectedCorrelationId: createResult.correlationId,
                  paymentIntentId: createResult.intentId,
                  paymentIntentStatusStream: paymentIntentStatusStream,
                ),
              ),
            );
        await _handlePaymentReturn(
          vm: vm,
          bookingId: createResult.bookingId!,
          paymentReturn: paymentReturn,
        );
        return;
      }

      AppLogger.w(
        'Booking payment draft was created without a form URL',
        tag: 'Payment',
      );
      await _cancelDraftIfPossible(createResult.bookingId!);
      setState(() {
        _error = 'Payment could not be started. Please try again.';
        _processing = false;
        _paymentFlowInProgress = false;
      });
    } on Exception catch (e, st) {
      AppLogger.e(
        'Payment flow failed',
        tag: 'Payment',
        error: '${e.runtimeType}: $e',
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _error = vm.bookingsError ?? 'Payment failed. Please try again.';
        _processing = false;
        _awaitingGatewayConfirmation = false;
        _paymentFlowInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    const amber = AmberDuskTokens.colors;

    return Scaffold(
      backgroundColor: amber.page,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AmberDuskColors.transparent,
        elevation: 0,
        foregroundColor: amber.text,
      ),
      body: ColoredBox(
        color: amber.page,
        child: SafeArea(
          child: SizedBox.expand(
            child: _paymentSuccess ? _buildSuccess() : _buildForm(cs),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    const amber = AmberDuskTokens.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppDimens.p80,
            height: AppDimens.p80,
            decoration: BoxDecoration(
              color: amber.successMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: amber.success,
              size: AppDimens.p48,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Text(
            'Payment Successful!',
            style: AppTypography.h2.copyWith(color: amber.text),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            'Your booking has been created.',
            style: AppTypography.bodyMedium.copyWith(color: amber.textSubtle),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AppColorScheme cs) {
    final vm = context.read<BookingViewModel>();
    final isDemoMode = vm.isDemoPaymentMode;
    final estimatedDueAt = _estimatedDueAt;
    const amber = AmberDuskTokens.colors;
    final buttons = AmberDuskTokens.widgetTheme.buttons;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PaymentOrderSummaryCard(
            taskTitle: widget.taskTitle,
            price: widget.price,
            cs: cs,
            packageTier: widget.packageTier,
            deliveryDays: widget.deliveryDays,
            estimatedDueAt: estimatedDueAt,
          ),

          const SizedBox(height: AppDimens.p20),

          Text(
            'Booking Note',
            style: AppTypography.h4.copyWith(color: amber.text),
          ),
          const SizedBox(height: AppDimens.p8),
          TextField(
            controller: _noteCtrl,
            maxLines: 4,
            minLines: 3,
            cursorColor: amber.primary,
            style: AppTypography.bodyMedium.copyWith(color: amber.text),
            decoration: InputDecoration(
              hintText: 'Add requirements or extra details for the provider',
              hintStyle: AppTypography.bodyMedium.copyWith(color: amber.muted),
              filled: true,
              fillColor: amber.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.r12),
                borderSide: BorderSide(color: amber.surfaceHighest),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.r12),
                borderSide: BorderSide(color: amber.surfaceHighest),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.r12),
                borderSide: BorderSide(
                  color: amber.primary,
                  width: AmberDuskTokens.spacing.borderWidthStrong,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppDimens.p24),

          Text(
            'Payment Details',
            style: AppTypography.h4.copyWith(color: amber.text),
          ),
          const SizedBox(height: AppDimens.p4),
          if (isDemoMode) ...[
            Text(
              'Demo mode — local test card fields are enabled',
              style: AppTypography.bodySmall.copyWith(
                color: amber.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppDimens.p16),
            _buildCardField(
              controller: _cardNumberCtrl,
              label: 'Card Number',
              icon: Icons.credit_card_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                LengthLimitingTextInputFormatter(19),
              ],
            ),
            const SizedBox(height: AppDimens.p12),
            _buildCardField(
              controller: _nameCtrl,
              label: 'Cardholder Name',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: AppDimens.p12),
            Row(
              children: [
                Expanded(
                  child: _buildCardField(
                    controller: _expiryCtrl,
                    label: 'Expiry',
                    icon: Icons.calendar_today_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                      LengthLimitingTextInputFormatter(5),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Expanded(
                  child: _buildCardField(
                    controller: _cvvCtrl,
                    label: 'CVV',
                    icon: Icons.lock_outline_rounded,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.p12),
              decoration: BoxDecoration(
                color: amber.infoMuted,
                borderRadius: BorderRadius.circular(AppDimens.r12),
                border: Border.all(color: amber.surfaceHighest),
              ),
              child: Text(
                'QiCard mode is active. After tapping Pay, you will complete card validation securely on the QiCard payment page.',
                style: AppTypography.bodySmall.copyWith(
                  color: amber.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppDimens.p16),
            Container(
              padding: const EdgeInsets.all(AppDimens.p12),
              decoration: BoxDecoration(
                color: amber.dangerMuted,
                borderRadius: BorderRadius.circular(AppDimens.r12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: amber.danger,
                    size: AppDimens.iconSmall,
                  ),
                  const SizedBox(width: AppDimens.p8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: amber.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_awaitingGatewayConfirmation) ...[
            const SizedBox(height: AppDimens.p12),
            Text(
              'Waiting for payment confirmation from gateway...',
              style: AppTypography.bodySmall.copyWith(
                color: amber.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppDimens.p24),
          SizedBox(
            width: double.infinity,
            height: AppDimens.p52,
            child: FilledButton(
              onPressed: _processing ? null : _processPayment,
              style: FilledButton.styleFrom(
                backgroundColor: amber.primary,
                disabledBackgroundColor: amber.primary.withValues(alpha: 0.5),
                foregroundColor: amber.textInverse,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                ),
              ),
              child: _processing
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: AppDimens.p20,
                          height: AppDimens.p20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: amber.textInverse,
                          ),
                        ),
                        const SizedBox(width: AppDimens.p12),
                        Text(
                          _awaitingGatewayConfirmation
                              ? 'Waiting for confirmation...'
                              : 'Processing Payment...',
                          style: buttons.textStyle.copyWith(
                            color: amber.textInverse,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Pay ${PriceFormatter.formatPrice(widget.price)}',
                      style: buttons.textStyle.copyWith(
                        color: amber.textInverse,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppDimens.p12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: AppDimens.iconSizeSmall,
                  color: amber.muted,
                ),
                const SizedBox(width: AppDimens.p4),
                Text(
                  'Secured payment · Funds held in escrow',
                  style: AppTypography.bodySmall.copyWith(color: amber.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
  }) {
    const amber = AmberDuskTokens.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      cursorColor: amber.primary,
      style: AppTypography.bodyMedium.copyWith(color: amber.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall.copyWith(color: amber.muted),
        prefixIcon: Icon(icon, color: amber.muted, size: AppDimens.iconSmall),
        filled: true,
        fillColor: amber.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          borderSide: BorderSide(color: amber.surfaceHighest),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          borderSide: BorderSide(color: amber.surfaceHighest),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          borderSide: BorderSide(
            color: amber.primary,
            width: AmberDuskTokens.spacing.borderWidthStrong,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p16,
          vertical: AppDimens.p14,
        ),
      ),
    );
  }
}
