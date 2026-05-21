import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/home/viewmodels/home_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

class _MockTaskService extends Mock implements TaskService {}

Task _task(String id, DateTime createdAt) {
  return Task(
    id: id,
    title: 'Task $id',
    description: 'Description for $id',
    budget: 100,
    userId: 'user-1',
    status: TaskStatus.open,
    createdAt: createdAt,
  );
}

void main() {
  group('HomeViewModel', () {
    late _MockTaskService taskService;
    late HomeViewModel viewModel;
    late TaskFilterViewModel filterViewModel;

    final firstPage = <Task>[
      _task('a1', DateTime.utc(2026, 3, 1, 12)),
      _task('a0', DateTime.utc(2026, 3, 1, 12)),
    ];
    final secondPage = <Task>[_task('b1', DateTime.utc(2026, 2, 28, 12))];

    setUp(() {
      taskService = _MockTaskService();
      viewModel = HomeViewModel(taskService: taskService);
      filterViewModel = TaskFilterViewModel();
    });

    test('loadFeaturedTasks populates feed and filter controller', () async {
      when(
        () => taskService.getOpenTasksForHome(
          limit: any(named: 'limit'),
          cursorCreatedAtIso: any(named: 'cursorCreatedAtIso'),
          cursorId: any(named: 'cursorId'),
          requestId: any(named: 'requestId'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => firstPage);

      await viewModel.loadFeaturedTasks(filterController: filterViewModel);

      expect(viewModel.featuredTasks, firstPage);
      expect(filterViewModel.filteredTasks, firstPage);
      expect(viewModel.hasMore, isFalse);
      verify(
        () => taskService.getOpenTasksForHome(
          requestId: any(named: 'requestId'),
        ),
      ).called(1);
    });

    test('loadMoreTasks uses composite cursor and appends results', () async {
      final initialPage = List<Task>.from(firstPage)
        ..addAll(
          List.generate(18, (i) {
            return _task(
              'seed-$i',
              DateTime.utc(
                2026,
                2,
                28,
                15,
              ).subtract(Duration(minutes: i)),
            );
          }),
        );

      when(
        () => taskService.getOpenTasksForHome(
          limit: any(named: 'limit'),
          cursorCreatedAtIso: any(named: 'cursorCreatedAtIso'),
          cursorId: any(named: 'cursorId'),
          requestId: any(named: 'requestId'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((invocation) async {
        final cursorCreatedAtIso =
            invocation.namedArguments[#cursorCreatedAtIso] as String?;
        if (cursorCreatedAtIso == null) {
          return initialPage;
        }
        return secondPage;
      });

      await viewModel.loadFeaturedTasks(filterController: filterViewModel);
      await viewModel.loadMoreTasks(filterController: filterViewModel);

      expect(viewModel.featuredTasks.last.id, 'b1');
      expect(filterViewModel.filteredTasks.last.id, 'b1');
      verify(
        () => taskService.getOpenTasksForHome(
          cursorCreatedAtIso: initialPage.last.createdAt
              .toUtc()
              .toIso8601String(),
          cursorId: initialPage.last.id,
          requestId: any(named: 'requestId'),
        ),
      ).called(1);
    });

    test('loadMoreTasks is ignored before first page is loaded', () async {
      await viewModel.loadMoreTasks(filterController: filterViewModel);

      verifyNever(
        () => taskService.getOpenTasksForHome(
          limit: any(named: 'limit'),
          cursorCreatedAtIso: any(named: 'cursorCreatedAtIso'),
          cursorId: any(named: 'cursorId'),
          requestId: any(named: 'requestId'),
          source: any(named: 'source'),
        ),
      );
    });

    test('refresh resets pagination and replaces the current list', () async {
      when(
        () => taskService.getOpenTasksForHome(
          limit: any(named: 'limit'),
          cursorCreatedAtIso: any(named: 'cursorCreatedAtIso'),
          cursorId: any(named: 'cursorId'),
          requestId: any(named: 'requestId'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((invocation) async {
        final cursorCreatedAtIso =
            invocation.namedArguments[#cursorCreatedAtIso] as String?;
        if (cursorCreatedAtIso == null) {
          return firstPage;
        }
        return secondPage;
      });

      await viewModel.loadFeaturedTasks(filterController: filterViewModel);
      await viewModel.loadMoreTasks(filterController: filterViewModel);
      await viewModel.refresh(filterController: filterViewModel);

      expect(viewModel.featuredTasks, firstPage);
      expect(filterViewModel.filteredTasks, firstPage);
      verify(
        () => taskService.getOpenTasksForHome(
          requestId: any(named: 'requestId'),
        ),
      ).called(2);
    });
  });
}
