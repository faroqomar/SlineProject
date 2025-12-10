/// Centralized logging utility for clean, filterable console output.
///
/// Why this exists:
/// 1. Single point of control for log formatting and verbosity
/// 2. Feature tags for easy filtering (e.g., [Auth], [Chat], [Tasks])
/// 3. Only logs in debug mode - safe for production
/// 4. Clean, minimal output that doesn't flood the console
///
/// Usage:
/// ```dart
/// AppLogger.i('User logged in', tag: 'Auth');
/// AppLogger.e('Failed to load', tag: 'Tasks', error: e);
/// AppLogger.api('GET /tasks', 200, tag: 'Tasks');
/// ```
///
/// Configure in main.dart:
/// ```dart
/// AppLogger.currentLevel = LogLevel.info;   // Normal (default)
/// AppLogger.currentLevel = LogLevel.debug;  // Verbose
/// AppLogger.currentLevel = LogLevel.error;  // Errors only
/// ```
library;

import 'package:flutter/foundation.dart';

/// Logging levels - higher index = more severe, fewer logs shown.
enum LogLevel { debug, info, warning, error }

/// Centralized logger for the app.
///
/// IMPORTANT: Always use this instead of `print()` or direct `Logger()` calls.
class AppLogger {
  /// Current log level (default: info). Set in main.dart.
  static LogLevel currentLevel = LogLevel.info;

  // ANSI color codes for terminal output
  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[36m';    // Debug
  static const String _green = '\x1B[32m';   // Info
  static const String _yellow = '\x1B[33m';  // Warning
  static const String _red = '\x1B[31m';     // Error
  static const String _gray = '\x1B[90m';    // Timestamp/Tag
  static const String _blue = '\x1B[34m';    // API

  /// Format: "HH:mm:ss" for clean timestamps
  static String _timestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  /// Core log method - all others delegate here.
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    if (level.index < currentLevel.index) return;

    final emoji = switch (level) {
      LogLevel.debug => '🔍',
      LogLevel.info => '✅',
      LogLevel.warning => '⚠️',
      LogLevel.error => '❌',
    };

    final color = switch (level) {
      LogLevel.debug => _cyan,
      LogLevel.info => _green,
      LogLevel.warning => _yellow,
      LogLevel.error => _red,
    };

    final tagStr = tag != null ? '$_gray[$tag]$_reset ' : '';
    final timeStr = '$_gray${_timestamp()}$_reset';

    // Clean single-line format: "HH:mm:ss [Tag] ✅ Message"
    debugPrint('$timeStr $tagStr$color$emoji $message$_reset');

    // For errors, print error and first few stack lines
    if (error != null) {
      debugPrint('$_red   └─ $error$_reset');
    }
    if (stackTrace != null && level == LogLevel.error) {
      final lines = stackTrace.toString().split('\n').take(3);
      for (final line in lines) {
        debugPrint('$_gray      $line$_reset');
      }
    }
  }

  /// Debug: Verbose info for development only.
  static void d(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// Info: General app flow, successful operations.
  static void i(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// Warning: Potential issues, recoverable errors.
  static void w(String message, {String? tag, dynamic error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  /// Error: Critical failures that need attention.
  static void e(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// API: Log API calls with status codes.
  /// Usage: AppLogger.api('GET /tasks', 200, tag: 'Tasks');
  static void api(String endpoint, int? statusCode, {String? tag, Duration? duration}) {
    if (!kDebugMode || currentLevel.index > LogLevel.info.index) return;

    final status = statusCode ?? 0;
    final color = status >= 200 && status < 300 ? _green : _red;
    final emoji = status >= 200 && status < 300 ? '🌐' : '🚫';
    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    final tagStr = tag != null ? '$_gray[$tag]$_reset ' : '';
    final timeStr = '$_gray${_timestamp()}$_reset';

    debugPrint('$timeStr $tagStr$_blue$emoji$_reset $endpoint $color$status$_reset$durationStr');
  }

  /// State: Log state changes in ViewModels.
  /// Usage: AppLogger.state('isLoading', true, tag: 'Auth');
  static void state(String field, dynamic value, {String? tag}) {
    if (!kDebugMode || currentLevel != LogLevel.debug) return;

    final tagStr = tag != null ? '$_gray[$tag]$_reset ' : '';
    final timeStr = '$_gray${_timestamp()}$_reset';

    debugPrint('$timeStr $tagStr$_cyan📊 $field = $value$_reset');
  }
}