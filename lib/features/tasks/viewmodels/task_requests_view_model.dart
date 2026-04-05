import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/proposals/data/proposal_repository.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_award_delegate.dart';

export 'package:sline_app/features/tasks/services/task_requests_service.dart'
    show OfferAlreadyAcceptedException, PriceMismatchException;

/// TaskRequestsViewModel — MVVM state holder for Task Requests (Offers)
///
/// Includes hardened state management (Phase 2.3):
/// - Double-submit prevention via loading flags (_isSubmitting, _isRejecting)
/// - Rate limiting via debouncing (2-second minimum between submits, T4: Bid Spam)
/// - Optimistic updates with automatic rollback on error
/// - Concurrent operation blocking (T2: Double Acceptance Race)
/// - Comprehensive error recovery with clearError()
/// - Full AppLogger instrumentation for all state transitions
///
/// Award, payment, accept, and cancel-award operations are delegated to
/// [TaskRequestsAwardDelegate] (Phase D delegate pattern).
class TaskRequestsViewModel extends ChangeNotifier {
  final String taskId;
  final bool isOwner;
  final TaskRequestsService _service;
  final TaskService _taskService;
  ProposalRepository? _proposalRepo;

  late final TaskRequestsAwardDelegate _awardDelegate;

  // Debounce configuration for rate limiting
  static const Duration _submitDebounceDuration = Duration(seconds: 2);

  TaskRequestsViewModel({
    required this.taskId,
    this.isOwner = false,
    TaskRequestsService? service,
    TaskService? taskService,
    ProposalRepository? proposalRepo,
  }) : _service = service ?? TaskRequestsService(),
       _taskService = taskService ?? TaskService(),
       _proposalRepo = proposalRepo {
    if (_proposalRepo == null && isOwner) {
      _proposalRepo = ProposalRepository(taskRequestsService: _service);
      AppLogger.d(
        'TaskRequestsViewModel self-constructed ProposalRepository for owner',
        tag: 'TaskRequestsViewModel',
      );
    }

    _awardDelegate = TaskRequestsAwardDelegate(
      taskId: taskId,
      taskService: _taskService,
      service: _service,
      onChanged: notifyListeners,
      refreshList: _refreshListAfterMutation,
    );
  }

  // ==========================================================================
  // PAGING STATE
  // ==========================================================================
  final List<TaskRequest> _items = <TaskRequest>[];
  List<TaskRequest> get items => List.unmodifiable(_items);

  bool _isLoadingInitial = false;
  bool get isLoadingInitial => _isLoadingInitial;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage ?? _awardDelegate.errorMessage;

  static const int _pageSize = 20;
  DateTime? _cursorBefore; // keyset pagination on created_at

  // ==========================================================================
  // LOADING STATE FLAGS — Prevent Double-Submit / Double-Click
  // See: THREAT_MODEL.md T2 (Double Acceptance Race)
  // ==========================================================================
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  /// Forwarding getter — award flag lives in the delegate.
  bool get isAwarding => _awardDelegate.isAwarding;

  bool _isRejecting = false;
  bool get isRejecting => _isRejecting;

  // ==========================================================================
  // DEBOUNCE STATE — Rate Limiting (T4: Bid Spam prevention)
  // ==========================================================================
  DateTime? _lastSubmitAttempt;
  DateTime? get lastSubmitAttempt => _lastSubmitAttempt;

  /// Returns remaining debounce time in milliseconds.
  /// Returns 0 if debounce period has elapsed.
  int get remainingDebounceMs {
    if (_lastSubmitAttempt == null) return 0;
    final elapsed = DateTime.now().difference(_lastSubmitAttempt!);
    final remaining = _submitDebounceDuration - elapsed;
    return remaining.inMilliseconds.clamp(0, 999999);
  }

  /// Returns true if submit is currently rate-limited
  bool get isSubmitRateLimited => remainingDebounceMs > 0;

  // ==========================================================================
  // OPTIMISTIC UPDATE STATE — For Rollback on Error
  // ==========================================================================
  TaskRequest? _optimisticPendingOffer;
  bool get hasOptimisticUpdate => _optimisticPendingOffer != null;

  // ==========================================================================
  // ERROR RECOVERY
  // ==========================================================================

  /// Clears the current error message (both local and delegate).
  /// Call this when user initiates a retry action.
  void clearError() {
    var changed = false;
    if (_errorMessage != null) {
      _errorMessage = null;
      changed = true;
    }
    if (_awardDelegate.errorMessage != null) {
      _awardDelegate.clearError();
      changed = true;
    }
    if (changed) {
      AppLogger.d('Error state cleared by user', tag: 'TaskRequests');
      notifyListeners();
    }
  }

  // ==========================================================================
  // DATA LOADING
  // ==========================================================================

