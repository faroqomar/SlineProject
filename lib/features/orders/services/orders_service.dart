import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';

/// Service to handle "My Orders" (Published Tasks) dashboard operations.
/// Aggregates functionality from TaskService and TaskRequestsService.
class OrdersService {
  final SupabaseClient _client;
  late final TaskService _taskService;
  late final TaskRequestsService _requestsService;

  OrdersService({
    SupabaseClient? client,
    TaskService? taskService,
    TaskRequestsService? requestsService,
  }) : _client = client ?? Supabase.instance.client {
    _taskService = taskService ?? TaskService(_client);
    _requestsService = requestsService ?? TaskRequestsService(client: _client);
  }

  /// Fetch all tasks published by the current user.
  Future<List<Task>> getMyPublishedTasks() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      AppLogger.w('Not authenticated', tag: 'OrdersService');
      return [];
    }
    return _taskService.getTasksByUser(uid);
  }

  /// Fetch offers/requests for a specific task.
  Future<List<TaskRequest>> getTaskOffers(String taskId) async {
    return _requestsService.listByTask(taskId: taskId);
  }

  /// Accept an offer.
  Future<void> acceptOffer(String offerId) async {
    await _requestsService.accept(offerId);
  }

  /// Reject an offer.
  Future<void> rejectOffer(String offerId) async {
    await _requestsService.reject(offerId);
  }

  /// Delete a task (if no active bookings/contracts).
  Future<void> deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
  }

  /// Close a task (mark as completed or closed).
  Future<void> closeTask(String taskId) async {
    await _taskService.updateTaskStatus(taskId, TaskStatus.closed);
  }
}

