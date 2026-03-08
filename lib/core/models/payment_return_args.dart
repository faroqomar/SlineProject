class PaymentReturnArgs {
  const PaymentReturnArgs({
    required this.status,
    required this.rawUri,
    this.bookingId,
    this.correlationId,
    this.paymentId,
    this.offerId,
    this.requestId,
    this.paymentRequestId,
  });

  final String status;
  final String? bookingId;
  final String? correlationId;
  final String? paymentId;

  /// Direct offer payment callback.
  final String? offerId;

  /// Tender (task_request) payment callback.
  final String? requestId;
  final String? paymentRequestId;
  final Uri rawUri;

  String get normalizedStatus => status.toUpperCase();

  bool get isSuccess =>
      normalizedStatus == 'SUCCESS' || normalizedStatus == 'COMPLETED';

  bool get isFailure =>
      normalizedStatus == 'FAILED' ||
      normalizedStatus == 'CANCELED' ||
      normalizedStatus == 'CANCELLED' ||
      normalizedStatus == 'ERROR';
}
