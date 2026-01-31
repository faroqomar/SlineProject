import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/core/utils/format_date.dart';
import '../viewmodels/wallet_view_model.dart';
import '../models/wallet_transaction_model.dart';

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
          if (vm.isLoading && vm.transactions.isEmpty) {
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
                      '\$${vm.balance.availableBalance.toStringAsFixed(2)}',
                      style: AppTypography.h1.copyWith(color: AppColors.teal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.p12),

              if (vm.balance.heldBalance > 0)
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
                        '\$${vm.balance.heldBalance.toStringAsFixed(2)}',
                        style: AppTypography.h3.copyWith(color: AppColors.gold),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppDimens.p24),

              Text(
                'Transactions',
                style: AppTypography.h5.copyWith(color: colorScheme.text),
              ),
              const SizedBox(height: AppDimens.p12),

              if (vm.transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.p24),
                    child: Text(
                      'No transactions yet.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...vm.transactions.map(
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
    WalletTransactionModel txn,
  ) {
    // In our model, amount is positive, type defines flow.
    // Types: 'deposit', 'escrow_hold', 'escrow_release', 'payment_in', 'refund', 'withdrawal'.
    // Debit: escrow_hold, withdrawal, payment_out (if any).
    // Credit: deposit, escrow_release, refund, payment_in.

    // Let's guess direction based on type for coloring:
    bool positive = [
      'deposit',
      'escrow_release',
      'refund',
      'payment_in',
    ].contains(txn.type);

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
                  _formatType(txn.type),
                  style: AppTypography.bodyLarge.copyWith(
                    color: context.colorScheme.text,
                  ),
                ),
                Text(
                  formatUtcToLocal(txn.createdAtUtc),
                  style: AppTypography.caption.copyWith(
                    color: context.colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : '-'}\$${txn.amount.toStringAsFixed(2)}',
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
}
