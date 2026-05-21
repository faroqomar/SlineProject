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
  DateTime? deadline,
  TaskType taskType = TaskType.tender,
  Map<String, dynamic>? packages,
  String? authorSellerLevel,
}) {
  return Task(
    id: id,
    title: title,
    description: description,
    budget: budget,
    userId: 'user-1',
    status: TaskStatus.open,
    taskType: taskType,
    createdAt: createdAt ?? DateTime.utc(2026),
    deadline: deadline,
    category: category,
    categoryName: categoryName,
    packages: packages,
    authorSellerLevel: authorSellerLevel,
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

      viewModel
        ..setTasks(tasks)
        ..searchTasks('dEsIgN');

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
        ),
        _task(
          id: 'name-only',
          title: 'UX review',
          description: 'Resolved categoryName only',
          budget: 120,
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

      viewModel
        ..setTasks(tasks)
        ..filterByCategory('Design');

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

      viewModel
        ..setTasks(tasks)
        ..applyAdvancedFilters(minBudget: 100, maxBudget: 200);

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

      viewModel
        ..setTasks(tasks)
        ..searchTasks('design')
        ..filterByCategory('Design')
        ..applyAdvancedFilters(
          minBudget: 100,
          maxBudget: 160,
          deliveryTimes: const [TaskFilterViewModel.deliveryUpTo3Days],
          sellerLevels: const [TaskFilterViewModel.sellerLevel2],
          sortBy: TaskFilterViewModel.sortPriceHighToLow,
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

    test(
      'T10 delivery filter derives from packages, deadlines, and anytime',
      () {
        final now = DateTime.now().toUtc();
        final tasks = <Task>[
          _task(
            id: 'booking-24h',
            title: 'Fast logo',
            description: 'One-day turnaround',
            budget: 100,
            taskType: TaskType.booking,
            packages: {
              'Basic': {'delivery': '1'},
              'Premium': {'delivery': '3'},
            },
          ),
          _task(
            id: 'booking-3d',
            title: 'Short site package',
            description: 'Three-day turnaround',
            budget: 150,
            taskType: TaskType.booking,
            packages: {
              'Basic': {'delivery': 3},
            },
          ),
          _task(
            id: 'deadline-6d',
            title: 'Content sprint',
            description: 'Deadline-based delivery',
            budget: 200,
            deadline: now.add(const Duration(days: 6)),
          ),
          _task(
            id: 'expired',
            title: 'Expired task',
            description: 'Past deadline should not match fast buckets',
            budget: 80,
            deadline: now.subtract(const Duration(hours: 2)),
          ),
          _task(
            id: 'anytime',
            title: 'Open-ended consulting',
            description: 'No delivery estimate',
            budget: 250,
          ),
        ];

        viewModel
          ..setTasks(tasks)
          ..applyAdvancedFilters(
            deliveryTimes: const [TaskFilterViewModel.deliveryUpTo24h],
          );
        expect(_ids(viewModel.filteredTasks), <String>['booking-24h']);

        viewModel.applyAdvancedFilters(
          deliveryTimes: const [TaskFilterViewModel.deliveryUpTo3Days],
        );
        expect(_ids(viewModel.filteredTasks), <String>['booking-3d']);

        viewModel.applyAdvancedFilters(
          deliveryTimes: const [TaskFilterViewModel.deliveryUpTo7Days],
        );
        expect(_ids(viewModel.filteredTasks), <String>['deadline-6d']);

        viewModel.applyAdvancedFilters(
          deliveryTimes: const [TaskFilterViewModel.deliveryAnytime],
        );
        expect(
          _ids(viewModel.filteredTasks),
          containsAll(<String>['anytime', 'expired']),
        );
        expect(_ids(viewModel.filteredTasks), isNot(contains('booking-24h')));
      },
    );

    test(
      'T11 seller-level filter excludes tenders and matches canonical levels',
      () {
        final tasks = <Task>[
          _task(
            id: 'booking-top-rated',
            title: 'Senior motion package',
            description: 'Top seller booking',
            budget: 300,
            taskType: TaskType.booking,
            authorSellerLevel: 'top_rated',
          ),
          _task(
            id: 'booking-level-2',
            title: 'Level 2 booking',
            description: 'Solid seller booking',
            budget: 180,
            taskType: TaskType.booking,
            authorSellerLevel: 'level_2',
          ),
          _task(
            id: 'tender-top-rated',
            title: 'Top-rated tender',
            description: 'Should be excluded when seller filter is active',
            budget: 140,
            authorSellerLevel: 'top_rated',
          ),
        ];

        viewModel
          ..setTasks(tasks)
          ..applyAdvancedFilters(
            sellerLevels: const [TaskFilterViewModel.sellerTopRated],
          );

        expect(_ids(viewModel.filteredTasks), <String>['booking-top-rated']);
        expect(
          _ids(viewModel.filteredTasks),
          isNot(contains('tender-top-rated')),
        );
      },
    );

    test(
      'T12 combined seller-level and budget filters intersect correctly',
      () {
        final tasks = <Task>[
          _task(
            id: 'booking-keep',
            title: 'Qualified booking',
            description: 'Matches seller level and budget',
            budget: 220,
            taskType: TaskType.booking,
            authorSellerLevel: 'level_2',
          ),
          _task(
            id: 'booking-budget-miss',
            title: 'Too expensive',
            description: 'Matches seller level only',
            budget: 500,
            taskType: TaskType.booking,
            authorSellerLevel: 'level_2',
          ),
          _task(
            id: 'booking-seller-miss',
            title: 'Wrong level',
            description: 'Matches budget only',
            budget: 210,
            taskType: TaskType.booking,
            authorSellerLevel: 'new_seller',
          ),
        ];

        viewModel
          ..setTasks(tasks)
          ..applyAdvancedFilters(
            minBudget: 200,
            maxBudget: 300,
            sellerLevels: const [TaskFilterViewModel.sellerLevel2],
          );

        expect(_ids(viewModel.filteredTasks), <String>['booking-keep']);
      },
    );
  });
}
