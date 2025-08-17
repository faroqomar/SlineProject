/// Message domain model with optional attachment fields and read receipts.
/// Why: attachments enable richer chat; read receipts enable UX states (sent/delivered/read).
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

  /// When the message was delivered to the receiver's device (nullable)
  /// Why: used for the double-grey ticks state in WhatsApp-like UX.
  final DateTime? deliveredAt;

  /// When the message was seen (read) by the receiver (nullable)
  /// Why: used for the double-blue ticks state in WhatsApp-like UX.
  final DateTime? seenAt;

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
    this.deliveredAt,
    this.seenAt,
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
      deliveredAt: json['delivered_at'] == null
          ? null
          : DateTime.parse(json['delivered_at'] as String),
      seenAt: json['seen_at'] == null
          ? null
          : DateTime.parse(json['seen_at'] as String),
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
    // Optional read-receipt timestamps
    if (deliveredAt != null) map['delivered_at'] = deliveredAt!.toIso8601String();
    if (seenAt != null) map['seen_at'] = seenAt!.toIso8601String();
    return map;
  }
}