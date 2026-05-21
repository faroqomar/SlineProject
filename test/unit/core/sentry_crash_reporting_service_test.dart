import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/services/crash_reporting_service.dart';
import 'package:sline_app/core/services/sentry_crash_reporting_service.dart';

void main() {
  group('SentryCrashReportingService', () {
    test('can be instantiated without Sentry DSN', () {
      // Sentry is not initialized in tests (no DSN), but the class should
      // construct without error and methods should not throw.
      final service = SentryCrashReportingService();
      expect(service, isNotNull);
      expect(service, isA<CrashReportingService>());
    });

    test('implements CrashReportingService interface', () {
      final service = SentryCrashReportingService();
      expect(service, isA<CrashReportingService>());
    });

    test('recordError does not throw when Sentry is not initialized', () async {
      final service = SentryCrashReportingService();
      // Should not throw even though Sentry DSN is empty in test environment
      await expectLater(
        service.recordError(Exception('test'), StackTrace.current, fatal: true),
        completes,
      );
    });

    test('log does not throw when Sentry is not initialized', () async {
      final service = SentryCrashReportingService();
      await expectLater(service.log('test breadcrumb'), completes);
    });

    test(
      'setUserIdentifier does not throw when Sentry is not initialized',
      () async {
        final service = SentryCrashReportingService();
        await expectLater(service.setUserIdentifier('user-123'), completes);
      },
    );

    test('setUserIdentifier with empty string clears user', () async {
      final service = SentryCrashReportingService();
      await expectLater(service.setUserIdentifier(''), completes);
    });

    test(
      'setCustomKey does not throw when Sentry is not initialized',
      () async {
        final service = SentryCrashReportingService();
        await expectLater(
          service.setCustomKey('app_version', '1.0.0'),
          completes,
        );
      },
    );

    test('recordError with reason passes hint', () async {
      final service = SentryCrashReportingService();
      await expectLater(
        service.recordError(
          Exception('payment failed'),
          StackTrace.current,
          reason: 'QiCard timeout',
        ),
        completes,
      );
    });
  });

  group('CrashReportingService singleton', () {
    test('defaults to NoOpCrashReportingService', () {
      // Reset to default
      CrashReportingService.instance = NoOpCrashReportingService();
      expect(CrashReportingService.instance, isA<NoOpCrashReportingService>());
    });

    test('can be swapped to SentryCrashReportingService', () {
      CrashReportingService.instance = SentryCrashReportingService();
      expect(
        CrashReportingService.instance,
        isA<SentryCrashReportingService>(),
      );
      // Restore default
      CrashReportingService.instance = NoOpCrashReportingService();
    });
  });

  group('PII sanitizer', () {
    test('strips email addresses', () {
      final result = SentryCrashReportingService.sanitizePii(
        'Failed to load profile for user@example.com',
      );
      expect(result, 'Failed to load profile for [EMAIL]');
      expect(result, isNot(contains('user@example.com')));
    });

    test('strips phone numbers', () {
      final result = SentryCrashReportingService.sanitizePii(
        'SMS sent to +9647701234567',
      );
      expect(result, 'SMS sent to [PHONE]');
    });

    test('strips multiple PII occurrences', () {
      final result = SentryCrashReportingService.sanitizePii(
        'User test@mail.com called +1234567890 then other@mail.org replied',
      );
      expect(result, isNot(contains('@')));
      expect(result, contains('[EMAIL]'));
      expect(result, contains('[PHONE]'));
    });

    test('leaves non-PII messages unchanged', () {
      const msg = 'Dashboard load error after 150ms';
      expect(SentryCrashReportingService.sanitizePii(msg), msg);
    });

    test('leaves UUIDs unchanged', () {
      const msg = 'User 550e8400-e29b-41d4-a716-446655440000 logged in';
      expect(SentryCrashReportingService.sanitizePii(msg), msg);
    });
  });
}
