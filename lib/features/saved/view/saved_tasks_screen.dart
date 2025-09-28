import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/saved/data/saved_tasks_service.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SavedTasksViewModel>().refresh(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          // Loading state
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (vm.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  vm.error!,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Empty state
          if (vm.savedTasks.isEmpty) {
            return const Center(child: Text('No saved tasks yet.'));
          }

          // Normal state
          final tasks = vm.savedTasks;
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
