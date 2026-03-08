/// RLS Test Fixtures — Test User Profiles for Security Testing
///
/// These fixtures provide user IDs and roles for testing RLS policies.
/// They complement the existing test/fixtures/profiles.dart with
/// RLS-specific user configurations.
///
/// Usage:
/// ```dart
/// import 'fixtures/rls_test_users.dart';
///
/// test('client can read own messages', () {
///   final user = TestUsers.clientUser;
///   // test with user.id
/// });
/// ```
library;

import 'package:sline_app/core/services/logger_service.dart';

const String _logTag = 'rls_fixture';

/// Test user configuration for RLS testing
class TestUser {
  /// User ID (UUID format)
  final String id;

  /// User email
  final String email;

  /// User role (client or freelancer)
  final String role;

  /// Full name
  final String fullName;

  /// Whether this user is an admin
  final bool isAdmin;

  /// Whether this user has service_role
  final bool isServiceRole;

  const TestUser({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
    this.isAdmin = false,
    this.isServiceRole = false,
  });

  /// Create a copy with modified properties
  TestUser copyWith({
    String? id,
    String? email,
    String? role,
    String? fullName,
    bool? isAdmin,
    bool? isServiceRole,
  }) {
    return TestUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      isAdmin: isAdmin ?? this.isAdmin,
      isServiceRole: isServiceRole ?? this.isServiceRole,
    );
  }

  @override
  String toString() {
    return 'TestUser(id: $id, role: $role, email: $email)';
  }
}

/// Pre-defined test users for RLS security testing
class TestUsers {
  TestUsers._();

  /// Client user - can create tasks, send messages in their conversations
  static final TestUser clientUser = () {
    AppLogger.d('Creating clientUser fixture', tag: _logTag);
    return const TestUser(
      id: '11111111-1111-1111-1111-111111111111',
      email: 'client@test.com',
      role: 'client',
      fullName: 'Test Client',
    );
  }();

  /// Freelancer user - can bid on tasks, send messages in their conversations
  static final TestUser freelancerUser = () {
    AppLogger.d('Creating freelancerUser fixture', tag: _logTag);
    return const TestUser(
      id: '22222222-2222-2222-2222-222222222222',
      email: 'freelancer@test.com',
      role: 'freelancer',
      fullName: 'Test Freelancer',
    );
  }();

  /// Other client user - for testing cross-user access denial
  /// This user should NOT be able to access data belonging to clientUser
  static final TestUser otherClientUser = () {
    AppLogger.d('Creating otherClientUser fixture', tag: _logTag);
    return const TestUser(
      id: '33333333-3333-3333-3333-333333333333',
      email: 'other-client@test.com',
      role: 'client',
      fullName: 'Other Test Client',
    );
  }();

  /// Admin user - for testing admin-only access
  static final TestUser adminUser = () {
    AppLogger.d('Creating adminUser fixture', tag: _logTag);
    return const TestUser(
      id: '44444444-4444-4444-4444-444444444444',
      email: 'admin@test.com',
      role: 'client', // Admin is still a client role
      fullName: 'Test Admin',
      isAdmin: true,
    );
  }();

  /// Service role - for testing service_role only operations
  static final TestUser serviceRole = () {
    AppLogger.d('Creating serviceRole fixture', tag: _logTag);
    return const TestUser(
      id: '55555555-5555-5555-5555-555555555555',
      email: 'service@system.local',
      role: 'service',
      fullName: 'Service Role',
      isServiceRole: true,
    );
  }();

  /// Anonymous user (no session) - for testing unauthenticated access
  static final TestUser anonymousUser = () {
    AppLogger.d('Creating anonymousUser fixture', tag: _logTag);
    return const TestUser(
      id: '', // Anonymous has no ID
      email: '',
      role: 'anon',
      fullName: 'Anonymous',
    );
  }();

  /// All test users as a list
  static List<TestUser> get allUsers => [
    clientUser,
    freelancerUser,
    otherClientUser,
    adminUser,
    serviceRole,
  ];

  /// Users that should have authenticated access (not anon)
  static List<TestUser> get authenticatedUsers => [
    clientUser,
    freelancerUser,
    otherClientUser,
    adminUser,
  ];

  /// Users that are NOT the primary client user (for testing isolation)
  static List<TestUser> get otherUsers => [
    freelancerUser,
    otherClientUser,
    adminUser,
  ];
}

/// Test conversation fixtures for message RLS testing
class TestConversations {
  TestConversations._();

  /// Conversation between clientUser and freelancerUser
  static final Map<String, dynamic> clientFreelancerConversation = () {
    AppLogger.d('Creating clientFreelancerConversation fixture', tag: _logTag);
    return {
      'id': 'conv-cf-001',
      'user1_id': TestUsers.clientUser.id,
      'user2_id': TestUsers.freelancerUser.id,
      'created_at': '2026-03-06T10:00:00Z',
    };
  }();

