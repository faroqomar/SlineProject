import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/models/app_failure.dart';
import 'package:sline_app/core/models/view_state.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/work/models/change_request_model.dart';
import 'package:sline_app/features/work/models/extension_request_model.dart';
import 'package:sline_app/features/work/models/unified_work_item_model.dart';
import 'package:sline_app/features/work/models/work_contract_model.dart';
import 'package:sline_app/features/work/services/work_management_service.dart';

/// Composite data class bundling all fields loaded together for work item details.
class WorkItemData {
  final UnifiedWorkItemModel workItem;
  final WorkContractModel? activeContract;
  final List<ChangeRequestModel> changeRequests;
  final List<ExtensionRequestModel> extensionRequests;
  final BookingModel? booking;
  final Map<String, dynamic>? otherPartyProfile;

  const WorkItemData({
    required this.workItem,
    this.activeContract,
    this.changeRequests = const [],
    this.extensionRequests = const [],
    this.booking,
    this.otherPartyProfile,
  });

  /// Returns a copy with selectively replaced fields.
  WorkItemData copyWith({
    UnifiedWorkItemModel? workItem,
    WorkContractModel? activeContract,
    List<ChangeRequestModel>? changeRequests,
    List<ExtensionRequestModel>? extensionRequests,
    BookingModel? booking,
    Map<String, dynamic>? otherPartyProfile,
  }) {
    return WorkItemData(
      workItem: workItem ?? this.workItem,
      activeContract: activeContract ?? this.activeContract,
      changeRequests: changeRequests ?? this.changeRequests,
      extensionRequests: extensionRequests ?? this.extensionRequests,
      booking: booking ?? this.booking,
      otherPartyProfile: otherPartyProfile ?? this.otherPartyProfile,
    );
  }
}

class WorkItemDetailsViewModel extends ChangeNotifier {
  final WorkManagementService _workService;
  final String currentUserId;
  final ChatViewModel? _chatViewModel;
  final DashboardViewModel? _dashboardViewModel;

  WorkItemDetailsViewModel({
    WorkManagementService? workService,
    required String uid,
    ChatViewModel? chatViewModel,
    DashboardViewModel? dashboardViewModel,
  }) : _workService = workService ?? WorkManagementService(),
       currentUserId = uid,
       _chatViewModel = chatViewModel,
       _dashboardViewModel = dashboardViewModel {
    if (currentUserId.isEmpty) {
      AppLogger.w('WorkItemDetailsViewModel initialized without user ID');
    }
  }

  // ---------------------------------------------------------------------------
  // Primary sealed state
  // ---------------------------------------------------------------------------

  ViewState<WorkItemData> _state = const ViewInitial<WorkItemData>();
  ViewState<WorkItemData> get state => _state;

  // ---------------------------------------------------------------------------
  // Backward-compatible convenience getters (view keeps working unchanged)
  // ---------------------------------------------------------------------------

  bool get isLoading =>
      _state is ViewLoading<WorkItemData> ||
      _state is ViewInitial<WorkItemData> ||
      _actionInProgress;

  // ---------------------------------------------------------------------------
  // Action-level loading flag (preserves ViewLoaded data during mutations)
  // ---------------------------------------------------------------------------

  bool _actionInProgress = false;
  bool get actionInProgress => _actionInProgress;

  String? get error {
    final s = _state;
    if (s is ViewFailed<WorkItemData>) return s.failure.userMessage;
    return null;
  }

  WorkItemData? get _data {
    final s = _state;
    if (s is ViewLoaded<WorkItemData>) return s.data;
    return null;
  }

  UnifiedWorkItemModel? get workItem => _data?.workItem;
  WorkContractModel? get activeContract => _data?.activeContract;
  List<ChangeRequestModel> get changeRequests =>
      _data?.changeRequests ?? const [];
  List<ExtensionRequestModel> get extensionRequests =>
      _data?.extensionRequests ?? const [];
  BookingModel? get booking => _data?.booking;
  Map<String, dynamic>? get otherPartyProfile => _data?.otherPartyProfile;

