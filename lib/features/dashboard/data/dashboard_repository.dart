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
        // Freelancer:
        // 1. Tasks assigned to me
        // 2. Bookings where I am provider

        // Note: TaskService.getTasksByUser gets tasks CREATED by user.
        // We need tasks ASSIGNED to user.
        // TaskService doesn't have getAssignedTasks? Let's check.
        // If not, we might need to add it or fetch manually.
        // For now preventing error, let's assume getTasksByUser is owner.
        // We need a way to get assigned tasks.

        // Let's implement fetching assigned tasks directly here for now if needed,
        // or just focus on Bookings for freelancer as Proof of Concept if TaskService is limited.
        // Actually, let's look at TaskService again. It has getTasksByStatus but not by assigned_freelancer_id.
        // I'll add a simple query here for assigned tasks.

        final assignedTasks = await _fetchAssignedTasks(uid);
        items.addAll(assignedTasks.map((t) => _mapTaskToWorkItem(t, role)));

        final bookings = await _bookingService.listBookingsAsProvider(
          limit: 50,
        );
        await _enrichBookingsWithProfiles(bookings, isProviderView: true);
        items.addAll(bookings.map((b) => _mapBookingToWorkItem(b, role)));
      } else {
        // Client:
        // 1. Tasks created by me (My Orders)
        // 2. Bookings where I am client

        final myTasks = await _taskService.getTasksByUser(uid);
        items.addAll(myTasks.map((t) => _mapTaskToWorkItem(t, role)));

        final bookings = await _bookingService.listBookingsAsClient(limit: 50);
        await _enrichBookingsWithProfiles(bookings, isProviderView: false);
        items.addAll(bookings.map((b) => _mapBookingToWorkItem(b, role)));
      }

      // Sort by last update or created at
      items.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
      AppLogger.i('Fetched ${items.length} work items');

      return items;
    } catch (e, st) {
      AppLogger.e('Failed to fetch dashboard items', error: e, stackTrace: st);
      return [];
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
    // Optimization: Calculate from currentItems where possible to save queries.
    // Counters needed:
    // Freelancer: Active Work (InProgress), Pending Bookings/Requests, Unread Messages
    // Client: Active Bookings, Open Tasks, Unread Messages

    // 1. Messages (Server fetch needed ideally, or just mocked for now/use MsgService)
    int unreadMessages = 0;
    // Todo: Hook up to MessageService unread count logic.

    int active = 0;
    int pending = 0;
    int offers = 0;

    if (role == UserRole.freelancer) {
      // Active Work: Status InProgress or Confirmed Booking
      active = currentItems.where((i) => i.statusUiBucket == 'Active').length;

      // Pending: Received Bookings pending confirmation
      pending = currentItems
          .where(
            (i) => i.statusRaw == 'pending' && i.type == WorkItemType.booking,
          )
          .length;
    } else {
      // Client
      active = currentItems.where((i) => i.statusUiBucket == 'Active').length;

      // Open Tasks (waiting for offers)
      // Pending here might mean tasks that are OPEN.
      // Or offers received?
      // Let's count Open Tasks as 'Pending' in general sense or use newOffers counter.
      pending = currentItems.where((i) => i.statusRaw == 'open').length;
    }

    final counters = DashboardCounters(
      activeWork: active,
      pendingRequests: pending,
      newMessages: unreadMessages,
      newOffers: offers,
    );
    AppLogger.d('Calculated counters: active=$active, pending=$pending');
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
      // If assigned_freelancer_id is present, we might haven't fetched their profile?
      // For MVP, if freelancer is assigned, we might show "Assigned" or fetch profile.
      // Let's rely on tasks view having sufficient specific data or generic "Freelancer".
      // Actually TaskService doesn't fetch freelancer profile.
      // For now, use generic or Task Title focused.
      cpName = 'Freelancer'; // TODO: Fetch freelancer profile
      cpId = task.assignedFreelancerId ?? '';
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
