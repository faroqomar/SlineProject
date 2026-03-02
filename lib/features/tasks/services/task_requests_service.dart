import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../models/task_request_model.dart';

/// Service for handling task offer/bid operations.
class TaskRequestsService {
  final SupabaseClient _client;
  static const String _selectWithProfile = '''
    id, task_id, bidder_id, freelancer_id, price, days, duration_days,
    note, message, status, payment_status, created_at, updated_at, deleted_at,
    profiles!task_requests_freelancer_id_fkey(full_name, avatar_url),
    tasks(title)
  ''';

  TaskRequestsService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Returns the current user's pending offer for the task, if any.
  Future<TaskRequest?> getExistingActiveOfferForCurrentUser(
    String taskId,
  ) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      AppLogger.d(
        'Checking existing active offer for task $taskId and user $uid',
        tag: 'Offers',
      );
      final rows = await _client
          .from('task_requests')
          .select()
          .eq('task_id', taskId)
          .eq('freelancer_id', uid)
          .is_('deleted_at', null)
          .eq('status', 'pending')
          .limit(1);
      if (rows.isEmpty) return null;
      return TaskRequest.fromMap(rows.first as Map<String, dynamic>);
    } catch (e, st) {
      AppLogger.e(
        'Failed to load existing active offer for task $taskId',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// List offers for a task with pagination.
  Future<List<TaskRequest>> listByTask({
    required String taskId,
    int limit = 20,
    DateTime? before,
  }) async {
    AppLogger.d('Fetching offers for task $taskId', tag: 'Offers');

    try {
      // Select * from task_requests and join profiles using explicit FK
      final query = _client
          .from('task_requests')
          .select(_selectWithProfile)
          .eq('task_id', taskId)
          .is_('deleted_at', null);

      if (before != null) {
        query.lt('created_at', before.toUtc().toIso8601String());
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final result = (data as List<dynamic>)
          .map((e) => TaskRequest.fromMap(e as Map<String, dynamic>))
          .toList();

      AppLogger.i('Loaded ${result.length} offers', tag: 'Offers');
      return result;
    } catch (e, st) {
      AppLogger.e(
        'Failed to list offers',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Submit a new offer for a task.
  Future<TaskRequest> submitOffer({
    required String taskId,
    required double price,
    required int days,
    String? note,
  }) async {
    AppLogger.d('Submitting offer for task $taskId', tag: 'Offers');

    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      AppLogger.e('Not authenticated', tag: 'Offers');
      throw Exception('Not authenticated');
    }

    try {
      // RLS Policy Enforcer: Ensure active_role is 'freelancer'
      final profile = await _client
          .from('profiles')
          .select('active_role')
          .eq('id', uid)
          .single();

      final activeRole = profile['active_role'] as String?;
      if (activeRole != 'freelancer') {
        AppLogger.i(
          'Switching active_role to freelancer for offer submission',
          tag: 'Offers',
        );
        await _client
            .from('profiles')
            .update({'active_role': 'freelancer'})
            .eq('id', uid);
      }

      final insertData = <String, dynamic>{
        'task_id': taskId,
        'bidder_id': uid,
        'freelancer_id': uid, // Required for RLS
        'price': price,
        'days': days,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final inserted = await _client
          .from('task_requests')
          .insert(insertData)
          .select()
          .single();

      final model = TaskRequest.fromMap(inserted as Map<String, dynamic>);
      AppLogger.i('Offer submitted: ${model.id}', tag: 'Offers');

      return model;
    } on PostgrestException catch (e, st) {
      final msg = (e.message).toLowerCase();
      if (msg.contains('ux_task_requests_pending_per_user') ||
          (msg.contains('duplicate key') &&
              msg.contains('task_id') &&
              msg.contains('bidder_id'))) {
        AppLogger.w('Duplicate pending offer', tag: 'Offers');
        throw Exception('You already have a pending offer on this task.');
      }
      AppLogger.e(
        'Failed to submit offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.e(
        'Failed to submit offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Replace an existing offer with new values.
  Future<TaskRequest> replaceOffer({
    required String taskId,
    required double price,
    required int days,
    String? note,
  }) async {
    AppLogger.d('Replacing offer for task $taskId', tag: 'Offers');

    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      AppLogger.e('Not authenticated', tag: 'Offers');
      throw Exception('Not authenticated');
    }

    try {
      await _client.rpc(
        'replace_task_request',
        params: {
          'p_task_id': taskId,
          'p_freelancer_id': uid,
          'p_message': note ?? '',
          'p_price': price,
          'p_days': days,
        },
      );

      final model = await getExistingActiveOfferForCurrentUser(taskId);
      if (model == null) {
        throw Exception(
          'Offer was updated, but the refreshed offer could not be loaded.',
        );
      }
      AppLogger.i('Offer replaced: ${model.id}', tag: 'Offers');
      return model;
    } catch (e, st) {
      AppLogger.e(
        'Failed to replace offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Accept an offer (task owner action).
  Future<TaskRequest> accept(String requestId, {String? taskId}) async {
    AppLogger.d('Accepting offer $requestId', tag: 'Offers');
    try {
      final resolvedTaskId = taskId ?? await _resolveTaskId(requestId);
      await _client.rpc(
        'accept_task_request',
        params: {'p_task_id': resolvedTaskId, 'p_request_id': requestId},
      );
      final model = await _fetchRequestById(requestId);
      AppLogger.i('Offer accepted: ${model.id}', tag: 'Offers');

      return model;
    } catch (e, st) {
      AppLogger.e(
        'Failed to accept offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      throw Exception(_mapDecisionError(e));
    }
  }

  /// Reject an offer (task owner action).
  Future<TaskRequest> reject(String requestId, {String? taskId}) async {
    AppLogger.d('Rejecting offer $requestId', tag: 'Offers');
    try {
      final resolvedTaskId = taskId ?? await _resolveTaskId(requestId);
      await _client.rpc(
        'reject_task_request',
        params: {'p_task_id': resolvedTaskId, 'p_request_id': requestId},
      );
      final model = await _fetchRequestById(requestId);
      AppLogger.i('Offer rejected: ${model.id}', tag: 'Offers');

      return model;
    } catch (e, st) {
      AppLogger.e(
        'Failed to reject offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      throw Exception(_mapDecisionError(e));
    }
  }

  Future<String> _resolveTaskId(String requestId) async {
    final row = await _client
        .from('task_requests')
        .select('task_id')
        .eq('id', requestId)
        .single();
    return row['task_id'] as String;
  }

  Future<TaskRequest> _fetchRequestById(String requestId) async {
    final row = await _client
        .from('task_requests')
        .select(_selectWithProfile)
        .eq('id', requestId)
        .single();
    return TaskRequest.fromMap(row as Map<String, dynamic>);
  }

  String _mapDecisionError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('only task owner') || message.contains('forbidden')) {
      return 'Only the task owner can perform this action.';
    }
    if (message.contains('already processed') ||
        message.contains('not pending') ||
        message.contains('request not found')) {
      return 'This offer is no longer available for action.';
    }
    return 'Unable to update the offer right now. Please try again.';
  }
}
