/// Represents a log entry in the Unified Management System.
///
/// Can be a manual note, a private note, or a system event (e.g. extension request).
class WorkLog {
  final String id;
  final String authorId;
  final String relatedEntityId;
  final String relatedEntityType; // 'task' or 'booking'
  final String content;
  final bool isPrivate;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  // Joined Profile Data
  final String? authorName;
  final String? authorAvatar;

  const WorkLog({
    required this.id,
    required this.authorId,
    required this.relatedEntityId,
    required this.relatedEntityType,
    required this.content,
    this.isPrivate = false,
    this.metadata = const {},
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
  });

  factory WorkLog.fromJson(Map<String, dynamic> json) {
    // Handle JOINed profile data
    // Supabase returns relations as nested objects
    // We expect: .select('*, profiles!work_logs_author_id_fkey(...)')
    // The key might be 'profiles' or whatever alias we give it.
    final profile = json['profiles'] as Map<String, dynamic>?;

    return WorkLog(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      relatedEntityId: json['related_entity_id'] as String,
      relatedEntityType: json['related_entity_type'] as String,
      content: json['content'] as String,
      isPrivate: json['is_private'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: profile?['full_name'] as String?,
      authorAvatar: profile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author_id': authorId,
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
      'content': content,
      'is_private': isPrivate,
      'metadata': metadata,
      // id and created_at are usually server-generated
    };
  }

  /// Helper to check if this is a system event
  bool get isSystemEvent => metadata.containsKey('type');

  /// Helper to get event type
  String? get eventType => metadata['type'] as String?;
}
