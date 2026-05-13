import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/config/payment_runtime_config.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_pending_store.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/web_url_utils_stub.dart'
    if (dart.library.html) 'package:sline_app/core/utils/web_url_utils_web.dart'
    as web_url_utils;
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
    final paymentReturn =
        widget.initialArgs ?? parsePaymentReturnArgs(Uri.base);

    // Clear payment params from the browser URL immediately so they are not
    // re-detected on subsequent navigations or hot-restarts.
    web_url_utils.clearPaymentReturnParamsFromUrl();

    final pendingStore = context.read<PaymentPendingStore>();
    final pendingContext = pendingStore.load();

    AppLogger.i(
      'Resolving payment return',
      tag: 'Payment',
      json: <String, dynamic>{
        'has_initial_args': widget.initialArgs != null,
        'has_pending_booking': pendingContext?.bookingId.isNotEmpty ?? false,
        'has_pending_correlation': pendingContext?.correlationId != null,
      },
    );

    if (paymentReturn == null) {
      AppLogger.w(
        'Payment return rejected: invalid callback payload',
        tag: 'Payment',
        error: 'INVALID_CALLBACK_PAYLOAD',
      );
      _setTerminalState(
        message: 'The payment callback is invalid.',
        isRecoverable: false,
      );
      return;
    }

    final bookingId = paymentReturn.bookingId ?? pendingContext?.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      AppLogger.w(
        'Payment return rejected: missing booking reference',
        tag: 'Payment',
        error: 'MISSING_BOOKING_REFERENCE',
      );
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
        AppLogger.w(
          'Payment return rejected: callback host mismatch',
          tag: 'Payment',
          json: <String, dynamic>{
            'callback_host': callbackHost,
            'expected_host_count': expectedHosts.length,
          },
        );
        _setTerminalState(
          message:
              'The payment callback host does not match the pending payment.',
          isRecoverable: false,
        );
        return;
      }

      if (paymentReturn.bookingId != null &&
          paymentReturn.bookingId != pendingContext.bookingId) {
        AppLogger.w(
          'Payment return rejected: booking mismatch',
          tag: 'Payment',
          json: <String, dynamic>{
            'has_callback_booking': paymentReturn.bookingId != null,
            'has_pending_booking': pendingContext.bookingId.isNotEmpty,
          },
        );
        _setTerminalState(
          message: 'The payment callback does not match the pending booking.',
          isRecoverable: false,
        );
        return;
      }

      if (paymentReturn.correlationId != null &&
          pendingContext.correlationId != null &&
          paymentReturn.correlationId != pendingContext.correlationId) {
        AppLogger.w(
          'Payment return rejected: correlation mismatch',
          tag: 'Payment',
          json: <String, dynamic>{
            'has_callback_correlation': paymentReturn.correlationId != null,
            'has_pending_correlation': pendingContext.correlationId != null,
          },
        );
        _setTerminalState(
          message:
              'The payment callback correlation does not match the pending payment.',
          isRecoverable: false,
        );
        return;
      }
    }

    if (paymentReturn.isFailure) {
      AppLogger.w(
        'Payment return reported failure',
        tag: 'Payment',
        json: <String, dynamic>{
          'has_booking': bookingId.isNotEmpty,
          'status': paymentReturn.normalizedStatus,
        },
      );
      await context.read<BookingViewModel>().cancelBookingDraftIfUnpaid(
        bookingId,
      );
      await pendingStore.clear();
      _setTerminalState(
        message:
            'Payment was not completed. You can retry checkout from the booking screen.',
        isRecoverable: false,
      );
      return;
    }

    AppLogger.i(
      'Payment return accepted, starting recovery',
      tag: 'Payment',
      json: <String, dynamic>{
        'has_booking': bookingId.isNotEmpty,
        'status': paymentReturn.normalizedStatus,
        'has_correlation': paymentReturn.correlationId != null,
      },
    );
    final recovery = await context
        .read<BookingViewModel>()
        .recoverBookingPaymentWithRetries(bookingId: bookingId);

    if (!mounted) return;

    if (recovery.isSuccess && recovery.paymentStatus == 'held') {
      await pendingStore.clear();
      AppLogger.i(
        'Payment recovery succeeded',
        tag: 'Payment',
        json: <String, dynamic>{
          'has_booking': bookingId.isNotEmpty,
          'recovery_result': recovery.recoveryResult,
          'payment_status': recovery.paymentStatus,
        },
      );
      setState(() {
        _isLoading = false;
        _isRecoverable = false;
        _isSuccess = true;
        _message = 'Payment confirmed. Your booking is ready.';
      });
      return;
    }

    AppLogger.w(
      'Payment recovery completed without held status',
      tag: 'Payment',
      error: recovery.error ?? 'BOOKING_PAYMENT_NOT_HELD',
      json: <String, dynamic>{
        'has_booking': bookingId.isNotEmpty,
        'recovery_result': recovery.recoveryResult,
        'payment_status': recovery.paymentStatus,
      },
    );
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
                              ? colorScheme.success
                              : colorScheme.warning,
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
                        if (_isRecoverable)
                          const SizedBox(height: AppDimens.p12),
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
