import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/features/wallet/utils/wallet_presentation_helper.dart';
import 'package:sline_app/features/wallet/view/widgets/wallet_hero_card.dart';
import 'package:sline_app/features/wallet/view/widgets/wallet_timeline_card.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';

/// Wallet tab body — renders hero card, insights, withdrawals, and timeline.
///
/// The shared body is used by both the dashboard wallet tab and full wallet
/// screen, while wallet loading and ledger data remain owned by WalletViewModel.
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
            WalletHeroCard(summary: summary),
            // Increased spacing for premium breathing room
            const SizedBox(height: AppDimens.p24),
            _WalletInsightsCard(summary: summary),
            const SizedBox(height: AppDimens.p16),
            _WalletActionCard(summary: summary),
            const SizedBox(height: AppDimens.p24),
            WalletTimelineCard(summary: summary),
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

// ─────────────────────────────────────────────────────────────────────────────
// Loading + Error states
// ─────────────────────────────────────────────────────────────────────────────

class _WalletLoadingCard extends StatelessWidget {
  const _WalletLoadingCard();

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    return AppCard(
      key: const ValueKey<String>('wallet_shared_loading'),
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Column(
        children: [
          const SizedBox(height: AppDimens.p8),
          const CircularProgressIndicator(),
          const SizedBox(height: AppDimens.p20),
          Text(
            'Loading wallet',
            style: AppTypography.h5.copyWith(color: amber.text),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            'Pulling in your live balance and recent ledger activity.',
            style: AppTypography.bodyMedium.copyWith(color: amber.textSubtle),
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
    const amber = AmberDuskTokens.colors;
    return AppCard(
      key: const ValueKey<String>('wallet_shared_error'),
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppDimens.p48,
            height: AppDimens.p48,
            decoration: BoxDecoration(
              color: amber.dangerMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_tethering_error_rounded,
              color: amber.danger,
              size: AppDimens.iconSizeMedium,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Text(
            'Wallet unavailable',
            style: AppTypography.h5.copyWith(color: amber.text),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: amber.textSubtle),
          ),
          const SizedBox(height: AppDimens.p20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              style: FilledButton.styleFrom(
                backgroundColor: amber.primary,
                foregroundColor: amber.text,
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

// ─────────────────────────────────────────────────────────────────────────────
// Insights — dashboard wallet flow stats
// ─────────────────────────────────────────────────────────────────────────────

/// Wallet flow stats with individual Amber Dusk metric tiles.
class _WalletInsightsCard extends StatelessWidget {
  const _WalletInsightsCard({required this.summary});

  final WalletPresentationSummary summary;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    return Column(
      key: const ValueKey<String>('wallet_insights_card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent wallet flow',
          style: AppTypography.h5.copyWith(color: amber.text),
        ),
        const SizedBox(height: AppDimens.p4),
        Text(
          summary.activityCaption,
          style: AppTypography.bodySmall.copyWith(color: amber.textSubtle),
        ),
        const SizedBox(height: AppDimens.p16),

        // ── Insight tiles — each in its own tinted container ──
        // Vertical stack on mobile, responsive wrap on wider screens
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
    );
  }
}

/// Individual insight tile — colored left accent bar + icon + amount.
/// Warm tinted background from the insight color for visual identity.
class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final WalletInsightStat insight;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    final accentColor = _insightColor(insight.kind, amber);
    final icon = _insightIcon(insight.kind);

    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: amber.surface,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: AmberDuskColors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored left accent bar — visual identity for each metric
          Container(
            width: 3,
            height: AppDimens.p48,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(AppDimens.r4),
            ),
          ),
          const SizedBox(width: AppDimens.p14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + label row
                Row(
                  children: [
                    Icon(icon, size: 14, color: accentColor),
                    const SizedBox(width: AppDimens.p6),
                    Text(
                      insight.label,
                      style: AppTypography.captionBold.copyWith(
                        color: amber.textSubtle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.p8),
                // Hero amount — large, colored
                Text(
                  PriceFormatter.formatPrice(insight.amount),
                  style: AppTypography.h4.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppDimens.p2),
                Text(
                  insight.caption,
                  style: AppTypography.micro.copyWith(color: amber.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action card — coming-soon withdrawal preview
// ─────────────────────────────────────────────────────────────────────────────

/// Withdrawals feature preview that keeps the existing coming-soon boundary.
class _WalletActionCard extends StatelessWidget {
  const _WalletActionCard({required this.summary});

  final WalletPresentationSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    const amber = AmberDuskTokens.colors;

    return Container(
      key: const ValueKey<String>('wallet_action_card'),
      decoration: BoxDecoration(
        color: amber.surface,
        borderRadius: BorderRadius.circular(AppDimens.r20),
        border: Border.all(color: AmberDuskColors.transparent),
        boxShadow: AppDecorations.elevation(1, isDark: colorScheme.isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.r20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              constraints: const BoxConstraints(minHeight: 180),
              color: amber.primary,
            ),

            // ── Content ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.p20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Withdrawals',
                          style: AppTypography.h5.copyWith(color: amber.text),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.p8,
                            vertical: AppDimens.p4,
                          ),
                          decoration: BoxDecoration(
                            color: amber.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppDimens.r4),
                            border: Border.all(
                              color: amber.primary.withValues(alpha: 0.24),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: AppTypography.micro.copyWith(
                              color: amber.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.p4),
                    Text(
                      'Withdrawals are paused until payout verification is enabled.',
                      style: AppTypography.bodySmall.copyWith(
                        color: amber.textSubtle,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p8),
                    Text(
                      'Your available and held balances remain visible here.',
                      style: AppTypography.micro.copyWith(color: amber.muted),
                    ),

                    const SizedBox(height: AppDimens.p20),

                    // ── Dot-indicator metrics (no inner container) ──
                    Row(
                      children: [
                        _WithdrawalMetric(
                          label: 'READY',
                          value: PriceFormatter.formatPrice(
                            summary.availableFunds,
                          ),
                          dotColor: amber.primary,
                        ),
                        const SizedBox(width: AppDimens.p24),
                        _WithdrawalMetric(
                          label: 'PENDING',
                          value: PriceFormatter.formatPrice(
                            summary.pendingWithdrawalFunds,
                          ),
                          dotColor: amber.danger,
                        ),
                        const SizedBox(width: AppDimens.p24),
                        _WithdrawalMetric(
                          label: 'HELD',
                          value: PriceFormatter.formatPrice(summary.heldFunds),
                          dotColor: amber.star,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimens.p20),

                    // ── Disabled CTA with subtle border ──
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: null,
                        style: FilledButton.styleFrom(
                          disabledBackgroundColor: amber.surfaceRaised,
                          disabledForegroundColor: amber.muted,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimens.p14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.r12),
                            side: BorderSide(
                              color: amber.heroDivider,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          'Withdrawal unavailable',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dot-indicator metric for the withdrawal section.
class _WithdrawalMetric extends StatelessWidget {
  const _WithdrawalMetric({
    required this.label,
    required this.value,
    required this.dotColor,
  });

  final String label;
  final String value;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimens.p6),
            Text(
              label,
              style: AppTypography.micro.copyWith(
                color: amber.textSubtle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p4),
        Text(
          value,
          style: AppTypography.bodyLarge.copyWith(
            color: amber.text,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Icon for each insight kind — small, understated visual cue.
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

/// Semantic insight color for light/dark mode consistency.
Color _insightColor(WalletInsightKind kind, AmberDuskColorTokens colors) {
  switch (kind) {
    case WalletInsightKind.received:
      return colors.primary;
    case WalletInsightKind.spent:
      return colors.danger;
    case WalletInsightKind.fees:
      return colors.star;
  }
}
