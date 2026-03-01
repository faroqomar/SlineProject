import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/config/payment_runtime_config.dart';
import 'package:sline_app/core/services/payment_pending_store.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/booking/models/payment_return_args.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';

class PaymentReturnScreen extends StatefulWidget {
  const PaymentReturnScreen({super.key, this.initialArgs});

  final PaymentReturnArgs? initialArgs;

  @override
  State<PaymentReturnScreen> createState() => _PaymentReturnScreenState();
}

class _PaymentReturnScreenState extends State<PaymentReturnScreen> {
  bool _isLoading = true;
  bool _isRecoverable = false;
  bool _isSuccess = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolvePaymentReturn();
    });
  }

  Future<void> _resolvePaymentReturn() async {
    final paymentReturn = widget.initialArgs ?? parsePaymentReturnArgs(Uri.base);
    final pendingStore = context.read<PaymentPendingStore>();
    final pendingContext = pendingStore.load();

    if (paymentReturn == null) {
      _setTerminalState(
        message: 'The payment callback is invalid.',
        isRecoverable: false,
      );
      return;
    }

    final bookingId = paymentReturn.bookingId ?? pendingContext?.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      _setTerminalState(
        message: 'The payment callback is missing the booking reference.',
        isRecoverable: false,
      );
      return;
    }

    if (pendingContext != null) {
      final expectedHosts = pendingContext.callbackHosts;
      final callbackHost = paymentReturn.rawUri.host.toLowerCase();
      if (expectedHosts.isNotEmpty && !expectedHosts.contains(callbackHost)) {
        _setTerminalState(
          message: 'The payment callback host does not match the pending payment.',
          isRecoverable: false,
        );
        return;
      }

      if (paymentReturn.bookingId != null &&
          paymentReturn.bookingId != pendingContext.bookingId) {
        _setTerminalState(
          message: 'The payment callback does not match the pending booking.',
          isRecoverable: false,
        );
        return;
      }

      if (paymentReturn.correlationId != null &&
          pendingContext.correlationId != null &&
          paymentReturn.correlationId != pendingContext.correlationId) {
        _setTerminalState(
          message:
              'The payment callback correlation does not match the pending payment.',
          isRecoverable: false,
        );
        return;
      }
    }

    if (paymentReturn.isFailure) {
      await context.read<BookingViewModel>().cancelBookingDraftIfUnpaid(bookingId);
      await pendingStore.clear();
      _setTerminalState(
        message: 'Payment was not completed. You can retry checkout from the booking screen.',
        isRecoverable: false,
      );
      return;
    }

    final recovery = await context
        .read<BookingViewModel>()
        .recoverBookingPaymentWithRetries(bookingId: bookingId);

    if (!mounted) return;

    if (recovery.isSuccess && recovery.paymentStatus == 'held') {
      await pendingStore.clear();
      setState(() {
        _isLoading = false;
        _isRecoverable = false;
        _isSuccess = true;
        _message = 'Payment confirmed. Your booking is ready.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _isRecoverable = true;
      _isSuccess = false;
      _message =
          recovery.error ??
          'Payment recovery completed with status ${recovery.paymentStatus ?? 'unknown'}.';
    });
  }

  void _setTerminalState({
    required String message,
    required bool isRecoverable,
  }) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isRecoverable = isRecoverable;
      _isSuccess = false;
      _message = message;
    });
  }

  void _openMainApp() {
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Return')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p24),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.p24),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(AppDimens.r16),
                border: Border.all(color: colorScheme.inputBorder),
              ),
              child: _isLoading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppDimens.p16),
                        Text(
                          'Finalizing payment...',
                          style: AppTypography.h5.copyWith(
                            color: colorScheme.text,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle : Icons.info_outline,
                          size: 48,
                          color: _isSuccess
                              ? AppColors.teal
                              : AppColors.gold,
                        ),
                        const SizedBox(height: AppDimens.p16),
                        Text(
                          _isSuccess ? 'Payment Complete' : 'Payment Update',
                          style: AppTypography.h4.copyWith(
                            color: colorScheme.text,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.p12),
                        Text(
                          _message ?? 'Unknown payment state.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.p24),
                        if (_isRecoverable)
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _isRecoverable = false;
                              });
                              _resolvePaymentReturn();
                            },
                            child: const Text('Retry Recovery'),
                          ),
                        if (_isRecoverable) const SizedBox(height: AppDimens.p12),
                        OutlinedButton(
                          onPressed: _openMainApp,
                          child: const Text('Open App'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
