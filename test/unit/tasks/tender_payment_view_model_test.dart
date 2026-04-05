import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/tasks/services/tender_payment_coordinator.dart';
import 'package:sline_app/features/tasks/viewmodels/tender_payment_view_model.dart';

class _MockTenderPaymentCoordinator extends Mock
    implements TenderPaymentCoordinator {}

void main() {
  late _MockTenderPaymentCoordinator coordinator;

  /// A deadline comfortably in the future (1 hour from now).
  late DateTime futureDeadline;

  /// A deadline in the past (1 hour ago).
  late DateTime pastDeadline;

  const requestId = 'req-001';
  const taskTitle = 'Design a Logo';
  const freelancerName = 'Ahmad';
  const amount = 150000.0;

  TenderPaymentViewModel buildVm({DateTime? deadline}) {
    return TenderPaymentViewModel(
      coordinator: coordinator,
      requestId: requestId,
      taskTitle: taskTitle,
      freelancerName: freelancerName,
      amount: amount,
      paymentDeadline: deadline ?? futureDeadline,
    );
  }

  setUp(() {
    coordinator = _MockTenderPaymentCoordinator();
    futureDeadline = DateTime.now().add(const Duration(hours: 1));
    pastDeadline = DateTime.now().subtract(const Duration(hours: 1));
  });

  // ---------------------------------------------------------------------------
  // Construction & Getters
  // ---------------------------------------------------------------------------
  group('Construction & Getters', () {
    test('constructs with required params without throwing', () {
      expect(buildVm, returnsNormally);
    });

    test('initial state has isProcessing false', () {
      final vm = buildVm();
      expect(vm.isProcessing, isFalse);
    });

    test('initial state has errorMessage null', () {
      final vm = buildVm();
      expect(vm.errorMessage, isNull);
    });

    test('initial state has success false', () {
      final vm = buildVm();
      expect(vm.success, isFalse);
    });

    test('initial state has pendingFormUrl null', () {
      final vm = buildVm();
      expect(vm.pendingFormUrl, isNull);
    });

    test('initial state has pendingRequestId null', () {
      final vm = buildVm();
      expect(vm.pendingRequestId, isNull);
    });

    test('initial state has pendingPaymentRequestId null', () {
      final vm = buildVm();
      expect(vm.pendingPaymentRequestId, isNull);
    });

    test('initial state has hasPendingWebPayment false', () {
      final vm = buildVm();
      expect(vm.hasPendingWebPayment, isFalse);
    });

    test('taskTitle returns constructor value', () {
      final vm = buildVm();
      expect(vm.taskTitle, taskTitle);
    });

    test('freelancerName returns constructor value', () {
      final vm = buildVm();
      expect(vm.freelancerName, freelancerName);
    });

    test('amount returns constructor value', () {
      final vm = buildVm();
      expect(vm.amount, amount);
    });

    test('isExpired returns false when deadline is in the future', () {
      final vm = buildVm(deadline: futureDeadline);
      expect(vm.isExpired, isFalse);
    });

    test('isExpired returns true when deadline is in the past', () {
      final vm = buildVm(deadline: pastDeadline);
      expect(vm.isExpired, isTrue);
    });

    test('timeRemaining is positive for future deadline', () {
      final vm = buildVm(deadline: futureDeadline);
      expect(vm.timeRemaining.isNegative, isFalse);
    });

    test('timeRemaining is negative for past deadline', () {
      final vm = buildVm(deadline: pastDeadline);
      expect(vm.timeRemaining.isNegative, isTrue);
    });

    test('isTenderPaymentAvailable delegates to coordinator', () {
      when(() => coordinator.isTenderPaymentAvailable).thenReturn(true);
      final vm = buildVm();
      expect(vm.isTenderPaymentAvailable, isTrue);
      verify(() => coordinator.isTenderPaymentAvailable).called(1);
    });

    test(
      'isTenderPaymentAvailable returns false when coordinator says false',
      () {
        when(() => coordinator.isTenderPaymentAvailable).thenReturn(false);
        final vm = buildVm();
        expect(vm.isTenderPaymentAvailable, isFalse);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Submit Happy Path
  // ---------------------------------------------------------------------------
  group('Submit Happy Path', () {
    test('isProcessing is true during execution', () async {
      final processingStates = <bool>[];

      when(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).thenAnswer((_) async {
        return <String, dynamic>{'status': 'ok'};
      });

      final vm = buildVm();
      vm.addListener(() {
        processingStates.add(vm.isProcessing);
      });

      await vm.submit();

      // First notification: isProcessing = true; second: isProcessing = false
      expect(processingStates, contains(true));
      expect(processingStates.last, isFalse);
    });

    test(
      'success is true after coordinator returns non-webview result',
      () async {
        when(
          () => coordinator.executePayment(
            requestId: any(named: 'requestId'),
            amount: any(named: 'amount'),
            currency: any(named: 'currency'),
            description: any(named: 'description'),
            finishUrl: any(named: 'finishUrl'),
          ),
        ).thenAnswer((_) async => <String, dynamic>{'status': 'ok'});

        final vm = buildVm();
        await vm.submit();

        expect(vm.success, isTrue);
        expect(vm.errorMessage, isNull);
      },
    );

    test('calls coordinator.executePayment with correct params', () async {
      when(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{'status': 'ok'});

      final vm = buildVm();
      await vm.submit(finishUrl: 'https://example.com/finish');

      verify(
        () => coordinator.executePayment(
          requestId: requestId,
          amount: amount,
          currency: 'IQD',
          description: 'Payment for "$taskTitle"',
          finishUrl: 'https://example.com/finish',
        ),
      ).called(1);
    });

    test('isProcessing is false after submit completes', () async {
      when(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{'status': 'ok'});

      final vm = buildVm();
      await vm.submit();

      expect(vm.isProcessing, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Submit WebView Redirect
  // ---------------------------------------------------------------------------
  group('Submit WebView Redirect', () {
    Map<String, dynamic> webViewResult() => <String, dynamic>{
      'open_webview': true,
      'form_url': 'https://pay.qi.iq/form/abc',
      'request_id': 'req-server-001',
      'payment_request_id': 'pay-req-001',
    };

    test(
      'coordinator returning open_webview=true sets pending fields on VM',
      () async {
        when(
          () => coordinator.executePayment(
            requestId: any(named: 'requestId'),
            amount: any(named: 'amount'),
            currency: any(named: 'currency'),
            description: any(named: 'description'),
            finishUrl: any(named: 'finishUrl'),
          ),
        ).thenAnswer((_) async => webViewResult());

        final vm = buildVm();
        await vm.submit();

        expect(vm.pendingFormUrl, 'https://pay.qi.iq/form/abc');
        expect(vm.pendingRequestId, 'req-server-001');
        expect(vm.pendingPaymentRequestId, 'pay-req-001');
        expect(vm.success, isFalse);
      },
    );

    test('hasPendingWebPayment is true after webview redirect', () async {
      when(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).thenAnswer((_) async => webViewResult());

      final vm = buildVm();
      await vm.submit();

      expect(vm.hasPendingWebPayment, isTrue);
    });

    test('clearPendingWebPayment clears all pending fields', () async {
      when(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).thenAnswer((_) async => webViewResult());

      final vm = buildVm();
      await vm.submit();

      // Verify fields are set before clearing
      expect(vm.hasPendingWebPayment, isTrue);

      vm.clearPendingWebPayment();

      expect(vm.pendingFormUrl, isNull);
      expect(vm.pendingRequestId, isNull);
      expect(vm.pendingPaymentRequestId, isNull);
      expect(vm.hasPendingWebPayment, isFalse);
    });

    test('clearPendingWebPayment notifies listeners', () async {
      when(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).thenAnswer((_) async => webViewResult());

      final vm = buildVm();
      await vm.submit();

      var notified = false;
      vm.addListener(() => notified = true);

      vm.clearPendingWebPayment();
      expect(notified, isTrue);
    });

    test('clearPendingWebPayment does not notify when already clear', () {
      final vm = buildVm();

      var notified = false;
      vm.addListener(() => notified = true);

      vm.clearPendingWebPayment();
      expect(notified, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Recovery
  // ---------------------------------------------------------------------------
  group('Recovery', () {
    test('completeRecovery calls coordinator.recoverTenderPayment', () async {
      when(
        () => coordinator.recoverTenderPayment(
          requestId: any(named: 'requestId'),
          paymentRequestId: any(named: 'paymentRequestId'),
        ),
      ).thenAnswer((_) async => const QiCardTenderRecoveryResult(ok: true));

      final vm = buildVm();
      await vm.completeRecovery(
        requestId: 'req-r-1',
        paymentRequestId: 'pay-r-1',
      );

      verify(
        () => coordinator.recoverTenderPayment(
          requestId: 'req-r-1',
          paymentRequestId: 'pay-r-1',
        ),
      ).called(1);
    });

    test(
      'success recovery sets success true and clears pending fields',
      () async {
        when(
          () => coordinator.executePayment(
            requestId: any(named: 'requestId'),
            amount: any(named: 'amount'),
            currency: any(named: 'currency'),
            description: any(named: 'description'),
            finishUrl: any(named: 'finishUrl'),
          ),
        ).thenAnswer(
          (_) async => <String, dynamic>{
            'open_webview': true,
            'form_url': 'https://pay.qi.iq/form/abc',
            'request_id': 'req-server-001',
            'payment_request_id': 'pay-req-001',
          },
        );

        when(
          () => coordinator.recoverTenderPayment(
            requestId: any(named: 'requestId'),
            paymentRequestId: any(named: 'paymentRequestId'),
          ),
        ).thenAnswer((_) async => const QiCardTenderRecoveryResult(ok: true));

        final vm = buildVm();

        // First set up pending web payment state
        await vm.submit();
        expect(vm.hasPendingWebPayment, isTrue);

        // Now recover
        await vm.completeRecovery(
          requestId: 'req-server-001',
          paymentRequestId: 'pay-req-001',
        );

        expect(vm.success, isTrue);
        expect(vm.pendingFormUrl, isNull);
        expect(vm.pendingRequestId, isNull);
        expect(vm.pendingPaymentRequestId, isNull);
        expect(vm.hasPendingWebPayment, isFalse);
        expect(vm.errorMessage, isNull);
      },
    );

    test('failed recovery sets errorMessage and clears pending fields', () async {
      when(
        () => coordinator.recoverTenderPayment(
          requestId: any(named: 'requestId'),
          paymentRequestId: any(named: 'paymentRequestId'),
        ),
      ).thenAnswer(
        (_) async => const QiCardTenderRecoveryResult(
          ok: false,
          error: 'PAYMENT_NOT_SUCCESS: cannot recover',
        ),
      );

      final vm = buildVm();
      await vm.completeRecovery(
        requestId: 'req-fail',
        paymentRequestId: 'pay-fail',
      );

      expect(vm.success, isFalse);
      expect(vm.errorMessage, isNotNull);
      expect(
        vm.errorMessage,
        'Payment was not completed. Please try again or pay from the payment page.',
      );
      expect(vm.pendingFormUrl, isNull);
      expect(vm.pendingRequestId, isNull);
      expect(vm.pendingPaymentRequestId, isNull);
    });

    test('recovery exception sets errorMessage', () async {
      when(
        () => coordinator.recoverTenderPayment(
          requestId: any(named: 'requestId'),
          paymentRequestId: any(named: 'paymentRequestId'),
        ),
      ).thenThrow(Exception('network error'));

      final vm = buildVm();
      await vm.completeRecovery(
        requestId: 'req-err',
        paymentRequestId: 'pay-err',
      );

      expect(vm.success, isFalse);
      expect(vm.errorMessage, isNotNull);
      expect(vm.isProcessing, isFalse);
    });

    test(
      'recovery with null error falls back to Recovery failed message',
      () async {
        when(
          () => coordinator.recoverTenderPayment(
            requestId: any(named: 'requestId'),
            paymentRequestId: any(named: 'paymentRequestId'),
          ),
        ).thenAnswer((_) async => const QiCardTenderRecoveryResult(ok: false));

        final vm = buildVm();
        await vm.completeRecovery(
          requestId: 'req-null-err',
          paymentRequestId: 'pay-null-err',
        );

        expect(vm.success, isFalse);
        // 'Recovery failed.' does not match any specific code, so fallback
        expect(vm.errorMessage, 'Payment failed. Please try again.');
      },
    );

    test('isProcessing is false after recovery completes', () async {
      when(
        () => coordinator.recoverTenderPayment(
          requestId: any(named: 'requestId'),
          paymentRequestId: any(named: 'paymentRequestId'),
        ),
      ).thenAnswer((_) async => const QiCardTenderRecoveryResult(ok: true));

      final vm = buildVm();
      await vm.completeRecovery(requestId: 'req-1', paymentRequestId: 'pay-1');

      expect(vm.isProcessing, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Error Mapping
  // ---------------------------------------------------------------------------
  group('Error Mapping', () {
    void stubCoordinatorThrows(String errorMessage) {
      when(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).thenThrow(Exception(errorMessage));
    }

    test('INVALID_STATE maps to not-in-state-that-allows message', () async {
      stubCoordinatorThrows('INVALID_STATE: must be awarded and unpaid');

      final vm = buildVm();
      await vm.submit();

      expect(
        vm.errorMessage,
        'This tender is not in a state that allows payment. '
        'It may already be paid or expired.',
      );
    });

    test('must be awarded and unpaid maps to not-in-state message', () async {
      stubCoordinatorThrows('must be awarded and unpaid');

      final vm = buildVm();
      await vm.submit();

      expect(
        vm.errorMessage,
        'This tender is not in a state that allows payment. '
        'It may already be paid or expired.',
      );
    });

    test('PAYMENT_NOT_SUCCESS maps to not-completed message', () async {
      stubCoordinatorThrows('PAYMENT_NOT_SUCCESS');

      final vm = buildVm();
      await vm.submit();

      expect(
        vm.errorMessage,
        'Payment was not completed. Please try again or pay from the payment page.',
      );
    });

    test('cannot recover maps to not-completed message', () async {
      stubCoordinatorThrows('cannot recover this payment');

      final vm = buildVm();
      await vm.submit();

      expect(
        vm.errorMessage,
        'Payment was not completed. Please try again or pay from the payment page.',
      );
    });

    test('PAYMENT_DEADLINE_EXPIRED maps to deadline-passed message', () async {
      stubCoordinatorThrows('PAYMENT_DEADLINE_EXPIRED');

      final vm = buildVm();
      await vm.submit();

      expect(vm.errorMessage, 'The payment deadline has passed.');
    });

    test('FORBIDDEN maps to task-owner message', () async {
      stubCoordinatorThrows('FORBIDDEN: not your task');

      final vm = buildVm();
      await vm.submit();

      expect(vm.errorMessage, 'Only the task owner can complete this payment.');
    });

    test('Only the task owner maps to task-owner message', () async {
      stubCoordinatorThrows('Only the task owner can pay');

      final vm = buildVm();
      await vm.submit();

      expect(vm.errorMessage, 'Only the task owner can complete this payment.');
    });

    test('TASK_REQUEST_NOT_FOUND maps to not-found message', () async {
      stubCoordinatorThrows('TASK_REQUEST_NOT_FOUND');

      final vm = buildVm();
      await vm.submit();

      expect(
        vm.errorMessage,
        'This tender or task could not be found. Please refresh and try again.',
      );
    });

    test('TASK_NOT_FOUND maps to not-found message', () async {
      stubCoordinatorThrows('TASK_NOT_FOUND');

      final vm = buildVm();
      await vm.submit();

      expect(
        vm.errorMessage,
        'This tender or task could not be found. Please refresh and try again.',
      );
    });

    test('Payment failed: prefix is returned as-is', () async {
      stubCoordinatorThrows('Payment failed: gateway timeout');

      final vm = buildVm();
      await vm.submit();

      // The exception toString is "Exception: Payment failed: gateway timeout"
      // which contains 'Payment failed:' so raw is returned
      expect(vm.errorMessage, contains('Payment failed:'));
    });

    test('unknown error maps to generic fallback', () async {
      stubCoordinatorThrows('something completely unexpected happened');

      final vm = buildVm();
      await vm.submit();

      expect(vm.errorMessage, 'Payment failed. Please try again.');
    });

    test('isProcessing is false after error', () async {
      stubCoordinatorThrows('FORBIDDEN');

      final vm = buildVm();
      await vm.submit();

      expect(vm.isProcessing, isFalse);
    });

    test('success remains false after error', () async {
      stubCoordinatorThrows('INVALID_STATE');

      final vm = buildVm();
      await vm.submit();

      expect(vm.success, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Edge Cases
  // ---------------------------------------------------------------------------
  group('Edge Cases', () {
    test('submit when already processing is a no-op', () async {
      final completer = Future<Map<String, dynamic>>.delayed(
        const Duration(milliseconds: 200),
        () => <String, dynamic>{'status': 'ok'},
      );

      when(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).thenAnswer((_) => completer);

      final vm = buildVm();

      // Start first submit (will be processing)
      final first = vm.submit();
      // Immediately try second submit while first is still running
      final second = vm.submit();

      await Future.wait([first, second]);

      // executePayment should only have been called once
      verify(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).called(1);
    });

    test('submit when expired is a no-op', () async {
      final vm = buildVm(deadline: pastDeadline);

      await vm.submit();

      verifyNever(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      );
      expect(vm.isProcessing, isFalse);
      expect(vm.success, isFalse);
    });

    test('submit when expired does not notify listeners', () async {
      final vm = buildVm(deadline: pastDeadline);

      var notified = false;
      vm.addListener(() => notified = true);

      await vm.submit();

      expect(notified, isFalse);
    });

    test('completeRecovery when already processing is a no-op', () async {
      final completer = Future<QiCardTenderRecoveryResult>.delayed(
        const Duration(milliseconds: 200),
        () => const QiCardTenderRecoveryResult(ok: true),
      );

      when(
        () => coordinator.recoverTenderPayment(
          requestId: any(named: 'requestId'),
          paymentRequestId: any(named: 'paymentRequestId'),
        ),
      ).thenAnswer((_) => completer);

      final vm = buildVm();

      // Start first recovery
      final first = vm.completeRecovery(
        requestId: 'r1',
        paymentRequestId: 'p1',
      );
      // Immediately try second recovery while first is running
      final second = vm.completeRecovery(
        requestId: 'r2',
        paymentRequestId: 'p2',
      );

      await Future.wait([first, second]);

      // Only one call to coordinator
      verify(
        () => coordinator.recoverTenderPayment(
          requestId: any(named: 'requestId'),
          paymentRequestId: any(named: 'paymentRequestId'),
        ),
      ).called(1);
    });

    test('submit clears previous error and pending fields', () async {
      // First call throws to set error state
      when(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).thenThrow(Exception('FORBIDDEN'));

      final vm = buildVm();
      await vm.submit();
      expect(vm.errorMessage, isNotNull);

      // Second call succeeds
      when(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{'status': 'ok'});

      await vm.submit();

      expect(vm.errorMessage, isNull);
      expect(vm.success, isTrue);
    });

    test('submit with finishUrl=null passes null to coordinator', () async {
      when(
        () => coordinator.executePayment(
          requestId: any(named: 'requestId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{'status': 'ok'});

      final vm = buildVm();
      await vm.submit();

      verify(
        () => coordinator.executePayment(
          requestId: requestId,
          amount: amount,
          currency: 'IQD',
          description: 'Payment for "$taskTitle"',
          finishUrl: null,
        ),
      ).called(1);
    });

    test(
      'webview result with missing form_url falls through to success',
      () async {
        when(
          () => coordinator.executePayment(
            requestId: any(named: 'requestId'),
            amount: any(named: 'amount'),
            currency: any(named: 'currency'),
            description: any(named: 'description'),
            finishUrl: any(named: 'finishUrl'),
          ),
        ).thenAnswer(
          (_) async => <String, dynamic>{
            'open_webview': true,
            'form_url': null,
            'request_id': 'req-1',
            'payment_request_id': 'pay-1',
          },
        );

        final vm = buildVm();
        await vm.submit();

        // Missing form_url means condition fails, goes to else branch
        expect(vm.success, isTrue);
        expect(vm.hasPendingWebPayment, isFalse);
      },
    );

    test(
      'webview result with open_webview=false falls through to success',
      () async {
        when(
          () => coordinator.executePayment(
            requestId: any(named: 'requestId'),
            amount: any(named: 'amount'),
            currency: any(named: 'currency'),
            description: any(named: 'description'),
            finishUrl: any(named: 'finishUrl'),
          ),
        ).thenAnswer(
          (_) async => <String, dynamic>{
            'open_webview': false,
            'form_url': 'https://pay.qi.iq/form/abc',
            'request_id': 'req-1',
            'payment_request_id': 'pay-1',
          },
        );

        final vm = buildVm();
        await vm.submit();

        expect(vm.success, isTrue);
        expect(vm.hasPendingWebPayment, isFalse);
      },
    );
  });
}
