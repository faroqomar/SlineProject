import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';

class DashboardCountersGrid extends StatelessWidget {
  const DashboardCountersGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final isFreelancer = vm.currentRole == UserRole.freelancer;
    final counters = vm.counters;
    final isLoading = vm.isLoading;

    AppLogger.d('DashboardCountersGrid loaded', tag: 'Cards');

    // Map counters to UI cards
    final items = isFreelancer
        ? [
            _CounterData(
              'Pending Requests',
              counters.pendingRequests,
              AppColors.gold,
              Icons.pending_actions,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
            _CounterData(
              'Active Work',
              counters.activeWork,
              AppColors.teal,
              Icons.work,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
            _CounterData(
              'Messages',
              counters.newMessages,
              AppColors.lightTeal,
              Icons.chat,
              () => vm.setTab(DashboardTab.inbox.index),
            ),
            _CounterData(
              'New Offers',
              counters.newOffers,
              AppColors.mediumGrey,
              Icons.local_offer,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
          ]
        : [
            _CounterData(
              'Active Work',
              counters.activeWork,
              AppColors.teal,
              Icons.work_outline,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
            _CounterData(
              'Needs Review',
              counters.needsReview,
              context.colorScheme.danger,
              Icons.rate_review_outlined,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
            _CounterData(
              'Pending Payment',
              counters.pendingPayment,
              AppColors.gold,
              Icons.payment_outlined,
              () => vm.setTab(DashboardTab.bookings.index),
            ),
            _CounterData(
              'Completed',
              counters.completed,
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
        return _CounterCard(data: items[index], isLoading: isLoading);
      },
    );
  }
}

class _CounterData {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  _CounterData(this.label, this.count, this.color, this.icon, this.onTap);
}

class _CounterCard extends StatelessWidget {
  final _CounterData data;
  final bool isLoading;

  const _CounterCard({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Semantics(
      label: '${data.label}: ${data.count}',
      child: AppCard(
        onTap: data.onTap,
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  data.icon,
                  color: data.color,
                  size: AppDimens.iconSizeMedium,
                ),
                if (isLoading)
                  _ShimmerPlaceholder(color: data.color)
                else
                  _AnimatedCount(endValue: data.count, color: data.color),
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
      ),
    );
  }
}

/// Animated count-up widget using IntTween.
class _AnimatedCount extends StatefulWidget {
  final int endValue;
  final Color color;

  const _AnimatedCount({required this.endValue, required this.color});

  @override
  State<_AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<_AnimatedCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotion.emphasis,
      vsync: this,
    );
    _animation = IntTween(begin: 0, end: widget.endValue).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.curveDecel),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(_AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endValue != widget.endValue) {
      _animation = IntTween(begin: oldWidget.endValue, end: widget.endValue)
          .animate(
            CurvedAnimation(parent: _controller, curve: AppMotion.curveDecel),
          );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${_animation.value}',
          style: AppTypography.h3.copyWith(
            color: widget.color,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}

/// Shimmer placeholder shown while counters are loading.
class _ShimmerPlaceholder extends StatefulWidget {
  final Color color;

  const _ShimmerPlaceholder({required this.color});

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: AppMotion.shimmer, vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: AppDimens.p32,
          height: AppDimens.p20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.r4),
            color: colorScheme.cardBorder.withValues(
              alpha: 0.3 + (_controller.value * 0.3),
            ),
          ),
        );
      },
    );
  }
}
