import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';

Map<String, dynamic> _bookingJson({String status = 'pending'}) {
  return <String, dynamic>{
    'id': 'booking-1',
    'task_id': 'task-1',
    'provider_id': 'provider-1',
    'client_id': 'client-1',
    'slot_id': 'slot-1',
    'status': status,
    'payment_status': 'unpaid',
    'note': 'note',
    'price': 100.0,
    'created_at': '2026-02-24T10:00:00Z',
  };
}

void main() {
  group('BookingModel T26-T27', () {
    test(
      'T26 BookingModel.fromJson maps in_progress to BookingStatus.active',
      () {
        final booking = BookingModel.fromJson(
          _bookingJson(status: 'in_progress'),
        );

        expect(booking.status, BookingStatus.active);
        expect(booking.id, 'booking-1');
        expect(
          booking.createdAtUtc,
          DateTime.parse('2026-02-24T10:00:00Z').toUtc(),
        );
      },
    );

    test('T27 BookingModel.fromJson maps paid_request_pending correctly', () {
      // "Correctly" for this phase = enum mapping + parse success sanity.
      final booking = BookingModel.fromJson(
        _bookingJson(status: 'paid_request_pending'),
      );

      expect(booking.status, BookingStatus.paidRequestPending);
      expect(booking.clientId, 'client-1');
      expect(booking.providerId, 'provider-1');
    });
  });
}
