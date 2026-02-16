import 'package:sline_app/core/app_enums.dart';
import '../models/work_item.dart';

/// Service to determine what actions a user can perform on a dashboard item.
class DashboardPermissionService {
  /// Calculates permissions for a WorkItem based on role and status.
  static WorkItemPermissions calculatePermissions({
    required UserRole userRole,
    required WorkItemType type,
    required Enum status, // BookingStatus or TaskStatus
  }) {
    if (type == WorkItemType.booking && status is BookingStatus) {
      return _getBookingPermissions(userRole, status);
    } else if (type == WorkItemType.task && status is TaskStatus) {
      return _getTaskPermissions(userRole, status);
    } else if (status is UnifiedWorkStatus) {
      return _getUnifiedPermissions(userRole, status);
    }
    return WorkItemPermissions();
  }

  static WorkItemPermissions _getUnifiedPermissions(
    UserRole role,
    UnifiedWorkStatus status,
  ) {
    // Unified Status: active, delivered, completed, cancelled, pending, unknown
    if (role == UserRole.freelancer) {
      return WorkItemPermissions(
        canStart: status == UnifiedWorkStatus.active, // Can "Submit Work"
        canComplete:
            false, // Delivered is a state, not permission to "Mark Completed" (Client does that)
        canApprove: false,
        canCancel: false, // Usually can't cancel active work easily
      );
    } else {
      // Client
      return WorkItemPermissions(
        canStart: false,
        canComplete: false,
        canApprove:
            status == UnifiedWorkStatus.delivered, // Can Accept Delivery
        canCancel: false,
      );
    }
  }

  static WorkItemPermissions _getBookingPermissions(
    UserRole role,
    BookingStatus status,
  ) {
    if (role == UserRole.freelancer) {
      // Freelancer permissions
      return WorkItemPermissions(
        canStart: status == BookingStatus.confirmed, // Can start if confirmed
        canComplete:
            status == BookingStatus.inProgress, // Can complete if in progress
        canCancel:
            status == BookingStatus.pending ||
            status == BookingStatus.confirmed,
        canReschedule:
            status == BookingStatus.pending ||
            status == BookingStatus.confirmed,
        canApprove:
            false, // Only clients approve completion usually (or system)
      );
    } else {
      // Client permissions
      return WorkItemPermissions(
        canStart: false,
        canComplete: false,
        canApprove:
            status ==
            BookingStatus
                .completed, // Approve means closing/reviewing? Or "Mark as done"?
        // Let's assume Client confirms completion or just reviews.
        // For now, if "Completed" by freelancer, maybe client "Closes" it.
        // Actually, BookingStatus.completed usually means job done.
        canCancel:
            status == BookingStatus.pending ||
            status == BookingStatus.confirmed,
        canReschedule:
            status == BookingStatus.pending ||
            status == BookingStatus.confirmed,
      );
    }
  }

  static WorkItemPermissions _getTaskPermissions(
    UserRole role,
    TaskStatus status,
  ) {
    if (role == UserRole.freelancer) {
      // Freelancer (Assigned to task)
      return WorkItemPermissions(
        canStart: status == TaskStatus.assigned,
        canComplete: status == TaskStatus.inProgress,
        canCancel: status == TaskStatus.assigned, // Can maybe drop it?
      );
    } else {
      // Client (Owner of task)
      return WorkItemPermissions(
        canStart: false,
        canComplete: false,
        canApprove: status == TaskStatus.completed, // Review work
        canCancel: status == TaskStatus.open || status == TaskStatus.assigned,
        canReschedule: false, // tasks usually have deadlines, separate logic
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

    if (perms.canComplete) return PrimaryActionType.markCompleted;
    if (perms.canStart) return PrimaryActionType.startWork;
    if (perms.canApprove) return PrimaryActionType.approveClose;

    // Unified Flow Action Mapping
    if (status is UnifiedWorkStatus) {
      if (userRole == UserRole.freelancer &&
          status == UnifiedWorkStatus.active) {
        return PrimaryActionType.startWork; // "Submit Work"
      }
      if (userRole == UserRole.client &&
          status == UnifiedWorkStatus.delivered) {
        return PrimaryActionType.approveClose; // "Accept Delivery"
      }
    }

    // Fallback or specific logical defaults
    if (type == WorkItemType.booking) {
      if (status == BookingStatus.pending && userRole == UserRole.freelancer) {
        // Freelancer needs to Accept/Decline. Not strict "PrimaryAction" enum maybe?
        // Or maybe startWork covers "View Details" to accept?
        return PrimaryActionType.startWork; // Placeholder
      }
    }

    return PrimaryActionType
        .approveClose; // Default safe (View Details usually)
  }
}
