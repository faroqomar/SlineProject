/// Award Expiration Monitor - Countdown timer for unpaid awarded offers
///
/// This ViewModel provides a live countdown for offers that have been accepted
/// but not yet paid. It emits updates every minute so the UI can display
/// remaining time and trigger actions when the deadline approaches.
///
/// Features:
/// - Live countdown (Xh Ym format)
/// - Color-coded urgency states (green → orange → red)
/// - Automatic disposal to prevent memory leaks
/// - Graceful handling of widget disposal
///
/// Usage:
/// ```dart
/// final monitor = AwardExpirationMonitor();
/// monitor.startMonitoring(deadline);
///
/// // In widget:
/// Consumer<AwardExpirationMonitor>(
///   builder: (context, monitor, _) => Text(monitor.countdownText ?? ''),
/// )
///
/// // In dispose:
/// monitor.dispose();
/// ```
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';

/// Log tag for the monitor
const String _logTag = 'AwardExpiration';

/// Urgency levels for the countdown display
enum UrgencyLevel {
  /// More than 24 hours remaining - calm state
  relaxed,

  /// Less than 24 hours but more than 6 hours - getting urgent
  urgent,

  /// Less than 6 hours remaining - critical
  critical,

  /// Expired
  expired,
}

/// ViewModel that monitors the expiration time of an awarded offer.
///
/// Emits notifications every minute so the UI can update countdown displays.
/// Properly handles disposal to prevent timer leaks.
class AwardExpirationMonitor extends ChangeNotifier {
  Timer? _timer;
  bool _disposed = false;
  DateTime? _paymentDeadline;

  /// Whether the monitor has been disposed.
  bool get isDisposed => _disposed;

  /// The current payment deadline being monitored.
  DateTime? get paymentDeadline => _paymentDeadline;

  /// Starts monitoring the given payment deadline.
  ///
  /// Cancels any existing timer and starts a new one that fires every minute.
  void startMonitoring(DateTime deadline) {
    if (_disposed) {
      AppLogger.w('Attempted to start monitoring on disposed monitor', tag: _logTag);
      return;
    }

    _paymentDeadline = deadline;
    _cancelTimer();

    AppLogger.d('Started monitoring deadline: $deadline', tag: _logTag);

    // Notify immediately to show initial state
    _onTick();

    // Set up periodic timer (every 60 seconds)
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _onTick());
  }

  /// Stops monitoring and cancels the timer.
  void stopMonitoring() {
    _cancelTimer();
    _paymentDeadline = null;
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Cancels the internal timer without clearing state.
  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Handles timer tick - updates state and notifies listeners.
  void _onTick() {
    if (_disposed) {
      AppLogger.w('Timer tick on disposed monitor - ignoring', tag: _logTag);
      return;
    }

    // Notify listeners to trigger UI update
    notifyListeners();

    // Log state for debugging
    if (_paymentDeadline != null) {
      final remaining = _paymentDeadline!.difference(DateTime.now());
      AppLogger.d(
        'Countdown tick: ${remaining.inHours}h ${remaining.inMinutes % 60}m remaining',
        tag: _logTag,
      );
    }
  }

  /// The formatted countdown text (e.g., "47h 32m").
  ///
  /// Returns null if no deadline is set.
  String? get countdownText {
    if (_paymentDeadline == null) return null;

    final remaining = _paymentDeadline!.difference(DateTime.now());

    if (remaining.isNegative) {
      return 'Expired';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '< 1m';
    }
  }

  /// The current urgency level based on time remaining.
  ///
  /// Use this to determine badge color and urgency indicators.
  UrgencyLevel get urgencyLevel {
    if (_paymentDeadline == null) return UrgencyLevel.relaxed;

    final remaining = _paymentDeadline!.difference(DateTime.now());

    if (remaining.isNegative) {
      return UrgencyLevel.expired;
    }

    final hours = remaining.inHours;

    if (hours < 6) {
      return UrgencyLevel.critical;
    } else if (hours < 24) {
      return UrgencyLevel.urgent;
    } else {
      return UrgencyLevel.relaxed;
    }
  }

  /// Whether the offer has expired.
  bool get isExpired {
    if (_paymentDeadline == null) return false;
    return _paymentDeadline!.isBefore(DateTime.now());
  }

  /// Returns a color based on urgency level.
  ///
  /// These are semantic colors - actual color values should come from theme.
  String get urgencyColor {
    switch (urgencyLevel) {
      case UrgencyLevel.relaxed:
        return 'green';
      case UrgencyLevel.urgent:
        return 'orange';
      case UrgencyLevel.critical:
        return 'red';
      case UrgencyLevel.expired:
        return 'grey';
    }
  }

  /// Whether the countdown should pulse/animate.
  ///
  /// Returns true when less than 6 hours remain to draw attention.
  bool get shouldPulse {
    return urgencyLevel == UrgencyLevel.critical || urgencyLevel == UrgencyLevel.expired;
  }

  @override
  void dispose() {
    AppLogger.d('Disposing AwardExpirationMonitor', tag: _logTag);
    _disposed = true;
    _cancelTimer();
    _paymentDeadline = null;
    super.dispose();
  }
}
