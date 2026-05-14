import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/features/chat/view/widgets/offer_message_bubble.dart';

void main() {
  group('OfferMessageBubble', () {
    Widget buildBubble({
      OfferStatus status = OfferStatus.pending,
      bool isMine = true,
      String? rawStatus,
      String? offerId,
      VoidCallback? onAccept,
      VoidCallback? onDecline,
    }) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: OfferMessageBubble(
            title: 'Test Offer',
            description: 'Test description',
            price: '500',
            deliveryDays: '3',
            status: status,
            isMine: isMine,
            time: '12:00',
            rawStatus: rawStatus,
            offerId: offerId,
            onAccept: onAccept,
            onDecline: onDecline,
          ),
        ),
      );
    }

    testWidgets('shows CUSTOM OFFER badge', (tester) async {
      await tester.pumpWidget(buildBubble());
      expect(find.text('CUSTOM OFFER'), findsOneWidget);
    });

    testWidgets('shows price', (tester) async {
      await tester.pumpWidget(buildBubble());
      expect(find.text('500 IQD'), findsOneWidget);
    });

    testWidgets('shows delivery days', (tester) async {
      await tester.pumpWidget(buildBubble());
      expect(find.text('3 Days Delivery'), findsOneWidget);
    });

    testWidgets('shows Pending Response for pending status', (tester) async {
      await tester.pumpWidget(buildBubble(rawStatus: 'pending'));
      expect(find.text('Pending Response'), findsOneWidget);
    });

    testWidgets('shows Completed Paid for completed status', (tester) async {
      await tester.pumpWidget(
        buildBubble(rawStatus: 'completed', offerId: 'offer-1'),
      );
      expect(find.text('Completed \u2022 Paid'), findsOneWidget);
    });

    testWidgets('shows Accept/Decline for client with sent offer', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildBubble(
          isMine: false,
          rawStatus: 'sent',
          offerId: 'offer-1',
          onAccept: () {},
          onDecline: () {},
        ),
      );
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('Accept callback is invoked on tap', (tester) async {
      // Verify the onAccept closure fires when the recipient taps Accept.
      var accepted = false;
      await tester.pumpWidget(
        buildBubble(
          isMine: false,
          rawStatus: 'sent',
          offerId: 'offer-1',
          onAccept: () => accepted = true,
          onDecline: () {},
        ),
      );
      await tester.tap(find.text('Accept'));
      await tester.pump();
      expect(accepted, isTrue);
    });

    testWidgets('Decline callback is invoked on tap', (tester) async {
      // Verify the onDecline closure fires when the recipient taps Decline.
      var declined = false;
      await tester.pumpWidget(
        buildBubble(
          isMine: false,
          rawStatus: 'sent',
          offerId: 'offer-1',
          onAccept: () {},
          onDecline: () => declined = true,
        ),
      );
      await tester.tap(find.text('Decline'));
      await tester.pump();
      expect(declined, isTrue);
    });

    testWidgets('shows Accepted status chip', (tester) async {
      await tester.pumpWidget(buildBubble(status: OfferStatus.accepted));
      expect(find.text('Accepted'), findsOneWidget);
    });

    testWidgets('shows Declined status chip', (tester) async {
      await tester.pumpWidget(buildBubble(status: OfferStatus.declined));
      expect(find.text('Declined'), findsOneWidget);
    });

    testWidgets('has Semantics with offer details', (tester) async {
      await tester.pumpWidget(buildBubble());
      final semantics = find.bySemanticsLabel(
        RegExp('Direct offer: Test Offer'),
      );
      expect(semantics, findsOneWidget);
    });
  });
}
