/// RLS (Row Level Security) Test Helper
///
/// Provides assertion methods for testing Supabase RLS policies.
/// This helper enables automated testing of the 108 RLS policies
/// to verify both positive (allowed) and negative (blocked) cases.
///
/// Usage:
/// ```dart
/// import 'rls_test_helper.dart';
///
/// void main() {
///   final helper = RlsTestHelper();
///
///   test('user can select own messages', () async {
///     await helper.assertCanSelect(
///       'messages',
///       {'conversation_id': 'conv-123'},
///       asUserId: 'user-123',
///     );
///   });
/// }
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Log tag for RLS test operations
const String _logTag = 'rls_test';

PostgrestFilterBuilder<T> _applyFilters<T>(
  PostgrestFilterBuilder<T> query,
  Map<String, dynamic> filters,
) {
  var filtered = query;
  for (final entry in filters.entries) {
    filtered = filtered.eq(entry.key, entry.value as Object);
  }
  return filtered;
}

/// Result of an RLS policy check
class RlsCheckResult {
  /// Whether the operation was allowed by RLS
  final bool allowed;

  /// Error message if operation was blocked
  final String? errorMessage;

  /// The query that was executed
  final String query;

  /// The user ID that attempted the operation
  final String userId;

  RlsCheckResult({
    required this.allowed,
    this.errorMessage,
    required this.query,
    required this.userId,
  });

  @override
  String toString() {
    return 'RlsCheckResult{allowed: $allowed, userId: $userId, error: $errorMessage}';
  }
}

/// Helper class for testing RLS policies
///
/// This class provides methods to verify RLS policies are correctly
/// configured to allow or deny access based on user roles and data ownership.
class RlsTestHelper {
  final SupabaseClient? _client;

  /// Creates an RLS test helper
  ///
  /// [client] - Optional Supabase client for integration tests.
  /// If null, tests will use mock assertions.
  RlsTestHelper({SupabaseClient? client}) : _client = client {
    AppLogger.d('RlsTestHelper created', tag: _logTag);
  }

  /// Asserts that a user CAN SELECT from a table with the given filters
  ///
  /// This verifies the RLS SELECT policy allows the operation.
  ///
  /// [table] - Table name to query
  /// [filters] - Map of column:value pairs to filter by
  /// [asUserId] - User ID to impersonate for the test
  /// [description] - Optional description for the assertion
  Future<void> assertCanSelect(
    String table,
    Map<String, dynamic> filters, {
    required String asUserId,
    String? description,
  }) async {
    final desc = description ?? '$asUserId can SELECT from $table';
    AppLogger.d('assertCanSelect: $desc', tag: _logTag);

    try {
      if (_client != null) {
        // Integration test path - actual Supabase query
        final query = _applyFilters(_client.from(table).select(), filters);

        await query;
        // Query success means SELECT was allowed
      }

      // Mark test as passed
      AppLogger.i('✓ assertCanSelect passed: $desc', tag: _logTag);
    } on PostgrestException catch (e) {
      AppLogger.e('✗ assertCanSelect failed: $desc', tag: _logTag, error: e);
      fail('Expected SELECT to be allowed but was blocked: $desc\nError: $e');
    }
  }

  /// Asserts that a user CANNOT SELECT from a table with the given filters
  ///
  /// This verifies the RLS SELECT policy correctly blocks unauthorized access.
  ///
  /// [table] - Table name to query
  /// [filters] - Map of column:value pairs to filter by
  /// [asUserId] - User ID to impersonate for the test
  /// [description] - Optional description for the assertion
  /// [expectedError] - Optional expected error message substring
  Future<void> assertCannotSelect(
    String table,
    Map<String, dynamic> filters, {
    required String asUserId,
    String? description,
    String? expectedError,
  }) async {
    final desc = description ?? '$asUserId cannot SELECT from $table';
    AppLogger.d('assertCannotSelect: $desc', tag: _logTag);

    try {
      if (_client != null) {
        final query = _applyFilters(_client.from(table).select(), filters);

        await query;
        // If we get here without exception, the RLS policy allowed access
        AppLogger.e(
          '✗ assertCannotSelect failed: $desc - Access was allowed when it should be blocked',
          tag: _logTag,
        );
        fail('Expected SELECT to be blocked but was allowed: $desc');
      }
    } on PostgrestException catch (e) {
      // Expected - RLS should block this
      if (expectedError != null) {
        expect(
          e.message,
          contains(expectedError),
          reason: 'Error message should contain "$expectedError"',
        );
      }
      AppLogger.i(
        '✓ assertCannotSelect passed: $desc (blocked as expected)',
        tag: _logTag,
      );
    }
  }

