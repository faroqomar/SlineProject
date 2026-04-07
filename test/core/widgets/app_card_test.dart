import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/scale_button.dart';

import 'widget_test_helpers.dart';

void main() {
  group('AppCard (Solid Card — NO GLASS)', () {
    testWidgets('T-CW040 renders child with solid container', (tester) async {
      await pumpCoreWidget(
        tester,
        const AppCard(child: Text('Content')),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(AppCardContainer), findsOneWidget);
      // NO BackdropFilter per NO GLASS POLICY
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('T-CW041 wraps in ScaleButton when onTap provided',
        (tester) async {
      await pumpCoreWidget(
        tester,
        AppCard(
          onTap: () {},
          child: const Text('Tappable'),
        ),
      );

      expect(find.byType(ScaleButton), findsOneWidget);
    });

    testWidgets('T-CW042 no ScaleButton when onTap is null', (tester) async {
      await pumpCoreWidget(
        tester,
        const AppCard(child: Text('Static')),
      );

      expect(find.byType(ScaleButton), findsNothing);
    });

    testWidgets('T-CW043 fires onTap callback', (tester) async {
      var tapped = false;
      await pumpCoreWidget(
        tester,
        AppCard(
          onTap: () => tapped = true,
          child: const Text('Tap Me'),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapped, isTrue);
    });

    testWidgets('T-CW044 disabled blocks tap', (tester) async {
      var tapped = false;
      await pumpCoreWidget(
        tester,
        AppCard(
          onTap: () => tapped = true,
          disabled: true,
          child: const Text('Disabled Card'),
        ),
      );

      await tester.tap(find.text('Disabled Card'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapped, isFalse);
    });

    testWidgets('T-CW045 has Semantics container=true', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCoreWidget(
        tester,
        const AppCard(child: Text('Semantic')),
      );

      final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
      final hasContainer =
          semantics.any((s) => s.container == true);
      expect(hasContainer, isTrue);
      handle.dispose();
    });

    testWidgets('T-CW046 passes elevation to AppCardContainer', (tester) async {
      await pumpCoreWidget(
        tester,
        const AppCard(
          elevation: 3,
          child: Text('Elevated'),
        ),
      );

      final container = tester.widget<AppCardContainer>(
        find.byType(AppCardContainer),
      );
      expect(container.elevation, equals(3));
    });
  });
}
