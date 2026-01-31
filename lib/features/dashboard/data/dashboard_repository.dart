import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/services/booking_service.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/models/activity_log.dart';
import 'package:sline_app/features/dashboard/models/dashboard_counters.dart';
import 'package:sline_app/features/dashboard/services/dashboard_permission_service.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';

class DashboardRepository {
  final SupabaseClient _client;
  final TaskService _taskService;
  final BookingService _bookingService;

  DashboardRepository({
    SupabaseClient? client,
    TaskService? taskService,
    BookingService? bookingService,
  }) : _client = client ?? Supabase.instance.client,
       _taskService = taskService ?? TaskService(client),
       _bookingService =
           bookingService ?? BookingService(client ?? Supabase.instance.client);

  User? get currentUser => _client.auth.currentUser;
  SupabaseClient get client => _client;

  /// Fetch the current user's active role from their profile
  Future<UserRole> fetchUserRole() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return UserRole.freelancer; // Default fallback

    try {
      final response = await _client
          .from('profiles')
          .select('active_role')
          .eq('id', uid)
          .single();

      final roleStr = response['active_role'] as String?;
      AppLogger.d('Fetched user role: $roleStr');
      if (roleStr == 'client') {
        return UserRole.client;
      }
      return UserRole.freelancer;
    } catch (e) {
      AppLogger.w(
        'Failed to fetch user role, defaulting to freelancer',
        error: e,
      );
      return UserRole.freelancer;
    }
  }

  /// Updates the user's active role in the database
  Future<void> updateUserRole(UserRole role) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    // Explicit mapping (don't trust enum.name)
    final roleDbValue = role == UserRole.client ? 'client' : 'freelancer';

    await _client
        .from('profiles')
        .update({'active_role': roleDbValue})
        .eq('id', uid);

    AppLogger.i('Updated DB role to: $roleDbValue');
  }

  /// Fetch all work items (Tasks & Bookings) for the given role.
  Future<List<WorkItem>> fetchWorkItems(UserRole role) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      AppLogger.d('Fetching work items for role: ${role.name}');
      final List<WorkItem> items = [];

      if (role == UserRole.freelancer) {
        // Freelancer: Tasks assigned to me + Bookings I provide
        final assignedTasks = await _fetchAssignedTasks(uid);
        items.addAll(assignedTasks.map((t) => _mapTaskToWorkItem(t, role)));

        final bookings = await _bookingService.listBookingsAsProvider(
          limit: 50,
        );
        await _enrichBookingsWithProfiles(bookings, isProviderView: true);
        items.addAll(bookings.map((b) => _mapBookingToWorkItem(b, role)));
      } else {
        // Client: My Orders (Tasks) + My Bookings
        final myTasks = await _taskService.getTasksByUser(uid);

        // Enrich tasks with Assigned Freelancer profiles
        await _enrichTasksWithFreelancers(myTasks);

        items.addAll(myTasks.map((t) => _mapTaskToWorkItem(t, role)));

        final bookings = await _bookingService.listBookingsAsClient(limit: 50);
        await _enrichBookingsWithProfiles(bookings, isProviderView: false);
        items.addAll(bookings.map((b) => _mapBookingToWorkItem(b, role)));
      }

      // Sort: Most recently updated/created first
      items.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
      AppLogger.i('Fetched ${items.length} work items');

      return items;
    } catch (e, st) {
      AppLogger.e('Failed to fetch dashboard items', error: e, stackTrace: st);
      return [];
    }
  }

  Future<void> _enrichTasksWithFreelancers(List<Task> tasks) async {
    final freelancerIds = tasks
        .where((t) => t.assignedFreelancerId != null)
        .map((t) => t.assignedFreelancerId!)
        .toSet();

    if (freelancerIds.isNotEmpty) {
      final profiles = await _fetchProfiles(freelancerIds);
      _tempProfilesCache.addAll(profiles);
    }
  }

  Future<List<ActivityLog>> fetchActivityFeed({int limit = 10}) async {
    try {
      // Join 'profiles' on actor_id
      // Note: In Supabase query, we need to specify relationship if multiple FKs exist to same table.
      // activity_log has user_id -> profiles and actor_id -> profiles.
      // We want actor profile.
      // Relation name usually: "profiles!activity_log_actor_id_fkey"

      final response = await _client
          .from('activity_log')
          .select(
            '*, profiles!activity_log_actor_id_fkey(full_name, avatar_url)',
          )
          .order('created_at', ascending: false)
          .limit(limit);

      final activities = (response as List)
          .map((e) => ActivityLog.fromJson(e))
          .toList();
      AppLogger.d('Fetched ${activities.length} activity log items');
      return activities;
    } catch (e) {
      AppLogger.e('Failed to fetch activity feed', error: e);
      return [];
    }
  }

  Future<DashboardCounters> fetchCounters(
    UserRole role,
    List<WorkItem> currentItems,
  ) async {
    // Phase 1.2: Strict Stats Definitions
    // 1. Pending Actions (Red Dot)
    // 2. Active Work
    // 3. Offers (Needs separate fetch usually)
    // 4. Messages (Needs separate fetch)

    int active = 0;
    int pending = 0;
    int offers = 0;
    int unreadMessages = 0; // TODO: Connect MessageService

    // Active Work: Booking(Active|Delivered) + Order(Active|Delivered)
    // Note: statusUiBucket 'Active' covers: assigned, in_progress, confirmed, paid_request_pending
    // We also need 'delivered' here as per plan.
    active = currentItems.where((i) {
      final s = i.statusRaw.toLowerCase();
      // Active states + Delivered
      return i.statusUiBucket == 'Active' ||
          s == 'delivered' ||
          s == 'in_progress' ||
          s == 'assigned' ||
          s == 'confirmed';
    }).length;

    if (role == UserRole.client) {
      // Client Pending Actions:
      // - unpaid bookings
      // - active orders (assignments) pending payment (if applicable) -> 'assigned' often implies pending work or payment
      // - delivered work (awaiting review)
      // - paid_request_pending bookings (manual confirm)
      pending = currentItems.where((i) {
        final s = i.statusRaw.toLowerCase();
        // Payment status check for bookings handling:
        // Checking status mainly for now.
        // 'delivered' -> Review needed
        // 'paid_request_pending' -> Confirm needed
        // 'assigned' -> Check if paid? (Assuming 'assigned' task needs funding logic later)
        if (s == 'delivered') return true;

        // For bookings:
        if (i.type == WorkItemType.booking) {
          if (s == 'paid_request_pending') {
            return true; // Provider asked for payment/confirm
          }
          // 'pending' booking needs payment?
          if (s == 'pending') return true; // Often "Unpaid" state
        }
        return false;
      }).length;

      // Client Offers: Proposals on open tasks
      // Fetching separately as it's not in WorkItems
      try {
        final proposals = await _taskService.getOffersReceived(
          _client.auth.currentUser?.id ?? '',
        );
        offers = proposals.where((p) => p.status == OfferStatus.pending).length;
      } catch (_) {}
    } else {
      // Freelancer Pending Actions:
      // - paid_request_pending bookings (Action: Accept/Decline)
      // - overdue deliverables (deadline passed & active)
      // - revisions_requested
      pending = currentItems.where((i) {
        final s = i.statusRaw.toLowerCase();
        if (s == 'paid_request_pending') return true;
        if (s == 'revision_requested') return true; // If we add this status

        // Overdue check
        if ((s == 'assigned' || s == 'in_progress' || s == 'confirmed') &&
            i.scheduledAt != null) {
          if (i.scheduledAt!.isBefore(DateTime.now())) return true;
        }
        return false;
      }).length;

      // Freelancer Offers: My Proposals (Submitted/Shortlisted)
      try {
        final myProposals = await _taskService.getOffersSubmitted(
          _client.auth.currentUser?.id ?? '',
        );
        offers = myProposals
            .where(
              (p) =>
                  p.status == OfferStatus.pending ||
                  p.status == OfferStatus.accepted,
            )
            .length;
        // Note: Accepted proposals usually become WorkItems, so counting 'pending' mainly.
      } catch (_) {}
    }

    final counters = DashboardCounters(
      activeWork: active,
      pendingRequests: pending,
      newMessages: unreadMessages,
      newOffers: offers,
    );
    AppLogger.d(
      'Calculated counters: active=$active, pending=$pending, offers=$offers',
    );
    return counters;
  }

  // --- Helpers ---

  Future<List<Task>> _fetchAssignedTasks(String freelancerId) async {
    // TODO: Move to TaskService eventually
    final response = await _client
        .from('tasks')
        .select('''
          id, title, description, budget, user_id, status, task_type,
          category_id, created_at, deadline, skills, image_paths,
          assigned_freelancer_id,
          categories(name)
        ''')
        .eq('assigned_freelancer_id', freelancerId)
        .neq(
          'status',
          'open',
        ) // Open tasks aren't "Assigned" effectively securely usually?
        // Actually if assigned_freelancer_id is set, it is assigned.
        .order('created_at', ascending: false);

    // We also need profiles of the OWNER (user_id) for the Freelancer to see who they work for.
    // TaskService._parseTasksWithProfiles expects user_id profiles.
    // I can reuse TaskService's logic by implementing a quick batch fetch here strictly for dashboard.
    // Or simply:
    final rows = response as List;
    if (rows.isEmpty) return [];

    final ownerIds = rows.map((r) => r['user_id'] as String).toSet();
    final profiles = await _fetchProfiles(ownerIds);

    return rows.map((json) {
      final taskJson = Map<String, dynamic>.from(json as Map);
      final userId = taskJson['user_id'] as String;
      if (profiles.containsKey(userId)) {
        taskJson['profiles'] = profiles[userId];
      }
      return Task.fromJson(taskJson);
    }).toList();
  }

  Future<void> _enrichBookingsWithProfiles(
    List<BookingModel> bookings, {
    required bool isProviderView,
  }) async {
    if (bookings.isEmpty) return;

    final idsToFetch = <String>{};
    for (var b in bookings) {
      // If Provider View, we need Client Profile
      // If Client View, we need Provider Profile
      idsToFetch.add(isProviderView ? b.clientId : b.providerId);
    }

    final profiles = await _fetchProfiles(idsToFetch);

    // We can't mutate BookingModel (const).
    // But we need to pass this profile info to _mapBookingToWorkItem.
    // I will store it in a temporary lookup during mapping,
    // or I can't really "enrich" the model itself.
    // Solution: Return Map logic, or map directly here.
    // Better: _profilesCache for this call.
    _tempProfilesCache = profiles;
  }

  Map<String, Map<String, dynamic>> _tempProfilesCache = {};

  Future<Map<String, Map<String, dynamic>>> _fetchProfiles(
    Set<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    final response = await _client
        .from('profiles')
        .select('id, full_name, avatar_url')
        .in_('id', userIds.toList());

    final map = <String, Map<String, dynamic>>{};
    for (final row in (response as List)) {
      final id = row['id'] as String;
      map[id] = row as Map<String, dynamic>;
    }
    return map;
  }

  WorkItem _mapTaskToWorkItem(Task task, UserRole role) {
    // Determine Counterparty
    String cpId = '';
    String cpName = 'Unknown';
    String cpAvatar = '';

    if (role == UserRole.client) {
      // I am client, counterparty is Freelancer
      // Task model has 'profiles' which is the OWNER (Client).
      // It does NOT have Freelancer profile joined usually unless we fetched it.
      // TaskService.getTasksByUser fetches User (Owner) profile.
      // If assigned_freelancer_id is present, we try to use cached profile.
      if (task.assignedFreelancerId != null &&
          _tempProfilesCache.containsKey(task.assignedFreelancerId)) {
        final profile = _tempProfilesCache[task.assignedFreelancerId!];
        cpName = profile?['full_name'] ?? 'Freelancer';
        cpAvatar = profile?['avatar_url'] ?? '';
        cpId = task.assignedFreelancerId!;
      } else {
        // Fallback if not assigned or not fetched
        cpName = 'Freelancer';
        cpId = task.assignedFreelancerId ?? '';
      }
    } else {
      // I am freelancer, counterparty is Client (Owner)
      // Task model (from _fetchAssignedTasks) has User profile flattened
      cpId = task.userId;
      cpName = task.userName ?? 'Client';
      cpAvatar = task.userAvatar ?? '';
    }

    return WorkItem(
      id: task.id,
      type: WorkItemType.task,
      title: task.title,
      counterpartyId: cpId,
      counterpartyName: cpName,
      counterpartyAvatar: cpAvatar,
      counterpartyRole: role == UserRole.client ? 'Freelancer' : 'Client',
      statusRaw: task.status.name,
      statusUiBucket: 'Active', // Todo: Derive from status
      createdAt: task.createdAt,
      scheduledAt: task.deadline,
      lastUpdate: task.createdAt, // Todo: updated_at if available
      primaryActionType: DashboardPermissionService.getPrimaryAction(
        userRole: role,
        type: WorkItemType.task,
        status: task.status,
      ),
      permissions: DashboardPermissionService.calculatePermissions(
        userRole: role,
        type: WorkItemType.task,
        status: task.status,
      ),
    );
  }

  WorkItem _mapBookingToWorkItem(BookingModel booking, UserRole role) {
    final isProvider = role == UserRole.freelancer;
    final counterpartyId = isProvider ? booking.clientId : booking.providerId;
    final profile = _tempProfilesCache[counterpartyId];

    // Task Title
    final taskTitle = booking.taskData?['title'] ?? 'Booking';

    return WorkItem(
      id: booking.id,
      type: WorkItemType.booking,
      title: taskTitle,
      counterpartyId: counterpartyId,
      counterpartyName: profile?['full_name'] ?? 'User',
      counterpartyAvatar: profile?['avatar_url'] ?? '',
      counterpartyRole: isProvider ? 'Client' : 'Freelancer',
      statusRaw: booking.status.name,
      statusUiBucket: 'Active', // Todo logic
      createdAt: booking.createdAtUtc,
      scheduledAt: booking
          .createdAtUtc, // Uses created for now, logical start comes from Slot?
      // BookingModel doesn't join Slot? It has slotId.
      // We might need to fetch Slot or pass date.
      // BookingService listBookings joins available_slots? No.
      // Ideally Booking should snapshot date.
      // For now use created_at.
      lastUpdate: booking.createdAtUtc,
      primaryActionType: DashboardPermissionService.getPrimaryAction(
        userRole: role,
        type: WorkItemType.booking,
        status: booking.status,
      ),
      permissions: DashboardPermissionService.calculatePermissions(
        userRole: role,
        type: WorkItemType.booking,
        status: booking.status,
      ),
    );
  }
}
