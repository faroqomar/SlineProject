import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/services/models/service_model.dart';
import 'package:sline_app/features/services/models/service_status.dart';
import 'package:sline_app/features/services/viewmodels/my_services_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/helpers.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

ServiceModel _service({
  String id = 'svc-1',
  String title = 'Logo Design',
  ServiceStatus status = ServiceStatus.active,
  double? price = 50.0,
}) {
  return ServiceModel(
    id: id,
    freelancerId: 'user-1',
    title: title,
    status: status,
    price: price,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  late MockServicesRepository mockRepo;
  late MyServicesViewModel vm;

  setUpAll(() {
    registerFallbackValue(ServiceStatus.active);
  });

  setUp(() {
    mockRepo = MockServicesRepository();
    vm = MyServicesViewModel(repository: mockRepo);
  });

  // ── Construction ──────────────────────────────────────────

  group('Construction', () {
    test('initial state has empty services, no loading, no error', () {
      expect(vm.services, isEmpty);
      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
    });
  });

  // ── load() ────────────────────────────────────────────────

  group('load', () {
    test('fetches services from repository and exposes them', () async {
      final items = [_service(), _service(id: 'svc-2', title: 'Web Dev')];
      when(() => mockRepo.fetchMyServices()).thenAnswer((_) async => items);

      await vm.load();

      expect(vm.services, hasLength(2));
      expect(vm.services.first.title, 'Logo Design');
      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
      verify(() => mockRepo.fetchMyServices()).called(1);
    });

    test('sets isLoading true during fetch and false after', () async {
      final loadingStates = <bool>[];
      vm.addListener(() => loadingStates.add(vm.isLoading));

      when(() => mockRepo.fetchMyServices()).thenAnswer((_) async => []);

      await vm.load();

      // First notification: loading = true, second: loading = false
      expect(loadingStates, contains(true));
      expect(loadingStates.last, isFalse);
    });

    test('sets error state on repository failure', () async {
      when(
        () => mockRepo.fetchMyServices(),
      ).thenThrow(Exception('network down'));

      await vm.load();

      expect(vm.error, isNotNull);
      expect(vm.services, isEmpty);
      expect(vm.isLoading, isFalse);
    });

    test('maps PostgrestException 42501 to session expired message', () async {
      when(
        () => mockRepo.fetchMyServices(),
      ).thenThrow(const PostgrestException(message: 'RLS', code: '42501'));

      await vm.load();

      expect(vm.error, contains('Session expired'));
    });

    test('maps PostgrestException 23505 to duplicate message', () async {
      when(() => mockRepo.fetchMyServices()).thenThrow(
        const PostgrestException(message: 'duplicate', code: '23505'),
      );

      await vm.load();

      expect(vm.error, contains('already exists'));
    });

    test('clears previous error on new load call', () async {
      when(() => mockRepo.fetchMyServices()).thenThrow(Exception('fail first'));
      await vm.load();
      expect(vm.error, isNotNull);

      when(
        () => mockRepo.fetchMyServices(),
      ).thenAnswer((_) async => [_service()]);
      await vm.load();
      expect(vm.error, isNull);
      expect(vm.services, hasLength(1));
    });
  });

  // ── createService() ───────────────────────────────────────

  group('createService', () {
    test('calls repository and prepends new service to list', () async {
      when(
        () => mockRepo.createService(
          title: any(named: 'title'),
          description: any(named: 'description'),
          price: any(named: 'price'),
          deliveryDays: any(named: 'deliveryDays'),
        ),
      ).thenAnswer((_) async => _service(id: 'svc-new', title: 'New Service'));

      // Pre-populate with one service
      when(
        () => mockRepo.fetchMyServices(),
      ).thenAnswer((_) async => [_service()]);
      await vm.load();

      await vm.createService(title: 'New Service', price: 100.0);

      expect(vm.services, hasLength(2));
      expect(vm.services.first.id, 'svc-new');
      expect(vm.error, isNull);
    });

    test('sets error on create failure', () async {
      when(
        () => mockRepo.createService(
          title: any(named: 'title'),
          description: any(named: 'description'),
          price: any(named: 'price'),
          deliveryDays: any(named: 'deliveryDays'),
        ),
      ).thenThrow(Exception('create failed'));

      await vm.createService(title: 'Bad Service');

      expect(vm.error, isNotNull);
    });
  });

  // ── updateStatus() ────────────────────────────────────────

  group('updateStatus', () {
    test('calls repository and optimistically updates local list', () async {
      when(
        () => mockRepo.fetchMyServices(),
      ).thenAnswer((_) async => [_service()]);
      await vm.load();

      when(
        () => mockRepo.updateServiceStatus(any(), any()),
      ).thenAnswer((_) async {});

      await vm.updateStatus('svc-1', ServiceStatus.paused);

      expect(vm.services.first.status, ServiceStatus.paused);
      expect(vm.error, isNull);
      verify(
        () => mockRepo.updateServiceStatus('svc-1', ServiceStatus.paused),
      ).called(1);
    });

    test('sets error on status update failure', () async {
      when(
        () => mockRepo.fetchMyServices(),
      ).thenAnswer((_) async => [_service()]);
      await vm.load();

      when(
        () => mockRepo.updateServiceStatus(any(), any()),
      ).thenThrow(Exception('status update failed'));

      await vm.updateStatus('svc-1', ServiceStatus.paused);

      expect(vm.error, isNotNull);
    });
  });

  // ── updateService() ───────────────────────────────────────

  group('updateService', () {
    test('calls repository and replaces service in local list', () async {
      when(
        () => mockRepo.fetchMyServices(),
      ).thenAnswer((_) async => [_service()]);
      await vm.load();

      final updated = _service(title: 'Updated Title');
      when(
        () => mockRepo.updateService(
          any(),
          title: any(named: 'title'),
          description: any(named: 'description'),
          price: any(named: 'price'),
          deliveryDays: any(named: 'deliveryDays'),
        ),
      ).thenAnswer((_) async => updated);

      await vm.updateService('svc-1', title: 'Updated Title');

      expect(vm.services.first.title, 'Updated Title');
      expect(vm.error, isNull);
    });

    test('sets error on update failure', () async {
      when(
        () => mockRepo.fetchMyServices(),
      ).thenAnswer((_) async => [_service()]);
      await vm.load();

      when(
        () => mockRepo.updateService(
          any(),
          title: any(named: 'title'),
          description: any(named: 'description'),
          price: any(named: 'price'),
          deliveryDays: any(named: 'deliveryDays'),
        ),
      ).thenThrow(Exception('update failed'));

      await vm.updateService('svc-1', title: 'Bad');

      expect(vm.error, isNotNull);
    });
  });

  // ── clearError() ──────────────────────────────────────────

  group('clearError', () {
    test('clears error and notifies listeners', () async {
      when(() => mockRepo.fetchMyServices()).thenThrow(Exception('fail'));
      await vm.load();
      expect(vm.error, isNotNull);

      var notified = false;
      vm.addListener(() => notified = true);

      vm.clearError();
      expect(vm.error, isNull);
      expect(notified, isTrue);
    });
  });

  // ── services getter immutability ──────────────────────────

  group('services getter', () {
    test('returns unmodifiable list', () async {
      when(
        () => mockRepo.fetchMyServices(),
      ).thenAnswer((_) async => [_service()]);
      await vm.load();

      expect(
        () => vm.services.add(_service(id: 'hack')),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
