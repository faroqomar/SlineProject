import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/booking/data/booking_repository.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/models/slot_model.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';
import 'package:sline_app/features/chat/data/chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockBookingRepository extends Mock implements BookingRepository {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockPaymentService extends Mock implements PaymentService {}

SlotModel _slot({required String id, required DateTime startsAtUtc}) {
  return SlotModel(
    id: id,
    providerId: 'provider-1',
    startsAtUtc: startsAtUtc,
    endsAtUtc: startsAtUtc.add(const Duration(hours: 1)),
    isBlocked: false,
    createdAtUtc: startsAtUtc.subtract(const Duration(days: 1)),
  );
}

BookingModel _booking({
  required String id,
  required DateTime createdAtUtc,
  BookingStatus status = BookingStatus.pending,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
}) {
  return BookingModel(
    id: id,
    taskId: 'task-1',
    providerId: 'provider-1',
    clientId: 'client-1',
    slotId: 'slot-1',
    status: status,
    paymentStatus: paymentStatus,
    note: null,
    price: 100.0,
    createdAtUtc: createdAtUtc,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026, 1, 1));
    registerFallbackValue(BookingStatus.pending);
  });

  group('BookingViewModel T14-T18', () {
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

    test('T14 Postgres 23505 maps to already exists/booked message', () async {
      when(
        () => bookingRepo.bookSlot(
          taskId: 'task-1',
          slotId: 'slot-1',
          note: null,
          providerId: 'provider-1',
          price: 100.0,
          packageId: null,
          requirements: null,
          status: BookingStatus.pending,
        ),
      ).thenThrow(
        const PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: '23505',
        ),
      );

      final result = await viewModel.bookSlot(
        taskId: 'task-1',
        slotId: 'slot-1',
        providerId: 'provider-1',
        price: 100.0,
      );

      expect(result, isNull);
      expect(viewModel.bookingsError, isNotNull);
      expect(viewModel.bookingsError!.toLowerCase(), contains('already'));
      expect(viewModel.bookingsError!.toLowerCase(), contains('booked'));
    });

    test('T15 loadSlots sets list, cursor, and hasMore correctly', () async {
      final base = DateTime.utc(2026, 2, 1, 8);
      final slots = List<SlotModel>.generate(
        50,
        (index) => _slot(
          id: 'slot-${index + 1}',
          startsAtUtc: base.add(Duration(hours: index)),
        ),
      );

      when(
        () => bookingRepo.listSlots(
          providerId: 'provider-1',
          fromUtc: null,
          toUtc: null,
          limit: 50,
        ),
      ).thenAnswer((_) async => slots);

      await viewModel.loadSlots(providerId: 'provider-1');

      expect(viewModel.slots.map((s) => s.id).toList(), slots.map((s) => s.id));
      expect(
        viewModel.slotsCursor,
        slots.last.startsAtUtc.toUtc().toIso8601String(),
      );
      expect(viewModel.slotsHasMore, isTrue);
      expect(viewModel.slotsLoading, isFalse);
      expect(viewModel.slotsError, isNull);
    });

    test(
      'T16 loadMoreSlots guard prevents request when loading/no cursor/no more',
      () async {
        final providerId = 'provider-1';

        // Subcase 1: slotsLoading == true
        final repoLoading = _MockBookingRepository();
        final vmLoading = BookingViewModel(
          repo: repoLoading,
          chatRepository: _MockChatRepository(),
          paymentService: _MockPaymentService(),
        );
        final loadingCompleter = Completer<List<SlotModel>>();
        var loadingCalls = 0;

        when(
          () => repoLoading.listSlots(
            providerId: providerId,
            fromUtc: null,
            toUtc: null,
            limit: 50,
          ),
        ).thenAnswer((_) {
          loadingCalls += 1;
          return loadingCompleter.future;
        });

        final loadFuture = vmLoading.loadSlots(providerId: providerId);
        expect(vmLoading.slotsLoading, isTrue);

        await vmLoading.loadMoreSlots(providerId: providerId);
        expect(loadingCalls, 1);

        loadingCompleter.complete(<SlotModel>[]);
        await loadFuture;
        vmLoading.dispose();

        // Subcase 2: slotsCursor == null
        final repoNoCursor = _MockBookingRepository();
        final vmNoCursor = BookingViewModel(
          repo: repoNoCursor,
          chatRepository: _MockChatRepository(),
          paymentService: _MockPaymentService(),
        );

        await vmNoCursor.loadMoreSlots(providerId: providerId);
        verifyNever(
          () => repoNoCursor.listSlots(providerId: providerId, limit: 50),
        );
        vmNoCursor.dispose();

        // Subcase 3: slotsHasMore == false
        final repoNoMore = _MockBookingRepository();
        final vmNoMore = BookingViewModel(
          repo: repoNoMore,
          chatRepository: _MockChatRepository(),
          paymentService: _MockPaymentService(),
        );
        var noMoreCalls = 0;

        when(
          () => repoNoMore.listSlots(
            providerId: providerId,
            fromUtc: null,
            toUtc: null,
            limit: 50,
          ),
        ).thenAnswer((_) async {
          noMoreCalls += 1;
          return <SlotModel>[
            _slot(id: 'slot-short', startsAtUtc: DateTime.utc(2026, 2, 1, 8)),
          ];
        });

        await vmNoMore.loadSlots(providerId: providerId);
        expect(vmNoMore.slotsCursor, isNotNull);
        expect(vmNoMore.slotsHasMore, isFalse);

        await vmNoMore.loadMoreSlots(providerId: providerId);
        expect(noMoreCalls, 1);
        vmNoMore.dispose();
      },
    );

    test(
      'T17 bookSlot with null price uses default and prepends client list',
      () async {
        final existing = _booking(
          id: 'booking-existing',
          createdAtUtc: DateTime.utc(2026, 2, 1, 9),
        );
        final created = _booking(
          id: 'booking-new',
          createdAtUtc: DateTime.utc(2026, 2, 1, 10),
        );
        double? capturedPrice;

        when(
          () => bookingRepo.listBookingsAsClient(limit: 50),
        ).thenAnswer((_) async => <BookingModel>[existing]);

        when(
          () => bookingRepo.bookSlot(
            taskId: 'task-1',
            slotId: 'slot-1',
            note: null,
            providerId: 'provider-1',
            price: any(named: 'price'),
            packageId: null,
            requirements: null,
            status: BookingStatus.pending,
          ),
        ).thenAnswer((invocation) async {
          capturedPrice = invocation.namedArguments[#price] as double;
          return created;
        });

        await viewModel.loadBookingsAsClient();
        final result = await viewModel.bookSlot(
          taskId: 'task-1',
          slotId: 'slot-1',
          providerId: 'provider-1',
          price: null,
        );

        expect(result?.id, 'booking-new');
        expect(capturedPrice, 100.0);
        expect(viewModel.bookingsAsClient.map((b) => b.id).toList(), [
          'booking-new',
          'booking-existing',
        ]);
        expect(viewModel.bookingsError, isNull);
      },
    );

    test(
      'T18 processPayment failure sets bookingsError and clears processing flag',
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
  });
}
