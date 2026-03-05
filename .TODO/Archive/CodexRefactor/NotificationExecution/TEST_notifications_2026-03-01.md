# Notification Test Infrastructure (2026-03-01)

## Scope

- **Unit**: Model parsing (type, contract/aliases), ViewModel (connect/disconnect, errors, read/update).
- **Widget**: Badge (count 0/1/9+), modal (loading, empty, error, list), mark-all, row selection, tap flow without disposed context.
- **Integration**: Deep-link flow with deterministic fixture or seeded contract; no reliance on opportunistic staging data only.

## Harnesses

- **Widget/unit**: Reuse `test/test_support/pump_app.dart` for MaterialApp wrapper. Provider setup for notification tests: provide `NotificationViewModel`, `DeepLinkService` (or mocks).
- **Integration**: Reuse `integration_test/support/helpers.dart`, `preflight.dart`, `t61_t70_env.dart`. Use `--dart-define` for fixture IDs when deterministic seed is used.

## Fixture / env contract

- **Unit/widget**: No live DB; mock `NotificationService` (stream, markAsRead, markAllAsRead).
- **Integration**: Either (a) seeded notification fixture with known IDs passed via `--dart-define` (e.g. `IT_T69_NOTIFICATION_ID`, `IT_T69_ENTITY_TYPE`), or (b) skip when no notifications and document as environment-dependent. Preferred: (a) for deterministic runs.

## Stable selectors / keys

- Bell: `NotificationBadgeButton.buttonKey` (existing).
- Modal shell: add `ValueKey('notifications_modal')` (or similar) to modal root.
- Loading: `CircularProgressIndicator` inside modal.
- Empty: `Text('No notifications yet')`.
- Error: add error state key and retry button key.
- Row: `ValueKey('notification_row_${item.id}')` on each tile for stable find by ID.

## Timeout and rerun

- Widget tests: default pump timeouts; single run.
- Integration: timeout budget per step (e.g. 15–20s for modal open, 20s for list load); max 1 rerun on failure; fail fast on missing env (e.g. skip with message if `IT_STAGING_CONFIRMED` not set or fixture IDs missing).

## Failure artifacts

- On failure: capture log tag (e.g. T69), last finder used, and timeout reason in test output.
- No automatic screenshot requirement; optional if harness supports it.

## Reference

- Plan: `.TODO/PLAN_NotificationsFix_2026-03-01.md`
- Integration test: `integration_test/notification_deeplink_flow_test.dart`
- Env: `integration_test/support/t61_t70_env.dart` (e.g. `t69EntityType`)
