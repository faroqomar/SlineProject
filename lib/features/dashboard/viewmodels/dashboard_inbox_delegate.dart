import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/services/booking_service.dart';
import 'package:sline_app/features/dashboard/data/dashboard_repository.dart';
import 'package:sline_app/features/dashboard/models/inbox_task_group.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';

/// Generates a short trace ID for correlating multi-step operations.
String _traceId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  return now.toRadixString(36).padLeft(8, '0').substring(0, 8);
}

/// Delegate that owns inbox state (offers, pending items)
/// and inbox-related actions for [DashboardViewModel].
class DashboardInboxDelegate {
  static const _kTag = 'dashboard.inbox';

  final DashboardRepository _repository;
  final TaskService _taskService;
  final BookingService _bookingService;
  final VoidCallback _onChanged;
  final bool Function() _isDisposed;

  DashboardInboxDelegate({
    required DashboardRepository repository,
    required TaskService taskService,
    required BookingService bookingService,
    required VoidCallback onChanged,
    required bool Function() isDisposed,
  }) : _repository = repository,
       _taskService = taskService,
       _bookingService = bookingService,
       _onChanged = onChanged,
       _isDisposed = isDisposed;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<TaskRequest> _inboxOffers = [];
  List<TaskRequest> get inboxOffers => _inboxOffers;

  List<BookingModel> _pendingRequests = [];
  List<BookingModel> get pendingRequests => _pendingRequests;

  List<Task> _pendingPaymentTenders = [];
  List<Task> get pendingPaymentTenders => _pendingPaymentTenders;

  List<Task> myTasks = [];

  bool _inboxLoaded = false;
  bool get inboxLoaded => _inboxLoaded;

