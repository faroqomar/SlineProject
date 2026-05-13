/// Tests Phase 9 profile dialogs that guard destructive or report actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/features/profile/view/public_profile_screen.dart';
import 'package:sline_app/features/profile/view/settings_screen.dart';

void main() {
  group('LogoutConfirmationDialog', () {
    testWidgets('cancel returns false', (tester) async {
      bool? result;

      await _pumpDialogLauncher(
        tester,
        onOpen: (context) async {
          result = await showDialog<bool>(
            context: context,
            builder: (_) => const LogoutConfirmationDialog(),
          );
        },
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('confirm returns true', (tester) async {
      bool? result;

      await _pumpDialogLauncher(
        tester,
        onOpen: (context) async {
          result = await showDialog<bool>(
            context: context,
            builder: (_) => const LogoutConfirmationDialog(),
          );
        },
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out').last);
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('ReportUserDialog', () {
    testWidgets('submit stays disabled until reason is non-empty', (
      tester,
    ) async {
      String? result;

      await _pumpDialogLauncher(
        tester,
        onOpen: (context) async {
          result = await showDialog<String>(
            context: context,
            builder: (_) => const ReportUserDialog(),
          );
        },
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      final disabledSubmit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit'),
      );
      expect(disabledSubmit.onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Spam profile');
      await tester.pump();

      final enabledSubmit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit'),
      );
      expect(enabledSubmit.onPressed, isNotNull);

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(result, 'Spam profile');
    });
  });
}

Future<void> _pumpDialogLauncher(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onOpen,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => onOpen(context),
              child: const Text('Open dialog'),
            );
          },
        ),
      ),
    ),
  );
}
