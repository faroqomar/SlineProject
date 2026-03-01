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
  });
}
