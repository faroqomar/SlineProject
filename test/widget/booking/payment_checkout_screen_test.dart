import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/models/payment_return_args.dart';
import 'package:sline_app/core/services/payment_pending_store.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/booking/view/payment_checkout_screen.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';

import '../../test_support/pump_app.dart';

// ---------------------------------------------------------------------------
// File-local mocks
// ---------------------------------------------------------------------------
class _MockBookingViewModel extends Mock
    with ChangeNotifier
    implements BookingViewModel {}

class _MockPaymentPendingStore extends Mock implements PaymentPendingStore {}

/// A [NavigatorObserver] that intercepts the push of the payment webview route
/// and immediately pops it with a success [PaymentReturnArgs], simulating
/// a successful webview payment return without requiring an actual webview.
///
/// Skips the first MaterialPageRoute push (which is the home route from
/// pumpApp's MaterialApp) and only intercepts subsequent pushes.
class _AutoPopWebViewObserver extends NavigatorObserver {
  int _pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pushCount++;
    // Skip the first push (home route from MaterialApp).
    // The second push is the PaymentWebViewScreen route.
    if (_pushCount <= 1) return;

    if (route is MaterialPageRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.navigator != null && route.isCurrent) {
          route.navigator!.pop(
            PaymentReturnArgs(
              status: 'SUCCESS',
              rawUri: Uri.parse('sline://payment?status=SUCCESS'),
              bookingId: 'booking-1',
            ),
          );
        }
      });
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const _taskId = 'task-1';
const _providerId = 'provider-1';
const _taskTitle = 'Logo Design Service';
const _price = 25000.0; // 25K IQD

/// A create-payment result that has NO formUrl/intentId, so the flow
/// terminates without attempting webview navigation.
const _noFormResult = QiCardCreatePaymentResult(
  bookingId: 'booking-1',
  error: null,
);

void _stubIdleState(_MockBookingViewModel vm) {
  when(() => vm.isDemoPaymentMode).thenReturn(true);
  when(() => vm.isProcessingPayment).thenReturn(false);
  when(() => vm.bookingsError).thenReturn(null);
}

void _stubNonDemoState(_MockBookingViewModel vm) {
  when(() => vm.isDemoPaymentMode).thenReturn(false);
  when(() => vm.isProcessingPayment).thenReturn(false);
  when(() => vm.bookingsError).thenReturn(null);
}

/// Stubs the common createPaymentForBooking with any-matchers.
void _stubCreatePayment(
  _MockBookingViewModel vm, {
  required Future<QiCardCreatePaymentResult> Function(Invocation) answer,
}) {
  when(
    () => vm.createPaymentForBooking(
      taskId: any(named: 'taskId'),
      note: any(named: 'note'),
      packageId: any(named: 'packageId'),
      requirements: any(named: 'requirements'),
      finishUrl: any(named: 'finishUrl'),
    ),
  ).thenAnswer(answer);
}

/// Stubs the create-payment call to throw [e].
void _stubCreatePaymentThrows(
  _MockBookingViewModel vm, {
  required Exception e,
}) {
  when(
    () => vm.createPaymentForBooking(
      taskId: any(named: 'taskId'),
      note: any(named: 'note'),
      packageId: any(named: 'packageId'),
      requirements: any(named: 'requirements'),
      finishUrl: any(named: 'finishUrl'),
    ),
  ).thenThrow(e);
}

/// Adds commonly needed default stubs for cancel-draft and
/// streamPaymentIntentStatus so tests that trigger _processPayment
/// don't crash on un-stubbed calls.
void _stubPaymentFlow(_MockBookingViewModel vm) {
  when(() => vm.cancelBookingDraftIfUnpaid(any())).thenAnswer((_) async {});
  when(
    () => vm.streamPaymentIntentStatus(any()),
  ).thenAnswer((_) => const Stream<String>.empty());
}

