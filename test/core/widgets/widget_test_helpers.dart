import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/l10n/app_localizations.dart';

/// Pumps a single widget in a minimal MaterialApp with SLine light theme.
///
/// Use this for isolated core widget component tests where you don't need
/// full app routing or provider trees. For full-screen tests, use
/// `test_support/pump_app.dart` instead.
Future<void> pumpCoreWidget(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pump();
}

/// Pumps a single widget in a minimal MaterialApp with SLine dark theme.
///
/// Use this to verify dark mode rendering of core widgets.
Future<void> pumpCoreWidgetDark(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pump();
}

/// Expects a [Semantics] widget with the given [label] to exist in the tree.
///
/// Example:
/// ```dart
/// expectSemantics(tester, label: 'Submit');
/// ```
void expectSemanticsLabel(WidgetTester tester, {required String label}) {
  final handle = tester.ensureSemantics();
  expect(
    find.bySemanticsLabel(label),
    findsWidgets,
    reason: 'Expected Semantics with label "$label"',
  );
  handle.dispose();
}
