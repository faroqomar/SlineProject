import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

/// A [SliverPersistentHeaderDelegate] that renders a [TabBar] with a
/// solid background and optional bottom border when pinned.
///
/// ## NO GLASS POLICY (see .impeccable.md)
/// Uses the solid Amber Dusk panel surface when pinned.
///
/// ## Phase 1 Changes
/// - Keeps the pinned header borderless per Amber Dusk surface evidence.
/// - Solid background from the Amber Dusk card surface.
/// - Amber Dusk tokens now provide the header surface, borderless pinned
///   treatment, and tab active/inactive colors.
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
    final tabTheme = AmberDuskTokens.widgetTheme.tabs;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    final isPinned = shrinkOffset > 0;
    final themedTabBar = Theme(
      data: Theme.of(context).copyWith(
        tabBarTheme: Theme.of(context).tabBarTheme.copyWith(
          labelColor: tabTheme.activeLabelColor,
          unselectedLabelColor: tabTheme.inactiveLabelColor,
          indicatorColor: tabTheme.indicatorColor,
          labelStyle: tabTheme.labelStyle,
          unselectedLabelStyle: tabTheme.inactiveLabelStyle,
        ),
      ),
      child: tabBar,
    );

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? cardTheme.panel.background,
        border: isPinned
            ? Border(
                bottom: BorderSide(
                  color: cardTheme.border,
                  width: cardTheme.borderWidth,
                ),
              )
            : null,
      ),
      child: themedTabBar,
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