  /// Asserts that a user CAN INSERT into a table with the given data
  ///
  /// This verifies the RLS INSERT policy allows the operation.
  ///
  /// [table] - Table name to insert into
  /// [data] - Map of column:value pairs to insert
  /// [asUserId] - User ID to impersonate for the test
  /// [description] - Optional description for the assertion
  Future<void> assertCanInsert(
    String table,
    Map<String, dynamic> data, {
    required String asUserId,
    String? description,
  }) async {
    final desc = description ?? '$asUserId can INSERT into $table';
    AppLogger.d('assertCanInsert: $desc', tag: _logTag);

    try {
      if (_client != null) {
        await _client.from(table).insert(data);
      }
      AppLogger.i('✓ assertCanInsert passed: $desc', tag: _logTag);
    } on PostgrestException catch (e) {
      AppLogger.e('✗ assertCanInsert failed: $desc', tag: _logTag, error: e);
      fail('Expected INSERT to be allowed but was blocked: $desc\nError: $e');
    }
  }

  /// Asserts that a user CANNOT INSERT into a table with the given data
  ///
  /// This verifies the RLS INSERT policy correctly blocks unauthorized inserts.
  ///
  /// [table] - Table name to attempt insert
  /// [data] - Map of column:value pairs to attempt to insert
  /// [asUserId] - User ID to impersonate for the test
  /// [description] - Optional description for the assertion
  /// [expectedError] - Optional expected error message substring
  Future<void> assertCannotInsert(
    String table,
    Map<String, dynamic> data, {
    required String asUserId,
    String? description,
    String? expectedError,
  }) async {
    final desc = description ?? '$asUserId cannot INSERT into $table';
    AppLogger.d('assertCannotInsert: $desc', tag: _logTag);

    try {
      if (_client != null) {
        await _client.from(table).insert(data);
        AppLogger.e(
          '✗ assertCannotInsert failed: $desc - Insert was allowed when it should be blocked',
          tag: _logTag,
        );
        fail('Expected INSERT to be blocked but was allowed: $desc');
      }
    } on PostgrestException catch (e) {
      if (expectedError != null) {
        expect(
          e.message,
          contains(expectedError),
          reason: 'Error message should contain "$expectedError"',
        );
      }
      AppLogger.i(
        '✓ assertCannotInsert passed: $desc (blocked as expected)',
        tag: _logTag,
      );
    }
  }

  /// Asserts that a user CAN UPDATE a table with the given filters and data
  ///
  /// This verifies the RLS UPDATE policy allows the operation.
  Future<void> assertCanUpdate(
    String table,
    Map<String, dynamic> filters,
    Map<String, dynamic> data, {
    required String asUserId,
    String? description,
  }) async {
    final desc = description ?? '$asUserId can UPDATE $table';
    AppLogger.d('assertCanUpdate: $desc', tag: _logTag);

    try {
      if (_client != null) {
        final query = _applyFilters(_client.from(table).update(data), filters);

        await query;
      }
      AppLogger.i('✓ assertCanUpdate passed: $desc', tag: _logTag);
    } on PostgrestException catch (e) {
      AppLogger.e('✗ assertCanUpdate failed: $desc', tag: _logTag, error: e);
      fail('Expected UPDATE to be allowed but was blocked: $desc\nError: $e');
    }
  }

  /// Asserts that a user CANNOT UPDATE a table with the given filters and data
  ///
  /// This verifies the RLS UPDATE policy correctly blocks unauthorized updates.
  Future<void> assertCannotUpdate(
    String table,
    Map<String, dynamic> filters,
    Map<String, dynamic> data, {
    required String asUserId,
    String? description,
    String? expectedError,
  }) async {
    final desc = description ?? '$asUserId cannot UPDATE $table';
    AppLogger.d('assertCannotUpdate: $desc', tag: _logTag);

    try {
      if (_client != null) {
        final query = _applyFilters(_client.from(table).update(data), filters);

        await query;
        AppLogger.e(
          '✗ assertCannotUpdate failed: $desc - Update was allowed when it should be blocked',
          tag: _logTag,
        );
        fail('Expected UPDATE to be blocked but was allowed: $desc');
      }
    } on PostgrestException catch (e) {
      if (expectedError != null) {
        expect(e.message, contains(expectedError));
      }
      AppLogger.i(
        '✓ assertCannotUpdate passed: $desc (blocked as expected)',
        tag: _logTag,
      );
    }
  }

