import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_transaction_model.dart';
import '../models/wallet_balance_model.dart';
import '../services/wallet_service.dart';

class WalletRepository {
  WalletRepository(SupabaseClient client) : _service = WalletService(client);

  final WalletService _service;

  Future<List<WalletTransactionModel>> getTransactions({
    int limit = 20,
    String? cursorCreatedAtIso,
  }) {
    return _service.getTransactions(
      limit: limit,
      cursorCreatedAtIso: cursorCreatedAtIso,
    );
  }

  Future<WalletBalanceModel> getWalletBalance() {
    return _service.getWalletBalance();
  }
}
