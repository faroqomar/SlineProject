import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/app/main_navigation_screen.dart';
import 'package:sline_app/core/navigation/main_nav_destinations.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

import '../../test_support/pump_app.dart';

class _TestNavigatorObserver extends NavigatorObserver {
  int didPushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    didPushCount += 1;
    super.didPush(route, previousRoute);
  }
}

List<Widget> _stubScreens() {
  return const [
    Center(
      key: ValueKey('main_nav_stub_home'),
      child: Text('Stub Home Screen'),
    ),
    Center(
      key: ValueKey('main_nav_stub_dashboard'),
      child: Text('Stub Dashboard Screen'),
    ),
    Center(
      key: ValueKey('main_nav_stub_messages'),
      child: Text('Stub Messages Screen'),
    ),
    Center(
      key: ValueKey('main_nav_stub_profile'),
      child: Text('Stub Profile Screen'),
    ),
  ];
}

void main() {
  group('MainNavigationScreen T50-T52', () {
    testWidgets('T50 renders with initial home content', (tester) async {
      await pumpApp(
        tester,
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(),
          child: MainNavigationScreen(screens: _stubScreens()),
        ),
      );

      expect(find.byKey(const ValueKey('main_nav_stub_home')), findsOneWidget);
      expect(find.text('Stub Home Screen'), findsOneWidget);
    });

    testWidgets('T51 FAB opens create task screen', (tester) async {
      final observer = _TestNavigatorObserver();

      await pumpApp(
        tester,
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(),
          child: MainNavigationScreen(
            screens: _stubScreens(),
            createTaskScreenBuilder: (_) => const Scaffold(
              body: Center(child: Text('Stub Create Task Screen')),
            ),
          ),
        ),
        navigatorObservers: [observer],
      );

      // Allow FAB spring entrance animation to complete
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(MainNavigationScreen.createTaskFabKey));
      await tester.pumpAndSettle();

      expect(observer.didPushCount, greaterThan(0));
      expect(find.text('Stub Create Task Screen'), findsOneWidget);
    });

    testWidgets('T52 changing nav index swaps active screen', (tester) async {
      final navigationProvider = NavigationProvider();

      await pumpApp(
        tester,
        ChangeNotifierProvider<NavigationProvider>.value(
          value: navigationProvider,
          child: MainNavigationScreen(screens: _stubScreens()),
        ),
      );

      // Allow initial animations to settle
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('main_nav_stub_home')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('main_nav_stub_dashboard')),
        findsNothing,
      );

      navigationProvider.setCurrentIndex(MainNavDestinations.dashboard);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('main_nav_stub_home')), findsNothing);
      expect(
        find.byKey(const ValueKey('main_nav_stub_dashboard')),
        findsOneWidget,
      );
    });

    testWidgets('T53 dashboard nav index renders dashboard screen', (
      tester,
    ) async {
      final navigationProvider = NavigationProvider();

      await pumpApp(
        tester,
        ChangeNotifierProvider<NavigationProvider>.value(
          value: navigationProvider,
          child: MainNavigationScreen(screens: _stubScreens()),
        ),
      );

      navigationProvider.setCurrentIndex(MainNavDestinations.dashboard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const ValueKey('main_nav_stub_dashboard')),
        findsOneWidget,
      );
      expect(find.text('Stub Dashboard Screen'), findsOneWidget);
    });

    testWidgets('T54 stale nav index normalizes to home without crashing', (
      tester,
    ) async {
      final navigationProvider = NavigationProvider();

      await pumpApp(
        tester,
        ChangeNotifierProvider<NavigationProvider>.value(
          value: navigationProvider,
          child: MainNavigationScreen(screens: _stubScreens()),
        ),
      );

      navigationProvider.setCurrentIndex(6);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('main_nav_stub_home')), findsOneWidget);
      expect(navigationProvider.currentIndex, MainNavDestinations.home);
    });

    testWidgets('T55 messages and profile nav indexes render their screens', (
      tester,
    ) async {
      final navigationProvider = NavigationProvider();

      await pumpApp(
        tester,
        ChangeNotifierProvider<NavigationProvider>.value(
          value: navigationProvider,
          child: MainNavigationScreen(screens: _stubScreens()),
        ),
      );

      navigationProvider.setCurrentIndex(MainNavDestinations.messages);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const ValueKey('main_nav_stub_messages')),
        findsOneWidget,
      );
      expect(find.text('Stub Messages Screen'), findsOneWidget);

      navigationProvider.setCurrentIndex(MainNavDestinations.profile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const ValueKey('main_nav_stub_profile')),
        findsOneWidget,
      );
      expect(find.text('Stub Profile Screen'), findsOneWidget);
    });

    testWidgets('T56 FAB stays above Android system navigation insets', (
      tester,
    ) async {
      const bottomSystemInset = 34.0;
      addTearDown(tester.view.reset);
      tester.view.viewPadding = FakeViewPadding(
        bottom: bottomSystemInset * tester.view.devicePixelRatio,
      );

      await pumpApp(
        tester,
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(),
          child: MainNavigationScreen(screens: _stubScreens()),
        ),
      );

      final positionedFinder = find.ancestor(
        of: find.byKey(MainNavigationScreen.createTaskFabKey),
        matching: find.byType(Positioned),
      );
      final positioned = tester.widget<Positioned>(positionedFinder);
      final expectedOffset =
          AmberDuskTokens.phoneLayout.bottomNavBottom +
          AmberDuskTokens.phoneLayout.bottomNavHeight +
          AmberDuskTokens.spacing.sm;

      expect(positioned.bottom, expectedOffset + bottomSystemInset);
    });

    testWidgets('T57 FAB is owned by Home and absent on other tabs', (
      tester,
    ) async {
      final navigationProvider = NavigationProvider();

      await pumpApp(
        tester,
        ChangeNotifierProvider<NavigationProvider>.value(
          value: navigationProvider,
          child: MainNavigationScreen(screens: _stubScreens()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(MainNavigationScreen.createTaskFabKey), findsOneWidget);

      for (final destination in [
        MainNavDestinations.dashboard,
        MainNavDestinations.messages,
        MainNavDestinations.profile,
      ]) {
        navigationProvider.setCurrentIndex(destination);
        await tester.pumpAndSettle();

        expect(find.byKey(MainNavigationScreen.createTaskFabKey), findsNothing);
      }
    });

    testWidgets('T58 FAB uses Amber Dusk action tokens', (tester) async {
      await pumpApp(
        tester,
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(),
          child: MainNavigationScreen(screens: _stubScreens()),
        ),
      );
      await tester.pumpAndSettle();

      final fab = tester.widget<Container>(
        find.byKey(MainNavigationScreen.createTaskFabKey),
      );
      final decoration = fab.decoration;
      expect(decoration, isA<BoxDecoration>());
      if (decoration is! BoxDecoration) return;
      final box = decoration;

      expect(box.color, AmberDuskTokens.colors.primary);
      expect(
        box.borderRadius,
        BorderRadius.circular(AmberDuskTokens.phoneLayout.fabRadius),
      );
    });
  });
}
