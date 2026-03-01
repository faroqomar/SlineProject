import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import 'package:sline_app/core/app_enums.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/models/conversation_model.dart'; // Added
import '../data/booking_repository.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/services/demo_payment_service.dart';
import 'package:uuid/uuid.dart';

/// BookingViewModel — MVVM state holder for Booking/Scheduling feature.
///
/// This ViewModel demonstrates several BEST PRACTICES that should be
/// followed across the codebase:
///
/// 1. **Cursor-Based Pagination**: Uses ISO timestamps as cursors instead of
///    offsets. This is more efficient and handles concurrent updates correctly.
///    See `bookingsClientCursor`, `bookingsProviderCursor`.
///
/// 2. **User-Friendly Error Mapping**: The `_mapError()` method translates
///    technical Supabase/Postgres errors into readable messages.
///    Error code 23505 = unique violation = "already booked"
///
/// 3. **Server-Authoritative Booking Creation**: New bookings are created
///    through the payment edge function, then refreshed from the canonical row.
///
/// 4. **Separate Loading States**: Each data type has its own loading flag
///    (`bookingsLoading`) to prevent UI flicker.
///
/// 5. **hasMore Flags**: Tracks whether more pages are available to prevent
///    unnecessary API calls when scrolling past the end.
class BookingViewModel extends ChangeNotifier {
  BookingViewModel({
    required BookingRepository repo,
    required ChatRepository chatRepository,
    PaymentService? paymentService,
  }) : _repo = repo,
       _chatRepository = chatRepository,
       _paymentService = paymentService ?? DemoPaymentService();

  final BookingRepository _repo;
  final ChatRepository _chatRepository;
  final PaymentService _paymentService;
  final Uuid _uuid = const Uuid();
  String get paymentServiceType => _paymentService.runtimeType.toString();

  static const int _pageSize = 50;

  /// Expose current authenticated user id for UI decisions when needed.
  String? get currentUserId => _repo.currentUser?.id;

  // Pagination flags
  bool bookingsClientHasMore = true;
  bool bookingsProviderHasMore = true;

  String _mapError(Object e) {
    // Friendly messages for common Supabase/Postgres errors
    try {
      if (e is PostgrestException) {
        final code = e.code ?? '';
        final msg = (e.message).toLowerCase();

        // Unique violation (e.g., double-booking the same slot)
        if (code == '23505') {
          return 'This action is not allowed: record already exists (likely already booked).';
        }

        // Custom trigger message for overlapping slots
        if (msg.contains('overlapping availability slot')) {
          return 'This slot overlaps with an existing one.';
        }

        if (msg.contains('booking_slot_in_past')) {
          return 'This slot is no longer available.';
        }

        if (msg.contains('booking_slot_unavailable')) {
          return 'This slot is no longer available.';
        }

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

        // Generic postgrest message
        return e.message;
      }

      if (e is AuthException) {
        return e.message;
      }

      return e.toString();
    } catch (_) {
      return e.toString();
    }
  }

  String? _mapServiceError(String? error) {
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
    return error;
  }

  // Bookings state
  bool bookingsLoading = false;
  String? bookingsError;
  bool clientBookingsLoading = false;
  bool providerBookingsLoading = false;
  String? clientBookingsError;
  String? providerBookingsError;
  final List<BookingModel> bookingsAsClient = [];
  final List<BookingModel> bookingsAsProvider = [];
  String? bookingsClientCursor; // ISO string of last created_at
  String? bookingsProviderCursor; // ISO string of last created_at