  // Resolved Accessors
  String get title => workItem?.title ?? '';
  UnifiedWorkStatus get status =>
      workItem?.unifiedStatus ?? UnifiedWorkStatus.unknown;
  bool get isFreelancer => workItem?.freelancerId == currentUserId;
  bool get isClient => workItem?.clientId == currentUserId;
  bool get canReview => isClient && status == UnifiedWorkStatus.delivered;

  // ---------------------------------------------------------------------------
  // State transition helper
  // ---------------------------------------------------------------------------

  void _setState(ViewState<WorkItemData> newState) {
    final previous = _state.runtimeType;
    _state = newState;
    AppLogger.d(
      'WorkItemDetails state: $previous -> ${newState.runtimeType}',
      tag: 'WorkDetails',
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> loadData(String id, String type) async {
    _setState(const ViewLoading<WorkItemData>());

    try {
      // Parallel fetch with partial-failure tolerance: work item (and optional booking for booking-type detail).
      final results = await Future.wait([
        _workService.getUnifiedWorkItem(id, type),
        _workService.getActiveContract(id, type).catchError((_) => null),
        _workService
            .getPendingChangeRequests(id, type)
            .catchError((_) => <ChangeRequestModel>[]),
        _workService
            .getPendingExtensionRequests(id, type)
            .catchError((_) => <ExtensionRequestModel>[]),
        if (type == 'booking')
          _workService.getBooking(id)
        else
          Future<BookingModel?>.value(),
      ]);

      final loadedWorkItem = results[0] as UnifiedWorkItemModel?;
      final loadedContract = results[1] as WorkContractModel?;
      final loadedChangeRequests = results[2]! as List<ChangeRequestModel>;
      final loadedExtensionRequests =
          results[3]! as List<ExtensionRequestModel>;
      final loadedBooking = results[4] as BookingModel?;

      if (loadedWorkItem == null) {
        AppLogger.d(
          'Work item detail: view returned no row',
          tag: 'WorkDetails',
          json: {'id': id, 'type': type},
        );
        _setState(
          ViewFailed<WorkItemData>(
            BusinessFailure(
              'Work item not found',
              code: 'WORK_ITEM_NOT_FOUND',
              debugMessage: 'getUnifiedWorkItem returned null for $id ($type)',
            ),
          ),
        );
        return;
      }

      AppLogger.d(
        'Work item details loaded',
        tag: 'WorkDetails',
        json: {
          'work_item_id': loadedWorkItem.id,
          'source_type': loadedWorkItem.sourceType,
          'unified_status': loadedWorkItem.unifiedStatus.name,
          'needs_review': loadedWorkItem.needsReview,
        },
      );

      // Fetch other party profile after primary data is available.
      final isCurrentUserFreelancer =
          loadedWorkItem.freelancerId == currentUserId;
      final otherUserId = isCurrentUserFreelancer
          ? loadedWorkItem.clientId
          : loadedWorkItem.freelancerId;

      Map<String, dynamic>? profile;
      if (otherUserId.isNotEmpty) {
        profile = await _workService.getProfile(otherUserId);
      }

      _setState(
        ViewLoaded<WorkItemData>(
          WorkItemData(
            workItem: loadedWorkItem,
            activeContract: loadedContract,
            changeRequests: loadedChangeRequests,
            extensionRequests: loadedExtensionRequests,
            booking: loadedBooking,
            otherPartyProfile: profile,
          ),
        ),
      );
    } on Exception catch (e, stack) {
      AppLogger.e('WorkItemDetails load error', error: e, stackTrace: stack);
      _setState(
        ViewFailed<WorkItemData>(
          BusinessFailure(
            'Failed to load work details',
            code: 'LOAD_FAILED',
            debugMessage: e.toString(),
          ),
        ),
      );
    }
  }

  // --- Actions ---

  /// Helper: reads the current workItem from loaded state, or returns null.
  UnifiedWorkItemModel? get _currentWorkItem => workItem;

  Future<void> submitDelivery(String note) async {
    final item = _currentWorkItem;
    if (item == null) return;
    AppLogger.i(
      'submitDelivery started',
      tag: 'WorkItemDetails',
      json: {'entityId': item.id, 'sourceType': item.sourceType},
    );
    _actionInProgress = true;
    notifyListeners();
    try {
      await _workService.submitDelivery(
        entityId: item.id,
        entityType: item.sourceType,
        note: note,
      );

      AppLogger.i('submitDelivery completed', tag: 'WorkItemDetails');
      await loadData(item.id, item.sourceType);
    } on Exception catch (e, stack) {
      AppLogger.e('Submit delivery error', error: e, stackTrace: stack);
      _setState(
        ViewFailed<WorkItemData>(
          BusinessFailure(
            ErrorMapper.map(e),
            code: 'SUBMIT_DELIVERY_FAILED',
            debugMessage: e.toString(),
          ),
        ),
      );
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> approveDelivery() async {
    final item = _currentWorkItem;
    if (item == null) return;
    final correlationId =
        'apv_${item.id}_${DateTime.now().millisecondsSinceEpoch}';
    AppLogger.i(
      'approveDelivery called',
      tag: 'WorkItemDetails',
      json: {
        'entityId': item.id,
        'sourceType': item.sourceType,
        'correlationId': correlationId,
      },
    );
    _actionInProgress = true;
    notifyListeners();
    try {
      await _workService.approveDelivery(
        entityId: item.id,
        entityType: item.sourceType,
        correlationId: correlationId,
      );

      AppLogger.i('approveDelivery completed', tag: 'WorkItemDetails');
      await loadData(item.id, item.sourceType);
    } on Exception catch (e, stack) {
      AppLogger.e(
        'Approve delivery error',
        tag: 'WorkItemDetails',
        error: e,
        stackTrace: stack,
      );
      _setState(
        ViewFailed<WorkItemData>(
          BusinessFailure(
            ErrorMapper.map(e),
            code: 'APPROVE_DELIVERY_FAILED',
            debugMessage: e.toString(),
          ),
        ),
      );
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> requestRevision(String note) async {
    final item = _currentWorkItem;
    if (item == null) return;
    AppLogger.i(
      'requestRevision started',
      tag: 'WorkItemDetails',
      json: {'entityId': item.id, 'sourceType': item.sourceType},
    );
    _actionInProgress = true;
    notifyListeners();
    try {
      await _workService.requestRevision(
        entityId: item.id,
        entityType: item.sourceType,
        note: note,
      );

      AppLogger.i('requestRevision completed', tag: 'WorkItemDetails');
      await loadData(item.id, item.sourceType);
    } on Exception catch (e, stack) {
      AppLogger.e(
        'Request revision error',
        tag: 'WorkItemDetails',
        error: e,
        stackTrace: stack,
      );
      _setState(
        ViewFailed<WorkItemData>(
          BusinessFailure(
            ErrorMapper.map(e),
            code: 'REQUEST_REVISION_FAILED',
            debugMessage: e.toString(),
          ),
        ),
      );
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> acceptChangeRequest(String requestId) async {
    final item = _currentWorkItem;
    if (item == null) return;
    AppLogger.i(
      'acceptChangeRequest started',
      tag: 'WorkItemDetails',
      json: {'requestId': requestId, 'entityId': item.id},
    );
    _actionInProgress = true;
    notifyListeners();
    try {
      await _workService.acceptChangeRequest(requestId);

      AppLogger.i('acceptChangeRequest completed', tag: 'WorkItemDetails');
      await loadData(item.id, item.sourceType);
    } on Exception catch (e, stack) {
      AppLogger.e(
        'Accept change request error',
        tag: 'WorkItemDetails',
        error: e,
        stackTrace: stack,
      );
      _setState(
        ViewFailed<WorkItemData>(
          BusinessFailure(
            ErrorMapper.map(e),
            code: 'ACCEPT_CHANGE_REQUEST_FAILED',
            debugMessage: e.toString(),
          ),
        ),
      );
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> requestExtension(String note, int days) async {
    final item = _currentWorkItem;
    if (item == null) return;
    AppLogger.i(
      'requestExtension started',
      tag: 'WorkItemDetails',
      json: {'entityId': item.id, 'days': days},
    );
    _actionInProgress = true;
    notifyListeners();
    try {
      final currentDeadline = item.deadline ?? DateTime.now();
      final newDeadline = currentDeadline.add(Duration(days: days));

      await _workService.requestExtension(
        entityId: item.id,
        entityType: item.sourceType,
        newDeadline: newDeadline,
        reason: note,
        requesterId: currentUserId,
      );

      AppLogger.i('requestExtension completed', tag: 'WorkItemDetails');
      await loadData(item.id, item.sourceType);
    } on Exception catch (e, stack) {
      AppLogger.e('Request extension error', error: e, stackTrace: stack);
      _setState(
        ViewFailed<WorkItemData>(
          BusinessFailure(
            'Failed to request extension',
            code: 'REQUEST_EXTENSION_FAILED',
            debugMessage: e.toString(),
          ),
        ),
      );
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> acceptBooking() async {
    final item = _currentWorkItem;
    if (item == null) return;
    AppLogger.i(
      'acceptBooking started',
      tag: 'WorkItemDetails',
      json: {'entityId': item.id},
    );
    _actionInProgress = true;
    notifyListeners();
    try {
      await _workService.acceptBooking(item.id);

      AppLogger.i('acceptBooking completed', tag: 'WorkItemDetails');
      await loadData(item.id, item.sourceType);
    } on Exception catch (e, stack) {
      AppLogger.e('Accept booking error', error: e, stackTrace: stack);
      _setState(
        ViewFailed<WorkItemData>(
          BusinessFailure(
            'Failed to accept booking',
            code: 'ACCEPT_BOOKING_FAILED',
            debugMessage: e.toString(),
          ),
        ),
      );
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> declineBooking() async {
    final item = _currentWorkItem;
    if (item == null) return;
    AppLogger.i(
      'declineBooking started',
      tag: 'WorkItemDetails',
      json: {'entityId': item.id},
    );
    _actionInProgress = true;
    notifyListeners();
    try {
      await _workService.declineBooking(item.id);

      AppLogger.i('declineBooking completed', tag: 'WorkItemDetails');
      await loadData(item.id, item.sourceType);
    } on Exception catch (e, stack) {
      AppLogger.e('Decline booking error', error: e, stackTrace: stack);
      _setState(
        ViewFailed<WorkItemData>(
          BusinessFailure(
            'Failed to decline booking',
            code: 'DECLINE_BOOKING_FAILED',
            debugMessage: e.toString(),
          ),
        ),
      );
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> cancelBooking() async {
    final item = _currentWorkItem;
    if (item == null) return;
    AppLogger.i(
      'cancelBooking started',
      tag: 'WorkItemDetails',
      json: {'entityId': item.id},
    );
    _actionInProgress = true;
    notifyListeners();
    try {
      await _workService.cancelBooking(item.id);

      AppLogger.i('cancelBooking completed', tag: 'WorkItemDetails');
      await loadData(item.id, item.sourceType);
    } on Exception catch (e, stack) {
      AppLogger.e('Cancel booking error', error: e, stackTrace: stack);
      _setState(
        ViewFailed<WorkItemData>(
          BusinessFailure(
            'Failed to cancel booking',
            code: 'CANCEL_BOOKING_FAILED',
            debugMessage: e.toString(),
          ),
        ),
      );
    } finally {
      _actionInProgress = false;
    }
  }

  /// Opens conversation for current work item (task-linked or DM for booking). Returns null if unavailable.
  Future<Conversation?> openConversation() async {
    final item = _currentWorkItem;
    if (item == null || _chatViewModel == null) return null;
    return _chatViewModel.createOrGetConversation(
      taskId: item.isTask ? item.id : null,
      user1Id: item.clientId,
      user2Id: item.freelancerId,
    );
  }

  /// Refreshes dashboard work list (e.g. after payment). No-op if dashboard not injected.
  void refreshDashboard() {
    unawaited(_dashboardViewModel?.refresh());
  }

  /// Cancels awarded offer. No-op if dashboard not injected. Caller should handle errors.
  Future<void> cancelAward(String requestId) async {
    if (_dashboardViewModel == null) return;
    await _dashboardViewModel.cancelAwardedOffer(requestId);
  }
}
