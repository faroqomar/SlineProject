import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sline_app/features/saved/controller/saved_tasks_controller.dart';
import 'package:sline_app/features/saved/data/saved_tasks_service.dart';
import 'package:sline_app/features/tasks/presentation/widgets/task_card.dart';
import 'package:sline_app/features/tasks/presentation/task_details_screen.dart';

/// SavedTasksScreen
/// Lists tasks bookmarked by the current user (MVP: shows task IDs).
/// Later we can join with `tasks` to display titles/budgets/etc.
class SavedTasksScreen extends StatelessWidget {
  const SavedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SavedTasksController(service: SavedTasksService())..load(),
      child: const _SavedTasksView(),
    );
  }
}

class _SavedTasksView extends StatelessWidget {
  const _SavedTasksView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SavedTasksController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SavedTasksController>().refresh(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          // Loading state
          if (ctrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (ctrl.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  ctrl.error!,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Empty state
          if (ctrl.savedTasks.isEmpty) {
            return const Center(child: Text('No saved tasks yet.'));
          }

          // Normal state
          final tasks = ctrl.savedTasks;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
