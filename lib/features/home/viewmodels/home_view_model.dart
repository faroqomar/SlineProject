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
import '../../../core/mixins/role_switch_aware.dart';
import '../../../core/services/role_switch_coordinator.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/services/task_service.dart';
import '../../tasks/viewmodels/discovery_feed_view_model_contract.dart';
import '../../tasks/viewmodels/task_filter_view_model.dart';

class HomeViewModel extends ChangeNotifier
    with RoleSwitchAware
    implements DiscoveryFeedViewModelContract {
  final TaskService _taskService;
  static int _requestSequence = 0;

  HomeViewModel({TaskService? taskService})
      : _taskService = taskService ?? TaskService() {
    // Register with role switch coordinator
    RoleSwitchCoordinator().register(this);
  }

  final List<Task> _featuredTasks = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;

  // Pagination state
  String? _cursorCreatedAtIso;
  String? _cursorId;
  bool _hasMore = true;

  // List of featured tasks for home screen
  @override
  List<Task> get featuredTasks => List.unmodifiable(_featuredTasks);

  // Current loading state (initial load)
  @override
  bool get isLoading => _isLoading;

  // Loading state for pagination (load more)
  @override
  bool get isLoadingMore => _isLoadingMore;

  // Whether more tasks are available to load
  @override
  bool get hasMore => _hasMore;

  // Load featured tasks for home screen (first page)
  // Optionally update a filter view model
  @override
  Future<void> loadFeaturedTasks({
    TaskFilterViewModel? filterController,
    String surface = 'home',
  }) async {
    if (_isLoading) return;

    final requestId = _nextFeedRequestId(
      surface: surface,
      operation: 'initial',
    );
    final stopwatch = Stopwatch()..start();
    _isLoading = true;
    _cursorCreatedAtIso = null;
    _cursorId = null;
    _hasMore = true;
    notifyListeners();
    _logFeedEvent(
      'home_feed_load_started',
      surface: surface,
      requestId: requestId,
      operation: 'initial',
      cursorPresent: false,
    );

    try {
      final tasks = await _taskService.getOpenTasksForHome(
        requestId: requestId,
        source: surface,
      );
      _featuredTasks
        ..clear()
        ..addAll(tasks);

      // Update cursor for next page
      if (tasks.isNotEmpty) {
        _cursorCreatedAtIso = tasks.last.createdAt.toUtc().toIso8601String();
        _cursorId = tasks.last.id;
      }

      // Check if we have more data
      _hasMore = tasks.length >= TaskService.defaultPageSize;

      if (filterController != null) {
        filterController.setTasks(_featuredTasks);
      }

      _logFeedEvent(
        'home_feed_load_succeeded',
        surface: surface,
        requestId: requestId,
        operation: 'initial',
        cursorPresent: false,
        resultCount: tasks.length,
        durationMs: stopwatch.elapsedMilliseconds,
        hasMore: _hasMore,
      );
    } catch (e) {
      AppLogger.e('home_feed_load_failed', tag: 'HomeFeed', error: e);
      AppLogger.w(
        'home_feed_load_failed',
        tag: 'HomeFeed',
        json: {
          'surface': surface,
          'feed_request_id': requestId,
          'operation': 'initial',
          'error_type': e.runtimeType.toString(),
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
      );
    } finally {
      stopwatch.stop();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more tasks (next page) - for infinite scroll
  @override
  Future<void> loadMoreTasks({
    TaskFilterViewModel? filterController,
    String surface = 'home',
  }) async {
    if (_isLoadingMore || !_hasMore || _cursorCreatedAtIso == null) {
      AppLogger.d(
        'home_feed_load_more_skipped',
        tag: 'HomeFeed',
        json: {
          'surface': surface,
          'is_loading_more': _isLoadingMore,
          'has_more': _hasMore,
          'cursor_present': _cursorCreatedAtIso != null,
        },
      );
      return;
    }

    final requestId = _nextFeedRequestId(
      surface: surface,
      operation: 'load_more',
    );
    final stopwatch = Stopwatch()..start();
    _isLoadingMore = true;
    notifyListeners();
    _logFeedEvent(
      'home_feed_load_started',
      surface: surface,
      requestId: requestId,
      operation: 'load_more',
      cursorPresent: true,
    );

    try {
      final tasks = await _taskService.getOpenTasksForHome(
        cursorCreatedAtIso: _cursorCreatedAtIso,
        cursorId: _cursorId,
        requestId: requestId,
        source: surface,
      );

      if (tasks.isNotEmpty) {
        _featuredTasks.addAll(tasks);
        _cursorCreatedAtIso = tasks.last.createdAt.toUtc().toIso8601String();
        _cursorId = tasks.last.id;
      }

      // Check if we have more data
      _hasMore = tasks.length >= TaskService.defaultPageSize;

      if (filterController != null) {
        filterController.setTasks(_featuredTasks);
      }

      _logFeedEvent(
        'home_feed_load_succeeded',
        surface: surface,
        requestId: requestId,
        operation: 'load_more',
        cursorPresent: true,
        resultCount: tasks.length,
        durationMs: stopwatch.elapsedMilliseconds,
        hasMore: _hasMore,
      );
    } catch (e) {
      AppLogger.e('home_feed_load_failed', tag: 'HomeFeed', error: e);
      AppLogger.w(
        'home_feed_load_failed',
        tag: 'HomeFeed',
        json: {
          'surface': surface,
          'feed_request_id': requestId,
          'operation': 'load_more',
          'error_type': e.runtimeType.toString(),
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
      );
    } finally {
      stopwatch.stop();
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Refresh home data and update the filter view model
  @override
  Future<void> refresh({
    required TaskFilterViewModel filterController,
    String surface = 'home',
  }) async {
    await loadFeaturedTasks(
      filterController: filterController,
      surface: surface,
    );
  }

  String _nextFeedRequestId({
    required String surface,
    required String operation,
  }) {
    _requestSequence += 1;
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    return '${surface}_${operation}_${timestamp}_$_requestSequence';
  }

  void _logFeedEvent(
    String eventName, {
    required String surface,
    required String requestId,
    required String operation,
    required bool cursorPresent,
    int? resultCount,
    int? durationMs,
    bool? hasMore,
  }) {
    AppLogger.i(
      eventName,
      tag: 'HomeFeed',
      json: {
        'surface': surface,
        'feed_request_id': requestId,
        'operation': operation,
        'cursor_present': cursorPresent,
        if (resultCount != null) 'result_count': resultCount,
        if (durationMs != null) 'duration_ms': durationMs,
        if (hasMore != null) 'has_more': hasMore,
      },
    );
  }

  @override
  void dispose() {
    RoleSwitchCoordinator().unregister(this);
    super.dispose();
  }

  /// RoleSwitchAware implementation: Teardown during role switch.
  @override
  Future<void> teardownForRoleSwitch() async {
    AppLogger.i('home_teardown_role_switch', tag: 'HomeVM');

    // Clear all cached feed data
    _featuredTasks.clear();
    _isLoading = false;
    _isLoadingMore = false;
    _cursorCreatedAtIso = null;
    _cursorId = null;
    _hasMore = true;
    _requestSequence = 0;

    AppLogger.i('home_teardown_complete', tag: 'HomeVM');
    notifyListeners();
  }
}
