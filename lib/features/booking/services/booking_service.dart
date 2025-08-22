import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';

/// Low-level service that talks to Supabase (PostgREST) only.
/// No UI state here; RLS is assumed to be enforced by the backend.
class BookingService {
  BookingService(this._client);

  final SupabaseClient _client;

  static const String _slotsTable = 'availability_slots';
  static const String _bookingsTable = 'bookings';

  /// List slots by provider and optional time window. Ordered by starts_at ASC.
  Future<List<SlotModel>> listSlots({
    required String providerId,
    DateTime? fromUtc,
    DateTime? toUtc,
    int limit = 50,
    String? cursorStartsAtIso, // simple cursor based on starts_at
  }) async {
    final query = _client.from(_slotsTable).select().eq('provider_id', providerId);

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

    final insert = await _client.from(_slotsTable).insert({
      'provider_id': uid, // <-- required by RLS
      'starts_at': startsAtUtc.toUtc().toIso8601String(),
      'ends_at': endsAtUtc.toUtc().toIso8601String(),
      'is_blocked': isBlocked,
    }).select().single();

    return SlotModel.fromJson(insert as Map<String, dynamic>);
  }

  /// Book a slot as the current client.
  /// RLS policy requires: client_id = auth.uid().
  Future<BookingModel> bookSlot({
    required String taskId,
    required String slotId,
    String? note,
    required String providerId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Not signed in');
    }

    final res = await _client.from(_bookingsTable).insert({
      'task_id': taskId,
      'slot_id': slotId,
      'note': note,
      'provider_id': providerId,
      'client_id': uid, // <-- required by RLS
    }).select().single();

    return BookingModel.fromJson(res as Map<String, dynamic>);
  }

  /// List bookings where the current user is the CLIENT.
  Future<List<BookingModel>> listBookingsAsClient({
    int limit = 50,
    String? cursorCreatedAtIso,
  }) async {
    final query = _client.from(_bookingsTable).select();

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
    final query = _client.from(_bookingsTable).select();

    if (cursorCreatedAtIso != null) {
      query.lt('created_at', cursorCreatedAtIso);
    }

    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List<dynamic>)
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Update booking status. RLS guards transitions.
  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
  }) async {
    final res = await _client
        .from(_bookingsTable)
        .update({'status': newStatus.name})
        .eq('id', bookingId)
        .select()
        .single();

    return BookingModel.fromJson(res as Map<String, dynamic>);
  }
}