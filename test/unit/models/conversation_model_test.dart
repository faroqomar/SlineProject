// Schema ref: conversations table — see Sline_everything/SUPABASE_SETUP.md
// Tests Conversation.fromJson, toJson, copyWith, and last_message parsing variants.

import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';

/// Builds a complete conversation JSON map with sensible defaults.
/// [overrides] are merged on top (use `null` value to remove a key via removeWhere).
Map<String, dynamic> _conversationJson({Map<String, dynamic>? overrides}) {
  final base = <String, dynamic>{
    'id': 'conv-1',
    'task_id': 'task-1',
    'user1_id': 'user-aaa',
    'user2_id': 'user-bbb',
    'created_at': '2026-03-15T08:00:00Z',
    'task_title': 'Fix my plumbing',
    'tasks': {'title': 'Nested task title', 'task_type': 'tender'},
    'user1_name': 'Alice',
    'user2_name': 'Bob',
    'last_message': {
      'content': 'See you tomorrow',
      'created_at': '2026-03-15T09:30:00Z',
      'sender_id': 'user-aaa',
      'seen_at': '2026-03-15T09:31:00Z',
    },
    'other_user_name': 'Bob',
    'other_user_avatar': 'avatars/bob.jpg',
    'other_user_typing': false,
    'presence_updated_at': '2026-03-15T09:32:00Z',
  };
  if (overrides != null) {
    base.addAll(overrides);
  }
  return base;
}

