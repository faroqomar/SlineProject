import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
import 'package:sline_app/core/app_enums.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/models/conversation_model.dart'; // Added
import '../data/booking_repository.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/services/demo_payment_service.dart';

/// BookingViewModel — MVVM state holder for Booking/Scheduling feature.
///
/// This ViewModel demonstrates several BEST PRACTICES that should be
/// followed across the codebase:
///
/// 1. **Cursor-Based Pagination**: Uses ISO timestamps as cursors instead of
///    offsets. This is more efficient and handles concurrent updates correctly.
///    See `slotsCursor`, `bookingsClientCursor`, `bookingsProviderCursor`.
///
/// 2. **User-Friendly Error Mapping**: The `_mapError()` method translates
///    technical Supabase/Postgres errors into readable messages.
///    Error code 23505 = unique violation = "already booked"
///
/// 3. **Optimistic Updates**: After `bookSlot()`, the new booking is immediately
///    prepended to `bookingsAsClient` without waiting for a refetch.
///
/// 4. **Separate Loading States**: Each data type has its own loading flag
///    (`slotsLoading`, `bookingsLoading`) to prevent UI flicker.
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
  String get paymentServiceType => _paymentService.runtimeType.toString();

  static const int _pageSize = 50;

  /// Expose current authenticated user id for UI decisions when needed.
  String? get currentUserId => _repo.currentUser?.id;

  // Pagination flags
  bool slotsHasMore = true;
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

  // Slots state
  bool slotsLoading = false;
  String? slotsError;
  final List<SlotModel> slots = [];
  String? slotsCursor; // ISO string of last starts_at

  // Bookings state
  bool bookingsLoading = false;
  String? bookingsError;
  final List<BookingModel> bookingsAsClient = [];
  final List<BookingModel> bookingsAsProvider = [];
  String? bookingsClientCursor; // ISO string of last created_at
  String? bookingsProviderCursor; // ISO string of last created_at

  // Optional filters
  DateTimeRange? slotsRange;

  /// Load first page of slots for a provider.
  Future<void> loadSlots({
    required String providerId,
    DateTime? fromUtc,
    DateTime? toUtc,
  }) async {
    slotsLoading = true;
    slotsError = null;
    slots.clear();
    slotsCursor = null;
    notifyListeners();
    try {
      final data = await _repo.listSlots(
        providerId: providerId,
        fromUtc: fromUtc,
        toUtc: toUtc,
        limit: _pageSize,
      );
      slots.addAll(data);
      if (data.isNotEmpty) {
        slotsCursor = data.last.startsAtUtc.toUtc().toIso8601String();
      }
      slotsHasMore = data.length == _pageSize;
      AppLogger.i(
        'Loaded ${data.length} slots for provider $providerId',
        tag: 'Booking',
      );
    } catch (e) {
      slotsError = _mapError(e);
      AppLogger.e('Failed to load slots', tag: 'Booking', error: e);
    } finally {
      slotsLoading = false;
      notifyListeners();
    }
  }

  /// Load next page of slots if available.
  Future<void> loadMoreSlots({required String providerId}) async {
    if (slotsLoading || slotsCursor == null || !slotsHasMore) return;
    slotsLoading = true;
    notifyListeners();
    try {
      final data = await _repo.listSlots(
        providerId: providerId,
        cursorStartsAtIso: slotsCursor,
        limit: _pageSize,
      );
      slots.addAll(data);
      if (data.isNotEmpty) {
        slotsCursor = data.last.startsAtUtc.toUtc().toIso8601String();
      }
      slotsHasMore = data.length == _pageSize;
    } catch (e) {
      slotsError = _mapError(e);
      AppLogger.e('Failed to load more slots', tag: 'Booking', error: e);
    } finally {
      slotsLoading = false;
      notifyListeners();
    }
  }

  /// Create a slot as provider (A4 button will call this later).
  Future<SlotModel?> createSlot({
    required DateTime startsAtUtc,
    required DateTime endsAtUtc,
    bool isBlocked = false,
    String? providerIdForRefresh, // optional: refresh list after create
  }) async {
    try {
      final slot = await _repo.createSlot(
        startsAtUtc: startsAtUtc,
        endsAtUtc: endsAtUtc,
        isBlocked: isBlocked,
      );
      // Refresh first page if we are looking at the same provider
      if (providerIdForRefresh != null) {
        await loadSlots(providerId: providerIdForRefresh);
      }
      AppLogger.i('Created slot: ${slot.id}', tag: 'Booking');
      return slot;
    } catch (e) {
      slotsError = _mapError(e);
      AppLogger.e('Failed to create slot', tag: 'Booking', error: e);
      notifyListeners();
      return null;
    }
  }

  /// Book a slot as client.
  Future<BookingModel?> bookSlot({
    required String taskId,
    required String slotId,
    required String providerId,
    required double price,
    String? note,
    String? packageId,
    Map<String, dynamic>? requirements,
    BookingStatus status = BookingStatus.pending,
  }) async {
    try {
      final b = await _repo.bookSlot(
        taskId: taskId,
        slotId: slotId,
        note: note,
        providerId: providerId,
        price: price,
        packageId: packageId,
        requirements: requirements,
        status: status,
      );
      // Optimistically prepend to client list
      bookingsAsClient.insert(0, b);
      AppLogger.i('Booked slot ${b.id} for task $taskId', tag: 'Booking');
      notifyListeners();
      return b;
    } catch (e) {
      bookingsError = _mapError(e);
      AppLogger.e('Failed to book slot', tag: 'Booking', error: e);
      notifyListeners();
      return null;
    }
  }

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
      // Wait to re-fetch or optimistically assume the payment status updated
      // Since booking model currently doesn't reflect payment_status directly in the UI as heavily,
      // we just notify listeners or reload. Ideally we update payment_status in the model.
      notifyListeners();
    } catch (e) {
      bookingsError = _mapError(e);
      notifyListeners();
    }
  }

  /// Release funds for a delivered booking (Client).
  Future<void> releaseBookingWithFee(String bookingId) async {
    try {
      await _repo.releaseBookingWithFee(bookingId);
      // Optimistic update
      await updateBookingStatus(
        bookingId: bookingId,
        newStatus: BookingStatus.completed,
      );
    } catch (e) {
      bookingsError = _mapError(e);
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
    } catch (e) {
      bookingsError = _mapError(e);
      notifyListeners();
    }
  }

  /// Decline booking (Provider).
  Future<void> declineBooking(String bookingId) async {
    try {
      final latest = await _repo.getBookingById(bookingId);
      if (latest.paymentStatus != PaymentStatus.held) {
        final held = await waitForBookingPaymentHeld(bookingId: bookingId);
        if (!held) {
          bookingsError =
              'Payment still processing. Please try again in a moment.';
          notifyListeners();
          return;
        }
      }

      await _repo.declineBooking(bookingId);
      // Optimistic update
      await updateBookingStatus(
        bookingId: bookingId,
        newStatus: BookingStatus.refunded, // Logic sets it to refunded/canceled
      );
    } catch (e) {
      bookingsError = _mapError(e);
      notifyListeners();
    }
  }

  /// Mark booking as delivered (Provider).
  Future<void> markDelivered(String bookingId) async {
    try {
      await _repo.markDelivered(bookingId);
      // Optimistic update handled by updateBookingStatus underneath or manually
      await updateBookingStatus(
        bookingId: bookingId,
        newStatus: BookingStatus.delivered,
      );
    } catch (e) {
      bookingsError = _mapError(e);
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

  /// Creates a pending/unpaid booking row before external payment initialization.
  Future<BookingModel?> createBookingDraft({
    required String taskId,
    required String slotId,
    required String providerId,
    String? note,
    required double price,
    String? packageId,
    Map<String, dynamic>? requirements,
  }) async {
    try {
      final draft = await _repo.createBookingDraft(
        taskId: taskId,
        slotId: slotId,
        providerId: providerId,
        note: note,
        price: price,
        packageId: packageId,
        requirements: requirements,
        status: BookingStatus.pending,
      );
      bookingsAsClient.insert(0, draft);
      notifyListeners();
      return draft;
    } catch (e) {
      bookingsError = _mapError(e);
      AppLogger.e('Failed to create booking draft', tag: 'Booking', error: e);
      notifyListeners();
      return null;
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

  Future<void> loadBookingsAsClient() async {
    bookingsLoading = true;
    bookingsError = null;
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
    } catch (e) {
      bookingsError = _mapError(e);
    } finally {
      bookingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreBookingsAsClient() async {
    if (bookingsLoading ||
        bookingsClientCursor == null ||
        !bookingsClientHasMore) {
      return;
    }
    bookingsLoading = true;
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
    } catch (e) {
      bookingsError = _mapError(e);
    } finally {
      bookingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBookingsAsProvider() async {
    bookingsLoading = true;
    bookingsError = null;
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
    } catch (e) {
      bookingsError = _mapError(e);
    } finally {
      bookingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreBookingsAsProvider() async {
    if (bookingsLoading ||
        bookingsProviderCursor == null ||
        !bookingsProviderHasMore) {
      return;
    }
    bookingsLoading = true;
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
    } catch (e) {
      bookingsError = _mapError(e);
    } finally {
      bookingsLoading = false;
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
    } catch (e) {
      bookingsError = _mapError(e);
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
    } catch (e) {
      bookingsError = _mapError(e);
      notifyListeners();
      return null;
    } finally {
      _isContactingProvider = false;
      notifyListeners();
    }
  }
}
