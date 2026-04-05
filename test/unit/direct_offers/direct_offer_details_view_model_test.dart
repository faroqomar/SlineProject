import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/models/app_failure.dart';
import 'package:sline_app/core/models/view_state.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/direct_offers/models/direct_offer_model.dart';
import 'package:sline_app/features/direct_offers/viewmodels/direct_offer_details_view_model.dart';

import '../../helpers/mock_services.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kClientId = 'client-1';
const _kFreelancerId = 'freelancer-1';
const _kOfferId = 'offer-42';
const _kConversationId = 'conv-1';

DirectOffer _offer({
  String id = _kOfferId,
  String status = 'sent',
  String paymentStatus = 'unpaid',
  String clientId = _kClientId,
  String freelancerId = _kFreelancerId,
  String conversationId = _kConversationId,
}) {
  return DirectOffer(
    id: id,
    conversationId: conversationId,
    clientId: clientId,
    freelancerId: freelancerId,
    price: 5000,
    days: 3,
    status: status,
    paymentStatus: paymentStatus,
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );
}

DirectOfferDetailsViewModel _buildVm({
  required MockDirectOffersService service,
  required MockPaymentService paymentService,
  String? currentUserId,
  String? conversationId,
}) {
  return DirectOfferDetailsViewModel(
    offerId: _kOfferId,
    conversationId: conversationId,
    currentUserId: currentUserId,
    directOffersService: service,
    paymentService: paymentService,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockDirectOffersService mockService;
  late MockPaymentService mockPayment;

  setUp(() {
    mockService = MockDirectOffersService();
    mockPayment = MockPaymentService();
  });

  // ── Construction ─────────────────────────────────────────────────────

  group('construction', () {
    test('initial state is ViewLoading', () {
      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
      );
      // The default field value in the VM is `ViewLoading`.
      expect(vm.state, isA<ViewLoading<DirectOffer>>());
      expect(vm.isLoading, true);
      expect(vm.offer, isNull);
      expect(vm.error, isNull);
      vm.dispose();
    });
  });

  // ── loadOffer ────────────────────────────────────────────────────────

  group('loadOffer', () {
    test('happy path transitions Loading -> Loaded with correct data', () async {
      final expected = _offer(status: 'active', paymentStatus: 'held');
      when(() => mockService.getOffer(_kOfferId))
          .thenAnswer((_) async => expected);

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );

      await vm.loadOffer();

      expect(vm.state, isA<ViewLoaded<DirectOffer>>());
      final loaded = vm.state as ViewLoaded<DirectOffer>;
      expect(loaded.data.id, _kOfferId);
      expect(loaded.data.status, 'active');
      expect(vm.offer, isNotNull);
      expect(vm.offer!.id, _kOfferId);
      expect(vm.isLoading, false);
      expect(vm.error, isNull);
      vm.dispose();
    });

    test('null response transitions to ViewFailed with OFFER_NOT_FOUND', () async {
      when(() => mockService.getOffer(_kOfferId))
          .thenAnswer((_) async => null);

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
      );

      await vm.loadOffer();

      expect(vm.state, isA<ViewFailed<DirectOffer>>());
      final failed = vm.state as ViewFailed<DirectOffer>;
      expect(failed.failure, isA<BusinessFailure>());
      expect((failed.failure as BusinessFailure).code, 'OFFER_NOT_FOUND');
      expect(vm.error, isNotNull);
      vm.dispose();
    });

    test('service exception transitions to ViewFailed with LOAD_FAILED', () async {
      when(() => mockService.getOffer(_kOfferId))
          .thenThrow(Exception('DB unavailable'));

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
      );

      await vm.loadOffer();

      expect(vm.state, isA<ViewFailed<DirectOffer>>());
      final failed = vm.state as ViewFailed<DirectOffer>;
      expect(failed.failure, isA<BusinessFailure>());
      expect((failed.failure as BusinessFailure).code, 'LOAD_FAILED');
      expect(vm.error, contains('DB unavailable'));
      vm.dispose();
    });

    test('network error results in ViewFailed', () async {
      when(() => mockService.getOffer(_kOfferId)).thenThrow(
        Exception('SocketException: Connection refused'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
      );

      await vm.loadOffer();

      expect(vm.state, isA<ViewFailed<DirectOffer>>());
      final failed = vm.state as ViewFailed<DirectOffer>;
      expect(failed.failure.userMessage, contains('SocketException'));
      vm.dispose();
    });
  });

  // ── canPay getter ────────────────────────────────────────────────────

  group('canPay', () {
    test('returns true when client and offer is accepted/unpaid', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'accepted', paymentStatus: 'unpaid'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();

      expect(vm.canPay, true);
      vm.dispose();
    });

    test('returns false when offer status is not accepted', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'active', paymentStatus: 'held'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();

      expect(vm.canPay, false);
      vm.dispose();
    });

    test('returns false when user is freelancer (not client)', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'accepted', paymentStatus: 'unpaid'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kFreelancerId,
      );
      await vm.loadOffer();

      expect(vm.canPay, false);
      vm.dispose();
    });
  });

  // ── canCancel getter ─────────────────────────────────────────────────

  group('canCancel', () {
    test('returns true when client and offer accepted/unpaid', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'accepted', paymentStatus: 'unpaid'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();

      expect(vm.canCancel, true);
      vm.dispose();
    });

    test('returns false when offer is active', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'active', paymentStatus: 'held'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();

      expect(vm.canCancel, false);
      vm.dispose();
    });
  });

  // ── canMarkDelivered getter ──────────────────────────────────────────

  group('canMarkDelivered', () {
    test('returns true when freelancer and offer is active', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'active', paymentStatus: 'held'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kFreelancerId,
      );
      await vm.loadOffer();

      expect(vm.canMarkDelivered, true);
      vm.dispose();
    });

    test('returns false when user is client', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'active', paymentStatus: 'held'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();

      expect(vm.canMarkDelivered, false);
      vm.dispose();
    });

    test('returns false when offer is not active', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'delivered', paymentStatus: 'held'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kFreelancerId,
      );
      await vm.loadOffer();

      expect(vm.canMarkDelivered, false);
      vm.dispose();
    });
  });

  // ── cancelOffer ──────────────────────────────────────────────────────

  group('cancelOffer', () {
    test('happy path calls service and reloads', () async {
      // First load: accepted/unpaid (canCancel == true)
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'accepted', paymentStatus: 'unpaid'),
      );
      when(() => mockService.cancelAcceptedOffer(_kOfferId))
          .thenAnswer((_) async {});

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();
      expect(vm.canCancel, true);

      // After cancel, reload returns canceled offer
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'canceled', paymentStatus: 'unpaid'),
      );
      await vm.cancelOffer();

      verify(() => mockService.cancelAcceptedOffer(_kOfferId)).called(1);
      // getOffer called once in initial loadOffer + once in reload after cancel
      verify(() => mockService.getOffer(_kOfferId)).called(2);
      expect(vm.offer!.status, 'canceled');
      expect(vm.cancelInProgress, false);
      vm.dispose();
    });

    test('error rethrows and resets cancelInProgress', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'accepted', paymentStatus: 'unpaid'),
      );
      when(() => mockService.cancelAcceptedOffer(_kOfferId))
          .thenThrow(Exception('Server error'));

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();

      await expectLater(vm.cancelOffer(), throwsException);
      expect(vm.cancelInProgress, false);
      vm.dispose();
    });
  });

  // ── markDelivered ────────────────────────────────────────────────────

  group('markDelivered', () {
    test('happy path calls service and reloads', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'active', paymentStatus: 'held'),
      );
      when(() => mockService.markDelivered(_kOfferId))
          .thenAnswer((_) async {});

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kFreelancerId,
      );
      await vm.loadOffer();
      expect(vm.canMarkDelivered, true);

      // After markDelivered, reload returns delivered offer
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'delivered', paymentStatus: 'held'),
      );
      await vm.markDelivered();

      verify(() => mockService.markDelivered(_kOfferId)).called(1);
      expect(vm.offer!.status, 'delivered');
      expect(vm.markDeliveredInProgress, false);
      vm.dispose();
    });

    test('error rethrows and resets markDeliveredInProgress', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'active', paymentStatus: 'held'),
      );
      when(() => mockService.markDelivered(_kOfferId))
          .thenThrow(Exception('Delivery failed'));

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kFreelancerId,
      );
      await vm.loadOffer();

      await expectLater(vm.markDelivered(), throwsException);
      expect(vm.markDeliveredInProgress, false);
      vm.dispose();
    });
  });

  // ── completeOffer ────────────────────────────────────────────────────

  group('completeOffer', () {
    test('happy path calls service and reloads', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'delivered', paymentStatus: 'held'),
      );
      when(() => mockService.completeOffer(_kOfferId))
          .thenAnswer((_) async {});

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();
      expect(vm.canComplete, true);

      // After complete, reload returns completed offer
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'completed', paymentStatus: 'released'),
      );
      await vm.completeOffer();

      verify(() => mockService.completeOffer(_kOfferId)).called(1);
      expect(vm.offer!.status, 'completed');
      expect(vm.completeInProgress, false);
      vm.dispose();
    });

    test('error rethrows and resets completeInProgress', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'delivered', paymentStatus: 'held'),
      );
      when(() => mockService.completeOffer(_kOfferId))
          .thenThrow(Exception('Complete failed'));

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();

      await expectLater(vm.completeOffer(), throwsException);
      expect(vm.completeInProgress, false);
      vm.dispose();
    });
  });

  // ── payForOffer (createPaymentForCard) ───────────────────────────────

  group('createPaymentForCard', () {
    test('calls payment service with correct args and returns result', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'accepted', paymentStatus: 'unpaid'),
      );
      when(
        () => mockPayment.createPaymentForDirectOffer(
          offerId: any(named: 'offerId'),
          amount: any(named: 'amount'),
          finishUrl: any(named: 'finishUrl'),
        ),
      ).thenAnswer(
        (_) async => const QiCardDirectOfferPaymentResult(
          offerId: _kOfferId,
          formUrl: 'https://pay.qicard.com/form',
          paymentRequestId: 'req-1',
          amount: 5000,
        ),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();

      final result = await vm.createPaymentForCard();

      expect(result.isSuccess, true);
      expect(result.formUrl, 'https://pay.qicard.com/form');
      verify(
        () => mockPayment.createPaymentForDirectOffer(
          offerId: _kOfferId,
          amount: 5000.0,
          finishUrl: any(named: 'finishUrl'),
        ),
      ).called(1);
      expect(vm.cardPaymentInProgress, false);
      vm.dispose();
    });

    test('returns error result when offer is null', () async {
      when(() => mockService.getOffer(_kOfferId))
          .thenAnswer((_) async => null);

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();

      final result = await vm.createPaymentForCard();

      expect(result.isSuccess, false);
      expect(result.errorCode, 'INVALID_STATE');
      verifyNever(
        () => mockPayment.createPaymentForDirectOffer(
          offerId: any(named: 'offerId'),
          amount: any(named: 'amount'),
          finishUrl: any(named: 'finishUrl'),
        ),
      );
      vm.dispose();
    });
  });

  // ── canComplete getter ───────────────────────────────────────────────

  group('canComplete', () {
    test('returns true when client and offer delivered with held payment', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'delivered', paymentStatus: 'held'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();

      expect(vm.canComplete, true);
      vm.dispose();
    });

    test('returns false when payment is not held', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'delivered', paymentStatus: 'unpaid'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();

      expect(vm.canComplete, false);
      vm.dispose();
    });
  });

  // ── effectiveConversationId / canOpenChat ─────────────────────────────

  group('effectiveConversationId', () {
    test('returns constructor conversationId when provided', () {
      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        conversationId: 'from-ctor',
      );
      expect(vm.effectiveConversationId, 'from-ctor');
      expect(vm.canOpenChat, true);
      vm.dispose();
    });

    test('falls back to offer conversationId after load', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(conversationId: 'from-offer'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
      );
      await vm.loadOffer();

      expect(vm.effectiveConversationId, 'from-offer');
      expect(vm.canOpenChat, true);
      vm.dispose();
    });
  });

  // ── Guard: no-op when preconditions unmet ────────────────────────────

  group('action guards', () {
    test('cancelOffer is no-op when canCancel is false', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'active', paymentStatus: 'held'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();
      expect(vm.canCancel, false);

      await vm.cancelOffer(); // should be no-op

      verifyNever(() => mockService.cancelAcceptedOffer(any()));
      vm.dispose();
    });

    test('markDelivered is no-op when canMarkDelivered is false', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'delivered', paymentStatus: 'held'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kFreelancerId,
      );
      await vm.loadOffer();
      expect(vm.canMarkDelivered, false);

      await vm.markDelivered(); // should be no-op

      verifyNever(() => mockService.markDelivered(any()));
      vm.dispose();
    });

    test('completeOffer is no-op when canComplete is false', () async {
      when(() => mockService.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'active', paymentStatus: 'held'),
      );

      final vm = _buildVm(
        service: mockService,
        paymentService: mockPayment,
        currentUserId: _kClientId,
      );
      await vm.loadOffer();
      expect(vm.canComplete, false);

      await vm.completeOffer(); // should be no-op

      verifyNever(() => mockService.completeOffer(any()));
      vm.dispose();
    });
  });
}
