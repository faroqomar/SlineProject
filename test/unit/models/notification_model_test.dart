import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';

void main() {
  group('NotificationItem', () {
    test('fromJson parses message, is_read, metadata', () {
      final json = {
        'id': 'n-1',
        'user_id': 'u-1',
        'title': 'Test',
        'message': 'Body text',
        'type': 'message',
        'related_entity_id': 'e-1',
        'related_entity_type': 'conversation',
        'is_read': false,
        'created_at': '2026-03-01T12:00:00Z',
        'metadata': {'key': 'value'},
      };
      final item = NotificationItem.fromJson(json);
      expect(item.id, 'n-1');
      expect(item.message, 'Body text');
      expect(item.isRead, false);
      expect(item.metadata, {'key': 'value'});
      expect(item.type, NotificationType.message);
    });

    test('fromJson defaults is_read to false when null', () {
      final json = {
        'id': 'n-2',
        'user_id': 'u-2',
        'title': 'T',
        'message': 'M',
        'type': 'system',
        'created_at': '2026-03-01T12:00:00Z',
      };
      final item = NotificationItem.fromJson(json);
      expect(item.isRead, false);
      expect(item.metadata, {});
    });

    test('fromJson maps unknown type to system', () {
      final json = {
        'id': 'n-3',
        'user_id': 'u-3',
        'title': 'T',
        'message': 'M',
        'type': 'offer_awarded',
        'created_at': '2026-03-01T12:00:00Z',
      };
      final item = NotificationItem.fromJson(json);
      expect(item.type, NotificationType.system);
    });

    test('fromJson uses empty string when title or message is null', () {
      final json = {
        'id': 'n-null',
        'user_id': 'u-null',
        'title': null,
        'message': null,
        'type': 'system',
        'created_at': '2026-03-01T12:00:00Z',
      };
      final item = NotificationItem.fromJson(Map<String, dynamic>.from(json));
      expect(item.title, '');
      expect(item.message, '');
    });

    test('fromJson parses metadata from Map (dynamic keys) safely', () {
      final json = {
        'id': 'n-m',
        'user_id': 'u-m',
        'title': 'T',
        'message': 'M',
        'type': 'task',
        'created_at': '2026-03-01T12:00:00Z',
        'metadata': {'a': 1, 'b': 'x'},
      };
      final item = NotificationItem.fromJson(Map<String, dynamic>.from(json));
      expect(item.metadata, {'a': 1, 'b': 'x'});
    });

    test('toJson round-trip', () {
      final json = Map<String, dynamic>.from({
        'id': 'n-4',
        'user_id': 'u-4',
        'title': 'Title',
        'message': 'Msg',
        'type': 'task',
        'related_entity_id': 'task-1',
        'related_entity_type': 'task',
        'is_read': true,
        'created_at': '2026-03-01T14:00:00Z',
        'metadata': <String, dynamic>{},
      });
      final item = NotificationItem.fromJson(json);
      final out = item.toJson();
      expect(out['message'], 'Msg');
      expect(out['is_read'], true);
      expect(out['type'], 'task');
      // Round-trip: fromJson expects Map<String, dynamic>
      final again = NotificationItem.fromJson(Map<String, dynamic>.from(out));
      expect(again.id, item.id);
      expect(again.message, item.message);
    });
  });
}
