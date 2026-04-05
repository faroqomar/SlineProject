import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/profile/models/profile_model.dart';
import 'package:sline_app/features/search/viewmodels/search_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

import '../../helpers/mock_services.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Task _task({required String id, String title = 'Task'}) {
  return Task(
    id: id,
    title: title,
    description: 'desc',
    budget: 50,
    userId: 'u1',
    status: TaskStatus.open,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

ProfileModel _profile({required String id, String? name}) {
  return ProfileModel(
    id: id,
    fullName: name ?? 'Profile $id',
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  late MockSearchService service;

  setUp(() {
    service = MockSearchService();
  });

  SearchViewModel buildVm() => SearchViewModel(service);

  // -----------------------------------------------------------------------
  // 1. Initial state
  // -----------------------------------------------------------------------
  test('initial state: empty results, no loading, no error', () {
    final vm = buildVm();

    expect(vm.tasks, isEmpty);
    expect(vm.profiles, isEmpty);
    expect(vm.isLoading, isFalse);
    expect(vm.error, isNull);
    expect(vm.query, isEmpty);
    expect(vm.activeTab, SearchTab.findWork);
    expect(vm.isTasksTab, isTrue);

    vm.dispose();
  });

  // -----------------------------------------------------------------------
  // 2. onSearchChanged with query triggers search after debounce
  // -----------------------------------------------------------------------
  test('onSearchChanged with query triggers search after debounce', () async {
    when(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => [_task(id: 't1')]);

    final vm = buildVm();

    vm.onSearchChanged('flutter');

    // Before debounce fires, service should NOT have been called
    verifyNever(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    );

    // Wait for the 500ms debounce + processing
    await Future<void>.delayed(const Duration(milliseconds: 600));

    verify(
      () => service.searchTasks(
        query: 'flutter',
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).called(1);
    expect(vm.tasks.length, 1);
    expect(vm.isLoading, isFalse);

    vm.dispose();
  });

  // -----------------------------------------------------------------------
  // 3. onSearchChanged with empty query clears results
  // -----------------------------------------------------------------------
  test('onSearchChanged with empty query clears results', () async {
    when(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => [_task(id: 't1')]);

    final vm = buildVm();

    // First perform a search
    vm.onSearchChanged('flutter');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(vm.tasks.length, 1);

    // Now clear with empty query
    vm.onSearchChanged('');
    expect(vm.tasks, isEmpty);
    expect(vm.profiles, isEmpty);
    expect(vm.isLoading, isFalse);
    expect(vm.error, isNull);

    vm.dispose();
  });

  // -----------------------------------------------------------------------
  // 4. setTab changes active tab and triggers new search
  // -----------------------------------------------------------------------
  test('setTab changes active tab and triggers new search if query exists',
      () async {
    when(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => [_task(id: 't1')]);
    when(
      () => service.searchProfiles(
        query: any(named: 'query'),
        roleFilter: any(named: 'roleFilter'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => [_profile(id: 'p1')]);

    final vm = buildVm();

    // Search on tasks tab first
    vm.onSearchChanged('test');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(vm.activeTab, SearchTab.findWork);
    expect(vm.tasks.length, 1);

    // Switch tab to findTalent -- should trigger searchProfiles
    vm.setTab(SearchTab.findTalent);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(vm.activeTab, SearchTab.findTalent);
    expect(vm.isTasksTab, isFalse);

    verify(
      () => service.searchProfiles(
        query: 'test',
        roleFilter: any(named: 'roleFilter'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).called(1);

    vm.dispose();
  });

  // -----------------------------------------------------------------------
  // 5. setTab with empty query clears results without search
  // -----------------------------------------------------------------------
  test('setTab with empty query clears results without triggering search', () {
    final vm = buildVm();

    vm.setTab(SearchTab.findTalent);

    expect(vm.activeTab, SearchTab.findTalent);
    expect(vm.tasks, isEmpty);
    expect(vm.profiles, isEmpty);

    verifyNever(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    );
    verifyNever(
      () => service.searchProfiles(
        query: any(named: 'query'),
        roleFilter: any(named: 'roleFilter'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    );

    vm.dispose();
  });

  // -----------------------------------------------------------------------
  // 6. setTab to same tab is no-op
  // -----------------------------------------------------------------------
  test('setTab to same tab is a no-op', () {
    final vm = buildVm();

    var notified = false;
    vm.addListener(() => notified = true);

    vm.setTab(SearchTab.findWork); // already the default
    expect(notified, isFalse);

    vm.dispose();
  });

  // -----------------------------------------------------------------------
  // 7. Search happy path: returns task results
  // -----------------------------------------------------------------------
  test('search happy path returns task results on findWork tab', () async {
    final tasks = [_task(id: 't1'), _task(id: 't2'), _task(id: 't3')];
    when(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => tasks);

    final vm = buildVm();

    vm.onSearchChanged('design');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(vm.tasks.length, 3);
    expect(vm.tasks.first.id, 't1');
    expect(vm.error, isNull);
    expect(vm.isLoading, isFalse);

    vm.dispose();
  });

  // -----------------------------------------------------------------------
  // 8. Search happy path: returns profile results
  // -----------------------------------------------------------------------
  test('search happy path returns profile results on findTalent tab',
      () async {
    final profiles = [_profile(id: 'p1'), _profile(id: 'p2')];
    when(
      () => service.searchProfiles(
        query: any(named: 'query'),
        roleFilter: any(named: 'roleFilter'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => profiles);

    final vm = buildVm();
    vm.setTab(SearchTab.findTalent);

    vm.onSearchChanged('developer');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(vm.profiles.length, 2);
    expect(vm.profiles.first.id, 'p1');
    expect(vm.error, isNull);
    expect(vm.isLoading, isFalse);

    vm.dispose();
  });

  // -----------------------------------------------------------------------
  // 9. Search error sets error state
  // -----------------------------------------------------------------------
  test('search error sets error state', () async {
    when(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenThrow(Exception('Network error'));

    final vm = buildVm();

    vm.onSearchChanged('fail');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(vm.error, 'Failed to search. Please try again.');
    expect(vm.isLoading, isFalse);

    vm.dispose();
  });

  // -----------------------------------------------------------------------
  // 10. Empty results: correct empty state
  // -----------------------------------------------------------------------
  test('empty search results yield correct empty state', () async {
    when(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => <Task>[]);

    final vm = buildVm();

    vm.onSearchChanged('nonexistent');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(vm.tasks, isEmpty);
    expect(vm.error, isNull);
    expect(vm.isLoading, isFalse);

    vm.dispose();
  });

  // -----------------------------------------------------------------------
  // 11. Dispose cancels debounce timer (no late error)
  // -----------------------------------------------------------------------
  test('dispose cancels debounce timer without errors', () async {
    when(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => [_task(id: 't1')]);

    final vm = buildVm();

    vm.onSearchChanged('test');
    // Dispose immediately before debounce fires
    vm.dispose();

    // Wait past debounce to ensure no error is thrown
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // If we reach here without error, the debounce was properly cancelled
    verifyNever(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    );
  });

  // -----------------------------------------------------------------------
  // 12. retry re-runs the last search
  // -----------------------------------------------------------------------
  test('retry re-runs the last search', () async {
    var callCount = 0;
    when(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) throw Exception('Temporary error');
      return [_task(id: 't1')];
    });

    final vm = buildVm();

    // First search fails
    vm.onSearchChanged('retry-test');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(vm.error, isNotNull);

    // Retry succeeds
    vm.retry();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(vm.tasks.length, 1);
    expect(vm.error, isNull);

    vm.dispose();
  });

  // -----------------------------------------------------------------------
  // 13. Debounce resets when query changes rapidly
  // -----------------------------------------------------------------------
  test('rapid query changes only fire one search (debounce resets)', () async {
    when(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => [_task(id: 't1')]);

    final vm = buildVm();

    vm.onSearchChanged('a');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    vm.onSearchChanged('ab');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    vm.onSearchChanged('abc');

    // Wait for the debounce to fire for the final query
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // Only the last query should have triggered a search
    verify(
      () => service.searchTasks(
        query: 'abc',
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).called(1);

    // The earlier queries should NOT have triggered searches
    verifyNever(
      () => service.searchTasks(
        query: 'a',
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    );
    verifyNever(
      () => service.searchTasks(
        query: 'ab',
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    );

    vm.dispose();
  });

  // -----------------------------------------------------------------------
  // 14. Results lists are unmodifiable
  // -----------------------------------------------------------------------
  test('tasks and profiles getters return unmodifiable lists', () async {
    when(
      () => service.searchTasks(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => [_task(id: 't1')]);

    final vm = buildVm();

    vm.onSearchChanged('test');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(() => (vm.tasks as List).add(_task(id: 'x')), throwsA(isA<Error>()));
    expect(
      () => (vm.profiles as List).add(_profile(id: 'x')),
      throwsA(isA<Error>()),
    );

    vm.dispose();
  });
}
