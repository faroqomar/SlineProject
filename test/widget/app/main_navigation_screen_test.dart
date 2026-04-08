import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/app/main_navigation_screen.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';

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
      key: ValueKey('main_nav_stub_tenders'),
      child: Text('Stub Tender Screen'),
    ),
    Center(child: Text('Stub Booking Screen')),
    Center(
      key: ValueKey('main_nav_stub_dashboard'),
      child: Text('Stub Dashboard Screen'),
    ),
    Center(child: Text('Stub Messages Screen')),
    Center(child: Text('Stub Profile Screen')),
    Center(child: Text('Stub Wallet Screen')),
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
      expect(find.byKey(const ValueKey('main_nav_stub_tenders')), findsNothing);

      navigationProvider.setCurrentIndex(1);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('main_nav_stub_home')), findsNothing);
      expect(
        find.byKey(const ValueKey('main_nav_stub_tenders')),
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

      navigationProvider.setCurrentIndex(3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const ValueKey('main_nav_stub_dashboard')),
        findsOneWidget,
      );
      expect(find.text('Stub Dashboard Screen'), findsOneWidget);
    });
  });
}
