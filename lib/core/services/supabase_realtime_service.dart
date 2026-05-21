/// Supabase Realtime Service for managing bid status and task request updates.
///
/// Features:
/// - Manage Supabase realtime channel lifecycle
/// - Subscribe to table changes with filters and return Streams
/// - Handle connection errors gracefully
/// - Full logging via AppLogger
///
/// Note: Debouncing is handled at the ViewModel level via Debouncer class.
library;

import 'dart:async';

import 'package:sline_app/core/services/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages Supabase realtime subscriptions for bid and task request updates.
///
/// This service handles channel lifecycle, error recovery, and returns Streams
/// that can be listened to by ViewModels. It follows a singleton pattern but
/// remains dependency-injection friendly through the optional [client] parameter.
class SupabaseRealtimeService {
  static const String _logTag = 'Realtime';

  /// Internal singleton instance
  static SupabaseRealtimeService? _instance;

  /// The Supabase client instance
  final SupabaseClient _client;

  /// Active stream controllers mapped by channel name
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};

  /// Factory constructor for singleton access
  ///
  /// [client] is optional - if not provided, uses Supabase.instance.client
  factory SupabaseRealtimeService({SupabaseClient? client}) {
    final supabaseClient = client ?? Supabase.instance.client;
    _instance ??= SupabaseRealtimeService._internal(supabaseClient);
    return _instance!;
  }

  /// Private constructor
  SupabaseRealtimeService._internal(this._client) {
    AppLogger.i('SupabaseRealtimeService initialized', tag: _logTag);
  }

  /// Reset the singleton instance (useful for testing)
  static void reset() {
    _instance?.unsubscribeAll();
    _instance = null;
    AppLogger.d('SupabaseRealtimeService singleton reset', tag: _logTag);
  }

  /// Subscribe to task request updates for a specific task
  ///
  /// [taskId] The task ID to filter updates by
  /// [events] Optional list of events to listen for (default: ['UPDATE'])
  /// Returns a Stream of realtime update payloads
  Stream<Map<String, dynamic>> subscribeToTaskRequests(
    String taskId, {
    List<String>? events,
  }) {
    final channelName = 'task_requests:task:$taskId';
    final listenEvents = events ?? ['UPDATE'];

    AppLogger.i(
      'Subscribing to task requests',
      tag: _logTag,
      json: {'channel': channelName, 'taskId': taskId, 'events': listenEvents},
    );

    // Return existing stream if already subscribed
    if (_controllers.containsKey(channelName)) {
      AppLogger.w(
        'Channel already exists, returning existing stream',
        tag: _logTag,
        json: {'channel': channelName},
      );
      return _controllers[channelName]!.stream;
    }

    // Create broadcast stream controller
    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () {
        AppLogger.d(
          'Stream cancelled, cleaning up channel',
          tag: _logTag,
          json: {'channel': channelName},
        );
        unsubscribe(channelName);
      },
    );

    _controllers[channelName] = controller;

    // Create Supabase realtime stream
    // Note: Using the simple stream API which handles reconnection internally
    final stream = _client
        .from('task_requests')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId);

    // Subscribe to the stream
    final subscription = stream.listen(
      (rows) {
        AppLogger.d(
          'Realtime update received',
          tag: _logTag,
          json: {'channel': channelName, 'rowCount': rows.length},
        );

        // Emit each row change
        for (final row in rows) {
          if (!controller.isClosed) {
            controller.add({
              'eventType': 'UPDATE',
              'table': 'task_requests',
              'new': row,
              'old': null,
            });
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.e(
          'Realtime stream error',
          tag: _logTag,
          error: error,
          stackTrace: stackTrace,
        );
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      },
      onDone: () {
        AppLogger.d(
          'Realtime stream closed',
          tag: _logTag,
          json: {'channel': channelName},
        );
        if (!controller.isClosed) {
          unawaited(controller.close());
        }
      },
    );

    // Store subscription reference for cleanup
    controller.onCancel = () {
      unawaited(subscription.cancel());
      unsubscribe(channelName);
    };

    AppLogger.i(
      'Subscription initiated successfully',
      tag: _logTag,
      json: {'channel': channelName},
    );

    return controller.stream;
  }

  /// Subscribe to bid status updates for a specific bid
  ///
  /// [bidId] The bid/task_request ID to listen for updates
  /// Returns a Stream of realtime update payloads
  Stream<Map<String, dynamic>> subscribeToBidStatus(String bidId) {
    final channelName = 'task_requests:bid:$bidId';

    AppLogger.i(
      'Subscribing to bid status',
      tag: _logTag,
      json: {'channel': channelName, 'bidId': bidId},
    );

    // Return existing stream if already subscribed
    if (_controllers.containsKey(channelName)) {
      AppLogger.w(
        'Channel already exists, returning existing stream',
        tag: _logTag,
        json: {'channel': channelName},
      );
      return _controllers[channelName]!.stream;
    }

    // Create broadcast stream controller
    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () {
        AppLogger.d(
          'Stream cancelled, cleaning up channel',
          tag: _logTag,
          json: {'channel': channelName},
        );
        unsubscribe(channelName);
      },
    );

    _controllers[channelName] = controller;

    // Create Supabase realtime stream for specific bid
    final stream = _client
        .from('task_requests')
        .stream(primaryKey: ['id'])
        .eq('id', bidId);

    // Subscribe to the stream
    final subscription = stream.listen(
      (rows) {
        AppLogger.d(
          'Bid status update received',
          tag: _logTag,
          json: {'channel': channelName, 'rowCount': rows.length},
        );

        // Emit the row change
        for (final row in rows) {
          if (!controller.isClosed) {
            controller.add({
              'eventType': 'UPDATE',
              'table': 'task_requests',
              'new': row,
              'old': null,
            });
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.e(
          'Bid status stream error',
          tag: _logTag,
          error: error,
          stackTrace: stackTrace,
        );
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      },
      onDone: () {
        AppLogger.d(
          'Bid status stream closed',
          tag: _logTag,
          json: {'channel': channelName},
        );
        if (!controller.isClosed) {
          unawaited(controller.close());
        }
      },
    );

    // Store subscription reference for cleanup
    controller.onCancel = () {
      unawaited(subscription.cancel());
      unsubscribe(channelName);
    };

    AppLogger.i(
      'Bid status subscription initiated',
      tag: _logTag,
      json: {'channel': channelName},
    );

    return controller.stream;
  }

  /// Unsubscribe from a specific channel
  ///
  /// [channelName] The channel name to unsubscribe from
  void unsubscribe(String channelName) {
    AppLogger.i(
      'Unsubscribing from channel',
      tag: _logTag,
      json: {'channel': channelName},
    );

    _cleanupChannel(channelName);

    AppLogger.i(
      'Unsubscription complete',
      tag: _logTag,
      json: {'channel': channelName},
    );
  }

  /// Unsubscribe from all channels
  void unsubscribeAll() {
    AppLogger.i(
      'Unsubscribing from all channels',
      tag: _logTag,
      json: {'channelCount': _controllers.length},
    );

    // Copy keys to avoid concurrent modification
    List<String>.from(_controllers.keys).forEach(_cleanupChannel);

    // Clear all tracking maps
    _controllers.clear();

    AppLogger.i('All channels unsubscribed', tag: _logTag);
  }

  /// Clean up a specific channel
  void _cleanupChannel(String channelName) {
    // Close and remove stream controller
    final controller = _controllers[channelName];
    if (controller != null && !controller.isClosed) {
      unawaited(controller.close());
    }
    _controllers.remove(channelName);
  }

  /// Get the number of active channels
  int get activeChannelCount => _controllers.length;

  /// Get list of active channel names
  List<String> get activeChannels => List<String>.from(_controllers.keys);
}

/// Debouncer utility for throttling rapid events.
///
/// Used to prevent excessive reloads when multiple realtime events
/// are received in quick succession.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  /// Run the [action] after the debounce delay.
  /// If called again before the delay expires, the previous call is cancelled.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending debounced action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether there's a pending debounced action.
  bool get hasPending => _timer != null && _timer!.isActive;
}

typedef VoidCallback = void Function();
