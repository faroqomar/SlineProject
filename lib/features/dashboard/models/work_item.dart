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
  final String statusUiBucket; // 'Active', 'Pending', 'Done', 'Cancelled'
  final DateTime createdAt;
  final DateTime? scheduledAt; // For bookings/tasks with deadlines
  final DateTime? completedAt;
  final DateTime lastUpdate;
  final PrimaryActionType primaryActionType;
  final String? deepLinkRoute;
  final WorkItemPermissions permissions;
  // v1 additions
  final String
  workItemId; // 'task:<uuid>' or 'booking:<uuid>' or 'direct_offer:<uuid>'
  final bool needsReview;
  final int sortRank;
  final DateTime? lastActivityAt;

  /// For direct offers: conversation to open when tapping the card.
  final String? conversationId;

  /// For awarded pending-payment tasks: task_request id for Pay/Cancel.
  final String? awardedRequestId;
  final DateTime? paymentDeadline;

  /// Optional price (e.g. for tender pending payment) for payment screen.
  final double? price;

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
    this.workItemId = '',
    this.needsReview = false,
    this.sortRank = 6,
    this.lastActivityAt,
    this.conversationId,
    this.awardedRequestId,
    this.paymentDeadline,
    this.price,
  });

  bool get actionableNeedsReview => needsReview && permissions.canReview;

  bool get awaitingCounterpartyReview => needsReview && !permissions.canReview;

  /// Create a copy with updated counterparty profile info
  WorkItem withCounterparty({required String name, required String avatar}) {
    return WorkItem(
      id: id,
      type: type,
      title: title,
      counterpartyId: counterpartyId,
      counterpartyName: name,
      counterpartyAvatar: avatar,
      counterpartyRole: counterpartyRole,
      sourceId: sourceId,
      statusRaw: statusRaw,
      statusUiBucket: statusUiBucket,
      createdAt: createdAt,
      scheduledAt: scheduledAt,
      completedAt: completedAt,
      lastUpdate: lastUpdate,
      primaryActionType: primaryActionType,
      deepLinkRoute: deepLinkRoute,
      permissions: permissions,
      workItemId: workItemId,
      needsReview: needsReview,
      sortRank: sortRank,
      lastActivityAt: lastActivityAt,
      conversationId: conversationId,
      awardedRequestId: awardedRequestId,
      paymentDeadline: paymentDeadline,
      price: price,
    );
  }

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
      'workItemId': workItemId,
      'needsReview': needsReview,
      'sortRank': sortRank,
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'conversationId': conversationId,
      'awardedRequestId': awardedRequestId,
      'paymentDeadline': paymentDeadline?.toIso8601String(),
      'price': price,
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
        orElse: () => PrimaryActionType.viewDetails,
      ),
      deepLinkRoute: json['deepLinkRoute'] as String?,
      permissions: WorkItemPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>,
      ),
      workItemId: json['workItemId'] as String? ?? '',
      needsReview: json['needsReview'] as bool? ?? false,
      sortRank: json['sortRank'] as int? ?? 6,
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'] as String)
          : null,
      conversationId: json['conversationId'] as String?,
      awardedRequestId: json['awardedRequestId'] as String?,
      paymentDeadline: json['paymentDeadline'] != null
          ? DateTime.parse(json['paymentDeadline'] as String)
          : null,
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}

class WorkItemPermissions {
  final bool canStart;
  final bool canComplete;
  final bool canApprove;
  final bool canCancel;
  final bool canReschedule;
  // v1 additions
  final bool canReview;
  final bool canDispute;
  final bool canPayEscrow;

  WorkItemPermissions({
    this.canStart = false,
    this.canComplete = false,
    this.canApprove = false,
    this.canCancel = false,
    this.canReschedule = false,
    this.canReview = false,
    this.canDispute = false,
    this.canPayEscrow = false,
  });

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'canStart': canStart,
      'canComplete': canComplete,
      'canApprove': canApprove,
      'canCancel': canCancel,
      'canReschedule': canReschedule,
      'canReview': canReview,
      'canDispute': canDispute,
      'canPayEscrow': canPayEscrow,
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
      canReview: json['canReview'] as bool? ?? false,
      canDispute: json['canDispute'] as bool? ?? false,
      canPayEscrow: json['canPayEscrow'] as bool? ?? false,
    );
  }
}
