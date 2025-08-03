import 'package:flutter/material.dart';
import '../../../core/services/logger_service.dart';
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

  /// Load featured tasks for home screen, optionally update a filter controller
  Future<void> loadFeaturedTasks({dynamic filterController}) async {
    _setLoading(true);
    try {
      final tasks = await _taskService.getOpenTasksForHome();
      _featuredTasks
        ..clear()
        ..addAll(tasks);

      if (filterController != null) {
        filterController.setTasks(_featuredTasks);
      }

      notifyListeners();
    } catch (e) {
      // Error: Failed to load featured tasks
      AppLogger.e('Error loading featured tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh home data, optionally update a filter controller
  Future<void> refresh({dynamic filterController}) async {
    await loadFeaturedTasks(filterController: filterController);
  }
}
