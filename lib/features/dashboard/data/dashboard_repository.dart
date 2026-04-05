import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/dashboard/models/activity_log.dart';
import 'package:sline_app/features/dashboard/models/dashboard_counters.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/services/dashboard_permission_service.dart';
import 'package:sline_app/features/profile/services/profile_summary_service.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/work/models/unified_work_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRepository {
  static const _kTag = 'dashboard.repo';
  final SupabaseClient _client;
  late final ProfileSummaryService _profileSummaryService;
  DashboardRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client {
    _profileSummaryService = ProfileSummaryService(_client);
  }

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
    } on Exception catch (e) {
      AppLogger.w(
        'Failed to fetch user role, defaulting to freelancer',
        error: e,
        tag: _kTag,
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

    AppLogger.i('Updated DB role to: $roleDbValue', tag: _kTag);
  }

  /// Fetch all work items using the Unified View (single source of truth).
  Future<List<WorkItem>> fetchWorkItems(UserRole role) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      AppLogger.d(
        'Fetching unified work items from view for role: ${role.name}',
        tag: _kTag,
      );

      var query = _client.from('vw_unified_work_items').select();

      if (role == UserRole.client) {
        query = query.eq('client_id', uid);
      } else {
        query = query.eq('freelancer_id', uid);
      }

      final response = await query
          .order('sort_rank', ascending: true)
          .order('last_activity_at', ascending: false);

      final unifiedItems = (response as List)
          .map(
            (e) => UnifiedWorkItemModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();

      final items = unifiedItems
          .map((u) => _mapUnifiedToWorkItem(u, role))
          .toList();

      final enrichedItems = await _enrichWithProfiles(items);

      AppLogger.i(
        'Fetched ${enrichedItems.length} work items from vw_unified_work_items',
        tag: _kTag,
        json: {'count': enrichedItems.length, 'role': role.name},
      );
      return enrichedItems;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to fetch dashboard work items',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      return [];
    }
  }

  /// Batch-fetch profiles for all counterparty IDs and enrich WorkItems
  Future<List<WorkItem>> _enrichWithProfiles(List<WorkItem> items) async {
    if (items.isEmpty) return items;

    // Collect unique counterparty IDs
    final ids = items
        .map((i) => i.counterpartyId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) return items;

    try {
      final profileMap = await _profileSummaryService.fetchByIds(ids);

      var enriched = 0;
      final result = items.map((item) {
        final profile = profileMap[item.counterpartyId];
        if (profile == null) return item;

        enriched++;
        return item.withCounterparty(
          name: (profile['full_name'] as String?) ?? 'Unknown',
          avatar: (profile['avatar_url'] as String?) ?? '',
        );
      }).toList();

      AppLogger.i(
        'Enriched $enriched/${items.length} items with profiles',
        tag: _kTag,
      );
      return result;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Profile enrichment failed',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      return items; // Graceful fallback — cards show 'Loading...'
    }
  }

  WorkItem _mapUnifiedToWorkItem(UnifiedWorkItemModel u, UserRole role) {
    final isClient = role == UserRole.client;
    final itemType = u.sourceType == 'booking'
        ? WorkItemType.booking
        : u.sourceType == 'direct_offer'
        ? WorkItemType.directOffer
        : WorkItemType.task;

    return WorkItem(
      id: u.id,
      type: itemType,
      title: u.title,
      counterpartyId: isClient ? u.freelancerId : u.clientId,
      counterpartyName: 'Loading...',
      counterpartyAvatar: '',
      counterpartyRole: isClient ? 'Freelancer' : 'Client',
      sourceId: u.id,
      statusRaw: u.sourceStatus,
      statusUiBucket: _mapUnifiedStatusToBucket(u.unifiedStatus),
      createdAt: u.lastActivityAt ?? DateTime.now(),
      scheduledAt: u.deadline,
      lastUpdate: u.lastActivityAt ?? DateTime.now(),
      primaryActionType: DashboardPermissionService.getPrimaryAction(
        userRole: role,
        type: itemType,
        status: u.unifiedStatus,
      ),
      permissions: DashboardPermissionService.calculatePermissions(
        userRole: role,
        type: itemType,
        status: u.unifiedStatus,
      ),
      workItemId: u.workItemId,
      needsReview: u.needsReview,
      sortRank: u.sortRank,
      lastActivityAt: u.lastActivityAt,
      awardedRequestId: u.awardedRequestId,
      paymentDeadline: u.paymentDeadline,
      price: u.price,
      conversationId: u.conversationId,
    );
  }

  /// Maps unified status to UI bucket.
  /// Buckets: 'Pending', 'Active', 'Done', 'Cancelled'
  String _mapUnifiedStatusToBucket(UnifiedWorkStatus status) {
    switch (status) {
      case UnifiedWorkStatus.pendingPayment:
      case UnifiedWorkStatus.requestPending:
      case UnifiedWorkStatus.pending:
        return 'Pending';
      case UnifiedWorkStatus.active:
      case UnifiedWorkStatus.delivered:
      case UnifiedWorkStatus.disputed:
        return 'Active';
      case UnifiedWorkStatus.completed:
        return 'Done';
      case UnifiedWorkStatus.canceled:
        return 'Cancelled';
      case UnifiedWorkStatus.unknown:
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
      AppLogger.d(
        'Fetched ${activities.length} activity log items',
        tag: _kTag,
      );
      return activities;
    } on Exception catch (e) {
      AppLogger.e('Failed to fetch activity feed', error: e, tag: _kTag);
      return [];
    }
  }

  Future<DashboardCounters> fetchCounters(
    UserRole role,
    List<WorkItem> currentItems,
    List<TaskRequest> inboxOffers,
  ) async {
    var active = 0;
    var pending = 0;
    var offers = 0;
    const unreadMessages = 0;
    var needsReview = 0;
    var pendingPayment = 0;
    var completed = 0;

    active = currentItems.where((i) {
      return i.statusUiBucket == 'Active';
    }).length;

    completed = currentItems.where((i) {
      return i.statusUiBucket == 'Done';
    }).length;

    // v1: Count needs_review and pending_payment from view data
    needsReview = currentItems
        .where(
          (i) =>
              i.actionableNeedsReview &&
              (i.statusUiBucket == 'Active' || i.statusUiBucket == 'Pending'),
        )
        .length;

    if (role == UserRole.client) {
      pending = currentItems.where((i) {
        return i.statusUiBucket == 'Pending';
      }).length;

      pendingPayment = currentItems.where((i) {
        return i.awardedRequestId != null ||
            i.statusRaw == 'paid_request_pending' ||
            (i.type == WorkItemType.directOffer && i.statusRaw == 'accepted');
      }).length;

      // Use pre-fetched inbox offers (no re-query)
      offers = inboxOffers.where((p) => p.status == OfferStatus.pending).length;
    } else {
      pending = currentItems.where((i) {
        return i.statusRaw == 'paid_request_pending';
      }).length;

      // Use pre-fetched inbox offers (no re-query)
      offers = inboxOffers
          .where(
            (p) =>
                p.status == OfferStatus.pending ||
                p.status == OfferStatus.accepted,
          )
          .length;
    }

    return DashboardCounters(
      activeWork: active,
      pendingRequests: pending,
      newMessages: unreadMessages,
      newOffers: offers,
      needsReview: needsReview,
      pendingPayment: pendingPayment,
      completed: completed,
    );
  }

  // Financial metrics (platform-wide) are not available to standard dashboard.
  // See CONTRACT_Dashboard_Finance_Boundary_2026-03-01.md; use admin RPC if needed.

  /// Fetches wallet balance for the current user from ledger.
  /// This is used by the dashboard to show user's available balance.
  Future<Map<String, double>> fetchWalletBalances() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return {'available': 0.0, 'pending_withdrawal': 0.0, 'held': 0.0};
    }

    try {
      AppLogger.d('Fetching wallet balances for $uid', tag: _kTag);

      final response = await _client
          .from('vw_wallet_balances_user')
          .select()
          .maybeSingle();

      if (response == null) {
        return {'available': 0.0, 'pending_withdrawal': 0.0, 'held': 0.0};
      }

      final balances = {
        'available': ((response['available_balance'] ?? 0) as num).toDouble(),
        'pending_withdrawal':
            ((response['pending_withdrawal_balance'] ?? 0) as num).toDouble(),
        'held': ((response['held_balance'] ?? 0) as num).toDouble(),
      };

      AppLogger.i(
        'Wallet balances: available=${balances['available']}, pending=${balances['pending_withdrawal']}, held=${balances['held']}',
        tag: _kTag,
      );

      return balances;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to fetch wallet balances',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      return {'available': 0.0, 'pending_withdrawal': 0.0, 'held': 0.0};
    }
  }

  // ==========================================================================
  // Tender Award & Payment Flow
  // ==========================================================================

  /// Fetches client's awarded but unpaid offers (for "Pay Now" section)
  Future<List<Map<String, dynamic>>> fetchClientAwardedUnpaidOffers() async {
    try {
      final result = await _client.rpc('get_client_awarded_unpaid_offers');
      final items = result as List;
      AppLogger.i(
        'Fetched ${items.length} awarded unpaid offers for client',
        tag: _kTag,
      );
      return items.cast<Map<String, dynamic>>();
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to fetch client awarded unpaid offers',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      return [];
    }
  }

  /// Fetches freelancer's awarded but unpaid offers (for "Waiting for Payment" section)
  Future<List<Map<String, dynamic>>>
  fetchFreelancerAwardedUnpaidOffers() async {
    try {
      final result = await _client.rpc('get_freelancer_awarded_unpaid_offers');
      final items = result as List;
      AppLogger.i(
        'Fetched ${items.length} awarded unpaid offers for freelancer',
        tag: _kTag,
      );
      return items.cast<Map<String, dynamic>>();
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to fetch freelancer awarded unpaid offers',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      return [];
    }
  }
}
