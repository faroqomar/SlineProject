import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/services/crash_reporting_service.dart';
import 'package:sline_app/core/services/demo_payment_service.dart';

class _CrashRecord {
  const _CrashRecord({
    required this.exception,
    required this.reason,
    required this.fatal,
  });

  final dynamic exception;
  final dynamic reason;
  final bool fatal;
}

class _FakeCrashReportingService implements CrashReportingService {
  final List<_CrashRecord> records = [];

  @override
  Future<void> log(String message) => Future<void>.value();

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) {
    records.add(
      _CrashRecord(exception: exception, reason: reason, fatal: fatal),
    );
    return Future<void>.value();
  }

  @override
  Future<void> setCustomKey(String key, Object value) => Future<void>.value();

  @override
  Future<void> setUserIdentifier(String identifier) => Future<void>.value();
}

void main() {
  group('DemoPaymentService T45', () {
    late CrashReportingService originalCrashReportingService;
    late _FakeCrashReportingService fakeCrashReportingService;

    setUp(() {
      originalCrashReportingService = CrashReportingService.instance;
      fakeCrashReportingService = _FakeCrashReportingService();
      CrashReportingService.instance = fakeCrashReportingService;
    });

    tearDown(() {
      CrashReportingService.instance = originalCrashReportingService;
    });

    test('T45 shouldFail true throws and logs failure path', () async {
      final service = DemoPaymentService(
        shouldFail: true,
        delay: Duration.zero,
      );

      await expectLater(
        service.processPayment(
          amount: 100,
          currency: 'IQD',
          description: 'Demo test',
        ),
        throwsA(
          predicate((e) => e.toString().contains('Payment declined (Demo)')),
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(fakeCrashReportingService.records, isNotEmpty);
      expect(
        fakeCrashReportingService.records.last.reason.toString(),
        contains('Demo payment failed (simulated)'),
      );
    });
  });
}
