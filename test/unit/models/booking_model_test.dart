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
    'due_at': '2026-02-28T10:00:00Z',
    'delivery_days': 5,
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

    test(
      'BookingModel.fromJson preserves null slot_id instead of zero UUID',
      () {
        final booking = BookingModel.fromJson(<String, dynamic>{
          ..._bookingJson(),
          'slot_id': null,
        });

        expect(booking.slotId, isNull);
      },
    );

    test('BookingModel.fromJson prefers due_at for direct bookings', () {
      final booking = BookingModel.fromJson(_bookingJson());

      expect(booking.dueAtUtc, DateTime.parse('2026-02-28T10:00:00Z').toUtc());
      expect(booking.deliveryDays, 5);
    });

    test(
      'BookingModel.fromJson falls back to legacy availability slot start when due_at is null',
      () {
        final booking = BookingModel.fromJson(<String, dynamic>{
          ..._bookingJson(),
          'due_at': null,
          'availability_slots': <String, dynamic>{
            'starts_at': '2026-02-26T09:00:00Z',
          },
        });

        expect(
          booking.dueAtUtc,
          DateTime.parse('2026-02-26T09:00:00Z').toUtc(),
        );
        expect(
          booking.scheduledAt,
          DateTime.parse('2026-02-26T09:00:00Z').toUtc(),
        );
      },
    );
  });

  group('BookingModel extended coverage', () {
    test('Minimal valid JSON — all nullable fields default', () {
      final json = <String, dynamic>{
        'id': 'booking-min',
        'provider_id': 'prov-1',
        'client_id': 'cli-1',
        'created_at': '2026-03-15T08:00:00Z',
        'status': 'pending',
      };
      final booking = BookingModel.fromJson(json);

      expect(booking.id, 'booking-min');
      expect(booking.providerId, 'prov-1');
      expect(booking.clientId, 'cli-1');
      expect(booking.taskId, isNull);
      expect(booking.slotId, isNull);
      expect(booking.note, isNull);
      expect(booking.price, isNull);
      expect(booking.packageId, isNull);
      expect(booking.requirements, isNull);
      expect(booking.dueAtUtc, isNull);
      expect(booking.deliveryDays, isNull);
      expect(booking.scheduledAt, isNull);
      expect(booking.completedAt, isNull);
      expect(booking.taskData, isNull);
    });

    test('Unknown status string maps to BookingStatus.pending', () {
      final json = <String, dynamic>{
        ..._bookingJson(),
        'status': 'totally_invented_status',
      };
      final booking = BookingModel.fromJson(json);

      expect(booking.status, BookingStatus.pending);
    });

    test('paymentStatus null maps to PaymentStatus.unpaid', () {
      final json = <String, dynamic>{..._bookingJson(), 'payment_status': null};
      final booking = BookingModel.fromJson(json);

      expect(booking.paymentStatus, PaymentStatus.unpaid);
    });

    test(
      'dueAtUtc fallback chain: due_at -> availability_slots.starts_at -> null',
      () {
        // Case 1: due_at present — uses due_at
        final withDueAt = BookingModel.fromJson(<String, dynamic>{
          ..._bookingJson(),
          'due_at': '2026-04-01T12:00:00Z',
          'availability_slots': <String, dynamic>{
            'starts_at': '2026-05-01T12:00:00Z',
          },
        });
        expect(
          withDueAt.dueAtUtc,
          DateTime.parse('2026-04-01T12:00:00Z').toUtc(),
        );

        // Case 2: due_at null, availability_slots.starts_at present — uses starts_at
        final withSlot = BookingModel.fromJson(<String, dynamic>{
          ..._bookingJson(),
          'due_at': null,
          'availability_slots': <String, dynamic>{
            'starts_at': '2026-05-01T12:00:00Z',
          },
        });
        expect(
          withSlot.dueAtUtc,
          DateTime.parse('2026-05-01T12:00:00Z').toUtc(),
        );

        // Case 3: both null — dueAtUtc is null
        final withNeither = BookingModel.fromJson(<String, dynamic>{
          ..._bookingJson(),
          'due_at': null,
        });
        expect(withNeither.dueAtUtc, isNull);
      },
    );

    test('Round-trip toJson -> fromJson for each BookingStatus enum value', () {
      // Map each BookingStatus to its DB string via statusToDbString,
      // then parse back and verify the round-trip.
      final statusDbStrings = <BookingStatus, String>{
        BookingStatus.pending: 'pending',
        BookingStatus.confirmed: 'confirmed',
        BookingStatus.active: 'active',
        BookingStatus.delivered: 'delivered',
        BookingStatus.completed: 'completed',
        BookingStatus.canceled: 'canceled',
        BookingStatus.refunded: 'refunded',
        BookingStatus.paidRequestPending: 'paid_request_pending',
        BookingStatus.expiredUnanswered: 'expired_unanswered',
        BookingStatus.disputed: 'disputed',
        BookingStatus.noShow: 'no_show',
        BookingStatus.declined:
            'canceled', // declined maps to 'canceled' DB string
      };

      for (final entry in statusDbStrings.entries) {
        final original = BookingModel(
          id: 'rt-${entry.key.name}',
          taskId: null,
          providerId: 'prov-1',
          clientId: 'cli-1',
          slotId: null,
          status: entry.key,
          paymentStatus: PaymentStatus.unpaid,
          note: null,
          createdAtUtc: DateTime.utc(2026, 3, 15, 8),
        );

        final json = original.toJson();
        expect(
          json['status'],
          entry.value,
          reason: '${entry.key} should serialize to ${entry.value}',
        );

        final restored = BookingModel.fromJson(json);
        // declined serializes as 'canceled' and parses back as canceled (not declined)
        if (entry.key == BookingStatus.declined) {
          expect(
            restored.status,
            BookingStatus.canceled,
            reason: 'declined round-trips through canceled',
          );
        } else if (entry.key == BookingStatus.inProgress) {
          // inProgress is a legacy alias — serializes to its .name,
          // which maps back to active in _mapDbStatusToEnum
          expect(
            restored.status,
            BookingStatus.active,
            reason: 'inProgress round-trips through active',
          );
        } else {
          expect(
            restored.status,
            entry.key,
            reason: '${entry.key} should round-trip',
          );
        }
      }
    });

    test("'cancelled' (British spelling) maps to BookingStatus.canceled", () {
      final json = <String, dynamic>{..._bookingJson(), 'status': 'cancelled'};
      final booking = BookingModel.fromJson(json);

      expect(booking.status, BookingStatus.canceled);
    });
  });
}
