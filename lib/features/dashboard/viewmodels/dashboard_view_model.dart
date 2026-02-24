import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../data/dashboard_repository.dart';
import '../models/work_item.dart';
import '../models/activity_log.dart';
import '../models/dashboard_counters.dart';
import '../models/inbox_task_group.dart';
import 'package:sline_app/core/services/dashboard_cache_service.dart';
import '../../services/models/service_model.dart';
import '../../services/services/services_service.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/services/task_service.dart';
import '../../booking/models/booking_model.dart';
import '../../booking/services/booking_service.dart';
import '../../tasks/models/task_request_model.dart';

/// Generates a short trace ID for correlating multi-step operations.
String _traceId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  return now.toRadixString(36).padLeft(8, '0').substring(0, 8);
}

class DashboardViewModel extends ChangeNotifier {
  static const _kTag = 'dashboard';
  final DashboardRepository _repository;
  final DashboardCacheService? _cacheService;

  // Dispose guard
  bool _isDisposed = false;
  DateTime? _lastRoleChangeAt;

  DashboardViewModel({
    DashboardRepository? repository,
    DashboardCacheService? cacheService,
    TaskService? taskService,
    ServicesService? servicesService,
    BookingService? bookingService,
  }) : _repository = repository ?? DashboardRepository(),
       _cacheService = cacheService,
       _taskService = taskService ?? TaskService(),
       _servicesService = servicesService ?? ServicesService(),
       _bookingService =
           bookingService ??
           BookingService((repository ?? DashboardRepository()).client) {
    _currentTab = DashboardTab.overview;
    _currentRole = UserRole.freelancer;

    _loadCachedRole();
    _syncRoleFromBackend();
    _loadData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Safe notify - silent if disposed
  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Returns true if disposed (caller should abort)
  bool _abortIfDisposed() => _isDisposed;

  /// Invalidates all cached computed lists derived from _workItems.
  void _invalidateWorkCaches() {
    _nextActionsCache = null;
    _activeWorkCache = null;
    _deliveredWorkCache = null;
    _completedWorkCache = null;
    _cancelledWorkCache = null;
  }

  UserRole _currentRole = UserRole.freelancer;
  UserRole get currentRole => _currentRole;

  DashboardTab _currentTab = DashboardTab.overview;
  DashboardTab get currentTab => _currentTab;

  // Nested sub-tab index for WorkTab (consumed once after navigation)
  int? _workSubTabIndex;
  int? get workSubTabIndex => _workSubTabIndex;

  /// Consumes the pending work sub-tab index (returns it and clears).
  int? consumeWorkSubTabIndex() {
    final idx = _workSubTabIndex;
    _workSubTabIndex = null;
    return idx;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<WorkItem> _workItems = [];
  List<WorkItem> get workItems => _workItems;

  List<ActivityLog> _activityFeed = [];
  List<ActivityLog> get activityFeed => _activityFeed;

  DashboardCounters _counters = const DashboardCounters();
  DashboardCounters get counters => _counters;

  // Phase 4: Management Data
  List<ServiceModel> _myServices = [];
  List<ServiceModel> get myServices => _myServices;

  List<Task> _myTasks = [];
  List<Task> get myTasks => _myTasks;

  // Phase 5: Bookings Data
  List<BookingModel> _bookings = [];
  List<BookingModel> get bookings => _bookings;

  BookingStatus? _bookingFilter;
  BookingStatus? get bookingFilter => _bookingFilter;

  // Phase 6: Inbox Data
  List<TaskRequest> _inboxOffers = [];
  List<TaskRequest> get inboxOffers => _inboxOffers;

  /// Groups inbox offers by task (stable ordering)
  List<InboxTaskGroup> get inboxGroupedByTask {
    // Group offers by taskId
    final map = <String, List<TaskRequest>>{};
    for (var offer in _inboxOffers) {
      map.putIfAbsent(offer.taskId, () => []).add(offer);
    }

    // Build list of groups
    final groups = <InboxTaskGroup>[];
    for (var entry in map.entries) {
      final offers = entry.value;

      // Sort offers within group: newest first
      offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      groups.add(
        InboxTaskGroup(
          taskId: entry.key,
          taskTitle: offers.first.taskTitle ?? 'Task ${entry.key}',
          offers: offers,
        ),
      );
    }

    // Sort groups by latest offer time (newest task group first)
    groups.sort((a, b) => b.latestOfferTime.compareTo(a.latestOfferTime));

    return groups;
  }

  // Services (injected or defaulted)
  final ServicesService _servicesService;
  final TaskService _taskService;
  late final BookingService _bookingService;

  // Cached computed lists (invalidated when _workItems changes)
  List<WorkItem>? _nextActionsCache;
  List<WorkItem>? _activeWorkCache;
  List<WorkItem>? _deliveredWorkCache;
  List<WorkItem>? _completedWorkCache;
  List<WorkItem>? _cancelledWorkCache;

  List<WorkItem> get nextActions {
    _nextActionsCache ??= _calculateNextActions();
    return _nextActionsCache!;
  }

  // User display name
  String? _userName;
  String get userName => _userName ?? 'there';

  // Phase 7: Pending Actions (New for restructuring)
  List<BookingModel> _pendingRequests = [];
  List<BookingModel> get pendingRequests => _pendingRequests;

  List<Task> _pendingPaymentTenders = [];
  List<Task> get pendingPaymentTenders => _pendingPaymentTenders;

  // --- Filtered Work Buckets (cached, invalidated on _workItems change) ---

  /// Active Work: items in Active or Pending bucket
  List<WorkItem> get activeWork {
    _activeWorkCache ??=
        _workItems.where((i) {
          return i.statusUiBucket == 'Active' || i.statusUiBucket == 'Pending';
        }).toList()..sort((a, b) {
          final rankCmp = a.sortRank.compareTo(b.sortRank);
          if (rankCmp != 0) return rankCmp;
          final aTime = a.lastActivityAt ?? a.lastUpdate;
          final bTime = b.lastActivityAt ?? b.lastUpdate;
          return bTime.compareTo(aTime);
        });
    return _activeWorkCache!;
  }

  /// Delivered work needing review (subset of active)
  List<WorkItem> get deliveredWork {
    _deliveredWorkCache ??= _workItems.where((i) {
      final isBucketValid =
          i.statusUiBucket == 'Active' || i.statusUiBucket == 'Pending';
      return i.needsReview && isBucketValid;
    }).toList();
    return _deliveredWorkCache!;
  }

  /// Completed Work
  List<WorkItem> get completedWork {
    _completedWorkCache ??=
        _workItems.where((i) {
          return i.statusUiBucket == 'Done';
        }).toList()..sort((a, b) {
          final timeA = a.completedAt ?? a.lastUpdate;
          final timeB = b.completedAt ?? b.lastUpdate;
          return timeB.compareTo(timeA);
        });
    return _completedWorkCache!;
  }

  /// Cancelled Work
  List<WorkItem> get cancelledWork {
    _cancelledWorkCache ??= _workItems.where((i) {
      return i.statusUiBucket == 'Cancelled';
    }).toList()..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    return _cancelledWorkCache!;
  }

  // Active Work Buckets (Keep for backward compatibility if needed, else deprecate)
  List<WorkItem> get activeUpNext => _calculateActiveUpNext();
  List<WorkItem> get activeInProgress => _calculateActiveInProgress();
  List<WorkItem> get activeInReview => _calculateActiveInReview();

  List<WorkItem> get activeItems => _workItems;

  /// Switches the active role with persistence
  Future<void> setRole(UserRole role) async {
    if (_currentRole == role) return;

    // Save previous role for revert
    final previousRole = _currentRole;

    // 1. Optimistic UI update
    _currentRole = role;
    _safeNotify();

    // 2. Write cache FIRST (offline-first)
    await _cacheService?.cacheUserRole(role);
    if (_abortIfDisposed()) return;

    try {
      // 3. Persist to backend
      await _repository.updateUserRole(role);
      if (_abortIfDisposed()) return;

      // 4. Mark timestamp to prevent backend override
      _lastRoleChangeAt = DateTime.now();

      // 5. Reload data
      await _loadData(forceRefresh: true);
      if (_abortIfDisposed()) return;

      AppLogger.i('Role switched to: ${role.name}', tag: _kTag);
    } catch (e) {
      AppLogger.e('Failed to persist role', error: e, tag: _kTag);

      // Revert to PREVIOUS role (not flip)
      if (!_isDisposed) {
        _currentRole = previousRole;
        await _cacheService?.cacheUserRole(previousRole);
        _safeNotify();
      }

      rethrow; // Let UI show error
    }
  }

  /// Loads cached role instantly
  Future<void> _loadCachedRole() async {
    final cached = await _cacheService?.getCachedUserRole();
    if (cached != null && cached != _currentRole) {
      _currentRole = cached;
      _safeNotify();
      AppLogger.i('Loaded cached role: ${cached.name}', tag: _kTag);
    }
  }

  /// Syncs role from backend (with protection)
  Future<void> _syncRoleFromBackend() async {
    try {
      // Prevent backend from overriding recent manual change
      if (_lastRoleChangeAt != null) {
        final elapsed = DateTime.now().difference(_lastRoleChangeAt!);
        if (elapsed.inSeconds < 15) {
          AppLogger.d('Skipping role sync - recent manual change', tag: _kTag);
          return;
        }
      }

      final dbRole = await _repository.fetchUserRole();
      if (_abortIfDisposed()) return;

      if (dbRole != _currentRole) {
        _currentRole = dbRole;
        await _cacheService?.cacheUserRole(dbRole);
        if (_abortIfDisposed()) return;

        _safeNotify();
        AppLogger.i('Synced role from DB: ${dbRole.name}', tag: _kTag);
      }
    } catch (e) {
      AppLogger.e('Failed to sync role from DB', error: e, tag: _kTag);
      // Keep cached role
    }
  }

  void setTab(int index, {int? workSubTab}) {
    if (index < 0 || index >= DashboardTab.values.length) {
      AppLogger.w('Invalid tab index: $index', tag: _kTag);
      return;
    }
    final tab = DashboardTab.values[index];

    // Store sub-tab intent for WorkTab to consume
    if (tab == DashboardTab.activeWork && workSubTab != null) {
      _workSubTabIndex = workSubTab;
    }

    if (_currentTab == tab && workSubTab == null) return;
    AppLogger.i(
      'Switching dashboard tab to: ${tab.name}'
      '${workSubTab != null ? ' (subTab=$workSubTab)' : ''}',
      tag: _kTag,
    );
    _currentTab = tab;
    _safeNotify();
  }

  /// Refreshes all dashboard data from the API
  Future<void> refresh() => _loadData(forceRefresh: true);

  /// Load dashboard data with stale-while-revalidate caching
  Future<void> _loadData({bool forceRefresh = false}) async {
    AppLogger.d(
      'Loading dashboard data (forceRefresh=$forceRefresh)...',
      tag: _kTag,
    );
    final sw = Stopwatch()..start();

    // Phase 1: Try cache first for instant loading (stale)
    if (_cacheService != null && !forceRefresh) {
      final cachedWorkItems = await _cacheService.getCachedWorkItems(
        _currentRole,
      );
      final cachedActivity = await _cacheService.getCachedActivityFeed();
      final cachedCounters = await _cacheService.getCachedCounters();

      if (cachedWorkItems != null || cachedActivity != null) {
        AppLogger.i('⚡ Dashboard loaded from cache (instant)', tag: _kTag);
        _workItems = cachedWorkItems ?? [];
        _activityFeed = cachedActivity ?? [];
        _invalidateWorkCaches();

        if (cachedCounters != null) {
          _counters = DashboardCounters.fromMap(cachedCounters);
        }

        _isLoading = false;
        _safeNotify();
      }
    }

    // Phase 2: Fetch fresh data in background (revalidate)
    _isLoading = true;
    _safeNotify();

    try {
      // 0. Resolve role (must be first — determines query filters)
      final fetchedRole = await _repository.fetchUserRole();
      if (_currentRole != fetchedRole) {
        _currentRole = fetchedRole;
      }
      if (_abortIfDisposed()) return;

      // 1. Fetch user name for greeting
      _userName =
          _repository.currentUser?.userMetadata?['full_name'] as String?;

      // 2. Parallel fetch — all independent of each other
      final results = await Future.wait([
        _repository.fetchWorkItems(_currentRole),
        _repository.fetchActivityFeed(),
        _fetchBookingsInternal(),
        _fetchInboxInternal(),
        _fetchPendingItemsInternal(),
        _loadManagementDataInternal(),
      ]);
      if (_abortIfDisposed()) return;

      // Assign results
      _workItems = results[0] as List<WorkItem>;
      _activityFeed = results[1] as List<ActivityLog>;
      _bookings = results[2] as List<BookingModel>;
      _inboxOffers = results[3] as List<TaskRequest>;
      // results[4] and results[5] are Maps, handled below
      final pendingResult = results[4] as Map<String, dynamic>;
      _pendingRequests = pendingResult['requests'] as List<BookingModel>;
      _pendingPaymentTenders = pendingResult['tenders'] as List<Task>;

      final mgmtResult = results[5] as Map<String, dynamic>;
      _myServices = mgmtResult['services'] as List<ServiceModel>;
      _myTasks = mgmtResult['tasks'] as List<Task>;

      // Invalidate cached computations
      _invalidateWorkCaches();

      // 3. Counters (depends on workItems + inboxOffers — sequential)
      _counters = await _repository.fetchCounters(
        _currentRole,
        _workItems,
        _inboxOffers,
      );

      // Cache fresh data
      if (_cacheService != null && !_abortIfDisposed()) {
        await _cacheService.cacheWorkItems(_workItems, _currentRole);
        await _cacheService.cacheActivityFeed(_activityFeed);
        await _cacheService.cacheCounters(_counters.toMap());
        AppLogger.i('💾 Dashboard data cached', tag: _kTag);
      }

      sw.stop();
      AppLogger.i(
        '✅ Dashboard refreshed from API in ${sw.elapsedMilliseconds}ms '
        '(${_workItems.length} items, ${_inboxOffers.length} offers, '
        '${_bookings.length} bookings)',
        tag: _kTag,
      );
    } catch (e) {
      sw.stop();
      AppLogger.e(
        'Dashboard load error after ${sw.elapsedMilliseconds}ms',
        error: e,
        tag: _kTag,
      );
    }

    _isLoading = false;
    _safeNotify();
  }

  /// Returns management data without assigning to fields (for Future.wait)
  Future<Map<String, dynamic>> _loadManagementDataInternal() async {
    final uid = _repository.currentUser?.id;
    if (uid == null) {
      return {'services': <ServiceModel>[], 'tasks': <Task>[]};
    }
    try {
      if (_currentRole == UserRole.freelancer) {
        final services = await _servicesService.getMyServices(uid);
        return {'services': services, 'tasks': <Task>[]};
      } else {
        final tasks = await _taskService.getTasksByUser(uid);
        return {'services': <ServiceModel>[], 'tasks': tasks};
      }
    } catch (e) {
      AppLogger.e('Failed to load management data', error: e, tag: _kTag);
      return {'services': <ServiceModel>[], 'tasks': <Task>[]};
    }
  }

  /// Returns bookings without assigning to fields (for Future.wait)
  Future<List<BookingModel>> _fetchBookingsInternal() async {
    try {
      if (_currentRole == UserRole.freelancer) {
        return await _bookingService.listBookingsAsProvider(limit: 50);
      } else {
        return await _bookingService.listBookingsAsClient(limit: 50);
      }
    } catch (e) {
      AppLogger.e('Failed to fetch bookings', error: e, tag: _kTag);
      return [];
    }
  }

  /// Returns inbox offers without assigning to fields (for Future.wait)
  Future<List<TaskRequest>> _fetchInboxInternal() async {
    final uid = _repository.currentUser?.id;
    if (uid == null) return [];
    try {
      if (_currentRole == UserRole.client) {
        return await _taskService.getOffersReceived(uid);
      } else {
        return await _taskService.getOffersSubmitted(uid);
      }
    } catch (e) {
      AppLogger.e('Failed to fetch inbox offers', error: e, tag: _kTag);
      return [];
    }
  }

  /// Returns pending items without assigning to fields (for Future.wait)
  Future<Map<String, dynamic>> _fetchPendingItemsInternal() async {
    final uid = _repository.currentUser?.id;
    if (uid == null) {
      return {'requests': <BookingModel>[], 'tenders': <Task>[]};
    }
    try {
      final requests = await _bookingService.getPendingRequests();
      List<Task> tenders = [];
      if (_currentRole == UserRole.freelancer) {
        tenders = await _taskService.getPendingPaymentTenders();
      }
      return {'requests': requests, 'tenders': tenders};
    } catch (e) {
      AppLogger.e('Failed to fetch pending items', error: e, tag: _kTag);
      return {'requests': <BookingModel>[], 'tenders': <Task>[]};
    }
  }

  // --- Inbox Actions ---

  Future<void> withdrawOffer(String offerId) async {
    final tid = _traceId();
    try {
      await _taskService.withdrawOffer(offerId);
      _inboxOffers.removeWhere((o) => o.id == offerId);
      AppLogger.i(
        'Offer withdrawn: $offerId [trace:$tid]',
        tag: '$_kTag.inbox',
      );
      _safeNotify();
    } catch (e) {
      AppLogger.e(
        'Failed to withdraw offer=$offerId [trace:$tid]',
        error: e,
        tag: '$_kTag.inbox',
      );
      rethrow;
    }
  }

  /// Accepts an offer atomically (And holds funds in escrow first)
  Future<void> acceptOffer(TaskRequest offer) async {
    final tid = _traceId();
    try {
      // 1. Hold funds in escrow, which then auto-accepts the offer
      await _taskService.escrowHoldOffer(offer.id);
      if (_abortIfDisposed()) return;

      // 2. Remove ALL offers for this task (not just this one!)
      _inboxOffers.removeWhere((o) => o.taskId == offer.taskId);
      _safeNotify();

      // 3. Reload work items only (not full inbox refresh)
      await _fetchWorkItems();
      if (_abortIfDisposed()) return;

      final mgmt = await _loadManagementDataInternal();
      _myServices = mgmt['services'] as List<ServiceModel>;
      _myTasks = mgmt['tasks'] as List<Task>;
      if (_abortIfDisposed()) return;

      _safeNotify();
      AppLogger.i(
        'Accepted offer=${offer.id} task=${offer.taskId} [trace:$tid]',
        tag: '$_kTag.inbox',
      );
    } catch (e) {
      AppLogger.e(
        'Failed to accept offer=${offer.id} task=${offer.taskId} [trace:$tid]',
        error: e,
        tag: '$_kTag.inbox',
      );
      rethrow;
    }
  }

  /// Helper to refresh just work items
  Future<void> _fetchWorkItems() async {
    try {
      _workItems = await _repository.fetchWorkItems(_currentRole);
      if (_abortIfDisposed()) return;

      _invalidateWorkCaches();

      // Update counters (pass existing inbox offers to avoid re-query)
      _counters = await _repository.fetchCounters(
        _currentRole,
        _workItems,
        _inboxOffers,
      );
      if (_cacheService != null && !_abortIfDisposed()) {
        await _cacheService.cacheWorkItems(_workItems, _currentRole);
        await _cacheService.cacheCounters(_counters.toMap());
      }
    } catch (e) {
      AppLogger.e('Failed to fetch work items', error: e, tag: _kTag);
    }
  }

  /// Release offer funds
  Future<void> releaseOfferWithFee(String offerId) async {
    final tid = _traceId();
    try {
      await _taskService.releaseOfferWithFee(offerId);
      await _fetchWorkItems();
      _safeNotify();
      AppLogger.i(
        'Released funds for offer=$offerId [trace:$tid]',
        tag: '$_kTag.ledger',
      );
    } catch (e) {
      AppLogger.e(
        'Failed to release funds for offer=$offerId [trace:$tid]',
        error: e,
        tag: '$_kTag.ledger',
      );
      rethrow;
    }
  }

  /// Refund offer
  Future<void> refundOffer(String offerId) async {
    final tid = _traceId();
    try {
      await _taskService.refundOffer(offerId);
      _inboxOffers.removeWhere((o) => o.id == offerId);
      await _fetchWorkItems();
      _safeNotify();
      AppLogger.i('Refunded offer=$offerId [trace:$tid]', tag: '$_kTag.ledger');
    } catch (e) {
      AppLogger.e(
        'Failed to refund offer=$offerId [trace:$tid]',
        error: e,
        tag: '$_kTag.ledger',
      );
      rethrow;
    }
  }

  /// Rejects an offer
  Future<void> rejectOffer(TaskRequest offer) async {
    final tid = _traceId();
    try {
      await _taskService.rejectOffer(offer.id);
      if (_abortIfDisposed()) return;

      _inboxOffers.removeWhere((o) => o.id == offer.id);
      _safeNotify();

      AppLogger.i(
        'Rejected offer=${offer.id} [trace:$tid]',
        tag: '$_kTag.inbox',
      );
    } catch (e) {
      if (e.toString().contains('Need reject_task_request RPC')) {
        AppLogger.w(
          'Reject needs RPC implementation [trace:$tid]',
          tag: '$_kTag.inbox',
        );
      }
      AppLogger.e(
        'Failed to reject offer=${offer.id} [trace:$tid]',
        error: e,
        tag: '$_kTag.inbox',
      );
      rethrow;
    }
  }

  void setBookingFilter(BookingStatus? status) {
    if (_bookingFilter == status) return;
    _bookingFilter = status;
    _safeNotify();
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      final updated = await _bookingService.updateBookingStatus(
        bookingId: bookingId,
        newStatus: status,
      );

      // Update local state
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = updated;
        AppLogger.i('Updated booking=$bookingId to ${status.name}', tag: _kTag);
        _safeNotify();
      }
    } catch (e) {
      AppLogger.e('Failed to update booking=$bookingId', error: e, tag: _kTag);
      rethrow; // Let UI handle error toast
    }
  }

