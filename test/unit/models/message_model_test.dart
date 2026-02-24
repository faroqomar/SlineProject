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
}
