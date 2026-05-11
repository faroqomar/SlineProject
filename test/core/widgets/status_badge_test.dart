import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/status_badge.dart';

import 'widget_test_helpers.dart';

void main() {
  group('StatusBadge', () {
    testWidgets('T-CW100 renders text', (tester) async {
      await pumpCoreWidget(tester, const StatusBadge(text: 'Completed'));
      expect(find.text('COMPLETED'), findsOneWidget);
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
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasPill = containers.any((c) {
        final dec = c.decoration;
        return dec is ShapeDecoration &&
            dec.shape is StadiumBorder &&
            dec.color ==
                AmberDuskTokens.widgetTheme.statusPills.active.background;
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
      expect(find.text('DONE'), findsOneWidget);
      final container = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (widget) => widget.decoration is ShapeDecoration,
            orElse: () => throw TestFailure(
              'No Container with ShapeDecoration found for small StatusBadge.',
            ),
          );
      final text = tester.widget<Text>(find.text('DONE'));
      final icon = tester.widget<Icon>(find.byType(Icon));

      expect(
        container.padding,
        AmberDuskTokens.widgetTheme.statusPills.smallPadding,
      );
      expect(
        text.style?.fontSize,
        AmberDuskTokens.widgetTheme.statusPills.smallTextStyle.fontSize,
      );
      expect(icon.size, AmberDuskTokens.widgetTheme.statusPills.smallIconSize);
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
      final container = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (widget) => widget.decoration is ShapeDecoration,
            orElse: () => throw TestFailure(
              'No Container with ShapeDecoration found for custom StatusBadge.',
            ),
          );
      final rawDecoration = container.decoration;
      if (rawDecoration is! ShapeDecoration) {
        throw TestFailure(
          'Expected custom StatusBadge decoration to be ShapeDecoration.',
        );
      }
      final decoration = rawDecoration;
      expect(decoration.color, Colors.purple.withValues(alpha: 0.12));
    });

    testWidgets('T-CW108 - uses Amber semantic colors for status groups', (
      tester,
    ) async {
      final pills = AmberDuskTokens.widgetTheme.statusPills;

      await pumpCoreWidget(tester, const StatusBadge(text: 'Won'));
      var icon = tester.widget<Icon>(find.byType(Icon));
      var decoration = _statusBadgeDecoration(tester);
      expect(icon.color, pills.active.foreground);
      expect(decoration.color, pills.active.background);

      await pumpCoreWidget(tester, const StatusBadge(text: 'Review'));
      icon = tester.widget<Icon>(find.byType(Icon));
      decoration = _statusBadgeDecoration(tester);
      expect(icon.color, pills.primary.foreground);
      expect(decoration.color, pills.primary.background);

      await pumpCoreWidget(tester, const StatusBadge(text: 'Refunded'));
      icon = tester.widget<Icon>(find.byType(Icon));
      decoration = _statusBadgeDecoration(tester);
      expect(icon.color, pills.completed.foreground);
      expect(decoration.color, pills.completed.background);

      await pumpCoreWidget(tester, const StatusBadge(text: 'Timeout'));
      icon = tester.widget<Icon>(find.byType(Icon));
      decoration = _statusBadgeDecoration(tester);
      expect(icon.color, pills.muted.foreground);
      expect(decoration.color, pills.muted.background);
    });

    testWidgets('T-CW109 - uses urgent rust overlay for failure statuses', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const StatusBadge(text: 'Failed'));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, AmberDuskTokens.colors.rust);

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasUrgentOverlay = containers.any((container) {
        final decoration = container.decoration;
        return decoration is ShapeDecoration &&
            decoration.color ==
                AmberDuskTokens.widgetTheme.statusPills.urgent.background;
      });
      expect(hasUrgentOverlay, isTrue);
    });

    testWidgets('T-CW110 - pending statuses run bounded pulse animation', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const StatusBadge(text: 'Review'));

      final firstOpacity = tester.widget<Opacity>(find.byType(Opacity));
      await tester.pump(const Duration(milliseconds: 120));
      final nextOpacity = tester.widget<Opacity>(find.byType(Opacity));

      expect(nextOpacity.opacity, isNot(firstOpacity.opacity));
      expect(nextOpacity.opacity, greaterThanOrEqualTo(0.7));
      expect(nextOpacity.opacity, lessThanOrEqualTo(1.0));
    });
  });
}

ShapeDecoration _statusBadgeDecoration(WidgetTester tester) {
  final container = tester
      .widgetList<Container>(find.byType(Container))
      .firstWhere(
        (widget) => widget.decoration is ShapeDecoration,
        orElse: () =>
            throw TestFailure('No Container with ShapeDecoration found.'),
      );
  final decoration = container.decoration;
  if (decoration is! ShapeDecoration) {
    throw TestFailure('Expected StatusBadge decoration to be ShapeDecoration.');
  }
  return decoration;
}
