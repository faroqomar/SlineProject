import 'dashboard_enums.dart';

class WorkItem {
  final String id;
  final WorkItemType type;
  final String title;
  final String counterpartyId;
  final String counterpartyName;
  final String counterpartyAvatar;
  final String counterpartyRole; // 'Client' or 'Freelancer'
  final String? sourceId;
  final String statusRaw; // String representation of original status
  final String statusUiBucket; // 'Active', 'Waiting', 'Done'
  final DateTime createdAt;
  final DateTime? scheduledAt; // For bookings/tasks with deadlines
  final DateTime? completedAt;
  final DateTime lastUpdate;
  final PrimaryActionType primaryActionType;
  final String? deepLinkRoute;
  final WorkItemPermissions permissions;

  WorkItem({
    required this.id,
    required this.type,
    required this.title,
    required this.counterpartyId,
    required this.counterpartyName,
    required this.counterpartyAvatar,
    required this.counterpartyRole,
    this.sourceId,
    required this.statusRaw,
    required this.statusUiBucket,
    required this.createdAt,
    this.scheduledAt,
    this.completedAt,
    required this.lastUpdate,
    required this.primaryActionType,
    this.deepLinkRoute,
    required this.permissions,
  });
}

class WorkItemPermissions {
  final bool canStart;
  final bool canComplete;
  final bool canApprove;
  final bool canCancel;
  final bool canReschedule;

  WorkItemPermissions({
    this.canStart = false,
    this.canComplete = false,
    this.canApprove = false,
    this.canCancel = false,
    this.canReschedule = false,
  });
}
