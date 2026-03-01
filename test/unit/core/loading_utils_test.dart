import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/utils/loading_utils.dart';

void main() {
  group('LoadingUtils', () {
    testWidgets('show inserts one overlay and close removes it', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.expand())),
      );

      final context = tester.element(find.byType(Scaffold));
      final handle = LoadingUtils.show(context);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      handle.close();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('close is idempotent even after disposal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.expand())),
      );

      final context = tester.element(find.byType(Scaffold));
      final handle = LoadingUtils.show(context);
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      handle.close();
      handle.close();

      expect(tester.takeException(), isNull);
    });
  });
}
