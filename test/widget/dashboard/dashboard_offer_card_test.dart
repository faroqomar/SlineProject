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
}) {
  return TaskRequest(
    id: 'offer-1',
    taskId: 'task-1',
    bidderId: 'freelancer-1',
    price: 450,
    days: 3,
    note: 'I can start tomorrow.',
    status: status,
    paymentStatus: paymentStatus,
    createdAt: DateTime.utc(2020),
    bidderName: 'Yara Ahmed',
    taskTitle: 'Landing page design',
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
}
