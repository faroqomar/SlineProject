import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';

/// SavedTasksScreen (MVVM)
/// Lists tasks bookmarked by the current user with full task details.
class SavedTasksScreen extends StatefulWidget {
  const SavedTasksScreen({super.key});

  @override
  State<SavedTasksScreen> createState() => _SavedTasksScreenState();
}

class _SavedTasksScreenState extends State<SavedTasksScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.d('saved_tasks_screen_loaded', tag: 'SavedTasksScreen');
    // VM is now global, we just refresh it on enter if needed, or rely on auto-sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Optional: force refresh when screen opens
      context.read<SavedTasksViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _SavedTasksView();
  }
}

class _SavedTasksView extends StatelessWidget {
  const _SavedTasksView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavedTasksViewModel>();
    final colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Semantics(
      label: 'Saved tasks screen',
      child: Scaffold(
        backgroundColor: colorScheme
            .phoneBackground, // Or transparent if global bg is visible
        body: Stack(
          children: [
            // Gradient Background (if needed, or rely on phoneBackground)
            CustomScrollView(
              slivers: [
                // --- Header ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppDimens.p24,
                      topPadding + AppDimens.p24,
                      AppDimens.p24,
                      AppDimens.p16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button — circular container with border.
                        // Semantics announces purpose for screen readers.
                        Semantics(
                          label: 'Back',
                          button: true,
                          child: ScaleButton(
                            onPressed: () => Navigator.pop(context),
                            child: Container(
                              // AppDimens.touchTarget (48) meets the minimum recommended touch target
                              width: AppDimens.touchTarget,
                              height: AppDimens.touchTarget,
                              decoration: BoxDecoration(
                                color: colorScheme.cardBackground,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.cardBorder,
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                color: colorScheme.text,
                                size: AppDimens.iconSmall,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Saved Tasks',
                          style: AppTypography.h4.copyWith(
                            color: colorScheme.text,
                          ),
                        ),
                        // Refresh button with haptic feedback
                        IconButton(
                          icon: Icon(Icons.refresh, color: colorScheme.text),
                          onPressed: () {
                            AppInteractionStates.hapticTap();
                            context.read<SavedTasksViewModel>().refresh();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Content ---
                // Loading state — 5 skeleton task cards for perceived speed
                if (vm.isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p16,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const SkeletonTaskCard(),
                        childCount: 5,
                      ),
                    ),
                  )
                else if (vm.error != null)
                  // Error state — icon in danger-tinted circle + message + retry
                  SliverFillRemaining(
                    child: Center(
                      child: Semantics(
                        label: 'Error loading saved tasks',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Error icon in a tinted circle
                            Container(
                              width: AppDimens.p80,
                              height: AppDimens.p80,
                              decoration: BoxDecoration(
                                color: colorScheme.danger.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: AppDimens.p48,
                                color: colorScheme.danger,
                              ),
                            ),
                            const SizedBox(height: AppDimens.p16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.p24,
                              ),
                              child: Text(
                                vm.error!,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(
                                  color: colorScheme.danger,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimens.p16),
                            // Retry button
                            OutlinedButton(
                              onPressed: () {
                                AppInteractionStates.hapticTap();
                                context.read<SavedTasksViewModel>().refresh();
                              },
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (vm.savedTasks.isEmpty)
                  // Empty state — icon in primary-tinted circle + title + subtitle
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Semantics(
                        label: 'No saved tasks yet',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon in a primary-tinted circle
                            Container(
                              width: AppDimens.p80,
                              height: AppDimens.p80,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.bookmark_border,
                                size: AppDimens.p48,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: AppDimens.p16),
                            Text(
                              'No saved tasks yet',
                              style: AppTypography.h5.copyWith(
                                color: colorScheme.text,
                              ),
                            ),
                            const SizedBox(height: AppDimens.p8),
                            Text(
                              "Browse and save tasks you're interested in",
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.textSecondary,
                              ),
                            ),
                            // CTA button to guide users toward task discovery
                            const SizedBox(height: AppDimens.p24),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/main',
                                  (route) => false,
                                );
                              },
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('Browse Tasks'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.p16,
                      0,
                      AppDimens.p16,
                      AppDimens.p24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final task = vm.savedTasks[index];
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
                      }, childCount: vm.savedTasks.length),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
