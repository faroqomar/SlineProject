import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/theme/app_theme.dart';

Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<NavigatorObserver> navigatorObservers = const [],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: child,
      navigatorObservers: navigatorObservers,
    ),
  );
  await tester.pump();
}