  /// Fetch a single booking by ID (for details screen/deep linking).
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final data = await _repo.getBookingById(bookingId);
      return data;
    } catch (e) {
      AppLogger.e('Failed to get booking $bookingId', tag: 'Booking', error: e);
      return null;
    }
  }

  Future<bool> waitForBookingPaymentHeld({
    required String bookingId,
    Duration timeout = const Duration(seconds: 60),
    Duration interval = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        await Future.delayed(interval);
        continue;
      }

      if (booking.paymentStatus == PaymentStatus.held) {
        return true;
      }

      // If it reached a terminal failure state, stop polling early.
      if (booking.paymentStatus == PaymentStatus.refunded ||
          booking.status == BookingStatus.canceled ||
          booking.status == BookingStatus.refunded) {
        return false;
      }

      await Future.delayed(interval);
    }

    return false;
  }

  Future<void> cancelBookingDraftIfUnpaid(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) return;
      if (booking.status != BookingStatus.pending ||
          booking.paymentStatus != PaymentStatus.unpaid) {
        return;
      }

      await updateBookingStatus(
        bookingId: bookingId,
        newStatus: BookingStatus.canceled,
      );
      AppLogger.i(
        'Canceled orphan unpaid booking draft: $bookingId',
        tag: 'Booking',
      );
    } catch (e) {
      AppLogger.w(
        'Failed to cancel unpaid draft booking=$bookingId',
        tag: 'Booking',
        error: e,
      );
    }
  }

  /// Escrow hold for a pending booking (Client)
  Future<void> escrowHoldBooking(String bookingId) async {
    try {
      await _repo.escrowHoldBooking(bookingId);
      // ✅ Refresh the booking to get updated payment_status
      await _refreshBookingInLists(bookingId);
      notifyListeners();
    } catch (e, st) {
      bookingsError = _mapError(e);
      AppLogger.e(
        'Failed to hold escrow for booking $bookingId',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      notifyListeners();
    }
  }

  /// Internal helper to refresh a booking in the in-memory lists
  Future<void> _refreshBookingInLists(String bookingId) async {
    try {
      final updated = await _repo.getBookingById(bookingId);

      // Update in client list
      final clientIdx = bookingsAsClient.indexWhere((b) => b.id == bookingId);
      if (clientIdx != -1) {
        bookingsAsClient[clientIdx] = updated;
      }

      // Update in provider list
      final providerIdx = bookingsAsProvider.indexWhere(
        (b) => b.id == bookingId,
      );
      if (providerIdx != -1) {
        bookingsAsProvider[providerIdx] = updated;
      }
    } catch (e) {
      AppLogger.w(
        'Failed to refresh booking $bookingId',
        tag: 'Booking',
        error: e,
      );
    }
  }

  /// Release funds for a delivered booking (Client).
  Future<void> releaseBookingWithFee(String bookingId) async {
    try {
      // ✅ Validate booking is delivered and payment is held before release
      final booking = await _repo.getBookingById(bookingId);

      if (booking.status != BookingStatus.delivered) {
        throw Exception('Booking must be delivered before releasing funds');
      }

      if (booking.paymentStatus != PaymentStatus.held) {
        throw Exception('Payment must be held before releasing');
      }

      // Current user must be the client
      if (currentUserId == null || currentUserId != booking.clientId) {
        throw Exception('Only the client can release funds');
      }

      await _repo.releaseBookingWithFee(bookingId);
      // Optimistic update - refresh to get accurate state
      await _refreshBookingInLists(bookingId);
    } catch (e, st) {
      bookingsError = _mapError(e);
      AppLogger.e(
        'Failed to release funds for booking $bookingId',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      notifyListeners();
    }
  }

  /// Accept booking (Provider).
  Future<void> acceptBooking(String bookingId) async {
    try {
      await updateBookingStatus(
        bookingId: bookingId,
        newStatus: BookingStatus.active,
      );
    } catch (e, st) {
      bookingsError = _mapError(e);
      AppLogger.e(
        'Failed to accept booking $bookingId',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      notifyListeners();
    }
  }

  /// Decline booking (Provider).
  ///
  /// This operation is atomic at the database level via RPC to avoid race conditions.
  Future<void> declineBooking(String bookingId) async {
    try {
      final result = await _paymentService.declineAndRefundBooking(
        bookingId: bookingId,
        reason: 'Booking declined',
      );
      if (!result.isSuccess) {
        throw Exception(result.error ?? 'Booking decline/refund failed');
      }

      // Refresh the booking state to reflect the refund
      await _refreshBookingInLists(bookingId);
      notifyListeners();
    } catch (e, st) {
      bookingsError = _mapError(e);
      AppLogger.e(
        'Failed to decline booking $bookingId',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      notifyListeners();
    }
  }

  /// Mark booking as delivered (Provider).
  Future<void> markDelivered(String bookingId) async {
    try {
      await _repo.markDelivered(bookingId);
      await _refreshBookingInLists(bookingId);
      notifyListeners();
    } catch (e, st) {
      bookingsError = _mapError(e);
      AppLogger.e(
        'Failed to mark booking $bookingId as delivered',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      notifyListeners();
    }
  }

  // Payment state
  bool _isProcessingPayment = false;
  bool get isProcessingPayment => _isProcessingPayment;

  /// Process a payment through the payment service.
  Future<String?> processPayment({
    required double amount,
    required String currency,
    required String description,
  }) async {
    _isProcessingPayment = true;
    bookingsError = null;
    notifyListeners();
    try {
      final txnId = await _paymentService.processPayment(
        amount: amount,
        currency: currency,
        description: description,
      );
      return txnId;
    } catch (e) {
      bookingsError = _mapError(e);
      AppLogger.e('Payment failed', tag: 'Booking', error: e);
      notifyListeners();
      return null;
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }

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

    final result = await _paymentService.initiatePayment(
      amount: amount,
      currency: 'IQD',
      bookingId: bookingId,
      clientId: clientId,
      description: description,
    );

    if (result.error != null) {
      bookingsError = result.error;
      notifyListeners();
    }

    return result;
  }

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

  Future<QiCardCreatePaymentResult> createPaymentForBooking({
    required String taskId,
    String? note,
    String? packageId,
    Map<String, dynamic>? requirements,
  }) async {
    final requestCorrelationId = 'booking_create:${_uuid.v4()}';
    AppLogger.i(
      'Requesting server-backed booking payment task=$taskId package=${packageId ?? 'none'}',
      tag: 'Booking',
      json: <String, dynamic>{
        'task_id': taskId,
        'package_id': packageId,
        'has_note': note != null && note.trim().isNotEmpty,
        'requirements_keys': (requirements ?? const <String, dynamic>{}).keys
            .toList(),
        'request_correlation_id': requestCorrelationId,
      },
    );
    final result = await _paymentService.createPaymentForBooking(
      taskId: taskId,
      note: note,
      packageId: packageId,
      requirements: requirements,
      requestCorrelationId: requestCorrelationId,
    );

    if (!result.isSuccess) {
      bookingsError = _mapServiceError(result.error);
      AppLogger.w(
        'Booking payment request failed for task=$taskId',
        tag: 'Booking',
        error: bookingsError ?? result.error ?? 'BOOKING_PAYMENT_CREATE_FAILED',
        json: <String, dynamic>{
          'task_id': taskId,
          'request_correlation_id':
              result.requestCorrelationId ?? requestCorrelationId,
        },
      );
      notifyListeners();
    } else {
      AppLogger.i(
        'Booking payment draft created booking=${result.bookingId} correlation=${result.correlationId}',
        tag: 'Booking',
        json: <String, dynamic>{
          'task_id': taskId,
          'request_correlation_id':
              result.requestCorrelationId ?? requestCorrelationId,
        },
      );
    }

    return result;
  }

  Future<QiCardRecoveryResult> recoverBookingPayment({
    required String bookingId,
  }) async {
    AppLogger.i(
      'Recovering booking payment booking=$bookingId',
      tag: 'Booking',
    );
    final result = await _paymentService.recoverBookingPayment(
      bookingId: bookingId,
    );

    if (result.isSuccess) {
      await _refreshBookingInLists(bookingId);
      AppLogger.i(
        'Booking payment recovered booking=$bookingId status=${result.paymentStatus} outcome=${result.recoveryResult}',
        tag: 'Booking',
      );
      notifyListeners();
    } else {
      bookingsError = result.error;
      AppLogger.w(
        'Booking payment recovery failed booking=$bookingId',
        tag: 'Booking',
        error: result.error ?? 'BOOKING_PAYMENT_RECOVERY_FAILED',
      );
      notifyListeners();
    }

    return result;
  }

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
        tag: 'Booking',
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

  Future<void> loadBookingsAsClient() async {
    bookingsLoading = true;
    bookingsError = null;
    clientBookingsLoading = true;
    clientBookingsError = null;
    bookingsAsClient.clear();
    bookingsClientCursor = null;
    notifyListeners();
    try {
      final data = await _repo.listBookingsAsClient(limit: _pageSize);
      bookingsAsClient.addAll(data);
      if (data.isNotEmpty) {
        bookingsClientCursor = data.last.createdAtUtc.toUtc().toIso8601String();
      }
      bookingsClientHasMore = data.length == _pageSize;
    } catch (e, st) {
      final message = _mapError(e);
      bookingsError = message;
      clientBookingsError = message;
      AppLogger.e(
        'Failed to load bookings as client',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
    } finally {
      bookingsLoading = false;
      clientBookingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreBookingsAsClient() async {
    if (clientBookingsLoading ||
        bookingsClientCursor == null ||
        !bookingsClientHasMore) {
      return;
    }
    clientBookingsLoading = true;
    notifyListeners();
    try {
      final data = await _repo.listBookingsAsClient(
        cursorCreatedAtIso: bookingsClientCursor,
        limit: _pageSize,
      );
      bookingsAsClient.addAll(data);
      if (data.isNotEmpty) {
        bookingsClientCursor = data.last.createdAtUtc.toUtc().toIso8601String();
      }
      bookingsClientHasMore = data.length == _pageSize;
    } catch (e, st) {
      final message = _mapError(e);
      bookingsError = message;
      clientBookingsError = message;
      AppLogger.e(
        'Failed to load more bookings as client',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
    } finally {
      clientBookingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBookingsAsProvider() async {
    bookingsLoading = true;
    bookingsError = null;
    providerBookingsLoading = true;
    providerBookingsError = null;
    bookingsAsProvider.clear();
    bookingsProviderCursor = null;
    notifyListeners();
    try {
      final data = await _repo.listBookingsAsProvider(limit: _pageSize);
      bookingsAsProvider.addAll(data);
      if (data.isNotEmpty) {
        bookingsProviderCursor = data.last.createdAtUtc
            .toUtc()
            .toIso8601String();
      }
      bookingsProviderHasMore = data.length == _pageSize;
    } catch (e, st) {
      final message = _mapError(e);
      bookingsError = message;
      providerBookingsError = message;
      AppLogger.e(
        'Failed to load bookings as provider',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
    } finally {
      bookingsLoading = false;
      providerBookingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreBookingsAsProvider() async {
    if (providerBookingsLoading ||
        bookingsProviderCursor == null ||
        !bookingsProviderHasMore) {
      return;
    }
    providerBookingsLoading = true;
    notifyListeners();
    try {
      final data = await _repo.listBookingsAsProvider(
        cursorCreatedAtIso: bookingsProviderCursor,
        limit: _pageSize,
      );
      bookingsAsProvider.addAll(data);
      if (data.isNotEmpty) {
        bookingsProviderCursor = data.last.createdAtUtc
            .toUtc()
            .toIso8601String();
      }
      bookingsProviderHasMore = data.length == _pageSize;
    } catch (e, st) {
      final message = _mapError(e);
      bookingsError = message;
      providerBookingsError = message;
      AppLogger.e(
        'Failed to load more bookings as provider',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
    } finally {
      providerBookingsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
  }) async {
    try {
      final updated = await _repo.updateBookingStatus(
        bookingId: bookingId,
        newStatus: newStatus,
      );
      // Update in-memory lists if present
      int idx = bookingsAsClient.indexWhere((e) => e.id == bookingId);
      if (idx != -1) bookingsAsClient[idx] = updated;
      idx = bookingsAsProvider.indexWhere((e) => e.id == bookingId);
      if (idx != -1) bookingsAsProvider[idx] = updated;
      notifyListeners();
      return true;
    } catch (e, st) {
      bookingsError = _mapError(e);
      AppLogger.e(
        'Failed to update booking $bookingId status to $newStatus',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      notifyListeners();
      return false;
    }
  }

  // Separate state for contacting provider
  bool _isContactingProvider = false;
  bool get isContactingProvider => _isContactingProvider;

  // --- Chat Integration ---

  Future<Conversation?> contactProvider(
    BookingModel booking,
    String currentUserId,
  ) async {
    try {
      _isContactingProvider = true;
      notifyListeners();

      // We pass the CLIENT ID and FREELANCER ID explicitly to startConversationByClient.
      // If current user is Provider, then 'clientId' is the other guy.
      // If current user is Client, then 'clientId' is ME.

      final String realClientId = booking.clientId;
      final String realProviderId = booking.providerId;

      final conversation = await _chatRepository.startConversationByClient(
        taskId: booking.taskId,
        clientId: realClientId,
        freelancerId: realProviderId,
      );

      return conversation;
    } catch (e, st) {
      bookingsError = _mapError(e);
      AppLogger.e(
        'Failed to contact provider for booking ${booking.id}',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      notifyListeners();
      return null;
    } finally {
      _isContactingProvider = false;
      notifyListeners();
    }
  }
}
