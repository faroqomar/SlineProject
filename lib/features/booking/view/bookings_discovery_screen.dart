import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import 'package:sline_app/features/tasks/view/widgets/discovery_task_sliver.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';
import 'package:sline_app/features/tasks/viewmodels/discovery_feed_view_model_contract.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

class BookingsDiscoveryScreen extends StatefulWidget {
  const BookingsDiscoveryScreen({super.key});

  @override
  State<BookingsDiscoveryScreen> createState() =>
      _BookingsDiscoveryScreenState();
}

class _BookingsDiscoveryScreenState extends State<BookingsDiscoveryScreen> {
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
          json: {'surface': 'bookings'},
        );
        homeVm.loadFeaturedTasks(
          filterController: filterVm,
          surface: 'bookings',
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
          final bookings = filterVM.filteredTasks
              .where((t) => t.isBooking)
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
                        'Bookings',
                        style: AppTypography.h1.copyWith(
                          color: colorScheme.text,
                        ),
                      ),
                      Text(
                        'Direct hire opportunities',
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
                surface: 'bookings',
                tasks: bookings,
                isInitialLoading: homeVM.isLoading,
                isLoadingMore: homeVM.isLoadingMore,
                hasMore: homeVM.hasMore,
                onLoadMore: () => homeVM.loadMoreTasks(
                  filterController: filterVM,
                  surface: 'bookings',
                ),
                emptyTitle: 'No booking services',
                emptyIcon: Icons.calendar_today_outlined,
                skeletonItem: const SkeletonBookingCard(),
                taskBuilder: (context, task) {
                  return TaskCard(
                    task: task,
                    onTap: () {
                      AppLogger.d(
                        'discovery_task_opened',
                        tag: 'DiscoveryUI',
                        json: {
                          'surface': 'bookings',
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
