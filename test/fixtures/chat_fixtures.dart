/// Test fixtures for Chat Creation Matrix testing
///
/// These fixtures provide consistent test data for unit and integration tests
/// related to conversation creation, DM rules, favorites enforcement, and
/// role-based access control for the Chat Creation Matrix feature.
///
/// Fixtures include:
/// - Test users (client, freelancer A, freelancer B)
/// - Favorite relationships (client → freelancer A)
/// - Conversation scenarios (valid DM, invalid DM, task-linked)
/// - RPC responses for start_direct_conversation_v1
/// - Guard trigger error scenarios
library;

import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';

/// Log tag for chat test fixture operations
const String _logTag = 'chat_test_fixture';

// ============================================================================
// TEST USER UUIDs
// ============================================================================

/// Test Client UUID - Can initiate DMs to favorited freelancers
const String testClientId = '550e8400-e29b-41d4-a716-446655440010';

/// Test Freelancer A UUID - In client's favorites list
const String testFreelancerAId = '550e8400-e29b-41d4-a716-446655440011';

/// Test Freelancer B UUID - NOT in client's favorites list
const String testFreelancerBId = '550e8400-e29b-41d4-a716-446655440012';

/// Test Task UUID - For task-linked conversation tests
const String testTaskId = '550e8400-e29b-41d4-a716-446655440020';

/// Test Conversation UUID - Existing conversation
const String testConversationId = '550e8400-e29b-41d4-a716-446655440030';

// ============================================================================
// PROFILE FIXTURES
// ============================================================================

