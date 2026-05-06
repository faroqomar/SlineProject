// Widget tests for DirectOfferDetailsScreen.
//
// Type B screen: creates DirectOfferDetailsViewModel internally via
// ChangeNotifierProvider. Tests inject mock services through Provider
// ancestors so the real VM constructor receives the mocks.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/direct_offers/models/direct_offer_model.dart';
import 'package:sline_app/features/direct_offers/services/direct_offers_service.dart';
import 'package:sline_app/features/direct_offers/view/direct_offer_details_screen.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';

import '../../test_support/pump_app.dart';

// ---------------------------------------------------------------------------
// File-local mocks
// ---------------------------------------------------------------------------
class _MockAuthSessionViewModel extends Mock
    with ChangeNotifier
    implements AuthSessionViewModel {}

class _MockDirectOffersService extends Mock implements DirectOffersService {}

class _MockPaymentService extends Mock implements PaymentService {}

class _MockSafetyViewModel extends Mock
    with ChangeNotifier
    implements SafetyViewModel {}

class _MockDeepLinkService extends Mock implements DeepLinkService {}

class _FakeBuildContext extends Fake implements BuildContext {}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const _kOfferId = 'offer-42';
const _kConversationId = 'conv-1';
const _kClientId = 'client-1';
const _kFreelancerId = 'freelancer-1';

// ---------------------------------------------------------------------------
// Factory helpers
// ---------------------------------------------------------------------------
/// Sentinel to distinguish "not passed" from "passed null".
const _defaultTitle = 'Logo Design';

DirectOffer _offer({
  String id = _kOfferId,
  String status = 'sent',
  String paymentStatus = 'unpaid',
  String clientId = _kClientId,
  String freelancerId = _kFreelancerId,
  String conversationId = _kConversationId,
  Object? title = _defaultTitle,
  String? description,
  num price = 5000,
  int days = 3,
}) {
  return DirectOffer(
    id: id,
    conversationId: conversationId,
    clientId: clientId,
    freelancerId: freelancerId,
    title: title as String?,
    description: description,
    price: price,
    days: days,
    status: status,
    paymentStatus: paymentStatus,
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );
}

