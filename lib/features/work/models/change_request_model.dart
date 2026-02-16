/// Model for `change_requests` table.
class ChangeRequestModel {
  final String id;
  final String relatedEntityType;
  final String relatedEntityId;
  final String requesterId;
  final String? scopeDiff;
  final double? priceDiff;
  final int? daysDiff;
  final String status; // 'pending', 'accepted', 'rejected', 'cancelled'
  final String? description;
  final int? appliedContractVersion;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const ChangeRequestModel({
    required this.id,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.requesterId,
    this.scopeDiff,
    this.priceDiff,
    this.daysDiff,
    required this.status,
    this.description,
    this.appliedContractVersion,
    required this.createdAt,
    this.resolvedAt,
  });

  factory ChangeRequestModel.fromJson(Map<String, dynamic> json) {
    return ChangeRequestModel(
      id: json['id'] as String,
      relatedEntityType: json['related_entity_type'] as String,
      relatedEntityId: json['related_entity_id'] as String,
      requesterId: json['requester_id'] as String,
      scopeDiff: json['scope_diff'] as String?,
      priceDiff: (json['price_diff'] as num?)?.toDouble(),
      daysDiff: json['days_diff'] as int?,
      status: json['status'] as String,
      description: json['description'] as String?,
      appliedContractVersion: json['applied_contract_version'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  bool get isPending => status == 'pending';
}
