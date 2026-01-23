class ActivityLog {
  final String id;
  final String userId;
  final String actorId;
  final String entityType; // 'task', 'booking'
  final String entityId;
  final String eventType; // 'created', 'status_change'
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime createdAt;

  // Joined Profile Data
  final String? actorName;
  final String? actorAvatar;

  const ActivityLog({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.entityType,
    required this.entityId,
    required this.eventType,
    this.metadata = const {},
    this.isRead = false,
    required this.createdAt,
    this.actorName,
    this.actorAvatar,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    return ActivityLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actorId: json['actor_id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      eventType: json['event_type'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      actorName: profile?['full_name'] as String?,
      actorAvatar: profile?['avatar_url'] as String?,
    );
  }

  /// Serialize to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'actor_id': actorId,
      'entity_type': entityType,
      'entity_id': entityId,
      'event_type': eventType,
      'metadata': metadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'profiles': actorName != null || actorAvatar != null
          ? {'full_name': actorName, 'avatar_url': actorAvatar}
          : null,
    };
  }
}
