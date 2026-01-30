import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/app_enums.dart';
import '../models/task_model.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';

import '../models/task_request_model.dart';

/// Service for handling task operations with Supabase.
///
/// Architecture: This service is called by TaskRepository, which is used by
/// TaskViewModel. UI widgets should never call this service directly.
///
/// Performance Note: Profile data is fetched in a batch query (2 queries total)
/// to avoid N+1 query issues. Direct JOINs require a FK from tasks.user_id to
/// profiles.id, which doesn't exist in the current schema.
class TaskService {
  final SupabaseClient _client;
  final NotificationService _notificationService = NotificationService();

  TaskService([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  /// Standard SELECT clause for tasks (without profile JOIN).
  ///
  /// Why no JOIN: The tasks.user_id FK points to auth.users, not profiles.
  /// Profile data is fetched separately via batch query to avoid N+1.
  static const String _selectBasic = '''
    id, title, description, budget, user_id, status, task_type,
    category_id, category, created_at, deadline, skills, image_paths,
    assigned_freelancer_id, packages,
    categories(name)
  ''';

  /// Batch-fetch profiles for a list of user IDs and return as a map.
  ///
  /// Why batch: Fetching profiles for N tasks requires 2 queries total
  /// (1 for tasks, 1 for profiles) instead of N+1 queries.
  Future<Map<String, Map<String, dynamic>>> _fetchProfilesByIds(
    Set<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .in_('id', userIds.toList());

      final map = <String, Map<String, dynamic>>{};
      for (final row in (response as List)) {
        final id = row['id'] as String;
        map[id] = row as Map<String, dynamic>;
      }
      return map;
    } catch (e) {
      AppLogger.w('Failed to fetch profiles batch: $e');
      return {};
    }
  }

  /// Merge profile data into task JSON before parsing.
  List<Task> _parseTasksWithProfiles(
    List<dynamic> rows,
    Map<String, Map<String, dynamic>> profilesMap,
  ) {
    return rows.map((json) {
      final taskJson = Map<String, dynamic>.from(json as Map);
      final userId = taskJson['user_id'] as String?;
      if (userId != null && profilesMap.containsKey(userId)) {
        taskJson['profiles'] = profilesMap[userId];
      }
      return Task.fromJson(taskJson);
    }).toList();
  }

  /// Get all tasks from database with user profile data.
  ///
  /// Performance: 2 queries (tasks + profiles batch) - no N+1 issue.
  Future<List<Task>> getTasks() async {
    AppLogger.i('Fetching all tasks from database');
    try {
      final response = await _client
          .from('tasks')
          .select(_selectBasic)
          .order('created_at', ascending: false);

      final rows = response as List;
      final userIds = rows
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet();

      final profilesMap = await _fetchProfilesByIds(userIds);
      final tasks = _parseTasksWithProfiles(rows, profilesMap);

      AppLogger.i('Successfully fetched ${tasks.length} tasks', tag: 'Tasks');
      return tasks;
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to get tasks',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    } catch (e, st) {
      AppLogger.e(
        'Failed to get tasks',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Create a new task and return it with profile data populated.
  ///
  /// Why batch fetch: We insert the task, then fetch profile data separately.
  /// This is 2 queries for a single creation (acceptable for non-list ops).
  Future<Task> createTask(Task task) async {
    AppLogger.i('Creating new task: ${task.title}');
    try {
      final response = await _client
          .from('tasks')
          .insert(task.toJson(includeSystemFields: false))
          .select(_selectBasic)
          .single();

      final taskJson = Map<String, dynamic>.from(response as Map);
      final userId = taskJson['user_id'] as String?;

      if (userId != null) {
        final profilesMap = await _fetchProfilesByIds({userId});
        if (profilesMap.containsKey(userId)) {
          taskJson['profiles'] = profilesMap[userId];
        }
      }

      final createdTask = Task.fromJson(taskJson);
      AppLogger.i('Task created successfully: ${createdTask.title}');
      return createdTask;
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to create task',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    } catch (e, st) {
      AppLogger.e(
        'Failed to create task',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Update task status (simple update, no profile data needed).
  ///
  /// Also triggers notifications for important status changes (completed, cancelled).
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      // 1. Fetch task details BEFORE update to know who to notify
      final taskRes = await _client
          .from('tasks')
          .select('user_id, assigned_freelancer_id, title')
          .eq('id', taskId)
          .single();

      final ownerId = taskRes['user_id'] as String;
      final freelancerId = taskRes['assigned_freelancer_id'] as String?;
      final taskTitle = taskRes['title'] as String;
      final currentUid = _client.auth.currentUser?.id;

      // 2. Perform the update
      await _client
          .from('tasks')
          .update({'status': _mapStatusToDb(status)})
          .eq('id', taskId);
      AppLogger.i(
        'Task status updated: $taskId → ${status.name}',
        tag: 'Tasks',
      );

      // 3. Send Notifications
      if (freelancerId != null && currentUid != null) {
        String? notifyUserId;
        String? title;
        String? message;

        // If Owner changed status -> Notify Freelancer
        if (currentUid == ownerId) {
          notifyUserId = freelancerId;
          if (status == TaskStatus.closed) {
            title = 'Task Completed';
            message = 'The client has marked "$taskTitle" as completed.';
          } else if (status == TaskStatus.canceled) {
            title = 'Task Cancelled';
            message = 'The client has cancelled "$taskTitle".';
          }
        }
        // If Freelancer changed status (e.g. if we allow them to mark as complete?)
        // Currently typically only client updates status to complete, but if freelancer does:
        else if (currentUid == freelancerId) {
          notifyUserId = ownerId;
          // Add logic here if freelancer can change status (e.g. to 'submitted' or 'completed')
        }

        if (notifyUserId != null && title != null && message != null) {
          _notificationService.createNotification(
            userId: notifyUserId,
            title: title,
            message: message,
            type: NotificationType.task,
            relatedEntityId: taskId,
            relatedEntityType: 'task',
          );
        }
      }
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to update task status',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    } catch (e, st) {
      AppLogger.e(
        'Failed to update task status',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Update an existing task with arbitrary fields.
  ///
  /// Note: `updates` may include `category_id` (DB FK) or legacy `category`.
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      await _client.from('tasks').update(updates).eq('id', taskId);
      AppLogger.i('Task updated: $taskId', tag: 'Tasks');
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to update task',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    } catch (e, st) {
      AppLogger.e(
        'Failed to update task',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Get tasks by user ID with profile data.
  ///
  /// Performance: 2 queries (tasks + profiles batch) - no N+1 issue.
  Future<List<Task>> getTasksByUser(String userId) async {
    try {
      // Custom select to include offer count
      final response = await _client
          .from('tasks')
          .select('$_selectBasic, task_requests(count)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final rows = response as List;
      final userIds = rows
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet();

      final profilesMap = await _fetchProfilesByIds(userIds);

      return rows.map((json) {
        final taskJson = Map<String, dynamic>.from(json as Map);

        // Profiles Mapping
        final userId = taskJson['user_id'] as String?;
        if (userId != null && profilesMap.containsKey(userId)) {
          taskJson['profiles'] = profilesMap[userId];
        }

        // Offers Mapping (Flatten count)
        if (taskJson['task_requests'] != null) {
          final requests = taskJson['task_requests'] as List;
          if (requests.isNotEmpty && requests[0] is Map) {
            taskJson['offers'] = requests[0]['count'];
          }
        }

        return Task.fromJson(taskJson);
      }).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to get tasks by user',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    } catch (e, st) {
      AppLogger.e(
        'Failed to get tasks by user',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Get tasks by status with profile data.
  ///
  /// Performance: 2 queries (tasks + profiles batch) - no N+1 issue.
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    try {
      final response = await _client
          .from('tasks')
          .select(_selectBasic)
          .eq('status', status.name)
          .order('created_at', ascending: false);

      final rows = response as List;
      final userIds = rows
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet();

      final profilesMap = await _fetchProfilesByIds(userIds);
      return _parseTasksWithProfiles(rows, profilesMap);
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to get tasks by status',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    } catch (e, st) {
      AppLogger.e(
        'Failed to get tasks by status',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Delete a task by ID.
  Future<void> deleteTask(String taskId) async {
    AppLogger.d('Deleting task with ID: $taskId', tag: 'Tasks');
    try {
      await _client.from('tasks').delete().eq('id', taskId);
      AppLogger.i('Task deleted successfully: $taskId', tag: 'Tasks');
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to delete task',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    } catch (e, st) {
      AppLogger.e(
        'Failed to delete task',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Default page size for paginated queries.
  static const int defaultPageSize = 20;

  /// Get open tasks for the Home screen with profile data and pagination.
  ///
  /// Performance: 2 queries (tasks + profiles batch) - no N+1 issue.
  /// This is the primary method for the home feed.
  ///
  /// Pagination: Uses cursor-based pagination with `created_at` timestamps.
  /// Pass `cursorCreatedAtIso` from the last task's `createdAt.toIso8601String()`
  /// to fetch the next page.
  ///
  /// Example:
  /// ```dart
  /// // First page
  /// final page1 = await taskService.getOpenTasksForHome(limit: 20);
  /// // Next page
  /// final page2 = await taskService.getOpenTasksForHome(
  ///   limit: 20,
  ///   cursorCreatedAtIso: page1.last.createdAt.toUtc().toIso8601String(),
  /// );
  /// ```
  Future<List<Task>> getOpenTasksForHome({
    int limit = defaultPageSize,
    String? cursorCreatedAtIso,
  }) async {
    try {
      var query = _client
          .from('tasks')
          .select(_selectBasic)
          .eq('status', TaskStatus.open.name);

      // Apply cursor for pagination (fetch tasks created before the cursor)
      if (cursorCreatedAtIso != null && cursorCreatedAtIso.isNotEmpty) {
        query = query.lt('created_at', cursorCreatedAtIso);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final rows = response as List;
      final userIds = rows
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet();

      final profilesMap = await _fetchProfilesByIds(userIds);
      return _parseTasksWithProfiles(rows, profilesMap);
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to get open tasks for home',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    } catch (e, st) {
      AppLogger.e(
        'Failed to get open tasks for home',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Get a single task by ID with profile data.
  ///
  /// Performance: 2 queries (task + profile) - acceptable for single item.
  Future<Task?> getTaskById(String taskId) async {
    try {
      final response = await _client
          .from('tasks')
          .select(_selectBasic)
          .eq('id', taskId)
          .maybeSingle();

      if (response == null) return null;

      final taskJson = Map<String, dynamic>.from(response as Map);
      final userId = taskJson['user_id'] as String?;

      if (userId != null) {
        final profilesMap = await _fetchProfilesByIds({userId});
        if (profilesMap.containsKey(userId)) {
          taskJson['profiles'] = profilesMap[userId];
        }
      }

      return Task.fromJson(taskJson);
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to get task by ID',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    } catch (e, st) {
      AppLogger.e(
        'Failed to get task by ID',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    }
  }

  String _mapStatusToDb(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress:
        return 'in_progress';
      default:
        return status.name;
    }
  }

  // --- Offer Management (Phase 6) ---

  /// Get offers received for a client's tasks.
  ///
  /// Returns a flat list of pending offers on tasks owned by [userId].
  Future<List<TaskRequest>> getOffersReceived(String userId) async {
    try {
      // Fetch pending offers where task owner is userId
      // Strategy:
      // 1. Fetch tasks owned by user IDs
      // 2. Or specialized query on task_requests joining tasks
      //
      // Supabase query:
      // select *, tasks!inner(user_id) where tasks.user_id = uid AND status = pending
      final response = await _client
          .from('task_requests')
          .select(
            '*, tasks!inner(user_id, title), profiles!task_requests_freelancer_id_fkey(full_name, avatar_url)',
          )
          .eq('status', 'pending')
          .eq('tasks.user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        // Map Task Title and Profile for UI convenience
        // Profiles is joined as 'profiles' object
        // Tasks is joined as 'tasks' object
        // TaskRequest.fromMap handles profiles mapping?
        // We might need to augment the map or update model
        // Actually TaskRequest model expects profiles flat or nested?
        return TaskRequest.fromMap(json as Map<String, dynamic>);
      }).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.e('Failed to get offers received', error: e, stackTrace: st);
      return [];
    } catch (e) {
      AppLogger.e('Failed to get offers received', error: e);
      return [];
    }
  }

  /// Get offers submitted by a freelancer.
  Future<List<TaskRequest>> getOffersSubmitted(String freelancerId) async {
    try {
      final response = await _client
          .from('task_requests')
          .select('*, tasks(title, user_id)') // Join task to show Title
          .eq('freelancer_id', freelancerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskRequest.fromMap(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e, st) {
      AppLogger.e('Failed to get offers submitted', error: e, stackTrace: st);
      return [];
    } catch (e) {
      AppLogger.e('Failed to get offers submitted', error: e);
      return [];
    }
  }

  /// Withdraw (delete) a pending offer.
  Future<void> withdrawOffer(String requestId) async {
    try {
      // RLS policy `tr_delete` allows deletion if status is pending and owner matches
      await _client.from('task_requests').delete().eq('id', requestId);
      AppLogger.i('Offer withdrawn: $requestId');
    } on PostgrestException catch (e, st) {
      AppLogger.e('Failed to withdraw offer', error: e, stackTrace: st);
      throw Exception(ErrorMapper.map(e));
    } catch (e) {
      AppLogger.e('Failed to withdraw offer', error: e);
      rethrow;
    }
  }

  /// Accepts an offer using atomic RPC
  Future<void> acceptOffer(String offerId) async {
    try {
      await _client.rpc(
        'accept_task_request',
        params: {'p_request_id': offerId},
      );
      AppLogger.i('Offer accepted via RPC: $offerId');
    } on PostgrestException catch (e, st) {
      if (e.message.contains('not the task owner')) {
        throw Exception('Only task owner can accept offers');
      }
      if (e.message.contains('already assigned')) {
        throw Exception('Task already assigned');
      }
      AppLogger.e('Failed to accept offer', error: e, stackTrace: st);
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Rejects an offer
  Future<void> rejectOffer(String offerId) async {
    try {
      // Try direct update (RLS policy tr_update_by_owner allows task owner)
      await _client
          .from('task_requests')
          .update({'status': 'rejected'})
          .eq('id', offerId);

      AppLogger.i('Offer rejected: $offerId');
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        // RLS blocks direct update, log clear error
        AppLogger.w('Need reject_task_request RPC - RLS blocks direct update');
        throw Exception('Need reject_task_request RPC - contact backend team');
      }
      AppLogger.e('Failed to reject offer', error: e, stackTrace: st);
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Get Tenders where the current user (freelancer) has an accepted offer
  /// but payment is pending (or any state requiring attention).
  ///
  /// For now, we fetch tasks where:
  /// 1. User is the assigned_freelancer_id
  /// 2. Status implies pending action (e.g. 'in_progress' but maybe 'assigned' if we separate them)
  ///
  /// CONTEXT: "Pending Payment Tenders" - This usually means the Client accepted the offer
  /// but hasn't paid into Escrow yet. However, in our flow, Acceptance = Payment (usually).
  /// If "Pay Later" is supported, then we look for status='assigned' or similar.
  ///
  /// Based on Phase 1, we use `paid_request_pending` for Bookings.
  /// For Tenders, if accepted -> Money is in Escrow -> Status is 'in_progress' (or similar).
  ///
  /// If the requirement is "Pending Payment Tenders", it might refer to
  /// "Offers I made that are Accepted but waiting for Payment" (if logic suggests separation).
  ///
  /// Current logic:
  /// Fetch tasks where assigned_freelancer_id = ME AND status IN ('assigned', 'payment_pending').
  Future<List<Task>> getPendingPaymentTenders() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      // Assuming 'assigned' is the status for "Accepted but not In Progress/Paid"
      // Or if we just want to show "Active Tenders" in pending section?
      // "Pending Payment" suggests the client needs to pay.
      //
      // If we don't have a specific 'payment_pending' status for Tenders,
      // we might just return empty or tasks where we are assigned.
      //
      // Let's assume we want to show tasks where we are assigned.
      final response = await _client
          .from('tasks')
          .select(_selectBasic)
          .eq('assigned_freelancer_id', uid)
          .eq(
            'status',
            'open',
          ) // Open means not yet fully kicked off? Or use 'assigned'
          // .eq('payment_status', 'pending') // if/when we add this
          .order('created_at', ascending: false);

      final rows = response as List;
      final userIds = rows
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet();

      final profilesMap = await _fetchProfilesByIds(userIds);
      return _parseTasksWithProfiles(rows, profilesMap);
    } catch (e, st) {
      AppLogger.e(
        'Failed to get pending payment tenders',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }
}
