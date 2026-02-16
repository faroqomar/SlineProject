/// Model for `extension_requests` table.
class ExtensionRequestModel {
  final String id;
  final String relatedEntityType;
  final String relatedEntityId;
  final String requesterId;
  final DateTime newDeadline;
  final String? reason;
  final String status; // 'pending', 'accepted', 'rejected', 'cancelled'
  final DateTime createdAt;

  const ExtensionRequestModel({
    required this.id,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.requesterId,
    required this.newDeadline,
    this.reason,
    required this.status,
    required this.createdAt,
  });

  factory ExtensionRequestModel.fromJson(Map<String, dynamic> json) {
    return ExtensionRequestModel(
      id: json['id'] as String,
      relatedEntityType: json['related_entity_type'] as String,
      relatedEntityId: json['related_entity_id'] as String,
      requesterId: json['requester_id'] as String,
      newDeadline: DateTime.parse(json['new_deadline'] as String),
      reason: json['reason'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
}
