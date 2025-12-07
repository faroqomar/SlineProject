import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/saved/data/saved_tasks_service.dart';
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
  late final SavedTasksViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = SavedTasksViewModel(service: SavedTasksService())..load();
  }

  @override
  void dispose() {
    // Don't dispose VM if provided from parent, but here we create it locally so we should?
    // Actually the previous implementation manually disposed it.
    // However, ChangeNotifierProvider usually handles disposal.
    // But here we are passing .value, so we must dispose manually.
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SavedTasksViewModel>.value(
      value: _vm,
      child: const _SavedTasksView(),
    );
  }
}

class _SavedTasksView extends StatelessWidget {
  const _SavedTasksView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavedTasksViewModel>();
    final AppColorScheme colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground, // Or transparent if global bg is visible
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
                        style: AppTypography.h4.copyWith(color: colorScheme.text),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: colorScheme.text),
                        onPressed: () => context.read<SavedTasksViewModel>().refresh(),
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
                        style: AppTypography.bodySmall.copyWith(color: AppColors.lightRed),
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
                          color: colorScheme.textSecondary.withValues(alpha: 0.5),
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
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = vm.savedTasks[index];
                        return TaskCard(
                          task: task,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
                            );
                          },
                        );
                      },
                      childCount: vm.savedTasks.length,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}