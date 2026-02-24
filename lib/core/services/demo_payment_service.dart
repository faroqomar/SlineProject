import 'dart:async';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_service.dart';

/// Demo implementation of PaymentService for testing.
///
/// Simulates network delays and random failures (optional).
class DemoPaymentService implements PaymentService {
  final bool shouldFail;
  final Duration delay;

  DemoPaymentService({
    this.shouldFail = false,
    this.delay = const Duration(seconds: 2),
  });

  @override
  Future<void> initialize() async {
    AppLogger.i('DemoPaymentService initialized');
  }

  @override
  Future<String> processPayment({
    required double amount,
    required String currency,
    required String description,
  }) async {
    AppLogger.i('Processing demo payment: $currency $amount - $description');

    // Simulate network delay
    await Future.delayed(delay);

    if (shouldFail) {
      AppLogger.e('Demo payment failed (simulated)');
      throw Exception('Payment declined (Demo)');
    }

    final transactionId = 'demo_txn_${DateTime.now().millisecondsSinceEpoch}';
    AppLogger.i('Demo payment successful: $transactionId');
    return transactionId;
  }

  @override
  Future<PaymentInitResult> initiatePayment({
    required double amount,
    required String currency,
    required String bookingId,
    required String clientId,
    String? description,
  }) async {
    return const PaymentInitResult(
      error: 'External payment init is not available in demo mode.',
      errorCode: 'DEMO_MODE_LEGACY_FLOW',
    );
  }

  @override
  Future<bool> triggerPaymentSuccessRecovery({
    required String bookingId,
    required String paymentId,
    required String requestId,
    required double amount,
    required String currency,
    required String clientId,
  }) async {
    return false;
  }
}
