import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/tasks/viewmodels/submit_request_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';
import '../../helpers/mock_services.dart';

class MockTaskRequestsViewModel extends Mock implements TaskRequestsViewModel {}

void main() {
  late MockTaskService mockTaskService;
  late MockTaskRequestsService mockRequestsService;
  late MockTaskRequestsViewModel mockController;

  setUp(() {
    mockTaskService = MockTaskService();
    mockRequestsService = MockTaskRequestsService();
    mockController = MockTaskRequestsViewModel();
  });

  SubmitRequestViewModel buildVm({
    String taskId = 'task-1',
    String? userId = 'user-1',
    String budget = '1000',
  }) {
    return SubmitRequestViewModel(
      taskService: mockTaskService,
      requestsService: mockRequestsService,
      controller: mockController,
      taskId: taskId,
      userId: userId,
      budget: budget,
    );
  }

  group('SubmitRequestViewModel', () {
    group('validateTask', () {
      test('returns false when task not found', () async {
        when(
          () => mockTaskService.getTaskById('task-1'),
        ).thenAnswer((_) async => null);

        final vm = buildVm();
        final result = await vm.validateTask();

        expect(result, isFalse);
        expect(vm.guardError, 'Task not found.');
      });

      test('returns false when task is not open', () async {
        when(
          () => mockTaskService.getTaskById('task-1'),
        ).thenAnswer((_) async => _buildTask(status: TaskStatus.inProgress));

        final vm = buildVm();
        final result = await vm.validateTask();

        expect(result, isFalse);
        expect(vm.guardError, 'This task is no longer accepting offers.');
      });

      test('returns false when user is task owner', () async {
        when(
          () => mockTaskService.getTaskById('task-1'),
        ).thenAnswer((_) async => _buildTask(userId: 'user-1'));

        final vm = buildVm();
        final result = await vm.validateTask();

        expect(result, isFalse);
        expect(vm.guardError, 'You cannot bid on your own task.');
      });

      test('returns true when task is valid', () async {
        when(
          () => mockTaskService.getTaskById('task-1'),
        ).thenAnswer((_) async => _buildTask());

        final vm = buildVm();
        final result = await vm.validateTask();

        expect(result, isTrue);
        expect(vm.guardError, isNull);
      });

      test('returns false on exception', () async {
        when(
          () => mockTaskService.getTaskById('task-1'),
        ).thenThrow(Exception('Network error'));

        final vm = buildVm();
        final result = await vm.validateTask();

        expect(result, isFalse);
        expect(vm.guardError, contains('Unable to load task'));
      });
    });

    group('checkReplaceability', () {
      test('returns null when no existing bid', () async {
        when(() => mockController.checkBidReplaceability()).thenAnswer(
          (_) async => const BidReplaceabilityResult(
            isReplaceable: false,
          ),
        );

        final vm = buildVm();
        final result = await vm.checkReplaceability();

        expect(result, isNull);
        expect(vm.isReplaceMode, isFalse);
        expect(vm.existingBid, isNull);
      });

      test('returns pre-fill values when replaceable bid exists', () async {
        final existingBid = _buildRequest(note: 'test');
        when(() => mockController.checkBidReplaceability()).thenAnswer(
          (_) async => BidReplaceabilityResult(
            isReplaceable: true,
            existingBid: existingBid,
          ),
        );

        final vm = buildVm();
        final result = await vm.checkReplaceability();

        expect(result, isNotNull);
        expect(result!.price, '5000'); // task_requests.price is whole IQD
        expect(result.days, '7');
        expect(result.note, 'test');
        expect(vm.isReplaceMode, isTrue);
        expect(vm.existingBid, existingBid);
      });

      test('returns null on exception', () async {
        when(
          () => mockController.checkBidReplaceability(),
        ).thenThrow(Exception('Network error'));

        final vm = buildVm();
        final result = await vm.checkReplaceability();

        expect(result, isNull);
      });
    });

    group('submitNewBid', () {
      test('returns true on success', () async {
        when(
          () => mockController.submitOfferUI(
            taskId: 'task-1',
            price: 100.0,
            days: 7,
          ),
        ).thenAnswer((_) async => true);

        final vm = buildVm();
        final result = await vm.submitNewBid(price: 100.0, days: 7);

        expect(result, isTrue);
        expect(vm.isSubmitting, isFalse);
      });

      test('returns false and sets error on failure', () async {
        when(
          () => mockController.submitOfferUI(
            taskId: 'task-1',
            price: 100.0,
            days: 7,
          ),
        ).thenAnswer((_) async => false);
        when(() => mockController.errorMessage).thenReturn('Duplicate bid');

        final vm = buildVm();
        final result = await vm.submitNewBid(price: 100.0, days: 7);

        expect(result, isFalse);
        expect(vm.submitError, 'Duplicate bid');
      });

      test('isSubmitting is true during async operation', () async {
        var wasSubmitting = false;
        when(
          () => mockController.submitOfferUI(
            taskId: any(named: 'taskId'),
            price: any(named: 'price'),
            days: any(named: 'days'),
            note: any(named: 'note'),
          ),
        ).thenAnswer((_) async {
          return true;
        });

        final vm = buildVm();
        vm.addListener(() {
          if (vm.isSubmitting) wasSubmitting = true;
        });
        await vm.submitNewBid(price: 100.0, days: 7);

        expect(wasSubmitting, isTrue);
        expect(vm.isSubmitting, isFalse);
      });
    });

    group('replaceBid', () {
      test('returns TaskRequest on success', () async {
        final replaced = _buildRequest(price: 10000, days: 5);
        when(
          () => mockRequestsService.replaceOffer(
            taskId: 'task-1',
            price: 100.0,
            days: 5,
          ),
        ).thenAnswer((_) async => replaced);
        when(
          () => mockController.loadForTask('task-1'),
        ).thenAnswer((_) async {});

        final vm = buildVm();
        final result = await vm.replaceBid(price: 100.0, days: 5);

        expect(result, isNotNull);
        expect(result!.id, replaced.id);
      });

      test('returns null and sets error on failure', () async {
        when(
          () => mockRequestsService.replaceOffer(
            taskId: 'task-1',
            price: 100.0,
            days: 5,
          ),
        ).thenThrow(Exception('no longer open'));

        final vm = buildVm();
        final result = await vm.replaceBid(price: 100.0, days: 5);

        expect(result, isNull);
        expect(vm.submitError, contains('no longer accepting offers'));
        expect(vm.isTaskClosedError, isTrue);
      });
    });

    group('computeComparison', () {
      test('returns null when no existing bid', () {
        final vm = buildVm();
        final result = vm.computeComparison(newPriceIqd: 5000, newDays: 7);
        expect(result, isNull);
      });

      test('computes correct diff when bid exists', () async {
        final existingBid = _buildRequest();
        when(() => mockController.checkBidReplaceability()).thenAnswer(
          (_) async => BidReplaceabilityResult(
            isReplaceable: true,
            existingBid: existingBid,
          ),
        );

        final vm = buildVm();
        await vm.checkReplaceability();

        final result = vm.computeComparison(newPriceIqd: 7000, newDays: 5);
        expect(result, isNotNull);
        expect(result!.priceDiffSign, 1); // Price increased
        expect(result.daysDiffSign, -1); // Days decreased (positive for user)
      });
    });
  });
}

Task _buildTask({
  String userId = 'other-user',
  TaskStatus status = TaskStatus.open,
}) {
  return Task.fromJson({
    'id': 'task-1',
    'user_id': userId,
    'title': 'Test Task',
    'description': 'desc',
    'budget': 1000.0,
    'status': status.name,
    'type': 'tender',
    'created_at': DateTime.now().toIso8601String(),
  });
}

TaskRequest _buildRequest({int price = 5000, int days = 7, String? note}) {
  return TaskRequest(
    id: 'req-1',
    taskId: 'task-1',
    bidderId: 'user-2',
    price: price,
    days: days,
    note: note,
    status: OfferStatus.pending,
    createdAt: DateTime.now(),
  );
}
