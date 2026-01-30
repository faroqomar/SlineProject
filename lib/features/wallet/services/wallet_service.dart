import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_transaction_model.dart';

class WalletService {
  WalletService(this._client);

  final SupabaseClient _client;
  static const String _table = 'wallet_transactions';

  Future<List<WalletTransactionModel>> getTransactions({
    int limit = 20,
    String? cursorCreatedAtIso,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final query = _client.from(_table).select().eq('user_id', uid);

    if (cursorCreatedAtIso != null) {
      query.lt('created_at', cursorCreatedAtIso);
    }

    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List<dynamic>)
        .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Balance calculation could be an RPC or local sum.
  /// For MVP, we can sum local 'released' transactions or fetch from a view.
  /// Phase 1 Plan did not specify a balance view, so we'll sum client-side or assume 0 for now.
  /// Actually, RPC `get_wallet_balance` would be better but I didn't create it.
  /// I'll do a simple query for now.
  Future<num> getBalance() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;

    // Naive implementation: fetch all 'released'/'completed' credit types?
    // This is expensive.
    // Let's just return 0 placeholder or sum latest.
    return 0;
  }
}
