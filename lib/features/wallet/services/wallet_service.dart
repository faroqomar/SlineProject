import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/wallet/models/wallet_activity_model.dart';
import 'package:sline_app/features/wallet/models/wallet_balance_model.dart';
import 'package:sline_app/features/wallet/services/ledger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletService {
  WalletService(this._client);

  final SupabaseClient _client;

  Future<List<WalletActivityModel>> getActivity({
    int limit = 20,
    String? cursorCreatedAtIso,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    var query = _client.from('vw_wallet_activity_user').select();

    if (cursorCreatedAtIso != null) {
      query = query.lt('created_at', cursorCreatedAtIso);
    }

    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List<dynamic>)
        .map((e) => WalletActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WalletBalanceModel> getWalletBalance() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return WalletBalanceModel.zero();

    try {
      final data = await _client
          .from('vw_wallet_balances_user')
          .select()
          .maybeSingle();

      if (data == null) return WalletBalanceModel.zero();
      return WalletBalanceModel.fromJson(data);
    } on Exception catch (e) {
      AppLogger.w(
        'getWalletBalance failed, returning zero',
        tag: 'Wallet',
        error: e,
      );
      return WalletBalanceModel.zero();
    }
  }

  /// Creates a withdrawal request and locks funds via the ledger.
  ///
  /// Flow:
  /// 1. Insert a row into `withdrawal_requests` (status = 'requested')
  /// 2. Call `process_payment_event_ledger` with event_type = 'withdrawal_request'
  ///    which moves funds from user_available → user_pending_withdrawal
  ///
  /// If the ledger call fails, the withdrawal request is cleaned up to prevent
  /// orphaned records.
  Future<String> requestWithdrawal({required num amount}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    if (amount <= 0) {
      throw const FormatException('Withdrawal amount must be positive.');
    }

    AppLogger.i(
      'Creating withdrawal request for amount=$amount',
      tag: 'Wallet',
    );

    String? withdrawalId;

    try {
      // Step 1: Insert withdrawal_request row
      final res = await _client
          .from('withdrawal_requests')
          .insert({
            'user_id': uid,
            'amount': amount,
            'currency': 'IQD',
            'status': 'requested',
          })
          .select()
          .single();

      withdrawalId = res['id'] as String;
      AppLogger.i('Withdrawal request created: $withdrawalId', tag: 'Wallet');

      // Step 2: Lock funds via ledger
      await LedgerService(_client).submitPaymentEvent(
        eventType: 'withdrawal_request',
        relatedEntityType: 'withdrawal_request',
        relatedEntityId: withdrawalId,
        amountGross: amount,
        meta: {},
      );

      AppLogger.i('Funds locked for withdrawal: $withdrawalId', tag: 'Wallet');

      return withdrawalId;
    } on Exception catch (e) {
      // If ledger call failed but we created the withdrawal request, clean it up
      if (withdrawalId != null) {
        AppLogger.w(
          'Ledger call failed for withdrawal $withdrawalId. Cleaning up.',
          tag: 'Wallet',
          error: e,
        );
        try {
          await _client
              .from('withdrawal_requests')
              .update({'status': 'failed'})
              .eq('id', withdrawalId);
        } on Exception catch (cleanupError) {
          AppLogger.e(
            'Failed to cleanup withdrawal request $withdrawalId',
            tag: 'Wallet',
            error: cleanupError,
          );
        }
      }
      rethrow;
    }
  }

  /// Get withdrawal requests for the current user.
  Future<List<Map<String, dynamic>>> getWithdrawalRequests({
    int limit = 20,
    List<String>? statuses,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    var query = _client.from('withdrawal_requests').select().eq('user_id', uid);

    if (statuses != null && statuses.isNotEmpty) {
      query = query.in_('status', statuses);
    }

    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Cancel a pending withdrawal request (if not yet processing).
  Future<void> cancelWithdrawalRequest(String withdrawalId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    // Verify ownership
    final existing = await _client
        .from('withdrawal_requests')
        .select()
        .eq('id', withdrawalId)
        .eq('user_id', uid)
        .eq('status', 'requested')
        .maybeSingle();

    if (existing == null) {
      throw Exception('Withdrawal request not found or cannot be cancelled.');
    }

    // Update status to canceled
    await _client
        .from('withdrawal_requests')
        .update({'status': 'canceled'})
        .eq('id', withdrawalId);

    AppLogger.i('Withdrawal request cancelled: $withdrawalId', tag: 'Wallet');
  }
}
