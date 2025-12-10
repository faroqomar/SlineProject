import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../models/task_model.dart';

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

  TaskService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// Standard SELECT clause for tasks (without profile JOIN).
  ///
  /// Why no JOIN: The tasks.user_id FK points to auth.users, not profiles.
  /// Profile data is fetched separately via batch query to avoid N+1.
  static const String _selectBasic = '''
    id, title, description, budget, user_id, status, task_type,
    category_id, category, created_at, deadline, skills, image_paths,
    assigned_freelancer_id,
    categories(name)
  ''';

  /// Batch-fetch profiles for a list of user IDs and return as a map.
  ///
  /// Why batch: Fetching profiles for N tasks requires 2 queries total
  /// (1 for tasks, 1 for profiles) instead of N+1 queries.
  Future<Map<String, Map<String, dynamic>>> _fetchProfilesByIds(
      Set<String> userIds) async {
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
      List<dynamic> rows, Map<String, Map<String, dynamic>> profilesMap) {
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

      AppLogger.i('Successfully fetched ${tasks.length} tasks');
      return tasks;
    } catch (e) {
      AppLogger.e('Failed to get tasks: $e');
      throw Exception('Failed to get tasks: $e');
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
    } catch (e) {
      AppLogger.e('Failed to create task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  /// Update task status (simple update, no profile data needed).
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      await _client
          .from('tasks')
          .update({'status': status.name})
          .eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }

  /// Update an existing task with arbitrary fields.
  ///
  /// Note: `updates` may include `category_id` (DB FK) or legacy `category`.
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      await _client.from('tasks').update(updates).eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Get tasks by user ID with profile data.
  ///
  /// Performance: 2 queries (tasks + profiles batch) - no N+1 issue.
  Future<List<Task>> getTasksByUser(String userId) async {
    try {
      final response = await _client
          .from('tasks')
          .select(_selectBasic)
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final rows = response as List;
      final userIds = rows
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet();

      final profilesMap = await _fetchProfilesByIds(userIds);
      return _parseTasksWithProfiles(rows, profilesMap);
    } catch (e) {
      throw Exception('Failed to get tasks by user: $e');
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
    } catch (e) {
      throw Exception('Failed to get tasks by status: $e');
    }
  }

  /// Delete a task by ID.
  Future<void> deleteTask(String taskId) async {
    AppLogger.i('Deleting task with ID: $taskId');
    try {
      await _client.from('tasks').delete().eq('id', taskId);
      AppLogger.i('Task deleted successfully: $taskId');
    } catch (e) {
      AppLogger.e('Failed to delete task: $e');
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Get open tasks for the Home screen with profile data.
  ///
  /// Performance: 2 queries (tasks + profiles batch) - no N+1 issue.
  /// This is the primary method for the home feed.
  Future<List<Task>> getOpenTasksForHome() async {
    try {
      final response = await _client
          .from('tasks')
          .select(_selectBasic)
          .eq('status', TaskStatus.open.name)
          .order('created_at', ascending: false);

      final rows = response as List;
      final userIds = rows
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet();

      final profilesMap = await _fetchProfilesByIds(userIds);
      return _parseTasksWithProfiles(rows, profilesMap);
    } catch (e) {
      throw Exception('Failed to get open tasks for home: $e');
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
    } catch (e) {
      AppLogger.e('Failed to get task by ID: $e');
      throw Exception('Failed to get task by ID: $e');
    }
  }
}
