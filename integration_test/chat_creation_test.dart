/// Integration tests for Chat Creation Matrix E2E flows.
///
/// These tests run against a real Supabase instance (local or test project).
/// They verify the complete flow from UI through backend.
///
/// Prerequisites:
/// - Supabase local running (`supabase start`)
/// - Test fixtures seeded
/// - Feature flag configured
///
/// Run: `flutter test integration_test/chat_creation_test.dart`
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../test/fixtures/chat_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Creation Matrix E2E Tests', () {
    late SupabaseClient client;

    setUpAll(() async {
      // Initialize Supabase (use local instance for testing)
      await Supabase.initialize(
        url: 'http://localhost:54321', // Supabase local default
        anonKey: 'your-local-anon-key',
      );
      client = Supabase.instance.client;

      // Seed test data
      await _seedTestData(client);
    });

    tearDownAll(() async {
      // Cleanup test data
      await _cleanupTestData(client);
    });

    test('T1: Client favorites freelancer then starts DM', () async {
      // Arrange: Ensure favorite exists
      await client.from('favorites').upsert(clientFavoritesFreelancerA);

      // Act: Create conversation via RPC
      final result = await client.rpc(
        'start_direct_conversation_v1',
        params: {'p_target_id': testFreelancerAId},
      );

      // Assert
      expect(result, isNotNull);
      expect(result['task_id'], isNull);
      expect(result['user1_id'], equals(testClientId));
      expect(result['user2_id'], equals(testFreelancerAId));
    });

    test('T2: Freelancer bid creates task-linked conversation', () async {
      // Arrange: Create a task and bid
      await _createTestTaskAndBid(client);

      // Act: Freelancer calls task conversation RPC
      final result = await client.rpc(
        'start_task_conversation_v1',
        params: {'p_task_id': testTaskId},
      );

      // Assert
      expect(result, isNotNull);
      expect(result['task_id'], equals(testTaskId));
    });

    test('T3: Client rejects bid creates conversation (reject flow)', () async {
      // Arrange: Create task with pending bid
      final requestId = await _createTestTaskWithBid(client);

      // Act: Client rejects the bid (this creates conversation via GUC exception)
      final result = await client.rpc(
        'reject_task_request',
        params: {'p_task_id': testTaskId, 'p_request_id': requestId},
      );

      // Assert
      expect(result, isNotNull); // Returns conversation ID
    });

    test('T4: Freelancer cannot start DM with client', () async {
      // Arrange: Authenticate as freelancer
      await _authenticateAsUser(client, testFreelancerAId);

      // Act & Assert: Should throw error
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

    test('T5: Client cannot DM without favorites', () async {
      // Arrange: Ensure NO favorite for freelancer B
      await client
          .from('favorites')
          .delete()
          .eq('client_id', testClientId)
          .eq('freelancer_id', testFreelancerBId);

      // Act & Assert
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

    test('T6: Rate limit blocks after 20 conversations', () async {
      // Arrange: Create 20 conversations first
      for (var i = 0; i < 20; i++) {
        final freelancerId = 'freelancer-$i-uuid';

        // Add to favorites
        await client.from('favorites').upsert({
          'id': 'fav-$i',
          'client_id': testClientId,
          'freelancer_id': freelancerId,
        });

        // Add profile
        await client.from('profiles').upsert({
          'id': freelancerId,
          'active_role': 'freelancer',
          'full_name': 'Test Freelancer $i',
        });

        // Create conversation
        await client.rpc(
          'start_direct_conversation_v1',
          params: {'p_target_id': freelancerId},
        );
      }

      // Act & Assert: 21st should fail
      expect(
        () => client.rpc(
          'start_direct_conversation_v1',
          params: {'p_target_id': 'another-freelancer'},
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

    test('T7: Idempotent - duplicate calls return same conversation', () async {
      // Arrange
      await client.from('favorites').upsert(clientFavoritesFreelancerA);

      // Act: Call twice
      final result1 = await client.rpc(
        'start_direct_conversation_v1',
        params: {'p_target_id': testFreelancerAId},
      );

      final result2 = await client.rpc(
        'start_direct_conversation_v1',
        params: {'p_target_id': testFreelancerAId},
      );

      // Assert
      expect(result1['id'], equals(result2['id']));
    });
  });
}

// ============================================================================
// Test Helpers
// ============================================================================

Future<void> _seedTestData(SupabaseClient client) async {
  // Create test profiles
  await client.from('profiles').upsert([
    chatClientProfile,
    chatFreelancerAProfile,
    chatFreelancerBProfile,
  ]);

  // Create favorite relationship
  await client.from('favorites').upsert(clientFavoritesFreelancerA);
}

Future<void> _cleanupTestData(SupabaseClient client) async {
  // Clean up conversations created by tests
  final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

  await client
      .from('conversations')
      .delete()
      .gte('created_at', oneHourAgo.toIso8601String());

  // Clean up test favorites (except fixture)
  await client
      .from('favorites')
      .delete()
      .neq('id', clientFavoritesFreelancerA['id']);
}

Future<void> _authenticateAsUser(SupabaseClient client, String userId) async {
  // In real tests, you'd use a service key or test auth flow
  // This is a placeholder
}

Future<void> _createTestTaskAndBid(SupabaseClient client) async {
  // Create task
  await client.from('tasks').upsert({
    'id': testTaskId,
    'title': 'Test Task',
    'owner_id': testClientId,
    'task_type': 'tender',
    'status': 'open',
  });

  // Create bid
  await client.from('task_requests').upsert({
    'id': 'test-request-id',
    'task_id': testTaskId,
    'freelancer_id': testFreelancerAId,
    'status': 'pending',
  });
}

Future<String> _createTestTaskWithBid(SupabaseClient client) async {
  await _createTestTaskAndBid(client);
  return 'test-request-id';
}
