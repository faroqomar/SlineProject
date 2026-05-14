import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/booking/view/bookings_discovery_screen.dart';
import 'package:sline_app/features/home/viewmodels/home_view_model.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/viewmodels/discovery_feed_view_model_contract.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

import '../../test_support/pump_app.dart';

class _MockHomeViewModel extends Mock
    with ChangeNotifier
    implements HomeViewModel {}

class _MockTaskFilterViewModel extends Mock
    with ChangeNotifier
    implements TaskFilterViewModel {}

class _MockSavedTasksViewModel extends Mock
    with ChangeNotifier
    implements SavedTasksViewModel {}

Task _task({
  required String id,
  required String title,
  required TaskType taskType,
}) {
  return Task(
    id: id,
    title: title,
    description: 'Description for $title',
    budget: 120,
    userId: 'user-1',
    status: TaskStatus.open,
    taskType: taskType,
    createdAt: DateTime.utc(2026, 3),
  );
}

void main() {
  testWidgets('renders booking-only tasks and triggers shared load-more', (
    tester,
  ) async {
    final homeVm = _MockHomeViewModel();
    final filterVm = _MockTaskFilterViewModel();
    final savedVm = _MockSavedTasksViewModel();
    final tasks = <Task>[
      _task(id: 'tender-1', title: 'Tender Task', taskType: TaskType.tender),
      _task(id: 'booking-1', title: 'Booking Task', taskType: TaskType.booking),
    ];

    when(() => homeVm.isLoading).thenReturn(false);
    when(() => homeVm.isLoadingMore).thenReturn(false);
    when(() => homeVm.hasMore).thenReturn(true);
    when(() => homeVm.featuredTasks).thenReturn(tasks);
    when(
      () =>
          homeVm.loadMoreTasks(filterController: filterVm, surface: 'bookings'),
    ).thenAnswer((_) async {});
    when(
      () => homeVm.loadFeaturedTasks(
        filterController: filterVm,
        surface: 'bookings',
      ),
    ).thenAnswer((_) async {});

    when(() => filterVm.filteredTasks).thenReturn(tasks);
    when(() => savedVm.isSaved(any())).thenReturn(false);

    await pumpApp(
      tester,
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeViewModel>.value(value: homeVm),
          ListenableProvider<DiscoveryFeedViewModelContract>.value(
            value: homeVm,
          ),
          ChangeNotifierProvider<TaskFilterViewModel>.value(value: filterVm),
          ChangeNotifierProvider<SavedTasksViewModel>.value(value: savedVm),
        ],
        child: const BookingsDiscoveryScreen(),
      ),
    );
    await tester.pump();

    expect(find.textContaining('BOOKING TASK'), findsOneWidget);
    expect(find.text('Tender Task'), findsNothing);
    verify(
      () =>
          homeVm.loadMoreTasks(filterController: filterVm, surface: 'bookings'),
    ).called(1);
  });
}