  Future<void> loadInitial() async {
    if (_isLoadingInitial) {
      AppLogger.w('Blocked concurrent loadInitial call', tag: 'TaskRequests');
      return;
    }
    _isLoadingInitial = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _cursorBefore = null;
      if (isOwner && _proposalRepo != null) {
        final proposals = await _proposalRepo!.listByTask(
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
      AppLogger.d(
        r'Loaded ${_items.length} initial items',
        tag: 'TaskRequests',
      );
    } on Exception catch (e, st) {
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
    if (!_hasMore || _isLoadingMore) {
      AppLogger.w(
        r'Blocked loadMore: hasMore=$_hasMore, isLoadingMore=$_isLoadingMore',
        tag: 'TaskRequests',
      );
      return;
    }
    _isLoadingMore = true;
    notifyListeners();
    try {
      if (isOwner && _proposalRepo != null) {
        final proposals = await _proposalRepo!.listByTask(
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
      AppLogger.d(
        r'Loaded more items, total: ${_items.length}',
        tag: 'TaskRequests',
      );
    } on Exception catch (e, st) {
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

  /// Checks if the current user's bid on this task is replaceable.
  ///
  /// Returns [BidReplaceabilityResult] containing:
  /// - isReplaceable: true if user has a pending bid (can replace)
  /// - existingBid: the existing bid if one exists
  Future<BidReplaceabilityResult> checkBidReplaceability() async {
    AppLogger.d(
      'Checking bid replaceability for task $taskId',
      tag: 'TaskRequests',
    );
    try {
      final result = await _service.isBidReplaceable(taskId);
      AppLogger.d(
        'Bid replaceability result: isReplaceable=${result.isReplaceable}, hasExistingBid=${result.existingBid != null}',
        tag: 'TaskRequests',
      );
      return result;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to check bid replaceability for task $taskId',
        tag: 'TaskRequests',
        error: e,
        stackTrace: st,
      );
      // Return non-replaceable on error for safety
      return const BidReplaceabilityResult(
        isReplaceable: false,
        existingBid: null,
      );
    }
  }

  // ==========================================================================
  // AWARD & PAYMENT — Forwarded to TaskRequestsAwardDelegate
  // ==========================================================================

  /// Step 1: Award the offer (without payment).
  /// See [TaskRequestsAwardDelegate.award].
  Future<Map<String, dynamic>?> award(
    String requestId, {
    int? expectedPriceCents,
  }) =>
      _awardDelegate.award(requestId, expectedPriceCents: expectedPriceCents);

  /// Step 2: Pay for the awarded offer.
  /// See [TaskRequestsAwardDelegate.payForAwardedOffer].
  Future<Map<String, dynamic>?> payForAwardedOffer(String requestId) =>
      _awardDelegate.payForAwardedOffer(requestId);

  /// Accepts an offer with optimistic concurrency control.
  /// See [TaskRequestsAwardDelegate.acceptOffer].
  Future<bool> acceptOffer(
    TaskRequest request, {
    int? expectedPriceCents,
  }) =>
      _awardDelegate.acceptOffer(
        request,
        expectedPriceCents: expectedPriceCents,
      );

  /// Cancel an awarded-but-unpaid offer.
  /// See [TaskRequestsAwardDelegate.cancelAwardedOffer].
  Future<bool> cancelAwardedOffer(String requestId) =>
      _awardDelegate.cancelAwardedOffer(requestId);

  /// Returns true if the error is retryable (network, timeout, etc.)
  bool isRetryableError(String? error) =>
      _awardDelegate.isRetryableError(error);

  /// Legacy: Combined award+pay (keep for backward compatibility)
  @Deprecated('Use award() and payForAwardedOffer() instead.')
  Future<void> accept(String requestId) =>
      // ignore: deprecated_member_use_from_same_package
      _awardDelegate.acceptLegacy(requestId);

  // ==========================================================================
  // REJECT
  // ==========================================================================

  Future<void> reject(String requestId) async {
    // Prevent concurrent reject operations
    if (_isRejecting) {
      AppLogger.w(
        r'Blocked concurrent reject attempt for request $requestId',
        tag: 'TaskRequests',
      );
      _errorMessage = 'A reject operation is already in progress.';
      notifyListeners();
      return;
    }

    _isRejecting = true;
    _errorMessage = null;
    notifyListeners();

    AppLogger.i(
      r'Starting reject flow for request $requestId',
      tag: 'TaskRequests',
    );

    try {
      final updated = await _service.reject(requestId);

      AppLogger.i(
        r'Request $requestId rejected successfully',
        tag: 'TaskRequests',
      );

      _replace(updated);
    } on Exception catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        r'Failed to reject offer $requestId',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
      notifyListeners();
    } finally {
      _isRejecting = false;
      notifyListeners();
      AppLogger.d(
        'Reject operation completed, flag cleared',
        tag: 'TaskRequests',
      );
    }
  }

  /// Submits a new offer with comprehensive protection against:
  /// - Double-submit (via _isSubmitting flag)
  /// - Rate limiting (via 2-second debounce, T4: Bid Spam)
  /// - Optimistic update with automatic rollback
  ///
  /// Returns true on success, false on failure.
  Future<bool> submitOfferUI({
    required String taskId,
    required double price,
    required int days,
    String? note,
  }) async {
    // 1. Check for concurrent submit operation (Double-submit prevention)
    if (_isSubmitting) {
      AppLogger.w(
        r'Blocked double-submit attempt for task $taskId',
        tag: 'TaskRequests',
      );
      _errorMessage = 'An offer submission is already in progress.';
      notifyListeners();
      return false;
    }

    // 2. Check rate limiting (T4: Bid Spam prevention)
    if (isSubmitRateLimited) {
      final remainingSec = (remainingDebounceMs / 1000).ceil();
      AppLogger.w(
        'Rate limited: submit attempted ${remainingDebounceMs}ms too early',
        tag: 'TaskRequests',
      );
      _errorMessage =
          'Please wait $remainingSec seconds before submitting another offer.';
      notifyListeners();
      return false;
    }

    // 3. Set state and record attempt time
    _isSubmitting = true;
    _lastSubmitAttempt = DateTime.now();
    _errorMessage = null;
    notifyListeners();

    // 4. Create optimistic offer for immediate UI feedback
    TaskRequest? optimisticOffer;
    try {
      optimisticOffer = TaskRequest(
        id: r'optimistic-${DateTime.now().millisecondsSinceEpoch}',
        taskId: taskId,
        bidderId: 'current-user', // Will be replaced by server
        price: (price * 100).round(), // Convert to cents (int)
        days: days,
        note: note,
        status: OfferStatus.pending,
        paymentStatus: PaymentStatus.unpaid,
        createdAt: DateTime.now(),
      );

      // Optimistically add to list for immediate UI feedback
      _optimisticPendingOffer = optimisticOffer;
      _items.insert(0, optimisticOffer);
      notifyListeners();

      AppLogger.d(
        r'Optimistic offer added to UI: ${optimisticOffer.id}',
        tag: 'TaskRequests',
      );
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to create optimistic offer',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
      // Continue with server call even if optimistic update fails
    }

    // 5. Execute server call
    try {
      final created = await _service.submitOffer(
        taskId: taskId,
        price: price,
        days: days,
        note: note,
      );

      // 6. Replace optimistic offer with real server response
      if (optimisticOffer != null) {
        final index = _items.indexWhere((o) => o.id == optimisticOffer!.id);
        if (index != -1) {
          _items[index] = created;
          AppLogger.d(
            r'Optimistic offer replaced with server response: ${created.id}',
            tag: 'TaskRequests',
          );
        } else {
          // Shouldn't happen, but handle gracefully
          _items.insert(0, created);
        }
      } else {
        _items.insert(0, created);
      }

      _optimisticPendingOffer = null;

      AppLogger.i(
        'Offer submitted successfully: ${created.id} for task $taskId',
        tag: 'TaskRequests',
      );

      notifyListeners();
      return true;
    } on Exception catch (e, st) {
      // 7. Rollback optimistic update on error
      if (optimisticOffer != null) {
        _items.removeWhere((o) => o.id == optimisticOffer!.id);
        _optimisticPendingOffer = null;
        AppLogger.w(
          'Rolled back optimistic offer due to error',
          tag: 'TaskRequests',
        );
      }

      _errorMessage = _friendlyError(e);
      AppLogger.e(
        r'Failed to submit offer UI for task $taskId',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
      notifyListeners();
      return false;
    } finally {
      // 8. Always clear submitting flag
      _isSubmitting = false;
      notifyListeners();
      AppLogger.d(
        'Submit operation completed, flag cleared',
        tag: 'TaskRequests',
      );
    }
  }

  /// Manually rollback an optimistic update if needed.
  /// This is a safety valve for edge cases.
  void rollbackOptimisticUpdate() {
    if (_optimisticPendingOffer != null) {
      _items.removeWhere((o) => o.id == _optimisticPendingOffer!.id);
      _optimisticPendingOffer = null;
      AppLogger.w(
        'Manual rollback executed: removed optimistic item',
        tag: 'TaskRequests',
      );
      notifyListeners();
    }
  }

  Future<void> _refreshListAfterMutation() async {
    if (isOwner && _proposalRepo != null) {
      final proposals = await _proposalRepo!.listByTask(
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
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Please wait a moment before trying again.';
    }
    if (msg.contains('deadline expired')) {
      return 'The payment deadline has expired. Please refresh and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
