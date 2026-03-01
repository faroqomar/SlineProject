import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/config/payment_runtime_config.dart';

void main() {
  group('payment_runtime_config', () {
    test('buildQiCardCallbackHosts includes the default finish host', () {
      final hosts = buildQiCardCallbackHosts();

      expect(hosts, contains('sline.app'));
    });

    test('buildQiCardCallbackHosts accepts a custom finish url', () {
      final hosts = buildQiCardCallbackHosts(
        finishUrl: 'https://checkout.example.com/payment/success',
      );

      expect(hosts, contains('checkout.example.com'));
    });

    test('parsePaymentReturnArgs infers success from payment success url', () {
      final args = parsePaymentReturnArgs(
        Uri.parse(
          'https://sline.app/payment/success?booking_id=b1&correlation_id=c1&payment_id=p1',
        ),
      );

      expect(args, isNotNull);
      expect(args!.normalizedStatus, 'SUCCESS');
      expect(args.bookingId, 'b1');
      expect(args.correlationId, 'c1');
      expect(args.paymentId, 'p1');
    });

    test('parsePaymentReturnArgs accepts root callback url with query signal', () {
      final args = parsePaymentReturnArgs(
        Uri.parse(
          'https://sline.app/?payment_return=1&booking_id=b1&correlation_id=c1',
        ),
      );

      expect(args, isNotNull);
      expect(args!.normalizedStatus, 'UNKNOWN');
      expect(args.bookingId, 'b1');
      expect(args.correlationId, 'c1');
    });

    test('buildQiCardFinishUrlForRuntime preserves the current web path', () {
      final finishUrl = buildQiCardFinishUrlForRuntime(
        runtimeUri: Uri.parse('https://app.example.com/dashboard?tab=bookings'),
      );

      expect(
        finishUrl,
        'https://app.example.com/dashboard?payment_return=1',
      );
    });

    test('buildQiCardCallbackHosts uses the runtime finish host', () {
      final hosts = buildQiCardCallbackHosts(
        finishUrl: 'https://app.example.com/dashboard?payment_return=1',
      );

      expect(hosts, contains('app.example.com'));
      expect(hosts, isNot(contains('sline.app')));
    });

    test('shouldResumePendingWebPayment resumes recent localhost payment', () {
      final shouldResume = shouldResumePendingWebPayment(
        currentUri: Uri.parse('http://localhost:58822/'),
        startedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
        callbackHosts: const <String>{'localhost'},
        expectedReturnUrl: 'http://localhost:58822/?payment_return=1',
      );

      expect(shouldResume, isTrue);
    });

    test('shouldResumePendingWebPayment rejects stale pending payment', () {
      final shouldResume = shouldResumePendingWebPayment(
        currentUri: Uri.parse('http://localhost:58822/'),
        startedAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        callbackHosts: const <String>{'localhost'},
        expectedReturnUrl: 'http://localhost:58822/?payment_return=1',
      );

      expect(shouldResume, isFalse);
    });
  });
}