/// Client profile fixture - active_role = 'client'
/// This user can initiate DMs to freelancers in their favorites list
final Map<String, dynamic> chatClientProfile = () {
  AppLogger.d('Creating chatClientProfile fixture', tag: _logTag);
  return <String, dynamic>{
    'id': testClientId,
    'full_name': 'Test Chat Client',
    'email': 'chat-client@test.com',
    'avatar_url': 'avatars/chat-client/avatar.png',
    'bio': 'I am a test client looking for freelancers',
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

/// Freelancer A profile fixture - active_role = 'freelancer'
/// This freelancer IS in the client's favorites list
final Map<String, dynamic> chatFreelancerAProfile = () {
  AppLogger.d('Creating chatFreelancerAProfile fixture', tag: _logTag);
  return <String, dynamic>{
    'id': testFreelancerAId,
    'full_name': 'Test Freelancer A',
    'email': 'freelancer-a@test.com',
    'avatar_url': 'avatars/freelancer-a/avatar.png',
    'bio': 'I am a test freelancer - in client favorites',
    'active_role': 'freelancer',
    'skills': <String>['Flutter', 'Dart', 'UI/UX'],
    'seller_level': 'level_2',
    'account_status': 'active',
    'moderation_reason': null,
    'restriction_scope': null,
    'force_logout_after': null,
    'created_at': '2026-01-15T10:30:00.000Z',
  };
}();

/// Freelancer B profile fixture - active_role = 'freelancer'
/// This freelancer is NOT in the client's favorites list (for negative tests)
final Map<String, dynamic> chatFreelancerBProfile = () {
  AppLogger.d('Creating chatFreelancerBProfile fixture', tag: _logTag);
  return <String, dynamic>{
    'id': testFreelancerBId,
    'full_name': 'Test Freelancer B',
    'email': 'freelancer-b@test.com',
    'avatar_url': 'avatars/freelancer-b/avatar.png',
    'bio': 'I am a test freelancer - NOT in client favorites',
    'active_role': 'freelancer',
    'skills': <String>['React', 'Node.js', 'Design'],
    'seller_level': 'level_1',
    'account_status': 'active',
    'moderation_reason': null,
    'restriction_scope': null,
    'force_logout_after': null,
    'created_at': '2026-01-15T10:30:00.000Z',
  };
}();

// ============================================================================
// FAVORITES FIXTURES
// ============================================================================

/// Favorite relationship: Client → Freelancer A
/// This enables the client to DM freelancer A
final Map<String, dynamic> clientFavoritesFreelancerA = () {
  AppLogger.d('Creating clientFavoritesFreelancerA fixture', tag: _logTag);
  return <String, dynamic>{
    'id': '550e8400-e29b-41d4-a716-446655440040',
    'client_id': testClientId,
    'freelancer_id': testFreelancerAId,
    'created_at': '2026-02-01T10:00:00.000Z',
  };
}();

// Note: No favorite fixture for Freelancer B (intentionally missing)
// This allows testing "DM to non-favorite fails" scenario

// ============================================================================
// CONVERSATION FIXTURES
// ============================================================================

/// Direct DM conversation fixture (task_id = null)
/// Client and Freelancer A have an existing DM conversation
final Map<String, dynamic> existingDirectConversation = () {
  AppLogger.d('Creating existingDirectConversation fixture', tag: _logTag);
  return <String, dynamic>{
    'id': testConversationId,
    'task_id': null,
    'user1_id': testClientId, // user1_id < user2_id (normalized)
    'user2_id': testFreelancerAId,
    'initiated_by': testClientId,
    'created_at': '2026-02-10T14:30:00.000Z',
    'updated_at': '2026-02-10T14:30:00.000Z',
    'deleted_at_user1': null,
    'deleted_at_user2': null,
    // Join fields for display
    'user1': chatClientProfile,
    'user2': chatFreelancerAProfile,
  };
}();

/// Task-linked conversation fixture
/// Conversation between Client and Freelancer A about a specific task
final Map<String, dynamic> existingTaskConversation = () {
  AppLogger.d('Creating existingTaskConversation fixture', tag: _logTag);
  return <String, dynamic>{
    'id': '550e8400-e29b-41d4-a716-446655440031',
    'task_id': testTaskId,
    'user1_id': testClientId,
    'user2_id': testFreelancerAId,
    'initiated_by': testFreelancerAId, // Freelancer initiated (bidder)
    'created_at': '2026-02-15T09:00:00.000Z',
    'updated_at': '2026-02-15T09:00:00.000Z',
    'deleted_at_user1': null,
    'deleted_at_user2': null,
    'tasks': <String, dynamic>{
      'title': 'Test Task for Conversation',
      'task_type': 'tender',
    },
    'user1': chatClientProfile,
    'user2': chatFreelancerAProfile,
  };
}();

/// New conversation response from start_direct_conversation_v1 RPC
/// Returned when a new DM conversation is successfully created
final Map<String, dynamic> newDirectConversationResponse = () {
  AppLogger.d('Creating newDirectConversationResponse fixture', tag: _logTag);
  return <String, dynamic>{
    'id': '550e8400-e29b-41d4-a716-446655440032',
    'task_id': null,
    'user1_id': testClientId,
    'user2_id': testFreelancerAId,
    'initiated_by': testClientId,
    'created_at': '2026-03-06T10:00:00.000Z',
    'updated_at': '2026-03-06T10:00:00.000Z',
    'deleted_at_user1': null,
    'deleted_at_user2': null,
    'user1': chatClientProfile,
    'user2': chatFreelancerAProfile,
  };
}();

/// Existing conversation response from start_direct_conversation_v1 RPC
/// Returned when conversation already exists (ON CONFLICT DO UPDATE)
final Map<String, dynamic> existingDirectConversationResponse = () {
  AppLogger.d('Creating existingDirectConversationResponse fixture', tag: _logTag);
  return <String, dynamic>{
    'id': testConversationId, // Same ID as existing
    'task_id': null,
    'user1_id': testClientId,
    'user2_id': testFreelancerAId,
    'initiated_by': testClientId,
    'created_at': '2026-02-10T14:30:00.000Z', // Original creation time
    'updated_at': '2026-03-06T10:00:00.000Z', // Updated by ON CONFLICT
    'deleted_at_user1': null,
    'deleted_at_user2': null,
    'user1': chatClientProfile,
    'user2': chatFreelancerAProfile,
  };
}();

// ============================================================================
// RPC ERROR FIXTURES
// ============================================================================

/// RPC Error: Freelancer attempting to start DM
/// Error returned when a freelancer calls start_direct_conversation_v1
final Map<String, dynamic> freelancerCannotStartDmError = () {
  AppLogger.d('Creating freelancerCannotStartDmError fixture', tag: _logTag);
  return <String, dynamic>{
    'code': 'P0001', // User-defined exception code
    'message': 'Freelancers cannot start direct conversations',
    'details': null,
    'hint': null,
  };
}();

/// RPC Error: Client DM to non-favorited freelancer
/// Error returned when client tries to DM freelancer not in favorites
final Map<String, dynamic> notInFavoritesError = () {
  AppLogger.d('Creating notInFavoritesError fixture', tag: _logTag);
  return <String, dynamic>{
    'code': 'P0001',
    'message': 'You can only message freelancers in your favorites list',
    'details': null,
    'hint': 'Add the freelancer to your favorites first',
  };
}();

/// RPC Error: Rate limit exceeded
/// Error returned when user exceeds 20 conversations/hour
final Map<String, dynamic> rateLimitExceededError = () {
  AppLogger.d('Creating rateLimitExceededError fixture', tag: _logTag);
  return <String, dynamic>{
    'code': 'P0001',
    'message': 'Rate limit exceeded: maximum 20 conversations per hour',
    'details': null,
    'hint': 'Please try again later',
  };
}();

/// RPC Error: Target user not found
/// Error returned when target_id doesn't exist in profiles
final Map<String, dynamic> targetUserNotFoundError = () {
  AppLogger.d('Creating targetUserNotFoundError fixture', tag: _logTag);
  return <String, dynamic>{
    'code': 'P0001',
    'message': 'Target user not found',
    'details': null,
    'hint': null,
  };
}();

/// RPC Error: Self-conversation attempt
/// Error returned when user tries to create conversation with themselves
final Map<String, dynamic> selfConversationError = () {
  AppLogger.d('Creating selfConversationError fixture', tag: _logTag);
  return <String, dynamic>{
    'code': 'P0001',
    'message': 'Cannot create conversation with yourself',
    'details': null,
    'hint': null,
  };
}();

/// Network timeout error
/// Simulated error for poor connectivity testing
final Map<String, dynamic> networkTimeoutError = () {
  AppLogger.d('Creating networkTimeoutError fixture', tag: _logTag);
  return <String, dynamic>{
    'code': 'network_timeout',
    'message': 'Connection timeout. Please check your internet connection and try again.',
    'details': 'Request exceeded 10 second timeout',
    'hint': 'Retry the operation',
  };
}();

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Creates a Conversation model from the new direct conversation response
Conversation createNewDirectConversationModel() {
  AppLogger.d('Creating new direct Conversation model', tag: _logTag);
  return Conversation.fromJson(newDirectConversationResponse);
}

/// Creates a Conversation model from the existing conversation response
Conversation createExistingDirectConversationModel() {
  AppLogger.d('Creating existing direct Conversation model', tag: _logTag);
  return Conversation.fromJson(existingDirectConversationResponse);
}

/// Creates a task-linked Conversation model
Conversation createTaskConversationModel() {
  AppLogger.d('Creating task-linked Conversation model', tag: _logTag);
  return Conversation.fromJson(existingTaskConversation);
}

/// Helper to create a customized conversation fixture
///
/// [baseConversation] - The base conversation to customize
/// [overrides] - Map of field values to override
Map<String, dynamic> createCustomConversation(
  Map<String, dynamic> baseConversation,
  Map<String, dynamic> overrides,
) {
  AppLogger.d(
    'Creating custom conversation fixture',
    tag: _logTag,
    json: {'base_id': baseConversation['id'], 'overrides': overrides.keys.toList()},
  );
  return <String, dynamic>{
    ...baseConversation,
    ...overrides,
  };
}

/// Helper to simulate rate limit exhaustion
/// Returns a list of 20 conversation creation timestamps within the last hour
List<DateTime> generateRateLimitExhaustedTimestamps() {
  AppLogger.d('Generating rate limit exhausted timestamps', tag: _logTag);
  final now = DateTime.now().toUtc();
  return List.generate(
    20,
    (index) => now.subtract(Duration(minutes: index * 2)),
  );
}

/// List of all chat creation error codes for validation
const List<String> chatCreationErrorCodes = <String>[
  'P0001', // User-defined PostgreSQL exception
  'network_timeout',
  '42501', // RLS violation
  '23505', // Unique constraint violation (if guard bypassed)
];

/// List of all chat creation error messages for ErrorMapper validation
const List<String> chatCreationErrorMessages = <String>[
  'Freelancers cannot start direct conversations',
  'You can only message freelancers in your favorites list',
  'Rate limit exceeded: maximum 20 conversations per hour',
  'Target user not found',
  'Cannot create conversation with yourself',
  'initiated_by must equal current user',
  'task owner cannot start a task-linked conversation',
];
