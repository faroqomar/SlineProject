import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/glass_card.dart';
import 'package:sline_app/features/wallet/utils/wallet_presentation_helper.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';

class WalletSharedBody extends StatefulWidget {
  const WalletSharedBody({
    super.key,
    this.header,
    this.padding = const EdgeInsets.all(AppDimens.p16),
    this.bottomSpacing = AppDimens.p100,
  });

  final Widget? header;
  final EdgeInsetsGeometry padding;
  final double bottomSpacing;

  @override
  State<WalletSharedBody> createState() => _WalletSharedBodyState();
}

class _WalletSharedBodyState extends State<WalletSharedBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WalletViewModel>().ensureLoaded();
    });
  }

  Future<void> _refresh(BuildContext context) {
    return context.read<WalletViewModel>().loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletViewModel>(
      builder: (context, vm, _) {
        final summary = vm.summary;
        final children = <Widget>[
          if (widget.header != null) widget.header!,
          if (widget.header != null) const SizedBox(height: AppDimens.p24),
        ];

        if (!vm.hasLoadedWallet && vm.error == null) {
          children.add(const _WalletLoadingCard());
        } else if (!vm.hasLoadedWallet && vm.error != null) {
          children.add(
            _WalletErrorCard(
              message: vm.error!,
              onRetry: () => _refresh(context),
            ),
          );
        } else {
          children.addAll([
            _WalletHeroCard(summary: summary),
            const SizedBox(height: AppDimens.p16),
            _WalletInsightsCard(summary: summary),
            const SizedBox(height: AppDimens.p16),
            _WalletActionCard(summary: summary),
            const SizedBox(height: AppDimens.p24),
            _WalletTimelineCard(summary: summary),
          ]);
        }

        children.add(SizedBox(height: widget.bottomSpacing));

        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView(
            key: const ValueKey<String>('wallet_shared_list'),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: widget.padding,
            children: children,
          ),
        );
      },
    );
  }
}

