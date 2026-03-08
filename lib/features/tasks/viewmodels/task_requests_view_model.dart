import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/proposals/data/proposal_repository.dart';
import 'package:sline_app/core/services/logger_service.dart';

export 'package:sline_app/features/tasks/services/task_requests_service.dart'
    show PriceMismatchException, OfferAlreadyAcceptedException;

/// TaskRequestsViewModel — MVVM state holder for Task Requests (Offers)
///
/// Includes hardened state management (Phase 2.3):
/// - Double-submit prevention via loading flags (_isSubmitting, _isAwarding, _isRejecting)
/// - Rate limiting via debouncing (2-second minimum between submits, T4: Bid Spam)
/// - Optimistic updates with automatic rollback on error
/// - Concurrent operation blocking (T2: Double Acceptance Race)
/// - Comprehensive error recovery with clearError()
/// - Full AppLogger instrumentation for all state transitions
class TaskRequestsViewModel extends ChangeNotifier {
  final String taskId;
  final bool isOwner;
  final TaskRequestsService _service;
  final TaskService _taskService;
  final ProposalRepository? _proposalRepo;

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
       _proposalRepo = proposalRepo;

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
  String? get errorMessage => _errorMessage;

  static const int _pageSize = 20;
  DateTime? _cursorBefore; // keyset pagination on created_at

  // ==========================================================================
  // LOADING STATE FLAGS — Prevent Double-Submit / Double-Click
  // See: THREAT_MODEL.md T2 (Double Acceptance Race)
  // ==========================================================================
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _isAwarding = false;
  bool get isAwarding => _isAwarding;

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

