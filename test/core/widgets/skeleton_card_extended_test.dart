import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/widgets/skeleton_card_extended.dart';

import 'widget_test_helpers.dart';

void main() {
  group('Skeleton Card Extended Variants', () {
    testWidgets('T-CW120 SkeletonWalletHeroCard renders without error',
        (tester) async {
      await pumpCoreWidget(tester, const SkeletonWalletHeroCard());
      expect(find.byType(SkeletonWalletHeroCard), findsOneWidget);
    });

    testWidgets('T-CW121 SkeletonProposalTile renders without error',
        (tester) async {
      await pumpCoreWidget(tester, const SkeletonProposalTile());
      expect(find.byType(SkeletonProposalTile), findsOneWidget);
    });

    testWidgets('T-CW122 SkeletonWorkItemCard renders without error',
        (tester) async {
      await pumpCoreWidget(tester, const SkeletonWorkItemCard());
      expect(find.byType(SkeletonWorkItemCard), findsOneWidget);
    });

    testWidgets('T-CW123 SkeletonNotificationTile renders without error',
        (tester) async {
      await pumpCoreWidget(tester, const SkeletonNotificationTile());
      expect(find.byType(SkeletonNotificationTile), findsOneWidget);
    });

    testWidgets('T-CW124 SkeletonServiceCard renders without error',
        (tester) async {
      await pumpCoreWidget(tester, const SkeletonServiceCard());
      expect(find.byType(SkeletonServiceCard), findsOneWidget);
    });

    testWidgets('T-CW125 SkeletonFavoriteCard renders without error',
        (tester) async {
      await pumpCoreWidget(tester, const SkeletonFavoriteCard());
      expect(find.byType(SkeletonFavoriteCard), findsOneWidget);
    });

    testWidgets('T-CW126 SkeletonSearchResultCard renders without error',
        (tester) async {
      await pumpCoreWidget(tester, const SkeletonSearchResultCard());
      expect(find.byType(SkeletonSearchResultCard), findsOneWidget);
    });

    testWidgets('T-CW127 SkeletonProfileCard renders without error',
        (tester) async {
      await pumpCoreWidget(tester, const SkeletonProfileCard());
      expect(find.byType(SkeletonProfileCard), findsOneWidget);
    });
  });
}
