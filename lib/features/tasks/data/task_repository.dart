import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

/// Repository layer for Tasks feature.
/// Encapsulates TaskService and exposes a stable API to ViewModels/UI.
class TaskRepository {
  TaskRepository(SupabaseClient client)
    : _service = TaskService(),
      _client = client;

  final TaskService _service;
  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  // CRUD APIs (delegate to TaskService)
  Future<List<Task>> getTasks() => _service.getTasks();

  Future<Task> createTask(Task task) => _service.createTask(task);

  Future<void> updateTask(String taskId, Map<String, dynamic> updates) =>
      _service.updateTask(taskId, updates);

  Future<void> updateTaskStatus(String taskId, TaskStatus status) =>
      _service.updateTaskStatus(taskId, status);

  Future<void> deleteTask(String taskId) => _service.deleteTask(taskId);

  Future<List<Task>> getTasksByUser(String userId) =>
      _service.getTasksByUser(userId);

  Future<List<Task>> getTasksByStatus(TaskStatus status) =>
      _service.getTasksByStatus(status);

  Future<Task?> getTaskById(String taskId) => _service.getTaskById(taskId);
}