  /// Clears the current error message.
  /// Call this when user initiates a retry action.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
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
      AppLogger.d(
        'Loaded \${_items.length} initial items',
        tag: 'TaskRequests',
      );
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
    if (!_hasMore || _isLoadingMore) {
      AppLogger.w(
        'Blocked loadMore: hasMore=\$_hasMore, isLoadingMore=\$_isLoadingMore',
        tag: 'TaskRequests',
      );
      return;
    }
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
      AppLogger.d(
        'Loaded more items, total: \${_items.length}',
        tag: 'TaskRequests',
      );
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
    } catch (e, st) {
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
  // TWO-STEP AWARD & PAYMENT FLOW
  // ==========================================================================

  /// Step 1: Award the offer (without payment)
  ///
  /// This creates "Awarded - Pending Payment" state.
  /// [expectedPriceCents] is the price the client saw when clicking Award.
  /// Returns the awarded offer details including payment deadline.
  Future<Map<String, dynamic>?> award(
    String requestId, {
    int? expectedPriceCents,
  }) async {
    // Prevent concurrent award operations (T2: Double Acceptance Race)
    if (_isAwarding) {
      AppLogger.w(
        'Blocked concurrent award attempt for request \$requestId',
        tag: 'TaskRequests',
      );
      _errorMessage = 'An award is already in progress. Please wait.';
      notifyListeners();
      return null;
    }

    _isAwarding = true;
    _errorMessage = null;
    notifyListeners();

    AppLogger.i(
      'Starting award flow for request \$requestId',
      tag: 'TaskRequests',
    );

    try {
      final result = await _taskService.awardOffer(
        requestId,
        expectedPriceCents: expectedPriceCents,
      );

      AppLogger.i(
        'Award completed successfully for request \$requestId',
        tag: 'TaskRequests',
      );

      await _refreshListAfterMutation();
      return result;
    } on PriceMismatchException catch (e) {
      AppLogger.w(
        'Price mismatch during award: expected ${e.expectedCents}, got ${e.actualCents}',
        tag: 'TaskRequests',
      );
      rethrow;
    } on OfferAlreadyAcceptedException {
      AppLogger.w(
        'Offer already accepted during award (race condition)',
        tag: 'TaskRequests',
      );
      rethrow;
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to award offer \$requestId',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
      notifyListeners();
      return null;
    } finally {
      _isAwarding = false;
      notifyListeners();
      AppLogger.d(
        'Award operation completed, flag cleared',
        tag: 'TaskRequests',
      );
    }
  }

  /// Step 2: Pay for the awarded offer
  ///
  /// This completes payment, creates escrow, and activates work.
  /// Must be called after [award] and before payment deadline.
  Future<Map<String, dynamic>?> payForAwardedOffer(String requestId) async {
    // Note: Payment has its own loading state managed by UI typically,
    // but we check _isAwarding to prevent concurrent operations
    if (_isAwarding) {
      AppLogger.w(
        'Blocked pay attempt during active award operation',
        tag: 'TaskRequests',
      );
      _errorMessage = 'Please wait for the current operation to complete.';
      notifyListeners();
      return null;
    }

    _errorMessage = null;
    notifyListeners();

    AppLogger.i(
      'Starting payment flow for request \$requestId',
      tag: 'TaskRequests',
    );

    try {
      final result = await _taskService.payAwardedOffer(requestId);

      AppLogger.i(
        'Payment completed successfully for request \$requestId',
        tag: 'TaskRequests',
      );

      await _refreshListAfterMutation();
      return result;
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to pay for awarded offer \$requestId',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
      notifyListeners();
      return null;
    }
  }

  /// Accepts an offer with optimistic concurrency control via price validation.
  ///
  /// [expectedPriceCents] should be the price the client saw when clicking Accept.
  /// If the freelancer changed their offer since then, a [PriceMismatchException]
  /// will be thrown. The UI should catch this and prompt the user to refresh.
  ///
  /// Returns true on success, false on failure (check [errorMessage]).
  Future<bool> acceptOffer(
    TaskRequest request, {
    int? expectedPriceCents,
  }) async {
    // Prevent concurrent accept operations (T2: Double Acceptance Race)
    if (_isAwarding) {
      AppLogger.w(
        'Blocked concurrent accept attempt (award in progress)',
        tag: 'TaskRequests',
      );
      _errorMessage = 'An operation is already in progress. Please wait.';
      notifyListeners();
      return false;
    }

    _isAwarding = true; // Re-use awarding flag for accept operation
    _errorMessage = null;
    notifyListeners();

    AppLogger.i(
      'Starting accept flow for request \${request.id}',
      tag: 'TaskRequests',
    );

    try {
      // DB stores task_requests.price in IQD; RPC expects p_expected_price_cents = price * 100
      final priceCents = expectedPriceCents ?? (request.price * 100);

      AppLogger.d(
        'Accepting offer \${request.id} with expected price: \$priceCents cents',
        tag: 'TaskRequests',
      );

      await _service.accept(
        request.id,
        taskId: taskId,
        expectedPriceCents: priceCents,
      );

      AppLogger.i(
        'Offer \${request.id} accepted successfully',
        tag: 'TaskRequests',
      );

      // Success - refresh the list
      await _refreshListAfterMutation();
      return true;
    } on PriceMismatchException catch (e) {
      // Log the price mismatch for security monitoring
      AppLogger.w(
        'Price mismatch detected: expected ${e.expectedCents} cents, got ${e.actualCents} cents',
        tag: 'TaskRequests',
      );

      // Refresh to get latest data
      await _refreshListAfterMutation();

      // Re-throw so UI can show error dialog
      rethrow;
    } on OfferAlreadyAcceptedException catch (_) {
      AppLogger.w(
        'Offer already accepted (idempotency hit)',
        tag: 'TaskRequests',
      );

      // Refresh and return success since it's already accepted
      await _refreshListAfterMutation();
      return true;
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to accept offer \${request.id}',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
      notifyListeners();
      return false;
    } finally {
      _isAwarding = false;
      notifyListeners();
      AppLogger.d(
        'Accept operation completed, flag cleared',
        tag: 'TaskRequests',
      );
    }
  }

  /// Cancel an awarded-but-unpaid offer. Returns task to open status.
  /// Only the task owner can cancel. Shows confirmation dialog in UI.
  Future<bool> cancelAwardedOffer(String requestId) async {
    // Prevent concurrent operations
    if (_isAwarding || _isRejecting) {
      AppLogger.w(
        'Blocked cancel attempt during active operation',
        tag: 'TaskRequests',
      );
      _errorMessage = 'Please wait for the current operation to complete.';
      notifyListeners();
      return false;
    }

    _isAwarding = true; // Re-use flag to block concurrent ops
    _errorMessage = null;
    notifyListeners();

    AppLogger.i(
      'Starting cancel flow for awarded offer $requestId',
      tag: 'TaskRequests',
    );

    try {
      final result = await _taskService.cancelAwardedOffer(requestId);

      if (result['success'] == true) {
        AppLogger.i(
          'Successfully cancelled awarded offer $requestId',
          tag: 'TaskRequests',
        );
        await _refreshListAfterMutation();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to cancel offer';
        AppLogger.w(
          'Cancel failed for $requestId: $_errorMessage',
          tag: 'TaskRequests',
        );
        notifyListeners();
        return false;
      }
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to cancel awarded offer $requestId',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
      notifyListeners();
      return false;
    } finally {
      _isAwarding = false;
      notifyListeners();
      AppLogger.d(
        'Cancel operation completed, flag cleared',
        tag: 'TaskRequests',
      );
    }
  }

  /// Returns true if the error is retryable (network, timeout, etc.)
  bool isRetryableError(String? error) {
    if (error == null) return false;
    final msg = error.toLowerCase();
    return msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('unavailable') ||
        msg.contains('try again');
  }

  /// Legacy: Combined award+pay (keep for backward compatibility)
  ///
  /// DEPRECATED: Use [award] + [payForAwardedOffer] for new flow
  @Deprecated('Use award() and payForAwardedOffer() instead.')
  Future<void> accept(String requestId) async {
    if (_isAwarding) {
      AppLogger.w(
        'Blocked concurrent legacy accept attempt',
        tag: 'TaskRequests',
      );
      _errorMessage = 'An operation is already in progress.';
      notifyListeners();
      return;
    }

    _isAwarding = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskService.escrowHoldOffer(requestId);
      await _refreshListAfterMutation();
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to accept offer \$requestId',
        error: e,
        stackTrace: st,
        tag: 'TaskRequests',
      );
      notifyListeners();
    } finally {
      _isAwarding = false;
      notifyListeners();
    }
  }

  Future<void> reject(String requestId) async {
    // Prevent concurrent reject operations
    if (_isRejecting) {
      AppLogger.w(
        'Blocked concurrent reject attempt for request \$requestId',
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
      'Starting reject flow for request \$requestId',
      tag: 'TaskRequests',
    );

    try {
      final updated = await _service.reject(requestId);

      AppLogger.i(
        'Request \$requestId rejected successfully',
        tag: 'TaskRequests',
      );

      _replace(updated);
    } catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to reject offer \$requestId',
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
        'Blocked double-submit attempt for task \$taskId',
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
        id: 'optimistic-\${DateTime.now().millisecondsSinceEpoch}',
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
        'Optimistic offer added to UI: \${optimisticOffer.id}',
        tag: 'TaskRequests',
      );
    } catch (e, st) {
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
            'Optimistic offer replaced with server response: \${created.id}',
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
        'Offer submitted successfully: \${created.id} for task \$taskId',
        tag: 'TaskRequests',
      );

      notifyListeners();
      return true;
    } catch (e, st) {
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
        'Failed to submit offer UI for task \$taskId',
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
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Please wait a moment before trying again.';
    }
    if (msg.contains('deadline expired')) {
      return 'The payment deadline has expired. Please refresh and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
