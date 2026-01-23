import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'package:provider/provider.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _service;
  StreamSubscription<List<NotificationItem>>? _subscription;

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

    _subscription = _service.streamNotifications().listen(
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> handleNotificationTap(
    BuildContext context,
    NotificationItem item,
  ) async {
    // 1. Mark as read immediately
    markAsRead(item.id);

    // 2. Delegate to DeepLinkService
    final deepLinkService = context.read<DeepLinkService>();
    await deepLinkService.handleNotification(context, item);
  }

  Future<void> markAsRead(String id) async {
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
