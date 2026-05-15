import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/home/view/home_screen.dart';
import 'package:sline_app/features/home/viewmodels/home_view_model.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/widgets/booking_task_card.dart';
import 'package:sline_app/features/tasks/view/widgets/discovery_task_sliver.dart';
import 'package:sline_app/features/tasks/viewmodels/discovery_feed_view_model_contract.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

const Duration _kShimmerPumpDuration = Duration(milliseconds: 500);

class _MockHomeViewModel extends Mock
    with ChangeNotifier
    implements HomeViewModel {}

class _MockTaskFilterViewModel extends Mock
    with ChangeNotifier
    implements TaskFilterViewModel {}

class _MockProfileViewModel extends Mock
    with ChangeNotifier
    implements ProfileViewModel {}

class _MockNotificationViewModel extends Mock
    with ChangeNotifier
    implements NotificationViewModel {}

class _MockSavedTasksViewModel extends Mock
    with ChangeNotifier
    implements SavedTasksViewModel {}

class _TestNavigatorObserver extends NavigatorObserver {
  int didPushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    didPushCount += 1;
    super.didPush(route, previousRoute);
  }
}

typedef _HomeBundle = ({
  _MockHomeViewModel homeVm,
  _MockTaskFilterViewModel filterVm,
  _MockProfileViewModel profileVm,
  _MockNotificationViewModel notificationVm,
  _MockSavedTasksViewModel savedVm,
});

_HomeBundle _buildHomeBundle() {
  final homeVm = _MockHomeViewModel();
  final filterVm = _MockTaskFilterViewModel();
  final profileVm = _MockProfileViewModel();
  final notificationVm = _MockNotificationViewModel();
  final savedVm = _MockSavedTasksViewModel();

  when(() => homeVm.isLoading).thenReturn(true);
  when(() => homeVm.isLoadingMore).thenReturn(false);
  when(() => homeVm.hasMore).thenReturn(false);
  when(
    () => homeVm.refresh(filterController: filterVm),
  ).thenAnswer((_) async {});

  when(() => filterVm.selectedCategory).thenReturn('');
  when(() => filterVm.filteredTasks).thenReturn(const []);

  when(() => profileVm.avatarUrl).thenReturn(null);
  when(() => profileVm.fullName).thenReturn('Test User');
  when(profileVm.loadHeaderProfile).thenAnswer((_) async {});

  when(() => notificationVm.unreadCount).thenReturn(0);

  when(savedVm.load).thenAnswer((_) async {});
  when(savedVm.refresh).thenAnswer((_) async {});

  return (
    homeVm: homeVm,
    filterVm: filterVm,
    profileVm: profileVm,
    notificationVm: notificationVm,
    savedVm: savedVm,
  );
}

Task _task({
  required String id,
  required String title,
  required TaskType taskType,
  String? category,
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
    category: category,
    categoryName: category,
  );
}

