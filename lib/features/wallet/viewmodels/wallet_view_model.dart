import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/account_guard_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/features/wallet/data/wallet_repository.dart';
import 'package:sline_app/features/wallet/models/wallet_activity_model.dart';
import 'package:sline_app/features/wallet/models/wallet_balance_model.dart';
import 'package:sline_app/features/wallet/utils/wallet_presentation_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletViewModel extends ChangeNotifier {
  WalletViewModel({
    WalletRepository? repo,
    AccountGuardService? accountGuardService,
    SupabaseClient? client,
  }) : _repo = repo ?? WalletRepository(client ?? Supabase.instance.client),
       _accountGuardService =
           accountGuardService ??
           AccountGuardService(client: client ?? Supabase.instance.client);

  final WalletRepository _repo;
  final AccountGuardService _accountGuardService;

  bool isLoading = false;
  String? error;
  final List<WalletActivityModel> activities = [];
  String? _cursor;
  bool _hasLoadedWallet = false;
  bool hasMore = true;
  WalletBalanceModel balance = WalletBalanceModel.zero();
  Future<void>? _loadingFuture;
  bool _pendingForceRefresh = false;

  bool get hasLoadedWallet => _hasLoadedWallet;

  WalletPresentationSummary get summary =>
      buildWalletPresentationSummary(balance: balance, activities: activities);

  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    if (_loadingFuture != null) {
      if (forceRefresh) _pendingForceRefresh = true;
      return _loadingFuture;
    }
    if (!forceRefresh && _hasLoadedWallet) return;

    return _loadingFuture = _runWalletLoadQueue();
  }

  Future<void> _runWalletLoadQueue() async {
    try {
      do {
        _pendingForceRefresh = false;
        await loadWallet();
      } while (_pendingForceRefresh);
    } finally {
      _loadingFuture = null;
    }
  }

  Future<void> loadWallet() async {
    isLoading = true;
    error = null;
    _hasLoadedWallet = false;
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
      _hasLoadedWallet = true;
    } on Exception catch (e) {
      error = ErrorMapper.map(e);
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
    } on Exception catch (e) {
      error = ErrorMapper.map(e);
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
      try {
        // Refresh balance and activities so summary stays consistent (e.g. new pending withdrawal)
        final results = await Future.wait([
          _repo.getWalletBalance(),
          _repo.getActivity(limit: 20),
        ]);
        balance = results[0] as WalletBalanceModel;
        final txns = results[1] as List<WalletActivityModel>;
        activities.clear();
        activities.addAll(txns);
        if (txns.isNotEmpty) {
          _cursor = txns.last.createdAtUtc.toUtc().toIso8601String();
        }
        hasMore = txns.length == 20;
        _hasLoadedWallet = true;
      } on Exception catch (e) {
        error = 'Failed to refresh wallet after withdrawal.';
        AppLogger.e(
          'Withdrawal requested but wallet refresh failed',
          error: e,
          tag: 'Wallet',
        );
      }
      AppLogger.i('Withdrawal requested: amount=$amount', tag: 'Wallet');
      return true;
    } on FormatException catch (e) {
      error = 'Invalid withdrawal amount. Please check and try again.';
      AppLogger.w('Withdrawal failed: ${e.message}', tag: 'Wallet');
      return false;
    } on Exception catch (e) {
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
