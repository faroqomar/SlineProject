import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:sline_app/core/services/crash_reporting_service.dart';

/// Sentry-backed implementation of [CrashReportingService].
///
/// Forwards crashes, breadcrumbs, user identity, and custom tags to the
/// Sentry dashboard. Falls back gracefully when no DSN is configured
/// (Sentry silently disables itself).
class SentryCrashReportingService implements CrashReportingService {
  @override
  Future<void> recordError(
    Object? exception,
    StackTrace? stack, {
    Object? reason,
    bool fatal = false,
  }) async {
    try {
      final sanitizedMessage = sanitizePii(exception.toString());
      await Sentry.captureEvent(
        SentryEvent(
          throwable: exception,
          message: SentryMessage(sanitizedMessage),
          level: fatal ? SentryLevel.fatal : SentryLevel.error,
        ),
        stackTrace: stack,
        hint: Hint.withMap({
          'fatal': fatal.toString(),
          if (reason != null) 'reason': sanitizePii(reason.toString()),
        }),
      );
    } on Exception catch (e) {
      // Never let Sentry errors crash the app.
      if (kDebugMode) {
        debugPrint('[SentryCrashReporting] Failed to report error: $e');
      }
    }
  }

  static final _emailPattern = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );
  static final _phonePattern = RegExp(
    r'(?<![0-9a-fA-F-])\+[0-9]{10,15}(?![0-9a-fA-F-])',
  );
  static final _localIraqiPhonePattern = RegExp(r'\b0\d{10}\b');

  /// Strips common PII patterns from log messages before sending to Sentry.
  static String sanitizePii(String message) {
    return message
        .replaceAll(_emailPattern, '[EMAIL]')
        .replaceAll(_phonePattern, '[PHONE]')
        .replaceAll(_localIraqiPhonePattern, '[PHONE]');
  }

  @override
  Future<void> log(String message) async {
    try {
      await Sentry.addBreadcrumb(Breadcrumb(message: sanitizePii(message)));
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[SentryCrashReporting] Failed to add breadcrumb: $e');
      }
    }
  }

  @override
  Future<void> setUserIdentifier(String identifier) async {
    try {
      Sentry.configureScope(
        (scope) => scope.setUser(
          identifier.isEmpty ? null : SentryUser(id: identifier),
        ),
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[SentryCrashReporting] Failed to set user: $e');
      }
    }
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    try {
      Sentry.configureScope((scope) => scope.setTag(key, value.toString()));
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[SentryCrashReporting] Failed to set tag: $e');
      }
    }
  }
}
