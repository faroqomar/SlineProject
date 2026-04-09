import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/favorites/data/favorites_service.dart';
import 'package:sline_app/features/favorites/models/favorite_with_profile_model.dart';
import 'package:sline_app/features/favorites/view/favorites_screen.dart';
import 'package:sline_app/features/favorites/viewmodels/favorites_view_model.dart';

import '../../../test_support/pump_app.dart';

class _MockFavoritesService extends Mock implements FavoritesService {}

void main() {
  late _MockFavoritesService mockService;

  setUp(() {
    mockService = _MockFavoritesService();
  });

  group('FavoritesScreen', () {
    testWidgets('shows empty state key when empty', (tester) async {
      when(
        () => mockService.listFavoritesWithProfile(),
      ).thenAnswer((_) async => <FavoriteWithProfile>[]);
      final vm = FavoritesViewModel(service: mockService);
      await pumpApp(
        tester,
        ChangeNotifierProvider<FavoritesViewModel>.value(
          value: vm,
          child: const FavoritesScreen(),
        ),
      );
      await vm.load();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorites_empty')), findsOneWidget);
      expect(find.text('No favorites yet'), findsOneWidget);
    });

    testWidgets('shows list key when items present', (tester) async {
      when(() => mockService.listFavoritesWithProfile()).thenAnswer(
        (_) async => [
          FavoriteWithProfile(
            id: 'f1',
            freelancerId: 'fl-1',
            createdAt: DateTime.utc(2026, 3, 1),
            freelancerName: 'Test User',
          ),
        ],
      );
      final vm = FavoritesViewModel(service: mockService);
      await pumpApp(
        tester,
        ChangeNotifierProvider<FavoritesViewModel>.value(
          value: vm,
          child: const FavoritesScreen(),
        ),
      );
      await vm.load();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorites_list')), findsOneWidget);
      expect(find.byKey(const Key('favorite_card_fl-1')), findsAtLeast(1));
    });

    testWidgets('does not show raw exception text in UI', (tester) async {
      when(() => mockService.listFavoritesWithProfile()).thenAnswer(
        (_) async => [
          FavoriteWithProfile(
            id: 'f1',
            freelancerId: 'fl-1',
            createdAt: DateTime.utc(2026, 3, 1),
            freelancerName: 'Test User',
          ),
        ],
      );
      final vm = FavoritesViewModel(service: mockService);
      await pumpApp(
        tester,
        ChangeNotifierProvider<FavoritesViewModel>.value(
          value: vm,
          child: const FavoritesScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to start chat:'), findsNothing);
    });
  });
}
