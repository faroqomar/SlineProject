import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/wallet/models/wallet_activity_model.dart';
import 'package:sline_app/features/wallet/models/wallet_balance_model.dart';
import 'package:sline_app/features/wallet/view/wallet_dashboard_screen.dart';
import 'package:sline_app/features/wallet/view/widgets/wallet_shared_body.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';

import '../../helpers/mock_supabase.dart';
import '../../test_support/pump_app.dart';

class _TestWalletViewModel extends WalletViewModel {
  _TestWalletViewModel({
    required bool loaded,
    bool loading = false,
    String? errorMessage,
    WalletBalanceModel? walletBalance,
    List<WalletActivityModel>? walletActivities,
  }) : _loaded = loaded,
       super(client: createMockSupabaseClient()) {
    isLoading = loading;
    error = errorMessage;
    balance = walletBalance ?? WalletBalanceModel.zero();
    activities.addAll(walletActivities ?? const []);
  }

  final bool _loaded;
  int ensureLoadedCalls = 0;

  @override
  bool get hasLoadedWallet => _loaded;

  @override
  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    ensureLoadedCalls += 1;
  }

  @override
  Future<void> loadWallet() async {}
}

Future<void> _pumpWallet(
  WidgetTester tester,
  WalletViewModel viewModel, {
  required Widget child,
}) async {
  await pumpApp(
    tester,
    ChangeNotifierProvider<WalletViewModel>.value(
      value: viewModel,
      child: child,
    ),
  );
}

WalletActivityModel _activity({
  required String id,
  required DateTime createdAtUtc,
  required String eventType,
  required num amountGross,
  num? amountNet,
  num feeAmount = 0,
  String? relatedEntityType,
}) {
  return WalletActivityModel(
    journalEntryId: id,
    createdAtUtc: createdAtUtc,
    eventType: eventType,
    amountGross: amountGross,
    amountNet: amountNet ?? amountGross,
    feeAmount: feeAmount,
    currency: 'IQD',
    relatedEntityType: relatedEntityType,
  );
}

void main() {
  group('WalletSharedBody', () {
    testWidgets('renders loading state', (tester) async {
      final vm = _TestWalletViewModel(loaded: false, loading: true);

      await _pumpWallet(
        tester,
        vm,
        child: const Scaffold(body: WalletSharedBody()),
      );

      expect(
        find.byKey(const ValueKey<String>('wallet_shared_loading')),
        findsOneWidget,
      );
      expect(find.text('Loading wallet'), findsOneWidget);
      expect(vm.ensureLoadedCalls, 1);
    });

    testWidgets('renders error state', (tester) async {
      final vm = _TestWalletViewModel(
        loaded: false,
        errorMessage: 'Network failed',
      );

      await _pumpWallet(
        tester,
        vm,
        child: const Scaffold(body: WalletSharedBody()),
      );

      expect(
        find.byKey(const ValueKey<String>('wallet_shared_error')),
        findsOneWidget,
      );
      expect(find.text('Wallet unavailable'), findsOneWidget);
      expect(find.text('Network failed'), findsOneWidget);
    });

    testWidgets('renders empty activity state', (tester) async {
      final vm = _TestWalletViewModel(
        loaded: true,
        walletBalance: const WalletBalanceModel(
          availableBalance: 500,
          pendingWithdrawalBalance: 0,
          heldBalance: 0,
        ),
      );

      await _pumpWallet(
        tester,
        vm,
        child: const Scaffold(body: WalletSharedBody()),
      );

      expect(
        find.byKey(const ValueKey<String>('wallet_hero_card')),
        findsOneWidget,
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('wallet_shared_list')),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('wallet_empty_state')),
        findsOneWidget,
      );
      expect(find.text('No wallet activity yet'), findsOneWidget);
      expect(find.text('Coming Soon'), findsOneWidget);
    });

    testWidgets('renders populated state with insights and timeline groups', (
      tester,
    ) async {
      // Use local "now" to build test timestamps so that the "Today"
      // bucket is stable regardless of the host timezone offset.
      final localNow = DateTime.now();
      final todayNoon = DateTime(
        localNow.year,
        localNow.month,
        localNow.day,
        12,
      ).toUtc();
      final vm = _TestWalletViewModel(
        loaded: true,
        walletBalance: const WalletBalanceModel(
          availableBalance: 900,
          pendingWithdrawalBalance: 200,
          heldBalance: 300,
        ),
        walletActivities: [
          _activity(
            id: 'txn-today',
            createdAtUtc: todayNoon,
            eventType: 'release_with_fee',
            amountGross: 1200,
            amountNet: 1100,
            feeAmount: 100,
            relatedEntityType: 'booking',
          ),
          _activity(
            id: 'txn-week',
            createdAtUtc: todayNoon.subtract(const Duration(days: 2)),
            eventType: 'gateway_escrow',
            amountGross: 400,
            relatedEntityType: 'task_request',
          ),
          _activity(
            id: 'txn-earlier',
            createdAtUtc: todayNoon.subtract(const Duration(days: 12)),
            eventType: 'withdrawal_request',
            amountGross: 250,
          ),
        ],
      );

      await _pumpWallet(
        tester,
        vm,
        child: const Scaffold(body: WalletSharedBody()),
      );

      expect(find.text('Recent wallet flow'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('Fees'), findsOneWidget);

      // Phase 7: Action card may be below fold after hero card redesign —
      // scroll it into view before asserting.
      await tester.scrollUntilVisible(
        find.text('Coming Soon'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Coming Soon'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('wallet_timeline_card')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('Earlier'), findsOneWidget);
    });
  });

  testWidgets('WalletDashboardScreen no longer renders mock wallet content', (
    tester,
  ) async {
    final vm = _TestWalletViewModel(
      loaded: true,
      walletBalance: const WalletBalanceModel(
        availableBalance: 700,
        pendingWithdrawalBalance: 100,
        heldBalance: 200,
      ),
      walletActivities: [
        _activity(
          id: 'txn-1',
          createdAtUtc: DateTime.now().toUtc().subtract(
            const Duration(hours: 1),
          ),
          eventType: 'release_with_fee',
          amountGross: 900,
          amountNet: 850,
          feeAmount: 50,
          relatedEntityType: 'booking',
        ),
      ],
    );

    await _pumpWallet(tester, vm, child: const WalletDashboardScreen());

    expect(find.text('My Wallet'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('wallet_hero_card')),
      findsOneWidget,
    );
    expect(find.text('Top Up'), findsNothing);
    expect(find.textContaining('4242'), findsNothing);
  });
}
