import 'package:flutter/foundation.dart';
import 'package:sline_app/core/utils/format_date.dart';

import 'package:sline_app/features/wallet/models/wallet_activity_model.dart';
import 'package:sline_app/features/wallet/models/wallet_balance_model.dart';
import 'package:sline_app/features/wallet/utils/transaction_label_helper.dart';

enum WalletInsightKind { received, spent, fees }

enum WalletBalanceSliceKind { available, pendingWithdrawal, held }

@immutable
class WalletPresentationSummary {
  const WalletPresentationSummary({
    required this.totalFunds,
    required this.availableFunds,
    required this.pendingWithdrawalFunds,
    required this.heldFunds,
    required this.balanceSlices,
    required this.insights,
    required this.timelineSections,
    required this.activityCaption,
  });

  final double totalFunds;
  final double availableFunds;
  final double pendingWithdrawalFunds;
  final double heldFunds;
  final List<WalletBalanceSlice> balanceSlices;
  final List<WalletInsightStat> insights;
  final List<WalletTimelineSection> timelineSections;
  final String activityCaption;

  bool get hasActivity => timelineSections.isNotEmpty;
}

@immutable
class WalletBalanceSlice {
  const WalletBalanceSlice({
    required this.kind,
    required this.label,
    required this.amount,
    required this.ratio,
  });

  final WalletBalanceSliceKind kind;
  final String label;
  final double amount;
  final double ratio;
}

@immutable
class WalletInsightStat {
  const WalletInsightStat({
    required this.kind,
    required this.label,
    required this.caption,
    required this.amount,
  });

  final WalletInsightKind kind;
  final String label;
  final String caption;
  final double amount;
}

@immutable
class WalletTimelineSection {
  const WalletTimelineSection({required this.title, required this.entries});

  final String title;
  final List<WalletTimelineEntry> entries;
}

@immutable
class WalletTimelineEntry {
  const WalletTimelineEntry({
    required this.activity,
    required this.label,
    required this.eventName,
    required this.timestampLabel,
    required this.isReceived,
    required this.displayAmount,
  });

  final WalletActivityModel activity;
  final String label;
  final String eventName;
  final String timestampLabel;
  final bool isReceived;
  final double displayAmount;
}

WalletPresentationSummary buildWalletPresentationSummary({
  required WalletBalanceModel balance,
  required List<WalletActivityModel> activities,
  DateTime? now,
}) {
  final availableFunds = _clampAmount(balance.availableBalance);
  final pendingWithdrawalFunds = _clampAmount(balance.pendingWithdrawalBalance);
  final heldFunds = _clampAmount(balance.heldBalance);
  final totalFunds = availableFunds + pendingWithdrawalFunds + heldFunds;

  final sortedActivities = List<WalletActivityModel>.from(activities)
    ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));

  double receivedTotal = 0;
  double spentTotal = 0;
  double feeTotal = 0;

  final todayEntries = <WalletTimelineEntry>[];
  final thisWeekEntries = <WalletTimelineEntry>[];
  final earlierEntries = <WalletTimelineEntry>[];

  final localNow = (now ?? DateTime.now()).toLocal();
  final todayStart = DateTime(localNow.year, localNow.month, localNow.day);
  final weekStart = todayStart.subtract(Duration(days: localNow.weekday - 1));

  for (final activity in sortedActivities) {
    final isReceived = isReceivedTransaction(activity);
    final displayAmount = _displayAmount(activity);
    final timelineEntry = WalletTimelineEntry(
      activity: activity,
      label: getTransactionSourceOrDestination(activity),
      eventName: _humanizeEventType(activity.eventType),
      timestampLabel: formatUtcToLocal(activity.createdAtUtc),
      isReceived: isReceived,
      displayAmount: displayAmount,
    );

    if (isReceived) {
      receivedTotal += displayAmount;
    } else {
      spentTotal += displayAmount;
    }
    feeTotal += _clampAmount(activity.feeAmount);

    final localCreatedAt = activity.createdAtUtc.toLocal();
    if (!localCreatedAt.isBefore(todayStart)) {
      todayEntries.add(timelineEntry);
    } else if (!localCreatedAt.isBefore(weekStart)) {
      thisWeekEntries.add(timelineEntry);
    } else {
      earlierEntries.add(timelineEntry);
    }
  }

  final timelineSections = <WalletTimelineSection>[
    if (todayEntries.isNotEmpty)
      WalletTimelineSection(
        title: 'Today',
        entries: List.unmodifiable(todayEntries),
      ),
    if (thisWeekEntries.isNotEmpty)
      WalletTimelineSection(
        title: 'This Week',
        entries: List.unmodifiable(thisWeekEntries),
      ),
    if (earlierEntries.isNotEmpty)
      WalletTimelineSection(
        title: 'Earlier',
        entries: List.unmodifiable(earlierEntries),
      ),
  ];

  return WalletPresentationSummary(
    totalFunds: totalFunds,
    availableFunds: availableFunds,
    pendingWithdrawalFunds: pendingWithdrawalFunds,
    heldFunds: heldFunds,
    balanceSlices: List.unmodifiable([
      WalletBalanceSlice(
        kind: WalletBalanceSliceKind.available,
        label: 'Available',
        amount: availableFunds,
        ratio: totalFunds == 0 ? 0 : availableFunds / totalFunds,
      ),
      WalletBalanceSlice(
        kind: WalletBalanceSliceKind.pendingWithdrawal,
        label: 'Pending',
        amount: pendingWithdrawalFunds,
        ratio: totalFunds == 0 ? 0 : pendingWithdrawalFunds / totalFunds,
      ),
      WalletBalanceSlice(
        kind: WalletBalanceSliceKind.held,
        label: 'Held',
        amount: heldFunds,
        ratio: totalFunds == 0 ? 0 : heldFunds / totalFunds,
      ),
    ]),
    insights: List.unmodifiable([
      WalletInsightStat(
        kind: WalletInsightKind.received,
        label: 'Received',
        caption: 'Recent inflow',
        amount: receivedTotal,
      ),
      WalletInsightStat(
        kind: WalletInsightKind.spent,
        label: 'Spent',
        caption: 'Recent outflow',
        amount: spentTotal,
      ),
      WalletInsightStat(
        kind: WalletInsightKind.fees,
        label: 'Fees',
        caption: 'Platform fees',
        amount: feeTotal,
      ),
    ]),
    timelineSections: List.unmodifiable(timelineSections),
    activityCaption: sortedActivities.isEmpty
        ? 'No recent wallet activity yet'
        : 'Based on your latest ${sortedActivities.length} wallet entries',
  );
}

double _displayAmount(WalletActivityModel activity) {
  final rawAmount = activity.eventType == 'release_with_fee'
      ? activity.amountNet
      : activity.amountGross;
  return _clampAmount(rawAmount);
}

double _clampAmount(num value) {
  return value.toDouble().clamp(0.0, double.infinity);
}

String _humanizeEventType(String eventType) {
  return eventType
      .split('_')
      .map(
        (part) =>
            part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ')
      .trim();
}
