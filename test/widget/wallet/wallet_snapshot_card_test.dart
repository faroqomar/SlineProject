/// Widget tests for the compact dashboard wallet snapshot.
///
/// The snapshot appears on Dashboard Overview, so this test protects the card
/// from regressing back into oversized button-like rows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/wallet/models/wallet_balance_model.dart';
import 'package:sline_app/features/wallet/view/widgets/wallet_snapshot_card.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';

import '../../helpers/mock_supabase.dart';
import '../../test_support/pump_app.dart';

class _TestWalletViewModel extends WalletViewModel {
  _TestWalletViewModel(WalletBalanceModel walletBalance)
    : super(client: createMockSupabaseClient()) {
    balance = walletBalance;
  }
}

void main() {
  testWidgets(
    'WalletSnapshotCard is compact and keeps balance details visible',
    (
      tester,
    ) async {
      final vm = _TestWalletViewModel(
        const WalletBalanceModel(
          availableBalance: 2062000,
          pendingWithdrawalBalance: 0,
          heldBalance: 0,
        ),
      );

      await pumpApp(
        tester,
        ChangeNotifierProvider<WalletViewModel>.value(
          value: vm,
          child: const Scaffold(
            body: Center(
              child: SizedBox(width: 360, child: WalletSnapshotCard()),
            ),
          ),
        ),
      );

      expect(find.text('AVAILABLE BALANCE'), findsOneWidget);
      expect(find.text('2062K IQD'), findsAtLeastNWidgets(1));
      expect(find.text('Withdraw soon'), findsOneWidget);
      expect(find.text('Top up soon'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Held'), findsOneWidget);
      final balanceText = tester.widget<Text>(find.text('2062K IQD').first);
      expect(
        balanceText.style?.fontFamily,
        AmberDuskTokens.typography.interfaceFamily,
      );
      expect(
        tester.getSize(find.byType(WalletSnapshotCard)).height,
        lessThan(180),
      );
    },
  );

  testWidgets(
    'WalletSnapshotCard displays available balance instead of total',
    (
      tester,
    ) async {
      final vm = _TestWalletViewModel(
        const WalletBalanceModel(
          availableBalance: 1000000,
          pendingWithdrawalBalance: 0,
          heldBalance: 500000,
        ),
      );

      await pumpApp(
        tester,
        ChangeNotifierProvider<WalletViewModel>.value(
          value: vm,
          child: const Scaffold(
            body: Center(
              child: SizedBox(width: 360, child: WalletSnapshotCard()),
            ),
          ),
        ),
      );

      expect(find.text('1000K IQD'), findsAtLeastNWidgets(1));
      expect(find.text('1500K IQD'), findsNothing);
    },
  );
}
