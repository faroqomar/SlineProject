import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/search/view/widgets/search_result_profile_card.dart';
import 'package:sline_app/features/search/viewmodels/search_view_model.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';

/// Top-level search screen providing task and freelancer search.
///
/// Wraps [_SearchScreenContent] in a [ChangeNotifierProvider] to scope
/// the [SearchViewModel] lifecycle to this screen.
class SearchScreen extends StatelessWidget {
  /// Creates the search route.
  ///
  /// [viewModel] is injectable for widget tests so accessibility and layout
  /// checks do not initialize Supabase-backed search services.
  const SearchScreen({super.key, this.viewModel});

  /// Optional prebuilt ViewModel used by tests or controlled harnesses.
  final SearchViewModel? viewModel;

  @override
  Widget build(BuildContext context) {
    final injectedViewModel = viewModel;
    if (injectedViewModel != null) {
      return ChangeNotifierProvider<SearchViewModel>.value(
        value: injectedViewModel,
        child: const _SearchScreenContent(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(),
      child: const _SearchScreenContent(),
    );
  }
}

/// Internal content widget that holds the search UI state.
///
/// Uses [SearchViewModel] via Provider to drive search input, tab switching,
/// loading/error/empty states, and result lists.
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
    final amber = _amberFor(context);

    // Solid phone background — no gradient overlay needed.
    return Scaffold(
      backgroundColor: amber.page,
      body: SafeArea(
        child: Column(
          children: [
            // Header & Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
              child: Column(
                children: [
                  const SizedBox(height: AppDimens.p16),

                  Semantics(
                    textField: true,
                    label: vm.isTasksTab
                        ? 'Search tasks'
                        : 'Search freelancers',
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: AppTextField(
                        controller: _searchController,
                        hintText:
                            'Search ${vm.isTasksTab ? "tasks" : "freelancers"}...',
                        prefixIcon: Icon(Icons.search, color: amber.textSubtle),
                        onChanged: vm.onSearchChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.p16),
                  // Tab Toggle — switches between Find Work / Find Talent
                  _buildTabToggle(context, vm),
                  const SizedBox(height: AppDimens.p8),
                ],
              ),
            ),

            // Results list, loading skeletons, or empty/error state
            Expanded(child: _buildResultsList(context, vm)),
          ],
        ),
      ),
    );
  }

