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
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/booking/models/payment_return_args.dart';
import 'package:sline_app/features/booking/view/payment_webview_screen.dart';
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
  StreamSubscription<String>? _intentSubscription;

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
    _intentSubscription?.cancel();
    _orphanDraftTimer?.cancel();
    final draftBookingId = _draftBookingId;
    if (!_paymentSuccess &&
        !_paymentFlowInProgress &&
        !_awaitingGatewayConfirmation &&
        draftBookingId != null &&
        _vm != null) {
      AppLogger.i(
        'Checkout screen disposed with unpaid draft booking=$draftBookingId; attempting cleanup',
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
    _intentSubscription?.cancel();
    AppLogger.i(
      'Attempting to cancel unpaid booking draft booking=$bookingId',
      tag: 'Payment',
    );
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
      'Redirecting payment in same browser tab for booking=${createResult.bookingId}',
      tag: 'Payment',
      json: <String, dynamic>{
        'booking_id': createResult.bookingId,
        'correlation_id': createResult.correlationId,
        'finish_url': _runtimeFinishUrl,
        'callback_hosts': _callbackHosts.toList(),
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
        'Payment return was not successful for booking=$bookingId',
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
      'QiCard payment return received booking=$bookingId '
      'paymentId=${paymentReturn.paymentId} '
      'correlation=${paymentReturn.correlationId} '
      'status=$resultStatus',
      tag: 'Payment',
    );

    final recovery = await vm.recoverBookingPaymentWithRetries(
      bookingId: bookingId,
    );
    if (!mounted) return;

    if (!recovery.isSuccess) {
      AppLogger.w(
        'Booking recovery failed after gateway return for booking=$bookingId',
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
        'Checkout Success: Booking confirmed and funds held for booking=$bookingId',
        tag: 'Payment',
        json: {
          'booking_id': bookingId,
          'task_id': widget.taskId,
          'amount': widget.price,
        },
      );
      _orphanDraftTimer?.cancel();
      _orphanDraftTimer = null;
      setState(() {
        _processing = false;
        _awaitingGatewayConfirmation = false;
        _paymentSuccess = true;
        _paymentFlowInProgress = false;
      });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    AppLogger.w(
      'Booking recovery returned a non-held status for booking=$bookingId',
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

  Future<void> _processPayment() async {
    setState(() {
      _processing = true;
      _error = null;
      _paymentFlowInProgress = true;
    });

    final vm = context.read<BookingViewModel>();
    AppLogger.i(
      'Starting booking checkout task=${widget.taskId} package=${widget.packageTier ?? 'none'}',
      tag: 'Payment',
      json: <String, dynamic>{
        'task_id': widget.taskId,
        'provider_id': widget.providerId,
        'package_id': widget.packageTier,
        'delivery_days': widget.deliveryDays,
        'task_deadline': widget.taskDeadline?.toUtc().toIso8601String(),
        'finish_url': _runtimeFinishUrl,
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
          'Booking payment draft creation failed for task=${widget.taskId}',
          tag: 'Payment',
          error:
              createResult.error ??
              vm.bookingsError ??
              'BOOKING_PAYMENT_CREATE_FAILED',
          json: <String, dynamic>{
            'task_id': widget.taskId,
            'request_correlation_id': createResult.requestCorrelationId,
          },
        );
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
      _orphanDraftTimer = Timer(const Duration(minutes: 30), () {
        if (!mounted) return;
        unawaited(_cancelDraftIfPossible(createResult.bookingId!));
      });

      if (createResult.formUrl != null) {
        if (createResult.intentId != null) {
          _intentSubscription?.cancel();
          _intentSubscription = vm
              .streamPaymentIntentStatus(createResult.intentId!)
              .listen((status) {
                if (_paymentSuccess) return;
                AppLogger.i(
                  'Payment intent realtime status updated: $status',
                  tag: 'Payment',
                );
                if (status == 'succeeded' || status == 'failed') {
                  _intentSubscription?.cancel();
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop(
                      PaymentReturnArgs(
                        paymentId: null,
                        correlationId: createResult.correlationId,
                        status: status == 'succeeded' ? 'SUCCESS' : 'FAILED',
                        rawUri: Uri.parse(
                          'sline://payment_sync?status=$status',
                        ),
                      ),
                    );
                  }
                }
              });
        }

        final uri = Uri.tryParse(createResult.formUrl!);
        if (uri == null) {
          AppLogger.w(
            'Booking payment provider returned an invalid URL for booking=${createResult.bookingId}',
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
          kIsWeb
              ? 'Opening browser payment flow for booking=${createResult.bookingId}'
              : 'Opening payment webview for booking=${createResult.bookingId}',
          tag: 'Payment',
          json: <String, dynamic>{
            'booking_id': createResult.bookingId,
            'correlation_id': createResult.correlationId,
            'request_correlation_id': createResult.requestCorrelationId,
            'finish_url': _runtimeFinishUrl,
            'callback_hosts': _callbackHosts.toList(),
          },
        );
        setState(() {
          _awaitingGatewayConfirmation = true;
        });

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
        'Booking payment draft was created without a form URL for booking=${createResult.bookingId}',
        tag: 'Payment',
      );
      await _cancelDraftIfPossible(createResult.bookingId!);
      setState(() {
        _error = 'Payment could not be started. Please try again.';
        _processing = false;
        _paymentFlowInProgress = false;
      });
    } catch (e) {
      AppLogger.e('Payment flow failed', error: e, tag: 'Payment');
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

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.text,
      ),
      body: SafeArea(
        child: _paymentSuccess ? _buildSuccess(cs) : _buildForm(cs),
      ),
    );
  }

  Widget _buildSuccess(AppColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.teal,
              size: 48,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Text(
            'Payment Successful!',
            style: AppTypography.h2.copyWith(color: cs.text),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            'Your booking has been created.',
            style: AppTypography.bodyMedium.copyWith(color: cs.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AppColorScheme cs) {
    final vm = context.read<BookingViewModel>();
    final isDemoMode = vm.paymentServiceType == 'DemoPaymentService';
    final estimatedDueAt = _estimatedDueAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.p16),
            decoration: BoxDecoration(
              color: cs.cardBackground,
              borderRadius: BorderRadius.circular(AppDimens.r16),
              border: Border.all(color: cs.text.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary',
                  style: AppTypography.h4.copyWith(color: cs.text),
                ),
                const SizedBox(height: AppDimens.p12),
                _summaryRow('Service', widget.taskTitle, cs),
                if (widget.packageTier != null) ...[
                  const SizedBox(height: AppDimens.p8),
                  _summaryRow('Package', widget.packageTier!, cs),
                ],
                if (widget.deliveryDays != null) ...[
                  const SizedBox(height: AppDimens.p8),
                  _summaryRow('Delivery', '${widget.deliveryDays} days', cs),
                ],
                if (estimatedDueAt != null) ...[
                  const SizedBox(height: AppDimens.p8),
                  _summaryRow('Due', formatUtcToLocal(estimatedDueAt), cs),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppTypography.h3.copyWith(color: cs.text),
                    ),
                    Text(
                      PriceFormatter.formatPrice(widget.price),
                      style: AppTypography.h3.copyWith(
                        color: AppColors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.p20),

          Text(
            'Booking Note',
            style: AppTypography.h4.copyWith(color: cs.text),
          ),
          const SizedBox(height: AppDimens.p8),
          TextField(
            controller: _noteCtrl,
            maxLines: 4,
            minLines: 3,
            style: TextStyle(color: cs.text),
            decoration: InputDecoration(
              hintText: 'Add requirements or extra details for the provider',
              hintStyle: TextStyle(color: cs.textSecondary),
              filled: true,
              fillColor: cs.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.r12),
                borderSide: BorderSide(color: cs.text.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.r12),
                borderSide: BorderSide(color: cs.text.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.r12),
                borderSide: BorderSide(color: AppColors.teal, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: AppDimens.p24),

          Text(
            'Payment Details',
            style: AppTypography.h4.copyWith(color: cs.text),
          ),
          const SizedBox(height: AppDimens.p4),
          if (isDemoMode) ...[
            Text(
              'Demo mode — local test card fields are enabled',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gold,
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
              cs: cs,
            ),
            const SizedBox(height: AppDimens.p12),
            _buildCardField(
              controller: _nameCtrl,
              label: 'Cardholder Name',
              icon: Icons.person_outline_rounded,
              cs: cs,
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
                    cs: cs,
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
                    cs: cs,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.p12),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.r12),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'QiCard mode is active. After tapping Pay, you will complete card validation securely on the QiCard payment page.',
                style: AppTypography.bodySmall.copyWith(
                  color: cs.text,
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
                color: AppColors.lightRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.r12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.lightRed,
                    size: 20,
                  ),
                  const SizedBox(width: AppDimens.p8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.lightRed,
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
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppDimens.p24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _processing ? null : _processPayment,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                ),
              ),
              child: _processing
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _awaitingGatewayConfirmation
                              ? 'Waiting for confirmation...'
                              : 'Processing Payment...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Pay ${PriceFormatter.formatPrice(widget.price)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppDimens.p12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: cs.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Secured payment · Funds held in escrow',
                  style: AppTypography.bodySmall.copyWith(
                    color: cs.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, AppColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: cs.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: cs.text,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildCardField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppColorScheme cs,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      style: TextStyle(color: cs.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.textSecondary),
        prefixIcon: Icon(icon, color: cs.textSecondary, size: 20),
        filled: true,
        fillColor: cs.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          borderSide: BorderSide(color: cs.text.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          borderSide: BorderSide(color: cs.text.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          borderSide: BorderSide(color: AppColors.teal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p16,
          vertical: AppDimens.p14,
        ),
      ),
    );
  }
}
