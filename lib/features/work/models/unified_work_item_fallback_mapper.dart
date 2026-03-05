import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/work/models/unified_work_item_model.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';

/// Single source of truth for mapping fallback data (task_requests+tasks or booking)
/// to [UnifiedWorkItemModel]. Used by work detail and dashboard so semantics stay aligned.
/// Per PLAN: work-owned; dashboard consumes this.
class UnifiedWorkItemFallbackMapper {
  UnifiedWorkItemFallbackMapper._();

  /// Builds [UnifiedWorkItemModel] from a task_requests row with joined tasks (task fallback).
  /// [taskRequestWithTask] must contain task_request fields and nested 'tasks' map.
  static UnifiedWorkItemModel? fromTaskRequestAndTaskMap(
    Map<String, dynamic> taskRequestWithTask,
  ) {
    final map = Map<String, dynamic>.from(taskRequestWithTask);
    final tasksMap = map['tasks'] as Map<String, dynamic>?;
    if (tasksMap == null) return null;

    final t = Map<String, dynamic>.from(tasksMap);
    final taskId = t['id'] as String?;
    if (taskId == null) return null;

    final trId = map['id'] as String?;
    final price = (map['price'] as num?)?.toDouble() ?? 0.0;
    final freelancerId =
        (map['freelancer_id'] as String?) ?? (map['bidder_id'] as String?) ?? '';
    final clientId =
        (t['client_id'] as String?) ?? (t['owner_id'] as String?) ?? '';
    final paymentDeadline = map['payment_deadline'] != null
        ? DateTime.tryParse(map['payment_deadline'] as String)
        : null;
    final trUpdated = map['updated_at'] != null
        ? DateTime.tryParse(map['updated_at'] as String)
        : null;
    final tUpdated = t['updated_at'] != null
        ? DateTime.tryParse(t['updated_at'] as String)
        : null;
    final deadline = t['deadline'] != null
        ? DateTime.tryParse(t['deadline'] as String)
        : null;

    final viewRow = <String, dynamic>{
      'id': taskId,
      'source_type': 'task',
      'source_status': 'assigned',
      'unified_status': 'pending_payment',
      'title': t['title'] as String? ?? 'Task',
      'price': price,
      'deadline': deadline?.toIso8601String(),
      'client_id': clientId,
      'freelancer_id': freelancerId,
      'delivered_at': null,
      'review_expires_at': null,
      'revisions_total': 3,
      'revisions_used': 0,
      'work_item_id': 'task:$taskId',
      'last_activity_at': (trUpdated ?? tUpdated)?.toIso8601String(),
      'needs_review': false,
      'sort_rank': 2,
      'awarded_request_id': trId,
      'payment_deadline': paymentDeadline?.toIso8601String(),
    };
    return UnifiedWorkItemModel.fromJson(viewRow);
  }

  /// Builds [UnifiedWorkItemModel] from a [BookingModel] (booking fallback).
  /// Maps completed → [UnifiedWorkStatus.completed] (not delivered) so Review is not shown.
  static UnifiedWorkItemModel fromBooking(BookingModel b) {
    final uStatus = _bookingStatusToUnified(b.status);
    return UnifiedWorkItemModel(
      id: b.id,
      sourceType: 'booking',
      sourceStatus: b.status.name,
      unifiedStatus: uStatus,
      title: b.taskData?['title'] ?? 'Booking Task',
      price: (b.price ?? 0).toDouble(),
      deadline: b.dueAtUtc ?? b.scheduledAt,
      clientId: b.clientId,
      freelancerId: b.providerId,
      revisionsTotal: 0,
      revisionsUsed: 0,
    );
  }

  static UnifiedWorkStatus _bookingStatusToUnified(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.paidRequestPending:
        return UnifiedWorkStatus.pending;
      case BookingStatus.confirmed:
      case BookingStatus.active:
      case BookingStatus.inProgress:
        return UnifiedWorkStatus.active;
      case BookingStatus.delivered:
        return UnifiedWorkStatus.delivered;
      case BookingStatus.completed:
        return UnifiedWorkStatus.completed;
      case BookingStatus.declined:
      case BookingStatus.canceled:
      case BookingStatus.refunded:
      case BookingStatus.expiredUnanswered:
      case BookingStatus.noShow:
        return UnifiedWorkStatus.canceled;
    }
  }
}
