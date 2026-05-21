import 'package:sline_app/core/services/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DisputeService {
  DisputeService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Submits a dispute for a task or a direct offer. Exactly one of [taskId] or [directOfferId] must be set.
  /// Uses rpc_submit_dispute for eligibility and single-open/active enforcement.
  Future<void> submitDispute({
    String? taskId,
    String? directOfferId,
    required String reason,
    String? defendantId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('You must be signed in to submit a dispute.');
    }
    if (reason.trim().isEmpty) {
      throw Exception('Please provide a reason.');
    }
    final hasTask = taskId != null && taskId.trim().isNotEmpty;
    final hasOffer = directOfferId != null && directOfferId.trim().isNotEmpty;
    if (hasTask == hasOffer) {
      throw Exception(
        'Exactly one of taskId or directOfferId must be provided.',
      );
    }

    final params = <String, dynamic>{
      'p_task_id': hasTask ? taskId : null,
      'p_direct_offer_id': hasOffer ? directOfferId : null,
      'p_reason': reason.trim(),
      'p_defendant_id': defendantId != null && defendantId.isNotEmpty
          ? defendantId
          : null,
    };

    await _client.rpc<dynamic>('rpc_submit_dispute', params: params);

    AppLogger.i(
      'Dispute submitted',
      tag: 'Safety',
      json: <String, dynamic>{
        'event_name': 'safety_dispute_submitted',
        if (hasTask) 'task_id': taskId,
        if (hasOffer) 'direct_offer_id': directOfferId,
      },
    );
  }

  /// Returns true if there is an open or active dispute for the given task.
  /// Used by UI to hide "Approve & Release" when a dispute is in progress.
  Future<bool> hasOpenDisputeForTask(String taskId) async {
    if (taskId.trim().isEmpty) return false;
    try {
      final res = await _client
          .from('disputes')
          .select('id')
          .eq('task_id', taskId)
          .inFilter('status', ['open', 'active'])
          .limit(1)
          .maybeSingle();
      final hasOpen = res != null;
      if (hasOpen) {
        AppLogger.d(
          'Open dispute found for task; approve delivery blocked',
          tag: 'Safety',
          json: <String, dynamic>{'task_id': taskId},
        );
      }
      return hasOpen;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to check open dispute for task',
        tag: 'Safety',
        error: e,
        stackTrace: st,
        json: <String, dynamic>{'task_id': taskId},
      );
      return true;
    }
  }

  /// Returns true if there is an open or active dispute for the given direct offer.
  Future<bool> hasOpenDisputeForDirectOffer(String offerId) async {
    if (offerId.trim().isEmpty) return false;
    try {
      final res = await _client
          .from('disputes')
          .select('id')
          .eq('direct_offer_id', offerId)
          .inFilter('status', ['open', 'active'])
          .limit(1)
          .maybeSingle();
      final hasOpen = res != null;
      if (hasOpen) {
        AppLogger.d(
          'Open dispute found for direct offer; approve release blocked',
          tag: 'Safety',
          json: <String, dynamic>{'direct_offer_id': offerId},
        );
      }
      return hasOpen;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to check open dispute for direct offer',
        tag: 'Safety',
        error: e,
        stackTrace: st,
        json: <String, dynamic>{'direct_offer_id': offerId},
      );
      return true;
    }
  }

  /// Returns dispute status 'open' or 'active' if one exists for the task; otherwise null.
  Future<String?> getDisputeStatusForTask(String taskId) async {
    if (taskId.trim().isEmpty) return null;
    try {
      final res = await _client
          .from('disputes')
          .select('status')
          .eq('task_id', taskId)
          .inFilter('status', ['open', 'active'])
          .limit(1)
          .maybeSingle();
      return res?['status'] as String?;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to get dispute status for task',
        tag: 'Safety',
        error: e,
        stackTrace: st,
        json: <String, dynamic>{'task_id': taskId},
      );
      return null;
    }
  }

  /// Returns dispute status 'open' or 'active' if one exists for the direct offer; otherwise null.
  Future<String?> getDisputeStatusForDirectOffer(String offerId) async {
    if (offerId.trim().isEmpty) return null;
    try {
      final res = await _client
          .from('disputes')
          .select('status')
          .eq('direct_offer_id', offerId)
          .inFilter('status', ['open', 'active'])
          .limit(1)
          .maybeSingle();
      return res?['status'] as String?;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to get dispute status for direct offer',
        tag: 'Safety',
        error: e,
        stackTrace: st,
        json: <String, dynamic>{'direct_offer_id': offerId},
      );
      return null;
    }
  }

  /// Returns dispute status 'open' or 'active' for the booking (via its task_id); otherwise null.
  Future<String?> getDisputeStatusForBooking(String bookingId) async {
    if (bookingId.trim().isEmpty) return null;
    try {
      final row = await _client
          .from('bookings')
          .select('task_id')
          .eq('id', bookingId)
          .maybeSingle();
      final taskId = row?['task_id'] as String?;
      if (taskId == null || taskId.isEmpty) return null;
      return getDisputeStatusForTask(taskId);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to get dispute status for booking',
        tag: 'Safety',
        error: e,
        stackTrace: st,
        json: <String, dynamic>{'booking_id': bookingId},
      );
      return null;
    }
  }

  /// Returns true if there is an open or active dispute for the booking (via its task_id).
  Future<bool> hasOpenDisputeForBooking(String bookingId) async {
    if (bookingId.trim().isEmpty) return false;
    try {
      final row = await _client
          .from('bookings')
          .select('task_id')
          .eq('id', bookingId)
          .maybeSingle();
      final taskId = row?['task_id'] as String?;
      if (taskId == null || taskId.isEmpty) return false;
      return hasOpenDisputeForTask(taskId);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to check open dispute for booking',
        tag: 'Safety',
        error: e,
        stackTrace: st,
        json: <String, dynamic>{'booking_id': bookingId},
      );
      return true;
    }
  }
}
