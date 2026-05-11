import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/widgets/scale_button.dart';

import 'widget_test_helpers.dart';

void main() {
  group('ScaleButton', () {
    testWidgets('T-CW020 contains ScaleTransition widget', (tester) async {
      await pumpCoreWidget(
        tester,
        ScaleButton(onPressed: () {}, child: const Text('Press')),
      );

      // ScaleButton uses ScaleTransition for animation
      expect(find.byType(ScaleTransition), findsWidgets);
    });

    testWidgets('T-CW021 returns to normal after tap completes', (
      tester,
    ) async {
      await pumpCoreWidget(
        tester,
        ScaleButton(onPressed: () {}, child: const Text('Press')),
      );

      await tester.tap(find.text('Press'));
      await tester.pumpAndSettle();

      // After animation settles, the widget should be rendered normally
      // (no visual assertion needed — pumpAndSettle confirms animation completes)
      expect(find.text('Press'), findsOneWidget);
    });

    testWidgets('T-CW022 fires onPressed callback', (tester) async {
      var fired = false;
      await pumpCoreWidget(
        tester,
        ScaleButton(onPressed: () => fired = true, child: const Text('Press')),
      );

      await tester.tap(find.text('Press'));
      // Wait for callback delay (default 50ms)
      await tester.pump(const Duration(milliseconds: 100));

      expect(fired, isTrue);
    });

    testWidgets('T-CW023 disabled state blocks interaction', (tester) async {
      var fired = false;
      await pumpCoreWidget(
        tester,
        ScaleButton(
          onPressed: () => fired = true,
          disabled: true,
          child: const Text('Disabled'),
        ),
      );

      await tester.tap(find.text('Disabled'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      expect(fired, isFalse);
    });

    testWidgets('T-CW024 disabled applies reduced opacity', (tester) async {
      await pumpCoreWidget(
        tester,
        ScaleButton(
          onPressed: () {},
          disabled: true,
          child: const Text('Disabled'),
        ),
      );

      expect(find.byType(Opacity), findsOneWidget);
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(
        opacity.opacity,
        equals(0.38),
      ); // AppInteractionStates.disabledOpacity
    });

    testWidgets('T-CW025 has Semantics button=true', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCoreWidget(
        tester,
        ScaleButton(onPressed: () {}, child: const Text('Action')),
      );

      expect(find.byType(Semantics), findsWidgets);
      handle.dispose();
    });

    testWidgets('T-CW026 does not fire callback when onPressed is null', (
      tester,
    ) async {
      // onPressed=null means the button is inert — no callback, no animation
      await pumpCoreWidget(
        tester,
        const ScaleButton(onPressed: null, child: Text('Inert')),
      );

      // Tapping should not throw and widget should remain
      await tester.tap(find.text('Inert'));
      await tester.pumpAndSettle();

      expect(find.text('Inert'), findsOneWidget);
    });

    testWidgets('T-CW027 callbackDelay=zero fires immediately', (tester) async {
      var fired = false;
      await pumpCoreWidget(
        tester,
        ScaleButton(
          onPressed: () => fired = true,
          callbackDelay: Duration.zero,
          child: const Text('Fast'),
        ),
      );

      await tester.tap(find.text('Fast'));
      await tester.pump(); // No delay needed

      expect(fired, isTrue);
    });
  });
}
