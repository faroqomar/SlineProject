import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/models/app_failure.dart';
import 'package:sline_app/core/models/view_state.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/work/models/change_request_model.dart';
import 'package:sline_app/features/work/models/extension_request_model.dart';
import 'package:sline_app/features/work/models/unified_work_item_model.dart';
import 'package:sline_app/features/work/models/work_contract_model.dart';
import 'package:sline_app/features/work/viewmodels/work_item_details_view_model.dart';

import '../../helpers/helpers.dart';

// ---------------------------------------------------------------------------
// Local mocks (ChatViewModel / DashboardViewModel are ChangeNotifiers, not
// services, so they live here rather than in mock_services.dart)
// ---------------------------------------------------------------------------

class MockChatViewModel extends Mock implements ChatViewModel {}

class MockDashboardViewModel extends Mock implements DashboardViewModel {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _kUserId = 'user-123';
const _kOtherUserId = 'user-456';
const _kWorkItemId = 'wi-1';
const _kWorkItemType = 'task';

UnifiedWorkItemModel _workItem({
  String id = _kWorkItemId,
  String sourceType = _kWorkItemType,
  UnifiedWorkStatus status = UnifiedWorkStatus.active,
  String clientId = _kUserId,
  String freelancerId = _kOtherUserId,
  DateTime? deadline,
}) {
  return UnifiedWorkItemModel(
    id: id,
    sourceType: sourceType,
    sourceStatus: status.name,
    unifiedStatus: status,
    title: 'Test Work Item',
    price: 100.0,
    clientId: clientId,
    freelancerId: freelancerId,
    deadline: deadline ?? DateTime.utc(2026, 6, 1),
    revisionsTotal: 3,
    revisionsUsed: 0,
  );
}

WorkContractModel _contract() {
  return WorkContractModel(
    id: 'contract-1',
    relatedEntityType: _kWorkItemType,
    relatedEntityId: _kWorkItemId,
    version: 1,
    snapshot: const {'title': 'Test Work Item', 'price': 100.0},
    contractHash: 'abc123',
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Stubs the minimum set of service calls for a successful `loadData`.
void _stubLoadDefaults(
  MockWorkManagementService mockService, {
  UnifiedWorkItemModel? workItem,
  WorkContractModel? contract,
  List<ChangeRequestModel>? changeRequests,
  List<ExtensionRequestModel>? extensionRequests,
  BookingModel? booking,
  Map<String, dynamic>? profile,
}) {
  when(
    () => mockService.getUnifiedWorkItem(any(), any()),
  ).thenAnswer((_) async => workItem ?? _workItem());

  when(
    () => mockService.getActiveContract(any(), any()),
  ).thenAnswer((_) async => contract);

  when(
    () => mockService.getPendingChangeRequests(any(), any()),
  ).thenAnswer((_) async => changeRequests ?? <ChangeRequestModel>[]);

  when(
    () => mockService.getPendingExtensionRequests(any(), any()),
  ).thenAnswer((_) async => extensionRequests ?? <ExtensionRequestModel>[]);

  when(() => mockService.getBooking(any())).thenAnswer((_) async => booking);

  when(
    () => mockService.getProfile(any()),
  ).thenAnswer((_) async => profile ?? {'full_name': 'Other User'});
}

void main() {
  late MockWorkManagementService mockService;
  late WorkItemDetailsViewModel vm;

  setUp(() {
    mockService = MockWorkManagementService();
    vm = WorkItemDetailsViewModel(workService: mockService, uid: _kUserId);
  });

  // ── Construction ──────────────────────────────────────────

  group('Construction', () {
    test('initial state is ViewInitial', () {
      expect(vm.state, isA<ViewInitial<WorkItemData>>());
      expect(vm.isLoading, isTrue);
      expect(vm.error, isNull);
      expect(vm.workItem, isNull);
      expect(vm.booking, isNull);
    });

    test('convenience getters return safe defaults before load', () {
      expect(vm.title, isEmpty);
      expect(vm.status, UnifiedWorkStatus.unknown);
      expect(vm.changeRequests, isEmpty);
      expect(vm.extensionRequests, isEmpty);
      expect(vm.otherPartyProfile, isNull);
    });
  });

  // ── loadData() ────────────────────────────────────────────

  group('loadData', () {
    test('happy path: ViewLoading then ViewLoaded with WorkItemData', () async {
      final stateLog = <Type>[];
      vm.addListener(() => stateLog.add(vm.state.runtimeType));

      _stubLoadDefaults(mockService, contract: _contract());

      await vm.loadData(_kWorkItemId, _kWorkItemType);

      expect(stateLog, contains(ViewLoading<WorkItemData>));
      expect(vm.state, isA<ViewLoaded<WorkItemData>>());

      final data = (vm.state as ViewLoaded<WorkItemData>).data;
      expect(data.workItem.id, _kWorkItemId);
      expect(data.activeContract, isNotNull);
      expect(data.otherPartyProfile, isNotNull);
    });

    test(
      'exposes workItem, booking, contract via convenience getters',
      () async {
        _stubLoadDefaults(mockService, contract: _contract());

        await vm.loadData(_kWorkItemId, _kWorkItemType);

        expect(vm.workItem, isNotNull);
        expect(vm.workItem!.id, _kWorkItemId);
        expect(vm.activeContract, isNotNull);
        expect(vm.title, 'Test Work Item');
        expect(vm.status, UnifiedWorkStatus.active);
      },
    );

    test('sets ViewFailed when work item not found (null)', () async {
      _stubLoadDefaults(mockService);
      when(
        () => mockService.getUnifiedWorkItem(any(), any()),
      ).thenAnswer((_) async => null);

      await vm.loadData(_kWorkItemId, _kWorkItemType);

      expect(vm.state, isA<ViewFailed<WorkItemData>>());
      final failure = (vm.state as ViewFailed<WorkItemData>).failure;
      expect(failure, isA<BusinessFailure>());
      expect(failure.userMessage, contains('not found'));
    });

    test('sets ViewFailed on network / service exception', () async {
      when(
        () => mockService.getUnifiedWorkItem(any(), any()),
      ).thenThrow(Exception('network error'));
      // Secondary fetches should not matter since Future.wait will reject
      when(
        () => mockService.getActiveContract(any(), any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockService.getPendingChangeRequests(any(), any()),
      ).thenAnswer((_) async => <ChangeRequestModel>[]);
      when(
        () => mockService.getPendingExtensionRequests(any(), any()),
      ).thenAnswer((_) async => <ExtensionRequestModel>[]);

      await vm.loadData(_kWorkItemId, _kWorkItemType);

      expect(vm.state, isA<ViewFailed<WorkItemData>>());
      expect(vm.error, isNotNull);
    });

    test('isFreelancer / isClient reflect current user role', () async {
      // Current user is client (clientId == _kUserId)
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      expect(vm.isClient, isTrue);
      expect(vm.isFreelancer, isFalse);
    });
  });

  // ── submitDelivery() ──────────────────────────────────────

  group('submitDelivery', () {
    test('happy path: calls service and reloads', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(
        () => mockService.submitDelivery(
          entityId: any(named: 'entityId'),
          entityType: any(named: 'entityType'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async {});

      // Re-stub load for the reload that happens after action
      _stubLoadDefaults(mockService);

      await vm.submitDelivery('Delivery note');

      verify(
        () => mockService.submitDelivery(
          entityId: _kWorkItemId,
          entityType: _kWorkItemType,
          note: 'Delivery note',
        ),
      ).called(1);
      expect(vm.state, isA<ViewLoaded<WorkItemData>>());
    });

    test('error: sets ViewFailed', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(
        () => mockService.submitDelivery(
          entityId: any(named: 'entityId'),
          entityType: any(named: 'entityType'),
          note: any(named: 'note'),
        ),
      ).thenThrow(Exception('submit failed'));

      await vm.submitDelivery('note');

      expect(vm.state, isA<ViewFailed<WorkItemData>>());
      expect(vm.error, isNotNull);
    });

    test('no-op when state has no loaded work item', () async {
      // State is ViewInitial, workItem is null
      await vm.submitDelivery('note');

      verifyNever(
        () => mockService.submitDelivery(
          entityId: any(named: 'entityId'),
          entityType: any(named: 'entityType'),
          note: any(named: 'note'),
        ),
      );
    });
  });

  // ── requestExtension() ────────────────────────────────────

  group('requestExtension', () {
    test('happy path: calls service with computed deadline', () async {
      final deadline = DateTime.utc(2026, 6, 1);
      _stubLoadDefaults(mockService, workItem: _workItem(deadline: deadline));
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(
        () => mockService.requestExtension(
          entityId: any(named: 'entityId'),
          entityType: any(named: 'entityType'),
          newDeadline: any(named: 'newDeadline'),
          reason: any(named: 'reason'),
          requesterId: any(named: 'requesterId'),
        ),
      ).thenAnswer((_) async {});

      _stubLoadDefaults(mockService);

      await vm.requestExtension('Need more time', 7);

      final captured = verify(
        () => mockService.requestExtension(
          entityId: _kWorkItemId,
          entityType: _kWorkItemType,
          newDeadline: captureAny(named: 'newDeadline'),
          reason: 'Need more time',
          requesterId: _kUserId,
        ),
      ).captured;
      final newDeadline = captured.first as DateTime;
      expect(newDeadline, deadline.add(const Duration(days: 7)));
    });

    test('error: sets ViewFailed', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(
        () => mockService.requestExtension(
          entityId: any(named: 'entityId'),
          entityType: any(named: 'entityType'),
          newDeadline: any(named: 'newDeadline'),
          reason: any(named: 'reason'),
          requesterId: any(named: 'requesterId'),
        ),
      ).thenThrow(Exception('extension failed'));

      await vm.requestExtension('reason', 5);

      expect(vm.state, isA<ViewFailed<WorkItemData>>());
    });
  });

  // ── acceptBooking / declineBooking ────────────────────────

  group('acceptBooking', () {
    test('happy path: calls service and reloads', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(() => mockService.acceptBooking(any())).thenAnswer((_) async {});
      _stubLoadDefaults(mockService);

      await vm.acceptBooking();

      verify(() => mockService.acceptBooking(_kWorkItemId)).called(1);
      expect(vm.state, isA<ViewLoaded<WorkItemData>>());
    });

    test('error: sets ViewFailed', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(
        () => mockService.acceptBooking(any()),
      ).thenThrow(Exception('accept failed'));

      await vm.acceptBooking();

      expect(vm.state, isA<ViewFailed<WorkItemData>>());
      expect(vm.error, contains('accept booking'));
    });
  });

  group('declineBooking', () {
    test('happy path: calls service and reloads', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(() => mockService.declineBooking(any())).thenAnswer((_) async {});
      _stubLoadDefaults(mockService);

      await vm.declineBooking();

      verify(() => mockService.declineBooking(_kWorkItemId)).called(1);
    });

    test('error: sets ViewFailed', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(
        () => mockService.declineBooking(any()),
      ).thenThrow(Exception('decline failed'));

      await vm.declineBooking();

      expect(vm.state, isA<ViewFailed<WorkItemData>>());
    });
  });

  // ── cancelBooking ─────────────────────────────────────────

  group('cancelBooking', () {
    test('happy path: calls service and reloads', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(() => mockService.cancelBooking(any())).thenAnswer((_) async {});
      _stubLoadDefaults(mockService);

      await vm.cancelBooking();

      verify(() => mockService.cancelBooking(_kWorkItemId)).called(1);
    });
  });

  // ── approveDelivery ───────────────────────────────────────

  group('approveDelivery', () {
    test('happy path: calls service and reloads', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(
        () => mockService.approveDelivery(
          entityId: any(named: 'entityId'),
          entityType: any(named: 'entityType'),
          correlationId: any(named: 'correlationId'),
        ),
      ).thenAnswer((_) async {});
      _stubLoadDefaults(mockService);

      await vm.approveDelivery();

      verify(
        () => mockService.approveDelivery(
          entityId: _kWorkItemId,
          entityType: _kWorkItemType,
          correlationId: any(named: 'correlationId'),
        ),
      ).called(1);
    });

    test('error: sets ViewFailed', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(
        () => mockService.approveDelivery(
          entityId: any(named: 'entityId'),
          entityType: any(named: 'entityType'),
          correlationId: any(named: 'correlationId'),
        ),
      ).thenThrow(Exception('approve failed'));

      await vm.approveDelivery();

      expect(vm.state, isA<ViewFailed<WorkItemData>>());
    });
  });

  // ── requestRevision ───────────────────────────────────────

  group('requestRevision', () {
    test('happy path: calls service and reloads', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(
        () => mockService.requestRevision(
          entityId: any(named: 'entityId'),
          entityType: any(named: 'entityType'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async {});
      _stubLoadDefaults(mockService);

      await vm.requestRevision('Please fix the logo');

      verify(
        () => mockService.requestRevision(
          entityId: _kWorkItemId,
          entityType: _kWorkItemType,
          note: 'Please fix the logo',
        ),
      ).called(1);
    });

    test('error: sets ViewFailed', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(
        () => mockService.requestRevision(
          entityId: any(named: 'entityId'),
          entityType: any(named: 'entityType'),
          note: any(named: 'note'),
        ),
      ).thenThrow(Exception('revision failed'));

      await vm.requestRevision('note');

      expect(vm.state, isA<ViewFailed<WorkItemData>>());
    });
  });

  // ── acceptChangeRequest ───────────────────────────────────

  group('acceptChangeRequest', () {
    test('happy path: calls service and reloads', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(
        () => mockService.acceptChangeRequest(any()),
      ).thenAnswer((_) async {});
      _stubLoadDefaults(mockService);

      await vm.acceptChangeRequest('cr-1');

      verify(() => mockService.acceptChangeRequest('cr-1')).called(1);
    });

    test('error: sets ViewFailed', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      when(
        () => mockService.acceptChangeRequest(any()),
      ).thenThrow(Exception('change request failed'));

      await vm.acceptChangeRequest('cr-1');

      expect(vm.state, isA<ViewFailed<WorkItemData>>());
    });
  });

  // ── canReview computed property ───────────────────────────

  group('canReview', () {
    test('true when client and status is delivered', () async {
      _stubLoadDefaults(
        mockService,
        workItem: _workItem(
          clientId: _kUserId,
          freelancerId: _kOtherUserId,
          status: UnifiedWorkStatus.delivered,
        ),
      );

      await vm.loadData(_kWorkItemId, _kWorkItemType);

      expect(vm.canReview, isTrue);
    });

    test('false when freelancer (not client)', () async {
      _stubLoadDefaults(
        mockService,
        workItem: _workItem(
          clientId: _kOtherUserId,
          freelancerId: _kUserId,
          status: UnifiedWorkStatus.delivered,
        ),
      );

      await vm.loadData(_kWorkItemId, _kWorkItemType);

      expect(vm.canReview, isFalse);
    });

    test('false when client but status is not delivered', () async {
      _stubLoadDefaults(
        mockService,
        workItem: _workItem(
          clientId: _kUserId,
          freelancerId: _kOtherUserId,
          status: UnifiedWorkStatus.active,
        ),
      );

      await vm.loadData(_kWorkItemId, _kWorkItemType);

      expect(vm.canReview, isFalse);
    });
  });

  // ── refreshDashboard / cancelAward ────────────────────────

  group('refreshDashboard and cancelAward', () {
    test('refreshDashboard is no-op without dashboard injected', () {
      // Should not throw
      vm.refreshDashboard();
    });

    test('refreshDashboard delegates to injected dashboard VM', () async {
      final mockDashboard = MockDashboardViewModel();
      when(mockDashboard.refresh).thenAnswer((_) async {});

      final vmWithDashboard = WorkItemDetailsViewModel(
        workService: mockService,
        uid: _kUserId,
        dashboardViewModel: mockDashboard,
      );

      vmWithDashboard.refreshDashboard();

      verify(mockDashboard.refresh).called(1);
    });

    test('cancelAward is no-op without dashboard injected', () async {
      // Should not throw
      await vm.cancelAward('req-1');
    });

    test('cancelAward delegates to dashboard VM', () async {
      final mockDashboard = MockDashboardViewModel();
      when(
        () => mockDashboard.cancelAwardedOffer(any()),
      ).thenAnswer((_) async {});

      final vmWithDashboard = WorkItemDetailsViewModel(
        workService: mockService,
        uid: _kUserId,
        dashboardViewModel: mockDashboard,
      );

      await vmWithDashboard.cancelAward('req-1');

      verify(() => mockDashboard.cancelAwardedOffer('req-1')).called(1);
    });
  });

  // ── openConversation ──────────────────────────────────────

  group('openConversation', () {
    test('returns null when chatViewModel is not injected', () async {
      _stubLoadDefaults(mockService);
      await vm.loadData(_kWorkItemId, _kWorkItemType);

      final result = await vm.openConversation();
      expect(result, isNull);
    });

    test('returns null when workItem is null', () async {
      // State is ViewInitial
      final mockChat = MockChatViewModel();
      final vmWithChat = WorkItemDetailsViewModel(
        workService: mockService,
        uid: _kUserId,
        chatViewModel: mockChat,
      );

      final result = await vmWithChat.openConversation();
      expect(result, isNull);
    });
  });
}
