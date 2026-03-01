class PaymentReturnArgs {
  const PaymentReturnArgs({
    required this.status,
    required this.rawUri,
    this.bookingId,
    this.correlationId,
    this.paymentId,
  });

  final String status;
  final String? bookingId;
  final String? correlationId;
  final String? paymentId;
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
