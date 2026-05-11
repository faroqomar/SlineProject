import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:sline_app/core/navigation/main_nav_destinations.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

/// Custom bottom navigation bar with solid surface design.
///
/// ## NO GLASS POLICY (see .impeccable.md)
///
/// All frosted translucent effects have been removed.
/// The bar now uses the solid Amber Dusk nav surface with elevation shadow.
///
/// ## Phase 1 Changes
/// - Removed all frosted translucent decoration
/// - Solid surface: Amber Dusk nav surface + elevation Level 3 shadow
/// - Migrated all animation values to AppMotion tokens
/// - Added tiny label text below each icon (fades in/out with active state)
/// - Notification badge: pill with count text (max "99+"), animated entrance
/// - Added HapticFeedback.selectionClick on each tap
/// - Added Semantics to each nav item
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    this.showMessagesNotification = true,
    this.messagesNotificationCount = 0,
  }) : assert(
         messagesNotificationCount == null || messagesNotificationCount >= 0,
         'messagesNotificationCount must be non-negative when provided.',
       );

  /// Whether the Messages tab should display its notification marker.
  final bool showMessagesNotification;

  /// Optional Messages badge count; null or zero renders a compact dot.
  final int? messagesNotificationCount;

  static const Key homeNavKey = ValueKey<String>('bottom_nav_home');
  static const Key dashboardNavKey = ValueKey<String>('bottom_nav_dashboard');
  @Deprecated('Use dashboardNavKey instead.')
  static const Key ordersNavKey = dashboardNavKey;
  static const Key messagesNavKey = ValueKey<String>('bottom_nav_messages');
  static const Key profileNavKey = ValueKey<String>('bottom_nav_profile');
  static const Key navSurfaceKey = ValueKey<String>('bottom_nav_surface');
  static const Key activeCapsuleKey = ValueKey<String>(
    'bottom_nav_active_capsule',
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navTheme = AmberDuskTokens.widgetTheme.bottomNav;
    const phoneLayout = AmberDuskTokens.phoneLayout;

    final navItems = <_NavItem>[
      const _NavItem(
        MainNavDestinations.home,
        Icons.home_outlined,
        Icons.home,
        'Home',
        key: homeNavKey,
      ),
      const _NavItem(
        MainNavDestinations.dashboard,
        Icons.dashboard_outlined,
        Icons.dashboard,
        'Dashboard',
        key: dashboardNavKey,
      ),
      _NavItem(
        MainNavDestinations.messages,
        Icons.message_outlined,
        Icons.message,
        'Messages',
        hasNotification: showMessagesNotification,
        notificationCount: messagesNotificationCount,
        key: messagesNavKey,
      ),
      const _NavItem(
        MainNavDestinations.profile,
        Icons.person_outline,
        Icons.person,
        'Profile',
        key: profileNavKey,
      ),
    ];

    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        final currentIndex =
            MainNavDestinations.isVisibleIndex(navigationProvider.currentIndex)
            ? navigationProvider.currentIndex
            : MainNavDestinations.home;
        if (currentIndex != navigationProvider.currentIndex) {
          AppLogger.w(
            'Clamped navigation index ${navigationProvider.currentIndex} -> $currentIndex',
            tag: 'Navigation',
          );
        }

        final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

        return Positioned(
          bottom: phoneLayout.bottomNavBottom + bottomSafePadding,
          left: phoneLayout.bottomNavInset,
          right: phoneLayout.bottomNavInset,
          child: Container(
            key: navSurfaceKey,
            height: phoneLayout.bottomNavHeight,
            decoration: BoxDecoration(
              color: navTheme.surface,
              borderRadius: BorderRadius.circular(navTheme.radius),
              boxShadow: AppDecorations.elevation(3, isDark: isDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: navItems.map((item) {
                final isActive = currentIndex == item.index;

                return _SolidNavItem(
                  item: item,
                  isActive: isActive,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    AppLogger.i(
                      'Bottom nav tap -> ${item.label} (${item.index})',
                      tag: 'Navigation',
                    );
                    navigationProvider.setCurrentIndex(item.index);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Individual navigation item with solid pill indicator.
class _SolidNavItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SolidNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SolidNavItem> createState() => _SolidNavItemState();
}

class _SolidNavItemState extends State<_SolidNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotion.standard,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: AppMotion.badgeEntrance)
        .animate(
          CurvedAnimation(parent: _controller, curve: AppMotion.curveSpring),
        );
    _pillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.curveStandard),
    );

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _SolidNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildNotificationBadge(AmberDuskBottomNavThemeTokens navTheme) {
    final count = widget.item.notificationCount;
    if (count == null || count <= 0) {
      return Container(
        width: AmberDuskTokens.spacing.sm,
        height: AmberDuskTokens.spacing.sm,
        decoration: const BoxDecoration(
          color: AmberDuskColors.rust,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AmberDuskTokens.spacing.xs,
        vertical: AmberDuskTokens.spacing.xxs,
      ),
      constraints: const BoxConstraints(minWidth: AppDimens.iconSizeSmall),
      decoration: BoxDecoration(
        color: AmberDuskTokens.colors.rust,
        borderRadius: BorderRadius.circular(AmberDuskTokens.spacing.sm),
      ),
      child: Text(
        widget.item.displayNotificationCount,
        textAlign: TextAlign.center,
        style: navTheme.labelStyle.copyWith(
          color: AmberDuskTokens.colors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navTheme = AmberDuskTokens.widgetTheme.bottomNav;

    return Semantics(
      label: widget.item.label,
      selected: widget.isActive,
      button: true,
      child: GestureDetector(
        key: widget.item.key,
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return SizedBox(
              width: AppLayout.minTouchTarget,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: AppLayout.minTouchTarget,
                    height: AppDimens.p40,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // The active capsule uses the exact Amber Dusk nav
                        // geometry so the icon state does not inherit teal-era
                        // pill sizing from the previous theme.
                        Transform.scale(
                          scale: widget.isActive ? _pillAnimation.value : 0,
                          child: Container(
                            key: widget.isActive
                                ? CustomBottomNavBar.activeCapsuleKey
                                : null,
                            width: navTheme.activeIconSize.width,
                            height: navTheme.activeIconSize.height,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                navTheme.activeIconRadius,
                              ),
                              color: navTheme.activeIconBackground,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Icon(
                            widget.isActive
                                ? widget.item.activeIcon
                                : widget.item.icon,
                            size: AppDimens.iconSizeMedium,
                            color: widget.isActive
                                ? navTheme.activeForeground
                                : navTheme.inactiveForeground,
                          ),
                        ),
                        // Notification badge keeps the existing marker
                        // behavior while switching the visual role to Amber
                        // Dusk rust instead of the previous red token.
                        if (widget.item.showsNotification)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _buildNotificationBadge(navTheme),
                          ),
                      ],
                    ),
                  ),
                  // Label text (fades with active state)
                  AnimatedOpacity(
                    opacity: widget.isActive ? 1.0 : 0.5,
                    duration: AppMotion.fast,
                    child: Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: navTheme.labelStyle.copyWith(
                        color: widget.isActive
                            ? navTheme.activeForeground
                            : navTheme.inactiveForeground,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Navigation item data model
class _NavItem {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool hasNotification;
  final int? notificationCount;
  final Key? key;

  const _NavItem(
    this.index,
    this.icon,
    this.activeIcon,
    this.label, {
    this.hasNotification = false,
    this.notificationCount,
    this.key,
  }) : assert(
         notificationCount == null || notificationCount >= 0,
         'notificationCount must be non-negative when provided.',
       );

  bool get showsNotification => hasNotification;

  String get displayNotificationCount {
    final count = notificationCount;
    if (count == null || count <= 0) return '';
    return count > 99 ? '99+' : count.toString();
  }
}
