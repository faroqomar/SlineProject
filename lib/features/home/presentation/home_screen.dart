import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/tasks/presentation/widgets/task_card.dart';
import '../controllers/home_controller.dart';
import '../../tasks/presentation/create_task_screen.dart';
import 'package:sline_app/features/tasks/controllers/task_filter_controller.dart';
import 'package:sline_app/shared/constants/categories.dart';
import 'package:sline_app/features/tasks/presentation/task_details_screen.dart';
import 'package:sline_app/features/saved/controller/saved_tasks_controller.dart';
import 'package:sline_app/features/saved/data/saved_tasks_service.dart';
import 'package:sline_app/features/saved/presentation/screens/saved_tasks_screen.dart';

/// Home screen - main dashboard for the app
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
      context.read<HomeController>().loadFeaturedTasks(
        filterController: context.read<TaskFilterController>(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final c = SavedTasksController(service: SavedTasksService());
        // Load saved tasks cache on first build
        c.load();
        return c;
      },
      // IMPORTANT: use `builder` (not `child`) so descendants use the scoped context
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SLine'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Saved Tasks',
                icon: const Icon(Icons.bookmark_outline),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedTasksScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  // Refresh tasks
                  await context.read<HomeController>().refresh(
                    filterController: context.read<TaskFilterController>(),
                  );
                  // Refresh saved cache to keep icons in sync
                  if (!context.mounted) return;
                  await context.read<SavedTasksController>().refresh();
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
                  );
                  if (result == true) {
                    await context.read<HomeController>().refresh(
                      filterController: context.read<TaskFilterController>(),
                    );
                    if (!context.mounted) return;
                    await context.read<SavedTasksController>().refresh();
                  }
                },
              ),
            ],
          ),
          body: Consumer2<HomeController, TaskFilterController>(
            builder: (context, homeController, filterController, child) {
              if (homeController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await homeController.refresh(
                    filterController: filterController,
                  );
                  if (!context.mounted) return;
                  await context.read<SavedTasksController>().refresh();
                },
                child: CustomScrollView(
                  slivers: [
                    // Search and filter section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Search tasks...',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: filterController.searchTasks,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Filter by Category',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('All'),
                                ),
                                ...taskCategories.map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  filterController.filterByCategory(value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Featured Tasks',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (filterController.filteredTasks.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No tasks found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
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
                        }, childCount: filterController.filteredTasks.length),
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
}
