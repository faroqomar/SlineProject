import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart'; // Added
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';

class WalletDashboardScreen extends StatelessWidget {
  const WalletDashboardScreen({super.key});

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
                      style: AppTypography.h3.copyWith(color: colorScheme.text),
                    ),
                    Text(
                      'Manage your earnings',
                      style: AppTypography.bodySmall.copyWith(color: colorScheme.textSecondary),
                    ),
                  ],
                ),
                GlassContainer(
                  borderRadius: BorderRadius.circular(AppDimens.r14),
                  padding: const EdgeInsets.all(AppDimens.p10),
                  child: Icon(Icons.credit_card, color: AppColors.teal, size: AppDimens.p24),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.p24),

            // --- Glass Credit Card ---
            // // TODO: Connect to Backend
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(AppDimens.p24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.r24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.teal,
                    Color.lerp(AppColors.teal, Colors.black, 0.3)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance',
                            style: AppTypography.caption.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$12,540.00',
                            style: AppTypography.h1.copyWith(color: Colors.white, fontSize: 32),
                          ),
                        ],
                      ),
                      const Icon(Icons.account_balance_wallet, color: Colors.white54),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildBalanceItem('Available', '\$11,690.00', Colors.white),
                          const SizedBox(width: AppDimens.p24),
                          _buildBalanceItem('In Escrow', '\$850.00', AppColors.gold),
                        ],
                      ),
                      // Card Brand Circles
                      SizedBox(
                        width: 30,
                        height: 20,
                        child: Stack(
                          children: [
                            Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.8), shape: BoxShape.circle)),
                            Positioned(right: 0, child: Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.8), shape: BoxShape.circle))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.p24),

            // --- Actions ---
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: 'Withdraw',
                    icon: Icons.arrow_outward,
                    bgColor: AppColors.gold,
                    textColor: Colors.black,
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: 'Top Up',
                    icon: Icons.add,
                    bgColor: colorScheme.cardBackground,
                    textColor: colorScheme.text,
                    isGlass: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.p32),

            // --- Recent Transactions ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions', style: AppTypography.h5.copyWith(color: colorScheme.text)),
                Text('View All', style: AppTypography.captionBold.copyWith(color: AppColors.teal)),
              ],
            ),
            const SizedBox(height: AppDimens.p16),
            
            // Mock List
            _buildTransactionItem(context, 'Payment Released: Brand Identity', 'Today, 2:30 PM', '+\$1,200.00', true, 'completed'),
            _buildTransactionItem(context, 'Service Fee (5%)', 'Today, 2:30 PM', '-\$60.00', false, 'completed'),
            _buildTransactionItem(context, 'Withdrawal to Bank', 'Yesterday', '-\$2,500.00', false, 'pending'),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.micro.copyWith(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
        Text(amount, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, {required String label, required IconData icon, required Color bgColor, required Color textColor, bool isGlass = false}) {
    final decoration = isGlass
        ? AppDecorations.glassBoxDecoration(colorScheme: context.colorScheme, borderRadius: BorderRadius.circular(AppDimens.r16))
        : BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppDimens.r16),
            boxShadow: [BoxShadow(color: bgColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
          );

    return Container(
      height: 50,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppDimens.r16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.bodySmall.copyWith(color: textColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, String title, String date, String amount, bool isPositive, String status) {
    final colorScheme = context.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: AppDecorations.glassBoxDecoration(colorScheme: colorScheme, borderRadius: BorderRadius.circular(AppDimens.r16)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPositive ? AppColors.teal.withValues(alpha: 0.1) : AppColors.lightRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: isPositive ? AppColors.teal.withValues(alpha: 0.2) : AppColors.lightRed.withValues(alpha: 0.2)),
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? AppColors.teal : AppColors.lightRed,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodySmall.copyWith(color: colorScheme.text, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(date, style: AppTypography.micro.copyWith(color: colorScheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: AppTypography.bodyMedium.copyWith(color: isPositive ? AppColors.teal : AppColors.lightRed, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(status.toUpperCase(), style: AppTypography.micro.copyWith(color: status == 'completed' ? AppColors.lightTeal : AppColors.gold, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
