import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/dashboard/view/widgets/activity_feed_preview.dart';
import 'package:sline_app/features/dashboard/view/widgets/dashboard_counters_grid.dart';
import 'package:sline_app/features/dashboard/view/widgets/next_actions_list.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/wallet/view/widgets/wallet_snapshot_card.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';

/// Dashboard overview tab — the default landing view after login.
///
/// Phase 7 REDESIGN: Hero h2 greeting, icon-badged section headers via
/// _SectionCard, increased spacing rhythm with spacingLarge for visual
/// breathing room. AnimatedSize for smooth activity feed expand/collapse.
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
        context.read<WalletViewModel>().loadWallet();
      }
    });
  }

  /// Returns a time-aware greeting based on the current hour.
  ///
  /// Provides a warmer, more personal feel than a static "Hello" — consistent
  /// with .impeccable.md brand voice: "Warm but competent."
  String _timeAwareGreeting(String userName) {
    final hour = DateTime.now().hour;
    final String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }
    return '$timeGreeting, $userName!';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final colorScheme = context.colorScheme;

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p16,
          vertical: AppLayout.spacingSection,
        ),
        children: [
          // ── Hero Greeting ─────────────────────────────────────────
          // Phase 7 REDESIGN: h2 (28px/900) up from h3, bodyLarge up from
          // bodyMedium — first thing the user sees should be commanding.
          Semantics(
            label: 'Greeting: ${_timeAwareGreeting(vm.userName)}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _timeAwareGreeting(vm.userName),
                  style: AppTypography.h2.copyWith(color: colorScheme.text),
                ),
                const SizedBox(height: AppLayout.spacingTight),
                Text(
                  vm.currentRole == UserRole.freelancer
                      ? 'Ready to pick up some work?'
                      : "Let's get your projects moving.",
                  style: AppTypography.bodyLarge.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Wallet Snapshot ───────────────────────────────────────
          const SizedBox(height: AppLayout.spacingScreen),
          const WalletSnapshotCard(),

          // ── Counters Grid ─────────────────────────────────────────
          const SizedBox(height: AppLayout.spacingScreen),
          const DashboardCountersGrid(),

          // ── Next Actions ──────────────────────────────────────────
          // Phase 7 REDESIGN: spacingLarge (32px) creates a visual paragraph
          // break before the action sections — separates metrics from actions.
          const SizedBox(height: AppLayout.spacingLarge),
          _SectionCard(
            title: 'Next Actions',
            // Bolt icon in accent/gold — urgency and action
            icon: Icons.bolt_rounded,
            iconColor: colorScheme.accent,
            child: const NextActionsList(),
          ),

          // ── Recent Activity ───────────────────────────────────────
          const SizedBox(height: AppLayout.spacingScreen),
          _SectionCard(
            title: 'Recent Activity',
            // History icon in info/blue — informational timeline
            icon: Icons.history_rounded,
            iconColor: colorScheme.info,
            action: TextButton(
              onPressed: () {
                setState(() {
                  _showAllActivity = !_showAllActivity;
                });
              },
              child: Text(
                _showAllActivity ? 'Show Less' : 'See All',
                style: AppTypography.captionBold.copyWith(
                  color: colorScheme.primary,
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

          // Bottom padding to clear the main bottom nav bar
          const SizedBox(height: AppLayout.fabBottomOffset),
        ],
      ),
    );
  }
}

/// Section header with icon badge and optional trailing action button.
///
/// Phase 7 REDESIGN: Replaces plain-text _SectionHeader. Each section gets
/// a colored icon badge (icon in rounded container) for visual identity —
/// bolt/accent for Next Actions, history/info for Recent Activity.
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget? action;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header row with icon badge
        Semantics(
          header: true,
          label: '$title section',
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppLayout.spacingStandard),
            child: Row(
              children: [
                // Icon badge — icon in colored rounded container
                Container(
                  padding: const EdgeInsets.all(AppDimens.p6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimens.r8),
                  ),
                  child: Icon(
                    icon,
                    size: AppDimens.iconSizeSmall,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: AppDimens.p8),
                Expanded(
                  child: Text(
                    title,
                    style:
                        AppTypography.h5.copyWith(color: colorScheme.text),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
        ),
        // Section content
        child,
      ],
    );
  }
}
