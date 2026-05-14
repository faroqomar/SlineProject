/// Tests the Amber Dusk loading overlay tokens and close lifecycle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/loading_utils.dart';

void main() {
  const colors = AmberDuskTokens.colors;
  final sheetRecipe = AmberDuskTokens.surfaces.sheet;

  group('LoadingUtils', () {
    testWidgets('show inserts one overlay and close removes it', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      final handle = LoadingUtils.show(context, debugLabel: 'unit-test');
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_loadingBarrierFinder(colors.light.scrim), findsOneWidget);

      handle.close();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('close is idempotent even after disposal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      final handle = LoadingUtils.show(context);
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      handle
        ..close()
        ..close();

      expect(tester.takeException(), isNull);
    });

    testWidgets('uses Amber Dusk solid scrim and sheet tokens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      final handle = LoadingUtils.show(context, debugLabel: 'token-check');
      await tester.pump();

      final barrier = tester.widget<ModalBarrier>(
        _loadingBarrierFinder(colors.scrim),
      );
      final progress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      final progressContainer = tester.widget<Container>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).color == sheetRecipe.fill,
        ),
      );
      final decoration = progressContainer.decoration! as BoxDecoration;

      expect(barrier.dismissible, isFalse);
      expect(barrier.color, colors.scrim);
      expect(progress.color, colors.primary);
      expect(progress.strokeWidth, AppDimens.p4);
      expect(decoration.color, sheetRecipe.fill);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(sheetRecipe.radius),
      );
      expect(decoration.boxShadow, isNotEmpty);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);

      handle.close();
      await tester.pump();
    });
  });
}

Finder _loadingBarrierFinder(Color color) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is ModalBarrier && widget.color == color && !widget.dismissible,
  );
}
