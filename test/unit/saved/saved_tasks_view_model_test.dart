import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/mock_supabase.dart';

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

/// Build a SavedTasksViewModel with all Supabase stubs pre-configured.
///
/// The auth stream controller is returned so tests can push auth events.
/// [currentUser] controls whether the VM triggers an initial load.
({SavedTasksViewModel vm, StreamController<AuthState> authCtrl})
_buildVm({
  required MockSavedTasksService service,
  User? currentUser,
}) {
  final mockClient = MockSupabaseClient();
  final mockAuth = MockGoTrueClient();
  final authCtrl = StreamController<AuthState>.broadcast(sync: true);

  when(() => mockClient.auth).thenReturn(mockAuth);
  when(() => mockAuth.currentUser).thenReturn(currentUser);
  when(() => mockAuth.onAuthStateChange).thenAnswer((_) => authCtrl.stream);

  final vm = SavedTasksViewModel(service: service, client: mockClient);
  return (vm: vm, authCtrl: authCtrl);
}

void main() {
  late MockSavedTasksService service;

  setUp(() {
    service = MockSavedTasksService();
  });

  // -----------------------------------------------------------------------
  // 1. Construction: initializes auth listener, no auto-load when logged out
  // -----------------------------------------------------------------------
  test('construction: no auto-load when user is not logged in', () async {
    when(() => service.listMineWithDetails()).thenAnswer((_) async => <Task>[]);

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    // Give microtasks time to settle
    await Future<void>.delayed(Duration.zero);

    // No load should have been triggered since currentUser is null
    verifyNever(() => service.listMineWithDetails());
    expect(vm.isLoading, isFalse);

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 2. Construction: auto-loads when user is already logged in
  // -----------------------------------------------------------------------
  test('construction: auto-loads when user is already logged in', () async {
    final tasks = [_task(id: 't1'), _task(id: 't2')];
    when(() => service.listMineWithDetails()).thenAnswer((_) async => tasks);

    final mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user-1');

    final result = _buildVm(service: service, currentUser: mockUser);
    final vm = result.vm;

    // Wait for async load to complete
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verify(() => service.listMineWithDetails()).called(1);
    expect(vm.savedTaskIds, ['t1', 't2']);
    expect(vm.savedTasks.length, 2);

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 3. load: fetches saved task IDs from service
  // -----------------------------------------------------------------------
  test('load fetches saved task IDs from service', () async {
    final tasks = [_task(id: 'a'), _task(id: 'b'), _task(id: 'c')];
    when(() => service.listMineWithDetails()).thenAnswer((_) async => tasks);

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    await vm.load();

    expect(vm.savedTaskIds, ['a', 'b', 'c']);
    expect(vm.savedTasks.length, 3);
    expect(vm.isLoading, isFalse);
    expect(vm.error, isNull);

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 4. load error: sets error state
  // -----------------------------------------------------------------------
  test('load error sets error state', () async {
    when(
      () => service.listMineWithDetails(),
    ).thenThrow(Exception('Network error'));

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    await vm.load();

    expect(vm.error, isNotNull);
    expect(vm.isLoading, isFalse);

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 5. isSaved: returns true for saved task ID
  // -----------------------------------------------------------------------
  test('isSaved returns true for saved task ID', () async {
    when(
      () => service.listMineWithDetails(),
    ).thenAnswer((_) async => [_task(id: 'saved-1')]);

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    await vm.load();

    expect(vm.isSaved('saved-1'), isTrue);

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 6. isSaved: returns false for unsaved task ID
  // -----------------------------------------------------------------------
  test('isSaved returns false for unsaved task ID', () async {
    when(
      () => service.listMineWithDetails(),
    ).thenAnswer((_) async => [_task(id: 'saved-1')]);

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    await vm.load();

    expect(vm.isSaved('not-saved'), isFalse);

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 7. toggle (save): adds task ID and calls service
  // -----------------------------------------------------------------------
  test('toggle save adds task ID and calls service', () async {
    when(() => service.listMineWithDetails()).thenAnswer((_) async => <Task>[]);
    when(() => service.toggle(any())).thenAnswer((_) async => true);

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    await vm.load();
    expect(vm.isSaved('new-task'), isFalse);

    final saved = await vm.toggle('new-task');

    expect(saved, isTrue);
    expect(vm.isSaved('new-task'), isTrue);
    verify(() => service.toggle('new-task')).called(1);

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 8. toggle (unsave): removes task ID and calls service
  // -----------------------------------------------------------------------
  test('toggle unsave removes task ID and calls service', () async {
    when(
      () => service.listMineWithDetails(),
    ).thenAnswer((_) async => [_task(id: 'existing')]);
    when(() => service.toggle(any())).thenAnswer((_) async => false);

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    await vm.load();
    expect(vm.isSaved('existing'), isTrue);

    final saved = await vm.toggle('existing');

    expect(saved, isFalse);
    expect(vm.isSaved('existing'), isFalse);
    verify(() => service.toggle('existing')).called(1);

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 9. toggle error: sets error state and rethrows
  // -----------------------------------------------------------------------
  test('toggle error sets error state and rethrows', () async {
    when(() => service.listMineWithDetails()).thenAnswer((_) async => <Task>[]);
    when(() => service.toggle(any())).thenThrow(Exception('DB error'));

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    await vm.load();

    await expectLater(() => vm.toggle('fail-task'), throwsA(isA<Exception>()));
    expect(vm.error, isNotNull);

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 10. savedTaskIds getter: returns unmodifiable list
  // -----------------------------------------------------------------------
  test('savedTaskIds getter returns unmodifiable list', () async {
    when(
      () => service.listMineWithDetails(),
    ).thenAnswer((_) async => [_task(id: 't1')]);

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    await vm.load();

    expect(
      () => (vm.savedTaskIds as List).add('hack'),
      throwsA(isA<Error>()),
    );

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 11. Empty state: no saved tasks
  // -----------------------------------------------------------------------
  test('empty state when no tasks are saved', () async {
    when(() => service.listMineWithDetails()).thenAnswer((_) async => <Task>[]);

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    await vm.load();

    expect(vm.savedTaskIds, isEmpty);
    expect(vm.savedTasks, isEmpty);
    expect(vm.isLoading, isFalse);
    expect(vm.error, isNull);

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 12. Auth stream signedIn triggers load
  // -----------------------------------------------------------------------
  test('auth stream signedIn event triggers load', () async {
    when(() => service.listMineWithDetails())
        .thenAnswer((_) async => [_task(id: 'from-auth')]);

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    // Emit signedIn event
    final mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user-1');
    final mockSession = MockSession();
    when(() => mockSession.user).thenReturn(mockUser);
    when(() => mockSession.accessToken).thenReturn('token');
    when(() => mockSession.refreshToken).thenReturn('refresh');
    when(() => mockSession.expiresIn).thenReturn(3600);

    result.authCtrl.add(AuthState(AuthChangeEvent.signedIn, mockSession));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verify(() => service.listMineWithDetails()).called(1);
    expect(vm.isSaved('from-auth'), isTrue);

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 13. Auth stream signedOut clears state
  // -----------------------------------------------------------------------
  test('auth stream signedOut event clears state', () async {
    when(
      () => service.listMineWithDetails(),
    ).thenAnswer((_) async => [_task(id: 't1')]);

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    // Load some data first
    await vm.load();
    expect(vm.savedTaskIds, isNotEmpty);

    // Emit signedOut
    result.authCtrl.add(AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(vm.savedTaskIds, isEmpty);
    expect(vm.savedTasks, isEmpty);
    expect(vm.error, isNull);

    vm.dispose();
    await result.authCtrl.close();
  });

  // -----------------------------------------------------------------------
  // 14. clear resets all state
  // -----------------------------------------------------------------------
  test('clear resets all state', () async {
    when(
      () => service.listMineWithDetails(),
    ).thenAnswer((_) async => [_task(id: 't1')]);

    final result = _buildVm(service: service, currentUser: null);
    final vm = result.vm;

    await vm.load();
    expect(vm.savedTaskIds, isNotEmpty);

    vm.clear();

    expect(vm.savedTaskIds, isEmpty);
    expect(vm.savedTasks, isEmpty);
    expect(vm.error, isNull);

    vm.dispose();
    await result.authCtrl.close();
  });
}
