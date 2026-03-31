# Chat Creation Matrix - Test Fixtures Strategy

**Document ID**: PLAN_ChatCreationMatrix_TestFixtures  
**Version**: 1.0  
**Date**: 2026-03-06  
**Owner**: @Sentinel (QA Lead)  
**Reviewers**: @Architect, @Supabase_Ops  

---

## 1. Overview

This document defines the test infrastructure strategy for the Chat Creation Matrix implementation. It specifies the test fixtures, seed data, and reset strategy required to verify the atomic RPC, hardened guard trigger, rate limiting, and role-based access controls.

## 2. Test Infrastructure Status

| Component | Status | Details |
|-----------|--------|---------|
| `flutter_test` | ✅ Available | SDK 3.38.9, configured in `pubspec.yaml` |
| `integration_test` | ✅ Available | 13 existing integration tests |
| `mocktail` | ✅ Available | Mocking library for Supabase |
| Unit test files | ✅ 79 files | Existing test coverage |
| Mock Supabase | ✅ Available | `test/helpers/mock_supabase.dart` |
| Profile fixtures | ✅ Available | `test/fixtures/profiles.dart` |
| **Chat fixtures** | ✅ **Created** | `test/fixtures/chat_fixtures.dart` |

## 3. Test Fixtures

### 3.1 File: `test/fixtures/chat_fixtures.dart`

Created with the following fixtures:

#### Test User UUIDs
| Constant | Value | Role | Description |
|----------|-------|------|-------------|
| `testClientId` | `550e8400-e29b-41d4-a716-446655440010` | Client | Can initiate DMs |
| `testFreelancerAId` | `550e8400-e29b-41d4-a716-446655440011` | Freelancer | In client's favorites |
| `testFreelancerBId` | `550e8400-e29b-41d4-a716-446655440012` | Freelancer | NOT in favorites |
| `testTaskId` | `550e8400-e29b-41d4-a716-446655440020` | - | For task-linked tests |
| `testConversationId` | `550e8400-e29b-41d4-a716-446655440030` | - | Existing conversation |

#### Profile Fixtures
- `chatClientProfile` - Client role, can initiate DMs
- `chatFreelancerAProfile` - In client's favorites
- `chatFreelancerBProfile` - NOT in favorites (for negative tests)

#### Favorite Fixtures
- `clientFavoritesFreelancerA` - Valid favorite relationship
- (Intentionally no fixture for Freelancer B)

#### Conversation Fixtures
- `existingDirectConversation` - DM conversation (task_id = null)
- `existingTaskConversation` - Task-linked conversation
- `newDirectConversationResponse` - RPC success response
- `existingDirectConversationResponse` - RPC idempotency response

#### Error Fixtures
- `freelancerCannotStartDmError` - Role-based rejection
- `notInFavoritesError` - Favorites enforcement
- `rateLimitExceededError` - Rate limit (20/hour)
- `targetUserNotFoundError` - Invalid target
- `selfConversationError` - Self-DM prevention
- `networkTimeoutError` - Connectivity failure

## 4. Test Files to Create

### 4.1 Unit Tests: `test/services/message_service_test.dart`

Tests for `MessageService.createOrGetConversation()`:

| Test Case | Description | Fixtures Used |
|-----------|-------------|---------------|
| `create DM to favorite succeeds` | Valid DM creation | `chatClientProfile`, `chatFreelancerAProfile`, `newDirectConversationResponse` |
| `create DM to non-favorite fails` | Favorites enforcement | `chatClientProfile`, `chatFreelancerBProfile`, `notInFavoritesError` |
| `freelancer creating DM fails` | Role enforcement | `chatFreelancerAProfile`, `freelancerCannotStartDmError` |
| `rate limit blocks after 20 attempts` | Rate limiting | `rateLimitExceededError` |
| `idempotent: duplicate calls return same conversation` | Atomicity | `newDirectConversationResponse`, `existingDirectConversationResponse` |
| `network timeout shows retry option` | Error handling | `networkTimeoutError` |
| `feature flag disabled uses direct insert` | Flag behavior | Mock flag = false |
| `feature flag enabled uses RPC` | Flag behavior | Mock flag = true |

### 4.2 Integration Tests: `integration_test/chat_creation_test.dart`

E2E flow tests:

| Test Case | Flow | Users |
|-----------|------|-------|
| `Client favorites freelancer then starts DM` | Full happy path | Client → Freelancer A |
| `Freelancer bid creates task-linked conversation` | Task context | Freelancer A → Task |
| `Client rejects bid creates conversation` | Reject flow | Client → Freelancer A |
| `Freelancer cannot start DM with client` | Role block | Freelancer A → Client |
| `Client cannot DM without favorites` | Favorites block | Client → Freelancer B |

## 5. Test Database Strategy

