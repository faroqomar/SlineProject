import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
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
        padding: EdgeInsets.all(spacing.lg),
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
            LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      PriceFormatter.formatPrice(summary.totalFunds),
                      style: typography.walletAmount.copyWith(
                        color: amber.heroText,
                      ),
                      maxLines: 1,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: spacing.lg),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                _HeroStatusPill(
                  label: '${l10n?.withdraw ?? 'Withdraw'} soon',
                  foreground: amber.heroMuted,
                  background: amber.heroChip,
                ),
                _HeroStatusPill(
                  label: '${l10n?.topUp ?? 'Top up'} soon',
                  foreground: amber.heroMuted,
                  background: amber.heroChip,
                ),
              ],
            ),
            SizedBox(height: spacing.lg),
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

/// Non-interactive hero status pill for wallet actions that are not wired yet.
///
/// Payment and withdrawal flows stay owned by their existing screens/services;
/// the hero shows their roadmap state without presenting a tappable control.
class _HeroStatusPill extends StatelessWidget {
  const _HeroStatusPill({
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
      enabled: false,
      label: label,
      hint: 'Wallet actions are coming soon',
      child: Container(
        constraints: const BoxConstraints(minHeight: AppDimens.p40),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p14,
          vertical: AppDimens.p8,
        ),
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