Future<void> _pumpCheckout(
  WidgetTester tester, {
  required _MockBookingViewModel vm,
  required _MockPaymentPendingStore store,
  String taskTitle = _taskTitle,
  double price = _price,
  String? packageTier,
  Map<String, dynamic>? packageData,
  int? deliveryDays,
  DateTime? taskDeadline,
}) async {
  await pumpApp(
    tester,
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BookingViewModel>.value(value: vm),
        Provider<PaymentPendingStore>.value(value: store),
      ],
      child: PaymentCheckoutScreen(
        providerId: _providerId,
        taskId: _taskId,
        taskTitle: taskTitle,
        price: price,
        packageTier: packageTier,
        packageData: packageData,
        deliveryDays: deliveryDays,
        taskDeadline: taskDeadline,
      ),
    ),
  );
  await tester.pump();
}

/// A create-payment result WITH a formUrl, so the flow enters the webview branch.
const _withFormResult = QiCardCreatePaymentResult(
  bookingId: 'booking-1',
  formUrl: 'https://pay.example.com/checkout',
  error: null,
);

/// A recovery result indicating success with funds held.
const _heldRecoveryResult = QiCardRecoveryResult(
  bookingId: 'booking-1',
  bookingStatus: 'confirmed',
  paymentStatus: 'held',
);

/// Stubs the full payment→success flow on [vm]:
/// 1. createPaymentForBooking returns a result WITH formUrl
/// 2. recoverBookingPaymentWithRetries returns held status
void _stubSuccessPaymentFlow(_MockBookingViewModel vm) {
  _stubIdleState(vm);
  _stubPaymentFlow(vm);
  _stubCreatePayment(vm, answer: (_) async => _withFormResult);
  when(
    () =>
        vm.recoverBookingPaymentWithRetries(bookingId: any(named: 'bookingId')),
  ).thenAnswer((_) async => _heldRecoveryResult);
}

/// Pumps a PaymentCheckoutScreen with a [NavigatorObserver] attached.
/// Used for testing flows that push additional routes (e.g. webview).
Future<void> _pumpCheckoutWithNav(
  WidgetTester tester, {
  required _MockBookingViewModel vm,
  required _MockPaymentPendingStore store,
  required List<NavigatorObserver> observers,
  String taskTitle = _taskTitle,
  double price = _price,
}) async {
  await pumpApp(
    tester,
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BookingViewModel>.value(value: vm),
        Provider<PaymentPendingStore>.value(value: store),
      ],
      child: PaymentCheckoutScreen(
        providerId: _providerId,
        taskId: _taskId,
        taskTitle: taskTitle,
        price: price,
      ),
    ),
    navigatorObservers: observers,
  );
  await tester.pump();
}

