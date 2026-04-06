import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/mixins/role_switch_aware.dart';
import 'package:sline_app/core/services/dashboard_cache_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/role_switch_coordinator.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/services/booking_service.dart';
import 'package:sline_app/features/dashboard/data/dashboard_repository.dart';
import 'package:sline_app/features/dashboard/models/activity_log.dart';
import 'package:sline_app/features/dashboard/models/dashboard_counters.dart';
import 'package:sline_app/features/dashboard/models/inbox_task_group.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_booking_delegate.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_inbox_delegate.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_work_delegate.dart';
import 'package:sline_app/features/direct_offers/services/direct_offers_service.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardViewModel extends ChangeNotifier with RoleSwitchAware {
  static const _kTag = 'dashboard';
  final DashboardRepository _repository;
  final DashboardCacheService? _cacheService;
  final TaskService _taskService;

  // Dispose guard
  bool _isDisposed = false;
  DateTime? _lastRoleChangeAt;

  // Delegates
  late final DashboardWorkDelegate _workDelegate;
  late final DashboardInboxDelegate _inboxDelegate;
  late final DashboardBookingDelegate _bookingDelegate;

  DashboardViewModel({
    DashboardRepository? repository,
    DashboardCacheService? cacheService,
    TaskService? taskService,
    BookingService? bookingService,
    DirectOffersService? directOffersService,
  }) : _repository = repository ?? DashboardRepository(),
       _cacheService = cacheService,
       _taskService = taskService ?? TaskService() {
    final repo = _repository;
    final ts = _taskService;
    final bs = bookingService ?? BookingService(repo.client);
    final dos =
        directOffersService ?? DirectOffersService(Supabase.instance.client);

    _workDelegate = DashboardWorkDelegate(
      repository: repo,
      taskService: ts,
      bookingService: bs,
      directOffersService: dos,
      onChanged: _safeNotify,
      isDisposed: () => _isDisposed,
    );
    _inboxDelegate = DashboardInboxDelegate(
      repository: repo,
      taskService: ts,
      bookingService: bs,
      onChanged: _safeNotify,
      isDisposed: () => _isDisposed,
    );
    _bookingDelegate = DashboardBookingDelegate(
      bookingService: bs,
      onChanged: _safeNotify,
      isDisposed: () => _isDisposed,
    );

    _currentTab = DashboardTab.overview;
    _currentRole = UserRole.freelancer;

    _loadCachedRole();
    _syncRoleFromBackend();
    _loadOverviewData();

    RoleSwitchCoordinator().register(this);
  }

  @override
  void dispose() {
    _isDisposed = true;
    RoleSwitchCoordinator().unregister(this);
    super.dispose();
  }

  @override
  Future<void> teardownForRoleSwitch() async {
    AppLogger.i('dashboard_teardown_role_switch', tag: _kTag);
    _workDelegate.clear();
    _inboxDelegate.clear();
    _bookingDelegate.clear();
    _activityFeed = [];
    _counters = const DashboardCounters();
    AppLogger.i('dashboard_teardown_complete', tag: _kTag);
    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  bool _abortIfDisposed() => _isDisposed;

  // ---------------------------------------------------------------------------
  // Role / Tab / Loading state (stays in parent)
  // ---------------------------------------------------------------------------

  UserRole _currentRole = UserRole.freelancer;
  UserRole get currentRole => _currentRole;

  String? get currentUserId => _repository.currentUser?.id;

  DashboardTab _currentTab = DashboardTab.overview;
  DashboardTab get currentTab => _currentTab;

  int? _workSubTabIndex;
  int? get workSubTabIndex => _workSubTabIndex;

  int? consumeWorkSubTabIndex() {
    final idx = _workSubTabIndex;
    _workSubTabIndex = null;
    return idx;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ActivityLog> _activityFeed = [];
  List<ActivityLog> get activityFeed => _activityFeed;

  DashboardCounters _counters = const DashboardCounters();
  DashboardCounters get counters => _counters;

  String? _userName;
  String get userName => _userName ?? 'there';

  // ---------------------------------------------------------------------------
  // Delegate proxies — preserves the exact public API
  // ---------------------------------------------------------------------------

  // Work
  List<WorkItem> get workItems => _workDelegate.workItems;
  List<WorkItem> get nextActions => _workDelegate.nextActions;
  List<WorkItem> get activeWork => _workDelegate.activeWork;
  List<WorkItem> get deliveredWork => _workDelegate.deliveredWork;
  List<WorkItem> get completedWork => _workDelegate.completedWork;
  List<WorkItem> get cancelledWork => _workDelegate.cancelledWork;
  List<WorkItem> get activeUpNext => _workDelegate.activeUpNext;
  List<WorkItem> get activeInProgress => _workDelegate.activeInProgress;
  List<WorkItem> get activeInReview => _workDelegate.activeInReview;
  List<WorkItem> get activeItems => _workDelegate.activeItems;

  Future<void> performPrimaryAction(WorkItem item) async {
    await _workDelegate.performPrimaryAction(item);
    // Refresh after state-changing actions
    if (item.primaryActionType == PrimaryActionType.startWork ||
        item.primaryActionType == PrimaryActionType.markCompleted) {
      await _loadData();
    }
  }

  Future<void> withdrawOffer(String offerId) async {
    await _workDelegate.withdrawOffer(offerId);
    _inboxDelegate.removeOffer(offerId);
    _safeNotify();
  }

  Future<void> releaseOfferWithFee(String offerId) async {
    await _workDelegate.releaseOfferWithFee(offerId);
    await _fetchWorkItems();
    _safeNotify();
  }

  Future<void> refundOffer(String offerId) async {
    await _workDelegate.refundOffer(offerId);
    _inboxDelegate.removeOffer(offerId);
    await _fetchWorkItems();
    _safeNotify();
  }

  Future<void> cancelAwardedOffer(String requestId) async {
    await _workDelegate.cancelAwardedOffer(requestId);
    if (_abortIfDisposed()) return;
    await refresh();
  }

  // Inbox
  List<TaskRequest> get inboxOffers => _inboxDelegate.inboxOffers;
  List<InboxTaskGroup> get inboxGroupedByTask =>
      _inboxDelegate.inboxGroupedByTask;
  List<Task> get myTasks => _inboxDelegate.myTasks;
  List<BookingModel> get pendingRequests => _inboxDelegate.pendingRequests;
  List<Task> get pendingPaymentTenders => _inboxDelegate.pendingPaymentTenders;

  Future<Map<String, dynamic>?> awardOffer(TaskRequest offer) =>
      _inboxDelegate.awardOffer(offer);

  Future<void> payAwardedOffer(TaskRequest offer) async {
    await _inboxDelegate.payAwardedOffer(offer);
    if (_abortIfDisposed()) return;
    await _fetchWorkItems();
    final mgmt = await _inboxDelegate.loadManagementDataInternal(_currentRole);
    _inboxDelegate.myTasks = mgmt['tasks'] as List<Task>;
    if (_abortIfDisposed()) return;
    _safeNotify();
  }

  @Deprecated(
    'Use awardOffer() and payAwardedOffer() for the two-step tender flow.',
  )
  Future<void> acceptOffer(TaskRequest offer) async {
    // ignore: deprecated_member_use_from_same_package
    await _inboxDelegate.acceptOffer(offer);
    if (_abortIfDisposed()) return;
    await _fetchWorkItems();
    final mgmt = await _inboxDelegate.loadManagementDataInternal(_currentRole);
    _inboxDelegate.myTasks = mgmt['tasks'] as List<Task>;
    if (_abortIfDisposed()) return;
    _safeNotify();
  }

  Future<void> rejectOffer(TaskRequest offer) =>
      _inboxDelegate.rejectOffer(offer);

  // Bookings
  List<BookingModel> get bookings => _bookingDelegate.bookings;
  BookingStatus? get bookingFilter => _bookingDelegate.bookingFilter;

  void setBookingFilter(BookingStatus? status) =>
      _bookingDelegate.setBookingFilter(status);

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) =>
      _bookingDelegate.updateBookingStatus(bookingId, status);

  Future<void> acceptBooking(String bookingId) async {
    await _bookingDelegate.acceptBooking(bookingId);
    await refresh();
  }

  Future<void> declineBooking(String bookingId) async {
    await _bookingDelegate.declineBooking(bookingId);
    await refresh();
  }

  Future<void> cancelBooking(String bookingId) async {
    await _bookingDelegate.cancelBooking(bookingId);
    await refresh();
  }

  // ---------------------------------------------------------------------------
  // Role switching
  // ---------------------------------------------------------------------------

  Future<void> setRole(UserRole role) async {
    if (_currentRole == role) return;
    final previousRole = _currentRole;
    _currentRole = role;
    _safeNotify();
    await _cacheService?.cacheUserRole(role);
    if (_abortIfDisposed()) return;
    try {
      await _repository.updateUserRole(role);
      if (_abortIfDisposed()) return;
      _lastRoleChangeAt = DateTime.now();
      await _loadData(forceRefresh: true);
      if (_abortIfDisposed()) return;
      AppLogger.i('Role switched to: ${role.name}', tag: _kTag);
    } on Exception catch (e) {
      AppLogger.e('Failed to persist role', error: e, tag: _kTag);
      if (!_isDisposed) {
        _currentRole = previousRole;
        await _cacheService?.cacheUserRole(previousRole);
        _safeNotify();
      }
      rethrow;
    }
  }

  Future<void> _loadCachedRole() async {
    final cached = await _cacheService?.getCachedUserRole();
    if (cached != null && cached != _currentRole) {
      _currentRole = cached;
      _safeNotify();
      AppLogger.i('Loaded cached role: ${cached.name}', tag: _kTag);
    }
  }

  Future<void> _syncRoleFromBackend() async {
    try {
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
    } on Exception catch (e) {
      AppLogger.e('Failed to sync role from DB', error: e, tag: _kTag);
    }
  }

  // ---------------------------------------------------------------------------
  // Tab switching
  // ---------------------------------------------------------------------------

  void setTab(int index, {int? workSubTab}) {
    if (index < 0 || index >= DashboardTab.values.length) {
      AppLogger.w('Invalid tab index: $index', tag: _kTag);
      return;
    }
    final tab = DashboardTab.values[index];
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
    if (tab == DashboardTab.bookings && !_bookingDelegate.bookingsLoaded) {
      _bookingDelegate.loadBookingsData(_currentRole);
    } else if (tab == DashboardTab.inbox && !_inboxDelegate.inboxLoaded) {
      _inboxDelegate.loadInboxData(_currentRole);
    }
  }

  Future<void> refresh() => _loadData(forceRefresh: true);

  // ---------------------------------------------------------------------------
  // Data loading orchestration (stays in parent)
  // ---------------------------------------------------------------------------

  Future<void> _loadOverviewData() async {
    AppLogger.d('Loading overview data only (lazy tab)', tag: _kTag);
    final sw = Stopwatch()..start();

    final cache = _cacheService;
    if (cache != null) {
      final cachedWorkItems = await cache.getCachedWorkItems(_currentRole);
      final cachedActivity = await cache.getCachedActivityFeed();
      final cachedCounters = await cache.getCachedCounters();
      if (cachedWorkItems != null || cachedActivity != null) {
        AppLogger.i('⚡ Overview loaded from cache', tag: _kTag);
        _workDelegate.setWorkItems(cachedWorkItems ?? []);
        _activityFeed = cachedActivity ?? [];
        if (cachedCounters != null) {
          _counters = DashboardCounters.fromMap(cachedCounters);
        }
        _isLoading = false;
        _safeNotify();
      }
    }

    _isLoading = true;
    _safeNotify();

    try {
      final fetchedRole = await _repository.fetchUserRole();
      if (_currentRole != fetchedRole) _currentRole = fetchedRole;
      if (_abortIfDisposed()) return;

      _userName =
          _repository.currentUser?.userMetadata?['full_name'] as String?;

      final items = await _repository.fetchWorkItems(_currentRole);
      if (_abortIfDisposed()) return;
      _workDelegate.setWorkItems(items);

      _activityFeed = await _repository.fetchActivityFeed();
      if (_abortIfDisposed()) return;

      _counters = await _repository.fetchCounters(
        _currentRole,
        _workDelegate.workItems,
        [],
      );
      final cacheForSave = _cacheService;
      if (cacheForSave != null && !_abortIfDisposed()) {
        await cacheForSave.cacheWorkItems(
          _workDelegate.workItems,
          _currentRole,
        );
        await cacheForSave.cacheActivityFeed(_activityFeed);
        await cacheForSave.cacheCounters(_counters.toMap());
      }
      sw.stop();
      AppLogger.i(
        '✅ Overview refreshed in ${sw.elapsedMilliseconds}ms',
        tag: _kTag,
      );
    } on Exception catch (e) {
      sw.stop();
      AppLogger.e('Overview load error', error: e, tag: _kTag);
    }
    _isLoading = false;
    _safeNotify();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    AppLogger.d(
      'Loading dashboard data (forceRefresh=$forceRefresh)...',
      tag: _kTag,
    );
    final sw = Stopwatch()..start();

    if (_cacheService != null && !forceRefresh) {
      final cachedWorkItems = await _cacheService.getCachedWorkItems(
        _currentRole,
      );
      final cachedActivity = await _cacheService.getCachedActivityFeed();
      final cachedCounters = await _cacheService.getCachedCounters();
      if (cachedWorkItems != null || cachedActivity != null) {
        AppLogger.i('⚡ Dashboard loaded from cache (instant)', tag: _kTag);
        _workDelegate.setWorkItems(cachedWorkItems ?? []);
        _activityFeed = cachedActivity ?? [];
        if (cachedCounters != null) {
          _counters = DashboardCounters.fromMap(cachedCounters);
        }
        _isLoading = false;
        _safeNotify();
      }
    }

    _isLoading = true;
    _safeNotify();

    try {
      final fetchedRole = await _repository.fetchUserRole();
      if (_currentRole != fetchedRole) _currentRole = fetchedRole;
      if (_abortIfDisposed()) return;

      _userName =
          _repository.currentUser?.userMetadata?['full_name'] as String?;

      final results = await Future.wait([
        _repository.fetchWorkItems(_currentRole),
        _repository.fetchActivityFeed(),
        _bookingDelegate.fetchBookingsInternal(_currentRole),
        _inboxDelegate.fetchInboxInternal(_currentRole),
        _inboxDelegate.fetchPendingItemsInternal(_currentRole),
        _inboxDelegate.loadManagementDataInternal(_currentRole),
      ]);
      if (_abortIfDisposed()) return;

      _workDelegate.setWorkItems(results[0] as List<WorkItem>);
      _activityFeed = results[1] as List<ActivityLog>;

      final bookingsList = results[2] as List<BookingModel>;
      _bookingDelegate.setBookings(bookingsList);

      final inboxList = results[3] as List<TaskRequest>;
      final pendingResult = results[4] as Map<String, dynamic>;
      final mgmtResult = results[5] as Map<String, dynamic>;
      _inboxDelegate.setInboxData(
        offers: inboxList,
        pendingRequests: pendingResult['requests'] as List<BookingModel>,
        pendingPaymentTenders: pendingResult['tenders'] as List<Task>,
        myTasks: mgmtResult['tasks'] as List<Task>,
      );

      _counters = await _repository.fetchCounters(
        _currentRole,
        _workDelegate.workItems,
        _inboxDelegate.inboxOffers,
      );

      if (_cacheService != null && !_abortIfDisposed()) {
        await _cacheService.cacheWorkItems(
          _workDelegate.workItems,
          _currentRole,
        );
        await _cacheService.cacheActivityFeed(_activityFeed);
        await _cacheService.cacheCounters(_counters.toMap());
        AppLogger.i('💾 Dashboard data cached', tag: _kTag);
      }

      sw.stop();
      AppLogger.i(
        '✅ Dashboard refreshed from API in ${sw.elapsedMilliseconds}ms '
        '(${_workDelegate.workItems.length} items, '
        '${_inboxDelegate.inboxOffers.length} offers, '
        '${_bookingDelegate.bookings.length} bookings)',
        tag: _kTag,
      );
    } on Exception catch (e) {
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

  Future<void> _fetchWorkItems() async {
    await _workDelegate.fetchWorkItems(_currentRole);
    if (_abortIfDisposed()) return;
    _counters = await _repository.fetchCounters(
      _currentRole,
      _workDelegate.workItems,
      _inboxDelegate.inboxOffers,
    );
    if (_cacheService != null && !_abortIfDisposed()) {
      await _cacheService.cacheWorkItems(_workDelegate.workItems, _currentRole);
      await _cacheService.cacheCounters(_counters.toMap());
    }
  }
}
