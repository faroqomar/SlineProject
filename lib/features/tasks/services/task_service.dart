import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

/// Service for handling task operations with Supabase
class TaskService {
  final _client = Supabase.instance.client;

  /// Get all tasks from database
  Future<List<Task>> getTasks() async {
    final response = await _client
        .from('tasks')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Task.fromJson(json))
        .toList();
  }

  /// Create a new task
  Future<Task> createTask(Task task) async {
    final response = await _client
        .from('tasks')
        .insert(task.toJson())
        .select()
        .single();

    return Task.fromJson(response);
  }

  /// Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    await _client
        .from('tasks')
        .update({'status': status.name})
        .eq('id', taskId);
  }

  /// Get tasks by user ID
  Future<List<Task>> getTasksByUser(String userId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('posted_by', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Task.fromJson(json))
        .toList();
  }

  /// Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('status', status.name)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Task.fromJson(json))
        .toList();
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    await _client
        .from('tasks')
        .delete()
        .eq('id', taskId);
  }
}
