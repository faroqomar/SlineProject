import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// ViewModel for notification list and read state. Context-free; navigation is view-layer responsibility.
class NotificationViewModel extends ChangeNotifier {
  final NotificationService _service;
  StreamSubscription<List<NotificationItem>>? _subscription;
  StreamSubscription<AuthState>? _authSubscription;

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;

  /// [authStateChanges] optional for tests; if null uses Supabase.instance.client.auth.onAuthStateChange.
  NotificationViewModel({
    NotificationService? service,
    Stream<AuthState>? authStateChanges,
  }) : _service = service ?? NotificationService() {
    _init(authStateChanges);
  }

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _init(Stream<AuthState>? authStateChanges) {
    if (authStateChanges != null) {
      _authSubscription = authStateChanges.listen((data) {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn) {
          if (data.session?.user != null) {
            AppLogger.d(
              'NotificationViewModel: session ready, connecting stream',
              tag: 'Notifications',
            );
            _connect();
          }
        } else if (event == AuthChangeEvent.signedOut ||
            event == AuthChangeEvent.userDeleted) {
          AppLogger.d(
            'NotificationViewModel: signed out, disconnecting and clearing state',
            tag: 'Notifications',
          );
          _disconnect();
        }
      });
      return;
    }
    final stream = Supabase.instance.client.auth.onAuthStateChange;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _connect();
    } else {
      AppLogger.d(
        'NotificationViewModel: no session, stream not started',
        tag: 'Notifications',
      );
    }
    _authSubscription = stream.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        if (data.session?.user != null) {
          AppLogger.d(
            'NotificationViewModel: session ready, connecting stream',
            tag: 'Notifications',
          );
          _connect();
        }
      } else if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userDeleted) {
        AppLogger.d(
          'NotificationViewModel: signed out, disconnecting and clearing state',
          tag: 'Notifications',
        );
        _disconnect();
      }
    });
  }

  Future<void> _connect() async {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();
    AppLogger.d(
      'NotificationViewModel: foreground sync then stream',
      tag: 'Notifications',
    );

    // Plan 13_notification-routing: fetch unread first so badge is correct (avoid limit-50 truncation)
    try {
      final unread = await _service.getUnreadNotifications(limit: 50);
      if (unread.isNotEmpty) {
        _notifications = unread;
        AppLogger.d(
          'NotificationViewModel: initial unread=${unread.length}',
          tag: 'Notifications',
        );
        notifyListeners();
      }
    } catch (e) {
      AppLogger.w(
        'NotificationViewModel: initial unread fetch failed',
        error: e,
        tag: 'Notifications',
      );
    }

    _subscription = _service.streamNotifications().listen(
      (items) {
        _notifications = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        AppLogger.e(
          'Error streaming notifications',
          error: e,
          tag: 'Notifications',
        );
        _error = 'Failed to load notifications';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _notifications = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Clears error and reconnects the stream (e.g. after failure).
  void retry() {
    _error = null;
    try {
      if (Supabase.instance.client.auth.currentUser != null) {
        _connect();
      } else {
        notifyListeners();
      }
    } catch (_) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
      notifyListeners();
    } catch (e) {
      AppLogger.e(
        'Failed to update notification',
        error: e,
        tag: 'Notifications',
      );
      _error = 'Failed to update notification';
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      notifyListeners();
    } catch (e) {
      AppLogger.e('Failed to mark all as read', error: e, tag: 'Notifications');
      _error = 'Failed to mark all as read';
      notifyListeners();
    }
  }
}
