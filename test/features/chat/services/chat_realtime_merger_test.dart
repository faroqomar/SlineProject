import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/chat/models/message_model.dart';
import 'package:sline_app/features/chat/services/chat_realtime_merger.dart';

// ChatRealtimeMerger unit tests — Gate 0 (Plan: 08_chat-realtime-sync)

void main() {
  group('ChatRealtimeMerger', () {
    late List<Map<String, dynamic>> messageJson;

    setUp(() {
      messageJson = [
        <String, dynamic>{
          'id': 'msg-1',
          'conversation_id': 'convo-1',
          'sender_id': 'user-a',
          'receiver_id': 'user-b',
          'content': 'Hello',
          'created_at': '2026-03-07T10:00:00.000Z',
          'message_type': 'text',
          'payload': <String, dynamic>{},
        },
        <String, dynamic>{
          'id': 'msg-2',
          'conversation_id': 'convo-1',
          'sender_id': 'user-b',
          'receiver_id': 'user-a',
          'content': 'Hi',
          'created_at': '2026-03-07T10:01:00.000Z',
          'message_type': 'text',
          'payload': <String, dynamic>{},
        },
        <String, dynamic>{
          'id': 'msg-3',
          'conversation_id': 'convo-1',
          'sender_id': 'user-a',
          'receiver_id': 'user-b',
          'content': 'Updated with delivered',
          'created_at': '2026-03-07T10:02:00.000Z',
          'message_type': 'text',
          'payload': <String, dynamic>{},
          'delivered_at': '2026-03-07T10:02:05.000Z',
          'seen_at': null,
        },
      ];
    });

    test('merge empty existing with new rows returns sorted list', () {
      final result = ChatRealtimeMerger.merge(
        <Message>[],
        messageJson,
        Message.fromJson,
      );
      expect(result.length, 3);
      expect(result[0].id, 'msg-1');
      expect(result[1].id, 'msg-2');
      expect(result[2].id, 'msg-3');
      for (var i = 1; i < result.length; i++) {
        expect(result[i].createdAt.isAfter(result[i - 1].createdAt) || result[i].createdAt.isAtSameMomentAs(result[i - 1].createdAt), true);
      }
    });

    test('merge dedupes by id and new row wins', () {
      final existing = [
        Message.fromJson(messageJson[0]),
        Message.fromJson(messageJson[1]),
      ];
      expect(existing[0].deliveredAt, isNull);
      final updatedRow = Map<String, dynamic>.from(messageJson[0])
        ..['delivered_at'] = '2026-03-07T10:00:10.000Z';
      final newRows = <Map<String, dynamic>>[updatedRow, messageJson[2]];
      final result = ChatRealtimeMerger.merge(
        existing,
        newRows,
        Message.fromJson,
      );
      expect(result.length, 3);
      final m1 = result.firstWhere((m) => m.id == 'msg-1');
      expect(m1.deliveredAt, isNotNull);
    });

    test('merge keeps order by created_at', () {
      final reversed = messageJson.reversed.map((e) => Map<String, dynamic>.from(e)).toList();
      final result = ChatRealtimeMerger.merge(
        <Message>[],
        reversed,
        Message.fromJson,
      );
      expect(result[0].id, 'msg-1');
      expect(result[1].id, 'msg-2');
      expect(result[2].id, 'msg-3');
    });

    test('merge skips unparseable row and keeps rest', () {
      final withBad = <Map<String, dynamic>>[
        Map<String, dynamic>.from(messageJson[0]),
        <String, dynamic>{'id': 'bad', 'invalid': true},
        Map<String, dynamic>.from(messageJson[1]),
      ];
      final result = ChatRealtimeMerger.merge(
        <Message>[],
        withBad,
        Message.fromJson,
      );
      expect(result.length, 2);
    });
  });
}
