import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/models/activity_log.dart';
import 'package:sline_app/features/dashboard/models/dashboard_counters.dart';
import 'package:sline_app/features/dashboard/models/financial_metrics_model.dart';
import 'package:sline_app/features/dashboard/services/dashboard_permission_service.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/work/models/unified_work_item_model.dart';

class DashboardRepository {
  static const _kTag = 'dashboard.repo';
  final SupabaseClient _client;
  DashboardRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

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

  /// Fetch all work items using the Unified View
  Future<List<WorkItem>> fetchWorkItems(UserRole role) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      AppLogger.d(
        'Fetching unified work items for role: ${role.name}',
        tag: _kTag,
      );

      var query = _client.from('vw_unified_work_items').select();

      if (role == UserRole.client) {
        query = query.eq('client_id', uid);
      } else {
        query = query.eq('freelancer_id', uid);
      }

      // v1: Use sort_rank and last_activity_at for ordering
      final response = await query
          .order('sort_rank', ascending: true)
          .order('last_activity_at', ascending: false);

      final unifiedItems = (response as List)
          .map((e) => UnifiedWorkItemModel.fromJson(e))
          .toList();

      final items = unifiedItems
          .map((u) => _mapUnifiedToWorkItem(u, role))
          .toList();

      // Batch-fetch counterparty profiles (single query, no N+1)
      final enrichedItems = await _enrichWithProfiles(items);

      AppLogger.i(
        'Fetched ${enrichedItems.length} unified work items',
        tag: _kTag,
      );
      return enrichedItems;
    } catch (e, st) {
      AppLogger.e(
        'Failed to fetch dashboard items',
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
      final profileRows = await _client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .in_('id', ids);

      // Build a lookup map
      final profileMap = <String, Map<String, dynamic>>{};
      for (final row in profileRows) {
        profileMap[row['id'] as String] = row;
      }

      // Enrich each item
      int enriched = 0;
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
    } catch (e, st) {
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
        : WorkItemType.task;

    return WorkItem(
      id: u.id,
      type: itemType,
      title: u.title,
      counterpartyId: isClient ? u.freelancerId : u.clientId,
      counterpartyName: 'Loading...', // Enriched by profile batch fetch
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
      // v1 fields
      workItemId: u.workItemId,
      needsReview: u.needsReview,
      sortRank: u.sortRank,
      lastActivityAt: u.lastActivityAt,
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
    } catch (e) {
      AppLogger.e('Failed to fetch activity feed', error: e, tag: _kTag);
      return [];
    }
  }

  Future<DashboardCounters> fetchCounters(
    UserRole role,
    List<WorkItem> currentItems,
    List<TaskRequest> inboxOffers,
  ) async {
    int active = 0;
    int pending = 0;
    int offers = 0;
    int unreadMessages = 0;
    int needsReview = 0;
    int pendingPayment = 0;
    int completed = 0;

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
              i.needsReview &&
              (i.statusUiBucket == 'Active' || i.statusUiBucket == 'Pending'),
        )
        .length;

    if (role == UserRole.client) {
      pending = currentItems.where((i) {
        return i.statusUiBucket == 'Pending';
      }).length;

      pendingPayment = currentItems.where((i) {
        return i.statusRaw == 'paid_request_pending';
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

  // ==========================================================================
  // Financial Metrics from Ledger Views
  // ==========================================================================

  /// Fetches real-time financial metrics from the ledger.
  /// These metrics reflect the current platform financial state.
  Future<FinancialMetrics> fetchFinancialMetrics() async {
    try {
      AppLogger.d('Fetching financial metrics from ledger', tag: _kTag);

      final response = await _client
          .from('vw_financial_metrics_realtime')
          .select()
          .maybeSingle();

      if (response == null) {
        AppLogger.w('No financial metrics found, returning zeros', tag: _kTag);
        return FinancialMetrics.zero();
      }

      final metrics = FinancialMetrics.fromJson(response);
      AppLogger.i(
        'Financial metrics: GMV=${metrics.gmv}, Revenue=${metrics.revenue}, Escrow=${metrics.escrowHeld}',
        tag: _kTag,
      );

      return metrics;
    } catch (e, st) {
      AppLogger.e(
        'Failed to fetch financial metrics',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      return FinancialMetrics.zero();
    }
  }

  /// Fetches period-based financial metrics for dashboard charts.
  ///
  /// [days] - Number of days to fetch (default 30)
  Future<List<PeriodFinancialMetrics>> fetchPeriodFinancialMetrics({
    int days = 30,
  }) async {
    try {
      AppLogger.d('Fetching period financial metrics for $days days', tag: _kTag);

      final response = await _client
          .from('vw_financial_metrics_period')
          .select()
          .order('period_start', ascending: false)
          .limit(days);

      final metrics = (response as List)
          .map((e) => PeriodFinancialMetrics.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.i(
        'Fetched ${metrics.length} period metrics',
        tag: _kTag,
      );

      return metrics;
    } catch (e, st) {
      AppLogger.e(
        'Failed to fetch period financial metrics',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      return [];
    }
  }

  /// Fetches wallet balance for the current user from ledger.
  /// This is used by the dashboard to show user's available balance.
  Future<Map<String, double>> fetchWalletBalances() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return {
        'available': 0.0,
        'pending_withdrawal': 0.0,
        'held': 0.0,
      };
    }

    try {
      AppLogger.d('Fetching wallet balances for $uid', tag: _kTag);

      final response = await _client
          .from('vw_wallet_balances_user')
          .select()
          .maybeSingle();

      if (response == null) {
        return {
          'available': 0.0,
          'pending_withdrawal': 0.0,
          'held': 0.0,
        };
      }

      final balances = {
        'available': ((response['available_balance'] ?? 0) as num).toDouble(),
        'pending_withdrawal': ((response['pending_withdrawal_balance'] ?? 0) as num).toDouble(),
        'held': ((response['held_balance'] ?? 0) as num).toDouble(),
      };

      AppLogger.i(
        'Wallet balances: available=${balances['available']}, pending=${balances['pending_withdrawal']}, held=${balances['held']}',
        tag: _kTag,
      );

      return balances;
    } catch (e, st) {
      AppLogger.e(
        'Failed to fetch wallet balances',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      return {
        'available': 0.0,
        'pending_withdrawal': 0.0,
        'held': 0.0,
      };
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
    } catch (e, st) {
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
  Future<List<Map<String, dynamic>>> fetchFreelancerAwardedUnpaidOffers() async {
    try {
      final result = await _client.rpc('get_freelancer_awarded_unpaid_offers');
      final items = result as List;
      AppLogger.i(
        'Fetched ${items.length} awarded unpaid offers for freelancer',
        tag: _kTag,
      );
      return items.cast<Map<String, dynamic>>();
    } catch (e, st) {
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
