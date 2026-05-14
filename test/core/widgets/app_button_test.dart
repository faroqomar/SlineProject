import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/scale_button.dart';

import 'widget_test_helpers.dart';

void main() {
  group('AppButton', () {
    testWidgets('T-CW050 renders text', (tester) async {
      await pumpCoreWidget(tester, AppButton(text: 'Submit', onPressed: () {}));
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('T-CW050a uses Amber Dusk button geometry and colors', (
      tester,
    ) async {
      final buttonTheme = AmberDuskTokens.widgetTheme.buttons;
      await pumpCoreWidget(tester, AppButton(text: 'Token', onPressed: () {}));

      final container = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (widget) => widget.constraints?.maxHeight == buttonTheme.minHeight,
            orElse: () => throw TestFailure(
              'No AppButton Container found with maxHeight '
              '${buttonTheme.minHeight}.',
            ),
          );
      final rawDecoration = container.decoration;
      if (rawDecoration is! BoxDecoration) {
        throw TestFailure('Expected AppButton decoration to be BoxDecoration.');
      }
      final decoration = rawDecoration;
      final rawRadius = decoration.borderRadius;
      if (rawRadius is! BorderRadius) {
        throw TestFailure('Expected AppButton radius to be BorderRadius.');
      }
      final radius = rawRadius;
      final material = tester
          .widgetList<Material>(find.byType(Material))
          .firstWhere(
            (widget) => widget.color == buttonTheme.primary.background,
            orElse: () => throw TestFailure(
              'No AppButton Material found with primary background '
              '${buttonTheme.primary.background}.',
            ),
          );
      final text = tester.widget<Text>(find.text('Token'));

      expect(radius.topLeft.x, buttonTheme.radius);
      expect(material.color, buttonTheme.primary.background);
      expect(text.style?.color, buttonTheme.primary.foreground);
      expect(text.style?.fontSize, buttonTheme.textStyle.fontSize);
      expect(text.style?.fontWeight, buttonTheme.textStyle.fontWeight);
    });

    testWidgets('T-CW050b uses Amber Dusk interaction state colors', (
      tester,
    ) async {
      final buttonTheme = AmberDuskTokens.widgetTheme.buttons;
      await pumpCoreWidget(tester, AppButton(text: 'State', onPressed: () {}));

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));

      expect(inkWell.hoverColor, buttonTheme.hoverOverlay);
      expect(inkWell.focusColor, buttonTheme.focusOverlay);
    });

    testWidgets('T-CW050c renders Amber flash overlays at runtime', (
      tester,
    ) async {
      final buttonTheme = AmberDuskTokens.widgetTheme.buttons;

      await pumpCoreWidget(
        tester,
        AppButton(
          key: const ValueKey<String>('success-button'),
          text: 'State',
          onPressed: () {},
        ),
      );
      await pumpCoreWidget(
        tester,
        AppButton(
          key: const ValueKey<String>('success-button'),
          text: 'State',
          onPressed: () {},
          isSuccess: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      final successColor = _flashOverlayColor(tester);
      expect(_rgbOf(successColor), _rgbOf(buttonTheme.successFlash));

      await pumpCoreWidget(
        tester,
        AppButton(
          key: const ValueKey<String>('error-button'),
          text: 'State',
          onPressed: () {},
        ),
      );
      await pumpCoreWidget(
        tester,
        AppButton(
          key: const ValueKey<String>('error-button'),
          text: 'State',
          onPressed: () {},
          isError: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      final errorColor = _flashOverlayColor(tester);
      expect(_rgbOf(errorColor), _rgbOf(buttonTheme.errorFlash));
    });

    testWidgets('T-CW051 fires onPressed callback', (tester) async {
      var fired = false;
      await pumpCoreWidget(
        tester,
        AppButton(text: 'Tap', onPressed: () => fired = true),
      );
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(fired, isTrue);
    });

    testWidgets('T-CW052 shows loading indicator when isLoading=true', (
      tester,
    ) async {
      await pumpCoreWidget(
        tester,
        const AppButton(text: 'Load', onPressed: null, isLoading: true),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Load'), findsNothing);
    });

    testWidgets('T-CW053 disabled state blocks taps', (tester) async {
      var fired = false;
      await pumpCoreWidget(
        tester,
        AppButton(
          text: 'Disabled',
          onPressed: () => fired = true,
          isDisabled: true,
        ),
      );
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(fired, isFalse);
    });

    testWidgets('T-CW054 contains Material widget for ripple', (tester) async {
      await pumpCoreWidget(tester, AppButton(text: 'Ripple', onPressed: () {}));
      // AppButton uses ScaleButton > Material > InkWell tree
      expect(find.byType(Material), findsWidgets);
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('T-CW055 contains ScaleButton for press feedback', (
      tester,
    ) async {
      await pumpCoreWidget(tester, AppButton(text: 'Scale', onPressed: () {}));
      expect(find.byType(ScaleButton), findsWidgets);
    });

    testWidgets('T-CW056 icon variant renders icon + text', (tester) async {
      await pumpCoreWidget(
        tester,
        AppButton(text: 'Add', onPressed: () {}, icon: Icons.add),
      );
      expect(find.text('Add'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('T-CW057 has Semantics with label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCoreWidget(
        tester,
        AppButton(text: 'Semantic', onPressed: () {}),
      );
      // Verify Semantics label is discoverable
      expect(find.bySemanticsLabel('Semantic'), findsWidgets);
      handle.dispose();
    });

    testWidgets('T-CW058 loading blocks onPressed', (tester) async {
      var fired = false;
      await pumpCoreWidget(
        tester,
        AppButton(
          text: 'Loading',
          onPressed: () => fired = true,
          isLoading: true,
        ),
      );
      await tester.tap(find.byType(AppButton));
      await tester.pump(const Duration(milliseconds: 100));
      expect(fired, isFalse);
    });

    testWidgets('T-CW059 respects custom visual overrides', (tester) async {
      const background = Color(0xFF123456);
      const foreground = Color(0xFFFEDCBA);
      final radius = BorderRadius.circular(7);

      await pumpCoreWidget(
        tester,
        AppButton(
          text: 'Custom',
          onPressed: () {},
          backgroundColor: background,
          foregroundColor: foreground,
          borderRadius: radius,
        ),
      );

      final material = tester
          .widgetList<Material>(find.byType(Material))
          .firstWhere(
            (widget) => widget.color == background,
            orElse: () => throw TestFailure(
              'No AppButton Material found with custom background.',
            ),
          );
      final container = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (widget) => widget.decoration is BoxDecoration,
            orElse: () => throw TestFailure(
              'No AppButton Container found with BoxDecoration.',
            ),
          );
      final decoration = container.decoration;
      if (decoration is! BoxDecoration) {
        throw TestFailure('Expected custom AppButton BoxDecoration.');
      }
      final text = tester.widget<Text>(find.text('Custom'));

      expect(material.color, background);
      expect(decoration.borderRadius, radius);
      expect(text.style?.color, foreground);
    });

    testWidgets('T-CW059a keeps long labels inside fixed-width buttons', (
      tester,
    ) async {
      await pumpCoreWidget(
        tester,
        AppButton(
          width: 140,
          text: 'A very long action label that should not overflow',
          onPressed: () {},
        ),
      );

      final text = tester.widget<Text>(
        find.text('A very long action label that should not overflow'),
      );
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });
  });
}

Color? _flashOverlayColor(WidgetTester tester) {
  for (final box in tester.widgetList<DecoratedBox>(
    find.byType(DecoratedBox),
  )) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration && decoration.color != null) {
      return decoration.color;
    }
  }
  return null;
}

int? _rgbOf(Color? color) {
  if (color == null) return null;
  return color.toARGB32() & 0x00FFFFFF;
}
