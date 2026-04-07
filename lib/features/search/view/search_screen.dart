import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
// Removed unused AppCardContainer import
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/search/view/widgets/search_result_profile_card.dart';
import 'package:sline_app/features/search/viewmodels/search_view_model.dart';
// Removed missing dashboard_background import
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(),
      child: const _SearchScreenContent(),
    );
  }
}

class _SearchScreenContent extends StatefulWidget {
  const _SearchScreenContent();

  @override
  State<_SearchScreenContent> createState() => _SearchScreenContentState();
}

class _SearchScreenContentState extends State<_SearchScreenContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent, // For background gradient
      body: Stack(
        children: [
          // Background Gradient (Dashboard style fallback)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.colorScheme.background,
                  context.colorScheme.background.withValues(alpha: 0.8),
                  context.colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header & Search Input
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p16,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppDimens.p16),
                      
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: AppTextField(
                          controller: _searchController,
                          hintText:
                              'Search ${vm.isTasksTab ? "tasks" : "freelancers"}...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: context.colorScheme.textSecondary,
                          ),
                          onChanged: vm.onSearchChanged,
                        ),
                      ),
                      const SizedBox(height: AppDimens.p16),
                      // Tab Toggle
                      _buildTabToggle(context, vm),
                      const SizedBox(height: AppDimens.p8),
                    ],
                  ),
                ),

                // Results
                Expanded(child: _buildResultsList(context, vm)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle(BuildContext context, SearchViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colorScheme.cardBackground.withValues(
          alpha: 0.3,
        ), // Replaced surface
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(
          color: context.colorScheme.cardBackground.withValues(
            alpha: 0.5,
          ), // Replaced surface
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              context,
              label: 'Find Work',
              isSelected: vm.activeTab == SearchTab.findWork,
              onTap: () => vm.setTab(SearchTab.findWork),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              context,
              label: 'Find Talent',
              isSelected: vm.activeTab == SearchTab.findTalent,
              onTap: () => vm.setTab(SearchTab.findTalent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
        decoration: BoxDecoration(
          color: isSelected ? context.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.r8),
        ),
        child: Text(
          label,
          // Replaced labelLarge with bodyMedium (bolded) as labelLarge was undefined
          style: AppTypography.bodyMedium.copyWith(
            color: isSelected
                ? AppColors.white
                : context.colorScheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, SearchViewModel vm) {
    if (vm.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.colorScheme.primary),
      );
    }

    if (vm.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: AppDimens.p16),
            Text(vm.error!, style: AppTypography.bodyLarge),
            TextButton(onPressed: vm.retry, child: const Text('Try Again')),
          ],
        ),
      );
    }

    if (vm.query.isEmpty && vm.tasks.isEmpty && vm.profiles.isEmpty) {
      // Empty State (Initial)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              vm.isTasksTab ? Icons.work_outline : Icons.people_outline,
              size: 64,
              color: context.colorScheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimens.p16),
            Text(
              'Start typing to search...',
              style: AppTypography.bodyLarge.copyWith(
                color: context.colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (vm.isTasksTab) {
      if (vm.tasks.isEmpty) {
        return _buildNoResults(context);
      }
      return ListView.separated(
        padding: const EdgeInsets.all(AppDimens.p16),
        itemCount: vm.tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.p12),
        itemBuilder: (context, index) {
          final task = vm.tasks[index];
          return TaskCard(
            task: task,
            onTap: () {
              AppLogger.i('Tapped task: ${task.id}');
              // Navigator.pushNamed(context, '/task/${task.id}');
            },
          );
        },
      );
    } else {
      if (vm.profiles.isEmpty) {
        return _buildNoResults(context);
      }
      return ListView.separated(
        padding: const EdgeInsets.all(AppDimens.p16),
        itemCount: vm.profiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.p12),
        itemBuilder: (context, index) {
          final profile = vm.profiles[index];
          return SearchResultProfileCard(
            profile: profile,
            onTap: () {
              AppLogger.i('Tapped profile: ${profile.id}');
              // Navigator.pushNamed(context, '/profile/${profile.id}');
            },
          );
        },
      );
    }
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: context.colorScheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimens.p16),
          Text(
            'No results found',
            style: AppTypography.bodyLarge.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