  /// Builds the Find Work / Find Talent toggle row.
  ///
  /// Uses [AppMotion.fast] for the selection animation and fires
  /// haptic feedback on each tab switch via [AppInteractionStates].
  Widget _buildTabToggle(BuildContext context, SearchViewModel vm) {
    final amber = _amberFor(context);

    return Container(
      padding: const EdgeInsets.all(AppDimens.p4),
      decoration: BoxDecoration(
        color: amber.surface,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: amber.heroRim),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              context,
              label: 'Find Work',
              isSelected: vm.activeTab == SearchTab.findWork,
              onTap: () {
                AppInteractionStates.hapticSelection();
                AppLogger.d('Search tab switched to Find Work');
                vm.setTab(SearchTab.findWork);
              },
            ),
          ),
          Expanded(
            child: _buildTabButton(
              context,
              label: 'Find Talent',
              isSelected: vm.activeTab == SearchTab.findTalent,
              onTap: () {
                AppInteractionStates.hapticSelection();
                AppLogger.d('Search tab switched to Find Talent');
                vm.setTab(SearchTab.findTalent);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds one tab button inside the toggle row.
  ///
  /// Selected tab gets the Amber Dusk action fill with inverse text.
  /// Unselected tab inherits the solid surface with muted text.
  /// Animation uses [AppMotion.fast] with [AppMotion.curveStandard].
  Widget _buildTabButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final amber = _amberFor(context);
    final semanticKey = ValueKey<String>(
      'search_tab_${label.toLowerCase().replaceAll(' ', '_')}',
    );

    return Semantics(
      key: semanticKey,
      button: true,
      selected: isSelected,
      label: 'Search tab: $label',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curveStandard,
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: AppDimens.touchTarget),
          padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
          decoration: BoxDecoration(
            // Selected state uses the Amber Dusk action token; the unselected
            // segment inherits the parent solid surface.
            color: isSelected ? amber.primary : null,
            borderRadius: BorderRadius.circular(AppDimens.r8),
          ),
          child: Text(
            label,
            style: AppTypography.captionBold.copyWith(
              color: isSelected ? amber.textInverse : amber.muted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  /// Builds the appropriate body content based on the current view-model state.
  ///
  /// Handles five states: loading (skeleton cards), error (icon + retry),
  /// initial empty (start typing), no results, and populated results.
  Widget _buildResultsList(BuildContext context, SearchViewModel vm) {
    final amber = _amberFor(context);

    // ── Loading: show skeleton cards matching the active tab ──
    if (vm.isLoading) {
      return ListView(
        padding: const EdgeInsets.all(AppDimens.p16),
        children: vm.isTasksTab
            ? List.generate(5, (_) => const SkeletonTaskCard())
            : List.generate(5, (_) => const SkeletonSearchResultCard()),
      );
    }

    // ── Error: icon-in-circle + message + retry button ──
    if (vm.error != null) {
      return Semantics(
        label: 'Search error',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Danger circle with error icon
                Container(
                  width: AppDimens.emptyStateIconContainer,
                  height: AppDimens.emptyStateIconContainer,
                  decoration: BoxDecoration(
                    color: amber.dangerMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: AppDimens.emptyStateIconSize,
                    color: amber.danger,
                  ),
                ),
                const SizedBox(height: AppDimens.p16),
                Text(
                  vm.error!,
                  style: AppTypography.h5.copyWith(color: amber.text),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.p8),
                Text(
                  'Please try again',
                  style: AppTypography.bodySmall.copyWith(
                    color: amber.textSubtle,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.p24),
                AppButton(
                  onPressed: () {
                    AppLogger.d('Search retry tapped');
                    vm.retry();
                  },
                  text: 'Try Again',
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Initial empty: user hasn't typed anything yet ──
    if (vm.query.isEmpty && vm.tasks.isEmpty && vm.profiles.isEmpty) {
      return Semantics(
        label: 'Start typing to search',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Primary circle with search icon
                Container(
                  width: AppDimens.emptyStateIconContainer,
                  height: AppDimens.emptyStateIconContainer,
                  decoration: BoxDecoration(
                    color: amber.activeGlow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search,
                    size: AppDimens.emptyStateIconSize,
                    color: amber.primary,
                  ),
                ),
                const SizedBox(height: AppDimens.p16),
                Text(
                  'Start typing to search',
                  style: AppTypography.h5.copyWith(color: amber.text),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.p8),
                Text(
                  'Find tasks or freelancers',
                  style: AppTypography.bodySmall.copyWith(
                    color: amber.textSubtle,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Populated results ──
    if (vm.isTasksTab) {
      if (vm.tasks.isEmpty) {
        return _buildNoResults(context);
      }
      return ListView.separated(
        padding: const EdgeInsets.all(AppDimens.p16),
        itemCount: vm.tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimens.p12),
        itemBuilder: (context, index) {
          final task = vm.tasks[index];
          return TaskCard(
            task: task,
            onTap: () {
              AppLogger.i('Search: tapped task ${task.id}');
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
        separatorBuilder: (_, _) => const SizedBox(height: AppDimens.p12),
        itemBuilder: (context, index) {
          final profile = vm.profiles[index];
          return SearchResultProfileCard(
            profile: profile,
            onTap: () {
              AppLogger.i('Search: tapped profile ${profile.id}');
              // Navigator.pushNamed(context, '/profile/${profile.id}');
            },
          );
        },
      );
    }
  }

  /// Builds the "no results found" empty state.
  ///
  /// Shown when a search query returns zero matches. Uses a muted icon
  /// in a circle with guidance text to try different keywords.
  Widget _buildNoResults(BuildContext context) {
    final amber = _amberFor(context);

    return Semantics(
      label: 'No search results',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Primary circle with search-off icon
              Container(
                width: AppDimens.emptyStateIconContainer,
                height: AppDimens.emptyStateIconContainer,
                decoration: BoxDecoration(
                  color: amber.activeGlow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off,
                  size: AppDimens.emptyStateIconSize,
                  color: amber.primary,
                ),
              ),
              const SizedBox(height: AppDimens.p16),
              Text(
                'No results found',
                style: AppTypography.h5.copyWith(color: amber.text),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.p8),
              Text(
                'Try different keywords or filters',
                style: AppTypography.bodySmall.copyWith(
                  color: amber.textSubtle,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  AmberDuskColorScheme _amberFor(BuildContext context) => context.amberColors;
}
