import 'package:flutter/foundation.dart';

const bool kVerboseNoOpCrashReporting = bool.fromEnvironment(
  'VERBOSE_DEBUG_CRASH_REPORTING',
);

/// Abstract service for reporting crashes and non-fatal errors.
///
/// This allows us to swap implementations (Firebase Crashlytics, Sentry, etc.)
/// without changing the calling code.
abstract class CrashReportingService {
  static CrashReportingService? _instance;

  static CrashReportingService get instance {
    return _instance ??= NoOpCrashReportingService();
  }

  static set instance(CrashReportingService service) {
    _instance = service;
  }

  /// Records a fatal crash or non-fatal error.
  ///
  /// [exception] The exception/error object.
  /// [stack] The stack trace.
  /// [reason] Optional reason or context message.
  /// [fatal] Whether this should be treated as a fatal crash (default: false).
  Future<void> recordError(
    Object? exception,
    StackTrace? stack, {
    Object? reason,
    bool fatal = false,
  });

  /// Logs a message to the crash reporting system.
  ///
  /// This log is usually attached to subsequent crash reports to provide context.
  Future<void> log(String message);

  /// Sets a user identifier for crash reports.
  Future<void> setUserIdentifier(String identifier);

  /// Sets a custom key-value pair for crash reports.
  Future<void> setCustomKey(String key, Object value);
}

/// A no-op implementation for development or when no provider is configured.
/// It simply prints to console in debug mode.
class NoOpCrashReportingService implements CrashReportingService {
  @override
  Future<void> recordError(
    Object? exception,
    StackTrace? stack, {
    Object? reason,
    bool fatal = false,
  }) async {
    if (kDebugMode && kVerboseNoOpCrashReporting) {
      debugPrint('💥 [CrashReporting] Error: $exception');
      if (reason != null) debugPrint('   Reason: $reason');
      if (stack != null) debugPrint('   Stack: $stack');
    }
  }

  @override
  Future<void> log(String message) async {
    if (kDebugMode && kVerboseNoOpCrashReporting) {
      debugPrint('📝 [CrashReporting] Log: $message');
    }
  }

  @override
  Future<void> setUserIdentifier(String identifier) async {
    if (kDebugMode && kVerboseNoOpCrashReporting) {
      debugPrint('👤 [CrashReporting] User ID: $identifier');
    }
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    if (kDebugMode && kVerboseNoOpCrashReporting) {
      debugPrint('🔑 [CrashReporting] Key: $key = $value');
    }
  }
}
