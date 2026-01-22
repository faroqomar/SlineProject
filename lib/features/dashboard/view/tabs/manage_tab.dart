import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_theme.dart';

import '../../models/dashboard_enums.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../widgets/manage_service_list.dart';
import '../widgets/manage_task_list.dart';

class ManageTab extends StatefulWidget {
  const ManageTab({super.key});

  @override
  State<ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<ManageTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final isFreelancer = vm.currentRole == UserRole.freelancer;
    final colorScheme = context.colorScheme;

    final tabs = isFreelancer
        ? const [Tab(text: "Active"), Tab(text: "Drafts"), Tab(text: "Paused")]
        : const [
            Tab(text: "Open"),
            Tab(text: "Assigned"),
            Tab(text: "History"),
          ];

    return Column(
      children: [
        Container(
          color: colorScheme.background,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.textSecondary,
            indicatorColor: colorScheme.primary,
            tabAlignment: TabAlignment.start,
            tabs: tabs,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: isFreelancer
                ? const [
                    ManageServiceList(status: "Active"),
                    ManageServiceList(status: "Drafts"),
                    ManageServiceList(status: "Paused"),
                  ]
                : const [
                    ManageTaskList(status: "Open"),
                    ManageTaskList(status: "Assigned"),
                    ManageTaskList(status: "History"),
                  ],
          ),
        ),
      ],
    );
  }
}
