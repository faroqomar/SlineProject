import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/booking/data/booking_repository.dart';
import 'package:uuid/uuid.dart';

/// Stateless delegate that owns payment coordination for [BookingViewModel].
///
/// All methods return results directly; the parent ViewModel is responsible
/// for setting error fields, refreshing in-memory lists, and calling
/// `notifyListeners()`.
class BookingPaymentDelegate {
  BookingPaymentDelegate({
    required BookingRepository repo,
    required PaymentService paymentService,
  }) : _repo = repo,
       _paymentService = paymentService;

  static const _kTag = 'Booking';

  final BookingRepository _repo;
  final PaymentService _paymentService;
  final Uuid _uuid = const Uuid();

  String? get currentUserId => _repo.currentUser?.id;

  // ── Simple payment processing ──────────────────────────────────────

  /// Process a payment through the payment service.
  /// Returns a transaction ID on success, or throws on failure.
  Future<String> processPayment({
    required double amount,
    required String currency,
    required String description,
  }) {
    return _paymentService.processPayment(
      amount: amount,
      currency: currency,
      description: description,
    );
  }

  // ── QiCard initiation ──────────────────────────────────────────────

  /// Initiate a QiCard payment flow. Returns [PaymentInitResult].
  Future<PaymentInitResult> initiateQiCardPayment({
    required double amount,
    required String bookingId,
    String? description,
  }) async {
    final clientId = currentUserId;
    if (clientId == null) {
      return const PaymentInitResult(
        error: 'Session expired. Please log in again.',
      );
    }

    return _paymentService.initiatePayment(
      amount: amount,
      currency: 'IQD',
      bookingId: bookingId,
      clientId: clientId,
      description: description,
    );
  }

  // ── QiCard success recovery ────────────────────────────────────────

  Future<bool> triggerQiCardSuccessRecovery({
    required String bookingId,
    required String paymentId,
    required String requestId,
    required double amount,
  }) async {
    final clientId = currentUserId;
    if (clientId == null) return false;
    return _paymentService.triggerPaymentSuccessRecovery(
      bookingId: bookingId,
      paymentId: paymentId,
      requestId: requestId,
      amount: amount,
      currency: 'IQD',
      clientId: clientId,
    );
  }

  // ── Create booking + payment intent ────────────────────────────────

  /// Creates a booking draft via RPC, then creates a payment intent via
  /// the payment edge function. Returns a composite result.
  Future<QiCardCreatePaymentResult> createPaymentForBooking({
    required String taskId,
    String? note,
    String? packageId,
    Map<String, dynamic>? requirements,
    String? finishUrl,
  }) async {
    final requestCorrelationId = 'booking_create:${_uuid.v4()}';
    AppLogger.i(
      'Requesting server-backed booking payment intent task=$taskId package=${packageId ?? 'none'}',
      tag: _kTag,
      json: <String, dynamic>{
        'task_id': taskId,
        'package_id': packageId,
        'has_note': note != null && note.trim().isNotEmpty,
        'finish_url': finishUrl,
        'request_correlation_id': requestCorrelationId,
      },
    );

    // 1. Create booking draft via Postgres RPC
    final draft = await _repo.createBookingDraft(
      taskId: taskId,
      note: note,
      packageId: packageId,
      requirements: requirements,
    );

    // 2. Create the payment intent using the edge function
    final intentResult = await _paymentService.createPaymentIntent(
      entityType: 'booking',
      entityId: draft.id,
      successUrl: finishUrl ?? 'https://sline.app/?payment_return=1',
      cancelUrl: 'https://sline.app/?payment_return=0',
    );

    if (!intentResult.isSuccess) {
      AppLogger.w(
        'Booking payment intent request failed for task=$taskId',
        tag: _kTag,
        error:
            mapServiceError(intentResult.error) ??
            intentResult.error ??
            'BOOKING_PAYMENT_CREATE_FAILED',
      );
      return QiCardCreatePaymentResult(
        bookingId: draft.id,
        error: intentResult.error,
        errorCode: intentResult.errorCode,
        requestCorrelationId: requestCorrelationId,
      );
    }

    AppLogger.i(
      'Booking payment intent created booking=${draft.id} intent=${intentResult.intentId}',
      tag: _kTag,
    );

    return QiCardCreatePaymentResult(
      bookingId: draft.id,
      intentId: intentResult.intentId,
      formUrl: intentResult.checkoutUrl,
      amount: draft.price?.toDouble(),
      providerId: draft.providerId,
      requestCorrelationId: requestCorrelationId,
    );
  }

  // ── Payment intent status stream ───────────────────────────────────

  /// Streams the status of a payment intent directly from the database.
  Stream<String> streamPaymentIntentStatus(String intentId) {
    return _paymentService.streamPaymentIntentStatus(intentId);
  }

  // ── Payment recovery ───────────────────────────────────────────────

  /// Recover booking payment state for the caller's own booking.
  Future<QiCardRecoveryResult> recoverBookingPayment({
    required String bookingId,
  }) async {
    AppLogger.i(
      'Recovering booking payment booking=$bookingId',
      tag: _kTag,
    );
    return _paymentService.recoverBookingPayment(bookingId: bookingId);
  }

  /// Retries [recoverBookingPayment] up to [maxAttempts] times when the
  /// server returns `no_action` (webhook not yet processed).
  Future<QiCardRecoveryResult> recoverBookingPaymentWithRetries({
    required String bookingId,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    var attempt = 1;
    var result = await recoverBookingPayment(bookingId: bookingId);

    while (result.isSuccess &&
        result.paymentStatus != 'held' &&
        result.recoveryResult == 'no_action' &&
        attempt < maxAttempts) {
      AppLogger.w(
        'Booking recovery returned no_action for booking=$bookingId; retrying',
        tag: _kTag,
        json: <String, dynamic>{
          'attempt': attempt + 1,
          'payment_status': result.paymentStatus,
          'recovery_result': result.recoveryResult,
        },
      );
      await Future.delayed(delay);
      result = await recoverBookingPayment(bookingId: bookingId);
      attempt += 1;
    }

    return result;
  }

  // ── Decline + refund ───────────────────────────────────────────────

  /// Decline a booking and refund held funds atomically via edge function.
  Future<BookingRefundResult> declineAndRefundBooking({
    required String bookingId,
    required String reason,
  }) {
    return _paymentService.declineAndRefundBooking(
      bookingId: bookingId,
      reason: reason,
    );
  }

  // ── Error mapping (exposed for parent) ─────────────────────────────

  /// Maps service-level error strings to user-friendly messages.
  /// Returns `null` when the input is null/empty, or the original string
  /// when no mapping applies.
  static String? mapServiceError(String? error) {
    if (error == null || error.isEmpty) return error;
    final msg = error.toLowerCase();
    if (msg.contains('booking_task_not_bookable')) {
      return 'This booking is not currently available.';
    }
    if (msg.contains('booking_self_booking_forbidden')) {
      return 'You cannot book your own service.';
    }
    if (msg.contains('booking_already_exists_for_client')) {
      return 'This booking request could not be created. Please refresh and try again.';
    }
    if (msg.contains('booking_package_invalid')) {
      return 'The selected package is no longer available.';
    }
    if (msg.contains('booking_slot_unavailable') ||
        msg.contains('booking_slot_in_past')) {
      return 'This slot is no longer available.';
    }
    if (msg.contains('qicard request failed with status 5') ||
        msg.contains('service unavailable') ||
        msg.contains('temporarily unavailable')) {
      return 'QiCard is temporarily unavailable. Please try again in a moment.';
    }
    return error;
  }
}
