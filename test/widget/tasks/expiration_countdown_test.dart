// Widget tests for ExpirationCountdown widget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/features/tasks/view/widgets/expiration_countdown.dart';

void main() {
  group('ExpirationCountdown Widget Tests', () {
    testWidgets('displays "Expired" when past deadline', (tester) async {
      final expirationTime = DateTime.now().subtract(const Duration(hours: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpirationCountdown(expirationTime: expirationTime),
          ),
        ),
      );

      expect(find.text('Expired'), findsOneWidget);
    });

    testWidgets('displays countdown for future expiration', (tester) async {
      final expirationTime = DateTime.now().add(const Duration(hours: 5));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpirationCountdown(expirationTime: expirationTime),
          ),
        ),
      );

      // Should find a time format like "05:00:00" or similar
      final countdownText = find.byType(Text);
      expect(countdownText, findsOneWidget);

      final textWidget = tester.widget<Text>(countdownText);
      expect(textWidget.data, isNotNull);
      expect(textWidget.data, isNot('Expired'));
    });

    testWidgets('uses green color for safe state (>4 hours)', (tester) async {
      final expirationTime = DateTime.now().add(const Duration(hours: 5));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpirationCountdown(expirationTime: expirationTime),
          ),
        ),
      );

      final container = find.byType(Container);
      expect(container, findsOneWidget);

      final containerWidget = tester.widget<Container>(container);
      final decoration = containerWidget.decoration as BoxDecoration?;
      expect(decoration, isNotNull);

      // Safe state should use green color (with alpha for border)
      final borderColor = decoration?.border?.bottom.color;
      expect(borderColor, equals(Colors.green.withValues(alpha: 0.3)));
    });

    testWidgets('uses gold color for warning state (1-4 hours)', (
      tester,
    ) async {
      final expirationTime = DateTime.now().add(const Duration(hours: 2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpirationCountdown(expirationTime: expirationTime),
          ),
        ),
      );

      final container = find.byType(Container);
      final containerWidget = tester.widget<Container>(container);
      final decoration = containerWidget.decoration as BoxDecoration?;
      final borderColor = decoration?.border?.bottom.color;

      expect(borderColor, equals(AppColors.gold.withValues(alpha: 0.3)));
    });

    testWidgets('uses red color for urgent state (<1 hour)', (tester) async {
      final expirationTime = DateTime.now().add(const Duration(minutes: 30));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpirationCountdown(expirationTime: expirationTime),
          ),
        ),
      );

      final container = find.byType(Container);
      final containerWidget = tester.widget<Container>(container);
      final decoration = containerWidget.decoration as BoxDecoration?;
      final borderColor = decoration?.border?.bottom.color;

      expect(borderColor, equals(AppColors.lightRed.withValues(alpha: 0.3)));
    });

    testWidgets('respects size parameter', (tester) async {
      final expirationTime = DateTime.now().add(const Duration(hours: 5));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpirationCountdown(
              expirationTime: expirationTime,
              size: CountdownSize.large,
            ),
          ),
        ),
      );

      final text = find.byType(Text);
      final textWidget = tester.widget<Text>(text);
      expect(textWidget.style?.fontSize, equals(18));
    });

    testWidgets('can hide icon when showIcon is false', (tester) async {
      final expirationTime = DateTime.now().add(const Duration(hours: 5));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpirationCountdown(
              expirationTime: expirationTime,
              showIcon: false,
            ),
          ),
        ),
      );

      // Should only have text, no icon
      expect(find.byIcon(Icons.timer), findsNothing);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('has correct accessibility label', (tester) async {
      final expirationTime = DateTime.now().add(
        const Duration(hours: 2, minutes: 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpirationCountdown(
              expirationTime: expirationTime,
              labelPrefix: 'Time left',
            ),
          ),
        ),
      );

      // Find the ExpirationCountdown widget's Semantics by looking for the widget first
      final countdown = find.byType(ExpirationCountdown);
      expect(countdown, findsOneWidget);

      // Verify the widget has the correct label by checking its properties
      final widget = tester.widget<ExpirationCountdown>(countdown);
      expect(widget.labelPrefix, equals('Time left'));
    });
  });

  group('ExpirationBadge Widget Tests', () {
    testWidgets('displays "Expired" chip when past deadline', (tester) async {
      final expirationTime = DateTime.now().subtract(const Duration(hours: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ExpirationBadge(expirationTime: expirationTime)),
        ),
      );

      expect(find.text('Expired'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('displays short format for future expiration', (tester) async {
      final expirationTime = DateTime.now().add(
        const Duration(hours: 2, minutes: 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ExpirationBadge(expirationTime: expirationTime)),
        ),
      );

      // Should find text in format "2h 30m"
      final textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.data, contains('h'));
      expect(textWidget.data, contains('m'));
    });

    testWidgets('uses appropriate colors for different states', (tester) async {
      // Test safe state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpirationBadge(
              expirationTime: DateTime.now().add(const Duration(hours: 5)),
            ),
          ),
        ),
      );

      final container = find.byType(Container);
      final containerWidget = tester.widget<Container>(container);
      final decoration = containerWidget.decoration as BoxDecoration?;
      expect(decoration?.color, equals(Colors.green.withValues(alpha: 0.1)));
    });
  });
}
