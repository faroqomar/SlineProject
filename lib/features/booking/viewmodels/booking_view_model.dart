import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
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
  BookingViewModel({SupabaseClient? client, PaymentService? paymentService})
    : _repo = BookingRepository(client ?? Supabase.instance.client),
      _paymentService = paymentService ?? DemoPaymentService();

  final BookingRepository _repo;
  final PaymentService _paymentService;

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
    String? note,
  }) async {
    try {
      final b = await _repo.bookSlot(
        taskId: taskId,
        slotId: slotId,
        note: note,
        providerId: providerId,
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
}
