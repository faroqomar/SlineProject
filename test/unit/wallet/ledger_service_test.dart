/// Unit tests for [LedgerService] (idempotency key deterministic; contract alignment).
///
/// Run: `flutter test test/unit/wallet/ledger_service_test.dart`
/// Observability: AppLogger is used by LedgerService; tests do not assert on logs.
/// Note: submitPaymentEvent RPC call is covered by integration tests (Supabase .rpc returns builder, not Future).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/wallet/services/ledger_service.dart';

import '../../helpers/mock_supabase.dart';

const String _logTag = 'ledger_service_test';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LedgerService.generateIdempotencyKey', () {
    late LedgerService service;
    late MockSupabaseClient mockClient;

    setUp(() {
      mockClient = MockSupabaseClient();
      when(() => mockClient.auth).thenReturn(MockGoTrueClient());
      service = LedgerService(mockClient);
      AppLogger.d('LedgerService idempotency tests starting', tag: _logTag);
    });

    test('same entityId and eventType produce the same key', () {
      const entityId = '550e8400-e29b-41d4-a716-446655440000';
      const eventType = 'escrow_hold';

      final key1 = service.generateIdempotencyKey(entityId, eventType);
      final key2 = service.generateIdempotencyKey(entityId, eventType);

      expect(key1, key2);
      expect(key1, isNotEmpty);
      AppLogger.d('Idempotency key deterministic: $key1', tag: _logTag);
    });

    test('different entityId produces different key', () {
      const eventType = 'escrow_hold';
      final key1 = service.generateIdempotencyKey('entity-a', eventType);
      final key2 = service.generateIdempotencyKey('entity-b', eventType);
      expect(key1, isNot(key2));
    });

    test('different eventType produces different key', () {
      const entityId = '550e8400-e29b-41d4-a716-446655440000';
      final key1 = service.generateIdempotencyKey(entityId, 'escrow_hold');
      final key2 = service.generateIdempotencyKey(entityId, 'release_with_fee');
      expect(key1, isNot(key2));
    });
  });
}
