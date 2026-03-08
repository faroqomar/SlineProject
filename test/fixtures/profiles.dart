/// Test fixtures for profile and role switching scenarios.
///
/// These fixtures provide consistent test data for unit and widget tests
/// related to user profiles, roles, and role switching functionality.
library;

import 'package:sline_app/core/services/logger_service.dart';

/// Log tag for test fixture operations
const String _logTag = 'test_fixture';

/// Sample UUID for test user
const String testUserId = '550e8400-e29b-41d4-a716-446655440000';

/// Sample UUID for test client user
const String testClientId = '550e8400-e29b-41d4-a716-446655440001';

/// Sample UUID for test freelancer user
const String testFreelancerId = '550e8400-e29b-41d4-a716-446655440002';

/// Profile fixture representing a user in client role
///
/// Contains all fields from the profiles table with active_role set to 'client'
final Map<String, dynamic> clientProfile = () {
  AppLogger.d('Creating clientProfile fixture', tag: _logTag);
  return <String, dynamic>{
    'id': testClientId,
    'full_name': 'Test Client User',
    'email': 'client@test.com',
    'avatar_url': 'avatars/test-client/avatar.png',
    'bio': 'I am a test client user looking for freelancers',
    'active_role': 'client',
    'skills': <String>[],
    'seller_level': null,
    'account_status': 'active',
    'moderation_reason': null,
    'restriction_scope': null,
    'force_logout_after': null,
    'created_at': '2026-01-15T10:30:00.000Z',
  };
}();

/// Profile fixture representing a user in freelancer role
///
/// Contains all fields from the profiles table with active_role set to 'freelancer'
final Map<String, dynamic> freelancerProfile = () {
  AppLogger.d('Creating freelancerProfile fixture', tag: _logTag);
  return <String, dynamic>{
    'id': testFreelancerId,
    'full_name': 'Test Freelancer User',
    'email': 'freelancer@test.com',
    'avatar_url': 'avatars/test-freelancer/avatar.png',
    'bio': 'I am a test freelancer offering my services',
    'active_role': 'freelancer',
    'skills': <String>['Flutter', 'Dart', 'UI/UX Design'],
    'seller_level': 'level_2',
    'account_status': 'active',
    'moderation_reason': null,
    'restriction_scope': null,
    'force_logout_after': null,
    'created_at': '2026-01-15T10:30:00.000Z',
  };
}();

/// Profile fixture representing a user with dual roles capability
///
/// Used for testing role switching scenarios where the user can be either client or freelancer
final Map<String, dynamic> dualRoleUserProfile = () {
  AppLogger.d('Creating dualRoleUserProfile fixture', tag: _logTag);
  return <String, dynamic>{
    'id': testUserId,
    'full_name': 'Test Dual Role User',
    'email': 'dual@test.com',
    'avatar_url': 'avatars/test-dual/avatar.png',
    'bio': 'I am a test user with dual role capability',
    'active_role': 'client', // Starts as client, can switch to freelancer
    'skills': <String>['Flutter', 'React', 'Node.js'],
    'seller_level': 'level_1',
    'account_status': 'active',
    'moderation_reason': null,
    'restriction_scope': null,
    'force_logout_after': null,
    'created_at': '2026-01-15T10:30:00.000Z',
  };
}();

/// JWT payload fixture for a user with client role
///
/// Represents the decoded payload of a JWT token for a client user
final Map<String, dynamic> jwtPayloadWithClientRole = () {
  AppLogger.d('Creating jwtPayloadWithClientRole fixture', tag: _logTag);
  return <String, dynamic>{
    'sub': testClientId,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'client@test.com',
    'app_metadata': <String, dynamic>{
      'active_role': 'client',
      'provider': 'email',
    },
    'user_metadata': <String, dynamic>{'full_name': 'Test Client User'},
    'iat': 1705312200,
    'exp': 1705398600,
  };
}();

/// JWT payload fixture for a user with freelancer role
///
/// Represents the decoded payload of a JWT token for a freelancer user
final Map<String, dynamic> jwtPayloadWithFreelancerRole = () {
  AppLogger.d('Creating jwtPayloadWithFreelancerRole fixture', tag: _logTag);
  return <String, dynamic>{
    'sub': testFreelancerId,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'freelancer@test.com',
    'app_metadata': <String, dynamic>{
      'active_role': 'freelancer',
      'provider': 'email',
    },
    'user_metadata': <String, dynamic>{'full_name': 'Test Freelancer User'},
    'iat': 1705312200,
    'exp': 1705398600,
  };
}();

/// JWT payload fixture for a user with mismatched role
///
/// Simulates a stale JWT where the role in JWT doesn't match the database
/// This is used for testing the JWT verification failure scenario
final Map<String, dynamic> jwtPayloadWithStaleRole = () {
  AppLogger.d('Creating jwtPayloadWithStaleRole fixture', tag: _logTag);
  return <String, dynamic>{
    'sub': testUserId,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'dual@test.com',
    'app_metadata': <String, dynamic>{
      'active_role': 'client', // JWT says client
      'provider': 'email',
    },
    'user_metadata': <String, dynamic>{'full_name': 'Test Dual Role User'},
    'iat': 1705312200,
    'exp': 1705398600,
  };
}();

/// Successful role switch RPC response fixture
///
/// Represents the response from the switch_active_role RPC function on success
final Map<String, dynamic> roleSwitchSuccessResponse = () {
  AppLogger.d('Creating roleSwitchSuccessResponse fixture', tag: _logTag);
  return <String, dynamic>{
    'success': true,
    'old_role': 'client',
    'new_role': 'freelancer',
    'switched_at': '2026-03-06T14:30:00.000Z',
    'session_refreshed': true,
  };
}();