  Future<void> performPrimaryAction(WorkItem item) async {
    // v1: Handle navigation-only actions first
    switch (item.primaryActionType) {
      case PrimaryActionType.approveClose:
        AppLogger.i('Action: approveClose item=${item.id}', tag: _kTag);
        return;
      case PrimaryActionType.reviewDelivery:
        AppLogger.i('Action: reviewDelivery item=${item.id}', tag: _kTag);
        // Note: Navigation routed via DeepLinkService in View
        return;
      case PrimaryActionType.payEscrow:
        AppLogger.i('Action: payEscrow item=${item.id}', tag: _kTag);
        // Note: Navigation routed via DeepLinkService in View
        return;
      case PrimaryActionType.submitEvidence:
        AppLogger.i('Action: submitEvidence item=${item.id}', tag: _kTag);
        // Note: Navigation routed via DeepLinkService in View
        return;
      case PrimaryActionType.viewDetails:
        AppLogger.i('Action: viewDetails item=${item.id}', tag: _kTag);
        return;
      case PrimaryActionType.startWork:
      case PrimaryActionType.markCompleted:
        break; // Handle below
    }

    try {
      if (item.type == WorkItemType.booking) {
        BookingStatus? newStatus;
        if (item.primaryActionType == PrimaryActionType.startWork) {
          newStatus = BookingStatus.inProgress;
        } else if (item.primaryActionType == PrimaryActionType.markCompleted) {
          newStatus = BookingStatus.completed;
        }

        if (newStatus != null) {
          await _bookingService.updateBookingStatus(
            bookingId: item.id,
            newStatus: newStatus,
          );
        }
      } else {
        TaskStatus? newStatus;
        if (item.primaryActionType == PrimaryActionType.startWork) {
          newStatus = TaskStatus.inProgress;
        } else if (item.primaryActionType == PrimaryActionType.markCompleted) {
          newStatus = TaskStatus.completed;
        }

        if (newStatus != null) {
          await _taskService.updateTaskStatus(item.id, newStatus);
        }
      }

      AppLogger.i(
        'Action: ${item.primaryActionType.name} completed item=${item.id}',
        tag: _kTag,
      );

      // Refresh to reflect changes
      await _loadData();
    } catch (e) {
      AppLogger.e(
        'Failed primary action=${item.primaryActionType.name} item=${item.id}',
        error: e,
        tag: _kTag,
      );
    }
  }

