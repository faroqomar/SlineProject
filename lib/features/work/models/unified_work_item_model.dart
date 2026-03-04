import 'package:sline_app/core/app_enums.dart';

/// Model for the `vw_unified_work_items` view.
class UnifiedWorkItemModel {
  final String id;
  final String sourceType; // 'task' or 'booking'
  final String sourceStatus;
  final UnifiedWorkStatus unifiedStatus;
  final String title;
  final double price;
  final DateTime? deadline;
  final String clientId;
  final String freelancerId;
  final DateTime? deliveredAt;
  final DateTime? reviewExpiresAt;
  final int revisionsTotal;
  final int revisionsUsed;
  // v1 computed columns
  final String workItemId; // 'task:<uuid>' or 'booking:<uuid>'
  final DateTime? lastActivityAt;
  final bool needsReview;
  final int sortRank;
  final String? resolutionType; // placeholder, nullable
  final bool? disputeRequiresUserAction; // placeholder, nullable
  /// Set for awarded pending-payment tasks (branch from vw_unified_work_items).
  final String? awardedRequestId;
  final DateTime? paymentDeadline;

  const UnifiedWorkItemModel({
    required this.id,
    required this.sourceType,
    required this.sourceStatus,
    required this.unifiedStatus,
    required this.title,
    required this.price,
    this.deadline,
    required this.clientId,
    required this.freelancerId,
    this.deliveredAt,
    this.reviewExpiresAt,
    required this.revisionsTotal,
    required this.revisionsUsed,
    this.workItemId = '',
    this.lastActivityAt,
    this.needsReview = false,
    this.sortRank = 6,
    this.resolutionType,
    this.disputeRequiresUserAction,
    this.awardedRequestId,
    this.paymentDeadline,
  });

  factory UnifiedWorkItemModel.fromJson(Map<String, dynamic> json) {
    return UnifiedWorkItemModel(
      id: json['id'] as String,
      sourceType: json['source_type'] as String,
      sourceStatus: json['source_status'] as String,
      unifiedStatus: _mapStatus(json['unified_status'] as String?),
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      clientId: json['client_id'] as String,
      freelancerId: json['freelancer_id'] as String,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      reviewExpiresAt: json['review_expires_at'] != null
          ? DateTime.parse(json['review_expires_at'] as String)
          : null,
      revisionsTotal: (json['revisions_total'] as int?) ?? 3,
      revisionsUsed: (json['revisions_used'] as int?) ?? 0,
      workItemId: json['work_item_id'] as String? ?? '',
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
      needsReview: json['needs_review'] as bool? ?? false,
      sortRank: json['sort_rank'] as int? ?? 6,
      resolutionType: json['resolution_type'] as String?,
      disputeRequiresUserAction: json['dispute_requires_user_action'] as bool?,
      awardedRequestId: json['awarded_request_id'] as String?,
      paymentDeadline: json['payment_deadline'] != null
          ? DateTime.parse(json['payment_deadline'] as String)
          : null,
    );
  }

  static UnifiedWorkStatus _mapStatus(String? status) {
    if (status == null) return UnifiedWorkStatus.unknown;
    // Map DB values to enum
    switch (status) {
      case 'active':
        return UnifiedWorkStatus.active;
      case 'delivered':
        return UnifiedWorkStatus.delivered;
      case 'completed':
        return UnifiedWorkStatus.completed;
      case 'canceled':
        return UnifiedWorkStatus.canceled;
      case 'pending_payment':
        return UnifiedWorkStatus.pendingPayment;
      case 'request_pending':
        return UnifiedWorkStatus.requestPending;
      case 'disputed':
        return UnifiedWorkStatus.disputed;
      case 'paid_request_pending':
        // Maps to requestPending so UI shows Accept/Decline (for freelancer) or Cancel (for client)
        return UnifiedWorkStatus.requestPending;
      case 'pending':
        return UnifiedWorkStatus.pending;
      default:
        return UnifiedWorkStatus.unknown;
    }
  }

  bool get isTask => sourceType == 'task';
  bool get isBooking => sourceType == 'booking';
}
