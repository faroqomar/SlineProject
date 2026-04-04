import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../../booking/models/booking_model.dart';
import '../../booking/services/booking_service.dart';

/// Delegate that owns booking state and booking-related actions
/// for [DashboardViewModel].
class DashboardBookingDelegate {
  static const _kTag = 'dashboard.bookings';

  final BookingService _bookingService;
  final VoidCallback _onChanged;
  final bool Function() _isDisposed;

  DashboardBookingDelegate({
    required BookingService bookingService,
    required VoidCallback onChanged,
    required bool Function() isDisposed,
  }) : _bookingService = bookingService,
       _onChanged = onChanged,
       _isDisposed = isDisposed;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<BookingModel> _bookings = [];
  List<BookingModel> get bookings => UnmodifiableListView(_bookings);

  BookingStatus? _bookingFilter;
  BookingStatus? get bookingFilter => _bookingFilter;

  bool _bookingsLoaded = false;
  bool get bookingsLoaded => _bookingsLoaded;

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  void clear() {
    _bookings = [];
    _bookingsLoaded = false;
    _bookingFilter = null;
  }

  /// Sets bookings from an external source (parent VM's _loadData).
  void setBookings(List<BookingModel> bookings) {
    _bookings = bookings.toList(); // defensive copy
    _bookingsLoaded = true;
  }

  /// Lazy-loads booking data when bookings tab is first shown.
  Future<void> loadBookingsData(UserRole currentRole) async {
    if (_bookingsLoaded) return;
    try {
      final result = await _fetchBookingsInternal(currentRole);
      _bookings = result;
      _bookingsLoaded = true;
      AppLogger.d('Bookings tab data loaded', tag: _kTag);
      if (!_isDisposed()) _onChanged();
    } on Exception catch (e) {
      // Do NOT set _bookingsLoaded = true on failure — allows retry.
      AppLogger.e('Failed to load bookings', error: e, tag: _kTag);
      if (!_isDisposed()) _onChanged();
    }
  }

  /// Returns bookings for Future.wait usage (does not assign).
  Future<List<BookingModel>> fetchBookingsInternal(UserRole currentRole) =>
      _fetchBookingsInternal(currentRole);

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void setBookingFilter(BookingStatus? status) {
    if (_bookingFilter == status) return;
    _bookingFilter = status;
    if (!_isDisposed()) _onChanged();
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      final updated = await _bookingService.updateBookingStatus(
        bookingId: bookingId,
        newStatus: status,
      );
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = updated;
        AppLogger.i('Updated booking=$bookingId to ${status.name}', tag: _kTag);
        if (!_isDisposed()) _onChanged();
      }
    } on Exception catch (e) {
      AppLogger.e('Failed to update booking=$bookingId', error: e, tag: _kTag);
      rethrow;
    }
  }

  Future<void> acceptBooking(String bookingId) async {
    try {
      await _bookingService.acceptBooking(bookingId);
      _updateLocalBookingStatus(bookingId, BookingStatus.confirmed);
      AppLogger.i('Accepted booking=$bookingId', tag: _kTag);
      if (!_isDisposed()) _onChanged();
    } on Exception catch (e) {
      AppLogger.e('Failed to accept booking=$bookingId', error: e, tag: _kTag);
      rethrow;
    }
  }

  Future<void> declineBooking(String bookingId) async {
    try {
      await _bookingService.declineBooking(bookingId);
      _updateLocalBookingStatus(bookingId, BookingStatus.canceled);
      AppLogger.i('Declined booking=$bookingId', tag: _kTag);
      if (!_isDisposed()) _onChanged();
    } on Exception catch (e) {
      AppLogger.e('Failed to decline booking=$bookingId', error: e, tag: _kTag);
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _bookingService.updateBookingStatus(
        bookingId: bookingId,
        newStatus: BookingStatus.canceled,
      );
      _updateLocalBookingStatus(bookingId, BookingStatus.canceled);
      AppLogger.i('Canceled booking=$bookingId', tag: _kTag);
      if (!_isDisposed()) _onChanged();
    } on Exception catch (e) {
      AppLogger.e('Failed to cancel booking=$bookingId', error: e, tag: _kTag);
      rethrow;
    }
  }

  /// Updates the local booking status without a network call.
  void _updateLocalBookingStatus(String bookingId, BookingStatus status) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: status);
    }
  }

  // ---------------------------------------------------------------------------
  // Internal fetcher
  // ---------------------------------------------------------------------------

  Future<List<BookingModel>> _fetchBookingsInternal(UserRole currentRole) {
    if (currentRole == UserRole.freelancer) {
      return _bookingService.listBookingsAsProvider(limit: 50);
    } else {
      return _bookingService.listBookingsAsClient(limit: 50);
    }
  }
}
