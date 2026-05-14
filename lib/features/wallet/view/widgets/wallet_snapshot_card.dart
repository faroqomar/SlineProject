import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';

/// Compact wallet balance snapshot for dashboard overview.
///
/// The snapshot mirrors the dashboard wallet hero shape while keeping the
/// existing wallet ViewModel as the only source of balance data.
class WalletSnapshotCard extends StatelessWidget {
  const WalletSnapshotCard({super.key});

  @override
  Widget build(BuildContext context) {
    final walletVM = context.watch<WalletViewModel>();
    final colorScheme = context.colorScheme;
    const amber = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    const typography = AmberDuskTokens.typography;
    final totalBalance =
        (walletVM.balance.availableBalance + walletVM.balance.heldBalance)
            .toDouble();

    return Container(
      decoration: BoxDecoration(
        color: amber.hero,
        borderRadius: BorderRadius.circular(spacing.heroCardRadius),
        border: Border.all(color: amber.heroRim),
        boxShadow: AppDecorations.elevation(1, isDark: colorScheme.isDark),
      ),
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABLE BALANCE',
            style: typography.chip.copyWith(
              color: amber.heroMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  PriceFormatter.formatPrice(totalBalance),
                  style: typography.moneyMedium.copyWith(color: amber.heroText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: spacing.sm),
              Text(
                'IQD',
                style: typography.bodySmall.copyWith(color: amber.heroMuted),
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Row(
            children: [
              Expanded(
                child: _SnapshotActionPill(
                  label: 'Withdraw soon',
                  foreground: amber.heroMuted,
                  background: amber.heroChip,
                ),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: _SnapshotActionPill(
                  label: 'Top up soon',
                  foreground: amber.heroMuted,
                  background: amber.heroChip,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Row(
            children: [
              _BreakdownChip(
                label: 'Available',
                amount: walletVM.balance.availableBalance.toDouble(),
                color: amber.primary,
              ),
              SizedBox(width: spacing.sm),
              _BreakdownChip(
                label: 'Held',
                amount: walletVM.balance.heldBalance.toDouble(),
                color: amber.star,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Disabled dashboard wallet action matching the Open Design affordance.
///
/// The full withdraw and top-up flows remain owned by the wallet screen; this
/// overview snapshot only mirrors the dashboard reference controls.
class _SnapshotActionPill extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;

  const _SnapshotActionPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = AmberDuskTokens.widgetTheme.buttons;

    return Semantics(
      button: true,
      enabled: false,
      label: label,
      hint: 'Wallet actions are coming soon',
      child: MouseRegion(
        cursor: SystemMouseCursors.forbidden,
        child: Opacity(
          opacity: 0.5,
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
        ),
      ),
    );
  }
}

/// Breakdown chip — colored dot + label + amount in a tinted container.
class _BreakdownChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _BreakdownChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    const typography = AmberDuskTokens.typography;
    // wallet_snapshot_card uses existing spacing tokens instead of deriving
    // former denseSix/compactTen values from arithmetic.
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.sm,
      ),
      decoration: BoxDecoration(
        color: amber.heroChip,
        borderRadius: BorderRadius.circular(spacing.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: spacing.sm,
            height: spacing.sm,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: spacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: typography.chip.copyWith(
                  color: amber.heroMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                PriceFormatter.formatPrice(amount),
                style: typography.chip.copyWith(color: amber.heroText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
