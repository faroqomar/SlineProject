import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/work/models/unified_work_item_fallback_mapper.dart';

void main() {
  group('UnifiedWorkItemFallbackMapper', () {
    group('fromTaskRequestAndTaskMap', () {
      test('returns null when tasks is missing', () {
        final map = <String, dynamic>{
          'id': 'tr-1',
          'task_id': 'task-1',
          'price': 50,
        };
        expect(
          UnifiedWorkItemFallbackMapper.fromTaskRequestAndTaskMap(map),
          isNull,
        );
      });

      test('returns null when task id is missing', () {
        final map = <String, dynamic>{
          'id': 'tr-1',
          'task_id': 'task-1',
          'price': 50,
          'tasks': <String, dynamic>{'title': 'Task'},
        };
        expect(
          UnifiedWorkItemFallbackMapper.fromTaskRequestAndTaskMap(map),
          isNull,
        );
      });

      test('builds UnifiedWorkItemModel with pending_payment status', () {
        final map = <String, dynamic>{
          'id': 'tr-1',
          'task_id': 'task-1',
          'price': 50,
          'payment_deadline': '2026-12-01T12:00:00Z',
          'updated_at': '2026-03-01T10:00:00Z',
          'freelancer_id': 'freelancer-1',
          'tasks': <String, dynamic>{
            'id': 'task-1',
            'title': 'Test Task',
            'deadline': '2026-11-30T23:59:59Z',
            'owner_id': 'client-1',
            'client_id': 'client-1',
            'status': 'assigned',
            'updated_at': '2026-03-01T10:00:00Z',
          },
        };
        final result =
            UnifiedWorkItemFallbackMapper.fromTaskRequestAndTaskMap(map);
        expect(result, isNotNull);
        expect(result!.id, 'task-1');
        expect(result.sourceType, 'task');
        expect(result.unifiedStatus, UnifiedWorkStatus.pendingPayment);
        expect(result.title, 'Test Task');
        expect(result.awardedRequestId, 'tr-1');
      });
    });

    group('fromBooking', () {
      BookingModel booking({
        required String id,
        required BookingStatus status,
      }) {
        return BookingModel(
          id: id,
          taskId: 'task-1',
          providerId: 'provider-1',
          clientId: 'client-1',
          slotId: null,
          status: status,
          paymentStatus: PaymentStatus.unpaid,
          note: null,
          price: 100,
          packageId: null,
          requirements: null,
          createdAtUtc: DateTime.utc(2026, 1, 1),
          dueAtUtc: null,
          deliveryDays: null,
          scheduledAt: null,
          completedAt: null,
          taskData: <String, dynamic>{'title': 'Booking Task'},
        );
      }

      test('maps completed to UnifiedWorkStatus.completed', () {
        final b = booking(id: 'book-1', status: BookingStatus.completed);
        final u = UnifiedWorkItemFallbackMapper.fromBooking(b);
        expect(u.unifiedStatus, UnifiedWorkStatus.completed);
      });

      test('maps delivered to UnifiedWorkStatus.delivered', () {
        final b = booking(id: 'book-1', status: BookingStatus.delivered);
        final u = UnifiedWorkItemFallbackMapper.fromBooking(b);
        expect(u.unifiedStatus, UnifiedWorkStatus.delivered);
      });

      test('maps active to UnifiedWorkStatus.active', () {
        final b = booking(id: 'book-1', status: BookingStatus.active);
        final u = UnifiedWorkItemFallbackMapper.fromBooking(b);
        expect(u.unifiedStatus, UnifiedWorkStatus.active);
      });

      test('maps pending to UnifiedWorkStatus.pending', () {
        final b = booking(id: 'book-1', status: BookingStatus.pending);
        final u = UnifiedWorkItemFallbackMapper.fromBooking(b);
        expect(u.unifiedStatus, UnifiedWorkStatus.pending);
      });

      test('maps canceled to UnifiedWorkStatus.canceled', () {
        final b = booking(id: 'book-1', status: BookingStatus.canceled);
        final u = UnifiedWorkItemFallbackMapper.fromBooking(b);
        expect(u.unifiedStatus, UnifiedWorkStatus.canceled);
      });
    });
  });
}
