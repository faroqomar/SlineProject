import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/work/models/change_request_model.dart';
import 'package:sline_app/features/work/models/extension_request_model.dart';
import 'package:sline_app/features/work/models/unified_work_item_model.dart';
import 'package:sline_app/features/work/models/work_contract_model.dart';
import 'package:sline_app/features/work/services/work_management_service.dart';
import 'package:sline_app/features/work/viewmodels/work_item_details_view_model.dart';

// Manual Mock
class MockWorkManagementService implements WorkManagementService {
  bool submitDeliveryCalled = false;
  bool requestExtensionCalled = false;
  bool acceptBookingCalled = false;
  bool declineBookingCalled = false;

  @override
  Future<UnifiedWorkItemModel?> getUnifiedWorkItem(
    String id,
    String type,
  ) async {
    if (id == 'error') throw Exception('Fetch error');
    if (id == 'missing_item') return null;
    return UnifiedWorkItemModel(
      id: id,
      sourceType: type,
      sourceStatus: 'active',
      unifiedStatus: UnifiedWorkStatus.active,
      title: 'Test Task',
      price: 100.0,
      clientId: 'c1',
      freelancerId: 'f1',
      deadline: DateTime.now().add(const Duration(days: 5)),
      revisionsTotal: 3,
      revisionsUsed: 0,
    );
  }

  @override
  Future<WorkContractModel?> getActiveContract(String id, String type) async {
    return WorkContractModel(
      id: 'wc1',
      relatedEntityType: type,
      relatedEntityId: id,
      version: 1,
      snapshot: {'price': 100},
      contractHash: 'hash',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<ChangeRequestModel>> getPendingChangeRequests(
    String id,
    String type,
  ) async {
    return [];
  }

  @override
  Future<List<ExtensionRequestModel>> getPendingExtensionRequests(
    String id,
    String type,
  ) async {
    return [];
  }

  @override
  Future<void> submitDelivery({
    required String entityId,
    required String entityType,
    required String note,
  }) async {
    submitDeliveryCalled = true;
  }

  @override
  Future<void> requestExtension({
    required String entityId,
    required String entityType,
    required DateTime newDeadline,
    required String reason,
    required String requesterId,
  }) async {
    requestExtensionCalled = true;
  }

  @override
  Future<List<UnifiedWorkItemModel>> listUnifiedWorkItems({
    required String userId,
    bool isClient = false,
    List<String>? statusFilter,
  }) async {
    return [];
  }

  @override
  Future<void> requestRevision({
    required String entityId,
    required String entityType,
    required String note,
  }) async {
    // No-op
  }

  @override
  Future<void> acceptChangeRequest(String requestId) async {
    // No-op
  }

  @override
  Future<void> acceptBooking(String bookingId) async {
    acceptBookingCalled = true;
  }

  @override
  Future<BookingModel?> getBooking(String id) async {
    if (id == 'b1') {
      return BookingModel(
        id: 'b1',
        taskId: 't1',
        providerId: 'p1',
        clientId: 'c1',
        slotId: 's1',
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.held,
        note: 'Test Note',
        createdAtUtc: DateTime.now(),
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
      );
    }
    if (id == 'missing_item') {
      return BookingModel(
        id: 'missing_item',
        taskId: 't_missing',
        providerId: 'p1',
        clientId: 'c1',
        slotId: 's1',
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.held,
        note: 'Fallback Note',
        createdAtUtc: DateTime.now(),
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        taskData: {'title': 'Fallback Task'},
      );
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    return {'full_name': 'Test User', 'avatar_url': 'http://test/avatar.png'};
  }

  @override
  Future<void> declineBooking(String bookingId) async {
    declineBookingCalled = true;
  }
}

void main() {
  group('WorkItemDetailsViewModel', () {
    late WorkItemDetailsViewModel viewModel;
    late MockWorkManagementService mockService;

    setUp(() {
      mockService = MockWorkManagementService();
      viewModel = WorkItemDetailsViewModel(workService: mockService, uid: 'f1');
    });

    test('loadData loads item and contract successfully', () async {
      await viewModel.loadData('t1', 'task');

      expect(viewModel.isLoading, false);
      expect(viewModel.error, null);
      expect(viewModel.workItem, isNotNull);
      expect(viewModel.workItem!.id, 't1');
      expect(viewModel.activeContract, isNotNull);
      expect(viewModel.isFreelancer, true);
    });

    test('submitDelivery calls service method', () async {
      await viewModel.loadData('t1', 'task');
      await viewModel.submitDelivery('Here is the work');

      expect(mockService.submitDeliveryCalled, true);
      expect(viewModel.error, null);
    });

    test('requestExtension calls service method', () async {
      await viewModel.loadData('t1', 'task');
      await viewModel.requestExtension('Need more time', 2);

      expect(mockService.requestExtensionCalled, true);
      expect(viewModel.error, null);
    });

    test('loadData handles incorrect ID gracefully', () async {
      // Mock behavior for null return is not explicitly mocked above,
      // but we can test error case if we modify mock or just test basic error path
      // by using 'error' ID which throws in our mock.
      await viewModel.loadData('error', 'task');

      expect(viewModel.error, isNotNull);
      expect(viewModel.workItem, null);
      expect(viewModel.error, isNotNull);
      expect(viewModel.workItem, null);
    });

    test('acceptBooking calls service method', () async {
      await viewModel.loadData('b1', 'booking');
      await viewModel.acceptBooking();

      expect(mockService.acceptBookingCalled, true);
      expect(viewModel.error, null);
    });

    test('declineBooking calls service method', () async {
      await viewModel.loadData('b1', 'booking');
      await viewModel.declineBooking();

      expect(mockService.declineBookingCalled, true);
      expect(viewModel.error, null);
    });

    test('loadData uses fallback booking when work item is null', () async {
      await viewModel.loadData('missing_item', 'booking');

      expect(viewModel.isLoading, false);
      expect(viewModel.error, null);
      expect(viewModel.workItem, isNotNull);
      expect(viewModel.workItem!.id, 'missing_item');
      expect(
        viewModel.workItem!.unifiedStatus,
        UnifiedWorkStatus.active,
      ); // mapped from confirmed
      expect(viewModel.booking, isNotNull);
      expect(viewModel.booking!.note, 'Fallback Note');
    });
  });
}
