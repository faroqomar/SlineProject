import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';

import 'widget_test_helpers.dart';

/// Verifies Amber Dusk loading-card surfaces and placeholder colors.
void main() {
  group('Skeleton Card Variants', () {
    testWidgets('SkeletonTaskCard uses Amber Dusk task surface tokens', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SkeletonTaskCard());

      final taskCard = AmberDuskTokens.widgetTheme.cards.task;
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasTaskSurface = containers.any((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration &&
            decoration.color == taskCard.background &&
            decoration.borderRadius == BorderRadius.circular(taskCard.radius);
      });

      expect(hasTaskSurface, isTrue);
      final skeletonTheme = AmberDuskTokens.widgetTheme.skeleton;
      final hasAmberDivider = containers.any((container) {
        final decoration = container.decoration;
        final border = decoration is BoxDecoration ? decoration.border : null;
        return border is Border && border.top.color == skeletonTheme.raised;
      });

      expect(hasAmberDivider, isTrue);
      expect(_hasAmberSkeletonGradient(tester), isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('SkeletonBookingCard uses Amber skeleton header colors', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SkeletonBookingCard());

      final skeletonTheme = AmberDuskTokens.widgetTheme.skeleton;
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasAmberHeader = containers.any((container) {
        final decoration = container.decoration;
        final gradient = decoration is BoxDecoration
            ? decoration.gradient
            : null;
        return gradient is LinearGradient &&
            gradient.colors.contains(skeletonTheme.raised) &&
            gradient.colors.contains(skeletonTheme.highlight);
      });

      expect(hasAmberHeader, isTrue);
      expect(_hasAmberSkeletonGradient(tester), isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('T-CW129 covers remaining base skeleton variants', (
      tester,
    ) async {
      final variants = <String, Widget>{
        'offer': const SkeletonOfferCard(),
        'message bubble': const SkeletonMessageBubble(),
        'conversation tile': const SkeletonConversationTile(),
        'search result': const SkeletonSearchResultCard(),
        'category tile': const SkeletonCategoryTile(),
        'favorite card': const SkeletonFavoriteCard(),
        'details screen': const SkeletonDetailsScreen(),
      };

      for (final entry in variants.entries) {
        await pumpCoreWidget(tester, entry.value);
        await tester.pump(const Duration(milliseconds: 16));

        expect(
          _hasAmberSkeletonGradient(tester),
          isTrue,
          reason:
              '${entry.key} should use Amber skeleton shimmer colors. '
              'Observed gradients: ${_gradientColorDebug(tester)}',
        );
        expect(
          find.byType(CircularProgressIndicator),
          findsNothing,
          reason: '${entry.key} should not render spinner loading UI.',
        );
      }
    });
  });
}

bool _hasAmberSkeletonGradient(WidgetTester tester) {
  final containerMatch = tester
      .widgetList<Container>(find.byType(Container))
      .any((container) => _isAmberSkeletonGradient(container.decoration));
  final decoratedBoxMatch = tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .any((box) => _isAmberSkeletonGradient(box.decoration));

  return containerMatch || decoratedBoxMatch;
}

bool _isAmberSkeletonGradient(Decoration? decoration) {
  final skeletonTheme = _themeSkeletonColors();
  final expectedColors = [
    skeletonTheme.base,
    skeletonTheme.highlight,
    skeletonTheme.base,
  ];
  final gradient = decoration is BoxDecoration ? decoration.gradient : null;
  return gradient is LinearGradient &&
      gradient.colors.length == expectedColors.length &&
      gradient.colors.indexed.every(
        (entry) => entry.$2.toARGB32() == expectedColors[entry.$1].toARGB32(),
      );
}

SkeletonColors _themeSkeletonColors() {
  final colors = AppTheme.light().extension<SkeletonColors>();
  if (colors == null) {
    throw TestFailure('Expected SkeletonColors extension in AppTheme.light().');
  }
  return colors;
}

List<List<int>> _gradientColorDebug(WidgetTester tester) {
  final gradients = <LinearGradient>[];
  for (final container in tester.widgetList<Container>(
    find.byType(Container),
  )) {
    final decoration = container.decoration;
    final gradient = decoration is BoxDecoration ? decoration.gradient : null;
    if (gradient is LinearGradient) gradients.add(gradient);
  }
  for (final box in tester.widgetList<DecoratedBox>(
    find.byType(DecoratedBox),
  )) {
    final decoration = box.decoration;
    final gradient = decoration is BoxDecoration ? decoration.gradient : null;
    if (gradient is LinearGradient) gradients.add(gradient);
  }
  return gradients
      .map(
        (gradient) => gradient.colors.map((color) => color.toARGB32()).toList(),
      )
      .toList();
}
