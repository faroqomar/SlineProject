import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/dashboard/view/widgets/booking_card.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';

import '../../test_support/pump_app.dart';

class _MockDashboardViewModel extends Mock
    with ChangeNotifier
    implements DashboardViewModel {}

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
    required DashboardViewModel viewModel,
    required BookingModel booking,
    required bool isProvider,
  }) async {
    await pumpApp(
      tester,
      ChangeNotifierProvider<DashboardViewModel>.value(
        value: viewModel,
        child: Scaffold(
          body: BookingCard(booking: booking, isProvider: isProvider),
        ),
      ),
    );
  }

  testWidgets('provider paid request pending shows Accept and no Confirm', (
    tester,
  ) async {
    final vm = _MockDashboardViewModel();
    when(() => vm.acceptBooking('booking-1')).thenAnswer((_) async {});
    when(() => vm.declineBooking('booking-1')).thenAnswer((_) async {});

    await pumpBookingCard(
      tester,
      viewModel: vm,
      booking: _booking(
        id: 'booking-1',
        status: BookingStatus.paidRequestPending,
        paymentStatus: PaymentStatus.held,
      ),
      isProvider: true,
    );

    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);

    await tester.tap(find.text('Accept'));
    await tester.pump();

    verify(() => vm.acceptBooking('booking-1')).called(1);
  });

  testWidgets(
    'provider pending unpaid shows Awaiting Payment instead of Confirm',
    (tester) async {
      final vm = _MockDashboardViewModel();
      when(() => vm.cancelBooking('booking-2')).thenAnswer((_) async {});

      await pumpBookingCard(
        tester,
        viewModel: vm,
        booking: _booking(
          id: 'booking-2',
          status: BookingStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
        ),
        isProvider: true,
      );

      expect(find.text('Awaiting Payment'), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);

      await tester.tap(find.text('Decline'));
      await tester.pump();

      verify(() => vm.cancelBooking('booking-2')).called(1);
    },
  );
}