void main() {
  // ---------------------------------------------------------------------------
  // fromJson — basic fields
  // ---------------------------------------------------------------------------
  group('Conversation.fromJson basic fields', () {
    test('parses all scalar fields from valid JSON', () {
      final c = Conversation.fromJson(_conversationJson());

      expect(c.id, 'conv-1');
      expect(c.taskId, 'task-1');
      expect(c.user1Id, 'user-aaa');
      expect(c.user2Id, 'user-bbb');
      expect(c.createdAt, DateTime.utc(2026, 3, 15, 8));
      expect(c.user1Name, 'Alice');
      expect(c.user2Name, 'Bob');
      expect(c.otherUserName, 'Bob');
      expect(c.otherUserAvatar, 'avatars/bob.jpg');
      expect(c.otherUserTyping, false);
      expect(c.presenceUpdatedAt, DateTime.utc(2026, 3, 15, 9, 32));
    });

    test('createdAt is parsed as UTC', () {
      final c = Conversation.fromJson(_conversationJson());
      expect(c.createdAt.isUtc, isTrue);
    });

    test('nullable fields default to null when missing', () {
      final json = <String, dynamic>{
        'id': 'conv-2',
        'user1_id': 'u1',
        'user2_id': 'u2',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final c = Conversation.fromJson(json);

      expect(c.taskId, isNull);
      expect(c.taskTitle, isNull);
      expect(c.taskType, isNull);
      expect(c.user1Name, isNull);
      expect(c.user2Name, isNull);
      expect(c.otherUserName, isNull);
      expect(c.otherUserAvatar, isNull);
      expect(c.lastMessage, isNull);
      expect(c.lastMessageTime, isNull);
      expect(c.lastMessageSenderId, isNull);
      expect(c.lastMessageSeenAt, isNull);
      expect(c.presenceUpdatedAt, isNull);
    });

    test('otherUserTyping defaults to false when key is absent', () {
      final json = <String, dynamic>{
        'id': 'conv-3',
        'user1_id': 'u1',
        'user2_id': 'u2',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final c = Conversation.fromJson(json);
      expect(c.otherUserTyping, false);
    });

    test('otherUserTyping parses true', () {
      final c = Conversation.fromJson(
        _conversationJson(overrides: {'other_user_typing': true}),
      );
      expect(c.otherUserTyping, true);
    });

    test('presenceUpdatedAt handles null gracefully', () {
      final c = Conversation.fromJson(
        _conversationJson(overrides: {'presence_updated_at': null}),
      );
      expect(c.presenceUpdatedAt, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — taskTitle / taskType fallback logic
  // ---------------------------------------------------------------------------
  group('Conversation.fromJson taskTitle fallback', () {
    test('prefers flat task_title over nested tasks.title', () {
      final c = Conversation.fromJson(_conversationJson());
      // Base fixture has both task_title and tasks.title — flat wins.
      expect(c.taskTitle, 'Fix my plumbing');
    });

    test('falls back to tasks.title when task_title is null', () {
      final c = Conversation.fromJson(
        _conversationJson(overrides: {'task_title': null}),
      );
      expect(c.taskTitle, 'Nested task title');
    });

    test('taskType comes from tasks.task_type', () {
      final c = Conversation.fromJson(_conversationJson());
      expect(c.taskType, 'tender');
    });

    test('taskType is null when tasks map is absent', () {
      final json = _conversationJson(overrides: {'tasks': null});
      final c = Conversation.fromJson(json);
      expect(c.taskType, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — last_message parsing (4 variants)
  // ---------------------------------------------------------------------------
  group('Conversation.fromJson last_message parsing', () {
    test(
      'last_message as Map extracts content/created_at/sender_id/seen_at',
      () {
        final c = Conversation.fromJson(_conversationJson());

        expect(c.lastMessage, 'See you tomorrow');
        expect(c.lastMessageTime, DateTime.utc(2026, 3, 15, 9, 30));
        expect(c.lastMessageSenderId, 'user-aaa');
        expect(c.lastMessageSeenAt, DateTime.utc(2026, 3, 15, 9, 31));
      },
    );

    test('last_message as List takes the last element', () {
      final c = Conversation.fromJson(
        _conversationJson(
          overrides: {
            'last_message': [
              {
                'content': 'First message',
                'created_at': '2026-03-15T08:00:00Z',
                'sender_id': 'user-bbb',
                'seen_at': null,
              },
              {
                'content': 'Most recent',
                'created_at': '2026-03-15T09:00:00Z',
                'sender_id': 'user-aaa',
                'seen_at': '2026-03-15T09:05:00Z',
              },
            ],
          },
        ),
      );

      expect(c.lastMessage, 'Most recent');
      expect(c.lastMessageTime, DateTime.utc(2026, 3, 15, 9));
      expect(c.lastMessageSenderId, 'user-aaa');
      expect(c.lastMessageSeenAt, DateTime.utc(2026, 3, 15, 9, 5));
    });

    test('last_message as empty List yields all null', () {
      final c = Conversation.fromJson(
        _conversationJson(overrides: {'last_message': <dynamic>[]}),
      );

      expect(c.lastMessage, isNull);
      expect(c.lastMessageTime, isNull);
      expect(c.lastMessageSenderId, isNull);
      expect(c.lastMessageSeenAt, isNull);
    });

    test('last_message as null yields all null', () {
      final c = Conversation.fromJson(
        _conversationJson(overrides: {'last_message': null}),
      );

      expect(c.lastMessage, isNull);
      expect(c.lastMessageTime, isNull);
      expect(c.lastMessageSenderId, isNull);
      expect(c.lastMessageSeenAt, isNull);
    });

    test('last_message Map with null created_at and seen_at', () {
      final c = Conversation.fromJson(
        _conversationJson(
          overrides: {
            'last_message': {
              'content': 'hi',
              'created_at': null,
              'sender_id': 'user-bbb',
              'seen_at': null,
            },
          },
        ),
      );

      expect(c.lastMessage, 'hi');
      expect(c.lastMessageTime, isNull);
      expect(c.lastMessageSenderId, 'user-bbb');
      expect(c.lastMessageSeenAt, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------
  group('Conversation.copyWith', () {
    test('preserves otherUserTyping and presenceUpdatedAt by default', () {
      final original = Conversation.fromJson(
        _conversationJson(
          overrides: {
            'other_user_typing': true,
            'presence_updated_at': '2026-03-15T10:00:00Z',
          },
        ),
      );

      final updated = original.copyWith(lastMessage: 'New msg');

      expect(updated.lastMessage, 'New msg');
      expect(updated.otherUserTyping, true);
      expect(updated.presenceUpdatedAt, DateTime.utc(2026, 3, 15, 10));
      // Other fields preserved.
      expect(updated.id, original.id);
      expect(updated.taskTitle, original.taskTitle);
      expect(updated.taskType, original.taskType);
    });

    test('can override otherUserTyping and presenceUpdatedAt', () {
      final original = Conversation.fromJson(_conversationJson());

      final newPresence = DateTime.utc(2026, 4, 1, 12);
      final updated = original.copyWith(
        otherUserTyping: true,
        presenceUpdatedAt: newPresence,
      );

      expect(updated.otherUserTyping, true);
      expect(updated.presenceUpdatedAt, newPresence);
    });

    test('copyWith with lastMessageTime and lastMessageSeenAt', () {
      final original = Conversation.fromJson(_conversationJson());
      final newTime = DateTime.utc(2026, 4);
      final newSeen = DateTime.utc(2026, 4, 1, 0, 1);

      final updated = original.copyWith(
        lastMessageTime: newTime,
        lastMessageSenderId: 'user-bbb',
        lastMessageSeenAt: newSeen,
      );

      expect(updated.lastMessageTime, newTime);
      expect(updated.lastMessageSenderId, 'user-bbb');
      expect(updated.lastMessageSeenAt, newSeen);
    });
  });

  // ---------------------------------------------------------------------------
  // toJson round-trip
  // ---------------------------------------------------------------------------
  group('Conversation.toJson', () {
    test('produces correct snake_case structure', () {
      final c = Conversation.fromJson(_conversationJson());
      final json = c.toJson();

      expect(json['id'], 'conv-1');
      expect(json['task_id'], 'task-1');
      expect(json['user1_id'], 'user-aaa');
      expect(json['user2_id'], 'user-bbb');
      expect(json['created_at'], '2026-03-15T08:00:00.000Z');
      expect(json['task_title'], 'Fix my plumbing');
      expect(json['task_type'], 'tender');
      expect(json['user1_name'], 'Alice');
      expect(json['user2_name'], 'Bob');
      expect(json['last_message'], 'See you tomorrow');
      expect(json['last_message_time'], '2026-03-15T09:30:00.000Z');
      expect(json['other_user_name'], 'Bob');
      expect(json['other_user_avatar'], 'avatars/bob.jpg');
      expect(json['other_user_typing'], false);
      expect(json['presence_updated_at'], '2026-03-15T09:32:00.000Z');
    });

    test('toJson nullable DateTime fields produce null when absent', () {
      final json = <String, dynamic>{
        'id': 'conv-min',
        'user1_id': 'u1',
        'user2_id': 'u2',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final c = Conversation.fromJson(json);
      final out = c.toJson();

      expect(out['last_message_time'], isNull);
      expect(out['presence_updated_at'], isNull);
    });
  });
}
