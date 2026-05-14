import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';

import 'widget_test_helpers.dart';

/// Verifies Amber Dusk skeleton loading primitives without settling repeaters.
void main() {
  group('SkeletonLoader', () {
    testWidgets('uses Amber Dusk skeleton gradient tokens', (tester) async {
      await pumpCoreWidget(
        tester,
        const SkeletonLoader(width: 120, height: 20),
      );
      await tester.pump(const Duration(milliseconds: 16));

      final gradient = _skeletonGradient(tester);
      final skeletonColors = _themeSkeletonColors();
      expect(gradient.colors, [
        skeletonColors.base,
        skeletonColors.highlight,
        skeletonColors.base,
      ]);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders circular avatars with shimmer, not a spinner', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SkeletonAvatar());
      await tester.pump(const Duration(milliseconds: 16));

      final decoration = _skeletonDecoration(tester);
      expect(decoration.shape, BoxShape.circle);
      final gradient = _skeletonGradient(tester);
      final skeletonColors = _themeSkeletonColors();
      expect(gradient.colors, [
        skeletonColors.base,
        skeletonColors.highlight,
        skeletonColors.base,
      ]);
      expect(gradient.stops, const [0.0, 0.5, 1.0]);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('animates the shimmer gradient over time', (tester) async {
      await pumpCoreWidget(
        tester,
        const SkeletonLoader(width: 120, height: 20),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final firstGradient = _skeletonGradient(tester);

      await tester.pump(const Duration(milliseconds: 96));
      final nextGradient = _skeletonGradient(tester);

      expect(nextGradient.begin, isNot(firstGradient.begin));
      expect(nextGradient.end, isNot(firstGradient.end));
    });
  });
}

Finder _skeletonContainerFinder() {
  return find.descendant(
    of: find.byType(SkeletonLoader),
    matching: find.byType(Container),
  );
}

BoxDecoration _skeletonDecoration(WidgetTester tester) {
  final finder = _skeletonContainerFinder();
  expect(finder, findsOneWidget);
  final container = tester.widget<Container>(finder);
  final decoration = container.decoration;
  if (decoration is! BoxDecoration) {
    throw TestFailure('Expected skeleton decoration to be BoxDecoration.');
  }
  return decoration;
}

LinearGradient _skeletonGradient(WidgetTester tester) {
  final gradient = _skeletonDecoration(tester).gradient;
  if (gradient is! LinearGradient) {
    throw TestFailure('Expected skeleton gradient to be LinearGradient.');
  }
  return gradient;
}

SkeletonColors _themeSkeletonColors() {
  final colors = AppTheme.light().extension<SkeletonColors>();
  if (colors == null) {
    throw TestFailure('Expected SkeletonColors extension in AppTheme.light().');
  }
  return colors;
}
