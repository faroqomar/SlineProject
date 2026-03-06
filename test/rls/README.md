# RLS (Row Level Security) Test Suite

## Overview

This directory contains automated tests for Supabase RLS policies. These tests verify that:

1. **Critical security blockers** are enforced (cross-user access, log injection, etc.)
2. **Views don't expose PII** and use `security_invoker`
3. **JWT-based role policies** correctly restrict operations by role

## Structure

```
test/rls/
├── rls_test_helper.dart          # Assertion library for RLS tests
├── fixtures/
│   └── rls_test_users.dart       # Test user definitions (5 users)
├── critical_blockers_test.dart   # 4 critical security tests (12 total)
├── view_security_test.dart       # View security tests (7 tests)
└── role_switch_jwt_test.dart     # JWT policy tests (7 tests)
```

## Running Tests

```bash
# Run all RLS tests
flutter test test/rls/

# Run specific test file
flutter test test/rls/critical_blockers_test.dart

# Run with verbose output
flutter test test/rls/ -v
```

## Test Users

| User | Role | ID | Purpose |
|------|------|-----|---------|
| clientUser | client | 1111... | Primary client persona |
| freelancerUser | freelancer | 2222... | Primary freelancer persona |
| otherClientUser | client | 3333... | Cross-user isolation testing |
| adminUser | client | 4444... | Admin privileges |
| serviceRole | service | 5555... | Service role operations |

## Test Categories

### Critical Blockers (`critical_blockers_test.dart`)

Tests for the 4 critical security vulnerabilities identified in the RLS Authorization Map:

1. **Messages Cross-User Read** — Users cannot read messages from conversations they don't participate in
2. **Messages Cross-User Insert** — Users cannot insert messages into others' conversations
3. **Admin Logs Service Role Only** — Only service_role can insert admin_logs
4. **Bookings Status-Only Update** — Users can only update status, not other columns

### View Security (`view_security_test.dart`)

Tests for view security hardening:

- `public.users` view dropped (PII exposure)
- `tasks_mvp` and `user_conversations` use `security_invoker`
- Admin/analytics views restricted to service_role

### JWT Policies (`role_switch_jwt_test.dart`)

Tests for JWT-based role enforcement:

- Client cannot perform freelancer operations (task_requests INSERT)
- Freelancer cannot perform client operations (tasks INSERT)
- JWT claim reflects current role after switch

## Writing RLS Tests

Use `RlsTestHelper` assertion methods:

```dart
import 'rls_test_helper.dart';
import 'fixtures/rls_test_users.dart';

void main() {
  late RlsTestHelper helper;

  setUp(() {
    helper = RlsTestHelper();
  });

  test('user can read own data', () async {
    await helper.assertCanSelect(
      'messages',
      {'conversation_id': 'conv-123'},
      asUserId: TestUsers.clientUser.id,
    );
  });

  test('user cannot read others data', () async {
    await helper.assertCannotSelect(
      'messages',
      {'conversation_id': 'others-conv'},
      asUserId: TestUsers.otherClientUser.id,
    );
  });
}
```

### Available Assertions

- `assertCanSelect()` / `assertCannotSelect()`
- `assertCanInsert()` / `assertCannotInsert()`
- `assertCanUpdate()` / `assertCannotUpdate()`
- `assertCanDelete()` / `assertCannotDelete()`
- `assertViewDoesNotExist()`

### Fluent API

```dart
await helper.asUser(TestUsers.clientUser.id)
  .canSelect('messages', {'conversation_id': '123'});

await helper.asUser(TestUsers.otherClientUser.id)
  .cannotInsert('admin_logs', fakeLogEntry);
```

## Integration Testing

The test helper supports both mock mode (default) and integration mode with live Supabase:

```dart
// Integration test with actual Supabase
final client = Supabase.instance.client;
final helper = RlsTestHelper(client: client);
```

For full integration tests, see `test/integration/` directory.

## References

- Plan: `.TODO/PLAN_RLS_Authorization_Map_CRITIC_2026-03-06.md`
- Execution Log: `.TODO/EXECUTION_LOG_RLS_Authorization_Map_CRITIC_2026-03-06.md`
- Policy Backup: `.TODO/BACKUP_policies_2026-03-06.json`
