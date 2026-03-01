import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import 'package:sline_app/features/tasks/view/widgets/discovery_task_sliver.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';
import 'package:sline_app/features/tasks/viewmodels/discovery_feed_view_model_contract.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

class TendersScreen extends StatefulWidget {
  const TendersScreen({super.key});

  @override
  State<TendersScreen> createState() => _TendersScreenState();
}

class _TendersScreenState extends State<TendersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeVm = context.read<DiscoveryFeedViewModelContract>();
      final filterVm = context.read<TaskFilterViewModel>();
      if (!homeVm.isLoading && homeVm.featuredTasks.isEmpty) {
        AppLogger.d(
          'discovery_screen_bootstrap',
          tag: 'DiscoveryUI',
          json: {'surface': 'tenders'},
        );
        homeVm.loadFeaturedTasks(
          filterController: filterVm,
          surface: 'tenders',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer2<DiscoveryFeedViewModelContract, TaskFilterViewModel>(
        builder: (context, homeVM, filterVM, child) {
          final tenders = filterVM.filteredTasks
              .where((t) => t.isTender)
              .toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.p24,
                    topPadding + AppDimens.p24,
                    AppDimens.p24,
                    AppDimens.p16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tenders',
                        style: AppTypography.h1.copyWith(
                          color: colorScheme.text,
                        ),
                      ),
                      Text(
                        'Open proposals',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DiscoveryTaskSliver(
                surface: 'tenders',
                tasks: tenders,
                isInitialLoading: homeVM.isLoading,
                isLoadingMore: homeVM.isLoadingMore,
                hasMore: homeVM.hasMore,
                onLoadMore: () => homeVM.loadMoreTasks(
                  filterController: filterVM,
                  surface: 'tenders',
                ),
                emptyTitle: 'No active tenders',
                emptyIcon: Icons.assignment_outlined,
                taskBuilder: (context, task) {
                  return TaskCard(
                    task: task,
                    onTap: () {
                      AppLogger.d(
                        'discovery_task_opened',
                        tag: 'DiscoveryUI',
                        json: {
                          'surface': 'tenders',
                          'task_id': task.id,
                          'task_type': task.taskType.name,
                        },
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaskDetailsScreen(task: task),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
