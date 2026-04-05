import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/categories/viewmodels/categories_view_model.dart';

/// CategoriesScreen
/// MVVM UI to browse and search categories.
/// This screen is not yet wired to navigation; you can push it manually
/// or add it to a tab/route as needed.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final CategoriesViewModel _vm;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = CategoriesViewModel();
    // Initial load without search filter
    _vm.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CategoriesViewModel>.value(
      value: _vm,
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoriesViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Search field
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search categories',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: vm.setSearchQuery,
            ),
            const SizedBox(height: 16),

            if (vm.isLoading) ...[
              const SizedBox(height: 120),
              const Center(child: CircularProgressIndicator()),
            ] else if (vm.error != null) ...[
              const SizedBox(height: 120),
              Center(
                child: Text(
                  vm.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ] else ...[
              if (vm.items.isEmpty) ...[
                const SizedBox(height: 120),
                const Center(child: Text('No categories found.')),
              ] else ...[
                // Simple list of categories
                ...vm.items.map(
                  (c) => ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        c.name.isNotEmpty
                            ? c.name.substring(0, 1).toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(c.name),
                    subtitle: Text(c.id),
                    onTap: () {
                      // TODO: handle selection/navigation if needed
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
