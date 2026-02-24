import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/booking/view/payment_webview_screen.dart';
import '../viewmodels/booking_view_model.dart';

/// Payment Checkout Screen — appears after user selects a slot.
///
/// Shows booking summary + test card form. On "Pay Now":
/// 1. Processes payment via DemoPaymentService (2s simulated delay)
/// 2. Creates booking with pending status
/// 3. Calls escrowHoldBooking to lock funds in ledger
/// 4. Returns success/failure to caller
class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({
    super.key,
    required this.slotId,
    required this.providerId,
    required this.taskId,
    required this.startUtc,
    required this.endUtc,
    required this.price,
    this.note,
    this.packageTier,
    this.packagePrice,
    this.packageData,
  });

  final String slotId;
  final String providerId;
  final String taskId;
  final DateTime startUtc;
  final DateTime endUtc;
  final double price;
  final String? note;
  final String? packageTier;
  final String? packagePrice;
  final Map<String, dynamic>? packageData;

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  // Pre-filled test card values
  final _cardNumberCtrl = TextEditingController(text: '4242 4242 4242 4242');
  final _expiryCtrl = TextEditingController(text: '12/28');
  final _cvvCtrl = TextEditingController(text: '123');
  final _nameCtrl = TextEditingController(text: 'Test User');

  bool _processing = false;
  String? _error;
  bool _paymentSuccess = false;
  bool _awaitingGatewayConfirmation = false;
  bool _isPollingGatewayResult = false;
  final bool _paymentFlowInProgress = false;
  String? _draftBookingId;
  BookingViewModel? _vm;
  Timer? _orphanDraftTimer;

  @override
  void dispose() {
    _orphanDraftTimer?.cancel();
    final draftBookingId = _draftBookingId;
    // Only cancel draft if:
    // 1. Payment was not successful AND
    // 2. No payment flow is in progress (user abandoned before starting) AND
    // 3. Not awaiting gateway confirmation (payment is being processed)
    // If payment is in progress, let the 30-min orphan timer handle cleanup
    if (!_paymentSuccess && 
        !_paymentFlowInProgress && 
        !_awaitingGatewayConfirmation && 
        draftBookingId != null && 
        _vm != null) {
      unawaited(_vm!.cancelBookingDraftIfUnpaid(draftBookingId));
    }
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelDraftIfPossible(String bookingId) async {
    _orphanDraftTimer?.cancel();
    _orphanDraftTimer = null;
    final vm = context.read<BookingViewModel>();
    _vm = vm;
    await vm.cancelBookingDraftIfUnpaid(bookingId);
  }

  Future<void> _waitForGatewayConfirmation(String bookingId) async {
    if (_isPollingGatewayResult) return;
    _isPollingGatewayResult = true;
    final vm = context.read<BookingViewModel>();

    setState(() {
      _processing = true;
      _awaitingGatewayConfirmation = true;
      _error = null;
    });

    final held = await vm.waitForBookingPaymentHeld(bookingId: bookingId);
    _isPollingGatewayResult = false;

    if (!mounted) return;
    if (held) {
      _orphanDraftTimer?.cancel();
      _orphanDraftTimer = null;
      setState(() {
        _processing = false;
        _awaitingGatewayConfirmation = false;
        _paymentSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _processing = false;
      _awaitingGatewayConfirmation = false;
      _error = 'Payment still processing. Please check booking status shortly.';
    });
  }

  Future<void> _processPayment() async {
    setState(() {
      _processing = true;
      _error = null;
    });

    final vm = context.read<BookingViewModel>();

    try {
      // Step 1: Create draft booking (pending/unpaid) before payment init.
      final draft = await vm.createBookingDraft(
        taskId: widget.taskId,
        slotId: widget.slotId,
        providerId: widget.providerId,
        note: widget.note,
        price: widget.price,
        packageId: widget.packageTier,
        requirements: widget.packageData,
      );

      if (draft == null) {
        setState(() {
          _error = vm.bookingsError ?? 'Failed to create booking draft.';
          _processing = false;
        });
        return;
      }

      _draftBookingId = draft.id;
      _orphanDraftTimer?.cancel();
      _orphanDraftTimer = Timer(const Duration(minutes: 30), () {
        if (!mounted) return;
        unawaited(_cancelDraftIfPossible(draft.id));
      });

      // Step 2: Initiate QiCard payment (form URL path).
      final initResult = await vm.initiateQiCardPayment(
        amount: widget.price,
        bookingId: draft.id,
        description:
            'Booking: ${widget.packageTier ?? 'Service'} — ${widget.price} IQD',
      );

      if (initResult.isSuccess && initResult.formUrl != null) {
        final uri = Uri.tryParse(initResult.formUrl!);
        if (uri == null) {
          await _cancelDraftIfPossible(draft.id);
          setState(() {
            _error = 'Payment provider returned an invalid URL.';
            _processing = false;
          });
          return;
        }
        if (!mounted) return;
        final webViewResult = await Navigator.of(context)
            .push<PaymentWebViewResult>(
              MaterialPageRoute(
                builder: (_) =>
                    PaymentWebViewScreen(initialUrl: uri.toString()),
              ),
            );

        final resultStatus = (webViewResult?.status ?? 'CANCELED')
            .toUpperCase();
        if (resultStatus == 'FAILED' ||
            resultStatus == 'CANCELED' ||
            resultStatus == 'CANCELLED') {
          await _cancelDraftIfPossible(draft.id);
          setState(() {
            _error = 'Payment was not completed. Please try again.';
            _processing = false;
            _awaitingGatewayConfirmation = false;
          });
          return;
        }

        AppLogger.i(
          'QiCard payment return received booking=${draft.id} paymentId=${webViewResult?.paymentId ?? initResult.paymentId} requestId=${initResult.requestId} status=$resultStatus',
          tag: 'QiCard',
        );

        final paymentId = initResult.paymentId;
        final requestId = initResult.requestId;
        if (paymentId != null && requestId != null) {
          await vm.triggerQiCardSuccessRecovery(
            bookingId: draft.id,
            paymentId: paymentId,
            requestId: requestId,
            amount: widget.price,
          );
        }

        setState(() {
          _awaitingGatewayConfirmation = true;
        });
        await _waitForGatewayConfirmation(draft.id);
        return;
      }

      // Step 3 (fallback): only for explicit demo mode signal.
      if (initResult.errorCode != 'DEMO_MODE_LEGACY_FLOW') {
        await _cancelDraftIfPossible(draft.id);
        setState(() {
          _error =
              initResult.error ??
              'Payment could not be started. Please try again.';
          _processing = false;
        });
        return;
      }

      await _cancelDraftIfPossible(draft.id);
      setState(() {
        _error =
            'QiCard gateway is not enabled in this build. '
            'Please run with USE_QICARD_PAYMENT=true and valid QiCard credentials.';
        _processing = false;
      });
      return;
    } catch (e) {
      AppLogger.e('Payment flow failed', error: e, tag: 'Payment');
      if (!mounted) return;
      setState(() {
        _error = vm.bookingsError ?? 'Payment failed. Please try again.';
        _processing = false;
      });
    }
  }

  String _fmtRange(DateTime startUtc, DateTime endUtc) {
    final s = startUtc.toLocal();
    final e = endUtc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    String ymd(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
    String hm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
    return '${ymd(s)} · ${hm(s)} → ${hm(e)}';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Order Summary ────────────────────
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
                _summaryRow('Service', widget.packageTier ?? 'Booking', cs),
                const SizedBox(height: AppDimens.p8),
                _summaryRow(
                  'Schedule',
                  _fmtRange(widget.startUtc, widget.endUtc),
                  cs,
                ),
                if (widget.packageData?['delivery'] != null) ...[
                  const SizedBox(height: AppDimens.p8),
                  _summaryRow(
                    'Delivery',
                    '${widget.packageData!['delivery']} days',
                    cs,
                  ),
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
                      'IQD ${widget.price.toStringAsFixed(0)}',
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

          const SizedBox(height: AppDimens.p24),

          // ─── Payment Details ──────────────────
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

          // Error message
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

          // ─── Pay Button ───────────────────────
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
                        SizedBox(width: 12),
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
                      'Pay IQD ${widget.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: AppDimens.p12),

          // Security badge
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
