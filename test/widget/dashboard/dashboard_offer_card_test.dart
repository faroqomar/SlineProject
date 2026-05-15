/// Widget tests for the dashboard offer card Amber Dusk presentation.
///
/// The file exists to keep inbox offer UI coverage close to the dashboard
/// phase without touching task request services or ViewModels.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/view/widgets/dashboard_offer_card.dart';

import '../../test_support/pump_app.dart';

TaskRequest _offer({
  OfferStatus status = OfferStatus.pending,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
  int price = 450,
  int days = 3,
  String note = 'I can start tomorrow.',
  String taskTitle = 'Landing page design',
}) {
  return TaskRequest(
    id: 'offer-1',
    taskId: 'task-1',
    bidderId: 'freelancer-1',
    price: price,
    days: days,
    note: note,
    status: status,
    paymentStatus: paymentStatus,
    createdAt: DateTime.utc(2020),
    bidderName: 'Yara Ahmed',
    taskTitle: taskTitle,
  );
}

void main() {
  testWidgets('DashboardOfferCard renders Amber Dusk offer hierarchy', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Scaffold(
        body: DashboardOfferCard(
          offer: _offer(),
          isClientView: true,
          onAccept: () {},
          onReject: () {},
        ),
      ),
    );

    expect(find.text('OFFER PRICE'), findsOneWidget);
    expect(find.text('450 IQD'), findsOneWidget);
    expect(find.text('Yara Ahmed'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('2020-01-01  03:00'), findsNothing);
  });

  testWidgets('DashboardOfferCard invokes reject callback only', (
    tester,
  ) async {
    var accepted = false;
    var rejected = false;

    await pumpApp(
      tester,
      Scaffold(
        body: DashboardOfferCard(
          offer: _offer(),
          isClientView: true,
          onAccept: () => accepted = true,
          onReject: () => rejected = true,
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Reject'));
    await tester.pumpAndSettle();

    expect(rejected, isTrue);
    expect(accepted, isFalse);
  });

  testWidgets('DashboardOfferCard invokes award callback only', (tester) async {
    var accepted = false;
    var rejected = false;

    await pumpApp(
      tester,
      Scaffold(
        body: DashboardOfferCard(
          offer: _offer(),
          isClientView: true,
          onAccept: () => accepted = true,
          onReject: () => rejected = true,
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Award'));
    await tester.pumpAndSettle();

    expect(accepted, isTrue);
    expect(rejected, isFalse);
  });

  testWidgets(
    'DashboardOfferCard keeps provider card compact with all fields',
    (
      tester,
    ) async {
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: DashboardOfferCard(
                offer: _offer(
                  price: 989,
                  days: 76,
                  note: 'kmhh',
                  taskTitle: 'Seeking Professional Graphic Designer',
                ),
                isClientView: false,
                onAccept: () {},
                onWithdraw: () {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Seeking Professional Graphic Designer'),
        findsOneWidget,
      );
      expect(find.text('989 IQD'), findsOneWidget);
      expect(find.text('76'), findsOneWidget);
      expect(find.text('DAYS'), findsOneWidget);
      expect(find.text('"kmhh"'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Withdraw'), findsOneWidget);
      expect(
        tester.getSize(find.byType(DashboardOfferCard)).height,
        lessThan(290),
      );
    },
  );
}
