import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/app_enums.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';
import '../../wallet/services/ledger_service.dart';

/// Low-level service that talks to Supabase (PostgREST) only.
/// No UI state here; RLS is assumed to be enforced by the backend.
class BookingService {
  BookingService(this._client);

  final SupabaseClient _client;

  static const String _slotsTable = 'availability_slots';
  static const String _bookingsTable = 'bookings';

  final NotificationService _notificationService = NotificationService();

  /// List slots by provider and optional time window. Ordered by starts_at ASC.
  Future<List<SlotModel>> listSlots({
    required String providerId,
    DateTime? fromUtc,
    DateTime? toUtc,
    int limit = 50,
    String? cursorStartsAtIso, // simple cursor based on starts_at
  }) async {
    var query = _client
        .from(_slotsTable)
        .select()
        .eq('provider_id', providerId);

    if (fromUtc != null) {
      query = query.gte('starts_at', fromUtc.toUtc().toIso8601String());
    }
    if (toUtc != null) {
      query = query.lte('ends_at', toUtc.toUtc().toIso8601String());
    }
    if (cursorStartsAtIso != null) {
      // naive cursor: fetch where starts_at > lastStartsAt
      query = query.gt('starts_at', cursorStartsAtIso);
    }

    final data = await query.order('starts_at', ascending: true).limit(limit);
    return (data as List<dynamic>)
        .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new slot for the current provider.
  /// RLS policy requires: provider_id = auth.uid().
  Future<SlotModel> createSlot({
    required DateTime startsAtUtc,
    required DateTime endsAtUtc,
    bool isBlocked = false,
  }) async {
    if (!endsAtUtc.isAfter(startsAtUtc)) {
      throw ArgumentError('endsAt must be after startsAt');
    }

    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Not signed in');
    }

    final insert = await _client
        .from(_slotsTable)
        .insert({
          'provider_id': uid, // <-- required by RLS
          'starts_at': startsAtUtc.toUtc().toIso8601String(),
          'ends_at': endsAtUtc.toUtc().toIso8601String(),
          'is_blocked': isBlocked,
        })
        .select()
        .single();

    return SlotModel.fromJson(insert as Map<String, dynamic>);
  }

  /// Book a slot as the current client.
  /// RLS policy requires: client_id = auth.uid().
  Future<BookingModel> createBookingDraft({
    required String taskId,
    required String slotId,
    String? note,
    required String providerId,
    required double price,
    String? packageId,
    Map<String, dynamic>? requirements,
    BookingStatus status = BookingStatus.pending,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Not signed in');
    }

    final res = await _client
        .from(_bookingsTable)
        .insert({
          'task_id': taskId,
          'slot_id': slotId,
          'note': note,
          'provider_id': providerId,
          'client_id': uid,
          'status': _mapStatusToDb(status),
          'payment_status': 'unpaid',
          'price': price,
          'package_id': packageId,
          'requirements': requirements,
        })
        .select()
        .single();

    // Re-fetch to get normalized row (joins/triggers).
    final updatedRes = await _client
        .from(_bookingsTable)
        .select()
        .eq('id', res['id'])
        .single();

    final booking = BookingModel.fromJson(updatedRes as Map<String, dynamic>);

    // Notify Provider
    _notificationService.createNotification(
      userId: providerId,
      title: 'New Booking Request',
      message: 'You have a new booking request for a task.',
      type: NotificationType.booking,
      relatedEntityId: booking.id,
      relatedEntityType: 'booking',
    );

    return booking;
  }

