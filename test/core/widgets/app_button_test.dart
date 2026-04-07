import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/scale_button.dart';

import 'widget_test_helpers.dart';

void main() {
  group('AppButton', () {
    testWidgets('T-CW050 renders text', (tester) async {
      await pumpCoreWidget(tester, AppButton(text: 'Submit', onPressed: () {}));
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('T-CW051 fires onPressed callback', (tester) async {
      var fired = false;
      await pumpCoreWidget(
        tester,
        AppButton(text: 'Tap', onPressed: () => fired = true),
      );
      await tester.tap(find.byType(AppButton));
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
      await tester.tap(find.byType(AppButton));
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
  });
}
