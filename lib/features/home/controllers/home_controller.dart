import 'package:flutter/material.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/services/task_service.dart';


/// Controller for managing home screen functionality
class HomeController extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final List<Task> _featuredTasks = [];
  bool _isLoading = false;

  /// List of featured tasks for home screen
  List<Task> get featuredTasks => List.unmodifiable(_featuredTasks);

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Load featured tasks for home screen
  Future<void> loadFeaturedTasks() async {
    _setLoading(true);
    try {
      final tasks = await _taskService.getOpenTasksForHome();
      _featuredTasks
        ..clear()
        ..addAll(tasks);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading featured tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh home data
  Future<void> refresh() async {
    await loadFeaturedTasks();
  }
}
