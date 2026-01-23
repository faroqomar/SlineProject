import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/app_enums.dart';
import '../viewmodels/dashboard_view_model.dart';
import 'tabs/overview_tab.dart';
import 'tabs/manage_tab.dart';
import 'tabs/bookings_tab.dart';
import 'tabs/active_work_tab.dart';
import 'tabs/inbox_tab.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(),
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSettings(BuildContext context, DashboardViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Dashboard Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("User Role"),
            const SizedBox(height: 12),
            // Reusing the Role Switcher here
            ChangeNotifierProvider.value(value: vm, child: const _RoleSwitch()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final colorScheme = context.colorScheme;

    // Sync controller with VM state
    if (_tabController.index != vm.currentTab.index) {
      _tabController.animateTo(vm.currentTab.index);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: AppTypography.h4.copyWith(color: colorScheme.text),
        ),
        backgroundColor: colorScheme.background,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: colorScheme.textSecondary,
            ),
            onPressed: () => _showSettings(context, vm),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.textSecondary,
            indicatorColor: colorScheme.primary,
            onTap: (index) => vm.setTab(index),
            tabs: const [
              Tab(icon: Icon(Icons.dashboard_outlined), text: "Overview"),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: "Manage"),
              Tab(icon: Icon(Icons.calendar_month_outlined), text: "Bookings"),
              Tab(icon: Icon(Icons.work_history_outlined), text: "Work"),
              Tab(icon: Icon(Icons.inbox_outlined), text: "Inbox"),
            ],
          ),
        ),
      ),
      body: Padding(
        // Add padding to avoid overlap with Main Bottom Nav Bar
        padding: const EdgeInsets.only(bottom: 80),
        child: TabBarView(
          controller: _tabController,
          physics:
              const NeverScrollableScrollPhysics(), // Disable swipe to avoid conflict with internal tabs
          children: [
            const OverviewTab(),
            const ManageTab(),
            const BookingsTab(),
            const ActiveWorkTab(),
            const InboxTab(),
          ],
        ),
      ),
    );
  }
}

class _RoleSwitch extends StatelessWidget {
  const _RoleSwitch();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final colorScheme = context.colorScheme;
    final isFreelancer = vm.currentRole == UserRole.freelancer;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.inputBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.inputBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoleButton(
            label: "Freelancer",
            isActive: isFreelancer,
            onTap: () => vm.setRole(UserRole.freelancer),
          ),
          _RoleButton(
            label: "Client",
            isActive: !isFreelancer,
            onTap: () => vm.setRole(UserRole.client),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTypography.captionBold.copyWith(
            color: isActive ? AppColors.white : colorScheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
