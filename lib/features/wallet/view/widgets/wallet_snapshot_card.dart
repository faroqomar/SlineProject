import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';
import 'package:sline_app/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final availableBalance = walletVM.balance.availableBalance.toDouble();

    return Container(
      decoration: BoxDecoration(
        color: amber.hero,
        borderRadius: BorderRadius.circular(spacing.heroCardRadius),
        border: Border.all(color: amber.heroRim),
        boxShadow: AppDecorations.elevation(1, isDark: colorScheme.isDark),
      ),
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                    SizedBox(height: spacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        PriceFormatter.formatPrice(availableBalance),
                        style: typography.walletAmountCompact.copyWith(
                          color: amber.heroText,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SnapshotStatusPill(
                    label: '${l10n?.withdraw ?? 'Withdraw'} soon',
                  ),
                  SizedBox(height: spacing.xs),
                  _SnapshotStatusPill(label: '${l10n?.topUp ?? 'Top up'} soon'),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Row(
            children: [
              Expanded(
                child: _BreakdownChip(
                  label: 'Available',
                  amount: walletVM.balance.availableBalance.toDouble(),
                  color: amber.primary,
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: _BreakdownChip(
                  label: 'Held',
                  amount: walletVM.balance.heldBalance.toDouble(),
                  color: amber.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Non-interactive dashboard wallet status matching the Open Design affordance.
///
/// The full withdraw and top-up flows remain owned by the wallet screen; this
/// overview snapshot only mirrors the roadmap state without fake buttons.
class _SnapshotStatusPill extends StatelessWidget {
  final String label;

  const _SnapshotStatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    const typography = AmberDuskTokens.typography;

    return Semantics(
      enabled: false,
      label: label,
      hint: 'Wallet actions are coming soon',
      child: Opacity(
        opacity: 0.68,
        child: Container(
          constraints: BoxConstraints(minHeight: spacing.lg + spacing.md),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: amber.heroChip,
            borderRadius: BorderRadius.circular(
              AmberDuskTokens.spacing.pillRadius,
            ),
          ),
          child: Text(
            label,
            style: typography.chip.copyWith(color: amber.heroMuted),
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
        children: [
          Container(
            width: spacing.sm,
            height: spacing.sm,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.chip.copyWith(
                color: amber.heroMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: spacing.xs),
          Flexible(
            child: Text(
              PriceFormatter.formatPrice(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: typography.chip.copyWith(color: amber.heroText),
            ),
          ),
        ],
      ),
    );
  }
}
