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
}
