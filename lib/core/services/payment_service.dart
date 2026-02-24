/// Interface for payment processing.
class PaymentInitResult {
  const PaymentInitResult({
    this.formUrl,
    this.paymentId,
    this.requestId,
    this.error,
    this.errorCode,
  });

  final String? formUrl;
  final String? paymentId;
  final String? requestId;
  final String? error;
  final String? errorCode;

  bool get isSuccess => formUrl != null && error == null;
}

abstract class PaymentService {
  /// Process a payment.
  ///
  /// Returns a transaction ID if successful, or throws an exception.
  Future<String> processPayment({
    required double amount,
    required String currency,
    required String description,
  });

  /// Initiate external payment flow (e.g. QiCard form URL).
  Future<PaymentInitResult> initiatePayment({
    required double amount,
    required String currency,
    required String bookingId,
    required String clientId,
    String? description,
  });

  /// Best-effort recovery trigger when gateway returns SUCCESS but webhook
  /// is delayed/missed. Returns true when webhook endpoint accepts the request.
  Future<bool> triggerPaymentSuccessRecovery({
    required String bookingId,
    required String paymentId,
    required String requestId,
    required double amount,
    required String currency,
    required String clientId,
  });

  /// Initialize the payment SDK (if needed).
  Future<void> initialize();
}
