import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/features/profile/services/profile_summary_service.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_offer_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling task CRUD and query operations with Supabase.
///
/// Architecture: This service is called by TaskRepository, which is used by
/// TaskViewModel. UI widgets should never call this service directly.
///
/// Offer management, award flow, and payment operations are delegated to
/// [TaskOfferService]. Delegation stubs are kept here so existing callers
/// continue to work without import changes.
///
/// Performance Note: Profile data is fetched in a batch query (2 queries total)
/// to avoid N+1 query issues. Direct JOINs require a FK from tasks.user_id to
/// profiles.id, which doesn't exist in the current schema.
class TaskService {
  final SupabaseClient _client;
  late final ProfileSummaryService _profileSummaryService;
  late final TaskOfferService _offerService;

  TaskService([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client {
    _profileSummaryService = ProfileSummaryService(_client);
    _offerService = TaskOfferService(client: _client);
  }

  /// Standard SELECT clause for tasks (without profile JOIN).
  ///
  /// Why no JOIN: The tasks.user_id FK points to auth.users, not profiles.
  /// Profile data is fetched separately via batch query to avoid N+1.
  static const String _selectBasic = '''
    id, title, description, budget, user_id, owner_id, client_id, freelancer_id,
    status, task_type,
    category_id, category, created_at, deadline, skills, image_paths,
    assigned_freelancer_id, packages,
    categories(name)
  ''';

  /// Batch-fetch profiles for a list of user IDs and return as a map.
  ///
  /// Why batch: Fetching profiles for N tasks requires 2 queries total
  /// (1 for tasks, 1 for profiles) instead of N+1 queries.
  Future<Map<String, Map<String, dynamic>>> _fetchProfilesByIds(
    Set<String> userIds, {
    String source = 'unknown',
    String? requestId,
  }) async {
    if (userIds.isEmpty) return {};

    try {
      final response = await _profileSummaryService.fetchByIds(
        userIds,
        source: source,
        requestId: requestId,
      );

      final map = <String, Map<String, dynamic>>{};
      for (final entry in response.entries) {
        map[entry.key] = entry.value;
      }
      return map;
    } on Exception catch (e) {
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
      final userId =
          taskJson['owner_id'] as String? ??
          taskJson['client_id'] as String? ??
          taskJson['user_id'] as String?;
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
          .map(
            (r) =>
                r['owner_id'] as String? ??
                r['client_id'] as String? ??
                r['user_id'] as String?,
          )
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
    } on Exception catch (e, st) {
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
      final userId =
          taskJson['owner_id'] as String? ??
          taskJson['client_id'] as String? ??
          taskJson['user_id'] as String?;

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
    } on Exception catch (e, st) {
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
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      await _client
          .from('tasks')
          .update({'status': _mapStatusToDb(status)})
          .eq('id', taskId);
      AppLogger.i(
        'Task status updated: $taskId → ${status.name}',
        tag: 'Tasks',
      );
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to update task status',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    } on Exception catch (e, st) {
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
    } on Exception catch (e, st) {
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
    return getTasksByOwner(userId);
  }

  /// Get tasks by owner with compatibility coverage for legacy `user_id` rows.
  Future<List<Task>> getTasksByOwner(String ownerId) async {
    try {
      // Custom select to include offer count
      final response = await _client
          .from('tasks')
          .select('$_selectBasic, task_requests(count)')
          .or('owner_id.eq.$ownerId,user_id.eq.$ownerId,client_id.eq.$ownerId')
          .order('created_at', ascending: false);

      final rows = response as List;
      final userIds = rows
          .map(
            (r) =>
                r['owner_id'] as String? ??
                r['client_id'] as String? ??
                r['user_id'] as String?,
          )
          .whereType<String>()
          .toSet();

      final profilesMap = await _fetchProfilesByIds(userIds);

      return rows.map((json) {
        final taskJson = Map<String, dynamic>.from(json as Map);

        // Profiles Mapping
        final userId =
            taskJson['owner_id'] as String? ??
            taskJson['client_id'] as String? ??
            taskJson['user_id'] as String?;
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
        'Failed to get tasks by owner',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to get tasks by owner',
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
          .eq('status', _mapStatusToDb(status))
          .order('created_at', ascending: false);

      final rows = response as List;
      final userIds = rows
          .map(
            (r) =>
                r['owner_id'] as String? ??
                r['client_id'] as String? ??
                r['user_id'] as String?,
          )
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
    } on Exception catch (e, st) {
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
    } on Exception catch (e, st) {
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
    String? cursorId,
    String source = 'home',
    String? requestId,
  }) async {
    try {
      var query = _client
          .from('tasks')
          .select(_selectBasic)
          .eq('status', TaskStatus.open.name);

      // Apply composite cursor for stable pagination across timestamp ties.
      if (cursorCreatedAtIso != null && cursorCreatedAtIso.isNotEmpty) {
        if (cursorId != null && cursorId.isNotEmpty) {
          query = query.or(
            'created_at.lt.$cursorCreatedAtIso,and(created_at.eq.$cursorCreatedAtIso,id.lt.$cursorId)',
          );
        } else {
          query = query.lt('created_at', cursorCreatedAtIso);
        }
      }

      final response = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);

      final rows = response as List;
      final userIds = rows
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet();

      final profilesMap = await _fetchProfilesByIds(
        userIds,
        source: source,
        requestId: requestId,
      );
      return _parseTasksWithProfiles(rows, profilesMap);
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to get open tasks for home',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    } on Exception catch (e, st) {
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
    } on Exception catch (e, st) {
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

  // ──────────────────────────────────────────────────────────────────────────
  // Offer Management — delegated to TaskOfferService
  //
  // Stubs kept here so existing callers (ViewModels, coordinators) continue
  // to compile without changing their imports.
  // ──────────────────────────────────────────────────────────────────────────

  /// Get offers received for a client's tasks.
  Future<List<TaskRequest>> getOffersReceived(String userId) =>
      _offerService.getOffersReceived(userId);

  /// Get offers submitted by a freelancer.
  Future<List<TaskRequest>> getOffersSubmitted(String freelancerId) =>
      _offerService.getOffersSubmitted(freelancerId);

  /// Withdraw (delete) a pending offer.
  Future<void> withdrawOffer(String requestId) =>
      _offerService.withdrawOffer(requestId);

  /// Accepts an offer using atomic RPC.
  Future<void> acceptOffer(String offerId) =>
      _offerService.acceptOffer(offerId);

  /// Rejects an offer.
  Future<void> rejectOffer(String offerId) =>
      _offerService.rejectOffer(offerId);

  /// Escrow hold for a Task Request (Offer).
  Future<void> escrowHoldOffer(String offerId) =>
      _offerService.escrowHoldOffer(offerId);

  /// Release payment with fee for a Task Request.
  Future<void> releaseOfferWithFee(String offerId) =>
      _offerService.releaseOfferWithFee(offerId);

  /// Refund a Task Request.
  Future<void> refundOffer(String offerId) =>
      _offerService.refundOffer(offerId);

  /// Award an offer (Step 1: Award without payment).
  Future<Map<String, dynamic>> awardOffer(
    String offerId, {
    int? expectedPriceCents,
  }) =>
      _offerService.awardOffer(offerId, expectedPriceCents: expectedPriceCents);

  /// Pay for an awarded offer (Step 2: Complete payment).
  Future<Map<String, dynamic>> payAwardedOffer(String offerId) =>
      _offerService.payAwardedOffer(offerId);

  /// Cancel an awarded-but-unpaid offer.
  Future<Map<String, dynamic>> cancelAwardedOffer(String requestId) =>
      _offerService.cancelAwardedOffer(requestId);

  /// Get client's awarded but unpaid offers (for "Pay Now" UI).
  Future<List<Map<String, dynamic>>> getClientAwardedUnpaidOffers() =>
      _offerService.getClientAwardedUnpaidOffers();

  /// Get freelancer's awarded but unpaid offers (for "Waiting for Payment" UI).
  Future<List<Map<String, dynamic>>> getFreelancerAwardedUnpaidOffers() =>
      _offerService.getFreelancerAwardedUnpaidOffers();

  /// Get Tenders where the current user (freelancer) has an accepted offer
  /// but payment is pending.
  Future<List<Task>> getPendingPaymentTenders() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final response = await _client
          .from('tasks')
          .select(_selectBasic)
          .eq('assigned_freelancer_id', uid)
          .eq('status', 'assigned') // Awarded offers awaiting payment
          .order('created_at', ascending: false);

      final rows = response as List;
      final userIds = rows
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet();

      final profilesMap = await _fetchProfilesByIds(userIds);
      return _parseTasksWithProfiles(rows, profilesMap);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to get pending payment tenders',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }
}