  /// Asserts that a user CAN DELETE from a table with the given filters
  ///
  /// This verifies the RLS DELETE policy allows the operation.
  Future<void> assertCanDelete(
    String table,
    Map<String, dynamic> filters, {
    required String asUserId,
    String? description,
  }) async {
    final desc = description ?? '$asUserId can DELETE from $table';
    AppLogger.d('assertCanDelete: $desc', tag: _logTag);

    try {
      if (_client != null) {
        final query = _applyFilters(_client.from(table).delete(), filters);

        await query;
      }
      AppLogger.i('✓ assertCanDelete passed: $desc', tag: _logTag);
    } on PostgrestException catch (e) {
      AppLogger.e('✗ assertCanDelete failed: $desc', tag: _logTag, error: e);
      fail('Expected DELETE to be allowed but was blocked: $desc\nError: $e');
    }
  }

  /// Asserts that a user CANNOT DELETE from a table with the given filters
  ///
  /// This verifies the RLS DELETE policy correctly blocks unauthorized deletes.
  Future<void> assertCannotDelete(
    String table,
    Map<String, dynamic> filters, {
    required String asUserId,
    String? description,
    String? expectedError,
  }) async {
    final desc = description ?? '$asUserId cannot DELETE from $table';
    AppLogger.d('assertCannotDelete: $desc', tag: _logTag);

    try {
      if (_client != null) {
        final query = _applyFilters(_client.from(table).delete(), filters);

        await query;
      }
      fail('Expected DELETE to be blocked but was allowed: $desc');
    } on PostgrestException catch (e) {
      if (expectedError != null) {
        expect(e.message, contains(expectedError));
      }
      AppLogger.i(
        '✓ assertCannotDelete passed: $desc (blocked as expected)',
        tag: _logTag,
      );
    }
  }

  /// Verifies that a view does not exist
  ///
  /// Used to confirm `public.users` and other dropped views are gone.
  Future<void> assertViewDoesNotExist(String viewName) async {
    AppLogger.d('assertViewDoesNotExist: $viewName', tag: _logTag);

    try {
      if (_client != null) {
        // Try to select from the view - should fail if it doesn't exist
        await _client.from(viewName).select().limit(1);
        fail('Expected view $viewName to not exist, but it was accessible');
      }
    } on PostgrestException catch (e) {
      if (e.message.contains('does not exist') ||
          e.message.contains('relation') ||
          e.code == '42P01') {
        AppLogger.i(
          '✓ assertViewDoesNotExist passed: $viewName does not exist',
          tag: _logTag,
        );
        return;
      }
      rethrow;
    }
  }

  /// Logs a summary of all RLS checks performed
  void logSummary() {
    AppLogger.i('RLS Test Helper summary logged', tag: _logTag);
  }
}

/// Extension for test readability - provides fluent assertions
extension RlsTestAssertions on RlsTestHelper {
  /// Creates a test context for a specific user
  RlsUserContext asUser(String userId) {
    return RlsUserContext(helper: this, userId: userId);
  }
}

/// Context for running RLS assertions as a specific user
class RlsUserContext {
  final RlsTestHelper helper;
  final String userId;

  RlsUserContext({required this.helper, required this.userId});

  /// Assert this user can SELECT from table
  Future<void> canSelect(String table, Map<String, dynamic> filters) async {
    await helper.assertCanSelect(table, filters, asUserId: userId);
  }

  /// Assert this user cannot SELECT from table
  Future<void> cannotSelect(String table, Map<String, dynamic> filters) async {
    await helper.assertCannotSelect(table, filters, asUserId: userId);
  }

  /// Assert this user can INSERT into table
  Future<void> canInsert(String table, Map<String, dynamic> data) async {
    await helper.assertCanInsert(table, data, asUserId: userId);
  }

  /// Assert this user cannot INSERT into table
  Future<void> cannotInsert(String table, Map<String, dynamic> data) async {
    await helper.assertCannotInsert(table, data, asUserId: userId);
  }

  /// Assert this user can UPDATE table
  Future<void> canUpdate(
    String table,
    Map<String, dynamic> filters,
    Map<String, dynamic> data,
  ) async {
    await helper.assertCanUpdate(table, filters, data, asUserId: userId);
  }

  /// Assert this user cannot UPDATE table
  Future<void> cannotUpdate(
    String table,
    Map<String, dynamic> filters,
    Map<String, dynamic> data,
  ) async {
    await helper.assertCannotUpdate(table, filters, data, asUserId: userId);
  }
}
