import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';

/// Compact wallet balance snapshot for dashboard overview.
class WalletSnapshotCard extends StatelessWidget {
  const WalletSnapshotCard({super.key});

  @override
  Widget build(BuildContext context) {
    final walletVM = context.watch<WalletViewModel>();
    final colorScheme = context.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Balance',
                style: AppTypography.captionBold.copyWith(
                  color: colorScheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimens.p4),
              Text(
                PriceFormatter.formatPrice(
                  (walletVM.balance.availableBalance +
                          walletVM.balance.heldBalance)
                      .toDouble(),
                ),
                style: AppTypography.h2.copyWith(color: colorScheme.text),
              ),
            ],
          ),
          Row(
            children: [
              _BalanceItem(
                label: 'Available',
                amount: walletVM.balance.availableBalance.toDouble(),
                color: AppColors.teal,
              ),
              const SizedBox(width: AppDimens.p16),
              _BalanceItem(
                label: 'Held',
                amount: walletVM.balance.heldBalance.toDouble(),
                color: AppColors.gold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _BalanceItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
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
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