/// Scrolls the pay button into view and taps it.
Future<void> _scrollAndTapPayButton(
  WidgetTester tester, {
  String label = 'Pay 25K IQD',
}) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  late _MockBookingViewModel mockVm;
  late _MockPaymentPendingStore mockStore;

  setUp(() {
    mockVm = _MockBookingViewModel();
    mockStore = _MockPaymentPendingStore();

    // Default stubs
    _stubIdleState(mockVm);
    _stubPaymentFlow(mockVm);
    when(() => mockStore.save(any())).thenAnswer((_) async {});
    when(() => mockStore.load()).thenReturn(null);
    when(() => mockStore.clear()).thenAnswer((_) async {});
  });

  // Register fallback values for mocktail argument matchers.
  setUpAll(() {
    registerFallbackValue(
      PendingPaymentContext(
        bookingId: '',
        provider: '',
        startedAt: DateTime.utc(2026),
        entityType: '',
        callbackHosts: const <String>{},
      ),
    );
  });

  group('PaymentCheckoutScreen', () {
    // ── Rendering ──────────────────────────────────────────────────────

    testWidgets('T100 renders PaymentCheckoutScreen widget', (tester) async {
      await _pumpCheckout(tester, vm: mockVm, store: mockStore);

      expect(find.byType(PaymentCheckoutScreen), findsOneWidget);
    });

    testWidgets('T101 renders appbar with Payment title', (tester) async {
      await _pumpCheckout(tester, vm: mockVm, store: mockStore);

      expect(find.text('Payment'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('T102 renders order summary card with task title', (
      tester,
    ) async {
      await _pumpCheckout(tester, vm: mockVm, store: mockStore);

      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text(_taskTitle), findsOneWidget);
    });

    testWidgets('T103 renders booking note section with label and text field', (
      tester,
    ) async {
      await _pumpCheckout(tester, vm: mockVm, store: mockStore);

      expect(find.text('Booking Note'), findsOneWidget);
      expect(
        find.text('Add requirements or extra details for the provider'),
        findsOneWidget,
      );
    });

    testWidgets('T104 renders payment details header', (tester) async {
      await _pumpCheckout(tester, vm: mockVm, store: mockStore);

      expect(find.text('Payment Details'), findsOneWidget);
    });

    testWidgets('T105 shows demo mode banner when isDemoPaymentMode is true', (
      tester,
    ) async {
      await _pumpCheckout(tester, vm: mockVm, store: mockStore);

      expect(
        find.text('Demo mode \u2014 local test card fields are enabled'),
        findsOneWidget,
      );
    });

    testWidgets(
      'T106 shows card input fields in demo mode (card number, name, expiry, CVV)',
      (tester) async {
        await _pumpCheckout(tester, vm: mockVm, store: mockStore);

        expect(find.text('Card Number'), findsOneWidget);
        expect(find.text('Cardholder Name'), findsOneWidget);
        expect(find.text('Expiry'), findsOneWidget);
        expect(find.text('CVV'), findsOneWidget);
      },
    );

    testWidgets('T107 shows QiCard info in non-demo mode', (tester) async {
      _stubNonDemoState(mockVm);
      await _pumpCheckout(tester, vm: mockVm, store: mockStore);

      expect(
        find.text(
          'QiCard mode is active. After tapping Pay, you will complete '
          'card validation securely on the QiCard payment page.',
        ),
        findsOneWidget,
      );
      // Demo card fields should NOT appear
      expect(find.text('Card Number'), findsNothing);
      expect(find.text('CVV'), findsNothing);
    });

    testWidgets('T108 renders pay button with formatted price', (tester) async {
      await _pumpCheckout(tester, vm: mockVm, store: mockStore);

      // 25000 => "Pay 25K IQD"
      expect(find.text('Pay 25K IQD'), findsOneWidget);
    });

    testWidgets('T109 renders security footer text', (tester) async {
      await _pumpCheckout(tester, vm: mockVm, store: mockStore);

      // Scroll down to ensure footer is visible
      await tester.ensureVisible(
        find.text('Secured payment \u00b7 Funds held in escrow'),
      );
      await tester.pump();

      expect(
        find.text('Secured payment \u00b7 Funds held in escrow'),
        findsOneWidget,
      );
    });

    // ── Interaction ────────────────────────────────────────────────────

    testWidgets('T110 pay button calls createPaymentForBooking when tapped', (
      tester,
    ) async {
      _stubCreatePayment(mockVm, answer: (_) async => _noFormResult);

      await _pumpCheckout(tester, vm: mockVm, store: mockStore);
      await _scrollAndTapPayButton(tester);
      await tester.pumpAndSettle();

      verify(
        () => mockVm.createPaymentForBooking(
          taskId: _taskId,
          note: any(named: 'note'),
          packageId: any(named: 'packageId'),
          requirements: any(named: 'requirements'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).called(1);
    });

    testWidgets('T111 shows processing state with spinner when processing', (
      tester,
    ) async {
      // Use a Completer that never resolves during the assertion phase.
      // Return a result WITHOUT formUrl so the async code won't attempt
      // webview navigation even if the completer does eventually resolve.
      final neverComplete = Completer<QiCardCreatePaymentResult>();

      _stubCreatePayment(mockVm, answer: (_) => neverComplete.future);

      await _pumpCheckout(tester, vm: mockVm, store: mockStore);
      await _scrollAndTapPayButton(tester);

      // Should show spinner and processing text
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Processing Payment...'), findsOneWidget);

      // Complete with a no-form result to avoid webview navigation
      neverComplete.complete(_noFormResult);
      await tester.pumpAndSettle();
    });

    testWidgets('T112 shows error container when error occurs', (tester) async {
      _stubCreatePayment(
        mockVm,
        answer: (_) async => const QiCardCreatePaymentResult(
          error: 'Failed to create booking payment.',
          errorCode: 'BOOKING_PAYMENT_CREATE_FAILED',
        ),
      );
      when(
        () => mockVm.bookingsError,
      ).thenReturn('Failed to create booking payment.');

      await _pumpCheckout(tester, vm: mockVm, store: mockStore);
      await _scrollAndTapPayButton(tester);
      await tester.pumpAndSettle();

      // Scroll to ensure the error is visible
      await tester.ensureVisible(find.byIcon(Icons.error_outline));
      await tester.pump();

      // Error container with red icon should appear
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to create booking payment.'), findsOneWidget);
    });

    testWidgets('T113 error displays user-friendly message not raw exception', (
      tester,
    ) async {
      _stubCreatePaymentThrows(
        mockVm,
        e: Exception('SocketException: Connection refused'),
      );
      when(
        () => mockVm.bookingsError,
      ).thenReturn('Payment failed. Please try again.');

      await _pumpCheckout(tester, vm: mockVm, store: mockStore);
      await _scrollAndTapPayButton(tester);
      await tester.pumpAndSettle();

      // Should show the user-friendly fallback, not the raw exception
      expect(find.text('Payment failed. Please try again.'), findsOneWidget);
      expect(find.text('SocketException: Connection refused'), findsNothing);
    });

    testWidgets('T114 shows gateway confirmation text when awaiting', (
      tester,
    ) async {
      // Return a result with a formUrl and intentId. The screen sets
      // _awaitingGatewayConfirmation = true, then attempts Navigator.push
      // for PaymentWebViewScreen. In unit tests the webview platform is not
      // available, so the route build throws. We consume that error with
      // tester.takeException() and verify the awaiting UI was rendered
      // before the navigation attempt.
      _stubCreatePayment(
        mockVm,
        answer: (_) async => const QiCardCreatePaymentResult(
          bookingId: 'booking-1',
          formUrl: 'https://pay.test/form',
          correlationId: 'corr-1',
          intentId: 'intent-1',
          requestCorrelationId: 'req-1',
        ),
      );

      await _pumpCheckout(tester, vm: mockVm, store: mockStore);
      await _scrollAndTapPayButton(tester);
      // Allow the async createPaymentForBooking to resolve and the
      // setState(_awaitingGatewayConfirmation = true) to fire.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Consume the webview platform error so it does not fail the test.
      tester.takeException();

      // The button text changes to 'Waiting for confirmation...' when both
      // _processing and _awaitingGatewayConfirmation are true.
      expect(find.text('Waiting for confirmation...'), findsOneWidget);
    });

    testWidgets('T115 success state shows check icon and success text', (
      tester,
    ) async {
      // Drive the real PaymentCheckoutScreen to its success state by:
      // 1. Stubbing createPaymentForBooking to return a result WITH formUrl
      // 2. Using _AutoPopWebViewObserver to intercept the webview push and
      //    immediately pop with a success PaymentReturnArgs
      // 3. Stubbing recoverBookingPaymentWithRetries to return held status
      _stubSuccessPaymentFlow(mockVm);
      final observer = _AutoPopWebViewObserver();

      await _pumpCheckoutWithNav(
        tester,
        vm: mockVm,
        store: mockStore,
        observers: [observer],
      );

      // Tap the pay button to start the payment flow
      await _scrollAndTapPayButton(tester);

      // Pump several frames to let the async flow complete:
      // createPaymentForBooking → webview push/pop → handlePaymentReturn →
      // recoverBookingPaymentWithRetries → setState(_paymentSuccess = true).
      // Use short pumps so we land AFTER _paymentSuccess is set but BEFORE
      // the 1200ms auto-pop timer fires.
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Consume any platform exceptions from the webview route
      tester.takeException();

      // Assert success UI is rendered from the real _buildSuccess() method
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Payment Successful!'), findsOneWidget);

      // Pump past the remaining 1200ms delay + pop to drain pending timers
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('T116 success state shows Your booking has been created', (
      tester,
    ) async {
      _stubSuccessPaymentFlow(mockVm);
      final observer = _AutoPopWebViewObserver();

      await _pumpCheckoutWithNav(
        tester,
        vm: mockVm,
        store: mockStore,
        observers: [observer],
      );

      await _scrollAndTapPayButton(tester);

      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      tester.takeException();

      expect(find.text('Your booking has been created.'), findsOneWidget);

      // Drain the 1200ms auto-pop timer
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('T117 booking note text field accepts input', (tester) async {
      await _pumpCheckout(tester, vm: mockVm, store: mockStore);

      // The booking note field has a specific hint text
      final noteField = find.widgetWithText(
        TextField,
        'Add requirements or extra details for the provider',
      );
      expect(noteField, findsOneWidget);

      await tester.enterText(noteField, 'Please deliver in 3 days');
      await tester.pump();

      expect(find.text('Please deliver in 3 days'), findsOneWidget);
    });

    testWidgets('T118 pre-filled demo card fields have default values', (
      tester,
    ) async {
      await _pumpCheckout(tester, vm: mockVm, store: mockStore);

      // Default controller values set in the State constructor
      expect(find.text('4242 4242 4242 4242'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('12/28'), findsOneWidget);
      expect(find.text('123'), findsOneWidget);
    });

    // ── Extra coverage ─────────────────────────────────────────────────

    testWidgets('T119 pay button shows processing text while awaiting', (
      tester,
    ) async {
      // Use a Completer that does NOT resolve during the assertion window.
      // This keeps _processing = true so the button shows 'Processing
      // Payment...' instead of the idle pay label.
      final neverComplete = Completer<QiCardCreatePaymentResult>();
      _stubCreatePayment(mockVm, answer: (_) => neverComplete.future);

      await _pumpCheckout(tester, vm: mockVm, store: mockStore);
      await _scrollAndTapPayButton(tester);

      // After tapping, _processing is true: the button text changes.
      expect(find.text('Processing Payment...'), findsOneWidget);
      expect(find.text('Pay 25K IQD'), findsNothing);

      // Complete with a simple result to clean up dangling futures.
      neverComplete.complete(_noFormResult);
      await tester.pumpAndSettle();
    });

    testWidgets('T120 renders correct formatted price for small amounts', (
      tester,
    ) async {
      await _pumpCheckout(tester, vm: mockVm, store: mockStore, price: 500);

      // 500 => "Pay 500 IQD"
      expect(find.text('Pay 500 IQD'), findsOneWidget);
    });

    testWidgets('T121 error state still shows form elements', (tester) async {
      _stubCreatePayment(
        mockVm,
        answer: (_) async => const QiCardCreatePaymentResult(
          error: 'Payment could not be started. Please try again.',
          errorCode: 'BOOKING_PAYMENT_CREATE_FAILED',
        ),
      );
      when(
        () => mockVm.bookingsError,
      ).thenReturn('Payment could not be started. Please try again.');

      await _pumpCheckout(tester, vm: mockVm, store: mockStore);
      await _scrollAndTapPayButton(tester);
      await tester.pumpAndSettle();

      // Form elements should still be visible after error
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Booking Note'), findsOneWidget);
      expect(find.text('Payment Details'), findsOneWidget);
    });

    testWidgets('T122 shield icon is present in security footer', (
      tester,
    ) async {
      await _pumpCheckout(tester, vm: mockVm, store: mockStore);

      await tester.ensureVisible(find.byIcon(Icons.shield_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });
  });
}