  List<WorkItem> _calculateNextActions() {
    // v1 Priority Tiers with Set-based exclusion (O(1) lookups)
    // Tier 1: Delivered (needs review) — highest urgency
    final tier1 = _workItems.where((i) => i.needsReview).toList()
      ..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    final seen = tier1.map((i) => i.id).toSet();

    // Tier 2: Pending Payment (awarded/escrow)
    final tier2 = _workItems.where((i) {
      if (seen.contains(i.id)) return false;
      final s = i.statusRaw.toLowerCase();
      return s == 'paid_request_pending' || s == 'awarded';
    }).toList()..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    seen.addAll(tier2.map((i) => i.id));

    // Tier 3: Disputed items
    final tier3 = _workItems.where((i) {
      if (seen.contains(i.id)) return false;
      return i.statusUiBucket == 'Active' &&
          i.statusRaw.toLowerCase() == 'disputed';
    }).toList()..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    seen.addAll(tier3.map((i) => i.id));

    // Tier 4: Urgent active (deadline within 48h)
    final tier4 = _workItems.where((i) {
      if (seen.contains(i.id)) return false;
      if (i.statusUiBucket != 'Active') return false;
      if (i.scheduledAt == null) return false;
      final hoursUntil = i.scheduledAt!.difference(DateTime.now()).inHours;
      return hoursUntil < 48;
    }).toList()..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

    // Combine: max 3 per tier, total max 3
    final combined = [
      ...tier1.take(3),
      ...tier2.take(3),
      ...tier3.take(3),
      ...tier4.take(3),
    ];
    return combined.take(3).toList();
  }

