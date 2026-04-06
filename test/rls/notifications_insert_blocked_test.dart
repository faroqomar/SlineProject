/// RLS: Authenticated users cannot INSERT into notifications
///
/// Plan: .TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md
/// Invariant: Only server (private_upsert_notification / private_create_notification)
/// can insert; anon and authenticated must be blocked.
///
/// With real Supabase: pass client to RlsTestHelper to run live assertCannotInsert.
/// Run: flutter test test/rls/notifications_insert_blocked_test.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/services/logger_service.dart';

import 'fixtures/rls_test_users.dart';
import 'rls_test_helper.dart';

const String _logTag = 'rls_test';

void main() {
  late RlsTestHelper rlsHelper;

  setUp(() {
    AppLogger.i('Setting up notifications INSERT blocked test', tag: _logTag);
    rlsHelper = RlsTestHelper(); // Mock mode when client is null
  });

  tearDown(() {
    AppLogger.d('Tearing down notifications RLS test', tag: _logTag);
  });

  group('Notifications: authenticated user cannot INSERT', () {
    test('authenticated user cannot insert into notifications', () async {
      AppLogger.i(
        'Test: authenticated user must not be able to INSERT into notifications',
        tag: _logTag,
        json: {'table': 'notifications', 'invariant': 'server-only writes'},
      );

      final fakeNotification = {
        'user_id': TestUsers.clientUser.id,
        'title': 'Test',
        'message': 'Must be blocked by RLS',
        'type': 'message',
      };

      await rlsHelper.assertCannotInsert(
        'notifications',
        fakeNotification,
        asUserId: TestUsers.clientUser.id,
        description:
            'Authenticated user cannot INSERT into notifications (expect 42501 or RLS)',
      );

      AppLogger.i(
        '✓ Notifications INSERT blocked for authenticated (contract satisfied)',
        tag: _logTag,
      );
    });
  });
}
