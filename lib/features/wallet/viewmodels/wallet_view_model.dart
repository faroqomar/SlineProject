import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/wallet_repository.dart';
import '../models/wallet_activity_model.dart';
import '../models/wallet_balance_model.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/account_guard_service.dart';

class WalletViewModel extends ChangeNotifier {
  WalletViewModel({SupabaseClient? client})
    : _repo = WalletRepository(client ?? Supabase.instance.client),
      _accountGuardService = AccountGuardService(
        client: client ?? Supabase.instance.client,
      );

  final WalletRepository _repo;
  final AccountGuardService _accountGuardService;

  bool isLoading = false;
  String? error;
  final List<WalletActivityModel> activities = [];
  String? _cursor;
  bool hasMore = true;
  WalletBalanceModel balance = WalletBalanceModel.zero();

  Future<void> loadWallet() async {
    isLoading = true;
    error = null;
    activities.clear();
    _cursor = null;
    notifyListeners();

    try {
      // Parallel fetch
      final results = await Future.wait([
        _repo.getActivity(limit: 20),
        _repo.getWalletBalance(),
      ]);

      final txns = results[0] as List<WalletActivityModel>;
      balance = results[1] as WalletBalanceModel;

      activities.addAll(txns);
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
      final txns = await _repo.getActivity(
        limit: 20,
        cursorCreatedAtIso: _cursor,
      );
      activities.addAll(txns);
      if (txns.isNotEmpty) {
        _cursor = txns.last.createdAtUtc.toUtc().toIso8601String();
      }
      hasMore = txns.length == 20;
    } catch (e) {
      error = e.toString();
      AppLogger.e('Failed to load more activities', error: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Withdrawal Request ──────────────────────────────────
  bool isWithdrawing = false;

  Future<bool> requestWithdrawal({required num amount}) async {
    isWithdrawing = true;
    error = null;
    notifyListeners();

    try {
      final allowed = await _accountGuardService.canPerformSensitiveAction();
      if (!allowed) {
        error = 'Your account is restricted. Please contact support.';
        return false;
      }
      await _repo.requestWithdrawal(amount: amount);
      // Refresh balances to reflect the locked funds
      balance = await _repo.getWalletBalance();
      AppLogger.i('Withdrawal requested: amount=$amount', tag: 'Wallet');
      return true;
    } on FormatException catch (e) {
      error = e.message;
      AppLogger.w('Withdrawal failed: ${e.message}', tag: 'Wallet');
      return false;
    } catch (e) {
      error = 'Failed to request withdrawal. Please try again.';
      AppLogger.e('Withdrawal request failed', error: e, tag: 'Wallet');
      return false;
    } finally {
      isWithdrawing = false;
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
