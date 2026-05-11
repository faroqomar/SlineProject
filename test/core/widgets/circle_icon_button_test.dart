import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/circle_icon_button.dart';

import 'widget_test_helpers.dart';

void main() {
  group('CircleIconButton', () {
    testWidgets('T-CW010 renders with correct icon', (tester) async {
      await pumpCoreWidget(
        tester,
        CircleIconButton(icon: Icons.favorite, onTap: () {}),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('T-CW010a uses Amber Dusk solid icon-button tokens', (
      tester,
    ) async {
      final iconButtonTheme = AmberDuskTokens.widgetTheme.iconButtons;
      await pumpCoreWidget(
        tester,
        CircleIconButton(icon: Icons.favorite, onTap: () {}),
      );

      final container = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (widget) => widget.decoration is BoxDecoration,
            orElse: () => throw TestFailure(
              'No CircleIconButton container with BoxDecoration found.',
            ),
          );
      final rawDecoration = container.decoration;
      if (rawDecoration is! BoxDecoration) {
        throw TestFailure(
          'Expected CircleIconButton decoration to be BoxDecoration.',
        );
      }
      final decoration = rawDecoration;
      final rawBorder = decoration.border;
      if (rawBorder is! Border) {
        throw TestFailure('Expected CircleIconButton border to be Border.');
      }
      final border = rawBorder;
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));

      expect(container.constraints?.maxWidth, iconButtonTheme.size);
      expect(container.constraints?.maxHeight, iconButtonTheme.size);
      expect(decoration.color, iconButtonTheme.background);
      expect(decoration.shape, BoxShape.circle);
      expect(border.top.width, iconButtonTheme.borderWidth);
      expect(icon.color, iconButtonTheme.foreground);
    });

    testWidgets('T-CW011 fires onTap callback on tap', (tester) async {
      var tapped = false;
      await pumpCoreWidget(
        tester,
        CircleIconButton(icon: Icons.share, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(CircleIconButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('T-CW012 applies custom icon color', (tester) async {
      await pumpCoreWidget(
        tester,
        CircleIconButton(
          icon: Icons.close,
          onTap: () {},
          iconColor: AmberDuskTokens.colors.rust,
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, equals(AmberDuskTokens.colors.rust));
    });

    testWidgets('T-CW013 applies custom background color', (tester) async {
      await pumpCoreWidget(
        tester,
        CircleIconButton(
          icon: Icons.add,
          onTap: () {},
          backgroundColor: AmberDuskTokens.colors.forest,
        ),
      );

      // Find the Container that provides the circular background
      final containers = tester.widgetList<Container>(find.byType(Container));
      final circleContainer = containers.firstWhere(
        (c) {
          final decoration = c.decoration;
          return decoration is BoxDecoration &&
              decoration.shape == BoxShape.circle &&
              decoration.color == AmberDuskTokens.colors.forest;
        },
        orElse: () => throw StateError(
          'No circular container with custom background found',
        ),
      );
      expect(circleContainer, isNotNull);
    });

    testWidgets('T-CW014 uses Amber Dusk default visual size', (tester) async {
      await pumpCoreWidget(
        tester,
        CircleIconButton(icon: Icons.edit, onTap: () {}),
      );

      final iconButtonTheme = AmberDuskTokens.widgetTheme.iconButtons;
      final containers = tester.widgetList<Container>(find.byType(Container));
      final sizedContainer = containers.firstWhere(
        (c) =>
            c.constraints?.maxWidth == iconButtonTheme.size &&
            c.constraints?.maxHeight == iconButtonTheme.size,
        orElse: () => throw StateError('No Amber icon-button container found'),
      );
      expect(sizedContainer, isNotNull);
    });

    testWidgets('T-CW015 uses custom icon size', (tester) async {
      await pumpCoreWidget(
        tester,
        CircleIconButton(icon: Icons.star, onTap: () {}, iconSize: 30),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, equals(30));
    });

    testWidgets('T-CW016 enforces minimum touch target', (tester) async {
      await pumpCoreWidget(
        tester,
        CircleIconButton(icon: Icons.more_horiz, onTap: () {}, size: 32),
      );

      final touchTarget = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .firstWhere(
            (box) =>
                box.width == AppLayout.minTouchTarget &&
                box.height == AppLayout.minTouchTarget &&
                box.child is Center,
            orElse: () => throw TestFailure(
              'No 48x48 CircleIconButton touch target found.',
            ),
          );
      expect(touchTarget.child, isA<Center>());
    });

    testWidgets('T-CW017 exposes tooltip and semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCoreWidget(
        tester,
        CircleIconButton(
          icon: Icons.info,
          onTap: () {},
          tooltip: 'More information',
        ),
      );

      expect(find.byTooltip('More information'), findsOneWidget);
      expect(find.bySemanticsLabel('More information'), findsWidgets);
      handle.dispose();
    });
  });
}
