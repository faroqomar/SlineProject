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
        createdAt: DateTime.utc(2026, 3, 1),
        freelancerName: null,
      );
      await pumpApp(
        tester,
        FavoriteCard(favorite: favorite, onStartChat: () {}, onRemove: () {}),
      );

      expect(find.text('Freelancer'), findsOneWidget);
    });
  });
}
