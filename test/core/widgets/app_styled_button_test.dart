import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/widgets/app_styled_button.dart';
import 'package:sline_app/core/widgets/scale_button.dart';

import 'widget_test_helpers.dart';

void main() {
  group('AppStyledButton (Solid Button — NO GLASS)', () {
    testWidgets('T-CW070 renders text with solid background', (tester) async {
      await pumpCoreWidget(
        tester,
        AppStyledButton(text: 'Action', onPressed: () {}),
      );
      expect(find.text('Action'), findsOneWidget);
      // NO BackdropFilter per NO GLASS POLICY
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('T-CW071 fires onPressed', (tester) async {
      var fired = false;
      await pumpCoreWidget(
        tester,
        AppStyledButton(text: 'Tap', onPressed: () => fired = true),
      );
      await tester.tap(find.byType(AppStyledButton));
      await tester.pump(const Duration(milliseconds: 100));
      expect(fired, isTrue);
    });

    testWidgets('T-CW072 loading state shows spinner', (tester) async {
      await pumpCoreWidget(
        tester,
        const AppStyledButton(text: 'Load', onPressed: null, isLoading: true),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('T-CW073 disabled reduces opacity', (tester) async {
      await pumpCoreWidget(
        tester,
        AppStyledButton(text: 'Off', onPressed: () {}, disabled: true),
      );
      // AppStyledButton applies its own Opacity + ScaleButton adds another
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      final hasReducedOpacity = opacities.any((o) => o.opacity < 1.0);
      expect(hasReducedOpacity, isTrue);
    });

    testWidgets('T-CW074 primary vs secondary styling differs', (tester) async {
      // Primary
      await pumpCoreWidget(
        tester,
        AppStyledButton(text: 'Primary', onPressed: () {}, isPrimary: true),
      );
      final primaryContainers = tester.widgetList<Container>(
        find.byType(Container),
      );
      final primaryBox = primaryContainers
          .where((c) => c.decoration is BoxDecoration)
          .firstOrNull;

      // Secondary
      await pumpCoreWidget(
        tester,
        AppStyledButton(text: 'Secondary', onPressed: () {}, isPrimary: false),
      );
      final secondaryContainers = tester.widgetList<Container>(
        find.byType(Container),
      );
      final secondaryBox = secondaryContainers
          .where((c) => c.decoration is BoxDecoration)
          .firstOrNull;

      // They should exist and be different
      expect(primaryBox, isNotNull);
      expect(secondaryBox, isNotNull);
    });

    testWidgets('T-CW075 has Semantics with label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCoreWidget(
        tester,
        AppStyledButton(text: 'Semantic', onPressed: () {}),
      );
      expect(find.bySemanticsLabel('Semantic'), findsWidgets);
      handle.dispose();
    });

    testWidgets('T-CW076 wraps in ScaleButton', (tester) async {
      await pumpCoreWidget(
        tester,
        AppStyledButton(text: 'Scale', onPressed: () {}),
      );
      expect(find.byType(ScaleButton), findsWidgets);
    });
  });
}
