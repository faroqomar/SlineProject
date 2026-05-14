import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import 'package:sline_app/features/tasks/view/widgets/discovery_task_sliver.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';
import 'package:sline_app/features/tasks/viewmodels/discovery_feed_view_model_contract.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

/// Booking discovery surface that filters the shared task feed to booking work.
class BookingsDiscoveryScreen extends StatefulWidget {
  /// Creates the booking discovery screen.
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
        unawaited(
          homeVm.loadFeaturedTasks(
            filterController: filterVm,
            surface: 'bookings',
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    const typography = AmberDuskTokens.typography;
    final topPadding = MediaQuery.of(context).padding.top;
    final baseInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(spacing.moduleRadius),
      borderSide: BorderSide.none,
    );

    return Scaffold(
      backgroundColor: amber.page,
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
                        'BROWSE',
                        style: typography.chip.copyWith(
                          color: amber.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimens.p4),
                      Text(
                        'Bookings',
                        style: typography.screenTitle.copyWith(
                          color: amber.text,
                        ),
                      ),
                      SizedBox(height: spacing.md),
                      Semantics(
                        label: 'Search services',
                        child: TextField(
                          onChanged: filterVM.searchTasks,
                          style: typography.body.copyWith(color: amber.text),
                          decoration: InputDecoration(
                            hintText: 'Search services...',
                            hintStyle: typography.body.copyWith(
                              color: amber.muted,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: amber.muted,
                            ),
                            filled: true,
                            fillColor:
                                AmberDuskTokens.widgetTheme.fields.background,
                            border: baseInputBorder,
                            enabledBorder: baseInputBorder,
                            focusedBorder: baseInputBorder.copyWith(
                              borderSide: BorderSide(color: amber.primary),
                            ),
                          ),
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
                      unawaited(
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TaskDetailsScreen(task: task),
                          ),
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