### 5.1 Local/Testing Supabase Instance

For unit tests using `mocktail`, no live database needed. For integration tests:

**Option A: Supabase Local CLI** (Recommended)
```bash
supabase start
supabase db reset  # Clean state between runs
```

**Option B: Dedicated Test Project**
- Separate Supabase project for CI/CD
- Isolated from production data

### 5.2 Seed Data Script

```sql
-- Run before integration tests
-- Creates test users, favorites, and base state

-- Test Client
INSERT INTO profiles (id, full_name, email, active_role, account_status)
VALUES ('550e8400-e29b-41d4-a716-446655440010', 'Test Chat Client', 'chat-client@test.com', 'client', 'active')
ON CONFLICT (id) DO NOTHING;

-- Test Freelancer A
INSERT INTO profiles (id, full_name, email, active_role, account_status)
VALUES ('550e8400-e29b-41d4-a716-446655440011', 'Test Freelancer A', 'freelancer-a@test.com', 'freelancer', 'active')
ON CONFLICT (id) DO NOTHING;

-- Test Freelancer B
INSERT INTO profiles (id, full_name, email, active_role, account_status)
VALUES ('550e8400-e29b-41d4-a716-446655440012', 'Test Freelancer B', 'freelancer-b@test.com', 'freelancer', 'active')
ON CONFLICT (id) DO NOTHING;

-- Favorite: Client → Freelancer A
INSERT INTO favorites (id, client_id, freelancer_id, created_at)
VALUES ('550e8400-e29b-41d4-a716-446655440040', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440011', NOW())
ON CONFLICT (client_id, freelancer_id) DO NOTHING;
```

### 5.3 Reset Strategy

**Between Test Runs:**
```sql
-- Clean up conversations created during tests
TRUNCATE conversations, messages, admin_logs 
WHERE created_at > (NOW() - INTERVAL '1 hour');

-- Reset rate limit state (implicit via time)
-- No explicit reset needed - rate limit is time-based
```

## 6. Test Commands

### Unit Tests
```bash
# Run all tests
flutter test

# Run only chat-related tests
flutter test test/services/message_service_test.dart
flutter test test/widget/chat/

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Integration Tests
```bash
# Start Supabase local
supabase start

# Run all integration tests
flutter test integration_test/

# Run specific chat creation flow
flutter test integration_test/chat_creation_test.dart

# Run with device
flutter test integration_test/chat_creation_test.dart -d ios
```

## 7. Mock Configuration

### Mocking start_direct_conversation_v1 RPC

```dart
// Example test setup
late MockSupabaseClient mockClient;
late MockGoTrueClient mockAuth;

setUp(() {
  mockClient = MockSupabaseClient();
  mockAuth = MockGoTrueClient();
  
  final mockUser = createMockClientUser(id: testClientId);
  final mockSession = createMockSessionWithRole('client', userId: testClientId);
  
  when(() => mockClient.auth).thenReturn(mockAuth);
  when(() => mockAuth.currentUser).thenReturn(mockUser);
  when(() => mockAuth.currentSession).thenReturn(mockSession);
  
  // Mock RPC response
  when(() => mockClient.rpc(
    'start_direct_conversation_v1',
    params: {'p_target_id': testFreelancerAId},
  )).thenAnswer((_) async => newDirectConversationResponse);
});
```

## 8. Success Criteria

### 8.1 Unit Tests
- [ ] 8 test cases in `message_service_test.dart`
- [ ] 100% pass rate
- [ ] Coverage >80% for `MessageService`

### 8.2 Integration Tests
- [ ] 5 E2E flow tests
- [ ] All tests deterministic (no flakes)
- [ ] Average run time < 30 seconds per test

### 8.3 Infrastructure
- [ ] `flutter test` passes without errors
- [ ] `integration_test/` runs successfully
- [ ] Mock Supabase properly configured for RPC calls

## 9. Risks & Mitigation

| Risk | Probability | Mitigation |
|------|-------------|------------|
| Test flakiness due to timing | Medium | Use mocktail for unit tests; deterministic seed for integration |
| RPC mocking complexity | Low | Use existing `mock_supabase.dart` patterns |
| Fixture maintenance drift | Medium | Fixtures documented in this file; update with schema changes |
| Integration test data pollution | Medium | TRUNCATE strategy; fresh Supabase local instance per CI run |

## 10. References

- Original Plan: `.TODO/improvement_the_system/ImplementReady/07_chat-creation-matrix/`
- Chat Fixtures: `test/fixtures/chat_fixtures.dart`
- Mock Supabase: `test/helpers/mock_supabase.dart`
- Profile Fixtures: `test/fixtures/profiles.dart`

---

**Document Status**: ✅ Ready for Implementation  
**Next Step**: Create `test/services/message_service_test.dart`
