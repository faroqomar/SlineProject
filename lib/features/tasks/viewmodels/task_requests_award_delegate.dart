import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';

export 'package:sline_app/features/tasks/services/task_requests_service.dart'
    show OfferAlreadyAcceptedException, PriceMismatchException;

/// Delegate that owns award, payment, accept, and cancel-award operations
/// for [TaskRequestsViewModel].
///
/// Follows the Phase D delegate pattern (see DashboardWorkDelegate,
/// DashboardInboxDelegate). The parent ViewModel keeps orchestration,
/// pagination, submit/reject, and state fields; this delegate encapsulates
/// the two-step award+payment flow, the accept-offer flow, and the
/// cancel-awarded-offer flow.
class TaskRequestsAwardDelegate {
  static const _kTag = 'TaskRequests.award';

  final String taskId;
  final TaskService _taskService;
  final TaskRequestsService _service;
  final VoidCallback _onChanged;
  final Future<void> Function() _refreshList;

  TaskRequestsAwardDelegate({
    required this.taskId,
    required TaskService taskService,
    required TaskRequestsService service,
    required VoidCallback onChanged,
    required Future<void> Function() refreshList,
  }) : _taskService = taskService,
       _service = service,
       _onChanged = onChanged,
       _refreshList = refreshList;

  // ==========================================================================
  // LOADING STATE FLAGS — Prevent Double-Submit / Double-Click
  // See: THREAT_MODEL.md T2 (Double Acceptance Race)
  // ==========================================================================
  bool _isAwarding = false;
  bool get isAwarding => _isAwarding;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Clears the delegate-owned error message.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      AppLogger.d('Award delegate error cleared', tag: _kTag);
      _onChanged();
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
        'Blocked concurrent award attempt for request $requestId',
        tag: _kTag,
      );
      _errorMessage = 'An award is already in progress. Please wait.';
      _onChanged();
      return null;
    }

    _isAwarding = true;
    _errorMessage = null;
    _onChanged();

    AppLogger.i('Starting award flow for request $requestId', tag: _kTag);

    try {
      final result = await _taskService.awardOffer(
        requestId,
        expectedPriceCents: expectedPriceCents,
      );

      AppLogger.i(
        'Award completed successfully for request $requestId',
        tag: _kTag,
      );

      await _refreshList();
      return result;
    } on PriceMismatchException catch (e) {
      AppLogger.w(
        'Price mismatch during award: expected ${e.expectedCents}, got ${e.actualCents}',
        tag: _kTag,
      );
      rethrow;
    } on OfferAlreadyAcceptedException {
      AppLogger.w(
        'Offer already accepted during award (race condition)',
        tag: _kTag,
      );
      rethrow;
    } on Exception catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to award offer $requestId',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      _onChanged();
      return null;
    } finally {
      _isAwarding = false;
      _onChanged();
      AppLogger.d('Award operation completed, flag cleared', tag: _kTag);
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
        tag: _kTag,
      );
      _errorMessage = 'Please wait for the current operation to complete.';
      _onChanged();
      return null;
    }

    _errorMessage = null;
    _onChanged();

    AppLogger.i('Starting payment flow for request $requestId', tag: _kTag);

    try {
      final result = await _taskService.payAwardedOffer(requestId);

      AppLogger.i(
        'Payment completed successfully for request $requestId',
        tag: _kTag,
      );

      await _refreshList();
      return result;
    } on Exception catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to pay for awarded offer $requestId',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      _onChanged();
      return null;
    }
  }

  /// Accepts an offer with optimistic concurrency control via price validation.
  ///
  /// [expectedPriceCents] should be the price the client saw when clicking
  /// Accept. If the freelancer changed their offer since then, a
  /// [PriceMismatchException] will be thrown. The UI should catch this and
  /// prompt the user to refresh.
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
        tag: _kTag,
      );
      _errorMessage = 'An operation is already in progress. Please wait.';
      _onChanged();
      return false;
    }

    _isAwarding = true; // Re-use awarding flag for accept operation
    _errorMessage = null;
    _onChanged();

    AppLogger.i('Starting accept flow for request ${request.id}', tag: _kTag);

    try {
      // DB stores task_requests.price in IQD; RPC expects
      // p_expected_price_cents = price * 100
      final priceCents = expectedPriceCents ?? (request.price * 100);

      AppLogger.d(
        'Accepting offer ${request.id} with expected price: $priceCents cents',
        tag: _kTag,
      );

      await _service.accept(
        request.id,
        taskId: taskId,
        expectedPriceCents: priceCents,
      );

      AppLogger.i('Offer ${request.id} accepted successfully', tag: _kTag);

      // Success - refresh the list
      await _refreshList();
      return true;
    } on PriceMismatchException catch (e) {
      // Log the price mismatch for security monitoring
      AppLogger.w(
        'Price mismatch detected: expected ${e.expectedCents} cents, got ${e.actualCents} cents',
        tag: _kTag,
      );

      // Refresh to get latest data
      await _refreshList();

      // Re-throw so UI can show error dialog
      rethrow;
    } on OfferAlreadyAcceptedException catch (_) {
      AppLogger.w('Offer already accepted (idempotency hit)', tag: _kTag);

      // Refresh and return success since it's already accepted
      await _refreshList();
      return true;
    } on Exception catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to accept offer ${request.id}',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      _onChanged();
      return false;
    } finally {
      _isAwarding = false;
      _onChanged();
      AppLogger.d('Accept operation completed, flag cleared', tag: _kTag);
    }
  }

  /// Cancel an awarded-but-unpaid offer. Returns task to open status.
  /// Only the task owner can cancel. Shows confirmation dialog in UI.
  Future<bool> cancelAwardedOffer(String requestId) async {
    // Prevent concurrent operations
    if (_isAwarding) {
      AppLogger.w('Blocked cancel attempt during active operation', tag: _kTag);
      _errorMessage = 'Please wait for the current operation to complete.';
      _onChanged();
      return false;
    }

    _isAwarding = true; // Re-use flag to block concurrent ops
    _errorMessage = null;
    _onChanged();

    AppLogger.i(
      'Starting cancel flow for awarded offer $requestId',
      tag: _kTag,
    );

    try {
      final result = await _taskService.cancelAwardedOffer(requestId);

      if (result['success'] == true) {
        AppLogger.i(
          'Successfully cancelled awarded offer $requestId',
          tag: _kTag,
        );
        await _refreshList();
        return true;
      } else {
        _errorMessage =
            result['message']?.toString() ?? 'Failed to cancel offer';
        AppLogger.w('Cancel failed for $requestId: $_errorMessage', tag: _kTag);
        _onChanged();
        return false;
      }
    } on Exception catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to cancel awarded offer $requestId',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      _onChanged();
      return false;
    } finally {
      _isAwarding = false;
      _onChanged();
      AppLogger.d('Cancel operation completed, flag cleared', tag: _kTag);
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
  Future<void> acceptLegacy(String requestId) async {
    if (_isAwarding) {
      AppLogger.w('Blocked concurrent legacy accept attempt', tag: _kTag);
      _errorMessage = 'An operation is already in progress.';
      _onChanged();
      return;
    }

    _isAwarding = true;
    _errorMessage = null;
    _onChanged();

    try {
      await _taskService.escrowHoldOffer(requestId);
      await _refreshList();
    } on Exception catch (e, st) {
      _errorMessage = _friendlyError(e);
      AppLogger.e(
        'Failed to accept offer $requestId',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      _onChanged();
    } finally {
      _isAwarding = false;
      _onChanged();
    }
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

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
