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
    await Future<void>.delayed(delay);

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

  @override
  Future<RefundResult> refundPayment({
    required String paymentId,
    required double amount,
    required String currency,
    String? reason,
  }) async {
    await Future<void>.delayed(delay);

    if (shouldFail) {
      return const RefundResult(
        error: 'Refund failed (Demo)',
        errorCode: 'DEMO_REFUND_FAILED',
      );
    }

    return RefundResult(
      refundId: 'demo_refund_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      currency: currency,
      status: 'COMPLETED',
    );
  }

  @override
  Future<CancelResult> cancelPayment({
    required String paymentId,
    required String reason,
  }) async {
    await Future<void>.delayed(delay);

    if (shouldFail) {
      return const CancelResult(
        error: 'Cancel failed (Demo)',
        errorCode: 'DEMO_CANCEL_FAILED',
      );
    }

    return CancelResult(
      cancelId: 'demo_cancel_${DateTime.now().millisecondsSinceEpoch}',
      status: 'CANCELLED',
    );
  }

  @override
  Future<PaymentStatusResult> getPaymentStatus({
    required String paymentId,
  }) async {
    await Future<void>.delayed(delay);

    if (shouldFail) {
      return const PaymentStatusResult(
        error: 'Status check failed (Demo)',
        errorCode: 'DEMO_STATUS_FAILED',
      );
    }

    return PaymentStatusResult(
      paymentId: paymentId,
      status: 'SUCCESS',
      amount: 100.0,
      currency: 'IQD',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );
  }

  @override
  Future<PaymentIntentResult> createPaymentIntent({
    required String entityType,
    required String entityId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    await Future<void>.delayed(delay);
    return const PaymentIntentResult(
      error: 'Payment Intents are not available in demo mode.',
      errorCode: 'DEMO_INTENTS_UNSUPPORTED',
    );
  }

  @override
  Future<QiCardCreatePaymentResult> createPaymentForBooking({
    required String taskId,
    String? note,
    String? packageId,
    Map<String, dynamic>? requirements,
    String? finishUrl,
    String? requestCorrelationId,
  }) async {
    await Future<void>.delayed(delay);
    return QiCardCreatePaymentResult(
      requestCorrelationId: requestCorrelationId,
      error: 'Booking checkout is not available in demo mode.',
      errorCode: 'DEMO_BOOKING_CREATE_UNSUPPORTED',
    );
  }

  @override
  Future<QiCardRecoveryResult> recoverBookingPayment({
    required String bookingId,
  }) async {
    await Future<void>.delayed(delay);
    return const QiCardRecoveryResult(
      error: 'Booking recovery is not available in demo mode.',
      errorCode: 'DEMO_BOOKING_RECOVERY_UNSUPPORTED',
    );
  }

  @override
  Future<BookingRefundResult> declineAndRefundBooking({
    required String bookingId,
    required String reason,
  }) async {
    await Future<void>.delayed(delay);
    return const BookingRefundResult(
      error: 'Booking refund is not available in demo mode.',
      errorCode: 'DEMO_BOOKING_REFUND_UNSUPPORTED',
    );
  }

  @override
  Future<QiCardDirectOfferPaymentResult> createPaymentForDirectOffer({
    required String offerId,
    required double amount,
    String? finishUrl,
    String? requestCorrelationId,
  }) async {
    await Future<void>.delayed(delay);
    return QiCardDirectOfferPaymentResult(
      offerId: offerId,
      error: 'Pay with card is not available in demo mode.',
      errorCode: 'DEMO_DIRECT_OFFER_PAYMENT_UNSUPPORTED',
    );
  }

  @override
  Future<QiCardTenderPaymentResult> createPaymentForTenderOffer({
    required String requestId,
    required double amount,
    String currency = 'IQD',
    String? description,
    String? finishUrl,
    String? requestCorrelationId,
  }) async {
    await Future<void>.delayed(delay);
    return QiCardTenderPaymentResult(
      requestId: requestId,
      error: 'Tender card payment is not available in demo mode.',
      errorCode: 'DEMO_TENDER_PAYMENT_UNSUPPORTED',
    );
  }

  @override
  Future<QiCardTenderRecoveryResult> recoverTenderPaymentAfterCallback({
    required String requestId,
    required String paymentRequestId,
  }) async {
    await Future<void>.delayed(delay);
    return const QiCardTenderRecoveryResult(
      error: 'Tender recovery is not available in demo mode.',
      errorCode: 'DEMO_TENDER_RECOVERY_UNSUPPORTED',
    );
  }

  @override
  Stream<String> streamPaymentIntentStatus(String intentId) {
    return Stream.value('succeeded');
  }
}
