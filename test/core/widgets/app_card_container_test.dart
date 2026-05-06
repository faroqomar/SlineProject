import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/widgets/app_card_container.dart';

import 'widget_test_helpers.dart';

void main() {
  group('AppCardContainer (Solid Surface — NO GLASS)', () {
    testWidgets('T-CW030 renders child widget', (tester) async {
      await pumpCoreWidget(
        tester,
        const AppCardContainer(child: Text('Hello')),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('T-CW031 does NOT contain BackdropFilter', (tester) async {
      await pumpCoreWidget(
        tester,
        const AppCardContainer(child: Text('Solid')),
      );

      // Per NO GLASS POLICY — no BackdropFilter anywhere
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('T-CW032 uses solid cardBackground color', (tester) async {
      await pumpCoreWidget(tester, const AppCardContainer(child: Text('Card')));

      // Find the Container with BoxDecoration that has a solid color
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasColoredContainer = containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration && decoration.color != null;
      });
      expect(hasColoredContainer, isTrue);
    });

    testWidgets('T-CW033 applies elevation shadow at given level', (
      tester,
    ) async {
      await pumpCoreWidget(
        tester,
        const AppCardContainer(elevation: 3, child: Text('Elevated')),
      );

      // Level 3 shadow should have blur=16
      final containers = tester.widgetList<Container>(find.byType(Container));
      final elevated = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration && decoration.boxShadow != null) {
          return decoration.boxShadow!.any((s) => s.blurRadius == 16);
        }
        return false;
      });
      expect(elevated, isNotEmpty);
    });

    testWidgets('T-CW034 respects borderRadius parameter', (tester) async {
      await pumpCoreWidget(
        tester,
        AppCardContainer(
          borderRadius: BorderRadius.circular(8),
          child: const Text('Rounded'),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final rounded = containers.where((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration &&
            decoration.borderRadius == BorderRadius.circular(8);
      });
      expect(rounded, isNotEmpty);
    });

    testWidgets('T-CW035 elevation 0 has no shadow', (tester) async {
      await pumpCoreWidget(
        tester,
        const AppCardContainer(elevation: 0, child: Text('Flat')),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final flat = containers.where((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration &&
            (decoration.boxShadow == null || decoration.boxShadow!.isEmpty);
      });
      expect(flat, isNotEmpty);
    });

    testWidgets('T-CW036 applies padding', (tester) async {
      await pumpCoreWidget(
        tester,
        const AppCardContainer(
          padding: EdgeInsets.all(24),
          child: Text('Padded'),
        ),
      );

      final container = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.padding == const EdgeInsets.all(24));
      expect(container, isNotEmpty);
    });
  });
}
