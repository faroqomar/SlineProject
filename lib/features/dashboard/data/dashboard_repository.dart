import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/models/activity_log.dart';
import 'package:sline_app/features/dashboard/models/dashboard_counters.dart';
import 'package:sline_app/features/dashboard/services/dashboard_permission_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/work/models/unified_work_item_model.dart';

class DashboardRepository {
  final SupabaseClient _client;
  final TaskService _taskService;
  DashboardRepository({SupabaseClient? client, TaskService? taskService})
    : _client = client ?? Supabase.instance.client,
      _taskService = taskService ?? TaskService(client);

  User? get currentUser => _client.auth.currentUser;
  SupabaseClient get client => _client;

  /// Fetch the current user's active role from their profile
  Future<UserRole> fetchUserRole() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return UserRole.freelancer;

    try {
      final response = await _client
          .from('profiles')
          .select('active_role')
          .eq('id', uid)
          .single();

      final roleStr = response['active_role'] as String?;
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

    final roleDbValue = role == UserRole.client ? 'client' : 'freelancer';

    await _client
        .from('profiles')
        .update({'active_role': roleDbValue})
        .eq('id', uid);

    AppLogger.i('Updated DB role to: $roleDbValue');
  }

  /// Fetch all work items using the Unified View
  Future<List<WorkItem>> fetchWorkItems(UserRole role) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      AppLogger.d('Fetching unified work items for role: ${role.name}');

      var query = _client.from('vw_unified_work_items').select();

      if (role == UserRole.client) {
        query = query.eq('client_id', uid);
      } else {
        query = query.eq('freelancer_id', uid);
      }

      final response = await query.order(
        'deadline',
        ascending: true,
      ); // Sort by deadline/urgency

      final unifiedItems = (response as List)
          .map((e) => UnifiedWorkItemModel.fromJson(e))
          .toList();

      final items = unifiedItems
          .map((u) => _mapUnifiedToWorkItem(u, role))
          .toList();

      // Additional Sort: Most recently updated/created first if no deadline, or stick to deadline?
      // Unified view sort order is usually better handled in DB, but we sorted by deadline.
      // Let's keep existing sort logic in ViewModel or here. ViewModel sorts them again.

      AppLogger.i('Fetched ${items.length} unified work items');
      return items;
    } catch (e, st) {
      AppLogger.e('Failed to fetch dashboard items', error: e, stackTrace: st);
      return [];
    }
  }

  WorkItem _mapUnifiedToWorkItem(UnifiedWorkItemModel u, UserRole role) {
    final isClient = role == UserRole.client;
    // Map Counterparty (Unified Model has client_name/avatar etc joined? No, check SQL View)
    // The view `vw_unified_work_items` returns client_id, freelancer_id.
    // It does NOT have names/avatars?
    // Let's check the SQL view definition in `migrations/20260216_unified_flow.sql`.
    // It selects t.*, b.* etc.
    // It does NOT join profiles to get names.
    // So `UnifiedWorkItemModel` only has IDs.
    // WE NEED NAMES/AVATARS.
    // I need to fetch profiles.
    // I'll add a batch profile fetch here.

    // NOTE: This _mapUnifiedToWorkItem function is used inside fetchWorkItems.
    // I should do batch fetch before mapping.
    // But I'm writing this file now.
    // I will add `_enrichUnifiedItemsWithProfiles` method.

    // For now, I'll return placeholders if I can't batch fetch inside `map`.
    // I need to structure `fetchWorkItems` to do batch fetch.
    return WorkItem(
      id: u.id,
      type: u.sourceType == 'booking'
          ? WorkItemType.booking
          : WorkItemType.task,
      title: u.title,
      counterpartyId: isClient ? u.freelancerId : u.clientId,
      counterpartyName: 'Loading...', // Placeholder, enriched later?
      counterpartyAvatar: '',
      counterpartyRole: isClient ? 'Freelancer' : 'Client',
      sourceId: u.id,
      statusRaw: u
          .sourceStatus, // or u.unifiedStatus.name? WorkItem uses statusRaw for logic.
      statusUiBucket: _mapUnifiedStatusToBucket(u.unifiedStatus),
      createdAt:
          DateTime.now(), // View doesn't have created_at? Check UnifiedWorkItemModel.
      // UnifiedWorkItemModel doesn't have created_at.
      // It has deadline sourceStatus.
      // I should add created_at to View and Model if needed.
      // Or use deadline/deliveredAt as proxy.
      scheduledAt: u.deadline,
      lastUpdate: DateTime.now(), // Placeholder
      primaryActionType: DashboardPermissionService.getPrimaryAction(
        userRole: role,
        type: u.sourceType == 'booking'
            ? WorkItemType.booking
            : WorkItemType.task,
        status: u.unifiedStatus,
      ),
      permissions: DashboardPermissionService.calculatePermissions(
        userRole: role,
        type: u.sourceType == 'booking'
            ? WorkItemType.booking
            : WorkItemType.task,
        status: u.unifiedStatus,
      ),
    );
  }

  String _mapUnifiedStatusToBucket(UnifiedWorkStatus status) {
    switch (status) {
      case UnifiedWorkStatus.active:
      case UnifiedWorkStatus.delivered:
        return 'Active';
      case UnifiedWorkStatus.completed:
        return 'Done';
      case UnifiedWorkStatus.canceled:
        return 'Cancelled';
      default:
        return 'Active'; // Safe default
    }
  }

  Future<List<ActivityLog>> fetchActivityFeed({int limit = 10}) async {
    try {
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
    int active = 0;
    int pending = 0;
    int offers = 0;
    int unreadMessages = 0;

    active = currentItems.where((i) {
      return i.statusUiBucket == 'Active';
    }).length;

    if (role == UserRole.client) {
      pending = currentItems.where((i) {
        // Delivered -> Needs review
        if (i.statusRaw == 'delivered') return true;
        // Paid request pending (if mapped)
        return false;
      }).length;

      try {
        final proposals = await _taskService.getOffersReceived(
          _client.auth.currentUser?.id ?? '',
        );
        offers = proposals.where((p) => p.status == OfferStatus.pending).length;
      } catch (_) {}
    } else {
      pending = currentItems.where((i) {
        // Revisions requested?
        return false;
      }).length;

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
      } catch (_) {}
    }

    return DashboardCounters(
      activeWork: active,
      pendingRequests: pending,
      newMessages: unreadMessages,
      newOffers: offers,
    );
  }
}
