import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/widgets/glass_card.dart';
import 'package:sline_app/features/wallet/models/wallet_activity_model.dart';
import 'package:sline_app/features/wallet/utils/transaction_label_helper.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({super.key});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppLogger.d('WalletTab: loading wallet', tag: 'Wallet');
        context.read<WalletViewModel>().loadWallet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.activities.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.p24),
              child: Text(
                vm.error!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.lightRed,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final totalBalance = _clamp(
          (vm.balance.availableBalance + vm.balance.heldBalance).toDouble(),
        );
        final availableBalance = _clamp(vm.balance.availableBalance.toDouble());
        final received = vm.activities.where(isReceivedTransaction).toList();
        final spent = vm.activities
            .where((a) => !isReceivedTransaction(a))
            .toList();

        return RefreshIndicator(
          onRefresh: () => vm.loadWallet(),
          child: ListView(
            padding: const EdgeInsets.all(AppDimens.p16),
            children: [
              _buildTotalBalanceCard(totalBalance),
              const SizedBox(height: AppDimens.p16),
              _buildAvailableCard(availableBalance),
              const SizedBox(height: AppDimens.p16),
              _buildWithdrawComingSoonCard(context),
              const SizedBox(height: AppDimens.p24),
              _SectionHeader(title: 'Transaction history'),
              const SizedBox(height: AppDimens.p12),
              if (vm.activities.isEmpty)
                _buildEmptyState(context)
              else ...[
                if (received.isNotEmpty) ...[
                  _SubSectionHeader(title: 'Money received'),
                  ...received.map(
                    (a) => _buildTransactionRow(context, a, true),
                  ),
                  const SizedBox(height: AppDimens.p16),
                ],
                if (spent.isNotEmpty) ...[
                  _SubSectionHeader(title: 'Money spent'),
                  ...spent.map((a) => _buildTransactionRow(context, a, false)),
                  const SizedBox(height: AppDimens.p16),
                ],
              ],
              const SizedBox(height: AppDimens.p100),
            ],
          ),
        );
      },
    );
  }

  double _clamp(double value) => value.clamp(0.0, double.infinity);

  Widget _buildTotalBalanceCard(double totalBalance) {
    final colorScheme = context.colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total balance',
            style: AppTypography.captionBold.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            'IQD ${totalBalance.toStringAsFixed(0)}',
            style: AppTypography.h1.copyWith(
              color: AppColors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableCard(double availableBalance) {
    final colorScheme = context.colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Available to withdraw',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
          Text(
            'IQD ${availableBalance.toStringAsFixed(0)}',
            style: AppTypography.h3.copyWith(
              color: AppColors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawComingSoonCard(BuildContext context) {
    final colorScheme = context.colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 20,
                color: colorScheme.textSecondary,
              ),
              const SizedBox(width: AppDimens.p8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.p8,
                  vertical: AppDimens.p4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.textSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimens.r8),
                ),
                child: Text(
                  'Coming Soon',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p12),
          Text(
            'Withdraw funds to your bank account',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.textSecondary.withValues(
                  alpha: 0.3,
                ),
                disabledBackgroundColor: colorScheme.textSecondary.withValues(
                  alpha: 0.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: AppDimens.p16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                ),
              ),
              child: Text(
                'Withdraw',
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: colorScheme.textSecondary,
            ),
            const SizedBox(height: AppDimens.p16),
            Text(
              'No transactions yet',
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    WalletActivityModel activity,
    bool isReceived,
  ) {
    final colorScheme = context.colorScheme;
    final displayAmount = activity.eventType == 'release_with_fee'
        ? activity.amountNet
        : activity.amountGross;
    final amount = displayAmount.toDouble().abs();
    final label = getTransactionSourceOrDestination(activity);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isReceived ? AppColors.teal : AppColors.lightRed)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReceived ? Icons.arrow_downward : Icons.arrow_upward,
              color: isReceived ? AppColors.teal : AppColors.lightRed,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimens.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyLarge.copyWith(
                    color: colorScheme.text,
                  ),
                ),
                Text(
                  formatUtcToLocal(activity.createdAtUtc),
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isReceived ? '+' : '-'}${activity.currency} ${amount.toStringAsFixed(0)}',
            style: AppTypography.bodyLarge.copyWith(
              color: isReceived ? AppColors.teal : AppColors.lightRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p12, left: AppDimens.p4),
      child: Text(
        title,
        style: AppTypography.h5.copyWith(color: context.colorScheme.text),
      ),
    );
  }
}

class _SubSectionHeader extends StatelessWidget {
  final String title;

  const _SubSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p8, top: AppDimens.p4),
      child: Text(
        title,
        style: AppTypography.captionBold.copyWith(
          color: context.colorScheme.textSecondary,
        ),
      ),
    );
  }
}
