import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

/// ChangeNotifier that holds UI state for booking/slots screens.
class BookingController extends ChangeNotifier {
  BookingController({SupabaseClient? client})
      : _svc = BookingService(client ?? Supabase.instance.client);

  final BookingService _svc;

  static const int _pageSize = 50;

  // Pagination flags
  bool slotsHasMore = true;
  bool bookingsClientHasMore = true;
  bool bookingsProviderHasMore = true;

  String _mapError(Object e) {
    // Friendly messages for common Supabase/Postgres errors
    try {
      if (e is PostgrestException) {
        final code = e.code ?? '';
        final msg = (e.message ?? '').toLowerCase();

        // Unique violation (e.g., double-booking the same slot)
        if (code == '23505') {
          return 'This action is not allowed: record already exists (likely already booked).';
        }

        // Custom trigger message for overlapping slots
        if (msg.contains('overlapping availability slot')) {
          return 'This slot overlaps with an existing one.';
        }

        // Generic postgrest message
        return e.message ?? 'Unexpected server error';
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
  Future<void> loadSlots({required String providerId, DateTime? fromUtc, DateTime? toUtc}) async {
    slotsLoading = true;
    slotsError = null;
    slots.clear();
    slotsCursor = null;
    notifyListeners();
    try {
      final data = await _svc.listSlots(
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
    } catch (e) {
      slotsError = _mapError(e);
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
      final data = await _svc.listSlots(
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
      final slot = await _svc.createSlot(
        startsAtUtc: startsAtUtc,
        endsAtUtc: endsAtUtc,
        isBlocked: isBlocked,
      );
      // Refresh first page if we are looking at the same provider
      if (providerIdForRefresh != null) {
        await loadSlots(providerId: providerIdForRefresh);
      }
      return slot;
    } catch (e) {
      slotsError = _mapError(e);
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
      final b = await _svc.bookSlot(
        taskId: taskId,
        slotId: slotId,
        note: note,
        providerId: providerId,
      );
      // Optimistically prepend to client list
      bookingsAsClient.insert(0, b);
      notifyListeners();
      return b;
    } catch (e) {
      bookingsError = _mapError(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> loadBookingsAsClient() async {
    bookingsLoading = true;
    bookingsError = null;
    bookingsAsClient.clear();
    bookingsClientCursor = null;
    notifyListeners();
    try {
      final data = await _svc.listBookingsAsClient(limit: _pageSize);
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
    if (bookingsLoading || bookingsClientCursor == null || !bookingsClientHasMore) return;
    bookingsLoading = true;
    notifyListeners();
    try {
      final data = await _svc.listBookingsAsClient(
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
      final data = await _svc.listBookingsAsProvider(limit: _pageSize);
      bookingsAsProvider.addAll(data);
      if (data.isNotEmpty) {
        bookingsProviderCursor = data.last.createdAtUtc.toUtc().toIso8601String();
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
    if (bookingsLoading || bookingsProviderCursor == null || !bookingsProviderHasMore) return;
    bookingsLoading = true;
    notifyListeners();
    try {
      final data = await _svc.listBookingsAsProvider(
        cursorCreatedAtIso: bookingsProviderCursor,
        limit: _pageSize,
      );
      bookingsAsProvider.addAll(data);
      if (data.isNotEmpty) {
        bookingsProviderCursor = data.last.createdAtUtc.toUtc().toIso8601String();
      }
      bookingsProviderHasMore = data.length == _pageSize;
    } catch (e) {
      bookingsError = _mapError(e);
    } finally {
      bookingsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBookingStatus({required String bookingId, required BookingStatus newStatus}) async {
    try {
      final updated = await _svc.updateBookingStatus(bookingId: bookingId, newStatus: newStatus);
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
