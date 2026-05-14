/// Storage RLS Test Suite (T50-T53)
///
/// Tests the storage RLS policies for signed URL access control.
/// Verifies that:
/// - T50: Participants can access chat attachments
/// - T51: Non-participants cannot access chat attachments
/// - T52: Owners can access task images
/// - T53: Admin can access all private storage
///
/// Run with: flutter test test/storage_rls_test.dart
/// With real Supabase: flutter test test/storage_rls_test.dart --dart-define=SUPABASE_INTEGRATION=1 --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'rls/fixtures/rls_test_users.dart';
import 'rls/storage_rls_test_harness.dart';
import 'supabase_test_helper.dart';

const String? _skipReason =
    String.fromEnvironment('SUPABASE_INTEGRATION', defaultValue: '') != '1'
    ? 'Requires Supabase; run with --dart-define=SUPABASE_INTEGRATION=1'
    : null;
const String _supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKeyDefine = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
);

String _supabaseConfigValue({
  required String dartDefineValue,
  required String environmentKey,
}) {
  final value = dartDefineValue.isNotEmpty
      ? dartDefineValue
      : Platform.environment[environmentKey];
  if (value == null || value.isEmpty) {
    throw StateError(
      '$environmentKey is required when SUPABASE_INTEGRATION=1',
    );
  }
  return value;
}

void main() {
  group('Storage RLS Security Tests (T50-T53)', skip: _skipReason, () {
    late StorageRlsTestHarness harness;

    setUpAll(() async {
      ensureSupabaseTestEnvironment();
      await Supabase.initialize(
        url: _supabaseConfigValue(
          dartDefineValue: _supabaseUrlDefine,
          environmentKey: 'SUPABASE_URL',
        ),
        anonKey: _supabaseConfigValue(
          dartDefineValue: _supabaseAnonKeyDefine,
          environmentKey: 'SUPABASE_ANON_KEY',
        ),
        debug: false,
        authOptions: FlutterAuthClientOptions(
          localStorage: supabaseTestLocalStorage,
          pkceAsyncStorage: supabaseTestPkceStorage,
        ),
      );
    });

    setUp(() {
      // Integration mode initializes Supabase in setUpAll, so use the real client.
      harness = StorageRlsTestHarness(client: Supabase.instance.client);
    });

    tearDown(() {
      try {
        harness.logSummary();
      } on Exception catch (e) {
        // Log but don't fail tearDown — prevents noise from masking real failures
        // ignore: avoid_print
        print('tearDown: harness.logSummary() failed: $e');
      }
    });

    // Test data - matches fixtures/storage_rls_test_data.sql
    const testConversationId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
    const testChatAttachmentPath =
        'convos/$testConversationId/test-attachment.jpg';
    const testTaskImagePath =
        '11111111-1111-1111-1111-111111111111/test-task-image.jpg';
    const testAvatarPath =
        '11111111-1111-1111-1111-111111111111/test-avatar.jpg';

    group('T50: Chat Attachments - Participant Access', () {
      test('T50a client participant CAN access chat attachment', () async {
        await harness.assertCanAccessStorage(
          bucket: 'chat-attachments',
          path: testChatAttachmentPath,
          asUserId: TestUsers.clientUser.id,
          description:
              'Client (participant) should access their conversation attachment',
        );
      });

      test('T50b freelancer participant CAN access chat attachment', () async {
        await harness.assertCanAccessStorage(
          bucket: 'chat-attachments',
          path: testChatAttachmentPath,
          asUserId: TestUsers.freelancerUser.id,
          description:
              'Freelancer (participant) should access their conversation attachment',
        );
      });
    });

    group('T51: Chat Attachments - Non-Participant Denial', () {
      test(
        'T51 other client (non-participant) CANNOT access chat attachment',
        () async {
          await harness.assertCannotAccessStorage(
            bucket: 'chat-attachments',
            path: testChatAttachmentPath,
            asUserId: TestUsers.otherClientUser.id,
            description:
                'Other client (non-participant) should be blocked from accessing chat attachment',
            expectedError: '403',
          );
        },
      );

      test('T51b anonymous user CANNOT access chat attachment', () async {
        await harness.assertCannotAccessStorage(
          bucket: 'chat-attachments',
          path: testChatAttachmentPath,
          asUserId: '',
          description:
              'Anonymous user should be blocked from accessing chat attachment',
          expectedError: 'JWT',
        );
      });
    });

    group('T52: Task Images - Owner Access', () {
      test('T52a owner CAN access their task image', () async {
        await harness.assertCanAccessStorage(
          bucket: 'task-images',
          path: testTaskImagePath,
          asUserId: TestUsers.clientUser.id,
          description: 'Owner should access their task image',
        );
      });

      test('T52b non-owner CANNOT access others task image', () async {
        await harness.assertCannotAccessStorage(
          bucket: 'task-images',
          path: testTaskImagePath,
          asUserId: TestUsers.otherClientUser.id,
          description:
              'Non-owner should be blocked from accessing others task image',
          expectedError: '403',
        );
      });
    });

    group('T53: Admin Access - All Private Storage', () {
      test('T53a admin CAN access any chat attachment', () async {
        await harness.assertCanAccessStorage(
          bucket: 'chat-attachments',
          path: testChatAttachmentPath,
          asUserId: TestUsers.adminUser.id,
          description:
              'Admin should access any chat attachment for dispute resolution',
        );
      });

      test('T53b admin CAN access any task image', () async {
        await harness.assertCanAccessStorage(
          bucket: 'task-images',
          path: testTaskImagePath,
          asUserId: TestUsers.adminUser.id,
          description:
              'Admin should access any task image for dispute resolution',
        );
      });

      test('T53c admin CAN access any avatar', () async {
        await harness.assertCanAccessStorage(
          bucket: 'avatars',
          path: testAvatarPath,
          asUserId: TestUsers.adminUser.id,
          description: 'Admin should access any avatar for dispute resolution',
        );
      });
    });

    group('Additional Security: Anonymous Access Denial', () {
      test('anonymous user CANNOT access task images', () async {
        await harness.assertCannotAccessStorage(
          bucket: 'task-images',
          path: testTaskImagePath,
          asUserId: '',
          description: 'Anonymous user should be blocked from task images',
          expectedError: 'JWT',
        );
      });

      test('anonymous user CANNOT access avatars', () async {
        await harness.assertCannotAccessStorage(
          bucket: 'avatars',
          path: testAvatarPath,
          asUserId: '',
          description: 'Anonymous user should be blocked from avatars',
          expectedError: 'JWT',
        );
      });
    });
  });
}
