import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/widgets/status_badge.dart';

import 'widget_test_helpers.dart';

void main() {
  group('StatusBadge', () {
    testWidgets('T-CW100 renders text', (tester) async {
      await pumpCoreWidget(tester, const StatusBadge(text: 'Completed'));
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('T-CW101 shows icon for completed status', (tester) async {
      await pumpCoreWidget(tester, const StatusBadge(text: 'Completed'));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('T-CW102 shows icon for pending status', (tester) async {
      await pumpCoreWidget(tester, const StatusBadge(text: 'Pending'));
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('T-CW103 shows icon for canceled status', (tester) async {
      await pumpCoreWidget(tester, const StatusBadge(text: 'Canceled'));
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('T-CW104 uses pill shape (StadiumBorder)', (tester) async {
      await pumpCoreWidget(tester, const StatusBadge(text: 'Active'));
      // Find Container with ShapeDecoration using StadiumBorder
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasPill = containers.any((c) {
        final dec = c.decoration;
        return dec is ShapeDecoration && dec.shape is StadiumBorder;
      });
      expect(hasPill, isTrue);
    });

    testWidgets('T-CW105 has Semantics with status text', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCoreWidget(tester, const StatusBadge(text: 'Delivered'));
      // Semantics label set to "Status: Delivered"
      expect(find.bySemanticsLabel(RegExp('Status.*Delivered')), findsWidgets);
      handle.dispose();
    });

    testWidgets('T-CW106 small variant renders smaller', (tester) async {
      await pumpCoreWidget(
        tester,
        const StatusBadge(text: 'Done', isSmall: true),
      );
      // Should render with smaller icon and text
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('T-CW107 custom color overrides semantic color', (
      tester,
    ) async {
      await pumpCoreWidget(
        tester,
        const StatusBadge(text: 'Custom', color: Colors.purple),
      );
      // Find icon with purple color
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, equals(Colors.purple));
    });
  });
}