/// Stale state error RPC response fixture
///
/// Represents the response from the switch_active_role RPC function
/// when the expected_old_role doesn't match the current database state
/// (e.g., user switched on another device)
final Map<String, dynamic> roleSwitchStaleStateResponse = () {
  AppLogger.d('Creating roleSwitchStaleStateResponse fixture', tag: _logTag);
  return <String, dynamic>{
    'success': false,
    'error': 'stale_state',
    'message':
        'Role has changed on another device. Please refresh and try again.',
    'current_role': 'freelancer',
    'expected_role': 'client',
  };
}();

/// Invalid role error RPC response fixture
///
/// Represents the response when an invalid role is provided
final Map<String, dynamic> roleSwitchInvalidRoleResponse = () {
  AppLogger.d('Creating roleSwitchInvalidRoleResponse fixture', tag: _logTag);
  return <String, dynamic>{
    'success': false,
    'error': 'invalid_role',
    'message':
        "Invalid role specified. Must be either 'client' or 'freelancer'.",
    'provided_role': 'admin',
  };
}();

/// Database error RPC response fixture
///
/// Represents the response when a database error occurs during role switch
final Map<String, dynamic> roleSwitchDbErrorResponse = () {
  AppLogger.d('Creating roleSwitchDbErrorResponse fixture', tag: _logTag);
  return <String, dynamic>{
    'success': false,
    'error': 'db_error',
    'message':
        'Database error occurred while switching role. Please try again later.',
  };
}();

/// Session error RPC response fixture
///
/// Represents the response when session refresh fails after role switch
final Map<String, dynamic> roleSwitchSessionErrorResponse = () {
  AppLogger.d('Creating roleSwitchSessionErrorResponse fixture', tag: _logTag);
  return <String, dynamic>{
    'success': false,
    'error': 'session_error',
    'message':
        'Failed to refresh session after role switch. Please log in again.',
  };
}();

/// Rate limit error RPC response fixture
///
/// Represents the response when user exceeds the rate limit for role switches
final Map<String, dynamic> roleSwitchRateLimitResponse = () {
  AppLogger.d('Creating roleSwitchRateLimitResponse fixture', tag: _logTag);
  return <String, dynamic>{
    'success': false,
    'error': 'rate_limit',
    'message': 'Too many role switches. Please wait before trying again.',
    'retry_after_seconds': 60,
  };
}();

/// Teardown error response fixture
///
/// Represents the error when ViewModel teardown fails during role switch
final Map<String, dynamic> roleSwitchTeardownErrorResponse = () {
  AppLogger.d('Creating roleSwitchTeardownErrorResponse fixture', tag: _logTag);
  return <String, dynamic>{
    'success': false,
    'error_code': 'teardown_error',
    'error_message': 'Failed to clear application state during role switch.',
    'failed_viewmodels': <String>['ChatViewModel', 'DashboardViewModel'],
  };
}();

/// List of all valid role switch error codes
///
/// Used for validation and testing error handling paths
const List<String> validErrorCodes = <String>[
  'stale_state',
  'invalid_role',
  'db_error',
  'session_error',
  'rate_limit',
  'teardown_error',
  'network_error',
];

/// Sample JWT token string (base64 encoded mock)
///
/// This is a mock JWT for testing - not cryptographically valid,
/// but useful for testing JWT parsing logic
const String mockJwtToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJzdWIiOiI1NTBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDAiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwicm9sZSI6ImF1dGhlbnRpY2F0ZWQiLCJlbWFpbCI6ImR1YWxAdGVzdC5jb20iLCJhcHBfbWV0YWRhdGEiOnsiYWN0aXZlX3JvbGUiOiJjbGllbnQiLCJwcm92aWRlciI6ImVtYWlsIn0sInVzZXJfbWV0YWRhdGEiOnsiZnVsbF9uYW1lIjoiVGVzdCBEdWFsIFJvbGUgVXNlciJ9LCJpYXQiOjE3MDUzMTIyMDAsImV4cCI6MTcwNTM5ODYwMH0.'
    'mock_signature';

/// Helper to create a customized profile fixture
///
/// [baseProfile] - The base profile to customize (clientProfile, freelancerProfile, etc.)
/// [overrides] - Map of field values to override in the base profile
Map<String, dynamic> createCustomProfile(
  Map<String, dynamic> baseProfile,
  Map<String, dynamic> overrides,
) {
  AppLogger.d(
    'Creating custom profile fixture',
    tag: _logTag,
    json: {
      'base': baseProfile['active_role'],
      'overrides': overrides.keys.toList(),
    },
  );
  return <String, dynamic>{...baseProfile, ...overrides};
}

/// Helper to create a customized JWT payload fixture
///
/// [basePayload] - The base JWT payload to customize
/// [role] - The role to set in app_metadata
/// [userId] - Optional user ID to override
Map<String, dynamic> createCustomJwtPayload(
  Map<String, dynamic> basePayload, {
  String? role,
  String? userId,
}) {
  AppLogger.d(
    'Creating custom JWT payload fixture',
    tag: _logTag,
    json: {'role': role, 'userId': userId},
  );
  final result = Map<String, dynamic>.from(basePayload);
  if (role != null) {
    final appMetadata = Map<String, dynamic>.from(
      result['app_metadata'] as Map<String, dynamic>,
    );
    appMetadata['active_role'] = role;
    result['app_metadata'] = appMetadata;
  }
  if (userId != null) {
    result['sub'] = userId;
  }
  return result;
}
