import 'package:flutter/foundation.dart';

enum NotificationType { offer, message, system, booking, task, payment, review }

@immutable
class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? relatedEntityId;
  final String? relatedEntityType;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedEntityId,
    this.relatedEntityType,
    required this.isRead,
    required this.createdAt,
    this.metadata = const {},
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      type: _parseType((json['type'] as String?) ?? 'system'),
      relatedEntityId: json['related_entity_id']?.toString(),
      relatedEntityType: json['related_entity_type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      metadata: _parseMetadata(json['metadata']),
    );
  }

  static Map<String, dynamic> _parseMetadata(dynamic value) {
    if (value == null) return const {};
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  static NotificationType _parseType(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NotificationType.system,
    );
  }
}
