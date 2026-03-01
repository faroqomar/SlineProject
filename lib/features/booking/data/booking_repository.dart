import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/services/booking_service.dart';

/// Repository layer for Booking feature.
class BookingRepository {
  BookingRepository(SupabaseClient client)
    : _service = BookingService(client),
      _client = client;

  final BookingService _service;
  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

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

  Future<void> acceptBooking(String bookingId) {
    return _service.acceptBooking(bookingId);
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
