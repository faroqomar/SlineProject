/// Mock Supabase client and related classes for testing
///
/// Provides mock implementations of Supabase client classes using mocktail,
/// following the patterns established in the existing test suite.
///
/// This file provides minimal mock classes that can be configured as needed
/// in individual tests. The mocks follow the same pattern used in
/// test/unit/auth/auth_repository_test.dart.
///
/// Usage:
/// ```dart
/// import '../helpers/mock_supabase.dart';
///
/// void main() {
///   late MockSupabaseClient mockClient;
///   late MockGoTrueClient mockAuth;
///
///   setUp(() {
///     mockClient = MockSupabaseClient();
///     mockAuth = MockGoTrueClient();
///     when(() => mockClient.auth).thenReturn(mockAuth);
///   });
/// }
/// ```
library;

import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Log tag for mock operations
const String _logTag = 'test_fixture';

/// Mock implementation of [SupabaseClient] for testing
class MockSupabaseClient extends Mock implements SupabaseClient {
  MockSupabaseClient();
}

/// Mock implementation of [GoTrueClient] for auth operations
class MockGoTrueClient extends Mock implements GoTrueClient {
  MockGoTrueClient();
}

/// Mock implementation of [User] for auth user testing
class MockUser extends Mock implements User {}

/// Mock implementation of [Session] for session testing
class MockSession extends Mock implements Session {}

/// Helper to configure a [MockUser] with the specified properties
void configureMockUser(
  MockUser user, {
  required String id,
  String? email,
  String? role,
  Map<String, dynamic>? appMetadata,
  Map<String, dynamic>? userMetadata,
}) {
  AppLogger.d('Configuring MockUser with id: $id', tag: _logTag);
  when(() => user.id).thenReturn(id);
  when(() => user.email).thenReturn(email ?? 'test@test.com');
  when(() => user.role).thenReturn(role ?? 'authenticated');
  when(() => user.appMetadata).thenReturn(appMetadata ?? <String, dynamic>{});
  when(() => user.userMetadata).thenReturn(userMetadata ?? <String, dynamic>{});
}

/// Helper to configure a [MockSession] with the specified properties
void configureMockSession(
  MockSession session, {
  String? accessToken,
  String? refreshToken,
  MockUser? user,
  int? expiresIn,
}) {
  AppLogger.d('Configuring MockSession', tag: _logTag);
  when(
    () => session.accessToken,
  ).thenReturn(accessToken ?? 'mock-access-token');
  when(
    () => session.refreshToken,
  ).thenReturn(refreshToken ?? 'mock-refresh-token');
  when(() => session.user).thenReturn(user ?? MockUser());
  when(() => session.expiresIn).thenReturn(expiresIn ?? 3600);
}

/// Factory function to create a fully configured mock Supabase client
///
/// This creates a [MockSupabaseClient] with the auth client pre-configured.
/// Additional behavior should be configured in individual tests.
MockSupabaseClient createMockSupabaseClient({MockGoTrueClient? authClient}) {
  AppLogger.d('Creating mock Supabase client via factory', tag: _logTag);
  final mockClient = MockSupabaseClient();
  final mockAuth = authClient ?? MockGoTrueClient();
  when(() => mockClient.auth).thenReturn(mockAuth);
  return mockClient;
}

/// Helper to create and configure a mock user with client role
MockUser createMockClientUser({String? id, String? email}) {
  final user = MockUser();
  configureMockUser(
    user,
    id: id ?? 'client-user-id',
    email: email ?? 'client@test.com',
    appMetadata: <String, dynamic>{'active_role': 'client'},
    userMetadata: <String, dynamic>{'full_name': 'Test Client'},
  );
  return user;
}

/// Helper to create and configure a mock user with freelancer role
MockUser createMockFreelancerUser({String? id, String? email}) {
  final user = MockUser();
  configureMockUser(
    user,
    id: id ?? 'freelancer-user-id',
    email: email ?? 'freelancer@test.com',
    appMetadata: <String, dynamic>{'active_role': 'freelancer'},
    userMetadata: <String, dynamic>{'full_name': 'Test Freelancer'},
  );
  return user;
}

/// Helper to create and configure a mock session with a specific role in JWT
MockSession createMockSessionWithRole(
  String role, {
  String? userId,
  String? email,
  String? accessToken,
}) {
  final user = MockUser();
  configureMockUser(
    user,
    id: userId ?? 'test-user-id',
    email: email ?? 'test@test.com',
    appMetadata: <String, dynamic>{'active_role': role, 'provider': 'email'},
  );
  final session = MockSession();
  configureMockSession(
    session,
    accessToken: accessToken ?? 'mock-jwt-with-role-$role',
    user: user,
  );
  return session;
}

/// Exception types for testing error scenarios
class MockPostgrestException implements Exception {
  final String message;
  final String? code;
  final String? details;
  final String? hint;

  MockPostgrestException({
    required this.message,
    this.code,
    this.details,
    this.hint,
  });

  @override
  String toString() =>
      'PostgrestException: $message (code: $code, details: $details, hint: $hint)';
}

/// Helper to create a mock PostgrestException for error testing
MockPostgrestException createMockPostgrestException({
  String? message,
  String? code,
  String? details,
}) {
  return MockPostgrestException(
    message: message ?? 'Database error',
    code: code ?? '42501', // RLS violation code
    details: details ?? 'Test error details',
  );
}

/// Extension to make MockPostgrestException work like real PostgrestException
extension MockPostgrestExceptionExtension on MockPostgrestException {
  /// Returns the message in the same format as real PostgrestException
  String get errorMessage => toString();
}
