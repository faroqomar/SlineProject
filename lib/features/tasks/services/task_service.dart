import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

/// Service for handling task operations with Supabase
class TaskService {
  final _client = Supabase.instance.client;

  /// Get all tasks from database
  Future<List<Task>> getTasks() async {
    try {
      final response = await _client
          .from('tasks')
          .select('*')
          .order('created_at', ascending: false);

      final tasks = (response as List)
          .map((json) => Task.fromJson(json))
          .toList();

      for (var i = 0; i < tasks.length; i++) {
        final user = await _client
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', tasks[i].userId)
            .maybeSingle();

        if (user != null) {
          tasks[i] = tasks[i].copyWith(
            userName: user['full_name'] as String?,
            userAvatar: user['avatar_url'] as String?,
          );
        }
      }

      return tasks;
    } catch (e) {
      throw Exception('Failed to get tasks: $e');
    }
  }

  /// Create a new task
  Future<Task> createTask(Task task) async {
    try {
      final response = await _client
          .from('tasks')
          .insert(task.toJson(includeSystemFields: false))
          .select('*')
          .single();

      // Fetch user details separately
      final user = await _client
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', response['user_id'])
          .maybeSingle();

      var createdTask = Task.fromJson(response);
      if (user != null) {
        createdTask = createdTask.copyWith(
          userName: user['full_name'] as String?,
          userAvatar: user['avatar_url'] as String?,
        );
      }

      return createdTask;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  /// Update task status
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
/// Update an existing task
Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
  try {
    await _client.from('tasks').update(updates).eq('id', taskId);
  } catch (e) {
    throw Exception('Failed to update task: $e');
  }
}
  /// Get tasks by user ID
  Future<List<Task>> getTasksByUser(String userId) async {
    try {
      final response = await _client
          .from('tasks')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final tasks = (response as List)
          .map((json) => Task.fromJson(json))
          .toList();

      for (var i = 0; i < tasks.length; i++) {
        final user = await _client
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', tasks[i].userId)
            .maybeSingle();

        if (user != null) {
          tasks[i] = tasks[i].copyWith(
            userName: user['full_name'] as String?,
            userAvatar: user['avatar_url'] as String?,
          );
        }
      }

      return tasks;
    } catch (e) {
      throw Exception('Failed to get tasks by user: $e');
    }
  }

  /// Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    try {
      final response = await _client
          .from('tasks')
          .select('*')
          .eq('status', status.name)
          .order('created_at', ascending: false);

      final tasks = (response as List)
          .map((json) => Task.fromJson(json))
          .toList();

      for (var i = 0; i < tasks.length; i++) {
        final user = await _client
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', tasks[i].userId)
            .maybeSingle();

        if (user != null) {
          tasks[i] = tasks[i].copyWith(
            userName: user['full_name'] as String?,
            userAvatar: user['avatar_url'] as String?,
          );
        }
      }

      return tasks;
    } catch (e) {
      throw Exception('Failed to get tasks by status: $e');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _client
          .from('tasks')
          .delete()
          .eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Get open tasks for the Home screen
  Future<List<Task>> getOpenTasksForHome() async {
    try {
      final response = await _client
          .from('tasks')
          .select('*')
          .eq('status', TaskStatus.open.name)
          .order('created_at', ascending: false);

      final tasks = (response as List)
          .map((json) => Task.fromJson(json))
          .toList();

      for (var i = 0; i < tasks.length; i++) {
        final user = await _client
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', tasks[i].userId)
            .maybeSingle();

        if (user != null) {
          tasks[i] = tasks[i].copyWith(
            userName: user['full_name'] as String?,
            userAvatar: user['avatar_url'] as String?,
          );
        }
      }

      return tasks;
    } catch (e) {
      throw Exception('Failed to get open tasks for home: $e');
    }
  }
}
