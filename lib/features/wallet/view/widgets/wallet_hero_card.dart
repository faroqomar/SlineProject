import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/wallet/utils/wallet_presentation_helper.dart';
import 'package:sline_app/l10n/app_localizations.dart';

/// Wallet hero card for high-emphasis balance presentation.
///
/// The card uses the staged Amber Dusk hero colors directly because this phase
/// does not flip the global app theme to Amber Dusk.
class WalletHeroCard extends StatelessWidget {
  const WalletHeroCard({super.key, required this.summary});

  final WalletPresentationSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    const amber = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    const typography = AmberDuskTokens.typography;
    final l10n = AppLocalizations.of(context);

    return Container(
      key: const ValueKey<String>('wallet_hero_card'),
      decoration: BoxDecoration(
        color: amber.hero,
        borderRadius: BorderRadius.circular(spacing.heroCardRadius),
        border: Border.all(color: amber.heroRim),
        boxShadow: AppDecorations.elevation(2, isDark: colorScheme.isDark),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.availableBalance ?? 'AVAILABLE BALANCE',
              style: typography.chip.copyWith(
                color: amber.heroMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimens.p6),
            Text(
              PriceFormatter.formatPrice(summary.totalFunds),
              style: typography.moneyLarge.copyWith(color: amber.heroText),
            ),
            const SizedBox(height: AppDimens.p6),
            Text(
              summary.activityCaption,
              style: typography.bodySmall.copyWith(color: amber.heroMuted),
            ),
            SizedBox(height: spacing.xl),
            Row(
              children: [
                Expanded(
                  child: _HeroActionPill(
                    label: '${l10n?.withdraw ?? 'Withdraw'} soon',
                    foreground: amber.heroMuted,
                    background: amber.heroChip,
                  ),
                ),
                SizedBox(width: spacing.md),
                Expanded(
                  child: _HeroActionPill(
                    label: '${l10n?.topUp ?? 'Top up'} soon',
                    foreground: amber.heroMuted,
                    background: amber.heroChip,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.lg),
            _CompositionBar(slices: summary.balanceSlices),
            SizedBox(height: spacing.md),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: summary.balanceSlices
                  .map(
                    (slice) => _BalanceChip(
                      slice: slice,
                      color: _sliceColor(slice.kind, amber),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Disabled hero-style action pill for commands not wired from this widget.
///
/// Payment and withdrawal flows stay owned by their existing screens/services;
/// the hero mirrors the Open Design affordance without changing behavior.
class _HeroActionPill extends StatelessWidget {
  const _HeroActionPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final buttons = AmberDuskTokens.widgetTheme.buttons;

    return Semantics(
      button: true,
      enabled: false,
      hint: 'Wallet actions are coming soon',
      child: Container(
        height: buttons.minHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(buttons.radius),
        ),
        child: Text(
          label,
          style: buttons.textStyle.copyWith(color: foreground),
        ),
      ),
    );
  }
}

/// Animated composition bar — 6px height with smooth segment transitions.
/// Uses AppMotion tokens for animation duration and curves.
class _CompositionBar extends StatelessWidget {
  const _CompositionBar({required this.slices});

  final List<WalletBalanceSlice> slices;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    final totalRatio = slices.fold<double>(
      0,
      (sum, slice) => sum + slice.ratio,
    );

    return Container(
      height: AppDimens.p6,
      decoration: BoxDecoration(
        color: amber.heroDivider,
        borderRadius: BorderRadius.circular(AppDimens.r4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (totalRatio == 0) return const SizedBox.expand();

          var left = 0.0;
          final bars = <Widget>[];
          for (var i = 0; i < slices.length; i++) {
            final slice = slices[i];
            final width = i == slices.length - 1
                ? constraints.maxWidth - left
                : constraints.maxWidth * slice.ratio;
            bars.add(
              AnimatedPositioned(
                duration: AppMotion.slow,
                curve: AppMotion.curveStandard,
                left: left,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: AppMotion.slow,
                  width: width.clamp(0.0, constraints.maxWidth),
                  decoration: BoxDecoration(
                    color: _sliceColor(slice.kind, amber),
                    borderRadius: BorderRadius.horizontal(
                      left: i == 0
                          ? const Radius.circular(AppDimens.r4)
                          : Radius.zero,
                      right: i == slices.length - 1
                          ? const Radius.circular(AppDimens.r4)
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

/// Balance chip — colored dot + label + amount in a subtle container.
///
/// Warm design: uses a tinted background matching the dot color at low alpha
/// so each chip has visual identity without being noisy. Generous padding
/// for touch comfort and scannability.
class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.slice, required this.color});

  final WalletBalanceSlice slice;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p8,
      ),
      decoration: BoxDecoration(
        color: amber.heroChip,
        borderRadius: BorderRadius.circular(AppDimens.r12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Colored dot matching the composition bar
          Container(
            width: AppDimens.p8,
            height: AppDimens.p8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppDimens.p8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slice.label,
                style: typography.chip.copyWith(
                  color: amber.heroMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                PriceFormatter.formatPrice(slice.amount),
                style: typography.chip.copyWith(color: amber.heroText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Semantic slice colors — primary (available), danger (pending), accent (held).
Color _sliceColor(WalletBalanceSliceKind kind, AmberDuskColorTokens colors) {
  switch (kind) {
    case WalletBalanceSliceKind.available:
      return colors.primary;
    case WalletBalanceSliceKind.pendingWithdrawal:
      return colors.danger;
    case WalletBalanceSliceKind.held:
      return colors.star;
  }
}
