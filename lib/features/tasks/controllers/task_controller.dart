import 'package:flutter/material.dart';
import '../models/task_model.dart';

/// Controller for managing task functionality
class TaskController extends ChangeNotifier {
  final List<Task> _tasks = [];
  bool _isLoading = false;

  /// List of tasks
  List<Task> get tasks => List.unmodifiable(_tasks);

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Load all tasks
  Future<void> loadTasks() async {
    _setLoading(true);
    try {
      // TODO: Implement loading tasks from Supabase
      // final tasks = await _taskService.getTasks();
      // _tasks.clear();
      // _tasks.addAll(tasks);
      
      // Mock data for now
      _tasks.clear();
      _tasks.addAll([
        Task(
          id: '1',
          title: 'Website Development',
          description: 'Need a modern website for my business',
          budget: 500.0,
          userId: 'client1',
          status: TaskStatus.open,
          createdAt: DateTime.now().subtract(const Duration(days: 2)), category: '',
        ),
        Task(
          id: '2',
          title: 'Mobile App Design',
          description: 'Design UI/UX for mobile application',
          budget: 800.0,
          userId: 'client2',
          status: TaskStatus.open,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)), category: '',
        ),
      ]);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new task
  Future<void> createTask(Task task) async {
    _setLoading(true);
    try {
      // TODO: Implement task creation in Supabase
      // await _taskService.createTask(task);
      
      _tasks.add(task);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating task: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(status: status);
        notifyListeners();
        
        // TODO: Update in Supabase
        // await _taskService.updateTaskStatus(taskId, status);
      }
    } catch (e) {
      debugPrint('Error updating task status: $e');
    }
  }

  /// Get tasks by status
  List<Task> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }
}
