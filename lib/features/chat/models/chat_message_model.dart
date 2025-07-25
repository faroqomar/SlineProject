/// Model representing a chat message
class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.timestamp,
    this.isRead = false,
  });

  /// Create ChatMessage from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      senderId: json['sender_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  /// Convert ChatMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender_id': senderId,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }

  /// Create a copy with updated fields
  ChatMessage copyWith({
    String? id,
    String? content,
    String? senderId,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
