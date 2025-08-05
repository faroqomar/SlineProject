import '../../../core/services/logger_service.dart';

/// Represents a conversation between two users about a specific task
class Conversation {
  final String id;
  final String taskId;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;

  // Extra fields for display
  final String? taskTitle;
  final String? user1Name;
  final String? user2Name;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  /// The display name of the other participant in the conversation
  final String? otherUserName;

  /// The avatar URL of the other participant
  final String? otherUserAvatar;

  Conversation({
    required this.id,
    required this.taskId,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    this.taskTitle,
    this.user1Name,
    this.user2Name,
    this.lastMessage,
    this.lastMessageTime,
    this.otherUserName,
    this.otherUserAvatar,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    String? lastMessage;
    DateTime? lastMessageTime;

    final rawLastMessage = json['last_message'];
    // Add debug printing to inspect the shape of last_message
    // ignore: avoid_print
    // Debug: Processing last message data
    AppLogger.d('🔎 last_message raw: $rawLastMessage');

    if (rawLastMessage is Map) {
      lastMessage = rawLastMessage['content'] as String?;
      if (rawLastMessage['created_at'] != null) {
        lastMessageTime = DateTime.tryParse(rawLastMessage['created_at'] as String);
      }
    } else if (rawLastMessage is List && rawLastMessage.isNotEmpty) {
      final msg = rawLastMessage.last;
      lastMessage = msg['content'] as String?;
      if (msg['created_at'] != null) {
        lastMessageTime = DateTime.tryParse(msg['created_at'] as String);
      }
    }

    AppLogger.d('👤 Parsed other user: ${json['other_user_name']} | avatar: ${json['other_user_avatar']}');

    return Conversation(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      taskTitle: json['task_title'] as String?,
      user1Name: json['user1_name'] as String?,
      user2Name: json['user2_name'] as String?,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      otherUserName: json['other_user_name'] as String?,
      otherUserAvatar: json['other_user_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'created_at': createdAt.toIso8601String(),
      'task_title': taskTitle,
      'user1_name': user1Name,
      'user2_name': user2Name,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'other_user_name': otherUserName,
      'other_user_avatar': otherUserAvatar,
    };
  }
}
