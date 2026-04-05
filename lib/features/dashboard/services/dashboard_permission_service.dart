import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';

/// Service to determine what actions a user can perform on a dashboard item.
class DashboardPermissionService {
  /// Calculates permissions for a WorkItem based on role and status.
  static WorkItemPermissions calculatePermissions({
    required UserRole userRole,
    required WorkItemType type,
    required Enum status, // BookingStatus, TaskStatus, or UnifiedWorkStatus
  }) {
    if (type == WorkItemType.booking && status is BookingStatus) {
      return _getBookingPermissions(userRole, status);
    } else if (type == WorkItemType.task && status is TaskStatus) {
      return _getTaskPermissions(userRole, status);
    } else if (type == WorkItemType.directOffer &&
        status is UnifiedWorkStatus) {
      return _getUnifiedPermissions(userRole, status);
    } else if (status is UnifiedWorkStatus) {
      return _getUnifiedPermissions(userRole, status);
    }
    return WorkItemPermissions();
  }

  static WorkItemPermissions _getUnifiedPermissions(
    UserRole role,
    UnifiedWorkStatus status,
  ) {
    if (role == UserRole.freelancer) {
      return WorkItemPermissions(
        canStart: status == UnifiedWorkStatus.active,
        canComplete: false,
        canApprove: false,
        canCancel: false,
      );
    } else {
      // Client permissions (task awarded pending payment: can pay or cancel)
      return WorkItemPermissions(
        canStart: false,
        canComplete: false,
        canApprove: false,
        canCancel: status == UnifiedWorkStatus.pendingPayment,
        // v1 client permissions
        canReview: status == UnifiedWorkStatus.delivered,
        canDispute:
            status == UnifiedWorkStatus.active ||
            status == UnifiedWorkStatus.delivered,
        canPayEscrow: status == UnifiedWorkStatus.pendingPayment,
      );
    }
  }

  static WorkItemPermissions _getBookingPermissions(
    UserRole role,
    BookingStatus status,
  ) {
    if (role == UserRole.freelancer) {
      return WorkItemPermissions(
        canStart: status == BookingStatus.confirmed,
        canComplete: status == BookingStatus.inProgress,
        canCancel:
            status == BookingStatus.pending ||
            status == BookingStatus.confirmed,
        canReschedule:
            status == BookingStatus.pending ||
            status == BookingStatus.confirmed,
        canApprove: false,
      );
    } else {
      // Client permissions
      return WorkItemPermissions(
        canStart: false,
        canComplete: false,
        canApprove: status == BookingStatus.completed,
        canCancel:
            status == BookingStatus.pending ||
            status == BookingStatus.confirmed,
        canReschedule:
            status == BookingStatus.pending ||
            status == BookingStatus.confirmed,
        canReview: status == BookingStatus.delivered,
        canPayEscrow: status == BookingStatus.paidRequestPending,
      );
    }
  }

  static WorkItemPermissions _getTaskPermissions(
    UserRole role,
    TaskStatus status,
  ) {
    if (role == UserRole.freelancer) {
      return WorkItemPermissions(
        canStart: status == TaskStatus.assigned,
        canComplete: status == TaskStatus.inProgress,
        canCancel: status == TaskStatus.assigned,
      );
    } else {
      // Client permissions
      return WorkItemPermissions(
        canStart: false,
        canComplete: false,
        canApprove: status == TaskStatus.completed,
        canCancel: status == TaskStatus.open || status == TaskStatus.assigned,
        canReschedule: false,
      );
    }
  }

  /// Determines the primary action button for the UI.
  static PrimaryActionType getPrimaryAction({
    required UserRole userRole,
    required WorkItemType type,
    required Enum status,
  }) {
    final perms = calculatePermissions(
      userRole: userRole,
      type: type,
      status: status,
    );

    // v1 client-specific actions take priority
    if (perms.canReview) return PrimaryActionType.reviewDelivery;
    if (perms.canPayEscrow) return PrimaryActionType.payEscrow;

    // Standard actions
    if (perms.canComplete) return PrimaryActionType.markCompleted;
    if (perms.canStart) return PrimaryActionType.startWork;
    if (perms.canApprove) return PrimaryActionType.approveClose;

    // Unified status-specific fallbacks
    if (status is UnifiedWorkStatus) {
      if (status == UnifiedWorkStatus.disputed) {
        return PrimaryActionType.submitEvidence;
      }
    }

    // Default: view details
    return PrimaryActionType.viewDetails;
  }
}