class _WalletLoadingCard extends StatelessWidget {
  const _WalletLoadingCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      key: const ValueKey<String>('wallet_shared_loading'),
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Column(
        children: [
          const SizedBox(height: AppDimens.p8),
          const CircularProgressIndicator(),
          const SizedBox(height: AppDimens.p20),
          Text(
            'Loading wallet',
            style: AppTypography.h5.copyWith(color: context.colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            'Pulling in your live balance and recent ledger activity.',
            style: AppTypography.bodyMedium.copyWith(
              color: context.colorScheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WalletErrorCard extends StatelessWidget {
  const _WalletErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      key: const ValueKey<String>('wallet_shared_error'),
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppDimens.p48,
            height: AppDimens.p48,
            decoration: BoxDecoration(
              color: AppColors.lightRed.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_tethering_error_rounded,
              color: AppColors.lightRed,
              size: AppDimens.iconSizeMedium,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Text(
            'Wallet unavailable',
            style: AppTypography.h5.copyWith(color: context.colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.p20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                padding: const EdgeInsets.symmetric(vertical: AppDimens.p16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.r14),
                ),
              ),
              label: const Text('Try again'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletHeroCard extends StatelessWidget {
  const _WalletHeroCard({required this.summary});

  final WalletPresentationSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('wallet_hero_card'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.r24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkTeal,
            AppColors.teal,
            AppColors.lightTeal.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.r24),
        child: Stack(
          children: [
            Positioned(
              top: -48,
              right: -24,
              child: _GlowOrb(
                size: 148,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              bottom: -62,
              left: -30,
              child: _GlowOrb(
                size: 168,
                color: AppColors.gold.withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              top: 72,
              right: 28,
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.24),
                size: AppDimens.p40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.p10,
                          vertical: AppDimens.p6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppDimens.r30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          'WALLET',
                          style: AppTypography.micro.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.p18),
                  Text(
                    'Total funds',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                  ),
                  const SizedBox(height: AppDimens.p8),
                  Text(
                    PriceFormatter.formatPrice(summary.totalFunds),
                    style: AppTypography.h1.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppDimens.p8),
                  Text(
                    summary.activityCaption,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: AppDimens.p20),
                  Text(
                    'Balance composition',
                    style: AppTypography.micro.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: AppDimens.p10),
                  _WalletBalanceCompositionBar(slices: summary.balanceSlices),
                  const SizedBox(height: AppDimens.p18),
                  Wrap(
                    spacing: AppDimens.p10,
                    runSpacing: AppDimens.p10,
                    children: summary.balanceSlices
                        .map((slice) => _BalanceChip(slice: slice))
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletInsightsCard extends StatelessWidget {
  const _WalletInsightsCard({required this.summary});

  final WalletPresentationSummary summary;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      key: const ValueKey<String>('wallet_insights_card'),
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent wallet flow',
            style: AppTypography.h5.copyWith(color: context.colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p6),
          Text(
            summary.activityCaption,
            style: AppTypography.bodySmall.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final columns = maxWidth >= 720
                  ? 3
                  : maxWidth >= 460
                  ? 2
                  : 1;
              final tileWidth = columns == 1
                  ? maxWidth
                  : (maxWidth - ((columns - 1) * AppDimens.p12)) / columns;

              return Wrap(
                spacing: AppDimens.p12,
                runSpacing: AppDimens.p12,
                children: summary.insights
                    .map(
                      (insight) => SizedBox(
                        width: tileWidth,
                        child: _InsightTile(insight: insight),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WalletActionCard extends StatelessWidget {
  const _WalletActionCard({required this.summary});

  final WalletPresentationSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return GlassCard(
      key: const ValueKey<String>('wallet_action_card'),
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.p10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                ),
                child: Icon(
                  Icons.savings_outlined,
                  color: AppColors.gold,
                  size: AppDimens.iconSizeSmall,
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdrawals',
                      style: AppTypography.h6.copyWith(color: colorScheme.text),
                    ),
                    Text(
                      'Live balances now, bank payout workflow next.',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.p10,
                  vertical: AppDimens.p6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.textSecondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppDimens.r30),
                ),
                child: Text(
                  'Coming Soon',
                  style: AppTypography.micro.copyWith(
                    color: colorScheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p18),
          Container(
            padding: const EdgeInsets.all(AppDimens.p16),
            decoration: BoxDecoration(
              color: colorScheme.inputBackground,
              borderRadius: BorderRadius.circular(AppDimens.r16),
              border: Border.all(color: colorScheme.inputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionMetric(
                    label: 'Ready now',
                    value: PriceFormatter.formatPrice(summary.availableFunds),
                    color: AppColors.teal,
                  ),
                ),
                Expanded(
                  child: _ActionMetric(
                    label: 'Pending',
                    value: PriceFormatter.formatPrice(
                      summary.pendingWithdrawalFunds,
                    ),
                    color: AppColors.lightRed,
                  ),
                ),
                Expanded(
                  child: _ActionMetric(
                    label: 'Held',
                    value: PriceFormatter.formatPrice(summary.heldFunds),
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.arrow_outward_rounded),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.textSecondary.withValues(
                  alpha: 0.18,
                ),
                disabledBackgroundColor: colorScheme.textSecondary.withValues(
                  alpha: 0.16,
                ),
                foregroundColor: colorScheme.text,
                disabledForegroundColor: colorScheme.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: AppDimens.p16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.r14),
                ),
              ),
              label: const Text('Request withdrawal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletTimelineCard extends StatelessWidget {
  const _WalletTimelineCard({required this.summary});

  final WalletPresentationSummary summary;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      key: const ValueKey<String>('wallet_timeline_card'),
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent activity',
            style: AppTypography.h5.copyWith(color: context.colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p6),
          Text(
            'Money received, money spent, and release events in one timeline.',
            style: AppTypography.bodySmall.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.p18),
          if (!summary.hasActivity)
            const _WalletEmptyActivityState()
          else
            ...summary.timelineSections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.p18),
                child: _TimelineSection(section: section),
              ),
            ),
        ],
      ),
    );
  }
}

class _WalletEmptyActivityState extends StatelessWidget {
  const _WalletEmptyActivityState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('wallet_empty_state'),
      padding: const EdgeInsets.all(AppDimens.p20),
      decoration: BoxDecoration(
        color: context.colorScheme.inputBackground,
        borderRadius: BorderRadius.circular(AppDimens.r18),
        border: Border.all(color: context.colorScheme.inputBorder),
      ),
      child: Column(
        children: [
          Container(
            width: AppDimens.p48,
            height: AppDimens.p48,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timeline_rounded,
              color: AppColors.teal,
              size: AppDimens.iconSizeMedium,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Text(
            'No wallet activity yet',
            style: AppTypography.h6.copyWith(color: context.colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            'When releases, refunds, or escrow moves happen, they will land here.',
            style: AppTypography.bodyMedium.copyWith(
              color: context.colorScheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.section});

  final WalletTimelineSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: AppTypography.captionBold.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimens.p10),
        ...List.generate(section.entries.length, (index) {
          final entry = section.entries[index];
          final isLast = index == section.entries.length - 1;
          return Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? AppDimens.p0 : AppDimens.p12,
            ),
            child: _TimelineEntry(entry: entry, isLast: isLast),
          );
        }),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.entry, required this.isLast});

  final WalletTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final accent = entry.isReceived ? AppColors.teal : AppColors.lightRed;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppDimens.p24,
          child: Column(
            children: [
              Container(
                width: AppDimens.p12,
                height: AppDimens.p12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: AppDimens.p60,
                  margin: const EdgeInsets.only(top: AppDimens.p4),
                  color: colorScheme.inputBorder,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.p12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppDimens.p16),
            decoration: BoxDecoration(
              color: colorScheme.inputBackground,
              borderRadius: BorderRadius.circular(AppDimens.r16),
              border: Border.all(color: colorScheme.inputBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.label,
                        style: AppTypography.bodyLarge.copyWith(
                          color: colorScheme.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimens.p4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.p8,
                          vertical: AppDimens.p4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppDimens.r30),
                        ),
                        child: Text(
                          entry.eventName,
                          style: AppTypography.micro.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.p8),
                      Text(
                        entry.timestampLabel,
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Text(
                  '${entry.isReceived ? '+' : '-'}${PriceFormatter.formatPrice(entry.displayAmount)}',
                  style: AppTypography.bodyLarge.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _WalletBalanceCompositionBar extends StatelessWidget {
  const _WalletBalanceCompositionBar({required this.slices});

  final List<WalletBalanceSlice> slices;

  @override
  Widget build(BuildContext context) {
    final totalRatio = slices.fold<double>(
      0,
      (runningTotal, slice) => runningTotal + slice.ratio,
    );

    return Container(
      height: AppDimens.p12,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.r30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (totalRatio == 0) {
            return const SizedBox.expand();
          }

          var left = 0.0;
          final bars = <Widget>[];
          for (var index = 0; index < slices.length; index += 1) {
            final slice = slices[index];
            final width = index == slices.length - 1
                ? constraints.maxWidth - left
                : constraints.maxWidth * slice.ratio;
            bars.add(
              AnimatedPositioned(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                left: left,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  width: width.clamp(0.0, constraints.maxWidth).toDouble(),
                  decoration: BoxDecoration(
                    color: _sliceColor(slice.kind),
                    borderRadius: BorderRadius.horizontal(
                      left: index == 0
                          ? const Radius.circular(AppDimens.r30)
                          : Radius.zero,
                      right: index == slices.length - 1
                          ? const Radius.circular(AppDimens.r30)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),
            );
            left += width;
          }

          return Stack(children: bars);
        },
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.slice});

  final WalletBalanceSlice slice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppDimens.p8,
            height: AppDimens.p8,
            decoration: BoxDecoration(
              color: _sliceColor(slice.kind),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimens.p8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slice.label,
                style: AppTypography.micro.copyWith(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                PriceFormatter.formatPrice(slice.amount),
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final WalletInsightStat insight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final accent = _insightColor(insight.kind);
    final icon = _insightIcon(insight.kind);

    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.inputBackground,
        borderRadius: BorderRadius.circular(AppDimens.r18),
        border: Border.all(color: colorScheme.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppDimens.p40,
            height: AppDimens.p40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppDimens.r12),
            ),
            child: Icon(icon, color: accent, size: AppDimens.iconSizeSmall),
          ),
          const SizedBox(height: AppDimens.p12),
          Text(
            insight.label,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.p4),
          Text(
            PriceFormatter.formatPrice(insight.amount),
            style: AppTypography.h6.copyWith(
              color: colorScheme.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppDimens.p4),
          Text(
            insight.caption,
            style: AppTypography.micro.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionMetric extends StatelessWidget {
  const _ActionMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.micro.copyWith(
            color: context.colorScheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimens.p4),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

Color _sliceColor(WalletBalanceSliceKind kind) {
  switch (kind) {
    case WalletBalanceSliceKind.available:
      return Colors.white;
    case WalletBalanceSliceKind.pendingWithdrawal:
      return AppColors.lightRed;
    case WalletBalanceSliceKind.held:
      return AppColors.gold;
  }
}

Color _insightColor(WalletInsightKind kind) {
  switch (kind) {
    case WalletInsightKind.received:
      return AppColors.teal;
    case WalletInsightKind.spent:
      return AppColors.lightRed;
    case WalletInsightKind.fees:
      return AppColors.gold;
  }
}

IconData _insightIcon(WalletInsightKind kind) {
  switch (kind) {
    case WalletInsightKind.received:
      return Icons.south_west_rounded;
    case WalletInsightKind.spent:
      return Icons.north_east_rounded;
    case WalletInsightKind.fees:
      return Icons.auto_awesome_rounded;
  }
}
