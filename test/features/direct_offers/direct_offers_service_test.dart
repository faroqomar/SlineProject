/// Unit tests for [DirectOffersService] — role and state guards.
///
/// Run: `flutter test test/features/direct_offers/direct_offers_service_test.dart`
/// Plan: PLAN_DirectChatOfferFlow_2026-03-07_CRITIC (Phase 0).
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/direct_offers/services/direct_offers_service.dart';
import '../../helpers/mock_supabase.dart';

const String _logTag = 'direct_offers_service_test';

/// Stub filter builder that resolves to [T] when awaited (getOffer uses .maybeSingle() then await).
class _StubDirectOfferBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T>, PostgrestTransformBuilder<T> {
  final T _data;
  _StubDirectOfferBuilder(this._data);

  @override
  PostgrestFilterBuilder<R> select<R>([
    String columns = '*',
    FetchOptions options = const FetchOptions(),
  ]) => _StubDirectOfferBuilder<R>(_data as R);
  @override
  PostgrestFilterBuilder<T> eq(String column, dynamic value) => this;
  @override
  PostgrestTransformBuilder<T> maybeSingle() => this;
  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) =>
      Future.value(_data).then(onValue, onError: onError);
}

class _QueryBuilder extends Fake implements SupabaseQueryBuilder {
  final dynamic _next;
  _QueryBuilder(this._next);
  @override
  PostgrestFilterBuilder<R> select<R>([
    String columns = '*',
    FetchOptions options = const FetchOptions(),
  ]) => _next;
}

Map<String, dynamic> _offerRow({
  required String id,
  required String clientId,
  required String freelancerId,
  String status = 'sent',
  String paymentStatus = 'unpaid',
}) => {
  'id': id,
  'conversation_id': 'conv-1',
  'client_id': clientId,
  'freelancer_id': freelancerId,
  'task_id': null,
  'title': null,
  'description': null,
  'price': 10000,
  'days': 3,
  'status': status,
  'payment_status': paymentStatus,
  'created_at': DateTime.now().toUtc().toIso8601String(),
  'updated_at': DateTime.now().toUtc().toIso8601String(),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DirectOffersService service;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('');

    AppLogger.d('DirectOffersService test setUp', tag: _logTag);
  });

  group('Role guards', () {
    test(
      'client cannot call cancelOffer (only freelancer can cancel)',
      () async {
        const clientId = 'client-uuid';
        const freelancerId = 'freelancer-uuid';
        const offerId = 'offer-1';

        when(() => mockUser.id).thenReturn(clientId);
        when(() => mockClient.from('direct_offers')).thenAnswer(
          (_) => _QueryBuilder(
            _StubDirectOfferBuilder<Map<String, dynamic>>(
              _offerRow(
                id: offerId,
                clientId: clientId,
                freelancerId: freelancerId,
                status: 'sent',
              ),
            ),
          ),
        );

        service = DirectOffersService(mockClient);

        expect(
          service.cancelOffer(offerId),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Only the freelancer'),
            ),
          ),
        );
        AppLogger.d('cancelOffer as client correctly threw', tag: _logTag);
      },
    );

    test('freelancer cannot call payNow (only client can pay)', () async {
      const clientId = 'client-uuid';
      const freelancerId = 'freelancer-uuid';
      const offerId = 'offer-1';

      when(() => mockUser.id).thenReturn(freelancerId);
      when(() => mockClient.from('direct_offers')).thenAnswer(
        (_) => _QueryBuilder(
          _StubDirectOfferBuilder<Map<String, dynamic>>(
            _offerRow(
              id: offerId,
              clientId: clientId,
              freelancerId: freelancerId,
              status: 'accepted',
              paymentStatus: 'unpaid',
            ),
          ),
        ),
      );

      service = DirectOffersService(mockClient);

      expect(
        service.payNow(offerId),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Only the client'),
          ),
        ),
      );
      AppLogger.d('payNow as freelancer correctly threw', tag: _logTag);
    });
  });

  group('State guards', () {
    test('markDelivered throws when offer is not active', () async {
      const clientId = 'client-uuid';
      const freelancerId = 'freelancer-uuid';
      const offerId = 'offer-1';

      when(() => mockUser.id).thenReturn(freelancerId);
      when(() => mockClient.from('direct_offers')).thenAnswer(
        (_) => _QueryBuilder(
          _StubDirectOfferBuilder<Map<String, dynamic>>(
            _offerRow(
              id: offerId,
              clientId: clientId,
              freelancerId: freelancerId,
              status: 'accepted',
              paymentStatus: 'unpaid',
            ),
          ),
        ),
      );

      service = DirectOffersService(mockClient);

      expect(
        service.markDelivered(offerId),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('active'),
          ),
        ),
      );
      AppLogger.d('markDelivered when !isActive correctly threw', tag: _logTag);
    });
  });
}
