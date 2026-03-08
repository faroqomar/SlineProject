import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/services/demo_payment_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/services/qicard_payment_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/services/tender_payment_coordinator.dart';

class MockTaskService extends Mock implements TaskService {}

class MockPaymentService extends Mock implements PaymentService {}

void main() {
  group('TenderPaymentCoordinator', () {
    late MockTaskService taskService;
    late MockPaymentService paymentService;
    late TenderPaymentCoordinator coordinator;

    setUp(() {
      taskService = MockTaskService();
      paymentService = MockPaymentService();
      coordinator = TenderPaymentCoordinator(
        taskService: taskService,
        paymentService: paymentService,
      );
    });

    test('executePayment calls processPayment then payAwardedOffer', () async {
      when(
        () => paymentService.processPayment(
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => 'ok');
      when(
        () => taskService.payAwardedOffer(any()),
      ).thenAnswer((_) async => {'success': true});

      await coordinator.executePayment(
        requestId: 'req-1',
        amount: 100.0,
        currency: 'IQD',
        description: 'Test',
      );

      verify(
        () => paymentService.processPayment(
          amount: 100.0,
          currency: 'IQD',
          description: 'Test',
        ),
      ).called(1);
      verify(() => taskService.payAwardedOffer('req-1')).called(1);
    });

    test(
      'executePayment does not call payAwardedOffer when processPayment throws',
      () async {
        when(
          () => paymentService.processPayment(
            amount: any(named: 'amount'),
            currency: any(named: 'currency'),
            description: any(named: 'description'),
          ),
        ).thenThrow(Exception('Payment failed'));

        expect(
          () => coordinator.executePayment(
            requestId: 'req-1',
            amount: 100.0,
            currency: 'IQD',
            description: 'Test',
          ),
          throwsA(isA<Exception>()),
        );

        verifyNever(() => taskService.payAwardedOffer(any()));
      },
    );

    test(
      'executePayment fail-closed: DemoPaymentService throws and never calls payAwardedOffer',
      () async {
        final demoCoordinator = TenderPaymentCoordinator(
          taskService: taskService,
          paymentService: DemoPaymentService(),
        );

        expect(
          () => demoCoordinator.executePayment(
            requestId: 'req-1',
            amount: 100.0,
            currency: 'IQD',
            description: 'Test',
          ),
          throwsA(isA<Exception>()),
        );

        verifyNever(() => taskService.payAwardedOffer(any()));
      },
    );

    test(
      'executePayment fail-closed: QiCardPaymentService throws and never calls payAwardedOffer',
      () async {
        final qiCoordinator = TenderPaymentCoordinator(
          taskService: taskService,
          paymentService: QiCardPaymentService(),
        );

        expect(
          () => qiCoordinator.executePayment(
            requestId: 'req-1',
            amount: 100.0,
            currency: 'IQD',
            description: 'Test',
          ),
          throwsA(isA<Exception>()),
        );

        verifyNever(() => taskService.payAwardedOffer(any()));
      },
    );
  });
}
