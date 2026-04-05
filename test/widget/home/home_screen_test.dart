import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/home/view/home_screen.dart';
import 'package:sline_app/features/home/viewmodels/home_view_model.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/discovery_feed_view_model_contract.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

import '../../test_support/pump_app.dart';

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
    () => homeVm.refresh(filterController: filterVm, surface: 'home'),
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

Future<void> _pumpHomeScreen(WidgetTester tester, _HomeBundle bundle) async {
  await pumpApp(
    tester,
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
      child: const HomeScreen(autoLoadOnInit: false),
    ),
  );
}

void main() {
  group('HomeScreen T53-T55', () {
    testWidgets('T53 renders search, categories, and task list shell', (
      tester,
    ) async {
      final bundle = _buildHomeBundle();

      await _pumpHomeScreen(tester, bundle);

      expect(find.byKey(HomeScreen.searchFieldKey), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Design'), findsOneWidget);
      expect(find.byType(SkeletonTaskCard), findsWidgets);
    });

    testWidgets(
      'T54 typing search delegates to TaskFilterViewModel.searchTasks',
      (tester) async {
        final bundle = _buildHomeBundle();

        await _pumpHomeScreen(tester, bundle);

        await tester.enterText(find.byKey(HomeScreen.searchFieldKey), 'design');
        await tester.pump();

        verify(() => bundle.filterVm.searchTasks('design')).called(1);
      },
    );

    testWidgets('T55 pull-to-refresh calls home refresh and profile reload', (
      tester,
    ) async {
      final bundle = _buildHomeBundle();

      await _pumpHomeScreen(tester, bundle);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(
        () => bundle.homeVm.refresh(
          filterController: bundle.filterVm,
          surface: 'home',
        ),
      ).called(1);
      verify(bundle.profileVm.loadHeaderProfile).called(1);
      verify(bundle.savedVm.refresh).called(1);
    });
  });
}
