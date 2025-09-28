
/// Domain model for an availability slot.
/// All timestamps are stored/handled in UTC.
class SlotModel {
  final String id;
  final String providerId;
  final DateTime startsAtUtc;
  final DateTime endsAtUtc;
  final bool isBlocked;
  final DateTime createdAtUtc;

  const SlotModel({
    required this.id,
    required this.providerId,
    required this.startsAtUtc,
    required this.endsAtUtc,
    required this.isBlocked,
    required this.createdAtUtc,
  });

  /// Factory from PostgREST JSON.
  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id'] as String,
      providerId: json['provider_id'] as String,
      startsAtUtc: DateTime.parse(json['starts_at'] as String).toUtc(),
      endsAtUtc: DateTime.parse(json['ends_at'] as String).toUtc(),
      isBlocked: (json['is_blocked'] as bool?) ?? false,
      createdAtUtc: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  /// Convert to JSON for inserts/updates (UTC ISO8601).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'starts_at': startsAtUtc.toUtc().toIso8601String(),
      'ends_at': endsAtUtc.toUtc().toIso8601String(),
      'is_blocked': isBlocked,
      'created_at': createdAtUtc.toUtc().toIso8601String(),
    };
  }

  SlotModel copyWith({
    String? id,
    String? providerId,
    DateTime? startsAtUtc,
    DateTime? endsAtUtc,
    bool? isBlocked,
    DateTime? createdAtUtc,
  }) {
    return SlotModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      startsAtUtc: startsAtUtc ?? this.startsAtUtc,
      endsAtUtc: endsAtUtc ?? this.endsAtUtc,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }
}
