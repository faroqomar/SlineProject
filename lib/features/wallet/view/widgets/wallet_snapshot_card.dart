import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';

/// Compact wallet balance snapshot for dashboard overview.
///
/// Matches the WalletHeroCard brand identity: warm teal-tinted surface
/// (headerBackground), left-aligned hero number, colored breakdown chips.
/// Compact version — no composition bar, just balance + breakdown.
class WalletSnapshotCard extends StatelessWidget {
  const WalletSnapshotCard({super.key});

  @override
  Widget build(BuildContext context) {
    final walletVM = context.watch<WalletViewModel>();
    final colorScheme = context.colorScheme;
    final totalBalance =
        (walletVM.balance.availableBalance + walletVM.balance.heldBalance)
            .toDouble();

    return Container(
      decoration: BoxDecoration(
        // Warm teal-tinted surface matching the full wallet hero card
        color: colorScheme.headerBackground,
        borderRadius: BorderRadius.circular(AppDimens.r20),
        border: Border.all(color: colorScheme.headerBorder),
        boxShadow: AppDecorations.elevation(1, isDark: colorScheme.isDark),
      ),
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet icon + label — small, understated
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: AppDimens.iconSizeSmall,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppDimens.p6),
              Text(
                'Wallet',
                style: AppTypography.captionBold.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p12),

          // Hero balance number
          Text(
            PriceFormatter.formatPrice(totalBalance),
            style: AppTypography.h2.copyWith(
              color: colorScheme.text,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppDimens.p16),

          // Balance breakdown chips
          Row(
            children: [
              _BreakdownChip(
                label: 'Available',
                amount: walletVM.balance.availableBalance.toDouble(),
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppDimens.p10),
              _BreakdownChip(
                label: 'Held',
                amount: walletVM.balance.heldBalance.toDouble(),
                color: colorScheme.accent,
              ),
            ],
          ),
        ],
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
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p10,
        vertical: AppDimens.p6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.r10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppDimens.p6,
            height: AppDimens.p6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppDimens.p6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.micro.copyWith(
                  color: colorScheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                PriceFormatter.formatPrice(amount),
                style: AppTypography.captionBold.copyWith(
                  color: colorScheme.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
