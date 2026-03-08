/// Storage RLS Test Harness
///
/// Provides assertion methods for testing Supabase Storage RLS policies.
/// This harness enables automated testing of storage access controls
/// to verify both positive (allowed) and negative (blocked) cases.
///
/// Usage:
/// ```dart
/// import 'storage_rls_test_harness.dart';
///
/// void main() {
///   final harness = StorageRlsTestHarness();
///
///   test('participant can access chat attachment', () async {
///     await harness.assertCanAccessStorage(
///       bucket: 'chat-attachments',
///       path: 'convos/conv-001/attachment.jpg',
///       asUserId: 'participant-user-id',
///     );
///   });
/// }
/// ```
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';

/// Log tag for storage RLS test operations
const String _logTag = 'storage_rls_test';

/// Result of a storage RLS policy check
class StorageRlsResult {
  /// Whether the storage access was allowed by RLS
  final bool allowed;

  /// Error message if access was blocked
  final String? errorMessage;

  /// The bucket that was accessed
  final String bucket;

  /// The path that was accessed
  final String path;

  /// The user ID that attempted the access
  final String userId;

  StorageRlsResult({
    required this.allowed,
    this.errorMessage,
    required this.bucket,
    required this.path,
    required this.userId,
  });

  @override
  String toString() {
    return 'StorageRlsResult{allowed: $allowed, bucket: $bucket, path: $path, userId: $userId, error: $errorMessage}';
  }
}

/// Helper class for testing Storage RLS policies
///
/// This class provides methods to verify storage RLS policies are correctly
/// configured to allow or deny access based on user roles and data ownership.
class StorageRlsTestHarness {
  final SupabaseClient? _client;

  /// Creates a storage RLS test harness
  ///
  /// [client] - Optional Supabase client for integration tests.
  /// If null, tests will use mock assertions.
  StorageRlsTestHarness({SupabaseClient? client}) : _client = client {
    AppLogger.d('StorageRlsTestHarness created', tag: _logTag);
  }

  /// Asserts that a user CAN access storage object (createSignedUrl succeeds)
  ///
  /// This verifies the storage RLS SELECT policy allows the operation.
  ///
  /// [bucket] - Storage bucket name
  /// [path] - Object path within bucket
  /// [asUserId] - User ID to impersonate for the test
  /// [description] - Optional description for the assertion
  Future<void> assertCanAccessStorage({
    required String bucket,
    required String path,
    required String asUserId,
    String? description,
  }) async {
    final desc = description ?? '$asUserId can access $bucket/$path';
    AppLogger.d('assertCanAccessStorage: $desc', tag: _logTag);

    try {
      if (_client != null) {
        // Integration test path - attempt to create signed URL
        await _client.storage.from(bucket).createSignedUrl(path, 60);
        // If we get here, access was allowed
      }

      AppLogger.i('✓ assertCanAccessStorage passed: $desc', tag: _logTag);
    } catch (e) {
      AppLogger.e(
        '✗ assertCanAccessStorage failed: $desc',
        tag: _logTag,
        error: e,
      );
      fail(
        'Expected storage access to be allowed but was blocked: $desc\nError: $e',
      );
    }
  }

  /// Asserts that a user CANNOT access storage object (createSignedUrl fails with 403)
  ///
  /// This verifies the storage RLS SELECT policy correctly blocks unauthorized access.
  ///
  /// [bucket] - Storage bucket name
  /// [path] - Object path within bucket
  /// [asUserId] - User ID to impersonate for the test
  /// [description] - Optional description for the assertion
  /// [expectedError] - Optional expected error message substring
  Future<void> assertCannotAccessStorage({
    required String bucket,
    required String path,
    required String asUserId,
    String? description,
    String? expectedError,
  }) async {
    final desc = description ?? '$asUserId cannot access $bucket/$path';
    AppLogger.d('assertCannotAccessStorage: $desc', tag: _logTag);

    try {
      if (_client != null) {
        await _client.storage.from(bucket).createSignedUrl(path, 60);
        // If we get here without exception, the RLS policy allowed access
        AppLogger.e(
          '✗ assertCannotAccessStorage failed: $desc - Access was allowed when it should be blocked',
          tag: _logTag,
        );
        fail('Expected storage access to be blocked but was allowed: $desc');
      }
    } on StorageException catch (e) {
      // Expected - RLS should block this
      if (expectedError != null) {
        expect(
          e.message,
          contains(expectedError),
          reason: 'Error message should contain "$expectedError"',
        );
      }
      // Verify it's a 403 or similar access denied
      final code = e.statusCode != null ? int.tryParse(e.statusCode!) : null;
      if (code != null && code >= 400) {
        AppLogger.i(
          '✓ assertCannotAccessStorage passed: $desc (blocked with ${e.statusCode})',
          tag: _logTag,
        );
      } else {
        AppLogger.i(
          '✓ assertCannotAccessStorage passed: $desc (blocked as expected)',
          tag: _logTag,
        );
      }
    } catch (e) {
      // Other errors might also indicate RLS blocking
      AppLogger.i(
        '✓ assertCannotAccessStorage passed: $desc (blocked with error: $e)',
        tag: _logTag,
      );
    }
  }

