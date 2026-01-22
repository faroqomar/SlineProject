import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<NotificationItem>> getNotifications({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => NotificationItem.fromJson(e))
          .toList();
    } catch (e, stack) {
      AppLogger.e('Failed to fetch notifications', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Stream<List<NotificationItem>> streamNotifications() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .map(
          (response) =>
              response.map((e) => NotificationItem.fromJson(e)).toList(),
        );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e, stack) {
      AppLogger.e(
        'Failed to mark notification as read',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e, stack) {
      AppLogger.e('Failed to mark all as read', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedEntityId,
    String? relatedEntityType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'related_entity_id': relatedEntityId,
        'related_entity_type': relatedEntityType,
        'metadata': metadata ?? {},
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e, stack) {
      AppLogger.e('Failed to create notification', error: e, stackTrace: stack);
      // Don't rethrow to avoid blocking the main action (e.g. sending message)
    }
  }

  /// Creates a new notification or updates an existing unread one from the same entity.
  /// Used to prevent spamming the user with multiple notifications for the same chat.
  Future<void> createOrUpdateNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedEntityId,
    String? relatedEntityType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 1. Check for existing UNREAD notification of same type/entity
      // This "groups" messages so you only see the latest one
      final existing = await _supabase
          .from('notifications')
          .select('id, metadata')
          .eq('user_id', userId)
          .eq('type', type.name)
          .eq('is_read', false)
          .eq('related_entity_id', relatedEntityId ?? '')
          .maybeSingle();

      if (existing != null) {
        final id = existing['id'];
        final oldMeta = existing['metadata'] as Map<String, dynamic>? ?? {};
        final count = (oldMeta['count'] as int? ?? 1) + 1;
        final newMeta = {...oldMeta, 'count': count, ...(metadata ?? {})};

        await _supabase
            .from('notifications')
            .update({
              'title':
                  title, // Update title (e.g. "5 new messages") if we wanted, or keep latest
              'message': message, // Show latest message preview
              'created_at': DateTime.now()
                  .toUtc()
                  .toIso8601String(), // Bump to top
              'metadata': newMeta,
            })
            .eq('id', id);
      } else {
        // 2. Create new if none exists
        await createNotification(
          userId: userId,
          title: title,
          message: message,
          type: type,
          relatedEntityId: relatedEntityId,
          relatedEntityType: relatedEntityType,
          metadata: metadata,
        );
      }
    } catch (e, stack) {
      AppLogger.e(
        'Failed to create/update notification',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
