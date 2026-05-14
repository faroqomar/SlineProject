/// Sanitized payment callback result passed between payment UI routes.
///
/// The object keeps internal recovery identifiers in app state while the
/// customer-facing callback URL can stay free of booking/correlation details.
class PaymentReturnArgs {
  const PaymentReturnArgs({
    required this.status,
    required this.rawUri,
    this.bookingId,
    this.correlationId,
    this.paymentId,
    this.paymentIntentId,
    this.offerId,
    this.requestId,
    this.paymentRequestId,
  });

  /// Gateway or app-derived callback status.
  final String status;

  /// Booking id resolved from trusted URL params, widget state, or pending store.
  final String? bookingId;

  /// Server-side payment correlation id when available from trusted state.
  final String? correlationId;

  /// Gateway payment reference when the provider exposes one.
  final String? paymentId;

  /// Hardened payment intent id used for realtime and recovery correlation.
  final String? paymentIntentId;

  /// Direct offer payment callback.
  final String? offerId;

  /// Tender (task_request) payment callback.
  final String? requestId;

  /// Gateway request id when legacy callback URLs still provide it.
  final String? paymentRequestId;

  /// Original callback URI after sanitization or a synthetic realtime URI.
  final Uri rawUri;

  /// Uppercase status value used for resilient gateway comparisons.
  String get normalizedStatus => status.toUpperCase();

  /// Whether the gateway reports a completed payment.
  bool get isSuccess =>
      normalizedStatus == 'SUCCESS' ||
      normalizedStatus == 'SUCCEEDED' ||
      normalizedStatus == 'COMPLETED';

  /// Whether the gateway reports a terminal failed or canceled payment.
  bool get isFailure =>
      normalizedStatus == 'FAILED' ||
      normalizedStatus == 'CANCELED' ||
      normalizedStatus == 'CANCELLED' ||
      normalizedStatus == 'ERROR';
}