Future<void> _pumpHomeScreen(
  WidgetTester tester,
  _HomeBundle bundle, {
  List<NavigatorObserver> navigatorObservers = const [],
  Widget Function(Task task)? taskDetailsScreenBuilder,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeViewModel>.value(value: bundle.homeVm),
        ListenableProvider<DiscoveryFeedViewModelContract>.value(
          value: bundle.homeVm,
        ),
        ChangeNotifierProvider<TaskFilterViewModel>.value(
          value: bundle.filterVm,
        ),
        ChangeNotifierProvider<ProfileViewModel>.value(value: bundle.profileVm),
        ChangeNotifierProvider<NotificationViewModel>.value(
          value: bundle.notificationVm,
        ),
        ChangeNotifierProvider<SavedTasksViewModel>.value(
          value: bundle.savedVm,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        navigatorObservers: navigatorObservers,
        home: HomeScreen(
          autoLoadOnInit: false,
          taskDetailsScreenBuilder: taskDetailsScreenBuilder,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('HomeScreen T53-T55', () {
    testWidgets('T53 renders search, discovery modes, and task list shell', (
      tester,
    ) async {
      final bundle = _buildHomeBundle();

      await _pumpHomeScreen(tester, bundle);
      // Use pump(Duration) — skeleton shimmer animations repeat forever
      // and pumpAndSettle will time out.
      await tester.pump(_kShimmerPumpDuration);

      expect(find.byKey(HomeScreen.searchFieldKey), findsOneWidget);
      expect(find.byKey(HomeScreen.discoveryAllWorkKey), findsOneWidget);
      expect(find.byKey(HomeScreen.discoveryBookingsKey), findsOneWidget);
      expect(find.byKey(HomeScreen.discoveryTendersKey), findsOneWidget);
      expect(find.text('All posts'), findsWidgets);
      expect(find.text('Tender posts'), findsOneWidget);
      expect(find.text('FEED'), findsOneWidget);
      expect(find.text('0 items'), findsOneWidget);
      expect(find.byType(SkeletonTaskCard), findsWidgets);
      expect(find.byType(SafeArea), findsWidgets);
      final discoverySliver = tester.widget<DiscoveryTaskSliver>(
        find.byType(DiscoveryTaskSliver),
      );
      expect(
        discoverySliver.bottomPadding,
        greaterThan(AmberDuskTokens.phoneLayout.bottomScrollPadding),
      );
    });

    testWidgets(
      'T54 typing search delegates to TaskFilterViewModel.searchTasks',
      (tester) async {
        final bundle = _buildHomeBundle();

        await _pumpHomeScreen(tester, bundle);
        // Use pump(Duration) instead of pumpAndSettle — skeleton shimmer
        // animations repeat forever and never settle.
        await tester.pump(_kShimmerPumpDuration);

        await tester.enterText(find.byKey(HomeScreen.searchFieldKey), 'design');
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => bundle.filterVm.searchTasks('design')).called(1);
      },
    );

    testWidgets('T55 pull-to-refresh calls home refresh and profile reload', (
      tester,
    ) async {
      final bundle = _buildHomeBundle();

      await _pumpHomeScreen(tester, bundle);
      // Use pump(Duration) instead of pumpAndSettle — skeleton shimmer
      // animations repeat forever and never settle.
      await tester.pump(_kShimmerPumpDuration);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pump();
      await tester.pump(_kShimmerPumpDuration);

      verify(
        () => bundle.homeVm.refresh(
          filterController: bundle.filterVm,
        ),
      ).called(1);
      verify(bundle.profileVm.loadHeaderProfile).called(1);
      verify(bundle.savedVm.refresh).called(1);
    });

    testWidgets('T56 Bookings discovery mode filters booking tasks', (
      tester,
    ) async {
      final bundle = _buildHomeBundle();
      final tasks = <Task>[
        _task(id: 'tender-1', title: 'Tender Task', taskType: TaskType.tender),
        _task(
          id: 'booking-1',
          title: 'Booking Task',
          taskType: TaskType.booking,
        ),
      ];

      when(() => bundle.homeVm.isLoading).thenReturn(false);
      when(() => bundle.filterVm.filteredTasks).thenReturn(tasks);
      when(() => bundle.savedVm.isSaved(any())).thenReturn(false);

      await _pumpHomeScreen(tester, bundle);
      await tester.pump(_kShimmerPumpDuration);

      await tester.tap(find.byKey(HomeScreen.discoveryBookingsKey));
      await tester.pumpAndSettle();

      expect(find.textContaining('BOOKING TASK'), findsOneWidget);
      expect(find.text('Tender Task'), findsNothing);
    });

    testWidgets('T57 Tenders discovery mode filters tender tasks', (
      tester,
    ) async {
      final bundle = _buildHomeBundle();
      final tasks = <Task>[
        _task(id: 'tender-1', title: 'Tender Task', taskType: TaskType.tender),
        _task(
          id: 'booking-1',
          title: 'Booking Task',
          taskType: TaskType.booking,
        ),
      ];

      when(() => bundle.homeVm.isLoading).thenReturn(false);
      when(() => bundle.filterVm.filteredTasks).thenReturn(tasks);
      when(() => bundle.savedVm.isSaved(any())).thenReturn(false);

      await _pumpHomeScreen(tester, bundle);
      await tester.pump(_kShimmerPumpDuration);

      await tester.tap(find.byKey(HomeScreen.discoveryTendersKey));
      await tester.pumpAndSettle();

      expect(find.text('Tender Task'), findsOneWidget);
      expect(find.text('Booking Task'), findsNothing);
    });

    testWidgets(
      'T58 discovery mode no longer renders the legacy category chip row',
      (tester) async {
        final bundle = _buildHomeBundle();
        final tasks = <Task>[
          _task(
            id: 'booking-1',
            title: 'Booking Task',
            taskType: TaskType.booking,
            category: 'Design',
          ),
        ];

        when(() => bundle.homeVm.isLoading).thenReturn(false);
        when(() => bundle.filterVm.filteredTasks).thenReturn(tasks);
        when(() => bundle.savedVm.isSaved(any())).thenReturn(false);

        await _pumpHomeScreen(tester, bundle);
        await tester.pump(_kShimmerPumpDuration);

        await tester.tap(find.byKey(HomeScreen.discoveryBookingsKey));
        await tester.pumpAndSettle();

        expect(find.byType(BookingTaskCard), findsOneWidget);
        verifyNever(() => bundle.filterVm.filterByCategory(any()));
      },
    );

    testWidgets('T59 task-card tap pushes task details route', (tester) async {
      final bundle = _buildHomeBundle();
      final observer = _TestNavigatorObserver();
      final tasks = <Task>[
        _task(
          id: 'booking-1',
          title: 'Booking Task',
          taskType: TaskType.booking,
        ),
      ];

      when(() => bundle.homeVm.isLoading).thenReturn(false);
      when(() => bundle.filterVm.filteredTasks).thenReturn(tasks);
      when(() => bundle.savedVm.isSaved(any())).thenReturn(false);

      await _pumpHomeScreen(
        tester,
        bundle,
        navigatorObservers: [observer],
        taskDetailsScreenBuilder: (task) =>
            Scaffold(body: Center(child: Text('Details for ${task.title}'))),
      );
      await tester.pump(_kShimmerPumpDuration);

      await tester.tap(find.textContaining('BOOKING TASK'));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();

      expect(observer.didPushCount, greaterThan(0));
      expect(find.text('Details for Booking Task'), findsOneWidget);
    });
  });
}
