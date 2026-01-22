class ActivityItem {
  final String id;
  final String actorId;
  final String actorRole;
  final String targetType; // 'booking', 'task', 'offer'
  final String targetId;
  final String eventType; // 'created', 'status_change', etc.
  final String description; // UI friendly text
  final DateTime createdAt;

  ActivityItem({
    required this.id,
    required this.actorId,
    required this.actorRole,
    required this.targetType,
    required this.targetId,
    required this.eventType,
    required this.description,
    required this.createdAt,
  });
}