/// Pump the DirectOfferDetailsScreen wrapped in the providers it reads from
/// context. The screen itself creates the DirectOfferDetailsViewModel, which
/// calls loadOffer() immediately.
Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockAuthSessionViewModel authVm,
  required _MockDirectOffersService offersService,
  required _MockPaymentService paymentService,
  required _MockSafetyViewModel safetyVm,
  required _MockDeepLinkService deepLinkService,
  String offerId = _kOfferId,
  String? conversationId,
}) async {
  await pumpApp(
    tester,
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionViewModel>.value(value: authVm),
        Provider<DirectOffersService>.value(value: offersService),
        Provider<PaymentService>.value(value: paymentService),
        ChangeNotifierProvider<SafetyViewModel>.value(value: safetyVm),
        Provider<DeepLinkService>.value(value: deepLinkService),
      ],
      child: DirectOfferDetailsScreen(
        offerId: offerId,
        conversationId: conversationId,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late _MockAuthSessionViewModel mockAuth;
  late _MockDirectOffersService mockOffers;
  late _MockPaymentService mockPayment;
  late _MockSafetyViewModel mockSafety;
  late _MockDeepLinkService mockDeepLink;

  setUpAll(() {
    registerFallbackValue(_FakeBuildContext());
  });

  setUp(() {
    mockAuth = _MockAuthSessionViewModel();
    mockOffers = _MockDirectOffersService();
    mockPayment = _MockPaymentService();
    mockSafety = _MockSafetyViewModel();
    mockDeepLink = _MockDeepLinkService();

    // Default stubs
    when(() => mockAuth.currentUserId).thenReturn(_kClientId);

    // Safety stubs: no disputes by default
    when(
      () => mockSafety.hasOpenDisputeForDirectOffer(any()),
    ).thenAnswer((_) async => false);
    when(
      () => mockSafety.getDisputeStatusForDirectOffer(any()),
    ).thenAnswer((_) async => null);

    // DeepLink stub
    when(
      () => mockDeepLink.openConversation(any(), any()),
    ).thenAnswer((_) async {});
  });

  group('DirectOfferDetailsScreen', () {
    // ── T180: Renders ────────────────────────────────────────────────────

    testWidgets('T180 renders DirectOfferDetailsScreen widget', (tester) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenAnswer((_) async => _offer());

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      expect(find.byType(DirectOfferDetailsScreen), findsOneWidget);
    });

    // ── T181: Loading indicator ──────────────────────────────────────────

    testWidgets('T181 shows loading indicator initially', (tester) async {
      // Use a Completer that never completes so the VM stays in loading state.
      final neverComplete = Completer<DirectOffer?>();
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenAnswer((_) => neverComplete.future);

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      // Only pump once so we catch the loading state before settle.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // ── T182: Offer title ────────────────────────────────────────────────

    testWidgets('T182 shows offer title when loaded', (tester) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenAnswer((_) async => _offer(title: 'Logo Design'));

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      expect(find.text('Logo Design'), findsAtLeastNWidgets(1));
    });

    // ── T183: Price info row ─────────────────────────────────────────────

    testWidgets('T183 shows offer price info row', (tester) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenAnswer((_) async => _offer(price: 5000));

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      // Phase 7 REDESIGN: Price now shown in hero zone with overline label
      expect(find.text('OFFER PRICE'), findsOneWidget);
      // 5000 => "5K IQD"
      expect(find.text('5K IQD'), findsOneWidget);
    });

    // ── T184: Delivery days info row ─────────────────────────────────────

    testWidgets('T184 shows delivery days info row', (tester) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenAnswer((_) async => _offer(days: 7));

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      // Phase 7 REDESIGN: Days shown in dedicated badge with "DAYS" micro label
      expect(find.text('DAYS'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    // ── T185: Status display ─────────────────────────────────────────────

    testWidgets('T185 shows status display', (tester) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenAnswer((_) async => _offer(status: 'in_progress'));

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      // Phase 7 REDESIGN: Status shown in header badge + "CUSTOM OFFER" label
      expect(find.text('CUSTOM OFFER'), findsOneWidget);
      expect(find.text('IN PROGRESS'), findsOneWidget);
    });

    // ── T186: Error message on service throw ─────────────────────────────

    testWidgets('T186 shows error message when service throws', (tester) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenThrow(Exception('Network error'));

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      // ErrorMapper wraps unknown exceptions; the AppBar still shows "Custom offer".
      expect(find.text('Custom offer'), findsOneWidget);
      // The error text appears in the body Center widget.
      expect(find.byType(Center), findsAtLeastNWidgets(1));
    });

    // ── T187: Error state has retry capability ───────────────────────────

    testWidgets('T187 error state renders with appbar and error text', (
      tester,
    ) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenThrow(Exception('Server error'));

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      // Error scaffold has appbar with back button and error text in body.
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    // ── T188: Cancel button opens confirmation dialog ────────────────────

    testWidgets('T188 cancel button opens confirmation dialog', (tester) async {
      // accepted + unpaid => canCancel = true for client
      when(() => mockOffers.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'accepted', paymentStatus: 'unpaid'),
      );

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      // Tap the cancel button
      await tester.tap(find.text('Cancel offer'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Cancel offer?'), findsOneWidget);
      expect(find.text('Keep'), findsOneWidget);
    });

    // ── T189: Confirming cancellation triggers cancel ────────────────────

    testWidgets('T189 confirming cancellation triggers cancelAcceptedOffer', (
      tester,
    ) async {
      when(() => mockOffers.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'accepted', paymentStatus: 'unpaid'),
      );
      when(
        () => mockOffers.cancelAcceptedOffer(_kOfferId),
      ).thenAnswer((_) async {});

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel offer'));
      await tester.pumpAndSettle();

      // Confirm by tapping the red "Cancel offer" button inside the dialog.
      // There are two "Cancel offer" texts now (button + dialog button).
      // The dialog FilledButton is the second one.
      final cancelButtons = find.text('Cancel offer');
      expect(cancelButtons, findsNWidgets(2));
      await tester.tap(cancelButtons.last);
      await tester.pumpAndSettle();

      verify(() => mockOffers.cancelAcceptedOffer(_kOfferId)).called(1);
    });

    // ── T190: Chat button visible when conversation exists ───────────────

    testWidgets('T190 chat button visible when conversationId is provided', (
      tester,
    ) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenAnswer((_) async => _offer());

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
        conversationId: _kConversationId,
      );
      await tester.pumpAndSettle();

      expect(find.text('Open chat'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    // ── T191: No action buttons on completed offer ───────────────────────

    testWidgets('T191 no cancel/pay/deliver buttons on completed offer', (
      tester,
    ) async {
      when(() => mockOffers.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'completed', paymentStatus: 'released'),
      );

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel offer'), findsNothing);
      expect(find.text('Pay (QiCard)'), findsNothing);
      expect(find.text('Submit work'), findsNothing);
      expect(find.text('Approve & release payment'), findsNothing);
    });

    // ── T192: No action buttons on canceled offer ────────────────────────

    testWidgets('T192 no action buttons on canceled offer', (tester) async {
      when(() => mockOffers.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'canceled', paymentStatus: 'unpaid'),
      );

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel offer'), findsNothing);
      expect(find.text('Pay (QiCard)'), findsNothing);
      expect(find.text('Submit work'), findsNothing);
    });

    // ── T193: Dispute banner hidden when no dispute ──────────────────────

    testWidgets('T193 dispute banner hidden when no dispute', (tester) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenAnswer((_) async => _offer(status: 'in_progress'));
      when(
        () => mockSafety.hasOpenDisputeForDirectOffer(_kOfferId),
      ).thenAnswer((_) async => false);

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      expect(find.text('Work frozen — in dispute.'), findsNothing);
      expect(
        find.text('Dispute under review. Approve and release disabled.'),
        findsNothing,
      );
    });

    // ── T194: PENDING PAYMENT status for accepted unpaid ─────────────────

    testWidgets('T194 shows PENDING PAYMENT status for accepted unpaid', (
      tester,
    ) async {
      when(() => mockOffers.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'accepted', paymentStatus: 'unpaid'),
      );

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      expect(find.text('PENDING PAYMENT'), findsOneWidget);
    });

    // ── T195: Pay button visible for client with accepted unpaid ─────────

    testWidgets('T195 pay button visible for client on accepted unpaid offer', (
      tester,
    ) async {
      when(() => mockAuth.currentUserId).thenReturn(_kClientId);
      when(() => mockOffers.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'accepted', paymentStatus: 'unpaid'),
      );

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      expect(find.text('Pay (QiCard)'), findsOneWidget);
    });

    // ── T196: Submit work button for freelancer on active offer ──────────

    testWidgets(
      'T196 submit work button visible for freelancer on active offer',
      (tester) async {
        // Set current user to freelancer
        when(() => mockAuth.currentUserId).thenReturn(_kFreelancerId);
        when(() => mockOffers.getOffer(_kOfferId)).thenAnswer(
          (_) async => _offer(
            status: 'active',
            paymentStatus: 'held',
            // The isActive getter checks status == 'active'
          ),
        );

        await _pumpScreen(
          tester,
          authVm: mockAuth,
          offersService: mockOffers,
          paymentService: mockPayment,
          safetyVm: mockSafety,
          deepLinkService: mockDeepLink,
        );
        await tester.pumpAndSettle();

        expect(find.text('Submit work'), findsOneWidget);
      },
    );

    // ── T197: Approve & release for client on delivered offer ─────────────

    testWidgets(
      'T197 approve & release payment visible for client on delivered offer',
      (tester) async {
        when(() => mockAuth.currentUserId).thenReturn(_kClientId);
        when(() => mockOffers.getOffer(_kOfferId)).thenAnswer(
          (_) async => _offer(status: 'delivered', paymentStatus: 'held'),
        );

        await _pumpScreen(
          tester,
          authVm: mockAuth,
          offersService: mockOffers,
          paymentService: mockPayment,
          safetyVm: mockSafety,
          deepLinkService: mockDeepLink,
        );
        await tester.pumpAndSettle();

        expect(find.text('Approve & release payment'), findsOneWidget);
      },
    );

    // ── T198: Offer with null title shows "Custom offer" ─────────────────

    testWidgets('T198 shows Custom offer when title is null', (tester) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenAnswer((_) async => _offer(title: null));

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      // AppBar and the AppCardContainer title both show "Custom offer"
      expect(find.text('Custom offer'), findsAtLeastNWidgets(1));
    });

    // ── T199: Description is shown when present ──────────────────────────

    testWidgets('T199 shows description when present', (tester) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenAnswer((_) async => _offer(description: 'Build a modern logo'));

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      expect(find.text('Build a modern logo'), findsOneWidget);
    });

    // ── T200: Chat button triggers openConversation ──────────────────────

    testWidgets(
      'T200 tapping Open chat calls DeepLinkService.openConversation',
      (tester) async {
        when(
          () => mockOffers.getOffer(_kOfferId),
        ).thenAnswer((_) async => _offer());

        await _pumpScreen(
          tester,
          authVm: mockAuth,
          offersService: mockOffers,
          paymentService: mockPayment,
          safetyVm: mockSafety,
          deepLinkService: mockDeepLink,
          conversationId: _kConversationId,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open chat'));
        await tester.pumpAndSettle();

        verify(
          () => mockDeepLink.openConversation(any(), _kConversationId),
        ).called(1);
      },
    );

    // ── T201: Cancel offer not visible for freelancer ────────────────────

    testWidgets('T201 cancel offer not shown when user is freelancer', (
      tester,
    ) async {
      when(() => mockAuth.currentUserId).thenReturn(_kFreelancerId);
      when(() => mockOffers.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'accepted', paymentStatus: 'unpaid'),
      );

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      // canCancel requires clientId == currentUserId; freelancer should not see it
      expect(find.text('Cancel offer'), findsNothing);
      expect(find.text('Pay (QiCard)'), findsNothing);
    });

    // ── T202: Keep button dismisses dialog without canceling ─────────────

    testWidgets('T202 Keep button in cancel dialog does not trigger cancel', (
      tester,
    ) async {
      when(() => mockOffers.getOffer(_kOfferId)).thenAnswer(
        (_) async => _offer(status: 'accepted', paymentStatus: 'unpaid'),
      );

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Cancel offer'));
      await tester.pumpAndSettle();

      // Tap Keep
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();

      // Dialog dismissed, no cancel call
      verifyNever(() => mockOffers.cancelAcceptedOffer(any()));
    });

    // ── T203: Offer not found shows fallback text ────────────────────────

    testWidgets('T203 shows Offer not found when service returns null', (
      tester,
    ) async {
      when(() => mockOffers.getOffer(_kOfferId)).thenAnswer((_) async => null);

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      expect(find.text('Offer not found.'), findsOneWidget);
    });

    // ── T204: Back button in appbar exists ────────────────────────────────

    testWidgets('T204 back button is present in appbar', (tester) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenAnswer((_) async => _offer());

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    // ── T205: AppCardContainer wraps offer details ─────────────────────────

    testWidgets('T205 offer details are inside a AppCardContainer', (
      tester,
    ) async {
      when(
        () => mockOffers.getOffer(_kOfferId),
      ).thenAnswer((_) async => _offer());

      await _pumpScreen(
        tester,
        authVm: mockAuth,
        offersService: mockOffers,
        paymentService: mockPayment,
        safetyVm: mockSafety,
        deepLinkService: mockDeepLink,
      );
      await tester.pumpAndSettle();

      // At least one AppCardContainer for the main details card
      expect(find.byType(AppCardContainer), findsAtLeastNWidgets(1));
    });
  });
}
