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
    this.intentId,
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
  final String? intentId;
  final String? paymentRequestId;
  final String? formUrl;
  final double? amount;
  final String? providerId;
  final DateTime? expiresAt;
  final String? correlationId;
  final String? requestCorrelationId;
  final String? error;
  final String? errorCode;

  bool get isSuccess =>
      (bookingId != null || paymentRequestId != null) &&
      formUrl != null &&
      error == null;
}

class PaymentIntentResult {
  const PaymentIntentResult({
    this.intentId,
    this.checkoutUrl,
    this.error,
    this.errorCode,
  });

  final String? intentId;
  final String? checkoutUrl;
  final String? error;
  final String? errorCode;

  bool get isSuccess =>
      intentId != null && checkoutUrl != null && error == null;
}

/// Result of creating a QiCard payment for a direct offer (accepted, unpaid).
class QiCardDirectOfferPaymentResult {
  const QiCardDirectOfferPaymentResult({
    this.offerId,
    this.formUrl,
    this.correlationId,
    this.paymentRequestId,
    this.amount,
    this.error,
    this.errorCode,
  });

  final String? offerId;
  final String? formUrl;
  final String? correlationId;

  /// For recovery when the app gets the success callback (from URL or create response).
  final String? paymentRequestId;
  final double? amount;
  final String? error;
  final String? errorCode;

  bool get isSuccess => offerId != null && formUrl != null && error == null;
}

/// Result of creating a QiCard payment for an awarded tender (task_request).
class QiCardTenderPaymentResult {
  const QiCardTenderPaymentResult({
    this.requestId,
    this.formUrl,
    this.correlationId,
    this.paymentRequestId,
    this.amount,
    this.error,
    this.errorCode,
  });

  final String? requestId;
  final String? formUrl;
  final String? correlationId;
  final String? paymentRequestId;
  final double? amount;
  final String? error;
  final String? errorCode;

  bool get isSuccess => requestId != null && formUrl != null && error == null;
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

  /// Unified hardned payment intent creation mapping to the secure Edge Function.
  Future<PaymentIntentResult> createPaymentIntent({
    required String entityType,
    required String entityId,
    required String successUrl,
    required String cancelUrl,
  });

  /// Create a booking draft and QiCard payment request on the server.
  Future<QiCardCreatePaymentResult> createPaymentForBooking({
    required String taskId,
    String? note,
    String? packageId,
    Map<String, dynamic>? requirements,
    String? finishUrl,
    String? requestCorrelationId,
  });

  /// Recover booking payment state for the caller's own booking.
  Future<QiCardRecoveryResult> recoverBookingPayment({
    required String bookingId,
  });

  /// Create a QiCard payment for an accepted, unpaid direct offer.
  /// Returns formUrl to open in WebView; on success the edge function records gateway escrow.
  Future<QiCardDirectOfferPaymentResult> createPaymentForDirectOffer({
    required String offerId,
    required double amount,
    String? finishUrl,
    String? requestCorrelationId,
  });

  /// Decline or cancel a booking and refund when funds are held.
  Future<BookingRefundResult> declineAndRefundBooking({
    required String bookingId,
    required String reason,
  });

  /// Create a QiCard payment for an awarded, unpaid tender (task_request).
  /// Returns formUrl to open in WebView; on return the app calls [recoverTenderPaymentAfterCallback].
  Future<QiCardTenderPaymentResult> createPaymentForTenderOffer({
    required String requestId,
    required double amount,
    String currency = 'IQD',
    String? description,
    String? finishUrl,
    String? requestCorrelationId,
  });

  /// Recover tender payment after WebView callback (QiCard success).
  /// Call after the user returns from the payment WebView with success.
  Future<QiCardTenderRecoveryResult> recoverTenderPaymentAfterCallback({
    required String requestId,
    required String paymentRequestId,
  });

  /// Streams the status of a payment intent directly from the database.
  Stream<String> streamPaymentIntentStatus(String intentId);
}

/// Result of tender payment recovery (after WebView return).
class QiCardTenderRecoveryResult {
  const QiCardTenderRecoveryResult({
    this.ok,
    this.recovered,
    this.message,
    this.error,
    this.errorCode,
  });

  final bool? ok;
  final bool? recovered;
  final String? message;
  final String? error;
  final String? errorCode;

  bool get isSuccess => ok == true && error == null;
}
