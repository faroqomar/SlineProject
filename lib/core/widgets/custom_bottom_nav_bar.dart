import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:sline_app/core/navigation/main_nav_destinations.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

/// Custom bottom navigation bar with the Amber Dusk solid surface design.
///
/// ## Solid Surface Policy
///
/// The bar uses the staged Amber Dusk nav surface with inset depth and
/// keeps the existing four-destination shell contract.
///
/// ## Phase 1 Changes
/// - Solid surface: Amber Dusk nav surface + quiet tactile depth
/// - Migrated all animation values to AppMotion tokens
/// - Added tiny label text below each icon (fades in/out with active state)
/// - Notification badge: pill with count text (max "99+"), animated entrance
/// - Added HapticFeedback.selectionClick on each tap
/// - Added Semantics to each nav item
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    this.showMessagesNotification = false,
    this.messagesNotificationCount,
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
  static const Key activeRailKey = ValueKey<String>('bottom_nav_active_rail');

  @override
  Widget build(BuildContext context) {
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

        return Positioned(
          // bottomNavBottom is measured from the phone frame edge in the
          // Amber Dusk source artboard, so adding MediaQuery safe padding here
          // double-lifts the shell on iPhones with a home indicator.
          bottom: phoneLayout.bottomNavBottom,
          left: phoneLayout.bottomNavInset,
          right: phoneLayout.bottomNavInset,
          child: Container(
            key: navSurfaceKey,
            height: phoneLayout.bottomNavHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p6,
              vertical: AppDimens.p6,
            ),
            decoration: BoxDecoration(
              color: navTheme.surface,
              borderRadius: BorderRadius.circular(navTheme.radius),
              boxShadow: AmberDuskMaterial.surfaceDepthShadows,
            ),
            child: Row(
              children: navItems.map((item) {
                final isActive = currentIndex == item.index;

                return Expanded(
                  child: _SolidNavItem(
                    item: item,
                    isActive: isActive,
                    onTap: () {
                      unawaited(HapticFeedback.selectionClick());
                      AppLogger.i(
                        'Bottom nav tap -> ${item.label} (${item.index})',
                        tag: 'Navigation',
                      );
                      navigationProvider.setCurrentIndex(item.index);
                    },
                  ),
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
      unawaited(_controller.forward());
    }
  }

  @override
  void didUpdateWidget(covariant _SolidNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        unawaited(_controller.forward());
      } else {
        unawaited(_controller.reverse());
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
        color: AmberDuskColors.rust,
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
    const amberColors = AmberDuskTokens.colors;

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
            final activeScale = widget.isActive ? _pillAnimation.value : 0.96;
            final activeOpacity = widget.isActive ? _pillAnimation.value : 0.0;
            final iconColor = widget.isActive
                ? navTheme.activeForeground
                : navTheme.inactiveForeground;
            final labelColor = widget.isActive
                ? navTheme.activeForeground
                : navTheme.inactiveForeground;

            return SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // The active destination is a full touch-tile surface, not
                  // just a small icon blob, so users can recognize the current
                  // tab at a glance without relying only on color.
                  Positioned.fill(
                    child: Opacity(
                      opacity: activeOpacity,
                      child: Transform.scale(
                        scale: activeScale,
                        child: Container(
                          key: widget.isActive
                              ? CustomBottomNavBar.activeCapsuleKey
                              : null,
                          decoration: BoxDecoration(
                            gradient: AmberDuskMaterial.activeWashGradient,
                            borderRadius: BorderRadius.circular(AppDimens.r18),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.isActive)
                    Positioned(
                      top: AppDimens.p4,
                      child: FadeTransition(
                        opacity: _pillAnimation,
                        child: Container(
                          key: CustomBottomNavBar.activeRailKey,
                          width: AppDimens.p28,
                          height: AppDimens.p4,
                          decoration: BoxDecoration(
                            color: amberColors.primary,
                            borderRadius: BorderRadius.circular(AppDimens.r50),
                          ),
                        ),
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: AppDimens.p40,
                        height: AppDimens.p32,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.isActive
                                    ? amberColors.primary.withValues(
                                        alpha: 0.16,
                                      )
                                    : AmberDuskColors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.r14,
                                ),
                              ),
                              child: const SizedBox(
                                width: AppDimens.p40,
                                height: AppDimens.p32,
                              ),
                            ),
                            Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Icon(
                                widget.isActive
                                    ? widget.item.activeIcon
                                    : widget.item.icon,
                                size: AmberDuskTokens
                                    .widgetTheme
                                    .iconButtons
                                    .iconSize,
                                color: iconColor,
                              ),
                            ),
                            // Notification badge keeps the existing marker
                            // behavior while using the Amber Dusk rust accent.
                            if (widget.item.showsNotification)
                              Positioned(
                                top: -AppDimens.p2,
                                right: -AppDimens.p2,
                                child: _buildNotificationBadge(navTheme),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.p2),
                      AnimatedDefaultTextStyle(
                        duration: AppMotion.fast,
                        curve: AppMotion.curveStandard,
                        style: navTheme.labelStyle.copyWith(
                          color: labelColor,
                          fontWeight: widget.isActive
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                        child: Text(
                          widget.item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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
