import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
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

    testWidgets('T-CW070a uses Amber Dusk compact action tokens', (
      tester,
    ) async {
      final buttonTheme = AmberDuskTokens.widgetTheme.buttons;
      await pumpCoreWidget(
        tester,
        AppStyledButton(text: 'Action', onPressed: () {}),
      );

      final container = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (widget) => widget.constraints?.maxHeight == buttonTheme.minHeight,
            orElse: () => throw TestFailure(
              'No AppStyledButton container matched minHeight '
              '${buttonTheme.minHeight}.',
            ),
          );
      final rawDecoration = container.decoration;
      if (rawDecoration is! BoxDecoration) {
        throw TestFailure(
          'Expected AppStyledButton decoration to be BoxDecoration.',
        );
      }
      final decoration = rawDecoration;
      final rawRadius = decoration.borderRadius;
      if (rawRadius is! BorderRadius) {
        throw TestFailure(
          'Expected AppStyledButton radius to be BorderRadius.',
        );
      }
      final radius = rawRadius;
      final text = tester.widget<Text>(find.text('Action'));

      expect(decoration.color, buttonTheme.primary.background);
      expect(radius.topLeft.x, buttonTheme.radius);
      expect(decoration.border, isNull);
      expect(container.padding, buttonTheme.padding);
      expect(text.style?.color, buttonTheme.primary.foreground);
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

    testWidgets('T-CW074 primary vs ghost styling differs', (tester) async {
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
      if (primaryBox == null) {
        throw TestFailure('No primary AppStyledButton decoration found.');
      }
      final primaryRawDecoration = primaryBox.decoration;
      if (primaryRawDecoration is! BoxDecoration) {
        throw TestFailure(
          'Expected primary AppStyledButton decoration to be BoxDecoration.',
        );
      }
      final primaryDecoration = primaryRawDecoration;

      // Ghost
      await pumpCoreWidget(
        tester,
        AppStyledButton(text: 'Ghost', onPressed: () {}, isPrimary: false),
      );
      final ghostContainers = tester.widgetList<Container>(
        find.byType(Container),
      );
      final ghostBox = ghostContainers
          .where((c) => c.decoration is BoxDecoration)
          .firstOrNull;
      if (ghostBox == null) {
        throw TestFailure('No ghost AppStyledButton decoration found.');
      }
      final ghostRawDecoration = ghostBox.decoration;
      if (ghostRawDecoration is! BoxDecoration) {
        throw TestFailure(
          'Expected ghost AppStyledButton decoration to be BoxDecoration.',
        );
      }
      final ghostDecoration = ghostRawDecoration;
      final buttonTheme = AmberDuskTokens.widgetTheme.buttons;

      expect(primaryDecoration.color, buttonTheme.primary.background);
      expect(ghostDecoration.color, buttonTheme.ghost.background);
      expect(primaryDecoration.color, isNot(ghostDecoration.color));
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
