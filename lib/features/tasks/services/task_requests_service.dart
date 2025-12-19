import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../models/task_request_model.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';

/// Service for handling task offer/bid operations.
class TaskRequestsService {
  final SupabaseClient _client;
  final NotificationService _notificationService = NotificationService();

  TaskRequestsService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// List offers for a task with pagination.
  Future<List<TaskRequest>> listByTask({
    required String taskId,
    int limit = 20,
    DateTime? before,
  }) async {
    AppLogger.d('Fetching offers for task $taskId', tag: 'Offers');

    try {
      // Select * from task_requests and join profiles for bidder info
      final query = _client
          .from('task_requests')
          .select('*, profiles(full_name, avatar_url)')
          .eq('task_id', taskId);

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
      final insertData = <String, dynamic>{
        'task_id': taskId,
        'bidder_id': uid,
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

      // Notify Task Owner
      try {
        // We need to fetch the task owner
        final taskRes = await _client
            .from('tasks')
            .select('client_id')
            .eq('id', taskId)
            .single();
        final ownerId = taskRes['client_id'] as String?;

        if (ownerId != null && ownerId != uid) {
          _notificationService.createNotification(
            userId: ownerId,
            title: 'New Bid on Task',
            message: 'You have received a new bid of ${model.price}',
            type: NotificationType.offer,
            relatedEntityId: taskId,
            relatedEntityType: 'task',
          );
        }
      } catch (e) {
        AppLogger.w('Failed to notify task owner: $e');
      }

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
      final res = await _client.rpc(
        'replace_task_request',
        params: {
          'p_task_id': taskId,
          'p_freelancer_id': uid,
          'p_message': note ?? '',
          'p_price': price,
          'p_days': days,
        },
      );

      final model = TaskRequest.fromMap(res as Map<String, dynamic>);
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
  Future<TaskRequest> accept(String requestId) async {
    AppLogger.d('Accepting offer $requestId', tag: 'Offers');
    try {
      final res = await _client.rpc(
        'accept_task_request',
        params: {'p_request_id': requestId},
      );

      Map<String, dynamic> map;
      if (res is Map<String, dynamic>) {
        map = res;
      } else if (res is List &&
          res.isNotEmpty &&
          res.first is Map<String, dynamic>) {
        map = res.first as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected RPC result format for accept_task_request');
      }

      final model = TaskRequest.fromMap(map);
      AppLogger.i('Offer accepted: ${model.id}', tag: 'Offers');

      // Notify Freelancer (Bidder)
      if (model.bidderId.isNotEmpty) {
        _notificationService.createNotification(
          userId: model.bidderId,
          title: 'Offer Accepted',
          message: 'Your offer has been accepted!',
          type: NotificationType.offer,
          relatedEntityId: model.taskId,
          relatedEntityType: 'task',
        );
      }

      return model;
    } catch (e, st) {
      AppLogger.e(
        'Failed to accept offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Reject an offer (task owner action).
  Future<TaskRequest> reject(String requestId) async {
    AppLogger.d('Rejecting offer $requestId', tag: 'Offers');
    try {
      final res = await _client.rpc(
        'reject_task_request',
        params: {'p_request_id': requestId},
      );

      Map<String, dynamic> map;
      if (res is Map<String, dynamic>) {
        map = res;
      } else if (res is List &&
          res.isNotEmpty &&
          res.first is Map<String, dynamic>) {
        map = res.first as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected RPC result format for reject_task_request');
      }

      final model = TaskRequest.fromMap(map);
      AppLogger.i('Offer rejected: ${model.id}', tag: 'Offers');

      // Notify Freelancer (Bidder)
      if (model.bidderId.isNotEmpty) {
        _notificationService.createNotification(
          userId: model.bidderId,
          title: 'Offer Rejected',
          message: 'Your offer was not selected.',
          type: NotificationType.offer,
          relatedEntityId: model.taskId,
          relatedEntityType: 'task',
        );
      }

      return model;
    } catch (e, st) {
      AppLogger.e(
        'Failed to reject offer',
        tag: 'Offers',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
