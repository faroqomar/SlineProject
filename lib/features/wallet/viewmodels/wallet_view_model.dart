import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/wallet_repository.dart';
import '../models/wallet_transaction_model.dart';
import '../models/wallet_balance_model.dart';
import 'package:sline_app/core/services/logger_service.dart';

class WalletViewModel extends ChangeNotifier {
  WalletViewModel({SupabaseClient? client})
    : _repo = WalletRepository(client ?? Supabase.instance.client);

  final WalletRepository _repo;

  bool isLoading = false;
  String? error;
  final List<WalletTransactionModel> transactions = [];
  String? _cursor;
  bool hasMore = true;
  WalletBalanceModel balance = WalletBalanceModel.zero();

  Future<void> loadWallet() async {
    isLoading = true;
    error = null;
    transactions.clear();
    _cursor = null;
    notifyListeners();

    try {
      // Parallel fetch
      final results = await Future.wait([
        _repo.getTransactions(limit: 20),
        _repo.getWalletBalance(),
      ]);

      final txns = results[0] as List<WalletTransactionModel>;
      balance = results[1] as WalletBalanceModel;

      transactions.addAll(txns);
      if (txns.isNotEmpty) {
        _cursor = txns.last.createdAtUtc.toUtc().toIso8601String();
      }
      hasMore = txns.length == 20;
    } catch (e) {
      error = e.toString();
      AppLogger.e('Failed to load wallet', error: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoading || !hasMore || _cursor == null) return;
    isLoading = true;
    notifyListeners();

    try {
      final txns = await _repo.getTransactions(
        limit: 20,
        cursorCreatedAtIso: _cursor,
      );
      transactions.addAll(txns);
      if (txns.isNotEmpty) {
        _cursor = txns.last.createdAtUtc.toUtc().toIso8601String();
      }
      hasMore = txns.length == 20;
    } catch (e) {
      error = e.toString();
      AppLogger.e('Failed to load more transactions', error: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
