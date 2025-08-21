import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';

/// UI-facing controller for Task Requests (Offers) list and actions.
class TaskRequestController extends ChangeNotifier {
  final String taskId;
  final TaskRequestsService _service;

  TaskRequestController({required this.taskId, TaskRequestsService? service})
      : _service = service ?? TaskRequestsService();

  // Paging state
  final List<TaskRequest> _items = <TaskRequest>[];
  List<TaskRequest> get items => List.unmodifiable(_items);

  bool _isLoadingInitial = false;
  bool get isLoadingInitial => _isLoadingInitial;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  static const int _pageSize = 20;
  DateTime? _cursorBefore; // keyset pagination on created_at

  Future<void> loadInitial() async {
    if (_isLoadingInitial) return;
    _isLoadingInitial = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _cursorBefore = null;
      final list = await _service.listByTask(
        taskId: taskId,
        limit: _pageSize,
        before: null,
      );
      _items
        ..clear()
        ..addAll(list);
      _hasMore = list.length == _pageSize;
      _cursorBefore = list.isEmpty ? null : list.last.createdAt;
    } catch (e) {
      _errorMessage = _friendlyError(e);
    } finally {
      _isLoadingInitial = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final list = await _service.listByTask(
        taskId: taskId,
        limit: _pageSize,
        before: _cursorBefore,
      );
      _items.addAll(list);
      _hasMore = list.length == _pageSize;
      _cursorBefore = list.isEmpty ? _cursorBefore : list.last.createdAt;
    } catch (e) {
      _errorMessage = _friendlyError(e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  bool canActOn(TaskRequest req) => req.isPending;

  Future<void> accept(String requestId) async {
    try {
      final updated = await _service.accept(requestId);
      _replace(updated);
    } catch (e) {
      _errorMessage = _friendlyError(e);
      notifyListeners();
    }
  }

  Future<void> reject(String requestId) async {
    try {
      final updated = await _service.reject(requestId);
      _replace(updated);
    } catch (e) {
      _errorMessage = _friendlyError(e);
      notifyListeners();
    }
  }

  Future<bool> submitOfferUI({
    required String taskId,
    required double price,
    required int days,
    String? note,
  }) async {
    try {
      final created = await _service.submitOffer(
        taskId: taskId,
        price: price,
        days: days,
        note: note,
      );
      _items.insert(0, created); // newest-first UI
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  void _replace(TaskRequest updated) {
    final i = _items.indexWhere((e) => e.id == updated.id);
    if (i != -1) {
      _items[i] = updated;
      notifyListeners();
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('pending') && msg.contains('offer')) {
      return 'You already have a pending offer for this task.';
    }
    if (msg.contains('only the task owner')) {
      return 'Only the task owner can perform this action.';
    }
    return 'Something went wrong. Please try again.';
  }
}

/// Backward-compatible plural alias if some imports still use this name.
class TaskRequestsController extends TaskRequestController {
  TaskRequestsController({required String taskId}) : super(taskId: taskId);
}
