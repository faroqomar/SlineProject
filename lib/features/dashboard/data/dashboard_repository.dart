import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/models/activity_log.dart';
import 'package:sline_app/features/dashboard/models/dashboard_counters.dart';
import 'package:sline_app/features/dashboard/services/dashboard_permission_service.dart';
import 'package:sline_app/features/profile/services/profile_summary_service.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/work/models/unified_work_item_model.dart';
import 'package:sline_app/features/direct_offers/models/direct_offer_model.dart';

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

      var items = unifiedItems
          .map((u) => _mapUnifiedToWorkItem(u, role))
          .toList();

      // Fallback: if view has no third branch (awarded pending payment), fetch from task_requests + tasks so Work tab shows them
      if (role == UserRole.client) {
        final fallback = await _fetchAwardedPendingPaymentFallback(uid);
        final fromViewIds = items.map((i) => i.id).toSet();
        for (final w in fallback) {
          if (!fromViewIds.contains(w.id)) {
            items = [...items, w];
            fromViewIds.add(w.id);
          }
        }
      }

      // Fetch direct offers (active/delivered/completed) and merge
      final directOffers = await _fetchDirectOffers(uid);
      final byRole = role == UserRole.client
          ? directOffers.where((o) => o.clientId == uid).toList()
          : directOffers.where((o) => o.freelancerId == uid).toList();
      final directWorkItems = byRole
          .map((o) => _mapDirectOfferToWorkItem(o, uid, role))
          .toList();
      final merged = <WorkItem>[...items, ...directWorkItems]
        ..sort((a, b) {
          final rank = (a.sortRank).compareTo(b.sortRank);
          if (rank != 0) return rank;
          final aAt = a.lastActivityAt ?? a.lastUpdate;
          final bAt = b.lastActivityAt ?? b.lastUpdate;
          return bAt.compareTo(aAt);
        });

      // Batch-fetch counterparty profiles (single query, no N+1)
      final enrichedItems = await _enrichWithProfiles(merged);

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
      final profileMap = await _profileSummaryService.fetchByIds(ids);

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
      awardedRequestId: u.awardedRequestId,
      paymentDeadline: u.paymentDeadline,
      price: u.price,
    );
  }

  /// Fallback when vw_unified_work_items has no third branch: fetch awarded-unpaid task_requests (client only).
  /// RLS allows SELECT for task owner; merge into work items so "Waiting payment" shows on Work tab.
  Future<List<WorkItem>> _fetchAwardedPendingPaymentFallback(String uid) async {
    try {
      final response = await _client
          .from('task_requests')
          .select('id, task_id, price, payment_deadline, updated_at, freelancer_id, bidder_id, tasks!task_id(id, title, deadline, owner_id, status)')
          .eq('status', 'accepted')
          .eq('payment_status', 'unpaid');

      final list = response as List;
      final workItems = <WorkItem>[];
      for (final e in list) {
        final map = Map<String, dynamic>.from(e as Map);
        final taskMap = map['tasks'] as Map<String, dynamic>?;
        if (taskMap == null) continue;
        final taskId = taskMap['id'] as String?;
        final ownerId = taskMap['owner_id'] as String?;
        if (taskId == null || ownerId != uid) continue;
        final title = taskMap['title'] as String? ?? '';
        final deadline = map['payment_deadline'] != null
            ? DateTime.tryParse(map['payment_deadline'] as String)
            : null;
        final requestId = map['id'] as String? ?? '';
        final freelancerId = (map['freelancer_id'] as String?) ?? (map['bidder_id'] as String?) ?? '';
        final price = (map['price'] as num?)?.toDouble() ?? 0.0;
        final updatedAt = map['updated_at'] != null
            ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
            : DateTime.now();
        final paymentDeadline = map['payment_deadline'] != null
            ? DateTime.tryParse(map['payment_deadline'] as String)
            : null;

        workItems.add(WorkItem(
          id: taskId,
          type: WorkItemType.task,
          title: title,
          counterpartyId: freelancerId,
          counterpartyName: 'Loading...',
          counterpartyAvatar: '',
          counterpartyRole: 'Freelancer',
          sourceId: taskId,
          statusRaw: 'assigned',
          statusUiBucket: 'Pending',
          createdAt: updatedAt,
          scheduledAt: deadline,
          lastUpdate: updatedAt,
          primaryActionType: PrimaryActionType.payEscrow,
          permissions: DashboardPermissionService.calculatePermissions(
            userRole: UserRole.client,
            type: WorkItemType.task,
            status: UnifiedWorkStatus.pendingPayment,
          ),
          workItemId: 'task:$taskId',
          needsReview: false,
          sortRank: 2,
          lastActivityAt: updatedAt,
          awardedRequestId: requestId,
          paymentDeadline: paymentDeadline,
          price: price,
        ));
      }
      if (workItems.isNotEmpty) {
        AppLogger.d(
          'Fallback: fetched ${workItems.length} awarded pending-payment items',
          tag: _kTag,
        );
      }
      return workItems;
    } catch (e, st) {
      AppLogger.e(
        'Fallback awarded pending-payment fetch failed',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      return [];
    }
  }

  Future<List<DirectOffer>> _fetchDirectOffers(String uid) async {
    try {
      final response = await _client
          .from('direct_offers')
          .select()
          .or('client_id.eq.$uid,freelancer_id.eq.$uid')
          .in_('status', ['accepted', 'active', 'delivered', 'completed']);
      return (response as List)
          .map((e) => DirectOffer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      AppLogger.e(
        'Failed to fetch direct offers',
        error: e,
        stackTrace: st,
        tag: _kTag,
      );
      return [];
    }
  }

  static UnifiedWorkStatus _directOfferStatusToUnified(
    String status,
    String paymentStatus,
  ) {
    if (status == 'accepted' && paymentStatus == 'unpaid') {
      return UnifiedWorkStatus.pendingPayment;
    }
    switch (status) {
      case 'active':
        return UnifiedWorkStatus.active;
      case 'delivered':
        return UnifiedWorkStatus.delivered;
      case 'completed':
        return UnifiedWorkStatus.completed;
      default:
        return UnifiedWorkStatus.active;
    }
  }

  static String _directOfferStatusToBucket(
    String status,
    String paymentStatus,
  ) {
    if (status == 'accepted' && paymentStatus == 'unpaid') return 'Pending';
    switch (status) {
      case 'active':
        return 'Active';
      case 'delivered':
        return 'Active';
      case 'completed':
        return 'Done';
      default:
        return 'Active';
    }
  }

  WorkItem _mapDirectOfferToWorkItem(DirectOffer o, String uid, UserRole role) {
    final isClient = role == UserRole.client;
    final counterpartyId = isClient ? o.freelancerId : o.clientId;
    final unifiedStatus = _directOfferStatusToUnified(
      o.status,
      o.paymentStatus,
    );
    final sortRank = o.status == 'accepted' && o.paymentStatus == 'unpaid'
        ? 2
        : o.status == 'active'
        ? 4
        : o.status == 'delivered'
        ? 5
        : 6;
    return WorkItem(
      id: o.id,
      type: WorkItemType.directOffer,
      title: o.title?.isNotEmpty == true ? o.title! : 'Custom Offer',
      counterpartyId: counterpartyId,
      counterpartyName: 'Loading...',
      counterpartyAvatar: '',
      counterpartyRole: isClient ? 'Freelancer' : 'Client',
      sourceId: o.id,
      statusRaw: o.status == 'accepted' && o.paymentStatus == 'unpaid'
          ? 'accepted'
          : o.status,
      statusUiBucket: _directOfferStatusToBucket(o.status, o.paymentStatus),
      createdAt: o.createdAt,
      scheduledAt: null,
      lastUpdate: o.updatedAt,
      primaryActionType: DashboardPermissionService.getPrimaryAction(
        userRole: role,
        type: WorkItemType.directOffer,
        status: unifiedStatus,
      ),
      permissions: DashboardPermissionService.calculatePermissions(
        userRole: role,
        type: WorkItemType.directOffer,
        status: unifiedStatus,
      ),
      workItemId: 'direct_offer:${o.id}',
      needsReview: o.status == 'delivered' && isClient,
      sortRank: sortRank,
      lastActivityAt: o.updatedAt,
      conversationId: o.conversationId,
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
    } catch (e, st) {
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
