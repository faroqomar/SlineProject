import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/home/view/widgets/filters_modal.dart';
import 'package:sline_app/features/notifications/view/notifications_modal.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';
import 'package:sline_app/features/saved/data/saved_tasks_service.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';
import 'package:sline_app/shared/constants/categories.dart';
import '../viewmodels/home_view_model.dart';

/// Home screen - main dashboard for the app (MVVM) with Glassmorphism design.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load featured tasks and notify filter controller when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadFeaturedTasks(
            filterController: context.read<TaskFilterViewModel>(),
          );
      // Ensure profile is loaded for the header
      context.read<ProfileViewModel>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    return ChangeNotifierProvider(
      create: (_) {
        final vm = SavedTasksViewModel(service: SavedTasksService());
        // Load saved tasks cache on first build
        vm.load();
        return vm;
      },
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent, // Allow main gradient to show through
          body: Consumer3<HomeViewModel, TaskFilterViewModel, ProfileViewModel>(
            builder: (context, homeViewModel, filterController, profileVM, child) {
              // Safe Area padding for the header
              final topPadding = MediaQuery.of(context).padding.top;

              return RefreshIndicator(
                onRefresh: () async {
                  final saved = context.read<SavedTasksViewModel>();
                  await homeViewModel.refresh(
                    filterController: filterController,
                  );
                  await profileVM.loadProfile();
                  if (!context.mounted) return;
                  await saved.refresh();
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
                            // 1. User Info & Bell
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SignedAvatar(
                                      storagePathOrUrl: profileVM.avatarUrl,
                                      size: 52,
                                      borderRadius: BorderRadius.circular(AppDimens.r16),
                                      borderColor: AppColors.offWhite.withValues(alpha: 0.2),
                                      borderWidth: 2,
                                    ),
                                    const SizedBox(width: AppDimens.p12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Good Morning 👋',
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
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => const NotificationsModal(),
                                    );
                                  },
                                  child: GlassContainer(
                                    borderRadius: BorderRadius.circular(AppDimens.r16),
                                    padding: const EdgeInsets.all(AppDimens.p12),
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      color: colorScheme.text,
                                      size: AppDimens.p24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimens.p24),

                            // 2. Search & Filter
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    hintText: 'Search amazing projects...',
                                    prefixIcon: Icon(Icons.search, color: colorScheme.textSecondary),
                                    onChanged: filterController.searchTasks,
                                  ),
                                ),
                                const SizedBox(width: AppDimens.p12),
                                GestureDetector(
                                  onTap: () {
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
                                      borderRadius: BorderRadius.circular(AppDimens.r14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.teal.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.filter_list, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimens.p24),

                            // 3. Categories
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              child: Row(
                                children: [
                                  _buildCategoryChip(
                                    context,
                                    label: '✨ All',
                                    isSelected: filterController.selectedCategory == '',
                                    onTap: () => filterController.filterByCategory(''),
                                  ),
                                  ...taskCategories.map((category) {
                                    // Add emoji based on category
                                    String label = category;
                                    if (category == 'Design') {
                                      label = '🎨 Design';
                                    } else if (category == 'Development') {
                                      label = '💻 Dev';
                                    } else if (category == 'Writing') {
                                      label = '✍️ Writing';
                                    } else if (category == 'Marketing') {
                                      label = '🎯 Marketing';
                                    }
                                    
                                    return _buildCategoryChip(
                                      context,
                                      label: label,
                                      isSelected: filterController.selectedCategory == category,
                                      onTap: () => filterController.filterByCategory(category),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Task List ---
                    if (homeViewModel.isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (filterController.filteredTasks.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 64,
                                color: colorScheme.textSecondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks found',
                                style: AppTypography.h5.copyWith(
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.p16,
                          0,
                          AppDimens.p16,
                          AppDimens.p100, // Bottom padding for nav bar
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final task = filterController.filteredTasks[index];
                              return TaskCard(
                                task: task,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TaskDetailsScreen(task: task),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: filterController.filteredTasks.length,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final AppColorScheme colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.p8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p16,
            vertical: AppDimens.p10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.teal
                : colorScheme.inputBackground, // Glass-like
            borderRadius: BorderRadius.circular(AppDimens.r12),
            border: Border.all(
              color: isSelected ? AppColors.teal : colorScheme.inputBorder,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
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
    );
  }
}
