import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_work_delegate.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import '../../helpers/mock_services.dart';

void main() {
  late MockDashboardRepository mockRepo;
  late MockTaskService mockTaskService;
  late MockBookingService mockBookingService;
  late MockDirectOffersService mockDirectOffersService;
  late int notifyCount;
  late bool disposed;

  DashboardWorkDelegate buildDelegate() {
    notifyCount = 0;
    disposed = false;
    return DashboardWorkDelegate(
      repository: mockRepo,
      taskService: mockTaskService,
      bookingService: mockBookingService,
      directOffersService: mockDirectOffersService,
      onChanged: () => notifyCount++,
      isDisposed: () => disposed,
    );
  }

  setUp(() {
    mockRepo = MockDashboardRepository();
    mockTaskService = MockTaskService();
    mockBookingService = MockBookingService();
    mockDirectOffersService = MockDirectOffersService();
  });

  group('DashboardWorkDelegate', () {
    test('initial state is empty', () {
      final delegate = buildDelegate();
      expect(delegate.workItems, isEmpty);
      expect(delegate.nextActions, isEmpty);
      expect(delegate.activeWork, isEmpty);
      expect(delegate.completedWork, isEmpty);
      expect(delegate.cancelledWork, isEmpty);
    });

    test('setWorkItems populates list and invalidates caches', () {
      final delegate = buildDelegate();
      final items = [
        _buildWorkItem(id: '1', statusRaw: 'inprogress', bucket: 'Active'),
        _buildWorkItem(id: '2', statusRaw: 'completed', bucket: 'Done'),
      ];
      delegate.setWorkItems(items);
      expect(delegate.workItems, hasLength(2));
      expect(delegate.activeInProgress, hasLength(1));
      expect(delegate.completedWork, hasLength(1));
    });

    test('clear resets all state', () {
      final delegate = buildDelegate();
      delegate.setWorkItems([
        _buildWorkItem(id: '1', statusRaw: 'inprogress', bucket: 'Active'),
      ]);
      expect(delegate.workItems, hasLength(1));
      delegate.clear();
      expect(delegate.workItems, isEmpty);
    });

    test('fetchWorkItems calls repository and notifies', () async {
      final delegate = buildDelegate();
      final items = [
        _buildWorkItem(id: '1', statusRaw: 'open', bucket: 'Active'),
      ];
      when(
        () => mockRepo.fetchWorkItems(UserRole.freelancer),
      ).thenAnswer((_) async => items);

      await delegate.fetchWorkItems(UserRole.freelancer);
      expect(delegate.workItems, hasLength(1));
      expect(notifyCount, 1);
    });

    test('fetchWorkItems does not notify when disposed', () async {
      final delegate = buildDelegate();
      when(() => mockRepo.fetchWorkItems(UserRole.freelancer)).thenAnswer((_) {
        disposed = true; // Simulate dispose during fetch
        return Future.value([
          _buildWorkItem(id: '1', statusRaw: 'open', bucket: 'Active'),
        ]);
      });

      await delegate.fetchWorkItems(UserRole.freelancer);
      expect(notifyCount, 0);
    });

    test('withdrawOffer calls taskService', () async {
      final delegate = buildDelegate();
      when(
        () => mockTaskService.withdrawOffer('offer-1'),
      ).thenAnswer((_) async {});

      await delegate.withdrawOffer('offer-1');
      verify(() => mockTaskService.withdrawOffer('offer-1')).called(1);
    });

    test('withdrawOffer rethrows on failure', () async {
      final delegate = buildDelegate();
      when(
        () => mockTaskService.withdrawOffer('offer-1'),
      ).thenThrow(Exception('Network error'));

      expect(() => delegate.withdrawOffer('offer-1'), throwsException);
    });

    test('releaseOfferWithFee calls taskService', () async {
      final delegate = buildDelegate();
      when(
        () => mockTaskService.releaseOfferWithFee('offer-1'),
      ).thenAnswer((_) async {});

      await delegate.releaseOfferWithFee('offer-1');
      verify(() => mockTaskService.releaseOfferWithFee('offer-1')).called(1);
    });

    test(
      'performPrimaryAction payEscrow on directOffer calls payNow',
      () async {
        final delegate = buildDelegate();
        when(
          () => mockDirectOffersService.payNow('do-1'),
        ).thenAnswer((_) async {});

        final now = DateTime.now();
        final item = WorkItem(
          id: 'do-1',
          type: WorkItemType.directOffer,
          title: 'Direct Offer',
          counterpartyId: 'cp-1',
          counterpartyName: 'Test',
          counterpartyAvatar: '',
          counterpartyRole: 'Client',
          statusRaw: 'pending_payment',
          statusUiBucket: 'Active',
          createdAt: now,
          lastUpdate: now,
          primaryActionType: PrimaryActionType.payEscrow,
          permissions: WorkItemPermissions(canPayEscrow: true),
        );

        await delegate.performPrimaryAction(item);
        verify(() => mockDirectOffersService.payNow('do-1')).called(1);
      },
    );

    test(
      'cancelAwardedOffer does not rethrow when disposed mid-call',
      () async {
        final delegate = buildDelegate();
        when(() => mockTaskService.cancelAwardedOffer('req-1')).thenAnswer((_) {
          disposed = true;
          return Future.value(<String, dynamic>{});
        });

        await delegate.cancelAwardedOffer('req-1');
        verify(() => mockTaskService.cancelAwardedOffer('req-1')).called(1);
      },
    );
  });
}

WorkItem _buildWorkItem({
  required String id,
  required String statusRaw,
  required String bucket,
  DateTime? scheduledAt,
  DateTime? completedAt,
}) {
  final now = DateTime.now();
  return WorkItem(
    id: id,
    type: WorkItemType.task,
    title: 'Test Item $id',
    counterpartyId: 'cp-1',
    counterpartyName: 'Test User',
    counterpartyAvatar: '',
    counterpartyRole: 'Client',
    statusRaw: statusRaw,
    statusUiBucket: bucket,
    sortRank: 0,
    createdAt: now,
    lastUpdate: now,
    lastActivityAt: null,
    scheduledAt: scheduledAt,
    completedAt: completedAt,
    primaryActionType: PrimaryActionType.viewDetails,
    permissions: WorkItemPermissions(),
  );
}
