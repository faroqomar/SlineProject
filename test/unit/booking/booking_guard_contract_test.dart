import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/booking/services/booking_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../helpers/mock_supabase.dart';

/// Stub builder so getBookingById gets a delivered booking; chain ends with single() -> Future.
class _StubBookingBuilder extends Fake
    implements
        PostgrestFilterBuilder<Map<String, dynamic>>,
        PostgrestTransformBuilder<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  _StubBookingBuilder(this._data);

  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) =>
      _StubBookingListBuilder(_data);

  @override
  PostgrestFilterBuilder<Map<String, dynamic>> eq(
    String column,
    Object value,
  ) => this;

  @override
  PostgrestTransformBuilder<PostgrestMap> single() => this;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(Map<String, dynamic>) onValue, {
    Function? onError,
  }) => Future.value(_data).then(onValue, onError: onError);
}

class _StubBookingListBuilder extends Fake
    implements
        PostgrestFilterBuilder<PostgrestList>,
        PostgrestTransformBuilder<PostgrestList> {
  final Map<String, dynamic> _data;
  _StubBookingListBuilder(this._data);

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<PostgrestMap> single() =>
      _StubBookingBuilder(_data);
}

class _QueryBuilder extends Fake implements SupabaseQueryBuilder {
  final dynamic _next;
  _QueryBuilder(this._next);
  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      _StubBookingListBuilder((_next as _StubBookingBuilder)._data);
}

/// Contract test: client cannot cancel a delivered booking (Plan: PLAN_BookingLifecycle_2026-03-08_PlanCritic).
/// Run: flutter test test/unit/booking/booking_guard_contract_test.dart
void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockUser user;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    user = MockUser();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(user);
  });

  group('BookingService updateBookingStatus guard', () {
    test('client canceling delivered booking throws StateError', () async {
      when(() => user.id).thenReturn('client-1');

      final deliveredBookingMap = {
        'id': 'booking-1',
        'task_id': 'task-1',
        'provider_id': 'provider-2',
        'client_id': 'client-1',
        'slot_id': null,
        'status': 'delivered',
        'payment_status': 'held',
        'note': null,
        'price': 100.0,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'due_at': null,
        'delivery_days': 1,
        'tasks': null,
      };

      when(() => client.from('bookings')).thenAnswer(
        (_) => _QueryBuilder(_StubBookingBuilder(deliveredBookingMap)),
      );

      final service = BookingService(client);

      expect(
        () => service.updateBookingStatus(
          bookingId: 'booking-1',
          newStatus: BookingStatus.canceled,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('cannot cancel after delivery'),
          ),
        ),
      );
    });
  });
}
