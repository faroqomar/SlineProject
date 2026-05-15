import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';
import 'package:sline_app/features/notifications/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ViewModel for notification list and read state. Context-free; navigation is view-layer responsibility.
class NotificationViewModel extends ChangeNotifier {
  /// Creates the notification state holder and starts auth-aware streaming.
  ///
  /// [realtimeReconnectBaseDelay] is injectable so tests can exercise the
  /// reconnect path without waiting on production backoff timers.
  NotificationViewModel({
    NotificationService? service,
    Stream<AuthState>? authStateChanges,
    SupabaseClient? client,
    Duration realtimeReconnectBaseDelay = const Duration(seconds: 2),
  }) : _service = service ?? NotificationService(),
       _client = client ?? Supabase.instance.client,
       _realtimeReconnectBaseDelay = realtimeReconnectBaseDelay {
    _init(authStateChanges);
  }

  final NotificationService _service;
  final SupabaseClient _client;
  final Duration _realtimeReconnectBaseDelay;
  StreamSubscription<List<NotificationItem>>? _subscription;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _reconnectTimer;
  var _connectGeneration = 0;
  var _reconnectAttempt = 0;
  var _disposed = false;
  var _hasActiveSession = false;

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool _shouldDisconnectForAuthEvent(AuthChangeEvent event) {
    return event == AuthChangeEvent.signedOut || event.name == 'userDeleted';
  }

  void _init(Stream<AuthState>? authStateChanges) {
    if (authStateChanges != null) {
      _authSubscription = authStateChanges.listen((data) {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn) {
          if (data.session?.user != null) {
            _hasActiveSession = true;
            AppLogger.d(
              'NotificationViewModel: session ready, connecting stream',
              tag: 'Notifications',
            );
            unawaited(_connect());
          }
        } else if (_shouldDisconnectForAuthEvent(event)) {
          AppLogger.d(
            'NotificationViewModel: auth ended, disconnecting and clearing state',
            tag: 'Notifications',
          );
          _hasActiveSession = false;
          _disconnect();
        }
      });
      return;
    }
    final stream = _client.auth.onAuthStateChange;
    final user = _client.auth.currentUser;
    _hasActiveSession = user != null;
    if (user != null) {
      unawaited(_connect());
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
          _hasActiveSession = true;
          AppLogger.d(
            'NotificationViewModel: session ready, connecting stream',
            tag: 'Notifications',
          );
          unawaited(_connect());
        }
      } else if (_shouldDisconnectForAuthEvent(event)) {
        AppLogger.d(
          'NotificationViewModel: auth ended, disconnecting and clearing state',
          tag: 'Notifications',
        );
        _hasActiveSession = false;
        _disconnect();
      }
    });
  }

  Future<void> _connect() async {
    final generation = ++_connectGeneration;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final currentSubscription = _subscription;
    _subscription = null;
    await currentSubscription?.cancel();
    if (_disposed || generation != _connectGeneration) return;

    _isLoading = true;
    _error = null;
    _safeNotify();
    AppLogger.d(
      'NotificationViewModel: foreground sync then stream',
      tag: 'Notifications',
    );

    // Plan 13_notification-routing: fetch unread first so badge is correct (avoid limit-50 truncation)
    try {
      final unread = await _service.getUnreadNotifications();
      if (unread.isNotEmpty) {
        _notifications = unread;
        AppLogger.d(
          'NotificationViewModel: initial unread=${unread.length}',
          tag: 'Notifications',
        );
        _safeNotify();
      }
    } on Exception catch (e) {
      AppLogger.w(
        'NotificationViewModel: initial unread fetch failed',
        error: e,
        tag: 'Notifications',
      );
    }

    if (_disposed || generation != _connectGeneration) return;

    _subscription = _service.streamNotifications().listen(
      (items) {
        if (_disposed || generation != _connectGeneration) return;
        _notifications = items;
        _reconnectAttempt = 0;
        _error = null;
        _isLoading = false;
        _safeNotify();
      },
      onError: (Object e, StackTrace st) {
        _handleStreamError(e, st, generation);
      },
      onDone: () {
        if (_disposed || generation != _connectGeneration) return;
        AppLogger.w(
          'NotificationViewModel: realtime stream closed',
          tag: 'Notifications',
        );
        _isLoading = false;
        _safeNotify();
        _scheduleReconnect();
      },
    );
  }

  void _disconnect() {
    _connectGeneration++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _notifications = [];
    _error = null;
    _isLoading = false;
    _safeNotify();
  }

  /// Clears error and reconnects the stream (e.g. after failure).
  void retry() {
    _error = null;
    try {
      if (_client.auth.currentUser != null) {
        unawaited(_connect());
      } else {
        _safeNotify();
      }
    } on Object catch (_) {
      // Supabase can be uninitialized in tests; retry should still notify so
      // widgets leave the loading/error branch deterministically.
      _safeNotify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _connectGeneration++;
    _reconnectTimer?.cancel();
    unawaited(_authSubscription?.cancel());
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
      _safeNotify();
    } on Exception catch (e) {
      AppLogger.e(
        'Failed to update notification',
        error: e,
        tag: 'Notifications',
      );
      _error = 'Failed to update notification';
      _safeNotify();
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      _error = null;
      _safeNotify();
      return true;
    } on Exception catch (e) {
      AppLogger.e('Failed to mark all as read', error: e, tag: 'Notifications');
      _error = 'Failed to mark all as read';
      _safeNotify();
      return false;
    }
  }

  void _handleStreamError(Object error, StackTrace stackTrace, int generation) {
    if (_disposed || generation != _connectGeneration) return;

    final transient = _isTransientRealtimeError(error);
    if (transient) {
      AppLogger.w(
        'NotificationViewModel: realtime stream interrupted; reconnecting',
        error: error,
        tag: 'Notifications',
      );
      unawaited(_subscription?.cancel());
      _subscription = null;
      _error = null;
      _isLoading = false;
      _safeNotify();
      _scheduleReconnect();
      return;
    }

    AppLogger.e(
      'Error streaming notifications',
      error: error,
      stackTrace: stackTrace,
      tag: 'Notifications',
    );
    _error = 'Failed to load notifications';
    _isLoading = false;
    _safeNotify();
  }

  bool _isTransientRealtimeError(Object error) {
    if (error is! RealtimeSubscribeException) return false;
    final details = error.details;
    if (details is RealtimeCloseEvent) {
      return details.code == 1002 || details.code == 1006;
    }
    return error.status == RealtimeSubscribeStatus.timedOut;
  }

  void _scheduleReconnect() {
    if (_disposed || (_reconnectTimer?.isActive ?? false)) return;

    final delay = _nextReconnectDelay();
    AppLogger.d(
      'NotificationViewModel: scheduling realtime reconnect',
      tag: 'Notifications',
      json: <String, dynamic>{'delay_ms': delay.inMilliseconds},
    );
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_disposed) return;
      if (_hasActiveSession) {
        unawaited(_connect());
      }
    });
  }

  Duration _nextReconnectDelay() {
    final exponent = _reconnectAttempt.clamp(0, 4);
    final multiplier = 1 << exponent;
    _reconnectAttempt++;
    final delayMs = _realtimeReconnectBaseDelay.inMilliseconds * multiplier;
    return Duration(milliseconds: delayMs.clamp(0, 30000));
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }
}
