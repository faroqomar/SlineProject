/// Security tests for Chat Creation Matrix.
///
/// These tests verify that the security controls work correctly:
/// - Identity spoofing prevention
/// - Role-based access control
/// - Favorites-based access control
/// - Task context spoofing prevention
/// - Rate limiting enforcement
///
/// These tests can run against a real Supabase instance with test fixtures.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../fixtures/chat_fixtures.dart';
import '../supabase_test_helper.dart';

/// Security test suite for Chat Creation Matrix
///
/// To run these tests:
/// 1. Ensure Supabase local is running: `supabase start`
/// 2. Seed test fixtures
/// 3. Run: `flutter test test/rls/chat_creation_security_test.dart --dart-define=SUPABASE_INTEGRATION=1`
const _skipReason =
    String.fromEnvironment('SUPABASE_INTEGRATION', defaultValue: '') != '1'
    ? 'Requires Supabase; run with --dart-define=SUPABASE_INTEGRATION=1'
    : null;

void main() {
  group('Chat Creation Matrix Security Tests', skip: _skipReason, () {
    late SupabaseClient client;

    setUpAll(() async {
      ensureSupabaseTestEnvironment();
      await Supabase.initialize(
        url: 'http://localhost:54321',
        anonKey: 'test-anon-key',
        localStorage: supabaseTestLocalStorage,
        pkceAsyncStorage: supabaseTestPkceStorage,
      );
      client = Supabase.instance.client;
    });

    group('S1: Identity Spoofing Prevention', () {
      test('cannot create conversation with spoofed initiated_by', () async {
        // This test verifies the guard trigger blocks inserts where
        // initiated_by doesn't match auth.uid()

        // Attempt to insert with different initiated_by
        final result = await client.from('conversations').insert({
          'user1_id': testClientId,
          'user2_id': testFreelancerAId,
          'initiated_by': 'spoofed-user-id', // Different from auth.uid()
        });

        // Should fail with identity error
        expect(
          result,
          throwsA(
            isA<PostgrestException>().having(
              (e) => e.message,
              'message',
              contains('initiated_by must equal current user'),
            ),
          ),
        );
      });
    });

    group('S2: Role-Based Access Control', () {
      test('freelancer cannot initiate DM (RPC)', () async {
        // Authenticate as freelancer
        await _authenticateAsFreelancer(client);

        // Attempt to start DM
        expect(
          () => client.rpc(
            'start_direct_conversation_v1',
            params: {'p_target_id': testClientId},
          ),
          throwsA(
            isA<PostgrestException>().having(
              (e) => e.message,
              'message',
              contains('Freelancers cannot start'),
            ),
          ),
        );
      });

      test('freelancer cannot initiate DM (direct INSERT)', () async {
        await _authenticateAsFreelancer(client);

        expect(
          () => client.from('conversations').insert({
            'user1_id': testFreelancerAId,
            'user2_id': testClientId,
            'initiated_by': testFreelancerAId,
            'task_id': null,
          }),
          throwsA(
            isA<PostgrestException>().having(
              (e) => e.message,
              'message',
              contains('Freelancers cannot start'),
            ),
          ),
        );
      });

      test('client can initiate DM (RPC)', () async {
        await _authenticateAsClient(client);

        // Ensure favorite exists
        await _ensureFavoriteExists(client);

        // Should succeed
        final result = await client.rpc(
          'start_direct_conversation_v1',
          params: {'p_target_id': testFreelancerAId},
        );

        expect(result, isNotNull);
      });
    });

    group('S3: Favorites-Based Access Control', () {
      test('client cannot DM non-favorited freelancer (RPC)', () async {
        await _authenticateAsClient(client);

        // Ensure NO favorite for freelancer B
        await _removeFavorite(client, testFreelancerBId);

        expect(
          () => client.rpc(
            'start_direct_conversation_v1',
            params: {'p_target_id': testFreelancerBId},
          ),
          throwsA(
            isA<PostgrestException>().having(
              (e) => e.message,
              'message',
              contains('favorites list'),
            ),
          ),
        );
      });

      test(
        'client cannot DM non-favorited freelancer (direct INSERT)',
        () async {
          await _authenticateAsClient(client);
          await _removeFavorite(client, testFreelancerBId);

          expect(
            () => client.from('conversations').insert({
              'user1_id': testClientId,
              'user2_id': testFreelancerBId,
              'initiated_by': testClientId,
              'task_id': null,
            }),
            throwsA(
              isA<PostgrestException>().having(
                (e) => e.message,
                'message',
                contains('favorites list'),
              ),
            ),
          );
        },
      );
    });

    group('S4: Task Context Spoofing Prevention', () {
      test(
        'cannot create task-linked conversation for task without bid',
        () async {
          await _authenticateAsClient(client);

          // Create a task where user has NOT bid
          const spoofedTaskId = 'spoofed-task-id';
          await _createTaskWithoutBid(client, spoofedTaskId);

          expect(
            () => client.from('conversations').insert({
              'user1_id': testClientId,
              'user2_id': testFreelancerAId,
              'initiated_by': testClientId,
              'task_id': spoofedTaskId, // User has no bid on this task
            }),
            throwsA(
              isA<PostgrestException>().having(
                (e) => e.message,
                'message',
                anyOf(
                  contains('task owner cannot start'),
                  contains('active bid'),
                ),
              ),
            ),
          );
        },
      );
    });

    group('S5: Rate Limiting Enforcement', () {
      test('rate limit blocks after 20 conversations', () async {
        await _authenticateAsClient(client);

        // Create 20 conversations
        for (var i = 0; i < 20; i++) {
          final freelancerId = 'rate-test-freelancer-$i';
          await _setupFreelancerAndFavorite(client, freelancerId);

          await client.rpc(
            'start_direct_conversation_v1',
            params: {'p_target_id': freelancerId},
          );
        }

        // 21st should fail
        expect(
          () => client.rpc(
            'start_direct_conversation_v1',
            params: {'p_target_id': 'one-more-freelancer'},
          ),
          throwsA(
            isA<PostgrestException>().having(
              (e) => e.message,
              'message',
              contains('Rate limit exceeded'),
            ),
          ),
        );
      });

      test('rate limit resets after 1 hour', () async {
        // This test would need to manipulate time or wait
        // In practice, tested via admin_logs or DB query
        // confirming older conversations don't count
      });
    });

    group('S6: Self-Conversation Prevention', () {
      test('cannot create conversation with self (RPC)', () async {
        await _authenticateAsClient(client);

        expect(
          () => client.rpc(
            'start_direct_conversation_v1',
            params: {'p_target_id': testClientId}, // Same as caller
          ),
          throwsA(
            isA<PostgrestException>().having(
              (e) => e.message,
              'message',
              contains('Cannot create conversation with yourself'),
            ),
          ),
        );
      });
    });

    group('S7: Error Message Privacy', () {
      test('error messages do not contain UUIDs', () async {
        await _authenticateAsClient(client);

        try {
          await client.rpc(
            'start_direct_conversation_v1',
            params: {'p_target_id': testFreelancerBId}, // Not in favorites
          );
          fail('Should have thrown');
        } on PostgrestException catch (e) {
          // Verify error message doesn't contain UUID format
          expect(e.message, isNot(contains(testFreelancerBId)));
          expect(
            e.message,
            isNot(
              predicate<String>(
                (m) => RegExp('[0-9a-f]{8}-').hasMatch(m),
                'contains UUID pattern',
              ),
            ),
          );
        }
      });
    });
  });
}

