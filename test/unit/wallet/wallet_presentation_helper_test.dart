import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/wallet/models/wallet_activity_model.dart';
import 'package:sline_app/features/wallet/models/wallet_balance_model.dart';
import 'package:sline_app/features/wallet/utils/wallet_presentation_helper.dart';

void main() {
  group('buildWalletPresentationSummary', () {
    const balance = WalletBalanceModel(
      availableBalance: 500,
      pendingWithdrawalBalance: 200,
      heldBalance: 300,
    );

    final activities = [
      WalletActivityModel(
        journalEntryId: 'txn-1',
        createdAtUtc: DateTime.utc(2026, 3, 11, 9),
        eventType: 'release_with_fee',
        amountGross: 1200,
        amountNet: 1100,
        feeAmount: 100,
        currency: 'IQD',
        relatedEntityType: 'booking',
      ),
      WalletActivityModel(
        journalEntryId: 'txn-2',
        createdAtUtc: DateTime.utc(2026, 3, 9, 10),
        eventType: 'gateway_escrow',
        amountGross: 400,
        amountNet: 400,
        feeAmount: 0,
        currency: 'IQD',
        relatedEntityType: 'task_request',
      ),
      WalletActivityModel(
        journalEntryId: 'txn-3',
        createdAtUtc: DateTime.utc(2026, 2, 27, 11),
        eventType: 'withdrawal_request',
        amountGross: 250,
        amountNet: 250,
        feeAmount: 0,
        currency: 'IQD',
      ),
    ];

    final summary = buildWalletPresentationSummary(
      balance: balance,
      activities: activities,
      now: DateTime.utc(2026, 3, 11, 12),
    );

    test('includes available pending and held in total funds', () {
      expect(summary.availableFunds, 500);
      expect(summary.pendingWithdrawalFunds, 200);
      expect(summary.heldFunds, 300);
      expect(summary.totalFunds, 1000);
    });

    test('calculates received spent and fees from display amounts', () {
      expect(summary.insights[0].label, 'Received');
      expect(summary.insights[0].amount, 1100);

      expect(summary.insights[1].label, 'Spent');
      expect(summary.insights[1].amount, 650);

      expect(summary.insights[2].label, 'Fees');
      expect(summary.insights[2].amount, 100);
    });

    test('groups timeline entries into today this week and earlier', () {
      expect(summary.timelineSections.map((section) => section.title), [
        'Today',
        'This Week',
        'Earlier',
      ]);
      expect(
        summary.timelineSections[0].entries.single.activity.journalEntryId,
        'txn-1',
      );
      expect(
        summary.timelineSections[1].entries.single.activity.journalEntryId,
        'txn-2',
      );
      expect(
        summary.timelineSections[2].entries.single.activity.journalEntryId,
        'txn-3',
      );
    });
  });
}
