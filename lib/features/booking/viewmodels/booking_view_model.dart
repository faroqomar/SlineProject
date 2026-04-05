import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/models/app_failure.dart';
import 'package:sline_app/core/models/view_state.dart';
import 'package:sline_app/core/services/demo_payment_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/features/booking/data/booking_repository.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/viewmodels/booking_payment_delegate.dart';
import 'package:sline_app/features/chat/data/chat_repository.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart'; // Added
import 'package:supabase_flutter/supabase_flutter.dart';

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
       _paymentService = paymentService ?? DemoPaymentService(),
       _paymentDelegate = BookingPaymentDelegate(
         repo: repo,
         paymentService: paymentService ?? DemoPaymentService(),
       );

  final BookingRepository _repo;
  final ChatRepository _chatRepository;
  final PaymentService _paymentService;
  final BookingPaymentDelegate _paymentDelegate;

  /// Whether the active payment service is the demo (non-production) implementation.
  bool get isDemoPaymentMode => _paymentService is DemoPaymentService;

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
        final msg = e.message.toLowerCase();

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

        if (msg.contains('client payment is still pending')) {
          return 'Client payment is still pending.';
        }

        if (msg.contains('booking_package_invalid')) {
          return 'The selected package is no longer available.';
        }
      }

      final genericMessage = e.toString();
      if (genericMessage.toLowerCase().contains(
        'client payment is still pending',
      )) {
        return 'Client payment is still pending.';
      }

      // Delegate to ErrorMapper for all remaining cases (PostgrestException
      // generic fallback, AuthException, and unknown exceptions).
      return ErrorMapper.map(e);
    } on Exception catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ── Primary list states (ViewState pattern) ───────────────────────
  ViewState<List<BookingModel>> _clientListState = const ViewInitial();
  ViewState<List<BookingModel>> _providerListState = const ViewInitial();

  ViewState<List<BookingModel>> get clientListState => _clientListState;
  ViewState<List<BookingModel>> get providerListState => _providerListState;

  // ── Shared action error (accept, decline, payment, etc.) ─────────
  /// Per-action error used by operations that mutate a single booking.
  /// NOT migrated to ViewState because many independent operations share it.
  String? bookingsError;

  // ── Backward-compatible convenience getters (keep view working) ──
  bool get bookingsLoading =>
      _clientListState is ViewLoading<List<BookingModel>> ||
      _providerListState is ViewLoading<List<BookingModel>>;

  bool get clientBookingsLoading =>
      _clientListState is ViewLoading<List<BookingModel>>;

  bool get providerBookingsLoading =>
      _providerListState is ViewLoading<List<BookingModel>>;

  String? get clientBookingsError => switch (_clientListState) {
    ViewFailed(:final failure) => failure.userMessage,
    _ => null,
  };

  String? get providerBookingsError => switch (_providerListState) {
    ViewFailed(:final failure) => failure.userMessage,
    _ => null,
  };

  List<BookingModel> get bookingsAsClient => switch (_clientListState) {
    ViewLoaded(:final data) => data,
    _ => _clientListMutable,
  };

  List<BookingModel> get bookingsAsProvider => switch (_providerListState) {
    ViewLoaded(:final data) => data,
    _ => _providerListMutable,
  };

  // Mutable backing lists used during loading/pagination to accumulate data.
  final List<BookingModel> _clientListMutable = [];
  final List<BookingModel> _providerListMutable = [];

  /// Seed the provider list for testing. Emits [ViewLoaded] with the given items.
  @visibleForTesting
  void seedProviderList(List<BookingModel> items) {
    _providerListMutable
      ..clear()
      ..addAll(items);
    _providerListState = ViewLoaded(List<BookingModel>.of(items));
  }

  /// Seed the client list for testing. Emits [ViewLoaded] with the given items.
  @visibleForTesting
  void seedClientList(List<BookingModel> items) {
    _clientListMutable
      ..clear()
      ..addAll(items);
    _clientListState = ViewLoaded(List<BookingModel>.of(items));
  }

  String? bookingsClientCursor; // ISO string of last created_at
  String? bookingsProviderCursor; // ISO string of last created_at

  /// Fetch a single booking by ID (for details screen/deep linking).
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final data = await _repo.getBookingById(bookingId);
      return data;
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e, st) {
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

      // Update in client mutable list and re-emit ViewLoaded
      final clientIdx = _clientListMutable.indexWhere((b) => b.id == bookingId);
      if (clientIdx != -1) {
        _clientListMutable[clientIdx] = updated;
        _clientListState = ViewLoaded(
          List<BookingModel>.of(_clientListMutable),
        );
      }

      // Update in provider mutable list and re-emit ViewLoaded
      final providerIdx = _providerListMutable.indexWhere(
        (b) => b.id == bookingId,
      );
      if (providerIdx != -1) {
        _providerListMutable[providerIdx] = updated;
        _providerListState = ViewLoaded(
          List<BookingModel>.of(_providerListMutable),
        );
      }
    } on Exception catch (e) {
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
    } on Exception catch (e, st) {
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
      await _repo.acceptBooking(bookingId);
      await _refreshBookingInLists(bookingId);
      notifyListeners();
    } on Exception catch (e, st) {
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
      final result = await _paymentDelegate.declineAndRefundBooking(
        bookingId: bookingId,
        reason: 'Booking declined',
      );
      if (!result.isSuccess) {
        throw Exception(result.error ?? 'Booking decline/refund failed');
      }
      await _refreshBookingInLists(bookingId);
      notifyListeners();
    } on Exception catch (e, st) {
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
    } on Exception catch (e, st) {
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
      return await _paymentDelegate.processPayment(
        amount: amount,
        currency: currency,
        description: description,
      );
    } on Exception catch (e) {
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
    final result = await _paymentDelegate.initiateQiCardPayment(
      amount: amount,
      bookingId: bookingId,
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
  }) => _paymentDelegate.triggerQiCardSuccessRecovery(
    bookingId: bookingId,
    paymentId: paymentId,
    requestId: requestId,
    amount: amount,
  );

  Future<QiCardCreatePaymentResult> createPaymentForBooking({
    required String taskId,
    String? note,
    String? packageId,
    Map<String, dynamic>? requirements,
    String? finishUrl,
  }) async {
    try {
      final result = await _paymentDelegate.createPaymentForBooking(
        taskId: taskId,
        note: note,
        packageId: packageId,
        requirements: requirements,
        finishUrl: finishUrl,
      );
      if (result.error != null) {
        bookingsError = BookingPaymentDelegate.mapServiceError(result.error);
        notifyListeners();
      }
      return result;
    } on Exception catch (e, st) {
      AppLogger.e(
        'createPaymentForBooking failed',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      bookingsError = _mapError(e);
      notifyListeners();
      return QiCardCreatePaymentResult(
        error: bookingsError,
        errorCode: 'BOOKING_PAYMENT_CREATE_FAILED',
      );
    }
  }

  /// Streams the status of a payment intent directly from the database.
  Stream<String> streamPaymentIntentStatus(String intentId) =>
      _paymentDelegate.streamPaymentIntentStatus(intentId);

  Future<QiCardRecoveryResult> recoverBookingPayment({
    required String bookingId,
  }) async {
    final result = await _paymentDelegate.recoverBookingPayment(
      bookingId: bookingId,
    );
    if (result.isSuccess) {
      await _refreshBookingInLists(bookingId);
      AppLogger.i(
        'Booking payment recovered booking=$bookingId status=${result.paymentStatus} outcome=${result.recoveryResult}',
        tag: 'Booking',
      );
    } else {
      bookingsError = result.error;
      AppLogger.w(
        'Booking payment recovery failed booking=$bookingId',
        tag: 'Booking',
        error: result.error ?? 'BOOKING_PAYMENT_RECOVERY_FAILED',
      );
    }
    notifyListeners();
    return result;
  }

  /// Retries recovery up to [maxAttempts] when the server returns `no_action`.
  /// Each attempt refreshes lists and notifies listeners via [recoverBookingPayment].
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
      await Future.delayed(delay);
      result = await recoverBookingPayment(bookingId: bookingId);
      attempt += 1;
    }
    return result;
  }

  Future<void> loadBookingsAsClient() async {
    _clientListState = const ViewLoading();
    bookingsError = null;
    _clientListMutable.clear();
    bookingsClientCursor = null;
    notifyListeners();
    try {
      final data = await _repo.listBookingsAsClient(limit: _pageSize);
      _clientListMutable.addAll(data);
      if (data.isNotEmpty) {
        bookingsClientCursor = data.last.createdAtUtc.toUtc().toIso8601String();
      }
      bookingsClientHasMore = data.length == _pageSize;
      _clientListState = ViewLoaded(List<BookingModel>.of(_clientListMutable));
    } on Exception catch (e, st) {
      final message = _mapError(e);
      bookingsError = message;
      _clientListState = ViewFailed(
        BusinessFailure(message, code: 'CLIENT_BOOKINGS_LOAD_FAILED'),
      );
      AppLogger.e(
        'Failed to load bookings as client',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMoreBookingsAsClient() async {
    if (clientBookingsLoading ||
        bookingsClientCursor == null ||
        !bookingsClientHasMore) {
      return;
    }
    // Keep existing data visible while loading more (no state transition to Loading).
    notifyListeners();
    try {
      final data = await _repo.listBookingsAsClient(
        cursorCreatedAtIso: bookingsClientCursor,
        limit: _pageSize,
      );
      _clientListMutable.addAll(data);
      if (data.isNotEmpty) {
        bookingsClientCursor = data.last.createdAtUtc.toUtc().toIso8601String();
      }
      bookingsClientHasMore = data.length == _pageSize;
      _clientListState = ViewLoaded(List<BookingModel>.of(_clientListMutable));
    } on Exception catch (e, st) {
      final message = _mapError(e);
      bookingsError = message;
      // Keep existing data; do not transition to ViewFailed for pagination.
      AppLogger.e(
        'Failed to load more bookings as client',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadBookingsAsProvider() async {
    _providerListState = const ViewLoading();
    bookingsError = null;
    _providerListMutable.clear();
    bookingsProviderCursor = null;
    notifyListeners();
    try {
      final data = await _repo.listBookingsAsProvider(limit: _pageSize);
      _providerListMutable.addAll(data);
      if (data.isNotEmpty) {
        bookingsProviderCursor = data.last.createdAtUtc
            .toUtc()
            .toIso8601String();
      }
      bookingsProviderHasMore = data.length == _pageSize;
      _providerListState = ViewLoaded(
        List<BookingModel>.of(_providerListMutable),
      );
    } on Exception catch (e, st) {
      final message = _mapError(e);
      bookingsError = message;
      _providerListState = ViewFailed(
        BusinessFailure(message, code: 'PROVIDER_BOOKINGS_LOAD_FAILED'),
      );
      AppLogger.e(
        'Failed to load bookings as provider',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMoreBookingsAsProvider() async {
    if (providerBookingsLoading ||
        bookingsProviderCursor == null ||
        !bookingsProviderHasMore) {
      return;
    }
    // Keep existing data visible while loading more (no state transition to Loading).
    notifyListeners();
    try {
      final data = await _repo.listBookingsAsProvider(
        cursorCreatedAtIso: bookingsProviderCursor,
        limit: _pageSize,
      );
      _providerListMutable.addAll(data);
      if (data.isNotEmpty) {
        bookingsProviderCursor = data.last.createdAtUtc
            .toUtc()
            .toIso8601String();
      }
      bookingsProviderHasMore = data.length == _pageSize;
      _providerListState = ViewLoaded(
        List<BookingModel>.of(_providerListMutable),
      );
    } on Exception catch (e, st) {
      final message = _mapError(e);
      bookingsError = message;
      // Keep existing data; do not transition to ViewFailed for pagination.
      AppLogger.e(
        'Failed to load more bookings as provider',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
    } finally {
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
      // Update in mutable backing lists and re-emit ViewLoaded
      var idx = _clientListMutable.indexWhere((e) => e.id == bookingId);
      if (idx != -1) {
        _clientListMutable[idx] = updated;
        _clientListState = ViewLoaded(
          List<BookingModel>.of(_clientListMutable),
        );
      }
      idx = _providerListMutable.indexWhere((e) => e.id == bookingId);
      if (idx != -1) {
        _providerListMutable[idx] = updated;
        _providerListState = ViewLoaded(
          List<BookingModel>.of(_providerListMutable),
        );
      }
      notifyListeners();
      return true;
    } on Exception catch (e, st) {
      bookingsError = _mapError(e);
      // Guard block (client cancel after delivery) is expected; do not report as crash
      if (e is StateError) {
        AppLogger.w(
          'Booking status update rejected (guard)',
          tag: 'Booking',
          error: e,
        );
      } else {
        AppLogger.e(
          'Failed to update booking $bookingId status to $newStatus',
          error: e,
          stackTrace: st,
          tag: 'Booking',
        );
      }
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

      final realClientId = booking.clientId;
      final realProviderId = booking.providerId;

      final conversation = await _chatRepository.startConversationByClient(
        taskId: booking.taskId,
        clientId: realClientId,
        freelancerId: realProviderId,
      );

      return conversation;
    } on Exception catch (e, st) {
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
