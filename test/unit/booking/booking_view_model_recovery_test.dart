import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/booking/data/booking_repository.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';
import 'package:sline_app/features/chat/data/chat_repository.dart';

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

void main() {
  group('BookingViewModel.recoverBookingPaymentWithRetries', () {
    late _MockBookingRepository bookingRepo;
    late _MockChatRepository chatRepo;
    late _MockPaymentService paymentService;
    late BookingViewModel viewModel;

    setUp(() {
      bookingRepo = _MockBookingRepository();
      chatRepo = _MockChatRepository();
      paymentService = _MockPaymentService();
      when(() => bookingRepo.getBookingById(any())).thenAnswer(
        (invocation) async => _booking(invocation.positionalArguments.first as String),
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

    test('stops retrying once payment becomes held', () async {
      when(
        () => paymentService.recoverBookingPayment(bookingId: 'booking-1'),
      ).thenAnswer((_) async => const QiCardRecoveryResult(
        bookingId: 'booking-1',
        paymentStatus: 'held',
        recoveryResult: 'applied',
      ));

      final result = await viewModel.recoverBookingPaymentWithRetries(
        bookingId: 'booking-1',
      );

      expect(result.paymentStatus, 'held');
      verify(
        () => paymentService.recoverBookingPayment(bookingId: 'booking-1'),
      ).called(1);
    });

    test('retries no_action responses until a later held status', () async {
      var callCount = 0;
      when(
        () => paymentService.recoverBookingPayment(bookingId: 'booking-2'),
      ).thenAnswer((_) async {
        callCount += 1;
        if (callCount < 3) {
          return const QiCardRecoveryResult(
            bookingId: 'booking-2',
            paymentStatus: 'unpaid',
            recoveryResult: 'no_action',
          );
        }
        return const QiCardRecoveryResult(
          bookingId: 'booking-2',
          paymentStatus: 'held',
          recoveryResult: 'applied',
        );
      });

      final result = await viewModel.recoverBookingPaymentWithRetries(
        bookingId: 'booking-2',
        delay: Duration.zero,
      );

      expect(result.paymentStatus, 'held');
      expect(callCount, 3);
    });

    test('returns terminal no_action after max attempts', () async {
      when(
        () => paymentService.recoverBookingPayment(bookingId: 'booking-3'),
      ).thenAnswer((_) async => const QiCardRecoveryResult(
        bookingId: 'booking-3',
        paymentStatus: 'unpaid',
        recoveryResult: 'no_action',
      ));

      final result = await viewModel.recoverBookingPaymentWithRetries(
        bookingId: 'booking-3',
        maxAttempts: 2,
        delay: Duration.zero,
      );

      expect(result.paymentStatus, 'unpaid');
      expect(result.recoveryResult, 'no_action');
      verify(
        () => paymentService.recoverBookingPayment(bookingId: 'booking-3'),
      ).called(2);
    });
  });
}
