/// Unit tests for Chat Creation Matrix functionality in MessageService.
///
/// Tests cover:
/// - Direct DM creation via RPC (when feature flag enabled)
/// - Legacy direct INSERT path (when feature flag disabled)
/// - Error handling for favorites enforcement
/// - Error handling for role enforcement
/// - Rate limiting behavior
/// - Idempotency (duplicate calls return same conversation)
/// - Network timeout handling
/// - Feature flag caching
///
/// Uses mocktail for mocking Supabase client.
// ignore_for_file: argument_type_not_assignable
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sline_app/features/chat/services/message_service.dart';

import '../fixtures/chat_fixtures.dart';
import '../helpers/mock_supabase.dart';

void main() {
  group('MessageService - Chat Creation Matrix', () {
    late MessageService messageService;
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();

      // Setup auth mock
      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(createMockClientUser(
        id: testClientId,
      ));

      messageService = MessageService(mockClient);
    });

    tearDown(() {
      reset(mockClient);
      reset(mockAuth);
    });

    group('Feature Flag Check', () {
      test('should use legacy INSERT path when feature flag is disabled', () async {
        // Arrange: Feature flag disabled
        _setupFeatureFlag(mockClient, enabled: false);

        // Setup legacy path (direct query + insert)
        _setupLegacyConversationQuery(mockClient, exists: false);
        _setupLegacyConversationInsert(mockClient);

        // Act
        final result = await messageService.createOrGetConversation(
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.id, equals(testConversationId));

        // Verify RPC was NOT called
        verifyNever(() => mockClient.rpc(
          'start_direct_conversation_v1',
          params: any(named: 'params'),
        ));
      });

      test('should use atomic RPC when feature flag is enabled', () async {
        // Arrange: Feature flag enabled
        _setupFeatureFlag(mockClient, enabled: true);

        // Setup RPC response
        when(() => mockClient.rpc(
          'start_direct_conversation_v1',
          params: {'p_target_id': testFreelancerAId},
        )).thenAnswer((_) async => newDirectConversationResponse);

               when(() => mockClient.from('conversations').select(any()).single() as dynamic)
            .thenAnswer((_) async => newDirectConversationResponse);

        // Act
        final result = await messageService.createOrGetConversation(
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        // Assert
        expect(result, isNotNull);

        // Verify RPC WAS called
        verify(() => mockClient.rpc(
          'start_direct_conversation_v1',
          params: {'p_target_id': testFreelancerAId},
        )).called(1);
      });

      test('should cache feature flag for 1 minute', () async {
        // Arrange
        _setupFeatureFlag(mockClient, enabled: true);

        when(() => mockClient.rpc(
          'start_direct_conversation_v1',
          params: any(named: 'params'),
        )).thenAnswer((_) async => newDirectConversationResponse);

        when(() => mockClient.from('conversations').select(any()).single() as dynamic)
            .thenAnswer((_) async => newDirectConversationResponse);

        // Act: Call twice within short time
        await messageService.createOrGetConversation(
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        await messageService.createOrGetConversation(
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        // Assert: Feature flag queried only once (cached)
        verify(() => mockClient.from('app_config').select('value').eq('key', 'enable_direct_conversation_rpc').maybeSingle()).called(1);
      });
    });

    group('Direct DM via RPC (Feature Flag Enabled)', () {
      setUp(() {
        _setupFeatureFlag(mockClient, enabled: true);
      });

      test('create DM to favorite succeeds', () async {
        // Arrange
        when(() => mockClient.rpc(
          'start_direct_conversation_v1',
          params: {'p_target_id': testFreelancerAId},
        )).thenAnswer((_) async => newDirectConversationResponse);

        when(() => mockClient.from('conversations').select(any()).single() as dynamic)
            .thenAnswer((_) async => newDirectConversationResponse);

        // Act
        final result = await messageService.createOrGetConversation(
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.id, equals('550e8400-e29b-41d4-a716-446655440032'));
        expect(result.taskId, isNull);
        expect(result.user1Id, equals(testClientId));
        expect(result.user2Id, equals(testFreelancerAId));
      });

      test('create DM to non-favorite fails with appropriate error', () async {
        // Arrange: RPC throws "favorites list" error
        when(() => mockClient.rpc(
          'start_direct_conversation_v1',
          params: {'p_target_id': testFreelancerBId},
        )).thenThrow(MockPostgrestException(
          message: 'You can only message freelancers in your favorites list',
          code: 'P0001',
        ));

        // Act & Assert
        expect(
          () => messageService.createOrGetConversation(
            user1Id: testClientId,
            user2Id: testFreelancerBId,
          ),
          throwsA(isA<PostgrestException>().having(
            (e) => e.message,
            'message',
            contains('favorites list'),
          )),
        );
      });

      test('freelancer creating DM fails with role error', () async {
        // Arrange: Freelancer user
        when(() => mockAuth.currentUser).thenReturn(createMockFreelancerUser(
          id: testFreelancerAId,
        ));

        when(() => mockClient.rpc(
          'start_direct_conversation_v1',
          params: {'p_target_id': testClientId},
        )).thenThrow(MockPostgrestException(
          message: 'Freelancers cannot start direct conversations',
          code: 'P0001',
        ));

        // Act & Assert
        expect(
          () => messageService.createOrGetConversation(
            user1Id: testFreelancerAId,
            user2Id: testClientId,
          ),
          throwsA(isA<PostgrestException>().having(
            (e) => e.message,
            'message',
            contains('Freelancers cannot start'),
          )),
        );
      });

      test('rate limit exceeded error', () async {
        // Arrange
        when(() => mockClient.rpc(
          'start_direct_conversation_v1',
          params: any(named: 'params'),
        )).thenThrow(MockPostgrestException(
          message: 'Rate limit exceeded: maximum 20 conversations per hour',
          code: 'P0001',
        ));

        // Act & Assert
        expect(
          () => messageService.createOrGetConversation(
            user1Id: testClientId,
            user2Id: testFreelancerAId,
          ),
          throwsA(isA<PostgrestException>().having(
            (e) => e.message,
            'message',
            contains('Rate limit exceeded'),
          )),
        );
      });

      test('target user not found error', () async {
        // Arrange
        when(() => mockClient.rpc(
          'start_direct_conversation_v1',
          params: any(named: 'params'),
        )).thenThrow(MockPostgrestException(
          message: 'Target user not found',
          code: 'P0001',
        ));

        // Act & Assert
        expect(
          () => messageService.createOrGetConversation(
            user1Id: testClientId,
            user2Id: 'non-existent-user-id',
          ),
          throwsA(isA<PostgrestException>().having(
            (e) => e.message,
            'message',
            contains('Target user not found'),
          )),
        );
      });

      test('self-conversation error', () async {
        // Arrange
        when(() => mockClient.rpc(
          'start_direct_conversation_v1',
          params: any(named: 'params'),
        )).thenThrow(MockPostgrestException(
          message: 'Cannot create conversation with yourself',
          code: 'P0001',
        ));

        // Act & Assert
        expect(
          () => messageService.createOrGetConversation(
            user1Id: testClientId,
            user2Id: testClientId, // Same user
          ),
          throwsA(isA<PostgrestException>().having(
            (e) => e.message,
            'message',
            contains('Cannot create conversation with yourself'),
          )),
        );
      });

      test('idempotent: duplicate calls return same conversation', () async {
        // Arrange: Both calls return same conversation
        when(() => mockClient.rpc(
          'start_direct_conversation_v1',
          params: {'p_target_id': testFreelancerAId},
        )).thenAnswer((_) async => existingDirectConversationResponse);

        when(() => mockClient.from('conversations').select(any()).single() as dynamic)
            .thenAnswer((_) async => existingDirectConversationResponse);

        // Act: Call twice
        final result1 = await messageService.createOrGetConversation(
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        final result2 = await messageService.createOrGetConversation(
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        // Assert: Same conversation ID
        expect(result1.id, equals(result2.id));
        expect(result1.id, equals(testConversationId));
      });

      test('network timeout throws TimeoutException', () async {
        // Arrange: RPC times out
        when(() => mockClient.rpc(
          'start_direct_conversation_v1',
          params: any(named: 'params'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 11)); // Exceeds 10s timeout
          return newDirectConversationResponse;
        });

        // Act & Assert
        expect(
          () => messageService.createOrGetConversation(
            user1Id: testClientId,
            user2Id: testFreelancerAId,
            timeout: const Duration(seconds: 10),
          ),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('Legacy Path (Feature Flag Disabled)', () {
      setUp(() {
        _setupFeatureFlag(mockClient, enabled: false);
      });

      test('legacy INSERT path creates new conversation when none exists', () async {
        // Arrange: No existing conversation
        _setupLegacyConversationQuery(mockClient, exists: false);
        _setupLegacyConversationInsert(mockClient);

        // Act
        final result = await messageService.createOrGetConversation(
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        // Assert
        expect(result, isNotNull);
        verify(() => mockClient.from('conversations').insert(any())).called(1);
      });

      test('legacy INSERT path returns existing conversation', () async {
        // Arrange: Existing conversation
        _setupLegacyConversationQuery(mockClient, exists: true);

        // Act
        final result = await messageService.createOrGetConversation(
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.id, equals(testConversationId));

        // Verify insert was NOT called
        verifyNever(() => mockClient.from('conversations').insert(any()));
      });
    });

    group('Task-Linked Conversations', () {
      test('always uses start_task_conversation_v1 RPC regardless of feature flag', () async {
        // Arrange: Feature flag disabled (but task-linked should still use RPC)
        _setupFeatureFlag(mockClient, enabled: false);

        when(() => mockClient.rpc(
          'start_task_conversation_v1',
          params: {'p_task_id': testTaskId},
        )).thenAnswer((_) async => existingTaskConversation);

        when(() => mockClient.from('conversations').select(any()).single() as dynamic)
            .thenAnswer((_) async => existingTaskConversation);

        // Act
        final result = await messageService.createOrGetConversation(
          taskId: testTaskId,
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.taskId, equals(testTaskId));

        // Verify task RPC was called
        verify(() => mockClient.rpc(
          'start_task_conversation_v1',
          params: {'p_task_id': testTaskId},
        )).called(1);
      });
    });
  });
}

// ============================================================================
// Helper Functions
// ============================================================================

void _setupFeatureFlag(MockSupabaseClient mockClient, {required bool enabled}) {
  final mockQueryBuilder = _MockPostgrestQueryBuilder();
  final mockFilterBuilder = _MockPostgrestFilterBuilder();

  when(() => mockClient.from('app_config')).thenReturn(mockQueryBuilder as dynamic);
  when(() => mockQueryBuilder.select(any())).thenReturn(mockFilterBuilder);
  when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockFilterBuilder);
  when(() => mockFilterBuilder.maybeSingle() as dynamic).thenAnswer((_) async => {'value': enabled ? 'true' : 'false'});
}

void _setupLegacyConversationQuery(MockSupabaseClient mockClient, {required bool exists}) {
  final mockFilterBuilder = _MockPostgrestFilterBuilder();
  final mockTransformBuilder = _MockPostgrestTransformBuilder();

  when(() => mockClient.from('conversations').select(any())).thenReturn(mockFilterBuilder);
  when(() => mockFilterBuilder.is_(any(), any())).thenReturn(mockFilterBuilder);
  when(() => mockFilterBuilder.or(any())).thenReturn(mockFilterBuilder);
  when(() => mockFilterBuilder.limit(any())).thenReturn(mockTransformBuilder);
  when(() => mockTransformBuilder.timeout(any()) as dynamic)
      .thenAnswer((_) async => exists ? [existingDirectConversation] : []);
}

void _setupLegacyConversationInsert(MockSupabaseClient mockClient) {
  when(() => mockClient.from('conversations').insert(any()))
      .thenReturn(_MockPostgrestFilterBuilder());
}

// ============================================================================
// Mock Classes (minimal; behavior stubbed via when() in tests)
// ============================================================================

class _MockPostgrestQueryBuilder extends Mock implements PostgrestQueryBuilder {}

class _MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}

class _MockPostgrestTransformBuilder extends Mock implements PostgrestTransformBuilder {}

/// Mock for PostgrestException that can be thrown in tests
class MockPostgrestException extends PostgrestException {
  MockPostgrestException({
    required super.message,
    super.code,
    super.details,
    super.hint,
  });
}
