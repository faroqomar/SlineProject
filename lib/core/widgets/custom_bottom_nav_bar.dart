import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';

/// Custom bottom navigation bar with iOS 26-inspired liquid glass effect.
///
/// Features:
/// - Frosted glass background with blur effect
/// - Animated pill indicator for active tab
/// - Smooth transitions and scaling animations
/// - Notification badges support
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  static const Key homeNavKey = ValueKey<String>('bottom_nav_home');
  static const Key tendersNavKey = ValueKey<String>('bottom_nav_tenders');
  static const Key bookingsNavKey = ValueKey<String>('bottom_nav_bookings');
  static const Key dashboardNavKey = ValueKey<String>('bottom_nav_dashboard');
  @Deprecated('Use dashboardNavKey instead.')
  static const Key ordersNavKey = dashboardNavKey;
  static const Key messagesNavKey = ValueKey<String>('bottom_nav_messages');
  static const Key profileNavKey = ValueKey<String>('bottom_nav_profile');

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    // Navigation items configuration
    final List<_NavItem> navItems = [
      _NavItem(
        NavView.home,
        Icons.home_outlined,
        Icons.home,
        'Home',
        key: homeNavKey,
      ),
      _NavItem(
        NavView.tender,
        Icons.assignment_outlined,
        Icons.assignment,
        'Tenders',
        key: tendersNavKey,
      ),
      _NavItem(
        NavView.booking,
        Icons.calendar_today_outlined,
        Icons.calendar_today,
        'Bookings',
        key: bookingsNavKey,
      ),
      _NavItem(
        NavView.orders,
        Icons.dashboard_outlined,
        Icons.dashboard,
        'Dashboard',
        key: dashboardNavKey,
      ),
      _NavItem(
        NavView.messages,
        Icons.message_outlined,
        Icons.message,
        'Messages',
        hasNotification: true,
        key: messagesNavKey,
      ),
      _NavItem(
        NavView.profile,
        Icons.person_outline,
        Icons.person,
        'Profile',
        key: profileNavKey,
      ),
    ];

    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        final int currentIndex = navigationProvider.currentIndex.clamp(
          0,
          navItems.length - 1,
        );
        if (currentIndex != navigationProvider.currentIndex) {
          AppLogger.w(
            'Clamped navigation index ${navigationProvider.currentIndex} -> $currentIndex',
            tag: 'Navigation',
          );
        }

        return Positioned(
          bottom: AppDimens.p16,
          left: AppDimens.p16,
          right: AppDimens.p16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.r30),
            child: kIsWeb
                ? Container(
                    height: 70,
                    decoration: _buildLiquidGlassDecoration(colorScheme),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: navItems.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final _NavItem item = entry.value;
                        final bool isActive = currentIndex == index;

                        return _LiquidGlassNavItem(
                          item: item,
                          isActive: isActive,
                          onTap: () {
                            AppLogger.i(
                              'Bottom nav tap -> ${item.label} ($index)',
                              tag: 'Navigation',
                            );
                            navigationProvider.setCurrentIndex(index);
                          },
                          colorScheme: colorScheme,
                        );
                      }).toList(),
                    ),
                  )
                : BackdropFilter(
                    // iOS 26 style blur - systemThinMaterial effect
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      height: 70,
                      decoration: _buildLiquidGlassDecoration(colorScheme),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: navItems.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final _NavItem item = entry.value;
                          final bool isActive = currentIndex == index;

                          return _LiquidGlassNavItem(
                            item: item,
                            isActive: isActive,
                            onTap: () {
                              AppLogger.i(
                                'Bottom nav tap -> ${item.label} ($index)',
                                tag: 'Navigation',
                              );
                              navigationProvider.setCurrentIndex(index);
                            },
                            colorScheme: colorScheme,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  /// Build iOS 26 liquid glass decoration
  BoxDecoration _buildLiquidGlassDecoration(AppColorScheme colorScheme) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppDimens.r30),
      // Liquid glass gradient - mimics iOS systemThinMaterial
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colorScheme.isDark
            ? [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.05),
              ]
            : [
                Colors.white.withValues(alpha: 0.85),
                Colors.white.withValues(alpha: 0.6),
              ],
      ),
      // Inner border glow effect
      border: Border.all(
        color: colorScheme.isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.8),
        width: 0.5,
      ),
      // Subtle shadow for depth
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: colorScheme.isDark ? 0.4 : 0.1),
          blurRadius: 30,
          spreadRadius: -5,
          offset: const Offset(0, 10),
        ),
        // Top highlight (simulates iOS inset effect)
        BoxShadow(
          color: Colors.white.withValues(alpha: colorScheme.isDark ? 0.1 : 0.5),
          blurRadius: 0,
          spreadRadius: 0,
          offset: const Offset(0, -0.5),
        ),
      ],
    );
  }
}

/// Individual navigation item with liquid glass pill effect
class _LiquidGlassNavItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final AppColorScheme colorScheme;

  const _LiquidGlassNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  State<_LiquidGlassNavItem> createState() => _LiquidGlassNavItemState();
}

class _LiquidGlassNavItemState extends State<_LiquidGlassNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _pillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _LiquidGlassNavItem oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: widget.item.key,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Liquid glass pill background (active state)
                if (widget.isActive)
                  Positioned.fill(
                    child: Transform.scale(
                      scale: _pillAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          // Liquid glass pill effect
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: widget.colorScheme.isDark
                                ? [
                                    AppColors.teal.withValues(alpha: 0.4),
                                    AppColors.teal.withValues(alpha: 0.2),
                                  ]
                                : [
                                    AppColors.teal.withValues(alpha: 0.25),
                                    AppColors.teal.withValues(alpha: 0.15),
                                  ],
                          ),
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Icon
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Icon(
                    widget.isActive ? widget.item.activeIcon : widget.item.icon,
                    size: 24,
                    color: widget.isActive
                        ? (widget.colorScheme.isDark
                              ? AppColors.offWhite
                              : AppColors.teal)
                        : (widget.colorScheme.isDark
                              ? AppColors.offWhite.withValues(alpha: 0.5)
                              : AppColors.almostBlack.withValues(alpha: 0.5)),
                  ),
                ),
                // Notification badge
                if (widget.item.hasNotification)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.lightRed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.colorScheme.isDark
                              ? AppColors.almostBlack
                              : AppColors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lightRed.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Navigation item data model
class _NavItem {
  final NavView id;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool hasNotification;
  final Key? key;

  const _NavItem(
    this.id,
    this.icon,
    this.activeIcon,
    this.label, {
    this.hasNotification = false,
    this.key,
  });
}
