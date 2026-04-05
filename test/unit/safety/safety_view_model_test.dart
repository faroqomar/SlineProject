/// Unit tests for [SafetyViewModel].
///
/// Run: `flutter test test/unit/safety/safety_view_model_test.dart`
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';

import '../../helpers/mock_services.dart';

void main() {
  late MockReportService mockReportService;
  late MockDisputeService mockDisputeService;

  setUp(() {
    mockReportService = MockReportService();
    mockDisputeService = MockDisputeService();
  });

  SafetyViewModel buildVm() {
    return SafetyViewModel(
      reportService: mockReportService,
      disputeService: mockDisputeService,
    );
  }

  group('SafetyViewModel', () {
    test('initial state: not submitting, no error', () {
      final vm = buildVm();

      expect(vm.isSubmitting, isFalse);
      expect(vm.error, isNull);
    });

    // ---------------------------------------------------------------
    // submitReport
    // ---------------------------------------------------------------

    test('submitReport happy path calls ReportService and returns true',
        () async {
      when(
        () => mockReportService.submitReport(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          reason: any(named: 'reason'),
          category: any(named: 'category'),
        ),
      ).thenAnswer((_) async {});

      final vm = buildVm();
      final result = await vm.submitReport(
        entityType: 'task',
        entityId: 'task-1',
        reason: 'Spam content',
      );

      expect(result, isTrue);
      expect(vm.error, isNull);
      expect(vm.isSubmitting, isFalse);
      verify(
        () => mockReportService.submitReport(
          entityType: 'task',
          entityId: 'task-1',
          reason: 'Spam content',
          category: null,
        ),
      ).called(1);
    });

    test('submitReport error returns false and sets error', () async {
      when(
        () => mockReportService.submitReport(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          reason: any(named: 'reason'),
          category: any(named: 'category'),
        ),
      ).thenThrow(Exception('Network error'));

      final vm = buildVm();
      final result = await vm.submitReport(
        entityType: 'user',
        entityId: 'user-1',
        reason: 'Harassment',
      );

      expect(result, isFalse);
      expect(vm.error, isNotNull);
      expect(vm.isSubmitting, isFalse);
    });

    test('submitReport sets isSubmitting true during operation', () async {
      final completer = Completer<void>();
      when(
        () => mockReportService.submitReport(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          reason: any(named: 'reason'),
          category: any(named: 'category'),
        ),
      ).thenAnswer((_) => completer.future);

      final vm = buildVm();
      final future = vm.submitReport(
        entityType: 'task',
        entityId: 'task-1',
        reason: 'Spam',
      );

      expect(vm.isSubmitting, isTrue);

      completer.complete();
      await future;

      expect(vm.isSubmitting, isFalse);
    });

    // ---------------------------------------------------------------
    // submitDispute
    // ---------------------------------------------------------------

    test('submitDispute happy path calls DisputeService and returns true',
        () async {
      when(
        () => mockDisputeService.submitDispute(
          taskId: any(named: 'taskId'),
          directOfferId: any(named: 'directOfferId'),
          reason: any(named: 'reason'),
          defendantId: any(named: 'defendantId'),
        ),
      ).thenAnswer((_) async {});

      final vm = buildVm();
      final result = await vm.submitDispute(
        taskId: 'task-42',
        reason: 'Work not delivered',
      );

      expect(result, isTrue);
      expect(vm.error, isNull);
      verify(
        () => mockDisputeService.submitDispute(
          taskId: 'task-42',
          directOfferId: null,
          reason: 'Work not delivered',
          defendantId: null,
        ),
      ).called(1);
    });

    test('submitDispute error returns false and sets error', () async {
      when(
        () => mockDisputeService.submitDispute(
          taskId: any(named: 'taskId'),
          directOfferId: any(named: 'directOfferId'),
          reason: any(named: 'reason'),
          defendantId: any(named: 'defendantId'),
        ),
      ).thenThrow(Exception('RLS denied'));

      final vm = buildVm();
      final result = await vm.submitDispute(
        taskId: 'task-42',
        reason: 'Fraudulent activity',
      );

      expect(result, isFalse);
      expect(vm.error, isNotNull);
    });

    // ---------------------------------------------------------------
    // hasOpenDisputeForTask
    // ---------------------------------------------------------------

    test('hasOpenDisputeForTask delegates to DisputeService', () async {
      when(
        () => mockDisputeService.hasOpenDisputeForTask('task-1'),
      ).thenAnswer((_) async => true);

      final vm = buildVm();
      final result = await vm.hasOpenDisputeForTask('task-1');

      expect(result, isTrue);
      verify(() => mockDisputeService.hasOpenDisputeForTask('task-1'))
          .called(1);
    });

    test('hasOpenDisputeForTask returns false when no dispute', () async {
      when(
        () => mockDisputeService.hasOpenDisputeForTask('task-2'),
      ).thenAnswer((_) async => false);

      final vm = buildVm();
      final result = await vm.hasOpenDisputeForTask('task-2');

      expect(result, isFalse);
    });

    // ---------------------------------------------------------------
    // getDisputeStatusForTask
    // ---------------------------------------------------------------

    test('getDisputeStatusForTask returns status from service', () async {
      when(
        () => mockDisputeService.getDisputeStatusForTask('task-1'),
      ).thenAnswer((_) async => 'open');

      final vm = buildVm();
      final result = await vm.getDisputeStatusForTask('task-1');

      expect(result, 'open');
    });

    test('getDisputeStatusForTask returns null when no dispute', () async {
      when(
        () => mockDisputeService.getDisputeStatusForTask('task-99'),
      ).thenAnswer((_) async => null);

      final vm = buildVm();
      final result = await vm.getDisputeStatusForTask('task-99');

      expect(result, isNull);
    });

    // ---------------------------------------------------------------
    // notifyListeners
    // ---------------------------------------------------------------

    test('submitReport notifies listeners on start and finish', () async {
      when(
        () => mockReportService.submitReport(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          reason: any(named: 'reason'),
          category: any(named: 'category'),
        ),
      ).thenAnswer((_) async {});

      final vm = buildVm();
      var notifyCount = 0;
      vm.addListener(() => notifyCount++);

      await vm.submitReport(
        entityType: 'task',
        entityId: 'task-1',
        reason: 'Spam',
      );

      // Two notifications: start (isSubmitting=true) and finish
      expect(notifyCount, 2);
    });

    // ---------------------------------------------------------------
    // Error clearing
    // ---------------------------------------------------------------

    test('error is cleared on next successful submit', () async {
      // First: fail
      when(
        () => mockReportService.submitReport(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          reason: any(named: 'reason'),
          category: any(named: 'category'),
        ),
      ).thenThrow(Exception('fail'));

      final vm = buildVm();
      await vm.submitReport(
        entityType: 'task',
        entityId: 'task-1',
        reason: 'Bad',
      );
      expect(vm.error, isNotNull);

      // Second: succeed
      when(
        () => mockReportService.submitReport(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          reason: any(named: 'reason'),
          category: any(named: 'category'),
        ),
      ).thenAnswer((_) async {});

      final result = await vm.submitReport(
        entityType: 'task',
        entityId: 'task-1',
        reason: 'Bad',
      );
      expect(result, isTrue);
      expect(vm.error, isNull);
    });
  });
}
