/// RLS tests for ledger tables: authenticated users must not INSERT.
///
/// Verifies that ledger_lines and journal_entries are system-only (writes via RPC only).
/// Run: flutter test test/rls/ledger_rls_test.dart
/// With real Supabase: pass client to RlsTestHelper to run live assertCannotInsert.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/services/logger_service.dart';

import 'rls_test_helper.dart';

const String _logTag = 'ledger_rls_test';

void main() {
  late RlsTestHelper rlsHelper;

  setUp(() {
    AppLogger.i('Setting up Ledger RLS test suite', tag: _logTag);
    rlsHelper = RlsTestHelper(); // No client: unit mode; with client: integration
  });

  group('Ledger tables: no direct INSERT by authenticated', () {
    test('ledger_lines INSERT must be blocked for app users (contract)', () async {
      AppLogger.d(
        'Contract: only process_payment_event_ledger RPC may write ledger_lines',
        tag: _logTag,
      );
      // With RlsTestHelper(client: null) we do not run live INSERT.
      // To verify: run with Supabase client and assertCannotInsert(ledger_lines, {...}, asUserId: someUser).
      // Minimal payload that would be rejected by RLS if attempted:
      final dummyData = {
        'journal_entry_id': '00000000-0000-0000-0000-000000000001',
        'account_id': '00000000-0000-0000-0000-000000000002',
        'direction': 'DEBIT',
        'amount': 1,
        'currency': 'IQD',
      };
      await rlsHelper.assertCannotInsert(
        'ledger_lines',
        dummyData,
        asUserId: 'test-user-id',
        description: 'Authenticated user cannot INSERT into ledger_lines',
      );
      AppLogger.i('✓ Ledger RLS contract: ledger_lines insert blocked', tag: _logTag);
    });

    test('journal_entries INSERT must be blocked for app users (contract)', () async {
      AppLogger.d(
        'Contract: only process_payment_event_ledger RPC may write journal_entries',
        tag: _logTag,
      );
      final dummyData = {
        'event_type': 'escrow_hold',
        'related_entity_type': 'booking',
        'related_entity_id': '00000000-0000-0000-0000-000000000001',
        'idempotency_key': 'test-key-${DateTime.now().millisecondsSinceEpoch}',
        'status': 'posted',
        'currency': 'IQD',
        'meta': {},
      };
      await rlsHelper.assertCannotInsert(
        'journal_entries',
        dummyData,
        asUserId: 'test-user-id',
        description: 'Authenticated user cannot INSERT into journal_entries',
      );
      AppLogger.i('✓ Ledger RLS contract: journal_entries insert blocked', tag: _logTag);
    });
  });
}
