library;
import 'dart:ui'; // For ImageFilter

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_colors.dart'; // NEW import
import 'package:sline_app/core/providers/navigation_provider.dart';

/// Custom bottom navigation bar component for the main app navigation
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    // Define navigation items with their corresponding NavView, IconData, and potential notification status
    final List<Map<String, dynamic>> navItems = [
      {'id': NavView.home, 'icon': Icons.home},
      {'id': NavView.tender, 'icon': Icons.assignment}, // Changed from Icons.description
      {'id': NavView.booking, 'icon': Icons.calendar_today},
      {'id': NavView.orders, 'icon': Icons.business_center}, // Changed from Icons.work_briefcase
      {'id': NavView.messages, 'icon': Icons.message, 'hasNotification': true},
      {'id': NavView.profile, 'icon': Icons.person},
    ];

    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Positioned(
          bottom: AppDimens.p24, // bottom-6
          left: AppDimens.p24, // left-6
          right: AppDimens.p24, // right-6
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.r30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: AppDimens.p20, sigmaY: AppDimens.p20), // blur(20px)
              child: Container(
                height: AppDimens.p80, // h-[80px]
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p4), // px-1
                decoration: AppDecorations.bottomNavBarDecoration(colorScheme: colorScheme),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: navItems.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final Map<String, dynamic> item = entry.value;
                    // final NavView navView = item['id']; // Unused
                    final IconData icon = item['icon'];
                    final bool hasNotification = item['hasNotification'] ?? false;
                    final bool isActive = navigationProvider.currentIndex == index;

                    return Expanded(
                      child: InkWell(
                        onTap: () => navigationProvider.setCurrentIndex(index),
                        borderRadius: BorderRadius.circular(AppDimens.r20), // rounded-2xl
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  transform: Matrix4.identity()
                                    ..scale(isActive ? 1.1 : 1.0), // scale-110
                                  child: Icon(
                                    icon,
                                    size: AppDimens.p22, // w-[22px] h-[22px]
                                    color: isActive
                                        ? AppColors.offWhite // text-[#f4f3f1]
                                        : AppColors.offWhite.withValues(alpha: 0.6), // text-[#f4f3f1]/60
                                  ),
                                ),
                                if (hasNotification)
                                  Positioned(
                                    top: -AppDimens.p2, // top-1
                                    right: -AppDimens.p8, // right-2
                                    child: Container(
                                      width: AppDimens.p8, // w-2
                                      height: AppDimens.p8, // h-2
                                      decoration: BoxDecoration(
                                        color: AppColors.lightRed, // bg-[#f49d9d]
                                        shape: BoxShape.circle,
                                        border: Border.all(color: colorScheme.phoneBackground, width: 2), // ADDED BORDER
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // If labels are ever needed again, they would go here
                            // Text(
                            //   navView.toString().split('.').last, // 'home' from NavView.home
                            //   style: TextStyle(
                            //     color: isActive ? colorScheme.text : colorScheme.textSecondary,
                            //     fontSize: 10,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
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
}