  /// Groups inbox offers by task (stable ordering)
  List<InboxTaskGroup> get inboxGroupedByTask {
    final map = <String, List<TaskRequest>>{};
    for (final offer in _inboxOffers) {
      map.putIfAbsent(offer.taskId, () => []).add(offer);
    }

    final groups = <InboxTaskGroup>[];
    for (final entry in map.entries) {
      final offers = entry.value;
      offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      groups.add(
        InboxTaskGroup(
          taskId: entry.key,
          taskTitle: offers.first.taskTitle ?? 'Task ${entry.key}',
          offers: offers,
        ),
      );
    }
    groups.sort((a, b) => b.latestOfferTime.compareTo(a.latestOfferTime));
    return groups;
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  void clear() {
    _inboxOffers = [];
    _pendingRequests = [];
    _pendingPaymentTenders = [];
    myTasks = [];
    _inboxLoaded = false;
  }

  /// Sets all inbox data from an external source (parent VM's _loadData).
  void setInboxData({
    required List<TaskRequest> offers,
    required List<BookingModel> pendingRequests,
    required List<Task> pendingPaymentTenders,
    required List<Task> myTasks,
  }) {
    _inboxOffers = offers;
    _pendingRequests = pendingRequests;
    _pendingPaymentTenders = pendingPaymentTenders;
    this.myTasks = myTasks;
    _inboxLoaded = true;
  }

  /// Lazy-loads inbox data when inbox tab is first shown.
  Future<void> loadInboxData(UserRole currentRole) async {
    if (_inboxLoaded) return;
    try {
      _inboxOffers = await _fetchInboxInternal(currentRole);
      if (_isDisposed()) return;
      final pending = await _fetchPendingItemsInternal(currentRole);
      _pendingRequests = pending['requests'] as List<BookingModel>;
      _pendingPaymentTenders = pending['tenders'] as List<Task>;
      _inboxLoaded = true;
      AppLogger.d('Inbox tab data loaded', tag: _kTag);
      if (!_isDisposed()) _onChanged();
    } on Exception catch (e) {
      AppLogger.e('Failed to load inbox', error: e, tag: _kTag);
      if (!_isDisposed()) _onChanged();
    }
  }

  /// Returns inbox offers for Future.wait usage (does not assign).
  Future<List<TaskRequest>> fetchInboxInternal(UserRole currentRole) =>
      _fetchInboxInternal(currentRole);

  /// Returns pending items for Future.wait usage (does not assign).
  Future<Map<String, dynamic>> fetchPendingItemsInternal(
    UserRole currentRole,
  ) => _fetchPendingItemsInternal(currentRole);

  /// Returns management data for Future.wait usage (does not assign).
  Future<Map<String, dynamic>> loadManagementDataInternal(
    UserRole currentRole,
  ) async {
    final uid = _repository.currentUser?.id;
    if (uid == null) return {'tasks': <Task>[]};
    try {
      if (currentRole == UserRole.client) {
        final tasks = await _taskService.getTasksByUser(uid);
        return {'tasks': tasks};
      }
      return {'tasks': <Task>[]};
    } on Exception catch (e) {
      AppLogger.e('Failed to load management data', error: e, tag: _kTag);
      return {'tasks': <Task>[]};
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> awardOffer(TaskRequest offer) async {
    final tid = _traceId();
    try {
      final expectedPriceCents = offer.price * 100;
      final result = await _taskService.awardOffer(
        offer.id,
        expectedPriceCents: expectedPriceCents,
      );
      if (_isDisposed()) return null;
      AppLogger.i(
        'Awarded offer=${offer.id} task=${offer.taskId} [trace:$tid]',
        tag: _kTag,
      );
      return result;
    } on Exception catch (e) {
      AppLogger.e(
        'Failed to award offer=${offer.id} task=${offer.taskId} [trace:$tid]',
        error: e,
        tag: _kTag,
      );
      rethrow;
    }
  }

  Future<void> payAwardedOffer(TaskRequest offer) async {
    final tid = _traceId();
    try {
      await _taskService.payAwardedOffer(offer.id);
      if (_isDisposed()) return;
      _inboxOffers.removeWhere((o) => o.taskId == offer.taskId);
      if (!_isDisposed()) _onChanged();
      AppLogger.i(
        'Paid for awarded offer=${offer.id} task=${offer.taskId} [trace:$tid]',
        tag: _kTag,
      );
    } on Exception catch (e) {
      AppLogger.e(
        'Failed to pay for awarded offer=${offer.id} task=${offer.taskId} [trace:$tid]',
        error: e,
        tag: _kTag,
      );
      rethrow;
    }
  }

  @Deprecated(
    'Use awardOffer() and payAwardedOffer() for the two-step tender flow.',
  )
  Future<void> acceptOffer(TaskRequest offer) async {
    final tid = _traceId();
    try {
      await _taskService.escrowHoldOffer(offer.id);
      if (_isDisposed()) return;
      _inboxOffers.removeWhere((o) => o.taskId == offer.taskId);
      if (!_isDisposed()) _onChanged();
      AppLogger.i(
        'Accepted offer=${offer.id} task=${offer.taskId} [trace:$tid]',
        tag: _kTag,
      );
    } on Exception catch (e) {
      AppLogger.e(
        'Failed to accept offer=${offer.id} task=${offer.taskId} [trace:$tid]',
        error: e,
        tag: _kTag,
      );
      rethrow;
    }
  }

  Future<void> rejectOffer(TaskRequest offer) async {
    final tid = _traceId();
    try {
      await _taskService.rejectOffer(offer.id);
      if (_isDisposed()) return;
      _inboxOffers.removeWhere((o) => o.id == offer.id);
      if (!_isDisposed()) _onChanged();
      AppLogger.i('Rejected offer=${offer.id} [trace:$tid]', tag: _kTag);
    } on Exception catch (e) {
      if (e.toString().contains('Need reject_task_request RPC')) {
        AppLogger.w('Reject needs RPC implementation [trace:$tid]', tag: _kTag);
      }
      AppLogger.e(
        'Failed to reject offer=${offer.id} [trace:$tid]',
        error: e,
        tag: _kTag,
      );
      rethrow;
    }
  }

  void removeOffer(String offerId) {
    _inboxOffers.removeWhere((o) => o.id == offerId);
  }

  // ---------------------------------------------------------------------------
  // Internal fetchers (for Future.wait)
  // ---------------------------------------------------------------------------

  Future<List<TaskRequest>> _fetchInboxInternal(UserRole currentRole) async {
    final uid = _repository.currentUser?.id;
    if (uid == null) return [];
    try {
      if (currentRole == UserRole.client) {
        return await _taskService.getOffersReceived(uid);
      } else {
        return await _taskService.getOffersSubmitted(uid);
      }
    } on Exception catch (e) {
      AppLogger.e('Failed to fetch inbox offers', error: e, tag: _kTag);
      return [];
    }
  }

  Future<Map<String, dynamic>> _fetchPendingItemsInternal(
    UserRole currentRole,
  ) async {
    final uid = _repository.currentUser?.id;
    if (uid == null) {
      return {'requests': <BookingModel>[], 'tenders': <Task>[]};
    }
    try {
      final requests = await _bookingService.getPendingRequests();
      var tenders = <Task>[];
      if (currentRole == UserRole.freelancer) {
        tenders = await _taskService.getPendingPaymentTenders();
      }
      return {'requests': requests, 'tenders': tenders};
    } on Exception catch (e) {
      AppLogger.e('Failed to fetch pending items', error: e, tag: _kTag);
      return {'requests': <BookingModel>[], 'tenders': <Task>[]};
    }
  }
}
