# Test Infrastructure: Notification Routing

**Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`

---

## Test directory contract

- **Unit/widget:** `test/unit/notifications/`, `test/widget/notifications/` — NotificationViewModel, notification_service (mocked), UI. No real Supabase.
- **Integration (RLS/DB):** `test/rls/notifications_insert_blocked_test.dart` — uses `RlsTestHelper`. With real Supabase client: run with env or test runner that injects client to get live assertCannotInsert.
- **E2E:** `integration_test/notification_deeplink_flow_test.dart` (existing); push when app killed: manual or e2e with real device/simulator + FCM.

---

## Run commands

- Unit: `flutter test test/unit/notifications/`
- Widget: `flutter test test/widget/notifications/`
- RLS (notifications INSERT blocked): `flutter test test/rls/notifications_insert_blocked_test.dart`
- All notification-related: `flutter test test/unit/notifications/ test/widget/notifications/ test/rls/notifications_insert_blocked_test.dart`

---

## Fixture

- RLS test uses `TestUsers.clientUser.id` from `test/rls/fixtures/rls_test_users.dart`. No notification row required for INSERT-denied test (we assert insert fails).
- For integration tests that need existing notification row: insert via service_role or use seed data; document in test file.

---

## Failure artifact

- On failure: capture `flutter test` output; RLS test logs via AppLogger (tag `rls_test`). No token or PII in logs.
