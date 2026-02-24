import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../models/wallet_activity_model.dart';
import '../models/wallet_balance_model.dart';
import 'ledger_service.dart';

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
    } catch (e) {
      return WalletBalanceModel.zero();
    }
  }

  /// Creates a withdrawal request and locks funds via the ledger.
  ///
  /// Flow:
  /// 1. Insert a row into `withdrawal_requests` (status = 'pending')
  /// 2. Call `process_payment_event_ledger` with event_type = 'withdrawal_request'
  ///    which moves funds from user_available → user_pending_withdrawal
  Future<void> requestWithdrawal({required num amount}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    if (amount <= 0) {
      throw const FormatException('Withdrawal amount must be positive.');
    }

    AppLogger.i(
      'Creating withdrawal request for amount=$amount',
      tag: 'Wallet',
    );

    // Step 1: Insert withdrawal_request row
    final res = await _client
        .from('withdrawal_requests')
        .insert({
          'user_id': uid,
          'amount': amount,
          'currency': 'IQD',
          'status': 'pending',
        })
        .select()
        .single();

    final withdrawalId = res['id'] as String;
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
  }
}
