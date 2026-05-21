import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
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

    testWidgets('T-CW032 uses Amber Dusk panel surface and borderless radius', (
      tester,
    ) async {
      final cardTheme = AmberDuskTokens.widgetTheme.cards;
      await pumpCoreWidget(tester, const AppCardContainer(child: Text('Card')));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final container = containers.firstWhere(
        (widget) {
          final decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == cardTheme.panel.background;
        },
        orElse: () => throw TestFailure(
          'No Container found with Amber Dusk panel background '
          '${cardTheme.panel.background}.',
        ),
      );
      final rawDecoration = container.decoration;
      if (rawDecoration is! BoxDecoration) {
        throw TestFailure(
          'Expected AppCardContainer decoration to be BoxDecoration.',
        );
      }
      final decoration = rawDecoration;
      final rawRadius = decoration.borderRadius;
      if (rawRadius is! BorderRadius) {
        throw TestFailure(
          'Expected AppCardContainer radius to be BorderRadius.',
        );
      }
      final radius = rawRadius;

      expect(decoration.color, cardTheme.panel.background);
      expect(decoration.border, isNull);
      expect(decoration.gradient, isNotNull);
      expect(radius.topLeft.x, cardTheme.panel.radius);
      expect(radius.topRight.x, cardTheme.panel.radius);
      expect(radius.bottomLeft.x, cardTheme.panel.radius);
      expect(radius.bottomRight.x, cardTheme.panel.radius);
    });

    testWidgets('T-CW033 applies elevation shadow at given level', (
      tester,
    ) async {
      await pumpCoreWidget(
        tester,
        const AppCardContainer(elevation: 3, child: Text('Elevated')),
      );

      final expectedBlur =
          AmberDuskMaterial.strongSurfaceDepthShadows.first.blurRadius;
      final containers = tester.widgetList<Container>(find.byType(Container));
      final elevated = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration && decoration.boxShadow != null) {
          return decoration.boxShadow!.any((s) => s.blurRadius == expectedBlur);
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