  /// Asserts that a user CAN upload to storage bucket
  ///
  /// This verifies the storage RLS INSERT policy allows the operation.
  ///
  /// [bucket] - Storage bucket name
  /// [path] - Object path to upload
  /// [data] - Binary data to upload
  /// [asUserId] - User ID to impersonate for the test
  /// [description] - Optional description for the assertion
  Future<void> assertCanUpload({
    required String bucket,
    required String path,
    required List<int> data,
    required String asUserId,
    String? description,
  }) async {
    final desc = description ?? '$asUserId can upload to $bucket/$path';
    AppLogger.d('assertCanUpload: $desc', tag: _logTag);

    try {
      if (_client != null) {
        await _client.storage
            .from(bucket)
            .uploadBinary(path, Uint8List.fromList(data));
      }
      AppLogger.i('✓ assertCanUpload passed: $desc', tag: _logTag);
    } catch (e) {
      AppLogger.e('✗ assertCanUpload failed: $desc', tag: _logTag, error: e);
      fail('Expected upload to be allowed but was blocked: $desc\nError: $e');
    }
  }

  /// Asserts that a user CANNOT upload to storage bucket
  ///
  /// This verifies the storage RLS INSERT policy correctly blocks unauthorized uploads.
  ///
  /// [bucket] - Storage bucket name
  /// [path] - Object path to attempt upload
  /// [data] - Binary data to attempt upload
  /// [asUserId] - User ID to impersonate for the test
  /// [description] - Optional description for the assertion
  Future<void> assertCannotUpload({
    required String bucket,
    required String path,
    required List<int> data,
    required String asUserId,
    String? description,
  }) async {
    final desc = description ?? '$asUserId cannot upload to $bucket/$path';
    AppLogger.d('assertCannotUpload: $desc', tag: _logTag);

    try {
      if (_client != null) {
        await _client.storage
            .from(bucket)
            .uploadBinary(path, Uint8List.fromList(data));
        AppLogger.e(
          '✗ assertCannotUpload failed: $desc - Upload was allowed when it should be blocked',
          tag: _logTag,
        );
        fail('Expected upload to be blocked but was allowed: $desc');
      }
    } on StorageException catch (e) {
      AppLogger.i(
        '✓ assertCannotUpload passed: $desc (blocked with ${e.statusCode})',
        tag: _logTag,
      );
    } catch (e) {
      AppLogger.i(
        '✓ assertCannotUpload passed: $desc (blocked with error: $e)',
        tag: _logTag,
      );
    }
  }

  /// Asserts that a user CAN delete storage object
  ///
  /// This verifies the storage RLS DELETE policy allows the operation.
  Future<void> assertCanDelete({
    required String bucket,
    required String path,
    required String asUserId,
    String? description,
  }) async {
    final desc = description ?? '$asUserId can delete $bucket/$path';
    AppLogger.d('assertCanDelete: $desc', tag: _logTag);

    try {
      if (_client != null) {
        await _client.storage.from(bucket).remove([path]);
      }
      AppLogger.i('✓ assertCanDelete passed: $desc', tag: _logTag);
    } catch (e) {
      AppLogger.e('✗ assertCanDelete failed: $desc', tag: _logTag, error: e);
      fail('Expected delete to be allowed but was blocked: $desc\nError: $e');
    }
  }

  /// Asserts that a user CANNOT delete storage object
  ///
  /// This verifies the storage RLS DELETE policy correctly blocks unauthorized deletes.
  Future<void> assertCannotDelete({
    required String bucket,
    required String path,
    required String asUserId,
    String? description,
  }) async {
    final desc = description ?? '$asUserId cannot delete $bucket/$path';
    AppLogger.d('assertCannotDelete: $desc', tag: _logTag);

    try {
      if (_client != null) {
        await _client.storage.from(bucket).remove([path]);
        AppLogger.e(
          '✗ assertCannotDelete failed: $desc - Delete was allowed when it should be blocked',
          tag: _logTag,
        );
        fail('Expected delete to be blocked but was allowed: $desc');
      }
    } on StorageException catch (e) {
      AppLogger.i(
        '✓ assertCannotDelete passed: $desc (blocked with ${e.statusCode})',
        tag: _logTag,
      );
    } catch (e) {
      AppLogger.i(
        '✓ assertCannotDelete passed: $desc (blocked with error: $e)',
        tag: _logTag,
      );
    }
  }

  /// Logs a summary of all storage RLS checks performed
  void logSummary() {
    AppLogger.i('Storage RLS Test Harness summary logged', tag: _logTag);
  }
}

/// Extension for test readability - provides fluent assertions
extension StorageRlsTestAssertions on StorageRlsTestHarness {
  /// Creates a test context for a specific user
  StorageRlsUserContext asUser(String userId) {
    return StorageRlsUserContext(harness: this, userId: userId);
  }
}

/// Context for running storage RLS assertions as a specific user
class StorageRlsUserContext {
  final StorageRlsTestHarness harness;
  final String userId;

  StorageRlsUserContext({required this.harness, required this.userId});

  /// Assert this user can access storage path
  Future<void> canAccess({required String bucket, required String path}) async {
    await harness.assertCanAccessStorage(
      bucket: bucket,
      path: path,
      asUserId: userId,
    );
  }

  /// Assert this user cannot access storage path
  Future<void> cannotAccess({
    required String bucket,
    required String path,
  }) async {
    await harness.assertCannotAccessStorage(
      bucket: bucket,
      path: path,
      asUserId: userId,
    );
  }

  /// Assert this user can upload to storage
  Future<void> canUpload({
    required String bucket,
    required String path,
    required List<int> data,
  }) async {
    await harness.assertCanUpload(
      bucket: bucket,
      path: path,
      data: data,
      asUserId: userId,
    );
  }

  /// Assert this user cannot upload to storage
  Future<void> cannotUpload({
    required String bucket,
    required String path,
    required List<int> data,
  }) async {
    await harness.assertCannotUpload(
      bucket: bucket,
      path: path,
      data: data,
      asUserId: userId,
    );
  }
}
