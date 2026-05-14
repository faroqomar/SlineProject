import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/portfolio/models/portfolio_item.dart';
import 'package:sline_app/features/portfolio/viewmodels/portfolio_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mock_services.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockUser extends Mock implements User {}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

PortfolioItem _item({required String id, String title = 'Item'}) {
  return PortfolioItem(
    id: id,
    ownerId: 'owner-1',
    title: title,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

final List<PortfolioItem> _sampleItems = [
  _item(id: 'p1', title: 'Project Alpha'),
  _item(id: 'p2', title: 'Project Beta'),
];

void main() {
  late MockPortfolioRepository repo;
  late _MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repo = MockPortfolioRepository();
    mockUser = _MockUser();
    when(() => mockUser.id).thenReturn('owner-1');

    // Default stubs
    when(() => repo.currentUser).thenReturn(mockUser);

    when(
      () => repo.listItems(
        ownerId: any(named: 'ownerId'),
        limit: any(named: 'limit'),
        cursorCreatedAtIso: any(named: 'cursorCreatedAtIso'),
      ),
    ).thenAnswer((_) async => _sampleItems);

    when(
      () => repo.addItem(
        ownerId: any(named: 'ownerId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        imageBytes: any(named: 'imageBytes'),
        imageFilename: any(named: 'imageFilename'),
      ),
    ).thenAnswer((_) async => _item(id: 'p-new', title: 'New Item'));

    when(
      () => repo.deleteItem(
        id: any(named: 'id'),
        alsoDeleteImage: any(named: 'alsoDeleteImage'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => repo.updateItem(
        id: any(named: 'id'),
        title: any(named: 'title'),
        description: any(named: 'description'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => repo.getImageUrl(any()),
    ).thenReturn('https://example.com/img.jpg');
  });

  PortfolioViewModel buildVM() {
    return PortfolioViewModel(repository: repo);
  }

  group('PortfolioViewModel', () {
    // ----- 1. Construction: initial empty state -----
    test('initial state has empty items, not loading, no error', () {
      final vm = buildVM();
      addTearDown(vm.dispose);

      expect(vm.items, isEmpty);
      expect(vm.initialLoading, isFalse);
      expect(vm.error, isNull);
      expect(vm.hasMore, isTrue);
    });

    // ----- 2. load fetches portfolio items for owner -----
    test('load fetches portfolio items for owner', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load(ownerId: 'owner-1');

      expect(vm.items, hasLength(2));
      expect(vm.items.first.title, 'Project Alpha');
      expect(vm.error, isNull);
      expect(vm.ownerId, 'owner-1');
    });

    // ----- 3. load error sets error state -----
    test('load error sets error state', () async {
      when(
        () => repo.listItems(
          ownerId: any(named: 'ownerId'),
          limit: any(named: 'limit'),
          cursorCreatedAtIso: any(named: 'cursorCreatedAtIso'),
        ),
      ).thenThrow(Exception('DB connection failed'));

      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load(ownerId: 'owner-1');

      expect(vm.error, isNotNull);
      expect(vm.items, isEmpty);
      expect(vm.hasMore, isFalse);
    });

    // ----- 4. addItem happy path: calls repository, inserts at front -----
    test('addItem calls repository and inserts item at front', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load(ownerId: 'owner-1');
      expect(vm.items, hasLength(2));

      final result = await vm.addItem(title: 'New Item');

      expect(result, isTrue);
      expect(vm.items, hasLength(3));
      expect(vm.items.first.id, 'p-new');
      expect(vm.error, isNull);
    });

    // ----- 5. addItem error sets error -----
    test('addItem error sets error and returns false', () async {
      when(
        () => repo.addItem(
          ownerId: any(named: 'ownerId'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          imageBytes: any(named: 'imageBytes'),
          imageFilename: any(named: 'imageFilename'),
        ),
      ).thenThrow(Exception('Upload failed'));

      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load(ownerId: 'owner-1');

      final result = await vm.addItem(title: 'Fail Item');

      expect(result, isFalse);
      expect(vm.error, isNotNull);
    });

    // ----- 6. deleteItem happy path: calls repository, removes from list -----
    test('deleteItem removes item from list and returns true', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load(ownerId: 'owner-1');
      expect(vm.items, hasLength(2));

      final result = await vm.deleteItem('p1');

      expect(result, isTrue);
      expect(vm.items, hasLength(1));
      expect(vm.items.first.id, 'p2');
      expect(vm.error, isNull);
    });

    // ----- 7. deleteItem error sets error -----
    test('deleteItem error sets error and returns false', () async {
      when(
        () => repo.deleteItem(
          id: any(named: 'id'),
          alsoDeleteImage: any(named: 'alsoDeleteImage'),
        ),
      ).thenThrow(Exception('Permission denied'));

      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load(ownerId: 'owner-1');

      final result = await vm.deleteItem('p1');

      expect(result, isFalse);
      expect(vm.error, isNotNull);
    });

    // ----- 8. items getter returns unmodifiable list -----
    test('items getter returns unmodifiable list', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load(ownerId: 'owner-1');

      expect(
        () => vm.items.add(_item(id: 'x')),
        throwsA(isA<UnsupportedError>()),
      );
    });

    // ----- 9. load without ownerId uses currentUser -----
    test('load without ownerId falls back to currentUser', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load();

      expect(vm.ownerId, 'owner-1');
      expect(vm.items, hasLength(2));
    });

    // ----- 10. load when unauthenticated sets error -----
    test('load when unauthenticated sets error', () async {
      when(() => repo.currentUser).thenReturn(null);

      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load();

      expect(vm.error, contains('Not authenticated'));
      expect(vm.items, isEmpty);
    });

    // ----- 11. clear resets all state -----
    test('clear resets all state', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load(ownerId: 'owner-1');
      expect(vm.items, isNotEmpty);

      vm.clear();

      expect(vm.items, isEmpty);
      expect(vm.ownerId, isNull);
      expect(vm.error, isNull);
      expect(vm.hasMore, isTrue);
    });

    // ----- 12. updateItem happy path -----
    test('updateItem updates local item and returns true', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load(ownerId: 'owner-1');

      final result = await vm.updateItem(
        id: 'p1',
        title: 'Updated Alpha',
        description: 'New description',
      );

      expect(result, isTrue);
      expect(vm.items.first.title, 'Updated Alpha');
      expect(vm.error, isNull);
    });
  });
}
