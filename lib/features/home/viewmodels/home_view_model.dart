// HomeViewModel: MVVM state holder for Home feature.
//
// Architecture: This ViewModel loads tasks for the home feed and coordinates
// with TaskFilterViewModel for search/filter functionality.
//
// Design Decision - Dual ViewModel Coordination:
// The Home screen uses two ViewModels:
// 1. HomeViewModel (this) - owns the raw task data and loading state
// 2. TaskFilterViewModel - owns filtered view of tasks, search query, category filter
//
// Why separate? The filter state needs to persist across tab switches,
// while the raw data fetch is specific to the Home screen.
//
// Data Flow:
// 1. HomeViewModel.loadFeaturedTasks() fetches tasks
// 2. Results are passed to TaskFilterViewModel.setTasks()
// 3. UI uses TaskFilterViewModel.filteredTasks for display

import 'package:flutter/foundation.dart';

import '../../../core/services/logger_service.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/services/task_service.dart';
import '../../tasks/viewmodels/task_filter_view_model.dart';

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
