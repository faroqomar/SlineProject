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
//
// Performance: Uses cursor-based pagination to load tasks incrementally,
// preventing the app from loading all tasks at once.

import 'package:flutter/foundation.dart';

import '../../../core/services/logger_service.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/services/task_service.dart';
import '../../tasks/viewmodels/task_filter_view_model.dart';

class HomeViewModel extends ChangeNotifier {
  final TaskService _taskService;

  HomeViewModel({TaskService? taskService})
    : _taskService = taskService ?? TaskService();

  final List<Task> _featuredTasks = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;

  // Pagination state
  String? _cursor; // ISO timestamp of last task's created_at
  bool _hasMore = true;

  // List of featured tasks for home screen
  List<Task> get featuredTasks => List.unmodifiable(_featuredTasks);

  // Current loading state (initial load)
  bool get isLoading => _isLoading;

  // Loading state for pagination (load more)
  bool get isLoadingMore => _isLoadingMore;

  // Whether more tasks are available to load
  bool get hasMore => _hasMore;

  // Load featured tasks for home screen (first page)
  // Optionally update a filter view model
  Future<void> loadFeaturedTasks({
    TaskFilterViewModel? filterController,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _cursor = null;
    _hasMore = true;
    notifyListeners();

    try {
      final tasks = await _taskService.getOpenTasksForHome();
      _featuredTasks
        ..clear()
        ..addAll(tasks);

      // Update cursor for next page
      if (tasks.isNotEmpty) {
        _cursor = tasks.last.createdAt.toUtc().toIso8601String();
      }

      // Check if we have more data
      _hasMore = tasks.length >= TaskService.defaultPageSize;

      if (filterController != null) {
        filterController.setTasks(_featuredTasks);
      }
    } catch (e) {
      AppLogger.e('Error loading featured tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more tasks (next page) - for infinite scroll
  Future<void> loadMoreTasks({TaskFilterViewModel? filterController}) async {
    if (_isLoadingMore || !_hasMore || _cursor == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final tasks = await _taskService.getOpenTasksForHome(
        cursorCreatedAtIso: _cursor,
      );

      if (tasks.isNotEmpty) {
        _featuredTasks.addAll(tasks);
        _cursor = tasks.last.createdAt.toUtc().toIso8601String();
      }

      // Check if we have more data
      _hasMore = tasks.length >= TaskService.defaultPageSize;

      if (filterController != null) {
        filterController.setTasks(_featuredTasks);
      }
    } catch (e) {
      AppLogger.e('Error loading more tasks: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Refresh home data and update the filter view model
  Future<void> refresh({required TaskFilterViewModel filterController}) async {
    await loadFeaturedTasks(filterController: filterController);
  }
}
