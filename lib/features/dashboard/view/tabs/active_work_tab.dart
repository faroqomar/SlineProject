import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/dashboard/view/widgets/work_item_card.dart';
import 'package:sline_app/core/widgets/glass_container.dart';

class ActiveWorkTab extends StatelessWidget {
  const ActiveWorkTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final upNext = vm.activeUpNext;
    final inProgress = vm.activeInProgress;
    final inReview = vm.activeInReview;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppDimens.p16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                "Active Work",
                style: AppTypography.h3.copyWith(
                  color: context.colorScheme.text,
                ),
              ),
              const SizedBox(height: AppDimens.p8),
              Text(
                "Manage your tasks and bookings in one place.",
                style: AppTypography.bodyMedium.copyWith(
                  color: context.colorScheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimens.p24),
            ]),
          ),
        ),

        // UP NEXT SECTION
        if (upNext.isNotEmpty) ...[
          _buildStickyHeader(
            context,
            "Up Next (${upNext.length})",
            Icons.calendar_today_outlined,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return WorkItemCard(
                  item: upNext[index],
                  onPrimaryAction: () {
                    vm.performPrimaryAction(upNext[index]);
                  },
                );
              }, childCount: upNext.length),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: AppDimens.p16)),
        ],

        // IN PROGRESS SECTION
        if (inProgress.isNotEmpty) ...[
          _buildStickyHeader(
            context,
            "In Progress (${inProgress.length})",
            Icons.pending_actions_outlined,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return WorkItemCard(
                  item: inProgress[index],
                  // Prominent card maybe? WorkItemCard handles it.
                );
              }, childCount: inProgress.length),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: AppDimens.p16)),
        ],

        // IN REVIEW / DONE SECTION
        if (inReview.isNotEmpty) ...[
          _buildStickyHeader(
            context,
            "In Review / Done (${inReview.length})",
            Icons.check_circle_outline,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Opacity(
                  opacity: 0.7, // Visual cue for "Done"
                  child: WorkItemCard(item: inReview[index]),
                );
              }, childCount: inReview.length),
            ),
          ),
        ],

        // Empty State
        if (upNext.isEmpty && inProgress.isEmpty && inReview.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_off_outlined,
                    size: 64,
                    color: context.colorScheme.textSecondary,
                  ),
                  const SizedBox(height: AppDimens.p16),
                  Text(
                    "No active items found.",
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Bottom Padding for Nav Bar
        SliverToBoxAdapter(child: const SizedBox(height: AppDimens.p80)),
      ],
    );
  }

  Widget _buildStickyHeader(BuildContext context, String title, IconData icon) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(
        child: GlassContainer(
          borderRadius: BorderRadius.circular(0), // Full width glass
          // Make it look like a section header
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p16,
              vertical: AppDimens.p12,
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.background.withValues(alpha: 0.8),
              border: Border(
                bottom: BorderSide(color: context.colorScheme.cardBorder),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: context.colorScheme.primary),
                const SizedBox(width: AppDimens.p12),
                Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    color: context.colorScheme.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        minHeight: 50,
        maxHeight: 50,
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _StickyHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxExtent ||
        minHeight != oldDelegate.minExtent ||
        child != oldDelegate.child;
  }
}
