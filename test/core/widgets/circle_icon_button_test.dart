import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
          iconColor: Colors.red,
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, equals(Colors.red));
    });

    testWidgets('T-CW013 applies custom background color', (tester) async {
      await pumpCoreWidget(
        tester,
        CircleIconButton(
          icon: Icons.add,
          onTap: () {},
          backgroundColor: Colors.blue,
        ),
      );

      // Find the Container that provides the circular background
      final containers = tester.widgetList<Container>(find.byType(Container));
      final circleContainer = containers.firstWhere(
        (c) {
          final decoration = c.decoration;
          return decoration is BoxDecoration &&
              decoration.shape == BoxShape.circle &&
              decoration.color == Colors.blue;
        },
        orElse: () => throw StateError(
          'No circular container with blue background found',
        ),
      );
      expect(circleContainer, isNotNull);
    });

    testWidgets('T-CW014 uses default size of 40', (tester) async {
      await pumpCoreWidget(
        tester,
        CircleIconButton(icon: Icons.edit, onTap: () {}),
      );

      // Default size=40 means the container should be 40x40
      final containers = tester.widgetList<Container>(find.byType(Container));
      final sizedContainer = containers.firstWhere(
        (c) => c.constraints?.maxWidth == 40 && c.constraints?.maxHeight == 40,
        orElse: () => throw StateError('No 40x40 container found'),
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
  });
}
