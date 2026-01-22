import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/dashboard/models/dashboard_enums.dart';
import '../../viewmodels/dashboard_view_model.dart';

class DashboardCountersGrid extends StatelessWidget {
  const DashboardCountersGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final isFreelancer = vm.currentRole == UserRole.freelancer;

    // TODO: Connect to VM real data (mock)
    // For now hardcoding mock values for UI Prototype until VM is fully wired

    final counters = isFreelancer
        ? [
            _CounterData("Pending", "3", AppColors.gold, Icons.pending_actions),
            _CounterData(
              "Active Work",
              "2",
              AppColors.teal,
              Icons.work,
            ), // Using teal
            _CounterData(
              "Messages",
              "5",
              AppColors.lightTeal,
              Icons.chat,
            ), // Using lightTeal
            _CounterData(
              "Offers",
              "0",
              AppColors.mediumGrey,
              Icons.local_offer,
            ),
          ]
        : [
            _CounterData("Active", "1", AppColors.teal, Icons.calendar_today),
            _CounterData("Open Tasks", "2", AppColors.gold, Icons.list_alt),
            _CounterData(
              "New Offers",
              "4",
              AppColors.lightRed,
              Icons.notifications_active,
            ), // Using lightRed
            _CounterData("Messages", "1", AppColors.lightTeal, Icons.chat),
          ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDimens.p12,
        mainAxisSpacing: AppDimens.p12,
        childAspectRatio: 1.5,
      ),
      itemCount: counters.length,
      itemBuilder: (context, index) {
        return _CounterCard(data: counters[index]);
      },
    );
  }
}

class _CounterData {
  final String label;
  final String count;
  final Color color;
  final IconData icon;

  _CounterData(this.label, this.count, this.color, this.icon);
}

class _CounterCard extends StatelessWidget {
  final _CounterData data;

  const _CounterCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, color: data.color, size: 24),
              Text(
                data.count,
                style: AppTypography.h3.copyWith(
                  color: data.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            data.label,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
