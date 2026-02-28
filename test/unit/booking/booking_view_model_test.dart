import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/booking/data/booking_repository.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';
import 'package:sline_app/features/chat/data/chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockBookingRepository extends Mock implements BookingRepository {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockPaymentService extends Mock implements PaymentService {}

BookingModel _booking({
  required String id,
  required DateTime createdAtUtc,
  BookingStatus status = BookingStatus.pending,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
  DateTime? dueAtUtc,
  int? deliveryDays,
}) {
  return BookingModel(
    id: id,
    taskId: 'task-1',
    providerId: 'provider-1',
    clientId: 'client-1',
    slotId: null,
    status: status,
    paymentStatus: paymentStatus,
    note: null,
    price: 100.0,
    createdAtUtc: createdAtUtc,
    dueAtUtc: dueAtUtc,
    deliveryDays: deliveryDays,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(BookingStatus.pending);
  });

  group('BookingViewModel slotless booking flow', () {
    late _MockBookingRepository bookingRepo;
    late _MockChatRepository chatRepo;
    late _MockPaymentService paymentService;
    late BookingViewModel viewModel;

    setUp(() {
      bookingRepo = _MockBookingRepository();
      chatRepo = _MockChatRepository();
      paymentService = _MockPaymentService();
      viewModel = BookingViewModel(
        repo: bookingRepo,
        chatRepository: chatRepo,
        paymentService: paymentService,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    test(
      'updateBookingStatus maps Postgres 23505 to already booked message',
      () async {
        when(
          () => bookingRepo.updateBookingStatus(
            bookingId: 'booking-1',
            newStatus: BookingStatus.confirmed,
          ),
        ).thenThrow(
          const PostgrestException(
            message: 'duplicate key value violates unique constraint',
            code: '23505',
          ),
        );

        final result = await viewModel.updateBookingStatus(
          bookingId: 'booking-1',
          newStatus: BookingStatus.confirmed,
        );

        expect(result, isFalse);
        expect(viewModel.bookingsError, isNotNull);
        expect(viewModel.bookingsError!.toLowerCase(), contains('already'));
        expect(viewModel.bookingsError!.toLowerCase(), contains('booked'));
      },
    );

    test(
      'createPaymentForBooking maps task-not-bookable to user-facing copy',
      () async {
        when(
          () => paymentService.createPaymentForBooking(
            taskId: 'task-1',
            note: 'Need it fast',
            packageId: 'Premium',
            requirements: <String, dynamic>{'delivery': 'rush'},
          ),
        ).thenAnswer(
          (_) async => const QiCardCreatePaymentResult(
            error: 'BOOKING_TASK_NOT_BOOKABLE',
            errorCode: 'BOOKING_PAYMENT_CREATE_FAILED',
          ),
        );

        final result = await viewModel.createPaymentForBooking(
          taskId: 'task-1',
          note: 'Need it fast',
          packageId: 'Premium',
          requirements: <String, dynamic>{'delivery': 'rush'},
        );

        expect(result.isSuccess, isFalse);
        expect(
          viewModel.bookingsError,
          'This booking is not currently available.',
        );
      },
    );

    test(
      'createPaymentForBooking maps duplicate active booking to user-facing copy',
      () async {
        when(
          () => paymentService.createPaymentForBooking(
            taskId: 'task-1',
            note: null,
            packageId: 'Premium',
            requirements: const <String, dynamic>{},
          ),
        ).thenAnswer(
          (_) async => const QiCardCreatePaymentResult(
            error: 'BOOKING_ALREADY_EXISTS_FOR_CLIENT',
            errorCode: 'BOOKING_PAYMENT_CREATE_FAILED',
          ),
        );

        final result = await viewModel.createPaymentForBooking(
          taskId: 'task-1',
          packageId: 'Premium',
          requirements: const <String, dynamic>{},
        );

        expect(result.isSuccess, isFalse);
        expect(
          viewModel.bookingsError,
          'You already have an active booking for this service.',
        );
      },
    );

    test(
      'processPayment failure sets bookingsError and clears processing flag',
      () async {
        when(
          () => paymentService.processPayment(
            amount: 25.0,
            currency: 'USD',
            description: 'Booking test payment',
          ),
        ).thenThrow(Exception('gateway timeout'));

        final txnId = await viewModel.processPayment(
          amount: 25.0,
          currency: 'USD',
          description: 'Booking test payment',
        );

        expect(txnId, isNull);
        expect(viewModel.isProcessingPayment, isFalse);
        expect(viewModel.bookingsError, isNotNull);
        expect(
          viewModel.bookingsError!.toLowerCase(),
          contains('gateway timeout'),
        );
      },
    );

    test('markDelivered performs one repository mutation', () async {
      when(
        () => bookingRepo.markDelivered('booking-1'),
      ).thenAnswer((_) async {});
      when(() => bookingRepo.getBookingById('booking-1')).thenAnswer(
        (_) async => _booking(
          id: 'booking-1',
          createdAtUtc: DateTime.utc(2026, 2, 1, 10),
          status: BookingStatus.delivered,
          dueAtUtc: DateTime.utc(2026, 2, 6, 10),
          deliveryDays: 5,
        ),
      );

      await viewModel.markDelivered('booking-1');

      verify(() => bookingRepo.markDelivered('booking-1')).called(1);
      verify(() => bookingRepo.getBookingById('booking-1')).called(1);
      verifyNever(
        () => bookingRepo.updateBookingStatus(
          bookingId: any(named: 'bookingId'),
          newStatus: any(named: 'newStatus'),
        ),
      );
    });
  });
}
