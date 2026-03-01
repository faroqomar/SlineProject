import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/payment_pending_store.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/booking/data/booking_repository.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/models/payment_return_args.dart';
import 'package:sline_app/features/booking/view/payment_return_screen.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';
import 'package:sline_app/features/chat/data/chat_repository.dart';

import '../../test_support/pump_app.dart';

class _MockBookingRepository extends Mock implements BookingRepository {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockPaymentService extends Mock implements PaymentService {}

BookingModel _booking(String id) {
  return BookingModel(
    id: id,
    taskId: 'task-1',
    providerId: 'provider-1',
    clientId: 'client-1',
    slotId: null,
    status: BookingStatus.pending,
    paymentStatus: PaymentStatus.unpaid,
    note: null,
    price: 100,
    createdAtUtc: DateTime.utc(2026, 3, 1),
  );
}

Future<void> _pumpReturnScreen(
  WidgetTester tester, {
  required BookingViewModel viewModel,
  required PaymentPendingStore pendingStore,
  required PaymentReturnArgs args,
}) async {
  await pumpApp(
    tester,
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BookingViewModel>.value(value: viewModel),
        Provider<PaymentPendingStore>.value(value: pendingStore),
      ],
      child: PaymentReturnScreen(initialArgs: args),
    ),
  );
  await tester.pump();
}

void main() {
  group('PaymentReturnScreen', () {
    late _MockBookingRepository bookingRepo;
    late _MockChatRepository chatRepo;
    late _MockPaymentService paymentService;
    late BookingViewModel viewModel;
    late PaymentPendingStore pendingStore;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      pendingStore = PaymentPendingStore(prefs);
      bookingRepo = _MockBookingRepository();
      chatRepo = _MockChatRepository();
      paymentService = _MockPaymentService();
      when(() => bookingRepo.getBookingById(any())).thenAnswer(
        (invocation) async =>
            _booking(invocation.positionalArguments.first as String),
      );
      viewModel = BookingViewModel(
        repo: bookingRepo,
        chatRepository: chatRepo,
        paymentService: paymentService,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    testWidgets('successful callback triggers recovery and success UI', (
      tester,
    ) async {
      await pendingStore.save(
        PendingPaymentContext(
          bookingId: 'booking-1',
          correlationId: 'corr-1',
          provider: 'qicard',
          startedAt: DateTime.utc(2026, 3, 1),
          entityType: 'booking',
          callbackHosts: const <String>{'sline.app'},
        ),
      );
      when(
        () => paymentService.recoverBookingPayment(bookingId: 'booking-1'),
      ).thenAnswer(
        (_) async => const QiCardRecoveryResult(
          bookingId: 'booking-1',
          paymentStatus: 'held',
          recoveryResult: 'applied',
        ),
      );

      await _pumpReturnScreen(
        tester,
        viewModel: viewModel,
        pendingStore: pendingStore,
        args: PaymentReturnArgs(
          status: 'SUCCESS',
          bookingId: 'booking-1',
          correlationId: 'corr-1',
          rawUri: Uri.parse(
            'https://sline.app/payment/success?booking_id=booking-1&correlation_id=corr-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Complete'), findsOneWidget);
      expect(
        find.text('Payment confirmed. Your booking is ready.'),
        findsOneWidget,
      );
    });

    testWidgets('failed recovery shows retryable error UI', (tester) async {
      await pendingStore.save(
        PendingPaymentContext(
          bookingId: 'booking-2',
          correlationId: 'corr-2',
          provider: 'qicard',
          startedAt: DateTime.utc(2026, 3, 1),
          entityType: 'booking',
          callbackHosts: const <String>{'sline.app'},
        ),
      );
      when(
        () => paymentService.recoverBookingPayment(bookingId: 'booking-2'),
      ).thenAnswer(
        (_) async => const QiCardRecoveryResult(
          bookingId: 'booking-2',
          paymentStatus: 'unpaid',
          recoveryResult: 'no_action',
        ),
      );

      await _pumpReturnScreen(
        tester,
        viewModel: viewModel,
        pendingStore: pendingStore,
        args: PaymentReturnArgs(
          status: 'SUCCESS',
          bookingId: 'booking-2',
          correlationId: 'corr-2',
          rawUri: Uri.parse(
            'https://sline.app/payment/success?booking_id=booking-2&correlation_id=corr-2',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Update'), findsOneWidget);
      expect(find.text('Retry Recovery'), findsOneWidget);
    });
  });
}
