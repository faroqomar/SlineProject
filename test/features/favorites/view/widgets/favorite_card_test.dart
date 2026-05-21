import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/favorites/models/favorite_with_profile_model.dart';
import 'package:sline_app/features/favorites/view/widgets/favorite_card.dart';

import '../../../../test_support/pump_app.dart';

void main() {
  group('FavoriteCard', () {
    testWidgets('shows freelancer name and formatted date', (tester) async {
      final favorite = FavoriteWithProfile(
        id: 'f1',
        freelancerId: 'fl-1',
        createdAt: DateTime.utc(2026, 3, 1, 14, 30),
        freelancerName: 'Jane Doe',
      );
      await pumpApp(
        tester,
        FavoriteCard(
          key: Key('favorite_card_${favorite.freelancerId}'),
          favorite: favorite,
          onStartChat: () {},
          onRemove: () {},
        ),
      );

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
    });

    testWidgets('shows placeholder when name null', (tester) async {
      final favorite = FavoriteWithProfile(
        id: 'f2',
        freelancerId: 'fl-2',
        createdAt: DateTime.utc(2026, 3),
      );
      await pumpApp(
        tester,
        FavoriteCard(favorite: favorite, onStartChat: () {}, onRemove: () {}),
      );

      expect(find.text('Freelancer'), findsOneWidget);
    });

    testWidgets('fires chat and remove callbacks from action buttons', (
      tester,
    ) async {
      final favorite = FavoriteWithProfile(
        id: 'f3',
        freelancerId: 'fl-3',
        createdAt: DateTime.utc(2026, 3),
        freelancerName: 'Action User',
      );
      var startChatCount = 0;
      var removeCount = 0;

      await pumpApp(
        tester,
        FavoriteCard(
          favorite: favorite,
          onStartChat: () => startChatCount++,
          onRemove: () => removeCount++,
        ),
      );

      await tester.tap(find.byKey(const Key('favorite_card_start_chat_fl-3')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('favorite_card_remove_fl-3')));
      await tester.pump();

      expect(startChatCount, 1);
      expect(removeCount, 1);
    });
  });
}
