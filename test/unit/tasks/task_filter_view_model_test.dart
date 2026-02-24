import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

Task _task({
  required String id,
  required String title,
  required String description,
  required double budget,
  String? category,
  String? categoryName,
  DateTime? createdAt,
}) {
  return Task(
    id: id,
    title: title,
    description: description,
    budget: budget,
    userId: 'user-1',
    status: TaskStatus.open,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
    category: category,
    categoryName: categoryName,
  );
}

List<String> _ids(Iterable<Task> tasks) =>
    tasks.map((task) => task.id).toList();

void main() {
  group('TaskFilterViewModel T06-T09', () {
    late TaskFilterViewModel viewModel;

    setUp(() {
      viewModel = TaskFilterViewModel();
    });

    test('T06 search filters title and description', () {
      final tasks = <Task>[
        _task(
          id: 't1',
          title: 'Design logo',
          description: 'Brand refresh for storefront',
          budget: 100,
        ),
        _task(
          id: 't2',
          title: 'Landing page cleanup',
          description: 'Need DESIGN system polish',
          budget: 120,
        ),
        _task(
          id: 't3',
          title: 'Mobile app audit',
          description: 'Include design recommendations',
          budget: 150,
        ),
        _task(
          id: 't4',
          title: 'Database indexing',
          description: 'Optimize query latency',
          budget: 200,
        ),
      ];

      viewModel.setTasks(tasks);
      viewModel.searchTasks('dEsIgN');

      expect(_ids(viewModel.filteredTasks), <String>['t1', 't2', 't3']);
      expect(_ids(viewModel.filteredTasks), isNot(contains('t4')));
    });

    test('T07 category matches category or categoryName', () {
      final tasks = <Task>[
        _task(
          id: 'legacy-only',
          title: 'Logo refresh',
          description: 'Legacy category field only',
          budget: 100,
          category: 'Design',
          categoryName: null,
        ),
        _task(
          id: 'name-only',
          title: 'UX review',
          description: 'Resolved categoryName only',
          budget: 120,
          category: null,
          categoryName: 'Design',
        ),
        _task(
          id: 'both-match',
          title: 'Brand guide',
          description: 'Both fields match',
          budget: 140,
          category: 'Design',
          categoryName: 'Design',
        ),
        _task(
          id: 'non-match',
          title: 'API refactor',
          description: 'Different category',
          budget: 160,
          category: 'Development',
          categoryName: 'Development',
        ),
      ];

      viewModel.setTasks(tasks);
      viewModel.filterByCategory('Design');

      expect(_ids(viewModel.filteredTasks), <String>[
        'legacy-only',
        'name-only',
        'both-match',
      ]);
      expect(_ids(viewModel.filteredTasks), isNot(contains('non-match')));
    });

    test('T08 min/max budget filter works', () {
      final tasks = <Task>[
        _task(
          id: 'b50',
          title: 'Task 50',
          description: 'Below range',
          budget: 50,
        ),
        _task(
          id: 'b100',
          title: 'Task 100',
          description: 'Min boundary',
          budget: 100,
        ),
        _task(
          id: 'b150',
          title: 'Task 150',
          description: 'Mid range',
          budget: 150,
        ),
        _task(
          id: 'b200',
          title: 'Task 200',
          description: 'Max boundary',
          budget: 200,
        ),
        _task(
          id: 'b250',
          title: 'Task 250',
          description: 'Above range',
          budget: 250,
        ),
      ];

      viewModel.setTasks(tasks);
      viewModel.applyAdvancedFilters(minBudget: 100, maxBudget: 200);

      expect(_ids(viewModel.filteredTasks), <String>['b100', 'b150', 'b200']);
      expect(_ids(viewModel.filteredTasks), isNot(contains('b50')));
      expect(_ids(viewModel.filteredTasks), isNot(contains('b250')));
    });

    test('T09 clearFilters resets query/category/sort/budgets', () {
      final tasks = <Task>[
        _task(
          id: 't1',
          title: 'Design logo',
          description: 'Brand refresh',
          budget: 100,
          category: 'Design',
        ),
        _task(
          id: 't2',
          title: 'Website redesign',
          description: 'UI polish and design cleanup',
          budget: 150,
          categoryName: 'Design',
        ),
        _task(
          id: 't3',
          title: 'Backend cleanup',
          description: 'No design work',
          budget: 250,
          category: 'Development',
        ),
      ];

      viewModel.setTasks(tasks);
      viewModel.searchTasks('design');
      viewModel.filterByCategory('Design');
      viewModel.applyAdvancedFilters(
        minBudget: 100,
        maxBudget: 160,
        deliveryTimes: const ['3 days'],
        sellerLevels: const ['Level 2'],
        sortBy: 'Price: High to Low',
      );

      expect(viewModel.filteredTasks.length, lessThan(tasks.length));

      viewModel.clearFilters();

      expect(viewModel.searchQuery, '');
      expect(viewModel.selectedCategory, '');
      expect(viewModel.minBudget, isNull);
      expect(viewModel.maxBudget, isNull);
      expect(viewModel.deliveryTimes, isEmpty);
      expect(viewModel.sellerLevels, isEmpty);
      expect(viewModel.sortBy, 'Relevance');
      expect(_ids(viewModel.filteredTasks), _ids(tasks));
    });
  });
}
