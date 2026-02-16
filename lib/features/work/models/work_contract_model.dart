/// Model for `work_contracts` table.
class WorkContractModel {
  final String id;
  final String relatedEntityType;
  final String relatedEntityId;
  final int version;
  final Map<String, dynamic> snapshot;
  final String contractHash;
  final DateTime createdAt;

  const WorkContractModel({
    required this.id,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.version,
    required this.snapshot,
    required this.contractHash,
    required this.createdAt,
  });

  factory WorkContractModel.fromJson(Map<String, dynamic> json) {
    return WorkContractModel(
      id: json['id'] as String,
      relatedEntityType: json['related_entity_type'] as String,
      relatedEntityId: json['related_entity_id'] as String,
      version: json['version'] as int,
      snapshot: json['snapshot'] as Map<String, dynamic>,
      contractHash: json['contract_hash'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
