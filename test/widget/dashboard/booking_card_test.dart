import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/view/widgets/booking_card.dart';
import 'package:sline_app/features/booking/view/widgets/dashboard_booking_card.dart';

import '../../test_support/pump_app.dart';

BookingModel _booking({
  required String id,
  required BookingStatus status,
  required PaymentStatus paymentStatus,
}) {
  return BookingModel(
    id: id,
    taskId: 'task-1',
    providerId: 'provider-1',
    clientId: 'client-1',
    slotId: null,
    status: status,
    paymentStatus: paymentStatus,
    note: 'Test note',
    price: 100,
    createdAtUtc: DateTime.utc(2026, 3, 1),
    dueAtUtc: DateTime.utc(2026, 3, 3),
    deliveryDays: 2,
    taskData: const {'title': 'Booking Task'},
  );
}

void main() {
  Future<void> pumpBookingCard(
    WidgetTester tester, {
    required BookingModel booking,
    required bool isProvider,
    Future<bool?> Function(BookingModel)? onTapDetails,
    VoidCallback? onRefresh,
    void Function(String)? onAccept,
    void Function(String)? onDecline,
    void Function(String)? onCancel,
    void Function(String, BookingStatus)? onUpdateStatus,
  }) async {
    await pumpApp(
      tester,
      Scaffold(
        body: DashboardBookingCard(
          booking: booking,
          isProvider: isProvider,
          onTapDetails: onTapDetails ?? ((_) async => null),
          onRefresh: onRefresh,
          onAccept: onAccept ?? (_) {},
          onDecline: onDecline ?? (_) {},
          onCancel: onCancel ?? (_) {},
          onUpdateStatus: onUpdateStatus ?? (_, __) {},
        ),
      ),
    );
  }

  testWidgets('provider paid request pending shows Accept and no Confirm', (
    tester,
  ) async {
    String? acceptedId;
    await pumpBookingCard(
      tester,
      booking: _booking(
        id: 'booking-1',
        status: BookingStatus.paidRequestPending,
        paymentStatus: PaymentStatus.held,
      ),
      isProvider: true,
      onAccept: (id) => acceptedId = id,
    );

    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
    expect(find.text('100 IQD'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pump();

    expect(acceptedId, 'booking-1');
  });

  testWidgets(
    'provider pending unpaid shows Awaiting Payment instead of Confirm',
    (tester) async {
      String? canceledId;
      await pumpBookingCard(
        tester,
        booking: _booking(
          id: 'booking-2',
          status: BookingStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
        ),
        isProvider: true,
        onCancel: (id) => canceledId = id,
      );

      expect(find.text('Awaiting Payment'), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(canceledId, 'booking-2');
    },
  );

  testWidgets('client confirmed booking cancel calls status update', (
    tester,
  ) async {
    String? updatedId;
    BookingStatus? updatedStatus;

    await pumpBookingCard(
      tester,
      booking: _booking(
        id: 'booking-4',
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.held,
      ),
      isProvider: false,
      onUpdateStatus: (id, status) {
        updatedId = id;
        updatedStatus = status;
      },
    );

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(updatedId, 'booking-4');
    expect(updatedStatus, BookingStatus.canceled);
  });

  testWidgets('compact BookingCard preserves tap callback and price fallback', (
    tester,
  ) async {
    // ignore: omit_local_variable_types - explicit bool requested by review.
    bool tapped = false;
    await pumpApp(
      tester,
      Scaffold(
        body: BookingCard(
          booking: _booking(
            id: 'booking-3',
            status: BookingStatus.active,
            paymentStatus: PaymentStatus.held,
          ),
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Booking Task'), findsOneWidget);

    await tester.tap(find.byType(ScaleButton));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
