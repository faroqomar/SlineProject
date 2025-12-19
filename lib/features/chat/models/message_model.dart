import 'package:sline_app/core/services/logger_service.dart';

/// Enum representing different types of messages.
/// Why: Distinguishes message content types for handling and UI rendering.
enum MessageType {
  text,
  offer,
  offerUpdate,
  offerAccepted,
  offerRejected,
  deliverySubmitted,
  endEarlyRequest,
  disputeReport,
}

MessageType messageTypeFromString(String type) {
  switch (type) {
    case 'offer':
      return MessageType.offer;
    case 'offerUpdate':
      return MessageType.offerUpdate;
    case 'offerAccepted':
      return MessageType.offerAccepted;
    case 'offerRejected':
      return MessageType.offerRejected;
    case 'deliverySubmitted':
      return MessageType.deliverySubmitted;
    case 'endEarlyRequest':
      return MessageType.endEarlyRequest;
    case 'disputeReport':
      return MessageType.disputeReport;
    case 'text':
    default:
      return MessageType.text;
  }
}

String messageTypeToString(MessageType type) {
  switch (type) {
    case MessageType.offer:
      return 'offer';
    case MessageType.offerUpdate:
      return 'offerUpdate';
    case MessageType.offerAccepted:
      return 'offerAccepted';
    case MessageType.offerRejected:
      return 'offerRejected';
    case MessageType.deliverySubmitted:
      return 'deliverySubmitted';
    case MessageType.endEarlyRequest:
      return 'endEarlyRequest';
    case MessageType.disputeReport:
      return 'disputeReport';
    case MessageType.text:
      return 'text';
  }
}

/// Message domain model with optional attachment fields and read receipts.
/// Why: attachments enable richer chat; read receipts enable UX states (sent/delivered/read).
/// Added messageType and payload to support various message semantics and additional data.
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

  /// Type of the message indicating its semantic meaning.
  /// Why: distinguishes different message categories beyond plain text.
  final MessageType messageType;

  /// Additional data associated with the message.
  /// Why: allows extensible payloads for complex message types.
  final Map<String, dynamic> payload;

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
    required this.messageType,
    required this.payload,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      final typeString = (json['message_type'] as String?) ?? 'text';
      final type = messageTypeFromString(typeString);
      final payloadJson = json['payload'] as Map<String, dynamic>? ?? {};

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
        messageType: type,
        payload: payloadJson,
      );
    } catch (e, st) {
      AppLogger.e(
        'Failed to parse Message',
        tag: 'Chat',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'message_type': messageTypeToString(messageType),
      'payload': payload,
    };
    if (attachmentUrl != null) map['attachment_url'] = attachmentUrl;
    if (attachmentType != null) map['attachment_type'] = attachmentType;
    if (attachmentName != null) map['attachment_name'] = attachmentName;
    if (attachmentSize != null) map['attachment_size'] = attachmentSize;
    // Optional read-receipt timestamps
    if (deliveredAt != null) {
      map['delivered_at'] = deliveredAt!.toIso8601String();
    }
    if (seenAt != null) map['seen_at'] = seenAt!.toIso8601String();
    return map;
  }
}
