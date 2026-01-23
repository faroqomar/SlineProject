import 'package:sline_app/core/app_enums.dart';

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

  /// Serialize to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'counterpartyId': counterpartyId,
      'counterpartyName': counterpartyName,
      'counterpartyAvatar': counterpartyAvatar,
      'counterpartyRole': counterpartyRole,
      'sourceId': sourceId,
      'statusRaw': statusRaw,
      'statusUiBucket': statusUiBucket,
      'createdAt': createdAt.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lastUpdate': lastUpdate.toIso8601String(),
      'primaryActionType': primaryActionType.name,
      'deepLinkRoute': deepLinkRoute,
      'permissions': permissions.toJson(),
    };
  }

  /// Deserialize from JSON for cache retrieval
  factory WorkItem.fromJson(Map<String, dynamic> json) {
    return WorkItem(
      id: json['id'] as String,
      type: WorkItemType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'] as String,
      counterpartyId: json['counterpartyId'] as String,
      counterpartyName: json['counterpartyName'] as String,
      counterpartyAvatar: json['counterpartyAvatar'] as String,
      counterpartyRole: json['counterpartyRole'] as String,
      sourceId: json['sourceId'] as String?,
      statusRaw: json['statusRaw'] as String,
      statusUiBucket: json['statusUiBucket'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
      primaryActionType: PrimaryActionType.values.firstWhere(
        (e) => e.name == json['primaryActionType'],
      ),
      deepLinkRoute: json['deepLinkRoute'] as String?,
      permissions: WorkItemPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>,
      ),
    );
  }
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

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'canStart': canStart,
      'canComplete': canComplete,
      'canApprove': canApprove,
      'canCancel': canCancel,
      'canReschedule': canReschedule,
    };
  }

  /// Deserialize from JSON
  factory WorkItemPermissions.fromJson(Map<String, dynamic> json) {
    return WorkItemPermissions(
      canStart: json['canStart'] as bool? ?? false,
      canComplete: json['canComplete'] as bool? ?? false,
      canApprove: json['canApprove'] as bool? ?? false,
      canCancel: json['canCancel'] as bool? ?? false,
      canReschedule: json['canReschedule'] as bool? ?? false,
    );
  }
}
