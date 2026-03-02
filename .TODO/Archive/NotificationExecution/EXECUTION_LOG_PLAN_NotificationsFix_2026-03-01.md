# Execution Log: PLAN_NotificationsFix_2026-03-01

**Plan**: `.TODO/PLAN_NotificationsFix_2026-03-01.md`  
**Start**: 2026-03-02  
**Status**: Done (review + fixes applied 2026-03-02)

---

## Pre-execution: Full context scan

### Evidence (what exists)

- **Notifications feature**: `lib/features/notifications/` — model (`NotificationItem`, `NotificationType`), `NotificationService` (getNotifications, streamNotifications, markAsRead, markAllAsRead only; no create methods in current code), `NotificationViewModel` (auto-subscribes, has `handleNotificationTap(BuildContext, NotificationItem)` using `context.read<DeepLinkService>()` — MVVM violation).
- **Producer callsites**: Grep for `createNotification(`, `createOrUpdateNotification(`, `NotificationService` in chat/tasks/booking returned **no matches** — client notification writes already removed from business features.
- **DeepLinkService**: Has `handleNotification`; logs with AppLogger.i; `navigateToEntity` supports task, booking, conversation/message, direct_offer, profile, user; **default** logs "Unknown entity type" and shows SnackBar. **No `task_request`** branch yet.
- **Modal**: `NotificationsModal` — taps call `Navigator.pop(context)` then `vm.handleNotificationTap(context, notification)` — **disposed context risk**.
- **Badge**: `NotificationBadgeButton` opens sheet inline; does **not** use `NotificationsModal.show()`; has `buttonKey`.
- **Docs**: `Sline_everything/SUPABASE_SETUP.md` §5.13 documents `notifications` with `message`, `is_read`, `metadata`. Realtime and RLS note: "notifications_insert_any was removed; select_own, update_own".
- **Migrations**: `20260301_harden_notification_writes.sql` — `private_upsert_notification`, triggers for messages/tasks; `notifications_insert_any` dropped. `20260301_reconcile_orders_owner_contract.sql` defines `private_create_notification`. **20260226_tender_award_payment_flow.sql** inserts into `notifications` with columns **body, data, read** (stale; live schema uses **message, is_read, metadata**).
- **Test harness**: `test/test_support/pump_app.dart` exists (minimal MaterialApp wrapper). `integration_test/support/helpers.dart`, `preflight.dart`, `t61_t70_env.dart` exist. No `test/features/notifications/` tests yet. Integration test `notification_deeplink_flow_test.dart` uses staging data and fails when no notifications.

### Gaps (what must be created)

- Phase 0: `.TODO/TEST_notifications_2026-03-01.md`, ACCEPTANCE, THREAT, CONTRACT, MIGRATION, delivery/PR slices.
- Phase 1: Patch 20260226 notification INSERTs to use `message`, `is_read`, `metadata`; optional policy capture migration if not in repo.
- Phase 2: `.TODO/RLS_notifications_matrix_2026-03-01.md`; logging cleanup (no PII).
- Phase 3: ViewModel context-free + auth-aware lifecycle; DeepLinkService `task_request` routing (metadata: conversation_id first, else task_id); defense-in-depth user filter in service.
- Phase 4: Modal returns selection; badge uses `NotificationsModal.show()`; stable keys (modal, loading, empty, error, row); error/retry UX in modal.
- Phase 5: Unit/widget tests under `test/features/notifications/`; integration fixture contract; AppLogger everywhere; docs sync; release grep gates.

### Risks

- Patching 20260226 may affect already-applied DBs; plan says patch for fresh bootstrap + verify/reconcile for deployed.
- Modal tap refactor can regress navigation if context ownership is wrong.
- Auth-aware ViewModel lifecycle requires auth state dependency (e.g. listen to Supabase auth changes).

### Observability notes

- AppLogger already used in NotificationService (errors), NotificationViewModel (stream error), DeepLinkService (info/warning/error). Add: service entry/exit for key methods; ViewModel connect/disconnect/clear; DeepLinkService entityType and "route not supported"; modal/badge selection; no message body in logs.

---

## Phase status

| Phase | Status | Notes |
|-------|--------|--------|
| Pre-execution | Done | Scan + strategy + this log |
| Phase 0 | Done | TEST, ACCEPTANCE, THREAT, CONTRACT, MIGRATION, delivery docs created. |
| Phase 1 | Done | Patched 20260226 (body/data/read → message/metadata/is_read); RLS matrix doc. |
| Phase 2 | Done | Grep gate passed; RLS matrix; no client writes. |
| Phase 3 | Done | Service read-only + user filter; ViewModel context-free + auth-aware; task_request routing. |
| Phase 4 | Done | Modal returns selection; badge uses show(); stable keys; error/retry UX. |
| Phase 5 | Done | Unit + widget tests; AppLogger throughout; docs sync; release grep passed. |

---

## Delivery / PR slices

- **PR1**: Contract + migration baseline + docs drift repair (Phase 0–1: TEST, ACCEPTANCE, THREAT, CONTRACT, MIGRATION docs; 20260226 patch; RLS matrix).
- **PR2**: App logic + MVVM/tap-flow (Phase 2–4: grep gate, logging cleanup; service read-only + ViewModel context-free + auth-aware; task_request routing; modal tap fix, stable keys, error UX).
- **PR3**: Tests + docs + release gates (Phase 5: unit/widget/integration, AppLogger everywhere, docs sync, release grep).

## Per-step evidence (updated as steps complete)

- **Phase 0**: Created `.TODO/TEST_notifications_2026-03-01.md`, `ACCEPTANCE_notifications_2026-03-01.md`, `THREAT_notifications_2026-03-01.md`, `CONTRACT_notifications_2026-03-01.md`, `MIGRATION_notifications_2026-03-01.md`. Delivery slices above.
- **Phase 1**: Patched `supabase/migrations/20260226_tender_award_payment_flow.sql` (body/data/read → message/metadata/is_read). Created `.TODO/RLS_notifications_matrix_2026-03-01.md`.
- **Phase 2**: Grep gate: no `createNotification`/`createOrUpdateNotification` in lib. RLS matrix doc created.
- **Phase 3**: `NotificationService` read/update-only with defense-in-depth user filter; `NotificationViewModel` context-free, auth-aware connect/disconnect; `DeepLinkService` task_request routing (metadata: conversation_id first, else task_id); AppLogger in service and ViewModel.
- **Phase 4**: Modal returns `Future<NotificationItem?>`; badge uses `NotificationsModal.show(context)` and navigates from parent context; stable keys (NotificationsModalKeys); error/retry UX; ViewModel.retry().
- **Phase 5**: Unit tests `test/unit/models/notification_model_test.dart`, `test/unit/notifications/notification_view_model_test.dart`; widget test `test/widget/notifications/notifications_modal_test.dart`. Docs: DEVELOPER_GUIDE (notifications server-generated), MVP_ROADMAP (Notifications completed). Release grep: no client notification writes; no ViewModel BuildContext routing.
- **Review (Plan Critic)**: Execution log phase table corrected; `NotificationItem.fromJson` hardened (metadata via `_parseMetadata`, id/userId/relatedEntityId safe toString, type null → 'system'); `NotificationService` markAsRead/markAllAsRead log when no session; unit test added for metadata parsing; all tests and analyze re-run. RLS/schema can be verified via MCP Supabase `execute_sql` with queries from `.TODO/RLS_notifications_matrix_2026-03-01.md` when project_id is available.
