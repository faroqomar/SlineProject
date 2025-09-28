import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/chat/view/messages_screen.dart';
import '../core/providers/navigation_provider.dart';
import '../core/widgets/custom_bottom_nav_bar.dart';
import '../features/home/view/home_screen.dart';
import '../features/tasks/view/create_task_screen.dart';
import '../features/profile/view/profile_screen.dart';

/// Main navigation screen that manages bottom navigation and screen switching
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  /// List of screens corresponding to bottom navigation tabs
  static const List<Widget> _screens = [
    HomeScreen(),
    MessagesScreen(),
    CreateTaskScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: navigationProvider.currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: const CustomBottomNavBar(),
        );
      },
    );
  }
}
