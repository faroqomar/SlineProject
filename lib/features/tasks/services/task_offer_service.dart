import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/features/profile/services/profile_summary_service.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/wallet/services/ledger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Re-export exceptions so callers that import task_offer_service get them.
export 'package:sline_app/features/tasks/exceptions/offer_exceptions.dart'
    show OfferAlreadyAcceptedException, PriceMismatchException;

/// Delegate service handling offer management, award flow, and payment
/// operations for task requests (tenders).
///
/// Extracted from [TaskService] to keep that class focused on task CRUD
/// and query operations. Both services share the same [SupabaseClient].
class TaskOfferService {
  final SupabaseClient _client;
  late final ProfileSummaryService _profileSummaryService;
  late final TaskRequestsService _taskRequestsService;
  late final LedgerService _ledgerService;

  TaskOfferService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client {
    _profileSummaryService = ProfileSummaryService(_client);
    _taskRequestsService = TaskRequestsService(client: _client);
    _ledgerService = LedgerService(_client);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Profile helpers (duplicated minimally — only needed for offer enrichment)
  // ──────────────────────────────────────────────────────────────────────────

  /// Batch-fetch profiles for a set of user IDs.
  Future<Map<String, Map<String, dynamic>>> _fetchProfilesByIds(
    Set<String> userIds, {
    String source = 'unknown',
    String? requestId,
  }) async {
    if (userIds.isEmpty) return {};

    try {
      final response = await _profileSummaryService.fetchByIds(
        userIds,
        source: source,
        requestId: requestId,
      );

      final map = <String, Map<String, dynamic>>{};
      for (final entry in response.entries) {
        map[entry.key] = entry.value;
      }
      return map;
    } on Exception catch (e) {
      AppLogger.w('Failed to fetch profiles batch: $e');
      return {};
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Offer Queries
  // ──────────────────────────────────────────────────────────────────────────

  /// Get offers received for a client's tasks.
  ///
  /// Returns pending offers (to award/reject) and accepted-but-unpaid offers
  /// (to show "Pay Now") so the client can complete payment from the inbox.
  /// Bidder name and avatar are loaded via rpc_get_profile_summaries (RLS on
  /// profiles only allows reading own profile, so we avoid JOIN and batch-fetch).
  Future<List<TaskRequest>> getOffersReceived(String userId) async {
    try {
      final ownedTasks = await _client
          .from('tasks')
          .select('id')
          .or('owner_id.eq.$userId,user_id.eq.$userId,client_id.eq.$userId');

      final taskIds = (ownedTasks as List<dynamic>)
          .map((row) => row['id'] as String?)
          .whereType<String>()
          .toList();

      if (taskIds.isEmpty) {
        return [];
      }

      // Include pending (to award/reject) and accepted+unpaid (to show Pay Now)
      final response = await _client
          .from('task_requests')
          .select(
            'id, task_id, bidder_id, freelancer_id, price, days, duration_days, note, message, status, payment_status, payment_deadline, awarded_at, awarded_by, created_at, deleted_at, tasks(title)',
          )
          .or(
            'status.eq.pending,and(status.eq.accepted,payment_status.eq.unpaid)',
          )
          .isFilter('deleted_at', null)
          .inFilter('task_id', taskIds)
          .order('created_at', ascending: false);

      final rows = response as List;
      if (rows.isEmpty) return [];

      final bidderIds = rows
          .map(
            (r) =>
                (r['freelancer_id'] as String?) ?? (r['bidder_id'] as String?),
          )
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      final profilesMap = await _fetchProfilesByIds(
        bidderIds,
        source: 'getOffersReceived',
      );

      return rows.map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        final bidderId =
            map['freelancer_id'] as String? ?? map['bidder_id'] as String?;
        if (bidderId != null && profilesMap.containsKey(bidderId)) {
          final p = profilesMap[bidderId]!;
          map['profiles'] = {
            'full_name': p['full_name'],
            'avatar_url': p['avatar_url'],
          };
        }
        return TaskRequest.fromMap(map);
      }).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.e('Failed to get offers received', error: e, stackTrace: st);
      return [];
    } on Exception catch (e) {
      AppLogger.e('Failed to get offers received', error: e);
      return [];
    }
  }

  /// Get offers submitted by a freelancer.
  Future<List<TaskRequest>> getOffersSubmitted(String freelancerId) async {
    try {
      final response = await _client
          .from('task_requests')
          .select('*, tasks(title, user_id)') // Join task to show Title
          .eq('freelancer_id', freelancerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskRequest.fromMap(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e, st) {
      AppLogger.e('Failed to get offers submitted', error: e, stackTrace: st);
      return [];
    } on Exception catch (e) {
      AppLogger.e('Failed to get offers submitted', error: e);
      return [];
    }
  }

  /// Withdraw (delete) a pending offer.
  Future<void> withdrawOffer(String requestId) async {
    try {
      // RLS policy `tr_delete` allows deletion if status is pending and owner matches
      await _client.from('task_requests').delete().eq('id', requestId);
      AppLogger.i('Offer withdrawn: $requestId');
    } on PostgrestException catch (e, st) {
      AppLogger.e('Failed to withdraw offer', error: e, stackTrace: st);
      throw Exception(ErrorMapper.map(e));
    } on Exception catch (e) {
      AppLogger.e('Failed to withdraw offer', error: e);
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Offer Actions (accept / reject / escrow / release / refund)
  // ──────────────────────────────────────────────────────────────────────────

  /// Accepts an offer using atomic RPC
  Future<void> acceptOffer(String offerId) async {
    try {
      await _taskRequestsService.accept(offerId);
      AppLogger.i('Offer accepted via RPC: $offerId');
    } on Exception catch (e, st) {
      AppLogger.e('Failed to accept offer', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Rejects an offer
  Future<void> rejectOffer(String offerId) async {
    try {
      await _taskRequestsService.reject(offerId);
      AppLogger.i('Offer rejected: $offerId');
    } on Exception catch (e, st) {
      AppLogger.e('Failed to reject offer', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Escrow hold for a Task Request (Offer)
  Future<void> escrowHoldOffer(String offerId) async {
    try {
      final res = await _client
          .from('task_requests')
          .select('price')
          .eq('id', offerId)
          .single();
      final price = res['price'] as num? ?? 0;

      await _ledgerService.submitPaymentEvent(
        eventType: 'escrow_hold',
        relatedEntityType: 'task_request',
        relatedEntityId: offerId,
        amountGross: price,
        meta: {},
      );

      // Once escrow is held successfully, accept the offer
      await acceptOffer(offerId);
    } on Exception catch (e) {
      AppLogger.e('Failed to process escrow hold for offer', error: e);
      rethrow;
    }
  }

  /// Release payment with fee for a Task Request
  Future<void> releaseOfferWithFee(String offerId) async {
    try {
      final res = await _client
          .from('task_requests')
          .select('price, fee_rate_applied_bps')
          .eq('id', offerId)
          .single();
      final price = res['price'] as num? ?? 0;
      final feeRateBps = res['fee_rate_applied_bps'] as int?;

      await _ledgerService.submitPaymentEvent(
        eventType: 'release_with_fee',
        relatedEntityType: 'task_request',
        relatedEntityId: offerId,
        amountGross: price,
        meta: {if (feeRateBps != null) 'fee_rate_bps': feeRateBps},
      );
    } on Exception catch (e) {
      AppLogger.e('Failed to release offer funds', error: e);
      rethrow;
    }
  }

  /// Refund a Task Request
  Future<void> refundOffer(String offerId) async {
    try {
      final res = await _client
          .from('task_requests')
          .select('price, status')
          .eq('id', offerId)
          .single();
      final price = res['price'] as num? ?? 0;
      final status = res['status'] as String?;

      if (status != 'rejected' &&
          status != 'canceled' &&
          status != 'declined' &&
          status != 'dispute_refund') {
        await rejectOffer(offerId);
      }

      await _ledgerService.submitPaymentEvent(
        eventType: 'refund',
        relatedEntityType: 'task_request',
        relatedEntityId: offerId,
        amountGross: price,
        meta: {},
      );
    } on Exception catch (e) {
      AppLogger.e('Failed to refund offer', error: e);
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Two-Step Award & Payment Flow (Phase 2 - Tender Payment)
  // ──────────────────────────────────────────────────────────────────────────

  /// Award an offer (Step 1: Award without payment)
  ///
  /// This creates an "Awarded but Pending Payment" state.
  /// Client must call [payAwardedOffer] to complete payment and activate work.
  ///
  /// [expectedPriceCents] is the price (in cents) the client saw when clicking Award.
  /// If the freelancer updated their offer since then, a [PriceMismatchException] is thrown.
  Future<Map<String, dynamic>> awardOffer(
    String offerId, {
    int? expectedPriceCents,
  }) async {
    try {
      final result = await _client.rpc(
        'award_task_offer',
        params: {
          'p_request_id': offerId,
          if (expectedPriceCents != null)
            'p_expected_price_cents': expectedPriceCents,
        },
      );

      final resultMap = result as Map<String, dynamic>;

      // Check for price mismatch in result
      if (resultMap['success'] == false &&
          (resultMap['error']?.toString().contains('PRICE_MISMATCH') ??
              false)) {
        final errorMsg = resultMap['error'] as String;
        final regex = RegExp(r'from (\d+) to (\d+)');
        final match = regex.firstMatch(errorMsg);

        if (match != null) {
          final expected = int.tryParse(match.group(1) ?? '0') ?? 0;
          final actual = int.tryParse(match.group(2) ?? '0') ?? 0;
          throw PriceMismatchException(
            expectedCents: expected,
            actualCents: actual,
          );
        }
      }

      // Check for already accepted (idempotency)
      if (resultMap['already_accepted'] == true) {
        throw const OfferAlreadyAcceptedException();
      }

      AppLogger.i('Offer awarded (pending payment): $offerId');
      return resultMap;
    } on PriceMismatchException {
      rethrow;
    } on OfferAlreadyAcceptedException {
      rethrow;
    } on PostgrestException catch (e, st) {
      AppLogger.e('Failed to award offer', error: e, stackTrace: st);
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Pay for an awarded offer (Step 2: Complete payment)
  ///
  /// This triggers escrow hold and activates the work.
  /// After success, freelancer can start working.
  Future<Map<String, dynamic>> payAwardedOffer(String offerId) async {
    AppLogger.i(
      'payAwardedOffer started for request $offerId',
      tag: 'TaskOfferService',
    );
    try {
      // 1. First, get offer details and validate it can be paid
      final offerData = await _client
          .from('task_requests')
          .select('price, task_id, status, payment_status, payment_deadline')
          .eq('id', offerId)
          .single();

      if (offerData['status'] != 'accepted') {
        throw Exception('Offer is not in accepted status');
      }
      if (offerData['payment_status'] != 'unpaid') {
        throw Exception('Offer is already paid or held');
      }

      final deadline = DateTime.tryParse(offerData['payment_deadline'] ?? '');
      if (deadline != null && deadline.isBefore(DateTime.now())) {
        throw Exception('Payment deadline has expired');
      }

      final price = offerData['price'] as num? ?? 0;

      // 2. Create ledger entry for escrow hold FIRST (while status is still 'unpaid')
      await _ledgerService.submitPaymentEvent(
        eventType: 'escrow_hold',
        relatedEntityType: 'task_request',
        relatedEntityId: offerId,
        amountGross: price,
        meta: {'awarded_at': DateTime.now().toUtc().toIso8601String()},
      );

      // 3. Mark the offer as paid in the database AFTER ledger succeeds
      final result =
          await _client.rpc(
                'pay_awarded_offer',
                params: {'p_request_id': offerId},
              )
              as Map<String, dynamic>;

      if (result['success'] != true) {
        // Ledger succeeded but DB update failed - this is a critical inconsistency
        AppLogger.e(
          'CRITICAL: Ledger succeeded but DB update failed for offer: $offerId',
        );
        throw Exception(result['error'] ?? 'Payment status update failed');
      }

      AppLogger.i('Payment completed for awarded offer: $offerId');
      return result;
    } on PostgrestException catch (e, st) {
      AppLogger.e('Failed to pay for awarded offer', error: e, stackTrace: st);
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Cancel an awarded-but-unpaid offer. Task returns to open and reappears in Inbox.
  Future<Map<String, dynamic>> cancelAwardedOffer(String requestId) async {
    try {
      final result =
          await _client.rpc(
                'cancel_awarded_offer',
                params: {'p_request_id': requestId},
              )
              as Map<String, dynamic>;
      if (result['success'] == true) {
        AppLogger.i('Cancelled awarded offer: $requestId');
      }
      return result;
    } on PostgrestException catch (e, st) {
      AppLogger.e('Failed to cancel awarded offer', error: e, stackTrace: st);
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Get client's awarded but unpaid offers (for "Pay Now" UI)
  Future<List<Map<String, dynamic>>> getClientAwardedUnpaidOffers() async {
    try {
      final result = await _client.rpc('get_client_awarded_unpaid_offers');
      return (result as List).cast<Map<String, dynamic>>();
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to get awarded unpaid offers',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Get freelancer's awarded but unpaid offers (for "Waiting for Payment" UI)
  Future<List<Map<String, dynamic>>> getFreelancerAwardedUnpaidOffers() async {
    try {
      final result = await _client.rpc('get_freelancer_awarded_unpaid_offers');
      return (result as List).cast<Map<String, dynamic>>();
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to get freelancer awarded offers',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }
}
