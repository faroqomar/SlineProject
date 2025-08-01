import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/tasks/presentation/widgets/task_card.dart';
import '../controllers/home_controller.dart';
import '../../tasks/presentation/create_task_screen.dart';
import 'package:sline_app/features/tasks/controllers/task_filter_controller.dart';
import 'package:sline_app/shared/constants/categories.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('SLine'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<HomeController>().refresh(
                filterController: context.read<TaskFilterController>(),
              );
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
                context.read<HomeController>().refresh(
                  filterController: context.read<TaskFilterController>(),
                );
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
              await homeController.refresh(filterController: filterController);
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
                            const DropdownMenuItem(value: '', child: Text('All')),
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
                          Icon(Icons.work_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No tasks found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = filterController.filteredTasks[index];
                        return TaskCard(
                          task: task,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Tapped on ${task.title}')),
                            );
                          },
                        );
                      },
                      childCount: filterController.filteredTasks.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
