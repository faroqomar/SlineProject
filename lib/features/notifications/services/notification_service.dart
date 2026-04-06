import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Read/update-only notification service. All notification creation is server-side.
class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches unread notifications (e.g. for foreground sync before stream).
  /// Plan: 13_notification-routing — sync unread on foreground.
  Future<List<NotificationItem>> getUnreadNotifications({
    int limit = 50,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.d(
        'getUnreadNotifications: no session, returning empty',
        tag: 'Notifications',
      );
      return [];
    }
    try {
      AppLogger.d(
        'getUnreadNotifications: fetching up to $limit',
        tag: 'Notifications',
      );
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(limit);
      final list = (response as List)
          .map((e) => NotificationItem.fromJson(e))
          .toList();
      AppLogger.d(
        'getUnreadNotifications: got ${list.length} unread',
        tag: 'Notifications',
      );
      return list;
    } catch (e, stack) {
      AppLogger.e(
        'Failed to fetch unread notifications',
        error: e,
        stackTrace: stack,
        tag: 'Notifications',
      );
      rethrow;
    }
  }

  Future<List<NotificationItem>> getNotifications({int limit = 20}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.d(
        'getNotifications: no session, returning empty',
        tag: 'Notifications',
      );
      return [];
    }
    try {
      AppLogger.d('getNotifications: fetching', tag: 'Notifications');
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final list = (response as List)
          .map((e) => NotificationItem.fromJson(e))
          .toList();
      AppLogger.d('getNotifications: got ${list.length}', tag: 'Notifications');
      return list;
    } catch (e, stack) {
      AppLogger.e(
        'Failed to fetch notifications',
        error: e,
        stackTrace: stack,
        tag: 'Notifications',
      );
      rethrow;
    }
  }

  Stream<List<NotificationItem>> streamNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.d(
        'streamNotifications: no session, returning empty stream',
        tag: 'Notifications',
      );
      return Stream.value([]);
    }
    AppLogger.d(
      'streamNotifications: connecting for user',
      tag: 'Notifications',
    );
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((response) {
          final list = response.map(NotificationItem.fromJson).toList();
          AppLogger.d(
            'streamNotifications: received ${list.length}',
            tag: 'Notifications',
          );
          return list;
        });
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.d('markAsRead: no session, skipping', tag: 'Notifications');
      return;
    }
    try {
      AppLogger.d('markAsRead: $notificationId', tag: 'Notifications');
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.e(
        'Failed to mark notification as read',
        error: e,
        stackTrace: stack,
        tag: 'Notifications',
      );
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.d('markAllAsRead: no session, skipping', tag: 'Notifications');
      return;
    }
    try {
      AppLogger.d('markAllAsRead requested', tag: 'Notifications');
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e, stack) {
      AppLogger.e(
        'Failed to mark all as read',
        error: e,
        stackTrace: stack,
        tag: 'Notifications',
      );
      rethrow;
    }
  }
}
