import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sline_app/core/navigation/main_nav_destinations.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/widgets/custom_bottom_nav_bar.dart';

void main() {
  group('CustomBottomNavBar (Solid Surface — NO GLASS)', () {
    Widget buildTestApp({int initialIndex = 0}) {
      return ChangeNotifierProvider(
        create: (_) => NavigationProvider()..setCurrentIndex(initialIndex),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: Stack(children: [CustomBottomNavBar()])),
        ),
      );
    }

    testWidgets('T-CW110 renders 4 primary navigation items', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // The consolidated shell exposes only primary destinations.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Tenders'), findsNothing);
      expect(find.text('Bookings'), findsNothing);
    });

    testWidgets('T-CW111 does NOT contain BackdropFilter', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // NO GLASS POLICY — zero BackdropFilter
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('T-CW112 active item shows label with full opacity', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(initialIndex: 0));
      await tester.pump();

      // "Home" should be visible (first tab is active)
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('T-CW113 has Semantics on each nav item', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Each nav item should have Semantics
      expect(find.byType(Semantics), findsWidgets);
      handle.dispose();
    });

    testWidgets('T-CW114 tapping nav item changes index', (tester) async {
      final navigationProvider = NavigationProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider<NavigationProvider>.value(
          value: navigationProvider,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: Stack(children: [CustomBottomNavBar()])),
          ),
        ),
      );
      await tester.pump();

      // Tap "Profile" (last item)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(navigationProvider.currentIndex, MainNavDestinations.profile);
    });

    testWidgets('keeps the nav bar above Android system navigation insets', (
      tester,
    ) async {
      const bottomSystemInset = 34.0;
      addTearDown(tester.view.reset);
      tester.view.viewPadding = FakeViewPadding(
        bottom: bottomSystemInset * tester.view.devicePixelRatio,
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      final positioned = tester
          .widgetList<Positioned>(find.byType(Positioned))
          .singleWhere(
            (widget) =>
                widget.left == AppDimens.p16 &&
                widget.right == AppDimens.p16 &&
                widget.bottom != null,
          );
      expect(positioned.bottom, AppDimens.p16 + bottomSystemInset);
    });
  });
}
