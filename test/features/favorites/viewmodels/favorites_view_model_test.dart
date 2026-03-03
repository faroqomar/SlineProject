import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/favorites/data/favorites_service.dart';
import 'package:sline_app/features/favorites/models/favorite_with_profile_model.dart';
import 'package:sline_app/features/favorites/models/favorites_mutation_result.dart';
import 'package:sline_app/features/favorites/viewmodels/favorites_view_model.dart';

class MockFavoritesService extends Mock implements FavoritesService {}

void main() {
  late MockFavoritesService mockService;
  late FavoritesViewModel vm;

  setUp(() {
    mockService = MockFavoritesService();
    vm = FavoritesViewModel(service: mockService);
  });

  group('FavoritesViewModel load', () {
    test('load sets items from listFavoritesWithProfile', () async {
      when(() => mockService.listFavoritesWithProfile()).thenAnswer((_) async => [
            FavoriteWithProfile(
              id: 'f1',
              freelancerId: 'fl-1',
              createdAt: DateTime.utc(2026, 3, 1),
              freelancerName: 'Alice',
            ),
          ]);

      await vm.load();

      expect(vm.itemsWithProfile.length, 1);
      expect(vm.itemsWithProfile.first.freelancerId, 'fl-1');
      expect(vm.items.length, 1);
      expect(vm.items.first.freelancerId, 'fl-1');
      expect(vm.error, null);
    });

    test('load on error sets error and does not crash', () async {
      when(() => mockService.listFavoritesWithProfile())
          .thenThrow(Exception('network'));

      await vm.load();

      expect(vm.itemsWithProfile, isEmpty);
      expect(vm.error, isNotNull);
    });

    test('ensureLoaded skips when already loaded even with empty list', () async {
      when(() => mockService.listFavoritesWithProfile()).thenAnswer((_) async => []);

      await vm.load();
      expect(vm.itemsWithProfile, isEmpty);

      await vm.ensureLoaded();
      await vm.ensureLoaded();
      verify(() => mockService.listFavoritesWithProfile()).called(1);
    });
  });

  group('FavoritesViewModel add', () {
    test('add returns success when service succeeds', () async {
      when(() => mockService.addFavorite(any())).thenAnswer((_) async {});
      when(() => mockService.listFavoritesWithProfile()).thenAnswer((_) async => []);

      final result = await vm.add('fl-1');

      expect(result, FavoritesMutationResult.success);
    });

    test('add returns duplicate when 23505', () async {
      when(() => mockService.addFavorite(any())).thenThrow(
        Exception('23505 unique_violation'),
      );

      final result = await vm.add('fl-1');

      expect(result, FavoritesMutationResult.duplicate);
    });
  });

  group('FavoritesViewModel remove', () {
    test('remove returns success when service succeeds', () async {
      when(() => mockService.removeFavorite(any())).thenAnswer((_) async {});

      final result = await vm.remove('fl-1');

      expect(result, FavoritesMutationResult.success);
    });

    test('remove updates in-memory list on success', () async {
      when(() => mockService.removeFavorite(any())).thenAnswer((_) async {});
      vm = FavoritesViewModel(service: mockService);
      // Seed state
      when(() => mockService.listFavoritesWithProfile()).thenAnswer((_) async => [
            FavoriteWithProfile(
              id: 'f1',
              freelancerId: 'fl-1',
              createdAt: DateTime.utc(2026, 3, 1),
            ),
          ]);
      await vm.load();
      expect(vm.itemsWithProfile.length, 1);

      await vm.remove('fl-1');

      expect(vm.itemsWithProfile, isEmpty);
      expect(vm.items, isEmpty);
    });
  });
}
