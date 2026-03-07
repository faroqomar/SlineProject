import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/work/models/unified_work_item_model.dart';
import 'package:sline_app/features/work/models/unified_work_item_fallback_mapper.dart';
import 'package:sline_app/features/work/models/work_contract_model.dart';
import 'package:sline_app/features/work/models/change_request_model.dart';
import 'package:sline_app/features/work/models/extension_request_model.dart';
import 'package:sline_app/features/work/services/work_management_service.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';

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
  })  : _workService = workService ?? WorkManagementService(),
        currentUserId = uid,
        _chatViewModel = chatViewModel,
        _dashboardViewModel = dashboardViewModel {
    if (currentUserId.isEmpty) {
      AppLogger.w('WorkItemDetailsViewModel initialized without user ID');
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Unified Data
  UnifiedWorkItemModel? _workItem;
  UnifiedWorkItemModel? get workItem => _workItem;

  WorkContractModel? _activeContract;
  WorkContractModel? get activeContract => _activeContract;

  List<ChangeRequestModel> _changeRequests = [];
  List<ChangeRequestModel> get changeRequests => _changeRequests;

  List<ExtensionRequestModel> _extensionRequests = [];
  List<ExtensionRequestModel> get extensionRequests => _extensionRequests;

  // Resolved Accessors
  String get title => _workItem?.title ?? '';
  UnifiedWorkStatus get status =>
      _workItem?.unifiedStatus ?? UnifiedWorkStatus.unknown;
  bool get isFreelancer => _workItem?.freelancerId == currentUserId;
  bool get isClient => _workItem?.clientId == currentUserId;
  bool get canReview => isClient && status == UnifiedWorkStatus.delivered;

  // Booking Specifics
  BookingModel? _booking;
  BookingModel? get booking => _booking;

  Map<String, dynamic>? _otherPartyProfile;
  Map<String, dynamic>? get otherPartyProfile => _otherPartyProfile;

  Future<void> loadData(String id, String type) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Parallel fetch with partial-failure tolerance: only work item (and booking fallback) is required.
      final results = await Future.wait([
        _workService.getUnifiedWorkItem(id, type),
        _workService.getActiveContract(id, type).catchError((_) => null),
        _workService.getPendingChangeRequests(id, type).catchError((_) => <ChangeRequestModel>[]),
        _workService.getPendingExtensionRequests(id, type).catchError((_) => <ExtensionRequestModel>[]),
        type == 'booking' ? _workService.getBooking(id) : Future.value(null),
      ]);

      _workItem = results[0] as UnifiedWorkItemModel?;
      _activeContract = results[1] as WorkContractModel?;
      _changeRequests = results[2] as List<ChangeRequestModel>;
      _extensionRequests = results[3] as List<ExtensionRequestModel>;
      _booking = results[4] as BookingModel?;

      // Fallback: If UnifiedWorkItem is missing but we have booking data, use shared mapper
      if (_workItem == null && _booking != null) {
        _workItem = UnifiedWorkItemFallbackMapper.fromBooking(_booking!);
      }

      if (_workItem == null) {
        _error = 'Work item not found';
      } else {
        AppLogger.d(
          'Work item details loaded',
          json: {
            'work_item_id': _workItem!.id,
            'source_type': _workItem!.sourceType,
            'unified_status': _workItem!.unifiedStatus.name,
            'needs_review': _workItem!.needsReview,
            'can_review': canReview,
          },
        );
        // Fetch User Profile
        final otherUserId = isFreelancer
            ? _workItem!.clientId
            : _workItem!.freelancerId;
        if (otherUserId.isNotEmpty) {
          _otherPartyProfile = await _workService.getProfile(otherUserId);
        }
      }
    } catch (e, stack) {
      _error = 'Failed to load work details';
      AppLogger.e('WorkItemDetails load error', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Actions ---

  Future<void> submitDelivery(String note) async {
    if (_workItem == null) return;
    try {
      _isLoading = true;
      notifyListeners();

      await _workService.submitDelivery(
        entityId: _workItem!.id,
        entityType: _workItem!.sourceType,
        note: note,
      );

      await loadData(_workItem!.id, _workItem!.sourceType);
    } catch (e, stack) {
      _error = 'Failed to submit delivery';
      AppLogger.e('Submit delivery error', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveDelivery() async {
    if (_workItem == null) return;
    final correlationId =
        'apv_${_workItem!.id}_${DateTime.now().millisecondsSinceEpoch}';
    AppLogger.i(
      'approveDelivery called',
      tag: 'WorkItemDetails',
      json: {
        'entityId': _workItem!.id,
        'sourceType': _workItem!.sourceType,
        'correlationId': correlationId,
      },
    );
    try {
      _isLoading = true;
      notifyListeners();

      await _workService.approveDelivery(
        entityId: _workItem!.id,
        entityType: _workItem!.sourceType,
        correlationId: correlationId,
      );

      await loadData(_workItem!.id, _workItem!.sourceType);
    } catch (e, stack) {
      _error = 'Failed to approve delivery';
      AppLogger.e(
        'Approve delivery error',
        tag: 'WorkItemDetails',
        error: e,
        stackTrace: stack,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestRevision(String note) async {
    if (_workItem == null) return;
    try {
      _isLoading = true;
      notifyListeners();

      await _workService.requestRevision(
        entityId: _workItem!.id,
        entityType: _workItem!.sourceType,
        note: note,
      );

      await loadData(_workItem!.id, _workItem!.sourceType);
    } catch (e, stack) {
      _error = 'Failed to request revision';
      AppLogger.e('Request revision error', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptChangeRequest(String requestId) async {
    if (_workItem == null) return;
    try {
      _isLoading = true;
      notifyListeners();

      await _workService.acceptChangeRequest(requestId);

      await loadData(_workItem!.id, _workItem!.sourceType);
    } catch (e, stack) {
      _error = 'Failed to accept change request';
      AppLogger.e('Accept change request error', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestExtension(String note, int days) async {
    if (_workItem == null) return;
    try {
      _isLoading = true;
      notifyListeners();

      final currentDeadline = _workItem!.deadline ?? DateTime.now();
      final newDeadline = currentDeadline.add(Duration(days: days));

      await _workService.requestExtension(
        entityId: _workItem!.id,
        entityType: _workItem!.sourceType,
        newDeadline: newDeadline,
        reason: note,
        requesterId: currentUserId,
      );

      await loadData(_workItem!.id, _workItem!.sourceType);
    } catch (e, stack) {
      _error = 'Failed to request extension';
      AppLogger.e('Request extension error', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptBooking() async {
    if (_workItem == null) return;
    try {
      _isLoading = true;
      notifyListeners();

      await _workService.acceptBooking(_workItem!.id);

      await loadData(_workItem!.id, _workItem!.sourceType);
    } catch (e, stack) {
      _error = 'Failed to accept booking';
      AppLogger.e('Accept booking error', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> declineBooking() async {
    if (_workItem == null) return;
    try {
      _isLoading = true;
      notifyListeners();

      await _workService.declineBooking(_workItem!.id);

      await loadData(_workItem!.id, _workItem!.sourceType);
    } catch (e, stack) {
      _error = 'Failed to decline booking';
      AppLogger.e('Decline booking error', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelBooking() async {
    if (_workItem == null) return;
    try {
      _isLoading = true;
      notifyListeners();

      await _workService.cancelBooking(_workItem!.id);

      await loadData(_workItem!.id, _workItem!.sourceType);
    } catch (e, stack) {
      _error = 'Failed to cancel booking';
      AppLogger.e('Cancel booking error', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Opens conversation for current work item (task-linked or DM for booking). Returns null if unavailable.
  Future<Conversation?> openConversation() async {
    final item = _workItem;
    if (item == null || _chatViewModel == null) return null;
    return _chatViewModel.createOrGetConversation(
      taskId: item.isTask ? item.id : null,
      user1Id: item.clientId,
      user2Id: item.freelancerId,
    );
  }

  /// Refreshes dashboard work list (e.g. after payment). No-op if dashboard not injected.
  void refreshDashboard() {
    _dashboardViewModel?.refresh();
  }

  /// Cancels awarded offer. No-op if dashboard not injected. Caller should handle errors.
  Future<void> cancelAward(String requestId) async {
    if (_dashboardViewModel == null) return;
    await _dashboardViewModel.cancelAwardedOffer(requestId);
  }
}
