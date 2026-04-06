import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/chat/models/message_model.dart';

Map<String, dynamic> _messageJson({Map<String, dynamic>? overrides}) {
  final base = <String, dynamic>{
    'id': 'msg-1',
    'conversation_id': 'conv-1',
    'sender_id': 'user-1',
    'receiver_id': 'user-2',
    'content': 'Hello',
    'created_at': '2026-02-24T10:00:00Z',
  };
  if (overrides != null) {
    base.addAll(overrides);
  }
  return base;
}

void main() {
  group('Message model T28-T30', () {
    test('T28 Message.fromJson defaults missing message_type to text', () {
      final message = Message.fromJson(_messageJson());

      expect(message.messageType, MessageType.text);
      expect(message.payload, isEmpty);
    });

    test('T29 Message.fromJson parses attachments and receipts', () {
      const deliveredIso = '2026-02-24T10:05:00Z';
      const seenIso = '2026-02-24T10:06:30Z';
      final message = Message.fromJson(
        _messageJson(
          overrides: {
            'message_type': 'text',
            'attachment_url': 'chat/attachments/file.png',
            'attachment_type': 'image',
            'attachment_name': 'file.png',
            'attachment_size': 2048,
            'delivered_at': deliveredIso,
            'seen_at': seenIso,
          },
        ),
      );

      expect(message.attachmentUrl, 'chat/attachments/file.png');
      expect(message.attachmentType, 'image');
      expect(message.attachmentName, 'file.png');
      expect(message.attachmentSize, 2048);
      expect(message.deliveredAt, DateTime.parse(deliveredIso));
      expect(message.seenAt, DateTime.parse(seenIso));
    });

    test(
      'T30 messageTypeFromString unknown value returns MessageType.text',
      () {
        // Locks the default branch for forward compatibility with new types.
        final type = messageTypeFromString('futureExperimentalType');

        expect(type, MessageType.text);
      },
    );
  });

  group('Message model extended coverage', () {
    test('All attachment fields null — no crash, model parses fine', () {
      final message = Message.fromJson(
        _messageJson(
          overrides: {
            'attachment_url': null,
            'attachment_type': null,
            'attachment_name': null,
            'attachment_size': null,
            'delivered_at': null,
            'seen_at': null,
          },
        ),
      );

      expect(message.attachmentUrl, isNull);
      expect(message.attachmentType, isNull);
      expect(message.attachmentName, isNull);
      expect(message.attachmentSize, isNull);
      expect(message.deliveredAt, isNull);
      expect(message.seenAt, isNull);
      expect(message.id, 'msg-1');
      expect(message.content, 'Hello');
    });

    test('toJson excludes null attachment fields from output', () {
      final message = Message.fromJson(_messageJson());
      final json = message.toJson();

      expect(json.containsKey('attachment_url'), isFalse);
      expect(json.containsKey('attachment_type'), isFalse);
      expect(json.containsKey('attachment_name'), isFalse);
      expect(json.containsKey('attachment_size'), isFalse);
      expect(json.containsKey('delivered_at'), isFalse);
      expect(json.containsKey('seen_at'), isFalse);
      // Core fields must still be present
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('conversation_id'), isTrue);
      expect(json.containsKey('sender_id'), isTrue);
      expect(json.containsKey('receiver_id'), isTrue);
      expect(json.containsKey('content'), isTrue);
      expect(json.containsKey('message_type'), isTrue);
    });

    test('attachmentSize type coercion from num to int', () {
      // JSON number could arrive as double from some backends
      final message = Message.fromJson(
        _messageJson(
          overrides: {
            'attachment_size': 4096.0, // double, not int
            'attachment_url': 'path/to/file',
          },
        ),
      );

      expect(message.attachmentSize, isA<int>());
      expect(message.attachmentSize, 4096);
    });

    test('Round-trip (toJson -> fromJson) preserves all fields', () {
      final original = Message.fromJson(
        _messageJson(
          overrides: {
            'message_type': 'offer',
            'payload': <String, dynamic>{'price': 500},
            'attachment_url': 'chat/file.pdf',
            'attachment_type': 'file',
            'attachment_name': 'invoice.pdf',
            'attachment_size': 8192,
            'delivered_at': '2026-03-01T14:00:00.000Z',
            'seen_at': '2026-03-01T14:05:00.000Z',
          },
        ),
      );

      final json = original.toJson();
      final restored = Message.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.conversationId, original.conversationId);
      expect(restored.senderId, original.senderId);
      expect(restored.receiverId, original.receiverId);
      expect(restored.content, original.content);
      expect(restored.createdAt, original.createdAt);
      expect(restored.messageType, original.messageType);
      expect(restored.payload, original.payload);
      expect(restored.attachmentUrl, original.attachmentUrl);
      expect(restored.attachmentType, original.attachmentType);
      expect(restored.attachmentName, original.attachmentName);
      expect(restored.attachmentSize, original.attachmentSize);
      expect(restored.deliveredAt, original.deliveredAt);
      expect(restored.seenAt, original.seenAt);
    });

    test(
      'Each MessageType enum value round-trips via messageTypeToString/messageTypeFromString',
      () {
        for (final type in MessageType.values) {
          final wireString = messageTypeToString(type);
          final parsed = messageTypeFromString(wireString);
          expect(
            parsed,
            type,
            reason: '${type.name} should round-trip through "$wireString"',
          );
        }
      },
    );
  });
}
