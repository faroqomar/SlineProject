import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';

const int _kCompletedWorkSubTab = 1;

/// Dashboard counters grid — 2x2 stat cards for freelancer or client.
///
/// Cards use Amber Dusk surface and status tokens while preserving the
/// DashboardViewModel tap routing for each metric.
class DashboardCountersGrid extends StatelessWidget {
  const DashboardCountersGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final isFreelancer = vm.currentRole == UserRole.freelancer;
    final counters = vm.counters;
    final isLoading = vm.isLoading;

    AppLogger.d('DashboardCountersGrid loaded', tag: 'Cards');

    const amber = AmberDuskTokens.colors;

    final items = isFreelancer
        ? [
            _CounterData(
              'Pending',
              counters.pendingRequests,
              amber.warning,
              Icons.pending_actions,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
            _CounterData(
              'Active',
              counters.activeWork,
              amber.success,
              Icons.work,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
            _CounterData(
              'Messages',
              counters.newMessages,
              amber.star,
              Icons.chat,
              () => vm.setTab(DashboardTab.inbox.index),
            ),
            _CounterData(
              'New Offers',
              counters.newOffers,
              amber.danger,
              Icons.local_offer,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
          ]
        : [
            _CounterData(
              'Active Work',
              counters.activeWork,
              amber.success,
              Icons.work_outline,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
            _CounterData(
              'Needs Review',
              counters.needsReview,
              amber.warning,
              Icons.rate_review_outlined,
              () => vm.setTab(DashboardTab.activeWork.index),
            ),
            _CounterData(
              'Pending Payment',
              counters.pendingPayment,
              amber.star,
              Icons.payment_outlined,
              () => vm.setTab(DashboardTab.bookings.index),
            ),
            _CounterData(
              'Completed',
              counters.completed,
              amber.success,
              Icons.check_circle_outline,
              () => vm.setTab(
                DashboardTab.activeWork.index,
                workSubTab: _kCompletedWorkSubTab,
              ),
            ),
          ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDimens.p12,
        mainAxisSpacing: AppDimens.p12,
        childAspectRatio: 1.62,
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

/// Counter card with colored icon badge and bold number.
///
/// The icon well and count color encode status without changing the tap target
/// or the ViewModel tab-routing callbacks.
class _CounterCard extends StatelessWidget {
  final _CounterData data;
  final bool isLoading;

  const _CounterCard({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;

    return Semantics(
      label: '${data.label}: ${data.count}',
      child: AppCard(
        onTap: data.onTap,
        padding: const EdgeInsets.all(AppDimens.p12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.p6),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.r10),
              ),
              child: Icon(
                data.icon,
                color: data.color,
                size: AppDimens.iconSizeSmall,
              ),
            ),
            // Number + label stack at bottom
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  _ShimmerPlaceholder(color: data.color)
                else
                  _AnimatedCount(endValue: data.count, color: data.color),
                const SizedBox(height: AppDimens.p2),
                Text(
                  data.label,
                  style: typography.bodySmall.copyWith(color: amber.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated count-up widget using IntTween.
///
/// Count-up motion keeps metric changes noticeable without shifting layout.
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
      if (mounted) unawaited(_controller.forward());
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
      _controller.reset();
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const typography = AmberDuskTokens.typography;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${_animation.value}',
          style: typography.sectionTitle.copyWith(
            color: widget.color,
            fontWeight: FontWeight.w900,
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
    _controller = AnimationController(
      duration: AppMotion.shimmer,
      vsync: this,
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skeleton = AmberDuskTokens.widgetTheme.skeleton;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: AppDimens.p32,
          height: AppDimens.p20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.r4),
            color: skeleton.highlight.withValues(
              alpha: 0.3 + (_controller.value * 0.3),
            ),
          ),
        );
      },
    );
  }
}
