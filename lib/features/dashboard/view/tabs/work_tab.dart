import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/dashboard/view/widgets/work_item_card.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';

class WorkTab extends StatelessWidget {
  const WorkTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final active = vm.activeWork;
    final completed = vm.completedWork;
    final cancelled = vm.cancelledWork;
    final colorScheme = context.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Header & Tab Bar
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.p16,
              AppDimens.p16,
              AppDimens.p16,
              0,
            ),
            color: Colors.transparent, // Or background color if needed
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "My Work",
                  style: AppTypography.h3.copyWith(color: colorScheme.text),
                ),
                const SizedBox(height: AppDimens.p8),
                Text(
                  "Track all your jobs and bookings.",
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.p16),

                // Nested Tab Bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.inputBackground,
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(AppDimens.r10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: colorScheme.textSecondary,
                    labelStyle: AppTypography.captionBold,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: "Active (${active.length})"),
                      Tab(text: "Done (${completed.length})"),
                      Tab(text: "Cancelled"),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.p16),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              children: [
                // 1. Active Tab
                _buildWorkList(
                  context: context,
                  items: active,
                  emptyMessage: "No active work.",
                  isDimmed: false,
                ),

                // 2. Completed Tab
                _buildWorkList(
                  context: context,
                  items: completed,
                  emptyMessage: "No completed work yet.",
                  isDimmed: true,
                ),

                // 3. Cancelled Tab
                _buildWorkList(
                  context: context,
                  items: cancelled,
                  emptyMessage: "No cancelled work.",
                  isDimmed: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkList({
    required BuildContext context,
    required List<WorkItem> items,
    required String emptyMessage,
    bool isDimmed = false,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 48,
              color: context.colorScheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimens.p16),
            Text(
              emptyMessage,
              style: AppTypography.bodyMedium.copyWith(
                color: context.colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final vm = context.read<DashboardViewModel>();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p16,
        0,
        AppDimens.p16,
        AppDimens.p100,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.p12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Opacity(
          opacity: isDimmed ? 0.7 : 1.0,
          child: WorkItemCard(
            item: item,
            onPrimaryAction: () => vm.performPrimaryAction(item),
          ),
        );
      },
    );
  }
}
