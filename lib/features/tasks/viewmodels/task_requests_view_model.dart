import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/proposals/data/proposal_repository.dart';
import 'package:sline_app/core/services/logger_service.dart';

/// TaskRequestsViewModel — MVVM state holder for Task Requests (Offers)
class TaskRequestsViewModel extends ChangeNotifier {
  final String taskId;
  final bool isOwner;
  final TaskRequestsService _service;
  final TaskService _taskService;
  final ProposalRepository? _proposalRepo;

  TaskRequestsViewModel({
    required this.taskId,
    this.isOwner = false,
    TaskRequestsService? service,
    TaskService? taskService,
    ProposalRepository? proposalRepo,
  })  : _service = service ?? TaskRequestsService(),
        _taskService = taskService ?? TaskService(),
        _proposalRepo = proposalRepo;

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
      if (isOwner && _proposalRepo != null) {
        final proposals = await _proposalRepo.listByTask(
          taskId: taskId,
          limit: _pageSize,
          before: null,
          isOwner: true,
        );
        final list = proposals.map(TaskRequest.fromProposal).toList();
        _items
          ..clear()
          ..addAll(list);
        _hasMore = list.length == _pageSize;
        _cursorBefore = list.isEmpty ? null : list.last.createdAt;
      } else {
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
      }
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to load initial task requests',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
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
      if (isOwner && _proposalRepo != null) {
        final proposals = await _proposalRepo.listByTask(
          taskId: taskId,
          limit: _pageSize,
          before: _cursorBefore,
          isOwner: true,
        );
        final list = proposals.map(TaskRequest.fromProposal).toList();
        _items.addAll(list);
        _hasMore = list.length == _pageSize;
        _cursorBefore = list.isEmpty ? _cursorBefore : list.last.createdAt;
      } else {
        final list = await _service.listByTask(
          taskId: taskId,
          limit: _pageSize,
          before: _cursorBefore,
        );
        _items.addAll(list);
        _hasMore = list.length == _pageSize;
        _cursorBefore = list.isEmpty ? _cursorBefore : list.last.createdAt;
      }
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to load more task requests',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Backward-compatible alias
  Future<void> loadForTask(String taskId) async {
    await loadInitial();
  }

  bool canActOn(TaskRequest req) => isOwner && req.isPending;

  /// Returns the current user's pending offer for the task, if any.
  Future<TaskRequest?> getExistingActiveOffer() async =>
      _service.getExistingActiveOfferForCurrentUser(taskId);

  // ==========================================================================
  // TWO-STEP AWARD & PAYMENT FLOW
  // ==========================================================================

  /// Step 1: Award the offer (without payment)
  ///
  /// This creates "Awarded - Pending Payment" state.
  /// Returns the awarded offer details including payment deadline.
  Future<Map<String, dynamic>?> award(String requestId) async {
    try {
      final result = await _taskService.awardOffer(requestId);

      await _refreshListAfterMutation();
      return result;
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to award offer $requestId',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
      notifyListeners();
      return null;
    }
  }

  /// Step 2: Pay for the awarded offer
  ///
  /// This completes payment, creates escrow, and activates work.
  /// Must be called after [award] and before payment deadline.
  Future<Map<String, dynamic>?> payForAwardedOffer(String requestId) async {
    try {
      final result = await _taskService.payAwardedOffer(requestId);

      await _refreshListAfterMutation();
      return result;
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to pay for awarded offer $requestId',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
      notifyListeners();
      return null;
    }
  }

  /// Legacy: Combined award+pay (keep for backward compatibility)
  ///
  /// DEPRECATED: Use [award] + [payForAwardedOffer] for new flow
  @Deprecated('Use award() and payForAwardedOffer() instead.')
  Future<void> accept(String requestId) async {
    try {
      await _taskService.escrowHoldOffer(requestId);
      await _refreshListAfterMutation();
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to accept offer $requestId',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
      notifyListeners();
    }
  }

  Future<void> reject(String requestId) async {
    try {
      final updated = await _service.reject(requestId);
      _replace(updated);
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to reject offer $requestId',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
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
      _items.insert(0, created);
      notifyListeners();
      return true;
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to submit offer UI for task $taskId',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> _refreshListAfterMutation() async {
    if (isOwner && _proposalRepo != null) {
      final proposals = await _proposalRepo.listByTask(
        taskId: taskId,
        limit: 100,
        before: null,
        isOwner: true,
      );
      _items.clear();
      _items.addAll(proposals.map(TaskRequest.fromProposal).toList());
    } else {
      final list = await _service.listByTask(taskId: taskId, limit: 100);
      _items.clear();
      _items.addAll(list);
    }
    notifyListeners();
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
    if (msg.contains('already accepted')) {
      return 'This request has already been accepted.';
    }
    return 'Something went wrong. Please try again.';
  }
}