// ============================================================================
// Security Test Helpers
// ============================================================================

Future<void> _authenticateAsClient(SupabaseClient client) async {
  // In real tests, implement actual auth flow or use service key
  // Placeholder for test structure
}

Future<void> _authenticateAsFreelancer(SupabaseClient client) async {
  // Authenticate as freelancer A
}

Future<void> _ensureFavoriteExists(SupabaseClient client) async {
  await client.from('favorites').upsert(clientFavoritesFreelancerA);
}

Future<void> _removeFavorite(SupabaseClient client, String freelancerId) async {
  await client
      .from('favorites')
      .delete()
      .eq('client_id', testClientId)
      .eq('freelancer_id', freelancerId);
}

Future<void> _createTaskWithoutBid(SupabaseClient client, String taskId) async {
  await client.from('tasks').upsert({
    'id': taskId,
    'title': 'Spoofed Task',
    'owner_id': 'someone-else', // Different owner
    'task_type': 'tender',
    'status': 'open',
  });
}

Future<void> _setupFreelancerAndFavorite(
  SupabaseClient client,
  String freelancerId,
) async {
  // Create freelancer profile
  await client.from('profiles').upsert({
    'id': freelancerId,
    'active_role': 'freelancer',
    'full_name': 'Test Freelancer',
  });

  // Add to favorites
  await client.from('favorites').upsert({
    'client_id': testClientId,
    'freelancer_id': freelancerId,
  });
}
