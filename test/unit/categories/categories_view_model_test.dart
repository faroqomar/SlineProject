import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/categories/models/category_model.dart';
import 'package:sline_app/features/categories/viewmodels/categories_view_model.dart';

import '../../helpers/mock_services.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

CategoryModel _cat({required String id, required String name}) {
  return CategoryModel(
    id: id,
    name: name,
    iconUrl: null,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

final _sampleCategories = [
  _cat(id: 'c1', name: 'Design'),
  _cat(id: 'c2', name: 'Development'),
  _cat(id: 'c3', name: 'Marketing'),
];

void main() {
  late MockCategoriesRepository repo;

  setUp(() {
    repo = MockCategoriesRepository();

    // Default stubs
    when(
      () => repo.getAll(
        search: any(named: 'search'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => _sampleCategories);

    when(
      () => repo.getAll(search: any(named: 'search')),
    ).thenAnswer((_) async => _sampleCategories);

    when(() => repo.clearCache()).thenReturn(null);
  });

  CategoriesViewModel buildVM() {
    return CategoriesViewModel(repository: repo);
  }

  group('CategoriesViewModel', () {
    // ----- 1. Construction: initial empty state -----
    test('initial state has empty items, not loading, no error', () {
      final vm = buildVM();
      addTearDown(vm.dispose);

      expect(vm.items, isEmpty);
      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
      expect(vm.searchQuery, isEmpty);
    });

    // ----- 2. load fetches categories from repository -----
    test('load fetches categories from repository', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load();

      expect(vm.items, hasLength(3));
      expect(vm.items.first.name, 'Design');
      expect(vm.error, isNull);
    });

    // ----- 3. load error sets error state -----
    test('load error sets error state', () async {
      when(
        () => repo.getAll(
          search: any(named: 'search'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('Network failure'));
      when(
        () => repo.getAll(search: any(named: 'search')),
      ).thenThrow(Exception('Network failure'));

      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load();

      expect(vm.error, 'Failed to load categories');
      expect(vm.items, isEmpty);
    });

    // ----- 4. load sets loading flag during operation -----
    test('load sets isLoading true during operation', () async {
      final loadingStates = <bool>[];
      final vm = buildVM();
      addTearDown(vm.dispose);

      vm.addListener(() => loadingStates.add(vm.isLoading));

      await vm.load();

      expect(loadingStates.first, isTrue);
      expect(loadingStates.last, isFalse);
    });

    // ----- 5. setSearchQuery triggers reload with query -----
    test('setSearchQuery triggers load with query parameter', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.setSearchQuery('Design');

      expect(vm.searchQuery, 'Design');
      // Verify getAll was called with search parameter
      verify(() => repo.getAll(search: 'Design')).called(1);
    });

    // ----- 6. items getter returns unmodifiable list -----
    test('items getter returns unmodifiable list', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load();

      expect(vm.items, isA<List<CategoryModel>>());
      expect(
        () => vm.items.add(_cat(id: 'x', name: 'X')),
        throwsA(isA<UnsupportedError>()),
      );
    });

    // ----- 7. load with empty result: empty list, no error -----
    test('load with empty result sets empty list and no error', () async {
      when(
        () => repo.getAll(
          search: any(named: 'search'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => repo.getAll(search: any(named: 'search')),
      ).thenAnswer((_) async => []);

      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load();

      expect(vm.items, isEmpty);
      expect(vm.error, isNull);
    });

    // ----- 8. Repeated load replaces previous data -----
    test('repeated load replaces previous data', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.load();
      expect(vm.items, hasLength(3));

      // Second load with different data
      final newData = [_cat(id: 'c4', name: 'Writing')];
      when(
        () => repo.getAll(
          search: any(named: 'search'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => newData);
      when(
        () => repo.getAll(search: any(named: 'search')),
      ).thenAnswer((_) async => newData);

      await vm.load();

      expect(vm.items, hasLength(1));
      expect(vm.items.first.name, 'Writing');
    });

    // ----- 9. refresh uses current search query -----
    test('refresh reloads using current search query', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.setSearchQuery('Dev');
      clearInteractions(repo);

      await vm.refresh();

      verify(() => repo.getAll(search: 'Dev')).called(1);
    });

    // ----- 10. setSearchQuery with empty string passes null search -----
    test('setSearchQuery with empty string passes null search', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.setSearchQuery('');

      verify(() => repo.getAll(search: null)).called(1);
    });
  });
}
