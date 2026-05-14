import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/skeleton_card_extended.dart';

import 'widget_test_helpers.dart';

void main() {
  group('Skeleton Card Extended Variants', () {
    testWidgets('T-CW120 SkeletonWalletHeroCard renders without error', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SkeletonWalletHeroCard());
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(SkeletonWalletHeroCard), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('T-CW121 SkeletonProposalTile renders without error', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SkeletonProposalTile());
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(SkeletonProposalTile), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('T-CW122 SkeletonWorkItemCard renders without error', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SkeletonWorkItemCard());
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(SkeletonWorkItemCard), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('T-CW123 SkeletonNotificationTile renders without error', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SkeletonNotificationTile());
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(SkeletonNotificationTile), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('T-CW124 SkeletonServiceCard renders without error', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SkeletonServiceCard());
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(SkeletonServiceCard), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('T-CW125 SkeletonFavoriteCard renders without error', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SkeletonFavoriteCard());
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(SkeletonFavoriteCard), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('T-CW126 SkeletonSearchResultCard renders without error', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SkeletonSearchResultCard());
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(SkeletonSearchResultCard), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('T-CW127 SkeletonProfileCard renders without error', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SkeletonProfileCard());
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(SkeletonProfileCard), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('T-CW128 SkeletonWorkItemCard uses Amber Dusk panel tokens', (
      tester,
    ) async {
      await pumpCoreWidget(tester, const SkeletonWorkItemCard());
      await tester.pump(const Duration(milliseconds: 16));

      final panelCard = AmberDuskTokens.widgetTheme.cards.panel;
      final rootContainer = tester.widget<Container>(
        find.byKey(SkeletonWorkItemCard.rootKey),
      );
      final decoration = rootContainer.decoration;

      if (decoration is! BoxDecoration) {
        throw TestFailure(
          'Expected SkeletonWorkItemCard root decoration to be BoxDecoration.',
        );
      }
      expect(decoration.color, panelCard.background);
      expect(_hasAmberSkeletonGradient(tester), isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
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
