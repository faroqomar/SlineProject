import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
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
    // VM is now global, we just refresh it on enter if needed, or rely on auto-sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Optional: force refresh when screen opens
      context.read<SavedTasksViewModel>().load();
    });
  }

  @override
  void dispose() {
    super.dispose();
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

    return Scaffold(
      backgroundColor:
          colorScheme.phoneBackground, // Or transparent if global bg is visible
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
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: colorScheme.cardBackground,
                          child: BackButton(color: colorScheme.text),
                        ),
                      ),
                      Text(
                        'Saved Tasks',
                        style: AppTypography.h4.copyWith(
                          color: colorScheme.text,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: colorScheme.text),
                        onPressed: () =>
                            context.read<SavedTasksViewModel>().refresh(),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Content ---
              if (vm.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (vm.error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        vm.error!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.lightRed,
                        ),
                      ),
                    ),
                  ),
                )
              else if (vm.savedTasks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 64,
                          color: colorScheme.textSecondary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No saved tasks yet',
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
    );
  }
}
