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
    );
  }

  static UnifiedWorkStatus _mapStatus(String? status) {
    if (status == null) return UnifiedWorkStatus.unknown;
    return UnifiedWorkStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => UnifiedWorkStatus.unknown,
    );
  }

  bool get isTask => sourceType == 'task';
  bool get isBooking => sourceType == 'booking';
}
