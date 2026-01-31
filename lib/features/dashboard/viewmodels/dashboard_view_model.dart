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

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _repository;
  final DashboardCacheService? _cacheService;

  // Dispose guard
  bool _isDisposed = false;
  DateTime? _lastRoleChangeAt;

  DashboardViewModel({
    DashboardRepository? repository,
    DashboardCacheService? cacheService,
  }) : _repository = repository ?? DashboardRepository(),
       _cacheService = cacheService {
    _bookingService = BookingService(_repository.client);
    // Default to overview tab
    _currentTab = DashboardTab.overview;
    // Default role
    _currentRole = UserRole.freelancer; // Will be replaced by cached/DB role

    // Load cached role instantly
    _loadCachedRole();

    // Sync from backend in background
    _syncRoleFromBackend();

    // Load dashboard data
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

  UserRole _currentRole = UserRole.freelancer;
  UserRole get currentRole => _currentRole;

  DashboardTab _currentTab = DashboardTab.overview;
  DashboardTab get currentTab => _currentTab;

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

  // Services (Lazy loaded)
  final ServicesService _servicesService = ServicesService();
  final TaskService _taskService = TaskService(); // Reuse or inject
  late final BookingService _bookingService;

  List<WorkItem> get nextActions => _calculateNextActions();

  // Phase 7: Pending Actions (New for restructuring)
  List<BookingModel> _pendingRequests = [];
  List<BookingModel> get pendingRequests => _pendingRequests;

  List<Task> _pendingPaymentTenders = [];
  List<Task> get pendingPaymentTenders => _pendingPaymentTenders;

  // --- Filtered Work Buckets ---

  /// Active Work: Open, Assigned, Pending, Confirmed, InProgress
  List<WorkItem> get activeWork {
    return _workItems.where((i) {
      final s = i.statusRaw.toLowerCase();
      return s == 'open' ||
          s == 'assigned' ||
          s == 'pending' ||
          s == 'confirmed' ||
          s == 'paid_request_pending' || // Added this
          s == 'inprogress';
    }).toList()..sort((a, b) {
      // Urgency sort
      if (a.scheduledAt != null && b.scheduledAt != null) {
        return a.scheduledAt!.compareTo(b.scheduledAt!);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  /// Completed Work: Completed, Paid, Reviewed
  List<WorkItem> get completedWork {
    return _workItems.where((i) {
      final s = i.statusRaw.toLowerCase();
      return s == 'completed' || s == 'paid' || s == 'reviewed';
    }).toList()..sort((a, b) {
      final timeA = a.completedAt ?? a.lastUpdate;
      final timeB = b.completedAt ?? b.lastUpdate;
      return timeB.compareTo(timeA);
    });
  }

  /// Cancelled Work: Cancelled, Rejected, Declined
  List<WorkItem> get cancelledWork {
    return _workItems.where((i) {
      final s = i.statusRaw.toLowerCase();
      return s == 'cancelled' || s == 'rejected' || s == 'declined';
    }).toList()..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
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

      AppLogger.i('Role switched to: ${role.name}');
    } catch (e) {
      AppLogger.e('Failed to persist role', error: e);

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
      AppLogger.i('Loaded cached role: ${cached.name}');
    }
  }

  /// Syncs role from backend (with protection)
  Future<void> _syncRoleFromBackend() async {
    try {
      // Prevent backend from overriding recent manual change
      if (_lastRoleChangeAt != null) {
        final elapsed = DateTime.now().difference(_lastRoleChangeAt!);
        if (elapsed.inSeconds < 15) {
          AppLogger.d('Skipping role sync - recent manual change');
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
        AppLogger.i('Synced role from DB: ${dbRole.name}');
      }
    } catch (e) {
      AppLogger.e('Failed to sync role from DB', error: e);
      // Keep cached role
    }
  }

  void setTab(int index) {
    final tab = DashboardTab.values[index];
    if (_currentTab == tab) return;
    AppLogger.i('Switching dashboard tab to: ${tab.name}');
    _currentTab = tab;
    _safeNotify();
  }

  /// Load dashboard data with stale-while-revalidate caching
  Future<void> _loadData({bool forceRefresh = false}) async {
    AppLogger.d('Loading dashboard data (forceRefresh=$forceRefresh)...');

    // Phase 1: Try cache first for instant loading (stale)
    if (_cacheService != null && !forceRefresh) {
      final cachedWorkItems = await _cacheService.getCachedWorkItems(
        _currentRole,
      );
      final cachedActivity = await _cacheService.getCachedActivityFeed();
      final cachedCounters = await _cacheService.getCachedCounters();

      if (cachedWorkItems != null || cachedActivity != null) {
        AppLogger.i('⚡ Dashboard loaded from cache (instant)');
        _workItems = cachedWorkItems ?? [];
        _activityFeed = cachedActivity ?? [];

        if (cachedCounters != null) {
          _counters = DashboardCounters.fromMap(cachedCounters);
        }

        _isLoading = false; // Hide initial loading
        _safeNotify();
      }
    }

    // Phase 2: Fetch fresh data in background (revalidate)
    _isLoading = true; // Show refresh indicator
    _safeNotify();

    try {
      // 0. Resolve Role (sync with backend active_role)
      final fetchedRole = await _repository.fetchUserRole();
      if (_currentRole != fetchedRole) {
        _currentRole = fetchedRole;
      }

      // 1. Fetch main work items
      _workItems = await _repository.fetchWorkItems(_currentRole);

      // 2. Fetch activity feed
      _activityFeed = await _repository.fetchActivityFeed();

      // 3. Calculate counters (client-side)
      _counters = await _repository.fetchCounters(_currentRole, _workItems);

      // Cache fresh data for next load
      if (_cacheService != null) {
        await _cacheService.cacheWorkItems(_workItems, _currentRole);
        await _cacheService.cacheActivityFeed(_activityFeed);
        await _cacheService.cacheCounters(_counters.toMap());
        AppLogger.i('💾 Dashboard data cached');
      }

      // 4. Load Management Data (lazy)
      await _loadManagementData();

      // 5. Load Bookings (lazy)
      await _fetchBookings();

      // 6. Load Inbox Offers (lazy)
      await _fetchInbox();

      // 7. Load Pending Items
      await _fetchPendingItems();

      AppLogger.i('✅ Dashboard refreshed from API');
    } catch (e) {
      AppLogger.e('Dashboard load error', error: e);
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> _loadManagementData() async {
    final uid = _repository.currentUser?.id; // Need access to UID
    if (uid == null) return;

    // Accessing auth logic from repo for now or inject AuthService
    // Hack: _repository._client.auth.currentUser? via getter in repo?
    // Let's assume passed in or available.
    // Repo has access to client.

    // Actually DashboardRepository has no getter for user.
    // Let's rely on services handling "current user" implicitly or pass it.
    // ServicesService.getMyServices(uid) needs uid.
    // Let's assume we can get it from repository or Supabase.instance.

    if (_currentRole == UserRole.freelancer) {
      _myServices = await _servicesService.getMyServices(uid);
    } else {
      _myTasks = await _taskService.getTasksByUser(uid);
    }
  }

  Future<void> _fetchBookings() async {
    try {
      if (_currentRole == UserRole.freelancer) {
        _bookings = await _bookingService.listBookingsAsProvider(limit: 50);
      } else {
        _bookings = await _bookingService.listBookingsAsClient(limit: 50);
      }
    } catch (e) {
      AppLogger.e("Failed to fetch bookings", error: e);
    }
  }

  Future<void> _fetchInbox() async {
    final uid = _repository.currentUser?.id;
    if (uid == null) return;

    try {
      if (_currentRole == UserRole.client) {
        _inboxOffers = await _taskService.getOffersReceived(uid);
      } else {
        _inboxOffers = await _taskService.getOffersSubmitted(uid);
      }
      AppLogger.d('Fetched ${_inboxOffers.length} inbox offers');
    } catch (e) {
      AppLogger.e('Failed to fetch inbox offers', error: e);
    }
  }

  Future<void> _fetchPendingItems() async {
    // Current user check
    final uid = _repository.currentUser?.id; // Assuming access to repo user
    // OR: Supabase.instance.client.auth.currentUser?.id
    // Since _repository is initialized with client, we can assume it works if called after auth.
    // Safe check:
    if (uid == null) return;

    try {
      if (_currentRole == UserRole.freelancer) {
        _pendingRequests = await _bookingService.getPendingRequests();
        _pendingPaymentTenders = await _taskService.getPendingPaymentTenders();
      } else {
        _pendingRequests = [];
        _pendingPaymentTenders = [];
      }
      AppLogger.d(
        'Fetched pending items: ${_pendingRequests.length} requests, ${_pendingPaymentTenders.length} tenders',
      );
    } catch (e) {
      AppLogger.e('Failed to fetch pending items', error: e);
    }
  }

  // --- Inbox Actions ---

  Future<void> withdrawOffer(String offerId) async {
    try {
      await _taskService.withdrawOffer(offerId);
      _inboxOffers.removeWhere((o) => o.id == offerId);
      AppLogger.i('Offer withdrawn: $offerId');
      _safeNotify();
    } catch (e) {
      AppLogger.e('Failed to withdraw offer', error: e);
      rethrow;
    }
  }

  /// Accepts an offer atomically
  Future<void> acceptOffer(TaskRequest offer) async {
    try {
      // 1. Call RPC (atomic: accept this, reject others, assign task)
      await _taskService.acceptOffer(offer.id);
      if (_abortIfDisposed()) return;

      // 2. Remove ALL offers for this task (not just this one!)
      // RPC rejects all other offers, so UI should reflect that
      _inboxOffers.removeWhere((o) => o.taskId == offer.taskId);
      _safeNotify();

      // 3. Reload work items only (not full inbox refresh)
      await _fetchWorkItems();
      if (_abortIfDisposed()) return;

      await _loadManagementData();
      if (_abortIfDisposed()) return;

      _safeNotify();
      AppLogger.i('Accepted offer ${offer.id} for task ${offer.taskId}');
    } catch (e) {
      AppLogger.e('Failed to accept offer', error: e);
      rethrow;
    }
  }

  /// Helper to refresh just work items
  Future<void> _fetchWorkItems() async {
    try {
      _workItems = await _repository.fetchWorkItems(_currentRole);
      if (_abortIfDisposed()) return;

      // Update counters
      _counters = await _repository.fetchCounters(_currentRole, _workItems);
      if (_cacheService != null && !_abortIfDisposed()) {
        await _cacheService.cacheWorkItems(_workItems, _currentRole);
        await _cacheService.cacheCounters(_counters.toMap());
      }
    } catch (e) {
      AppLogger.e('Failed to fetch work items', error: e);
    }
  }

  /// Rejects an offer
  Future<void> rejectOffer(TaskRequest offer) async {
    try {
      await _taskService.rejectOffer(offer.id);
      if (_abortIfDisposed()) return;

      // Remove only this offer
      _inboxOffers.removeWhere((o) => o.id == offer.id);
      _safeNotify();

      AppLogger.i('Rejected offer ${offer.id}');
    } catch (e) {
      if (e.toString().contains('Need reject_task_request RPC')) {
        AppLogger.w('Reject needs RPC implementation');
      }
      AppLogger.e('Failed to reject offer', error: e);
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
        AppLogger.i('Updated booking $bookingId status to ${status.name}');
        _safeNotify();
      }
    } catch (e) {
      AppLogger.e("Failed to update booking status", error: e);
      rethrow; // Let UI handle error toast
    }
  }

  Future<void> performPrimaryAction(WorkItem item) async {
    if (item.primaryActionType == PrimaryActionType.approveClose) {
      // Navigation only for now, or 'Closed' status if/when added.
      AppLogger.i("Approve/Close action triggered for ${item.id}");
      return;
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
        AppLogger.i(
          'Primary action "${item.primaryActionType.name}" completed for ${item.id}',
        );
      }

      // Refresh to reflect changes
      await _loadData();
    } catch (e) {
      AppLogger.e("Failed to perform primary action", error: e);
      // For UI feedback, we might want to rethrow or set error state
    }
  }

  List<WorkItem> _calculateNextActions() {
    // Phase 1.3: Strict Sorting (Money/Trust > Urgency > CreatedAt)
    // 1. Pending Actions (Money/Trust)
    final pendingItems = _workItems.where((i) {
      final s = i.statusRaw.toLowerCase();
      // Client Money: 'pending' booking (unpaid), 'delivered' (Trust/Review)
      // Freelancer Money: 'paid_request_pending' (Accept/Decline)
      return s == 'pending' ||
          s == 'paid_request_pending' ||
          s == 'delivered' ||
          s == 'revision_requested';
    }).toList();

    // 2. Urgent Active Work (Deadline approaching)
    final urgentItems = _workItems.where((i) {
      if (pendingItems.contains(i)) return false; // Avoid dupes
      if (i.statusUiBucket != 'Active') return false;
      if (i.scheduledAt == null) return false;
      // Urgent if due within 48 hours or overdue
      final hoursUntil = i.scheduledAt!.difference(DateTime.now()).inHours;
      return hoursUntil < 48;
    }).toList();

    // 3. Recent Active Work (Everything else active)
    final otherItems = _workItems.where((i) {
      if (pendingItems.contains(i)) return false;
      if (urgentItems.contains(i)) return false;
      return i.statusUiBucket == 'Active';
    }).toList();

    // Sort Groups
    pendingItems.sort((a, b) {
      // Delivered > Money Pending
      if (a.statusRaw == 'delivered' && b.statusRaw != 'delivered') return -1;
      if (b.statusRaw == 'delivered' && a.statusRaw != 'delivered') return 1;
      return b.lastUpdate.compareTo(a.lastUpdate);
    });

    urgentItems.sort(
      (a, b) => a.scheduledAt!.compareTo(b.scheduledAt!),
    ); // Closest first

    otherItems.sort(
      (a, b) => b.lastUpdate.compareTo(a.lastUpdate),
    ); // Most recent activity first

    // Combine Top 3
    final combined = [...pendingItems, ...urgentItems, ...otherItems];
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
