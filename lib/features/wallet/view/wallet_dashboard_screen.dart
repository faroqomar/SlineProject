import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

/// Wallet dashboard screen with glass credit card design matching the new design system.
class WalletDashboardScreen extends StatelessWidget {
  const WalletDashboardScreen({super.key});

  // Mock wallet data
  static const _walletData = {
    'totalBalance': '12,540.00',
    'availableBalance': '11,690.00',
    'escrowBalance': '850.00',
    'cardLast4': '4242',
  };

  static const List<Map<String, dynamic>> _transactions = [
    {
      'id': 1,
      'type': 'payment',
      'description': 'Payment Released: Brand Identity',
      'amount': '1,200.00',
      'date': 'Today, 2:30 PM',
      'status': 'completed',
      'isPositive': true,
    },
    {
      'id': 2,
      'type': 'fee',
      'description': 'Service Fee (5%)',
      'amount': '60.00',
      'date': 'Today, 2:30 PM',
      'status': 'completed',
      'isPositive': false,
    },
    {
      'id': 3,
      'type': 'withdrawal',
      'description': 'Withdrawal to Bank Account',
      'amount': '2,500.00',
      'date': 'Yesterday',
      'status': 'completed',
      'isPositive': false,
    },
    {
      'id': 4,
      'type': 'escrow',
      'description': 'Escrow Deposit: UI Audit',
      'amount': '350.00',
      'date': 'Nov 12, 2023',
      'status': 'pending',
      'isPositive': true,
    },
    {
      'id': 5,
      'type': 'payment',
      'description': 'Payment Released: Blog Series',
      'amount': '250.00',
      'date': 'Nov 10, 2023',
      'status': 'completed',
      'isPositive': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDimens.p24,
          topPadding + AppDimens.p24,
          AppDimens.p24,
          AppDimens.p100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Wallet',
                      style: AppTypography.h2.copyWith(color: colorScheme.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your earnings',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimens.p24),

            // --- Glass Credit Card ---
            _GlassCreditCard(data: _walletData),
            const SizedBox(height: AppDimens.p24),

            // --- Action Buttons ---
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Withdraw',
                    icon: Icons.arrow_outward,
                    isPrimary: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Expanded(
                  child: _ActionButton(
                    label: 'Top Up',
                    icon: Icons.add,
                    isPrimary: false,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.p32),

            // --- Recent Transactions ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: AppTypography.h5.copyWith(color: colorScheme.text),
                ),
                Text(
                  'View All',
                  style: AppTypography.captionBold.copyWith(color: AppColors.teal),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.p16),

            // Transaction list
            ..._transactions.map(
              (tx) => _TransactionItem(transaction: tx),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass credit card widget matching the new design.
class _GlassCreditCard extends StatelessWidget {
  final Map<String, String> data;

  const _GlassCreditCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.r24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.teal,
            const Color(0xFF0c3b40), // Darker teal
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.2),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppDimens.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${data['totalBalance']}',
                          style: AppTypography.h1.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ],
                ),

                // Bottom row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balances
                    Row(
                      children: [
                        _buildBalanceItem('Available', '\$${data['availableBalance']}', Colors.white),
                        const SizedBox(width: AppDimens.p32),
                        _buildBalanceItem('In Escrow', '\$${data['escrowBalance']}', AppColors.gold),
                      ],
                    ),
                    const SizedBox(height: AppDimens.p16),

                    // Card number and brand
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '**** **** **** ${data['cardLast4']}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        // Card brand circles
                        SizedBox(
                          width: 32,
                          height: 20,
                          child: Stack(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withValues(alpha: 0.8),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.yellow.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.micro.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Action button widget for Withdraw/Top Up.
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.gold : colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r16),
          border: isPrimary ? null : Border.all(color: colorScheme.cardBorder),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? Colors.black : colorScheme.text,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isPrimary ? Colors.black : colorScheme.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Transaction item widget.
class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final bool isPositive = transaction['isPositive'] as bool;
    final String status = transaction['status'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPositive
                  ? AppColors.teal.withValues(alpha: 0.2)
                  : AppColors.lightRed.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isPositive
                    ? AppColors.teal.withValues(alpha: 0.3)
                    : AppColors.lightRed.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? AppColors.teal : AppColors.lightRed,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimens.p12),

          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'] as String,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.text,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  transaction['date'] as String,
                  style: AppTypography.micro.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}\$${transaction['amount']}',
                style: AppTypography.bodySmall.copyWith(
                  color: isPositive ? AppColors.teal : AppColors.lightRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status.toUpperCase(),
                style: AppTypography.micro.copyWith(
                  color: status == 'completed' ? AppColors.lightTeal : AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
