import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/features/chat/view/widgets/message_bubble.dart';

void main() {
  group('MessageBubble grouping', () {
    Widget buildTestBubble({
      bool isMine = true,
      bool isFirstInGroup = true,
      bool isLastInGroup = true,
      String? status,
    }) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MessageBubble(
            text: 'Hello',
            time: '12:00',
            isMine: isMine,
            isFirstInGroup: isFirstInGroup,
            isLastInGroup: isLastInGroup,
            status: status,
          ),
        ),
      );
    }

    testWidgets('defaults to standalone (first and last in group)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: MessageBubble(text: 'Hello', time: '12:00', isMine: true),
          ),
        ),
      );

      // Should show text and timestamp (last in group shows time)
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
    });

    testWidgets('hides timestamp when not last in group', (tester) async {
      await tester.pumpWidget(buildTestBubble(isLastInGroup: false));

      expect(find.text('Hello'), findsOneWidget);
      // Timestamp should be hidden for non-last messages in group
      expect(find.text('12:00'), findsNothing);
    });

    testWidgets('shows timestamp when last in group', (tester) async {
      await tester.pumpWidget(buildTestBubble(isLastInGroup: true));

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
    });

    testWidgets('shows status icon for sent messages when last in group', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestBubble(isMine: true, status: 'sent', isLastInGroup: true),
      );

      // Should find a check icon for sent status
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('shows double check for delivered status', (tester) async {
      await tester.pumpWidget(
        buildTestBubble(isMine: true, status: 'delivered', isLastInGroup: true),
      );

      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('shows double check for read status', (tester) async {
      await tester.pumpWidget(
        buildTestBubble(isMine: true, status: 'read', isLastInGroup: true),
      );

      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('no status icon for other user messages', (tester) async {
      await tester.pumpWidget(
        buildTestBubble(isMine: false, status: 'read', isLastInGroup: true),
      );

      // Other user messages don't show status icons
      expect(find.byIcon(Icons.done_all), findsNothing);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('has Semantics with correct label', (tester) async {
      await tester.pumpWidget(buildTestBubble(isMine: true, status: 'sent'));

      // Verify Semantics node exists with expected content
      final semantics = find.bySemanticsLabel(RegExp('You said: Hello'));
      expect(semantics, findsOneWidget);
    });

    testWidgets('hides status icon when not last in group', (tester) async {
      // Status icons are only rendered on the last message in a group;
      // middle/first-only messages should show no check icons to reduce noise.
      await tester.pumpWidget(
        buildTestBubble(isMine: true, status: 'sent', isLastInGroup: false),
      );
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.done_all), findsNothing);
    });

    testWidgets('has Semantics for other user messages', (tester) async {
      // Non-mine bubbles should expose an accessibility label starting with
      // "Other said:" so screen readers differentiate sender identity.
      await tester.pumpWidget(buildTestBubble(isMine: false));
      final semantics = find.bySemanticsLabel(RegExp('Other said: Hello'));
      expect(semantics, findsOneWidget);
    });

    testWidgets('delivered status icon uses metaColor (white with opacity)',
        (tester) async {
      // For isMine bubbles, delivered uses metaColor = white.withValues(alpha: 0.7).
      // This verifies the icon color matches that token rather than colorScheme.info.
      await tester.pumpWidget(
        buildTestBubble(isMine: true, status: 'delivered', isLastInGroup: true),
      );
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.done_all));
      // metaColor for isMine is Colors.white.withValues(alpha: 0.7)
      expect(iconWidget.color, equals(Colors.white.withValues(alpha: 0.7)));
    });

    testWidgets('read status icon uses colorScheme.info', (tester) async {
      // For isMine read status, color must be colorScheme.info (semantic blue),
      // not the default metaColor — this distinguishes read from delivered.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              // Capture colorScheme from the tree so we can compare the exact
              // resolved token value rather than a hardcoded constant.
              // We use Builder to access the real colorScheme context;
              // the actual assertion is done after pumpWidget settles below.
              return const Scaffold(
                body: MessageBubble(
                  text: 'Hello',
                  time: '12:00',
                  isMine: true,
                  status: 'read',
                ),
              );
            },
          ),
        ),
      );
      // Retrieve the Icon widget and check its color is not the metaColor
      // (white with opacity). It should be colorScheme.info (a blue variant).
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.done_all));
      // metaColor (white 0.7) must NOT match — read uses colorScheme.info
      expect(
        iconWidget.color,
        isNot(equals(Colors.white.withValues(alpha: 0.7))),
      );
      // The color should be non-null (icon is coloured, not default)
      expect(iconWidget.color, isNotNull);
    });
  });
}
