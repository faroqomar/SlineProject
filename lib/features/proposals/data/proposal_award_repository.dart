// Award and payment operations for proposals. Uses secure RPCs (auth.uid() bound).
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProposalAwardRepository {
  ProposalAwardRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Award an offer (owner only; auth from session).
  Future<Map<String, dynamic>> awardOffer(String requestId) async {
    AppLogger.i('Proposals: awardOffer request=$requestId', tag: 'Proposals');
    try {
      final result =
          await _client.rpc(
                'award_task_offer',
                params: {'p_request_id': requestId},
              )
              as Map<String, dynamic>;
      if (result['success'] == true) {
        AppLogger.i(
          'Proposals: award success request=$requestId',
          tag: 'Proposals',
        );
      }
      return result;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Proposals: awardOffer failed',
        tag: 'Proposals',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Complete payment for awarded offer (owner only). Call after ledger/confirmation.
  Future<Map<String, dynamic>> finalizePayment(String requestId) async {
    AppLogger.i(
      'Proposals: finalizePayment request=$requestId',
      tag: 'Proposals',
    );
    try {
      final result =
          await _client.rpc(
                'finalize_awarded_offer_payment',
                params: {'p_request_id': requestId},
              )
              as Map<String, dynamic>;
      if (result['success'] == true) {
        AppLogger.i(
          'Proposals: finalize success request=$requestId',
          tag: 'Proposals',
        );
      } else {
        AppLogger.w(
          'Proposals: finalize failed request=$requestId',
          tag: 'Proposals',
        );
      }
      return result;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Proposals: finalizePayment failed',
        tag: 'Proposals',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Legacy: pay_awarded_offer (use finalizePayment when coordinator uses single path).
  Future<Map<String, dynamic>> payAwardedOffer(String requestId) async {
    AppLogger.i(
      'Proposals: payAwardedOffer request=$requestId',
      tag: 'Proposals',
    );
    try {
      final result =
          await _client.rpc(
                'pay_awarded_offer',
                params: {'p_request_id': requestId},
              )
              as Map<String, dynamic>;
      return result;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Proposals: payAwardedOffer failed',
        tag: 'Proposals',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Cancel awarded-but-unpaid offer (owner only).
  Future<Map<String, dynamic>> cancelAwardedOffer(String requestId) async {
    AppLogger.i(
      'Proposals: cancelAwardedOffer request=$requestId',
      tag: 'Proposals',
    );
    try {
      final result =
          await _client.rpc(
                'cancel_awarded_offer',
                params: {'p_request_id': requestId},
              )
              as Map<String, dynamic>;
      if (result['success'] == true) {
        AppLogger.i(
          'Proposals: cancel success request=$requestId',
          tag: 'Proposals',
        );
      }
      return result;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Proposals: cancelAwardedOffer failed',
        tag: 'Proposals',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Client's awarded-unpaid offers (for Pay Now / resume). Auth from session.
  Future<List<ProposalPaymentSummary>> getClientAwardedUnpaid() async {
    AppLogger.d('Proposals: getClientAwardedUnpaid', tag: 'Proposals');
    try {
      final result =
          await _client.rpc('get_client_awarded_unpaid_offers')
              as List<dynamic>?;
      if (result == null || result.isEmpty) return [];
      return result
          .map(
            (r) => _rowToPaymentSummary(
              Map<String, dynamic>.from(r as Map),
              isClient: true,
            ),
          )
          .toList();
    } on Exception catch (e, st) {
      AppLogger.e(
        'Proposals: getClientAwardedUnpaid failed',
        tag: 'Proposals',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Freelancer's awarded-unpaid offers. Auth from session.
  Future<List<ProposalPaymentSummary>> getFreelancerAwardedUnpaid() async {
    AppLogger.d('Proposals: getFreelancerAwardedUnpaid', tag: 'Proposals');
    try {
      final result =
          await _client.rpc('get_freelancer_awarded_unpaid_offers')
              as List<dynamic>?;
      if (result == null || result.isEmpty) return [];
      return result
          .map(
            (r) => _rowToPaymentSummary(
              Map<String, dynamic>.from(r as Map),
              isClient: false,
            ),
          )
          .toList();
    } on Exception catch (e, st) {
      AppLogger.e(
        'Proposals: getFreelancerAwardedUnpaid failed',
        tag: 'Proposals',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  static ProposalPaymentSummary _rowToPaymentSummary(
    Map<String, dynamic> r, {
    required bool isClient,
  }) {
    final requestId = r['request_id'] as String? ?? '';
    final taskId = r['task_id'] as String? ?? '';
    final taskTitle = r['task_title'] as String? ?? 'Task';
    final price = (r['price'] as num?)?.toDouble() ?? 0.0;
    final deadline = r['payment_deadline'] != null
        ? DateTime.tryParse(r['payment_deadline'] as String)
        : null;
    final name = isClient
        ? (r['freelancer_name'] as String? ?? 'Freelancer')
        : (r['client_name'] as String? ?? 'Client');
    return ProposalPaymentSummary(
      requestId: requestId,
      taskId: taskId,
      taskTitle: taskTitle,
      freelancerName: name,
      amount: price,
      paymentDeadline: deadline,
    );
  }
}
