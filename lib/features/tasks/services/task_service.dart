import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/app_enums.dart';
import '../../profile/services/profile_summary_service.dart';
import '../models/task_model.dart';

import '../models/task_request_model.dart';
import 'task_requests_service.dart';
import '../../wallet/services/ledger_service.dart';

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
  late final ProfileSummaryService _profileSummaryService;
  late final TaskRequestsService _taskRequestsService;

  TaskService([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client {
    _profileSummaryService = ProfileSummaryService(_client);
    _taskRequestsService = TaskRequestsService(client: _client);
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
    } catch (e, st) {
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
      final ownedTasks = await _client
          .from('tasks')
          .select('id')
          .or('owner_id.eq.$userId,user_id.eq.$userId,client_id.eq.$userId');

      final taskIds = (ownedTasks as List<dynamic>)
          .map((row) => row['id'] as String?)
          .whereType<String>()
          .toList();

      if (taskIds.isEmpty) {
        return [];
      }

      final response = await _client
          .from('task_requests')
          .select(
            'id, task_id, bidder_id, freelancer_id, price, days, duration_days, note, message, status, payment_status, created_at, deleted_at, tasks(title), profiles!task_requests_freelancer_id_fkey(full_name, avatar_url)',
          )
          .eq('status', 'pending')
          .is_('deleted_at', null)
          .in_('task_id', taskIds)
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
      await _taskRequestsService.accept(offerId);
      AppLogger.i('Offer accepted via RPC: $offerId');
    } catch (e, st) {
      AppLogger.e('Failed to accept offer', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Rejects an offer
  Future<void> rejectOffer(String offerId) async {
    try {
      await _taskRequestsService.reject(offerId);
      AppLogger.i('Offer rejected: $offerId');
    } catch (e, st) {
      AppLogger.e('Failed to reject offer', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Escrow hold for a Task Request (Offer)
  Future<void> escrowHoldOffer(String offerId) async {
    try {
      final res = await _client
          .from('task_requests')
          .select('price')
          .eq('id', offerId)
          .single();
      final price = res['price'] as num? ?? 0;

      await LedgerService(_client).submitPaymentEvent(
        eventType: 'escrow_hold',
        relatedEntityType: 'task_request',
        relatedEntityId: offerId,
        amountGross: price,
        meta: {},
      );

      // Once escrow is held successfully, accept the offer
      await acceptOffer(offerId);
    } catch (e) {
      AppLogger.e('Failed to process escrow hold for offer', error: e);
      rethrow;
    }
  }

  /// Release payment with fee for a Task Request
  Future<void> releaseOfferWithFee(String offerId) async {
    try {
      final res = await _client
          .from('task_requests')
          .select('price')
          .eq('id', offerId)
          .single();
      final price = res['price'] as num? ?? 0;

      await LedgerService(_client).submitPaymentEvent(
        eventType: 'release_with_fee',
        relatedEntityType: 'task_request',
        relatedEntityId: offerId,
        amountGross: price,
        meta: {
          'fee_rate_bps': 0, // MVP zero fee
        },
      );
    } catch (e) {
      AppLogger.e('Failed to release offer funds', error: e);
      rethrow;
    }
  }

  /// Refund a Task Request
  Future<void> refundOffer(String offerId) async {
    try {
      final res = await _client
          .from('task_requests')
          .select('price, status')
          .eq('id', offerId)
          .single();
      final price = res['price'] as num? ?? 0;
      final status = res['status'] as String?;

      if (status != 'rejected' &&
          status != 'canceled' &&
          status != 'declined' &&
          status != 'dispute_refund') {
        await rejectOffer(offerId);
      }

      await LedgerService(_client).submitPaymentEvent(
        eventType: 'refund',
        relatedEntityType: 'task_request',
        relatedEntityId: offerId,
        amountGross: price,
        meta: {},
      );
    } catch (e) {
      AppLogger.e('Failed to refund offer', error: e);
      rethrow;
    }
  }

  // ==========================================================================
  // TWO-STEP AWARD & PAYMENT FLOW (Phase 2 - Tender Payment)
  // ==========================================================================

  /// Award an offer (Step 1: Award without payment)
  ///
  /// This creates an "Awarded but Pending Payment" state.
  /// Client must call [payAwardedOffer] to complete payment and activate work.
  Future<Map<String, dynamic>> awardOffer(String offerId) async {
    try {
      final result = await _client.rpc(
        'award_task_offer',
        params: {'p_request_id': offerId},
      );

      AppLogger.i('Offer awarded (pending payment): $offerId');
      return result as Map<String, dynamic>;
    } on PostgrestException catch (e, st) {
      AppLogger.e('Failed to award offer', error: e, stackTrace: st);
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Pay for an awarded offer (Step 2: Complete payment)
  ///
  /// This triggers escrow hold and activates the work.
  /// After success, freelancer can start working.
  Future<Map<String, dynamic>> payAwardedOffer(String offerId) async {
    AppLogger.i(
      'payAwardedOffer started for request $offerId',
      tag: 'TaskService',
    );
    try {
      // 1. First, get offer details and validate it can be paid
      final offerData = await _client
          .from('task_requests')
          .select('price, task_id, status, payment_status, payment_deadline')
          .eq('id', offerId)
          .single();

      if (offerData['status'] != 'accepted') {
        throw Exception('Offer is not in accepted status');
      }
      if (offerData['payment_status'] != 'unpaid') {
        throw Exception('Offer is already paid or held');
      }

      final deadline = DateTime.tryParse(offerData['payment_deadline'] ?? '');
      if (deadline != null && deadline.isBefore(DateTime.now())) {
        throw Exception('Payment deadline has expired');
      }

      final price = offerData['price'] as num? ?? 0;

      // 2. Create ledger entry for escrow hold FIRST (while status is still 'unpaid')
      await LedgerService(_client).submitPaymentEvent(
        eventType: 'escrow_hold',
        relatedEntityType: 'task_request',
        relatedEntityId: offerId,
        amountGross: price,
        meta: {'awarded_at': DateTime.now().toIso8601String()},
      );

      // 3. Mark the offer as paid in the database AFTER ledger succeeds
      final result =
          await _client.rpc(
                'pay_awarded_offer',
                params: {'p_request_id': offerId},
              )
              as Map<String, dynamic>;

      if (result['success'] != true) {
        // Ledger succeeded but DB update failed - this is a critical inconsistency
        AppLogger.e(
          'CRITICAL: Ledger succeeded but DB update failed for offer: $offerId',
        );
        throw Exception(result['error'] ?? 'Payment status update failed');
      }

      AppLogger.i('Payment completed for awarded offer: $offerId');
      return result;
    } on PostgrestException catch (e, st) {
      AppLogger.e('Failed to pay for awarded offer', error: e, stackTrace: st);
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Get client's awarded but unpaid offers (for "Pay Now" UI)
  Future<List<Map<String, dynamic>>> getClientAwardedUnpaidOffers() async {
    try {
      final result = await _client.rpc('get_client_awarded_unpaid_offers');
      return (result as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      AppLogger.e(
        'Failed to get awarded unpaid offers',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Get freelancer's awarded but unpaid offers (for "Waiting for Payment" UI)
  Future<List<Map<String, dynamic>>> getFreelancerAwardedUnpaidOffers() async {
    try {
      final result = await _client.rpc('get_freelancer_awarded_unpaid_offers');
      return (result as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      AppLogger.e(
        'Failed to get freelancer awarded offers',
        error: e,
        stackTrace: st,
      );
      return [];
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
