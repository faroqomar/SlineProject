// SavedTasksController
// Holds UI state for saved (bookmarked) tasks.
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

import '../data/saved_tasks_service.dart';

final _savedCtrlLogger = Logger();

class SavedTasksController extends ChangeNotifier {
  final SavedTasksService service;

  SavedTasksController({required this.service});

  final Set<String> _savedTaskIds = <String>{};
  bool _loading = false;
  String? _error;
  List<Task> _savedTasks = [];

  bool get isLoading => _loading;
  String? get error => _error;
  bool isSaved(String taskId) => _savedTaskIds.contains(taskId);

  /// Public read-only view of saved task ids for UI lists.
  List<String> get savedTaskIds => List.unmodifiable(_savedTaskIds);

  /// Full saved tasks (with details).
  List<Task> get savedTasks => List.unmodifiable(_savedTasks);

  Future<void> load() async {
    _setLoading(true);
    _setError(null);
    try {
      final list = await service.listMineWithDetails();
      _savedTasks = list;
      _savedTaskIds
        ..clear()
        ..addAll(list.map((e) => e.id));
    } catch (e, st) {
      _savedCtrlLogger.e('SavedTasksController.load failed', error: e, stackTrace: st);
      _setError(_humanize(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() => load();

  /// Toggle save state for a task and update local cache.
  Future<bool> toggle(String taskId) async {
    try {
      final nowSaved = await service.toggle(taskId);
      if (nowSaved) {
        _savedTaskIds.add(taskId);
      } else {
        _savedTaskIds.remove(taskId);
      }
      notifyListeners();
      // Also reload full tasks list
      try {
        _savedTasks = await service.listMineWithDetails();
      } catch (_) {
        // ignore errors here
      }
      return nowSaved;
    } catch (e, st) {
      _savedCtrlLogger.e('SavedTasksController.toggle failed', error: e, stackTrace: st);
      _setError(_humanize(e));
      rethrow;
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  String _humanize(Object e) {
    final s = e.toString();
    if (s.contains('Not authenticated')) {
      return 'Please sign in.';
    }
    if (s.contains('23505')) {
      return 'Already saved.';
    }
    if (s.toLowerCase().contains('rls')) {
      return 'Not allowed.';
    }
    return 'Something went wrong.';
  }
}
