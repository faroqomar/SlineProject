/// Message domain model with optional attachment fields.
class Message {
  /// Unique id of the message
  final String id;
  /// Conversation this message belongs to
  final String conversationId;
  /// Sender user id
  final String senderId;
  /// Receiver user id
  final String receiverId;
  /// Text content (may be empty when sending attachment-only)
  final String content;
  /// Server timestamp when the message is created
  final DateTime createdAt;

  /// Optional attachment storage path (private bucket path)
  final String? attachmentUrl;
  /// Attachment type: 'image' | 'file'
  final String? attachmentType;
  /// Original filename (if any)
  final String? attachmentName;
  /// Size in bytes (if any)
  final int? attachmentSize;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
    this.attachmentSize,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: (json['content'] ?? '') as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      attachmentUrl: json['attachment_url'] as String?,
      attachmentType: json['attachment_type'] as String?,
      attachmentName: json['attachment_name'] as String?,
      attachmentSize: json['attachment_size'] == null
          ? null
          : (json['attachment_size'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
    if (attachmentUrl != null) map['attachment_url'] = attachmentUrl;
    if (attachmentType != null) map['attachment_type'] = attachmentType;
    if (attachmentName != null) map['attachment_name'] = attachmentName;
    if (attachmentSize != null) map['attachment_size'] = attachmentSize;
    return map;
  }
}