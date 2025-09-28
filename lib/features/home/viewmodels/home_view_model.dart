// HomeViewModel: MVVM state holder for Home feature
// Migrated logic from HomeController to ViewModel using ChangeNotifier.

import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

class HomeViewModel extends ChangeNotifier {
  final TaskService _taskService;

  HomeViewModel({TaskService? taskService}) : _taskService = taskService ?? TaskService();

  final List<Task> _featuredTasks = [];
  bool _isLoading = false;

  // List of featured tasks for home screen
  List<Task> get featuredTasks => List.unmodifiable(_featuredTasks);

  // Current loading state
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Load featured tasks for home screen, optionally update a filter view model
  Future<void> loadFeaturedTasks({TaskFilterViewModel? filterController}) async {
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
      AppLogger.e('Error loading featured tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh home data and update the filter view model
  Future<void> refresh({required TaskFilterViewModel filterController}) async {
    await loadFeaturedTasks(filterController: filterController);
  }
}
