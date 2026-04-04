import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_inbox_delegate.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import '../../helpers/mock_services.dart';

void main() {
  late MockDashboardRepository mockRepo;
  late MockTaskService mockTaskService;
  late MockBookingService mockBookingService;
  late int notifyCount;
  late bool disposed;

  DashboardInboxDelegate buildDelegate() {
    notifyCount = 0;
    disposed = false;
    return DashboardInboxDelegate(
      repository: mockRepo,
      taskService: mockTaskService,
      bookingService: mockBookingService,
      onChanged: () => notifyCount++,
      isDisposed: () => disposed,
    );
  }

  setUp(() {
    mockRepo = MockDashboardRepository();
    mockTaskService = MockTaskService();
    mockBookingService = MockBookingService();
  });

  group('DashboardInboxDelegate', () {
    test('initial state is empty', () {
      final delegate = buildDelegate();
      expect(delegate.inboxOffers, isEmpty);
      expect(delegate.pendingRequests, isEmpty);
      expect(delegate.myTasks, isEmpty);
      expect(delegate.inboxLoaded, isFalse);
    });

    test('setInboxData populates all fields and marks loaded', () {
      final delegate = buildDelegate();
      final offer = _buildTaskRequest(id: 'r1', taskId: 't1');
      delegate.setInboxData(
        offers: [offer],
        pendingRequests: [],
        pendingPaymentTenders: [],
        myTasks: [],
      );
      expect(delegate.inboxOffers, hasLength(1));
      expect(delegate.inboxLoaded, isTrue);
    });

    test('inboxGroupedByTask groups offers by task', () {
      final delegate = buildDelegate();
      final offers = [
        _buildTaskRequest(id: 'r1', taskId: 't1'),
        _buildTaskRequest(id: 'r2', taskId: 't1'),
        _buildTaskRequest(id: 'r3', taskId: 't2'),
      ];
      delegate.setInboxData(
        offers: offers,
        pendingRequests: [],
        pendingPaymentTenders: [],
        myTasks: [],
      );
      // Verify offers were stored
      expect(delegate.inboxOffers, hasLength(3));
      expect(delegate.inboxOffers[0].taskId, 't1');
      expect(delegate.inboxOffers[1].taskId, 't1');
      expect(delegate.inboxOffers[2].taskId, 't2');
      final groups = delegate.inboxGroupedByTask;
      expect(groups, hasLength(2));
    });

    test('clear resets state and marks unloaded', () {
      final delegate = buildDelegate();
      delegate.setInboxData(
        offers: [_buildTaskRequest(id: 'r1', taskId: 't1')],
        pendingRequests: [],
        pendingPaymentTenders: [],
        myTasks: [],
      );
      delegate.clear();
      expect(delegate.inboxOffers, isEmpty);
      expect(delegate.inboxLoaded, isFalse);
    });

    test('removeOffer removes by ID', () {
      final delegate = buildDelegate();
      delegate.setInboxData(
        offers: [
          _buildTaskRequest(id: 'r1', taskId: 't1'),
          _buildTaskRequest(id: 'r2', taskId: 't2'),
        ],
        pendingRequests: [],
        pendingPaymentTenders: [],
        myTasks: [],
      );
      delegate.removeOffer('r1');
      expect(delegate.inboxOffers, hasLength(1));
      expect(delegate.inboxOffers.first.id, 'r2');
    });

    test('rejectOffer calls taskService and removes from list', () async {
      final delegate = buildDelegate();
      delegate.setInboxData(
        offers: [_buildTaskRequest(id: 'r1', taskId: 't1')],
        pendingRequests: [],
        pendingPaymentTenders: [],
        myTasks: [],
      );
      when(() => mockTaskService.rejectOffer('r1')).thenAnswer((_) async {});

      await delegate.rejectOffer(_buildTaskRequest(id: 'r1', taskId: 't1'));
      expect(delegate.inboxOffers, isEmpty);
      expect(notifyCount, 1);
    });

    test('rejectOffer does not notify when disposed', () async {
      final delegate = buildDelegate();
      delegate.setInboxData(
        offers: [_buildTaskRequest(id: 'r1', taskId: 't1')],
        pendingRequests: [],
        pendingPaymentTenders: [],
        myTasks: [],
      );
      when(() => mockTaskService.rejectOffer('r1')).thenAnswer((_) async {
        disposed = true;
      });

      await delegate.rejectOffer(_buildTaskRequest(id: 'r1', taskId: 't1'));
      expect(notifyCount, 0);
    });

    test('setMyTasks updates the task list', () {
      final delegate = buildDelegate();
      expect(delegate.myTasks, isEmpty);
      delegate.setMyTasks([
        Task.fromJson({
          'id': 't1',
          'user_id': 'u1',
          'title': 'Test Task',
          'description': 'desc',
          'budget': 100.0,
          'status': 'open',
          'type': 'tender',
          'created_at': DateTime.now().toIso8601String(),
        }),
      ]);
      expect(delegate.myTasks, hasLength(1));
    });
  });
}

TaskRequest _buildTaskRequest({required String id, required String taskId}) {
  return TaskRequest(
    id: id,
    taskId: taskId,
    bidderId: 'f1',
    price: 5000,
    days: 7,
    note: 'test note',
    status: OfferStatus.pending,
    createdAt: DateTime.now(),
    taskTitle: 'Test Task',
  );
}
