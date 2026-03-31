import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/widgets/glass_card.dart';
import '../../viewmodels/dashboard_view_model.dart';

class DashboardCountersGrid extends StatelessWidget {
  const DashboardCountersGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final isFreelancer = vm.currentRole == UserRole.freelancer;
    final counters = vm.counters;

    // Map counters to UI cards
    final List<_CounterData> items = isFreelancer
        ? [
            _CounterData(
              'Pending Requests',
              counters.pendingRequests.toString(),
              AppColors.gold,
              Icons.pending_actions,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
            _CounterData(
              'Active Work',
              counters.activeWork.toString(),
              AppColors.teal,
              Icons.work,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
            _CounterData(
              'Messages',
              counters.newMessages.toString(),
              AppColors.lightTeal,
              Icons.chat,
              () => vm.setTab(DashboardTab.inbox.index),
            ),
            _CounterData(
              'New Offers',
              counters.newOffers.toString(),
              AppColors.mediumGrey,
              Icons.local_offer,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
          ]
        : [
            _CounterData(
              'Active Work',
              counters.activeWork.toString(),
              AppColors.teal,
              Icons.work_outline,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
            _CounterData(
              'Needs Review',
              counters.needsReview.toString(),
              AppColors.lightRed,
              Icons.rate_review_outlined,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
            _CounterData(
              'Pending Payment',
              counters.pendingPayment.toString(),
              AppColors.gold,
              Icons.payment_outlined,
              () => vm.setTab(DashboardTab.bookings.index),
            ),
            _CounterData(
              'Completed',
              counters.completed.toString(),
              AppColors.lightTeal,
              Icons.check_circle_outline,
              () => vm.setTab(DashboardTab.activeWork.index, workSubTab: 1),
            ),
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
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _CounterCard(data: items[index]);
      },
    );
  }
}

class _CounterData {
  final String label;
  final String count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  _CounterData(this.label, this.count, this.color, this.icon, this.onTap);
}

class _CounterCard extends StatelessWidget {
  final _CounterData data;

  const _CounterCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return GlassCard(
      onTap: data.onTap,
      padding: const EdgeInsets.all(AppDimens.p16),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
