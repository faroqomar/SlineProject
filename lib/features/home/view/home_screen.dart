import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/home/view/widgets/filters_modal.dart';
import 'package:sline_app/features/notifications/view/widgets/notification_badge_button.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import 'package:sline_app/features/tasks/view/widgets/discovery_task_sliver.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';
import 'package:sline_app/features/tasks/viewmodels/discovery_feed_view_model_contract.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';
import 'package:sline_app/shared/constants/categories.dart';

/// Home screen - main dashboard for the app (MVVM) with Glassmorphism design.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.autoLoadOnInit = true,
    this.taskDetailsScreenBuilder,
  });

  static const Key searchFieldKey = ValueKey<String>('home_search_field');
  static const Key discoveryAllWorkKey = ValueKey<String>(
    'home_discovery_all_work',
  );
  static const Key discoveryBookingsKey = ValueKey<String>(
    'home_discovery_bookings',
  );
  static const Key discoveryTendersKey = ValueKey<String>(
    'home_discovery_tenders',
  );
  static const Key refreshIndicatorKey = ValueKey<String>(
    'home_refresh_indicator',
  );
  static const Key filterButtonKey = ValueKey<String>('home_filter_button');

  final bool autoLoadOnInit;
  final Widget Function(Task task)? taskDetailsScreenBuilder;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// The Home discovery mode controls task-type filtering below search.
///
/// It stays local to the View because it only changes presentation of the
/// already-loaded discovery feed owned by the existing ViewModels.
enum _HomeDiscoveryMode { allWork, bookings, tenders }

class _HomeScreenState extends State<HomeScreen> {
  _HomeDiscoveryMode _selectedDiscoveryMode = _HomeDiscoveryMode.allWork;

