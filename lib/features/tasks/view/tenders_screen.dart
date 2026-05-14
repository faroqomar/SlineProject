import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import 'package:sline_app/features/tasks/view/widgets/discovery_task_sliver.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';
import 'package:sline_app/features/tasks/viewmodels/discovery_feed_view_model_contract.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';
import 'package:sline_app/l10n/app_localizations.dart';

class TendersScreen extends StatefulWidget {
  const TendersScreen({super.key});

  @override
  State<TendersScreen> createState() => _TendersScreenState();
}

class _TendersScreenState extends State<TendersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeVm = context.read<DiscoveryFeedViewModelContract>();
      final filterVm = context.read<TaskFilterViewModel>();
      _clearSearch(filterVm);
      if (!homeVm.isLoading && homeVm.featuredTasks.isEmpty) {
        AppLogger.d(
          'discovery_screen_bootstrap',
          tag: 'DiscoveryUI',
          json: {'surface': 'tenders'},
        );
        unawaited(
          homeVm.loadFeaturedTasks(
            filterController: filterVm,
            surface: 'tenders',
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch(TaskFilterViewModel filterVm) {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    // TextEditingController.clear may already drive onChanged; only reset the
    // ViewModel directly when its query is still dirty after the field reset.
    if (filterVm.searchQuery.isNotEmpty) {
      filterVm.clearSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    const amberColors = AmberDuskTokens.colors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: amberColors.page,
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
                        'BROWSE',
                        style: AppTypography.overline.copyWith(
                          color: amberColors.muted,
                        ),
                      ),
                      Text(
                        'Tenders',
                        style: AmberDuskTokens.typography.screenTitle.copyWith(
                          color: amberColors.text,
                        ),
                      ),
                      const SizedBox(height: AppDimens.p16),
                      TextField(
                        controller: _searchController,
                        onChanged: filterVM.searchTasks,
                        style: AmberDuskTokens.typography.body.copyWith(
                          color: amberColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.searchTenders,
                          prefixIcon: Icon(
                            Icons.search,
                            color: amberColors.muted,
                          ),
                          filled: true,
                          fillColor:
                              AmberDuskTokens.widgetTheme.fields.background,
                          hintStyle: AmberDuskTokens.typography.body.copyWith(
                            color: amberColors.muted,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AmberDuskTokens.spacing.moduleRadius,
                            ),
                            borderSide: BorderSide.none,
                          ),
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