  /// Conversation that otherClientUser is NOT part of
  /// Used for testing cross-user message access denial
  static final Map<String, dynamic> privateConversation = () {
    AppLogger.d('Creating privateConversation fixture', tag: _logTag);
    return {
      'id': 'conv-private-001',
      'user1_id': TestUsers.clientUser.id,
      'user2_id': TestUsers.freelancerUser.id,
      'created_at': '2026-03-06T10:00:00Z',
    };
  }();

  /// Conversation that otherClientUser IS part of
  static final Map<String, dynamic> otherClientConversation = () {
    AppLogger.d('Creating otherClientConversation fixture', tag: _logTag);
    return {
      'id': 'conv-oc-001',
      'user1_id': TestUsers.otherClientUser.id,
      'user2_id': TestUsers.freelancerUser.id,
      'created_at': '2026-03-06T11:00:00Z',
    };
  }();
}

/// Test message fixtures for RLS testing
class TestMessages {
  TestMessages._();

  /// Message in client-freelancer conversation
  static final Map<String, dynamic> clientMessage = () {
    AppLogger.d('Creating clientMessage fixture', tag: _logTag);
    return {
      'id': 'msg-001',
      'conversation_id': TestConversations.clientFreelancerConversation['id'],
      'sender_id': TestUsers.clientUser.id,
      'receiver_id': TestUsers.freelancerUser.id,
      'content': 'Hello from client',
      'created_at': '2026-03-06T10:05:00Z',
    };
  }();

  /// Message that otherClientUser should NOT be able to access
  static final Map<String, dynamic> privateMessage = () {
    AppLogger.d('Creating privateMessage fixture', tag: _logTag);
    return {
      'id': 'msg-private-001',
      'conversation_id': TestConversations.privateConversation['id'],
      'sender_id': TestUsers.clientUser.id,
      'receiver_id': TestUsers.freelancerUser.id,
      'content': 'Private message content',
      'created_at': '2026-03-06T10:10:00Z',
    };
  }();

  /// Message that otherClientUser sends
  static final Map<String, dynamic> otherClientMessage = () {
    AppLogger.d('Creating otherClientMessage fixture', tag: _logTag);
    return {
      'id': 'msg-oc-001',
      'conversation_id': TestConversations.otherClientConversation['id'],
      'sender_id': TestUsers.otherClientUser.id,
      'receiver_id': TestUsers.freelancerUser.id,
      'content': 'Hello from other client',
      'created_at': '2026-03-06T11:05:00Z',
    };
  }();
}

/// Test booking fixtures for RLS testing
class TestBookings {
  TestBookings._();

  /// Booking where clientUser is the client
  static final Map<String, dynamic> clientBooking = () {
    AppLogger.d('Creating clientBooking fixture', tag: _logTag);
    return {
      'id': 'booking-001',
      'client_id': TestUsers.clientUser.id,
      'provider_id': TestUsers.freelancerUser.id,
      'status': 'pending',
      'price_cents': 10000,
      'created_at': '2026-03-06T09:00:00Z',
    };
  }();

  /// Booking where otherClientUser is the client (for testing cross-user denial)
  static final Map<String, dynamic> otherClientBooking = () {
    AppLogger.d('Creating otherClientBooking fixture', tag: _logTag);
    return {
      'id': 'booking-002',
      'client_id': TestUsers.otherClientUser.id,
      'provider_id': TestUsers.freelancerUser.id,
      'status': 'confirmed',
      'price_cents': 15000,
      'created_at': '2026-03-06T09:30:00Z',
    };
  }();
}

/// Helper to create admin_logs entry for testing
class TestAdminLogs {
  TestAdminLogs._();

  /// Valid admin log entry that service_role can insert
  static Map<String, dynamic> validLogEntry(String action) {
    AppLogger.d('Creating validLogEntry fixture: $action', tag: _logTag);
    return {
      'user_id': TestUsers.clientUser.id,
      'action': action,
      'entity_type': 'test',
      'entity_id': 'test-001',
      'details': {'test': true},
    };
  }
}

/// Extension methods for convenient test user access
extension TestUserHelpers on TestUser {
  /// JWT payload for this user (mock)
  Map<String, dynamic> get jwtPayload {
    return {
      'sub': id,
      'aud': 'authenticated',
      'role': isServiceRole ? 'service_role' : 'authenticated',
      'email': email,
      'app_metadata': {'active_role': role, 'provider': 'email'},
      'user_metadata': {'full_name': fullName},
    };
  }

  /// Auth UID claim (for RLS auth.uid() checks)
  String get authUid => id;
}