  @override
  void initState() {
    super.initState();
    if (!widget.autoLoadOnInit) return;
    AppLogger.d(
      'home_screen_bootstrap_scheduled',
      tag: 'HomeUI',
      json: {'surface': 'home'},
    );
    // Load featured tasks and notify filter controller when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryFeedViewModelContract>().loadFeaturedTasks(
        filterController: context.read<TaskFilterViewModel>(),
        surface: 'home',
      );
      // Ensure profile is loaded for the header
      context.read<ProfileViewModel>().loadHeaderProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer3<DiscoveryFeedViewModelContract, TaskFilterViewModel, ProfileViewModel>(
        builder: (context, homeViewModel, filterController, profileVM, child) {
          final topPadding = MediaQuery.of(context).padding.top;
          final visibleTasks = _tasksForMode(
            filterController.filteredTasks,
            _selectedDiscoveryMode,
          );
          final selectedModeMetadata = _metadataForMode(_selectedDiscoveryMode);

          return RefreshIndicator(
            key: HomeScreen.refreshIndicatorKey,
            onRefresh: () async {
              final saved = context.read<SavedTasksViewModel>();
              AppLogger.i(
                'home_refresh_started',
                tag: 'HomeUI',
                json: {'surface': 'home'},
              );
              try {
                await homeViewModel.refresh(
                  filterController: filterController,
                  surface: 'home',
                );
                await profileVM.loadHeaderProfile();
                if (!context.mounted) return;
                await saved.refresh();
                AppLogger.i(
                  'home_refresh_succeeded',
                  tag: 'HomeUI',
                  json: {'surface': 'home'},
                );
              } on Exception catch (error, stackTrace) {
                AppLogger.e(
                  'home_refresh_failed',
                  tag: 'HomeUI',
                  error: error,
                  stackTrace: stackTrace,
                );
              }
            },
            child: CustomScrollView(
              slivers: [
                // --- Custom Header Section ---
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
                        // 1. User Info & Bell — wrapped in Semantics for a11y
                        Semantics(
                          label: 'Home screen greeting',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SignedAvatar(
                                    storagePathOrUrl: profileVM.avatarUrl,
                                    size: 52,
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.r16,
                                    ),
                                    // Use semantic token for theme-aware border
                                    borderColor: colorScheme.cardBorder,
                                    borderWidth: 2,
                                  ),
                                  const SizedBox(width: AppDimens.p12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getGreeting(),
                                        style: AppTypography.bodySmall.copyWith(
                                          color: colorScheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        profileVM.fullName ?? 'Guest',
                                        style: AppTypography.h4.copyWith(
                                          color: colorScheme.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const NotificationBadgeButton(),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimens.p24),

                        // 2. Search & Filter
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                fieldKey: HomeScreen.searchFieldKey,
                                hintText: 'Search amazing projects...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: colorScheme.textSecondary,
                                ),
                                onChanged: filterController.searchTasks,
                              ),
                            ),
                            const SizedBox(width: AppDimens.p12),

                            /// Filter button — opens the filters modal with
                            /// haptic feedback and scale-down press effect.
                            ScaleButton(
                              key: HomeScreen.filterButtonKey,
                              onPressed: () {
                                // Haptic tap before showing modal — curveSpring for delight
                                AppInteractionStates.hapticTap();
                                AppLogger.d(
                                  'home_filters_opened',
                                  tag: 'HomeUI',
                                  json: {'surface': 'home'},
                                );
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const FiltersModal(),
                                );
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.teal,
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.r14,
                                  ),
                                  // Use elevation token instead of hardcoded teal shadow
                                  boxShadow: AppDecorations.elevation(
                                    1,
                                    isDark: colorScheme.isDark,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.filter_list,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.p24),

                        // 3. Discovery mode chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              _buildDiscoveryModeChip(
                                context,
                                key: HomeScreen.discoveryAllWorkKey,
                                metadata: _metadataForMode(
                                  _HomeDiscoveryMode.allWork,
                                ),
                              ),
                              _buildDiscoveryModeChip(
                                context,
                                key: HomeScreen.discoveryBookingsKey,
                                metadata: _metadataForMode(
                                  _HomeDiscoveryMode.bookings,
                                ),
                              ),
                              _buildDiscoveryModeChip(
                                context,
                                key: HomeScreen.discoveryTendersKey,
                                metadata: _metadataForMode(
                                  _HomeDiscoveryMode.tenders,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimens.p16),

                        // 4. Categories
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              _buildCategoryChip(
                                context,
                                label: 'All',
                                isSelected:
                                    filterController.selectedCategory == '',
                                onTap: () =>
                                    filterController.filterByCategory(''),
                              ),
                              ...taskCategories.map((category) {
                                return _buildCategoryChip(
                                  context,
                                  label: category,
                                  isSelected:
                                      filterController.selectedCategory ==
                                      category,
                                  onTap: () => filterController
                                      .filterByCategory(category),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Task feed section — DiscoveryTaskSliver is a sliver
                // widget and cannot be wrapped with Semantics directly
                // inside a CustomScrollView (slivers require RenderSliver
                // children). Individual cards have their own Semantics.
                DiscoveryTaskSliver(
                  surface: 'home',
                  tasks: visibleTasks,
                  isInitialLoading: homeViewModel.isLoading,
                  isLoadingMore: homeViewModel.isLoadingMore,
                  hasMore: homeViewModel.hasMore,
                  onLoadMore: () => homeViewModel.loadMoreTasks(
                    filterController: filterController,
                    surface: 'home',
                  ),
                  emptyTitle: selectedModeMetadata.emptyTitle,
                  emptyIcon: selectedModeMetadata.icon,
                  taskBuilder: (context, task) {
                    return TaskCard(
                      task: task,
                      onTap: () {
                        AppLogger.d(
                          'home_task_opened',
                          tag: 'HomeUI',
                          json: {
                            'surface': 'home',
                            'task_id': task.id,
                            'task_type': task.taskType.name,
                          },
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                widget.taskDetailsScreenBuilder?.call(task) ??
                                TaskDetailsScreen(task: task),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Task> _tasksForMode(List<Task> tasks, _HomeDiscoveryMode mode) {
    switch (mode) {
      case _HomeDiscoveryMode.allWork:
        return tasks;
      case _HomeDiscoveryMode.bookings:
        return tasks.where((task) => task.isBooking == true).toList();
      case _HomeDiscoveryMode.tenders:
        return tasks.where((task) => task.isTender == true).toList();
    }
  }

  ({
    _HomeDiscoveryMode mode,
    String label,
    String semanticLabel,
    IconData icon,
    String emptyTitle,
  })
  _metadataForMode(_HomeDiscoveryMode mode) {
    switch (mode) {
      case _HomeDiscoveryMode.allWork:
        return (
          mode: mode,
          label: 'All Work',
          semanticLabel: 'Discovery mode: All Work',
          icon: Icons.work_outline,
          emptyTitle: 'No tasks found',
        );
      case _HomeDiscoveryMode.bookings:
        return (
          mode: mode,
          label: 'Bookings',
          semanticLabel: 'Discovery mode: Bookings',
          icon: Icons.calendar_today_outlined,
          emptyTitle: 'No booking services',
        );
      case _HomeDiscoveryMode.tenders:
        return (
          mode: mode,
          label: 'Tenders',
          semanticLabel: 'Discovery mode: Tenders',
          icon: Icons.assignment_outlined,
          emptyTitle: 'No active tenders',
        );
    }
  }

  /// Builds the Home discovery mode chip below search.
  ///
  /// It uses the same solid token family as category chips so the new entry
  /// points feel native to Home instead of becoming a second navigation bar.
  Widget _buildDiscoveryModeChip(
    BuildContext context, {
    required Key key,
    required ({
      _HomeDiscoveryMode mode,
      String label,
      String semanticLabel,
      IconData icon,
      String emptyTitle,
    })
    metadata,
  }) {
    final colorScheme = context.colorScheme;
    final isSelected = _selectedDiscoveryMode == metadata.mode;
    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.p8),
      child: Semantics(
        selected: isSelected,
        label: metadata.semanticLabel,
        button: true,
        child: GestureDetector(
          key: key,
          onTap: () {
            AppInteractionStates.hapticSelection();
            if (isSelected) {
              AppLogger.d(
                'home_discovery_mode_reselected',
                tag: 'HomeUI',
                json: {'surface': 'home', 'mode': metadata.mode.name},
              );
              return;
            }
            AppLogger.d(
              'home_discovery_mode_changed',
              tag: 'HomeUI',
              json: {'surface': 'home', 'mode': metadata.mode.name},
            );
            setState(() => _selectedDiscoveryMode = metadata.mode);
          },
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curveStandard,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p14,
              vertical: AppDimens.p10,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.teal : colorScheme.inputBackground,
              borderRadius: BorderRadius.circular(AppDimens.r12),
              border: Border.all(
                color: isSelected ? AppColors.teal : colorScheme.inputBorder,
              ),
              boxShadow: isSelected
                  ? AppDecorations.elevation(1, isDark: colorScheme.isDark)
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  metadata.icon,
                  size: AppDimens.iconSizeSmall,
                  color: isSelected ? AppColors.offWhite : colorScheme.text,
                ),
                const SizedBox(width: AppDimens.p8),
                Text(
                  metadata.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.offWhite : colorScheme.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single category filter chip with selection animation and haptics.
  ///
  /// Uses [AppMotion.fast] + [AppMotion.curveStandard] for the state transition
  /// and [AppDecorations.elevation] instead of a hardcoded teal shadow.
  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.p8),
      // Semantics wrapper so screen readers announce selection state
      child: Semantics(
        selected: isSelected,
        label: 'Category: $label',
        child: GestureDetector(
          onTap: () {
            // Haptic selection click for chip toggle — selection, not tap
            AppInteractionStates.hapticSelection();
            AppLogger.d(
              'home_chip_haptic',
              tag: 'HomeScreen',
              json: {'label': label},
            );
            onTap();
          },
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curveStandard,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p16,
              vertical: AppDimens.p10,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.teal : colorScheme.inputBackground,
              borderRadius: BorderRadius.circular(AppDimens.r12),
              border: Border.all(
                color: isSelected ? AppColors.teal : colorScheme.inputBorder,
              ),
              // Use elevation token instead of hardcoded teal shadow
              boxShadow: isSelected
                  ? AppDecorations.elevation(1, isDark: colorScheme.isDark)
                  : [],
            ),
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.offWhite : colorScheme.text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns a contextual greeting for the current local time.
  ///
  /// This keeps the header message aligned with morning/afternoon/evening
  /// instead of always rendering a static greeting.
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 18) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }
}
