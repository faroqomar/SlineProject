import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/dashboard/view/widgets/activity_feed_preview.dart';
import 'package:sline_app/features/dashboard/view/widgets/dashboard_counters_grid.dart';
import 'package:sline_app/features/dashboard/view/widgets/next_actions_list.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/wallet/view/widgets/wallet_snapshot_card.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';

/// Dashboard overview tab — the default landing view after login.
///
/// The tab starts at dashboard content because [DashboardScreen] owns the page
/// title and tab context. Wallet, counters, actions, and activity stay wired to
/// their existing ViewModels.
class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  bool _showAllActivity = false;

  @override
  void initState() {
    super.initState();
    // Ensure wallet loads when dashboard overview is first shown (snapshot contract)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.read<WalletViewModel>().loadWallet());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    const spacing = AmberDuskTokens.spacing;
    const amber = AmberDuskTokens.colors;
    const phoneLayout = AmberDuskTokens.phoneLayout;
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;
    final bottomNavClearance =
        bottomSafePadding +
        phoneLayout.bottomNavBottom +
        phoneLayout.bottomNavHeight +
        spacing.lg;

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          spacing.contentHorizontalPadding,
          0,
          spacing.contentHorizontalPadding,
          bottomNavClearance,
        ),
        children: [
          // Wallet appears first to match the dashboard overview evidence.
          const WalletSnapshotCard(),

          SizedBox(height: spacing.md),
          const DashboardCountersGrid(),

          SizedBox(height: spacing.lg),
          const _SectionCard(title: 'Next Actions', child: NextActionsList()),

          SizedBox(height: spacing.lg),
          _SectionCard(
            title: 'Recent Activity',
            action: TextButton(
              onPressed: () {
                setState(() {
                  _showAllActivity = !_showAllActivity;
                });
              },
              child: Text(
                _showAllActivity ? 'Show Less' : 'See All',
                style: AmberDuskTokens.typography.chip.copyWith(
                  color: amber.primary,
                ),
              ),
            ),
            child: AnimatedSize(
              duration: AppMotion.standard,
              curve: AppMotion.curveStandard,
              // Clip.none prevents content clipping during height animation.
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              child: ActivityFeedPreview(limit: _showAllActivity ? null : 3),
            ),
          ),

          SizedBox(height: spacing.md),
        ],
      ),
    );
  }
}

/// Dashboard section header with optional trailing action.
///
/// The Open Design dashboard uses compact uppercase labels; this widget keeps
/// that rhythm while preserving the existing section children.
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? action;
  final Widget child;

  const _SectionCard({required this.title, this.action, required this.child});

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;
    const spacing = AmberDuskTokens.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          label: '$title section',
          child: Padding(
            padding: EdgeInsets.only(bottom: spacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: typography.chip.copyWith(
                      color: amber.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
