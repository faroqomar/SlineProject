import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/app_enums.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../widgets/activity_feed_preview.dart';
import '../widgets/dashboard_counters_grid.dart';
import '../widgets/next_actions_list.dart';
import '../widgets/wallet_snapshot_card.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  bool _showAllActivity = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final colorScheme = context.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppDimens.p16),
      children: [
        Text(
          "Hello, Eros! 👋",
          style: AppTypography.h3.copyWith(color: colorScheme.text),
        ),
        Text(
          vm.currentRole == UserRole.freelancer
              ? "Ready to pick up some work?"
              : "Let's get your projects moving.",
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimens.p20),

        const SizedBox(height: AppDimens.p20),
        const WalletSnapshotCard(),
        const SizedBox(height: AppDimens.p20),

        DashboardCountersGrid(),

        const SizedBox(height: AppDimens.p24),

        _SectionHeader(title: "Next Actions"),
        const NextActionsList(),

        const SizedBox(height: AppDimens.p24),

        _SectionHeader(
          title: "Recent Activity",
          action: TextButton(
            onPressed: () {
              setState(() {
                _showAllActivity = !_showAllActivity;
              });
            },
            child: Text(_showAllActivity ? "Show Less" : "See All"),
          ),
        ),
        ActivityFeedPreview(limit: _showAllActivity ? null : 3),
        // Add some bottom padding for navigation bar
        const SizedBox(height: AppDimens.p100),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.h5.copyWith(color: context.colorScheme.text),
        ),
        if (action != null) action!,
      ],
    );
  }
}
