import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _service;

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;

  NotificationViewModel({NotificationService? service})
    : _service = service ?? NotificationService() {
    _init();
  }

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _init() {
    // Auto-load on init
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _isLoading = true;
    notifyListeners();

    _service.streamNotifications().listen(
      (items) {
        _notifications = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        AppLogger.e('Error streaming notifications', error: e);
        _error = 'Failed to load notifications';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    // We can't modify the item directly since it's immutable
    // But we can depend on the stream to update us shortly.
    // However, for immediate UI feedback, we often want an optimistic update.
    // For now, let's just trigger the service call and let the stream handle the update.

    try {
      await _service.markAsRead(id);
    } catch (e) {
      _error = 'Failed to update notification';
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
    } catch (e) {
      _error = 'Failed to mark all as read';
      notifyListeners();
    }
  }
}
