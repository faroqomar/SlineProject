import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/utils/app_animations.dart';
import 'package:sline_app/features/booking/view/bookings_discovery_screen.dart';
import 'package:sline_app/features/chat/view/messages_screen.dart';
import 'package:sline_app/features/home/view/home_screen.dart';
import 'package:sline_app/features/orders/view/orders_dashboard_screen.dart';
import 'package:sline_app/features/profile/view/profile_screen.dart';
import 'package:sline_app/features/tasks/view/create_task_screen.dart';
import 'package:sline_app/features/tasks/view/tenders_screen.dart';
import 'package:sline_app/features/wallet/view/wallet_dashboard_screen.dart';
import 'package:sline_app/features/notifications/view/widgets/notification_badge_button.dart';
import '../core/providers/navigation_provider.dart';
import '../core/widgets/custom_bottom_nav_bar.dart';

/// Main navigation screen that manages bottom navigation and screen switching
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    // Screens matching NavView enum order: home, tender, booking, orders, messages, profile, wallet
    final List<Widget> screens = [
      const HomeScreen(),
      const TendersScreen(),
      const BookingsDiscoveryScreen(),
      const OrdersDashboardScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
      const WalletDashboardScreen(),
    ];

    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          // IMPORTANT: extendBody must be true for the liquid glass effect to work
          // This allows the body to paint behind the bottom navigation bar
          extendBody: true,
          body: Stack(
            children: [
              // 1. Global Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.teal,
                      AppColors.lightTeal,
                      AppColors.gold.withValues(alpha: 0.3), // Subtle gold hint
                    ],
                  ),
                ),
              ),

              // 2. Phone Background (The "Mockup" inner container)
              Container(color: colorScheme.phoneBackground),

              // 3. Active Screen with smooth fade transition
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(navigationProvider.currentIndex),
                  child: screens[navigationProvider.currentIndex],
                ),
              ),

              // 4. iOS 26 Liquid Glass Bottom Navigation Bar
              const CustomBottomNavBar(),

              // 5. Floating Action Button (Create Task) with rotation animation
              Positioned(
                bottom: 100, // Above liquid glass bottom bar
                right: AppDimens.p24,
                child: AnimatedRotationButton(
                  rotationAngle: 0.125, // 45 degrees
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateTaskScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(AppDimens.r18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(Icons.add, color: AppColors.white, size: 30),
                  ),
                ),
              ),
              // 6. Notification Badge (Top Right)
              Positioned(
                top: MediaQuery.of(context).padding.top + AppDimens.p16,
                right: AppDimens.p16,
                child: const NotificationBadgeButton(),
              ),
            ],
          ),
          // Note: CustomBottomNavBar is positioned inside the Stack, not as bottomNavigationBar
        );
      },
    );
  }
}