  /// Backward-compatible alias for older call sites.
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
    return createBookingDraft(
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
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final query = _client
        .from(_bookingsTable)
        .select('*, tasks(*), availability_slots(starts_at)')
        .eq('client_id', uid);

    if (cursorCreatedAtIso != null) {
      query.lt('created_at', cursorCreatedAtIso);
    }

    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List<dynamic>)
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// List bookings where the current user is the PROVIDER.
  Future<List<BookingModel>> listBookingsAsProvider({
    int limit = 50,
    String? cursorCreatedAtIso,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final query = _client
        .from(_bookingsTable)
        .select('*, tasks(*), availability_slots(starts_at)')
        .eq('provider_id', uid);

    if (cursorCreatedAtIso != null) {
      query.lt('created_at', cursorCreatedAtIso);
    }

    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List<dynamic>)
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get pending booking requests for the provider (Status: paid_request_pending).
  Future<List<BookingModel>> getPendingRequests({int limit = 50}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final data = await _client
          .from(_bookingsTable)
          .select('*, tasks(*), availability_slots(starts_at)')
          .eq('provider_id', uid)
          .eq('status', 'paid_request_pending')
          .order('created_at', ascending: false)
          .limit(limit);

      return (data as List<dynamic>)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      // Log error but don't crash UI, return empty list
      AppLogger.e(
        'Failed to get pending requests',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      return [];
    }
  }

  /// Update booking status. RLS guards transitions.
  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
  }) async {
    final res = await _client
        .from(_bookingsTable)
        .update({'status': _mapStatusToDb(newStatus)})
        .eq('id', bookingId)
        .select()
        .single();

    final booking = BookingModel.fromJson(res as Map<String, dynamic>);

    // Notify the other party
    final uid = _client.auth.currentUser?.id;
    if (uid != null) {
      String? targetUserId;
      String title = 'Booking Update';
      String message = 'Booking status changed to ${newStatus.name}';

      if (uid == booking.providerId) {
        targetUserId = booking.clientId;
      } else if (uid == booking.clientId) {
        targetUserId = booking.providerId;
      }

      if (targetUserId != null) {
        _notificationService.createNotification(
          userId: targetUserId,
          title: title,
          message: message,
          type: NotificationType.booking,
          relatedEntityId: booking.id,
          relatedEntityType: 'booking',
        );
      }
    }

    return booking;
  }

  /// Get a single booking by ID.
  Future<BookingModel> getBookingById(String bookingId) async {
    final res = await _client
        .from(_bookingsTable)
        .select('*, tasks(*)')
        .eq('id', bookingId)
        .single();
    return BookingModel.fromJson(res);
  }

  /// Escrow hold for booking
  Future<void> escrowHoldBooking(String bookingId) async {
    final booking = await getBookingById(bookingId);
    await LedgerService(_client).submitPaymentEvent(
      eventType: 'escrow_hold',
      relatedEntityType: 'booking',
      relatedEntityId: booking.id,
      amountGross: booking.price ?? 0,
      meta: {},
    );
  }

  /// Approve booking and release funds (RPC).
  Future<void> approveAndRelease(String bookingId) async {
    final booking = await getBookingById(bookingId);

    // Status must be delivered, payment_status held for this to work
    await LedgerService(_client).submitPaymentEvent(
      eventType: 'release_with_fee',
      relatedEntityType: 'booking',
      relatedEntityId: booking.id,
      amountGross: booking.price ?? 0,
      meta: {
        'fee_rate_bps':
            0, // Simplified without fee config for now, or match plan
      },
    );
  }

  /// Decline booking and refund funds.
  /// Usually status is updated to declined FIRST, then refund is issued.
  Future<void> declineBooking(String bookingId) async {
    final booking = await getBookingById(bookingId);

    // The UI must update status to declined before refunding or the RPC handles it?
    // Let's ensure status is declined:
    if (booking.status != BookingStatus.declined) {
      await updateBookingStatus(
        bookingId: booking.id,
        newStatus: BookingStatus.declined,
      );
    }

    await LedgerService(_client).submitPaymentEvent(
      eventType: 'refund',
      relatedEntityType: 'booking',
      relatedEntityId: booking.id,
      amountGross: booking.price ?? 0,
      meta: {},
    );
  }

  Future<void> markDelivered(String bookingId) async {
    await updateBookingStatus(
      bookingId: bookingId,
      newStatus: BookingStatus.delivered,
    );
  }

  /// Accept booking (Provider).
  Future<void> acceptBooking(String bookingId) async {
    await updateBookingStatus(
      bookingId: bookingId,
      newStatus: BookingStatus.active,
    );
  }

  String _mapStatusToDb(BookingStatus status) {
    switch (status) {
      case BookingStatus.paidRequestPending:
        return 'paid_request_pending';
      case BookingStatus.active:
        return 'active';
      case BookingStatus.delivered:
        return 'delivered';
      case BookingStatus.refunded:
        return 'refunded';
      case BookingStatus.expiredUnanswered:
        return 'expired_unanswered';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.noShow:
        return 'no_show';
      case BookingStatus.declined:
        return 'canceled';
      default:
        return status.name;
    }
  }
}
