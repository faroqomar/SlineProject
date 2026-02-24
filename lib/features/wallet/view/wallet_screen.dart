import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/core/utils/format_date.dart';
import '../viewmodels/wallet_view_model.dart';
import '../models/wallet_activity_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletViewModel>().loadWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.text),
            onPressed: () => context.read<WalletViewModel>().loadWallet(),
          ),
        ],
      ),
      body: Consumer<WalletViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.activities.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.error != null) {
            return Center(
              child: Text(
                vm.error!,
                style: TextStyle(color: AppColors.lightRed),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppDimens.p24),
            children: [
              // Balance Cards
              GlassContainer(
                padding: const EdgeInsets.all(AppDimens.p24),
                child: Column(
                  children: [
                    Text(
                      'Available Balance',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p8),
                    Text(
                      'IQD ${vm.balance.availableBalance.toStringAsFixed(0)}',
                      style: AppTypography.h1.copyWith(color: AppColors.teal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.p12),

              if (vm.balance.pendingWithdrawalBalance > 0)
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimens.p16,
                    horizontal: AppDimens.p24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: AppColors.lightRed,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimens.p8),
                      Text(
                        'Pending Withdrawal: ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                      Text(
                        'IQD ${vm.balance.pendingWithdrawalBalance.toStringAsFixed(0)}',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.lightRed,
                        ),
                      ),
                    ],
                  ),
                ),

              if (vm.balance.heldBalance > 0) ...[
                const SizedBox(height: AppDimens.p12),
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimens.p16,
                    horizontal: AppDimens.p24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_clock, color: AppColors.gold, size: 20),
                      const SizedBox(width: AppDimens.p8),
                      Text(
                        'Pending Escrow: ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                      Text(
                        'IQD ${vm.balance.heldBalance.toStringAsFixed(0)}',
                        style: AppTypography.h3.copyWith(color: AppColors.gold),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppDimens.p16),

              // ── Request Withdrawal (NO Deposit button per Addendum S) ──
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: vm.isWithdrawing
                      ? null
                      : () => _showWithdrawalSheet(context, vm),
                  icon: vm.isWithdrawing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    vm.isWithdrawing ? 'Processing...' : 'Request Withdrawal',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.p16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.r12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.p24),

              Text(
                'Activity',
                style: AppTypography.h5.copyWith(color: colorScheme.text),
              ),
              const SizedBox(height: AppDimens.p12),

              if (vm.activities.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.p24),
                    child: Text(
                      'No wallet activity yet.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...vm.activities.map(
                  (txn) => _buildTransactionItem(context, txn),
                ),

              if (vm.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    WalletActivityModel activity,
  ) {
    bool positive = [
      'deposit',
      'release_with_fee',
      'refund',
      'admin_credit',
    ].contains(activity.eventType);

    // Some events might have a net amount (release_with_fee), others gross
    num displayAmount = activity.eventType == 'release_with_fee'
        ? activity.amountNet
        : activity.amountGross;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: context.colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: context.colorScheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (positive ? AppColors.teal : AppColors.lightRed)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              positive ? Icons.arrow_downward : Icons.arrow_upward,
              color: positive ? AppColors.teal : AppColors.lightRed,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimens.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatType(activity.eventType),
                  style: AppTypography.bodyLarge.copyWith(
                    color: context.colorScheme.text,
                  ),
                ),
                Text(
                  formatUtcToLocal(activity.createdAtUtc),
                  style: AppTypography.caption.copyWith(
                    color: context.colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : '-'}${activity.currency} ${displayAmount.toStringAsFixed(0)}',
            style: AppTypography.bodyLarge.copyWith(
              color: positive ? AppColors.teal : AppColors.lightRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatType(String type) {
    return type
        .split('_')
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ');
  }

  void _showWithdrawalSheet(BuildContext context, WalletViewModel vm) {
    final controller = TextEditingController();
    final colorScheme = context.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimens.p24,
            AppDimens.p24,
            AppDimens.p24,
            MediaQuery.of(sheetCtx).viewInsets.bottom + AppDimens.p24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request Withdrawal',
                style: AppTypography.h3.copyWith(color: colorScheme.text),
              ),
              const SizedBox(height: AppDimens.p8),
              Text(
                'Available: IQD ${vm.balance.availableBalance.toStringAsFixed(0)}',
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimens.p16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colorScheme.text),
                decoration: InputDecoration(
                  labelText: 'Amount (IQD)',
                  labelStyle: TextStyle(color: colorScheme.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                  ),
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: AppDimens.p16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final amount = num.tryParse(controller.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid amount.')),
                      );
                      return;
                    }
                    Navigator.pop(sheetCtx);
                    final success = await vm.requestWithdrawal(amount: amount);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Withdrawal requested. Funds locked.'
                              : vm.error ?? 'Withdrawal failed.',
                        ),
                        backgroundColor: success
                            ? AppColors.teal
                            : AppColors.lightRed,
                      ),
                    );
                    if (success) {
                      vm.loadWallet(); // Refresh activity list
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.p16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.r12),
                    ),
                  ),
                  child: const Text('Submit Withdrawal'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
