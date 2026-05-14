/// Centralized logging utility for clean, filterable console output.
///
/// Features:
/// 1. JSON Pretty Printing & Token Masking
/// 2. Feature tags for easy filtering
/// 3. Clean emojis and time formatting
/// 4. No raw ANSI codes by default (to prevent console garbage)
library;

import 'dart:async';

import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:sline_app/core/services/crash_reporting_service.dart';

/// Logging levels - higher index = more severe.
enum LogLevel { debug, info, warning, error }

class AppLogger {
  /// Current log level (default: info)
  static LogLevel currentLevel = LogLevel.info;

  /// Enable if your terminal supports ANSI colors.
  /// Default false to ensure clean output on all platforms.
  static bool useColors = false;

  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[36m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _gray = '\x1B[90m';

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  /// Pretty-prints JSON and masks sensitive fields
  static String _formatJson(dynamic json) {
    if (json == null) return 'null';
    try {
      // Decode if string
      var data = json;
      if (json is String) {
        if (json.trim().startsWith('{') || json.trim().startsWith('[')) {
          try {
            data = jsonDecode(json);
          } on Exception catch (_) {
            return json; // Return raw string if not valid JSON
          }
        } else {
          return json;
        }
      }

      // Encode with indentation
      final encoder = JsonEncoder.withIndent('  ', (object) {
        if (object.toString().contains('access_token')) return '***MASKED***';
        return object;
      });

      var pretty = encoder.convert(data);

      // Manual masking for known keys in the string output
      pretty = pretty.replaceAll(
        RegExp('"access_token": "[^"]+"'),
        '"access_token": "***MASKED***"',
      );
      pretty = pretty.replaceAll(
        RegExp('"refresh_token": "[^"]+"'),
        '"refresh_token": "***MASKED***"',
      );

      return pretty;
    } on Object catch (_) {
      // Encoding can fail for unsupported objects supplied by platform or SDK
      // errors; logging must degrade to a safe string instead of crashing.
      return json.toString();
    }
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    dynamic jsonPayload,
  }) {
    if (!kDebugMode) return;
    if (level.index < currentLevel.index) return;

    final emoji = switch (level) {
      LogLevel.debug => '🔍',
      LogLevel.info => '✅',
      LogLevel.warning => '⚠️',
      LogLevel.error => '❌',
    };

    final color = useColors
        ? switch (level) {
            LogLevel.debug => _cyan,
            LogLevel.info => _green,
            LogLevel.warning => _yellow,
            LogLevel.error => _red,
          }
        : '';

    final reset = useColors ? _reset : '';
    final gray = useColors ? _gray : '';

    final tagStr = tag != null ? '$gray[$tag]$reset ' : '';
    final timeStr = '$gray${_timestamp()}$reset';

    // Main line
    debugPrint('$timeStr $tagStr$color$emoji $message$reset');

    // Optional JSON payload
    if (jsonPayload != null) {
      final pretty = _formatJson(jsonPayload);
      final prefix = useColors ? '$gray  │$reset' : '  │';
      debugPrint('$prefix JSON Payload:');
      pretty.split('\n').forEach((line) => debugPrint('$prefix $line'));
    }

    // Errors
    if (error != null) {
      final errPrefix = useColors ? '$color  └─$reset' : '  └─';
      // Attempt to clean up common verbose errors (e.g. Supabase)
      var errorStr = error.toString();
      if (errorStr.contains('PostgrestException')) {
        // Extract basic message to reduce noise
        final match = RegExp('message: (.*?), code:').firstMatch(errorStr);
        if (match != null) {
          errorStr = 'DB Error: ${match.group(1)} (Full trace below)';
        }
      }
      debugPrint('$errPrefix $errorStr');
    }

    if (stackTrace != null && level == LogLevel.error) {
      final tracePrefix = useColors ? '$gray      $reset' : '      ';
      final lines = stackTrace.toString().split('\n').take(5);
      for (final line in lines) {
        debugPrint('$tracePrefix$line');
      }
    }
  }

  static void d(String message, {String? tag, dynamic json}) {
    _log(LogLevel.debug, message, tag: tag, jsonPayload: json);
  }

  static void i(String message, {String? tag, dynamic json}) {
    _log(LogLevel.info, message, tag: tag, jsonPayload: json);
  }

  static void w(String message, {String? tag, dynamic error, dynamic json}) {
    _log(LogLevel.warning, message, tag: tag, error: error, jsonPayload: json);
  }

  static void e(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    dynamic json,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      jsonPayload: json,
    );

    // Automatically report errors to crashlytics
    unawaited(
      CrashReportingService.instance.recordError(
        error ?? message,
        stackTrace,
        reason: message,
      ),
    );
  }

  static void api(
    String endpoint,
    int? statusCode, {
    String? tag,
    Duration? duration,
  }) {
    if (!kDebugMode || currentLevel.index > LogLevel.info.index) return;

    final status = statusCode ?? 0;
    final isSuccess = status >= 200 && status < 300;
    final emoji = isSuccess ? '🌐' : '🚫';
    final durationStr = duration != null
        ? ' (${duration.inMilliseconds}ms)'
        : '';

    final color = useColors ? (isSuccess ? _green : _red) : '';
    final reset = useColors ? _reset : '';

    _log(
      LogLevel.info,
      '$color$emoji $endpoint -> $status$reset$durationStr',
      tag: tag,
    );
  }
}
