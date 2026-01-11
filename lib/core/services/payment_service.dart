/// Interface for payment processing.
abstract class PaymentService {
  /// Process a payment.
  ///
  /// Returns a transaction ID if successful, or throws an exception.
  Future<String> processPayment({
    required double amount,
    required String currency,
    required String description,
  });

  /// Initialize the payment SDK (if needed).
  Future<void> initialize();
}
