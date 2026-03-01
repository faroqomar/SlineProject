// Interface for payment processing.
//
// This file defines the abstract contract that all payment implementations
// must follow, including QiCard, Stripe, and demo/test implementations.

/// Result of payment initiation.
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

/// Result of refund operation.
class RefundResult {
  const RefundResult({
    this.refundId,
    this.amount,
    this.currency,
    this.status,
    this.error,
    this.errorCode,
  });

  final String? refundId;
  final double? amount;
  final String? currency;
  final String? status;
  final String? error;
  final String? errorCode;

  bool get isSuccess => refundId != null && error == null;
}

/// Result of cancel operation.
class CancelResult {
  const CancelResult({this.cancelId, this.status, this.error, this.errorCode});

  final String? cancelId;
  final String? status;
  final String? error;
  final String? errorCode;

  bool get isSuccess => cancelId != null && error == null;
}

/// Result of payment status check.
class PaymentStatusResult {
  const PaymentStatusResult({
    this.paymentId,
    this.status,
    this.amount,
    this.currency,
    this.createdAt,
    this.error,
    this.errorCode,
  });

  final String? paymentId;
  final String? status; // 'PENDING', 'SUCCESS', 'FAILED', 'CANCELLED', etc.
  final double? amount;
  final String? currency;
  final DateTime? createdAt;
  final String? error;
  final String? errorCode;

  bool get isSuccess => status != null && error == null;

  bool get isPending =>
      status?.toUpperCase() == 'PENDING' || status?.toUpperCase() == 'CREATED';
  bool get isCompleted =>
      status?.toUpperCase() == 'SUCCESS' ||
      status?.toUpperCase() == 'COMPLETED';
  bool get isFailed =>
      status?.toUpperCase() == 'FAILED' || status?.toUpperCase() == 'CANCELLED';
}

class QiCardCreatePaymentResult {
  const QiCardCreatePaymentResult({
    this.bookingId,
    this.paymentRequestId,
    this.formUrl,
    this.amount,
    this.providerId,
    this.expiresAt,
    this.correlationId,
    this.requestCorrelationId,
    this.error,
    this.errorCode,
  });

  final String? bookingId;
  final String? paymentRequestId;
  final String? formUrl;
  final double? amount;
  final String? providerId;
  final DateTime? expiresAt;
  final String? correlationId;
  final String? requestCorrelationId;
  final String? error;
  final String? errorCode;

  bool get isSuccess => bookingId != null && formUrl != null && error == null;
}

class QiCardRecoveryResult {
  const QiCardRecoveryResult({
    this.bookingId,
    this.bookingStatus,
    this.paymentStatus,
    this.recoveryResult,
    this.correlationId,
    this.error,
    this.errorCode,
  });

  final String? bookingId;
  final String? bookingStatus;
  final String? paymentStatus;
  final String? recoveryResult;
  final String? correlationId;
  final String? error;
  final String? errorCode;

  bool get isSuccess => bookingId != null && error == null;
}

class BookingRefundResult {
  const BookingRefundResult({
    this.bookingId,
    this.bookingStatus,
    this.paymentStatus,
    this.refundResult,
    this.correlationId,
    this.error,
    this.errorCode,
  });

  final String? bookingId;
  final String? bookingStatus;
  final String? paymentStatus;
  final String? refundResult;
  final String? correlationId;
  final String? error;
  final String? errorCode;

  bool get isSuccess => bookingId != null && error == null;
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

  /// Refund a payment.
  ///
  /// [paymentId] - The original payment ID to refund.
  /// [amount] - The amount to refund (may be partial).
  /// [currency] - The currency code (e.g., 'IQD').
  /// [reason] - Optional reason for the refund.
  ///
  /// Returns [RefundResult] with refund details or error information.
  Future<RefundResult> refundPayment({
    required String paymentId,
    required double amount,
    required String currency,
    String? reason,
  });

  /// Cancel a pending payment.
  ///
  /// [paymentId] - The payment ID to cancel.
  /// [reason] - Optional reason for cancellation.
  ///
  /// Returns [CancelResult] with cancel details or error information.
  Future<CancelResult> cancelPayment({
    required String paymentId,
    required String reason,
  });

  /// Get the current status of a payment.
  ///
  /// [paymentId] - The payment ID to check.
  ///
  /// Returns [PaymentStatusResult] with current status or error information.
  Future<PaymentStatusResult> getPaymentStatus({required String paymentId});

  /// Create a booking draft and QiCard payment request on the server.
  Future<QiCardCreatePaymentResult> createPaymentForBooking({
    required String taskId,
    String? note,
    String? packageId,
    Map<String, dynamic>? requirements,
    String? requestCorrelationId,
  });

  /// Recover booking payment state for the caller's own booking.
  Future<QiCardRecoveryResult> recoverBookingPayment({
    required String bookingId,
  });

  /// Decline or cancel a booking and refund when funds are held.
  Future<BookingRefundResult> declineAndRefundBooking({
    required String bookingId,
    required String reason,
  });
}