  // --- Active Work Buckets ---

  List<WorkItem> _calculateActiveUpNext() {
    // Status: open, assigned, pending, confirmed
    // Sort: scheduledAt ASC (Urgency)
    return _workItems.where((i) {
      final s = i.statusRaw.toLowerCase();
      return s == 'open' ||
          s == 'assigned' ||
          s == 'pending' ||
          s == 'confirmed';
    }).toList()..sort((a, b) {
      // Urgency sort
      if (a.scheduledAt != null && b.scheduledAt != null) {
        return a.scheduledAt!.compareTo(b.scheduledAt!);
      }
      // If no schedule, fallback to creation
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  List<WorkItem> _calculateActiveInProgress() {
    // Status: inProgress
    // Sort: lastUpdate DESC (Recent activity)
    return _workItems.where((i) {
      return i.statusRaw.toLowerCase() == 'inprogress';
    }).toList()..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
  }

  List<WorkItem> _calculateActiveInReview() {
    // Status: completed
    // Sort: completedAt DESC or lastUpdate DESC
    return _workItems.where((i) {
      return i.statusRaw.toLowerCase() == 'completed';
    }).toList()..sort((a, b) {
      final timeA = a.completedAt ?? a.lastUpdate;
      final timeB = b.completedAt ?? b.lastUpdate;
      return timeB.compareTo(timeA);
    });
  }
}
