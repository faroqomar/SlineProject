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
              // In a real app, we might just use the full screen, but preserving the design's layering
              Container(
                color: colorScheme.phoneBackground,
              ),

              // 3. Global Noise Texture (Optional - skipping for performance/asset dependency)

              // 4. Active Screen
              IndexedStack(
                index: navigationProvider.currentIndex,
                children: screens,
              ),

              // 5. Floating Action Button (Create Task) with rotation animation
              Positioned(
                bottom: 100,
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
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),

              // 6. Custom Bottom Navigation (Floating Island)
              const CustomBottomNavBar(),
            ],
          ),
        );
      },
    );
  }
}
