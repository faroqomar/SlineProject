import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_theme.dart';

/// A [SliverPersistentHeaderDelegate] that renders a [TabBar] with a
/// solid background and optional bottom border when pinned.
///
/// ## NO GLASS POLICY (see .impeccable.md)
/// Uses solid `cardBackground` when pinned — no blur or glass effects.
///
/// ## Phase 1 Changes
/// - Added bottom border when pinned (1px, divider color)
/// - Solid background from cardBackground (no blur per NO GLASS POLICY)
class SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color? backgroundColor;

  const SliverTabBarDelegate(this.tabBar, {this.backgroundColor});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = context.colorScheme;
    final isPinned = shrinkOffset > 0;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.cardBackground,
        border: isPinned
            ? Border(
                bottom: BorderSide(
                  color: colorScheme.divider,
                  width: AppLayout.borderStandard,
                ),
              )
            : null,
      ),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
