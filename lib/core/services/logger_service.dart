/// What: Centralized logging utility built on top of the `logger` package.
/// Why: Provides a single place to control log formatting and verbosity by env/level.
library;
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Logging levels to control verbosity
enum LogLevel { debug, info, warning, error }

/// Centralized logger for the app
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Hide method calls
      errorMethodCount: 5, // Show more lines for errors
      lineLength: 80, // Console line width
      colors: true, // Colored output
      printEmojis: true, // Emojis for clarity
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // Show time
    ),
  );

  /// Current log level (default: info)
  static LogLevel currentLevel = LogLevel.info;

  static void d(String message) {
    if (kDebugMode && currentLevel == LogLevel.debug) {
      _logger.d(message);
    }
  }

  static void i(String message) {
    if (kDebugMode && currentLevel.index <= LogLevel.info.index) {
      _logger.i(message);
    }
  }

  static void w(String message) {
    if (kDebugMode && currentLevel.index <= LogLevel.warning.index) {
      _logger.w(message);
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode && currentLevel.index <= LogLevel.error.index) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }
}