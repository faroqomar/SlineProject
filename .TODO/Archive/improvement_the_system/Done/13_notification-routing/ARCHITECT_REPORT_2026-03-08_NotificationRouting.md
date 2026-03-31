# Architect Report: Notification Routing

**Scope:** Notification Routing (13_notification-routing)  
**Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`  
**Date:** 2026-03-08  
**Agent:** @Architect

---

## 1) Architecture / Logic Findings

### MVVM boundary check

- **View layer** (`lib/features/notifications/view/`): No direct Supabase calls. Verified: `grep Supabase.instance|\.from\(` in view returns no matches. All data via `Consumer<NotificationViewModel>`.
- **ViewModel** (`notification_view_model.dart`): Uses `NotificationService` and `PushDeviceService` (not yet wired). References `Supabase.instance.client.auth` in `_init` for auth state — acceptable for session subscription; no `.from()` or `.rpc()` in ViewModel.
- **Service layer** (`notification_service.dart`, `push_device_service.dart`): All Supabase access is in services. Single `NotificationService` for read/stream/update; single `PushDeviceService` for device upsert.

**Verdict:** MVVM boundaries respected.

### Data flow map

- Notifications list: `NotificationService.getUnreadNotifications(50)` → then `NotificationService.streamNotifications()` → ViewModel `_notifications` → View. Single source of truth: one stream plus one initial unread fetch (no duplicate subscriptions).
- Device registration: `PushDeviceService.registerDevice(fcmToken, platform)` → `user_devices` upsert (RLS: own row only). Not yet invoked from app (no Firebase); call sites to be added on login/resume/onTokenRefresh per plan.

### Contract checks

- **CONTRACT_notification_push.md:** user_devices columns match `UserDevice` model and migration. Push payload shape matches Edge Function `validatePayload` (notification_id, user_id, title, message, type, related_entity_id, related_entity_type).
- **Idempotency:** Documented; `private_upsert_notification` collapse-on-unread; no change to function signatures.

### Path validation

- All referenced paths exist: `lib/features/notifications/models/user_device_model.dart`, `services/push_device_service.dart`, `notification_service.dart`, `notification_view_model.dart`, `view/notifications_modal.dart`, `test/rls/notifications_insert_blocked_test.dart`.
- DB objects: `user_devices`, `notification_push_queue`, `notifications`, trigger `trg_notifications_after_insert_push_queue` — confirmed via execution log and MCP.

---

## 2) Proposed Refactors (Optional)

- **LOW:** Consider injecting `PushDeviceService` into `NotificationViewModel` (or a dedicated auth/lifecycle coordinator) so it can be tested without Supabase. Currently not wired; when wiring, prefer constructor injection.
- **LOW:** ViewModel `_init` uses `Supabase.instance.client.auth` when `authStateChanges` is null. Acceptable; could be abstracted behind a small AuthStateStream interface for tests if desired.

---

## 3) Contract / Plan Alignment

- Plan Phase 0–4 deliverables present: CONTRACT, RLS matrix, threat checklist, test infra, RLS test, user_devices migration, notification_push_queue + trigger, push-notify and process-push-queue Edge Functions, Flutter model/service/ViewModel foreground sync, docs updates.
- No missing plan steps in scope of Architect (logic/MVVM/data flow).

---

## 4) Evidence Summary

| Check | Result | Evidence |
|-------|--------|----------|
| View → no Supabase | Pass | grep on view/ : no matches |
| Single source of truth for list | Pass | One stream + one getUnreadNotifications in _connect |
| Services own Supabase | Pass | notification_service.dart, push_device_service.dart |
| Model matches contract | Pass | UserDevice ↔ CONTRACT user_devices |
| Payload shape in Edge | Pass | push-notify validatePayload matches CONTRACT §2 |

**Conclusion:** Architecture and MVVM compliance verified. No blockers. Optional refactors are low priority.
