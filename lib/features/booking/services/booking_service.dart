import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/app_enums.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';

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
    final query = _client
        .from(_slotsTable)
        .select()
        .eq('provider_id', providerId);

    if (fromUtc != null) {
      query.gte('starts_at', fromUtc.toUtc().toIso8601String());
    }
    if (toUtc != null) {
      query.lte('ends_at', toUtc.toUtc().toIso8601String());
    }
    if (cursorStartsAtIso != null) {
      // naive cursor: fetch where starts_at > lastStartsAt
      query.gt('starts_at', cursorStartsAtIso);
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
  Future<BookingModel> bookSlot({
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

    // Process Payment (Escrow)
    // In a real app, we'd wait for Stripe webhook.
    // Here we simulate immediate payment -> escrow.
    await _client.rpc(
      'process_payment_event',
      params: {
        'p_entity_id': res['id'],
        'p_type': 'escrow',
        'p_event': 'booking_creation',
      },
    );

    // Re-fetch to get updated status
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
    } catch (e) {
      // Log error but don't crash UI, return empty list
      // AppLogger.e('Failed to get pending requests', error: e); // Assuming logger usage
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
        .select()
        .eq('id', bookingId)
        .single();
    return BookingModel.fromJson(res);
  }

  /// Approve booking and release funds (RPC).
  Future<void> approveAndRelease(String bookingId) async {
    await _client.rpc(
      'process_payment_event',
      params: {
        'p_entity_id': bookingId,
        'p_type': 'release',
        'p_event': 'provider_approval',
      },
    );
  }

  /// Decline booking and refund funds (RPC).
  Future<void> declineBooking(String bookingId) async {
    await _client.rpc(
      'process_payment_event',
      params: {
        'p_entity_id': bookingId,
        'p_type': 'refund',
        'p_event': 'provider_decline',
      },
    );
  }

  /// Mark booking as delivered (Status update).
  Future<void> markDelivered(String bookingId) async {
    await updateBookingStatus(
      bookingId: bookingId,
      newStatus: BookingStatus.delivered,
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
