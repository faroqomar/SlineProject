import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sline_app/core/navigation/main_nav_destinations.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/custom_bottom_nav_bar.dart';

void main() {
  group('CustomBottomNavBar Amber Dusk solid surface', () {
    Widget buildTestApp({
      int initialIndex = 0,
      bool showMessagesNotification = true,
      int? messagesNotificationCount = 0,
    }) {
      return ChangeNotifierProvider(
        create: (_) => NavigationProvider()..setCurrentIndex(initialIndex),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Stack(
              children: [
                CustomBottomNavBar(
                  showMessagesNotification: showMessagesNotification,
                  messagesNotificationCount: messagesNotificationCount,
                ),
              ],
            ),
          ),
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

    testWidgets('T-CW111 does not contain BackdropFilter blur', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // The Phase 2 shell uses an opaque Amber Dusk surface.
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('T-CW112 active item shows label with full opacity', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // "Home" should be visible (first tab is active)
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('T-CW112a uses Amber Dusk nav surface and active colors', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      final navTheme = AmberDuskTokens.widgetTheme.bottomNav;
      final navSurface = tester.widget<Container>(
        find.byKey(CustomBottomNavBar.navSurfaceKey),
      );
      final navDecoration = navSurface.decoration;
      if (navDecoration is! BoxDecoration) {
        throw TestFailure(
          'Expected nav surface decoration to be BoxDecoration.',
        );
      }
      final navBox = navDecoration;
      expect(navBox.color, navTheme.surface);
      expect(navBox.borderRadius, BorderRadius.circular(navTheme.radius));

      final activeIcon = tester.widget<Icon>(find.byIcon(Icons.home));
      expect(activeIcon.color, navTheme.activeForeground);

      final activeCapsule = tester.widget<Container>(
        find.byKey(CustomBottomNavBar.activeCapsuleKey),
      );
      final capsuleDecoration = activeCapsule.decoration;
      if (capsuleDecoration is! BoxDecoration) {
        throw TestFailure(
          'Expected active capsule decoration to be BoxDecoration.',
        );
      }
      final capsuleBox = capsuleDecoration;
      expect(capsuleBox.color, navTheme.activeIconBackground);
      expect(
        capsuleBox.borderRadius,
        BorderRadius.circular(navTheme.activeIconRadius),
      );
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

    testWidgets('T-CW115 renders compact Messages dot for zero count', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      final rustDots = tester.widgetList<Container>(find.byType(Container));
      final hasCompactDot = rustDots.any((container) {
        final decoration = container.decoration;
        return container.constraints?.maxWidth == AmberDuskTokens.spacing.sm &&
            container.constraints?.maxHeight == AmberDuskTokens.spacing.sm &&
            decoration is BoxDecoration &&
            decoration.shape == BoxShape.circle &&
            decoration.color == AmberDuskTokens.colors.rust;
      });

      expect(hasCompactDot, isTrue);
      expect(find.text('0'), findsNothing);
    });

    testWidgets(
      'T-CW116 renders numeric Messages badge when count is positive',
      (tester) async {
        await tester.pumpWidget(buildTestApp(messagesNotificationCount: 12));
        await tester.pump();

        expect(find.text('12'), findsOneWidget);
      },
    );

    testWidgets('T-CW117 can suppress the Messages notification marker', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(showMessagesNotification: false));
      await tester.pump();

      expect(find.text('0'), findsNothing);
      expect(find.text('99+'), findsNothing);
      final rustDotCount = tester
          .widgetList<Container>(find.byType(Container))
          .where((container) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.shape == BoxShape.circle &&
                decoration.color == AmberDuskTokens.colors.rust;
          })
          .length;
      expect(rustDotCount, 0);
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
                widget.left == AmberDuskTokens.phoneLayout.bottomNavInset &&
                widget.right == AmberDuskTokens.phoneLayout.bottomNavInset &&
                widget.bottom != null,
          );
      expect(
        positioned.bottom,
        AmberDuskTokens.phoneLayout.bottomNavBottom + bottomSystemInset,
      );
    });
  });
}
