import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/app_enums.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

/// Repository layer for Booking feature.
/// Encapsulates data access via BookingService and provides a stable
/// interface to higher layers (ViewModels / Controllers).
class BookingRepository {
  BookingRepository(SupabaseClient client)
    : _service = BookingService(client),
      _client = client;

  final BookingService _service;
  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<List<SlotModel>> listSlots({
    required String providerId,
    DateTime? fromUtc,
    DateTime? toUtc,
    int limit = 50,
    String? cursorStartsAtIso,
  }) {
    return _service.listSlots(
      providerId: providerId,
      fromUtc: fromUtc,
      toUtc: toUtc,
      limit: limit,
      cursorStartsAtIso: cursorStartsAtIso,
    );
  }

  Future<SlotModel> createSlot({
    required DateTime startsAtUtc,
    required DateTime endsAtUtc,
    bool isBlocked = false,
  }) {
    return _service.createSlot(
      startsAtUtc: startsAtUtc,
      endsAtUtc: endsAtUtc,
      isBlocked: isBlocked,
    );
  }

  Future<BookingModel> bookSlot({
    required String taskId,
    required String slotId,
    String? note,
    required String providerId,
    required double price,
    String? packageId,
    Map<String, dynamic>? requirements,
    BookingStatus status = BookingStatus.pending,
  }) {
    return _service.bookSlot(
      taskId: taskId,
      slotId: slotId,
      note: note,
      providerId: providerId,
      price: price,
      packageId: packageId,
      requirements: requirements,
      status: status,
    );
  }

  Future<BookingModel> createBookingDraft({
    required String taskId,
    required String slotId,
    String? note,
    required String providerId,
    required double price,
    String? packageId,
    Map<String, dynamic>? requirements,
    BookingStatus status = BookingStatus.pending,
  }) {
    return _service.createBookingDraft(
      taskId: taskId,
      slotId: slotId,
      note: note,
      providerId: providerId,
      price: price,
      packageId: packageId,
      requirements: requirements,
      status: status,
    );
  }

  Future<List<BookingModel>> listBookingsAsClient({
    int limit = 50,
    String? cursorCreatedAtIso,
  }) {
    return _service.listBookingsAsClient(
      limit: limit,
      cursorCreatedAtIso: cursorCreatedAtIso,
    );
  }

  Future<List<BookingModel>> listBookingsAsProvider({
    int limit = 50,
    String? cursorCreatedAtIso,
  }) {
    return _service.listBookingsAsProvider(
      limit: limit,
      cursorCreatedAtIso: cursorCreatedAtIso,
    );
  }

  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
  }) {
    return _service.updateBookingStatus(
      bookingId: bookingId,
      newStatus: newStatus,
    );
  }

  Future<BookingModel> getBookingById(String bookingId) {
    return _service.getBookingById(bookingId);
  }

  Future<void> escrowHoldBooking(String bookingId) {
    return _service.escrowHoldBooking(bookingId);
  }

  Future<void> releaseBookingWithFee(String bookingId) {
    return _service.approveAndRelease(bookingId);
  }

  Future<void> declineBooking(String bookingId) {
    return _service.declineBooking(bookingId);
  }

  Future<void> markDelivered(String bookingId) {
    return _service.markDelivered(bookingId);
  }
}
