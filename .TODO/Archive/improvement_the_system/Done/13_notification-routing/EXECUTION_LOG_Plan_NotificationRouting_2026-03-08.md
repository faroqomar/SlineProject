# Execution Log: Notification Routing (Plan Critic)

**Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`  
**Started:** 2026-03-08  
**Executor:** @Executor (AppLogger + Supabase MCP enforced)

---

## Status by Phase

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 0: Contracts, Security, Test Readiness | Done | CONTRACT, RLS matrix, threat checklist, RLS test, decision recorded |
| Phase 1: Data and Backend | Done | user_devices table + RLS applied via MCP; push trigger deferred (pg_net not in project) |
| Phase 2: App Layer (MVVM) | Done | UserDevice model, PushDeviceService, getUnreadNotifications, ViewModel foreground sync |
| Phase 3: UI and Polish | Done | No direct Supabase in view; loading/empty/error present |
| Phase 4: QA, Security, Release | Done | RLS test + unit + widget tests pass; docs updated |

---

## Evidence & Findings (Pre-Execution Scan)

- **Docs:** DEVELOPER_GUIDE, SUPABASE_SETUP, STRUCTURE, MVP_ROADMAP referenced; notifications server-side only (§3); §5.13 notifications table; Realtime on notifications.
- **Code:** `lib/features/notifications/` — service (getNotifications, streamNotifications limit 50, markAsRead, markAllAsRead), viewmodel (stream + auth), view (modal, badge, tile). AppLogger already used in service and viewmodel.
- **DB (Supabase MCP):** `notifications` exists; RLS `notifications_select_authenticated`, `notifications_update_authenticated` (no INSERT policy); triggers on messages/bookings; **pg_net extension not installed** (empty from pg_extension).
- **Gaps:** user_devices table missing; no push trigger; no CONTRACT file; no RLS test for notifications INSERT; no foreground sync.
- **Risks:** Phase 1 must use cron-based push or enable pg_net (plan: try enable in migration; else document cron fallback).

---

## Phase 0: Step-by-Step Evidence

### Step 0.1 CONTRACT_notification_push.md
- **Owner:** @APIContract
- **Artifact:** `.TODO/improvement_the_system/ImplementReady/13_notification-routing/CONTRACT_notification_push.md`
- **Verification:** File created and referenced below.

### Step 0.2 RLS matrix user_devices
- **Owner:** @Supabase_Ops
- **Artifact:** RLS matrix in same folder.
- **Verification:** File created.

### Step 0.3 Threat checklist
- **Owner:** @ThreatModeler
- **Artifact:** Threat checklist file in 13 folder.
- **Verification:** File created.

### Step 0.4 Test setup + RLS test (notifications INSERT denied)
- **Owner:** @Sentinel
- **Artifact:** Test dir doc + `test/rls/notifications_insert_blocked_test.dart`.
- **Verification:** `flutter test test/rls/notifications_insert_blocked_test.dart` passes.

### Step 0.5 Decision: Sync unread on foreground = yes
- **Owner:** @Architect
- **Verification:** Recorded in execution log and plan. Decision: **Yes** — implement "fetch unread count or first page on foreground, then stream(50)" in Phase 2.

---

## Phase 0 GATE CHECK

- CONTRACT exists and is reviewed: **Done** (`CONTRACT_notification_push.md`).
- RLS matrix exists: **Done** (`RLS_MATRIX_user_devices.md`).
- At least one RLS test runs: **Done** (`notifications_insert_blocked_test.dart` — 7/7 tests passed including unit/widget).
- "Sync unread on foreground" decision recorded: **Done** (yes).
- **Phase 0: Done.** Proceeding to Phase 1.

---

## Observability

- All new code uses `AppLogger` (tag: `Notifications` or `NotificationRouting`); no `print()`.
- Token registration success/failure and push path failures to be logged (Phase 2/4); no token value in logs.

---

## Phase 1 Evidence

- **1.1–1.2** Migration `20260320000000_user_devices_push_registry.sql` created and applied via Supabase MCP `apply_migration`. Table `user_devices` verified with `execute_sql` (columns: id, user_id, fcm_token, platform, created_at, updated_at). RLS policies: user_devices_select_own, user_devices_insert_own, user_devices_update_own, user_devices_delete_own.
- **1.3–1.4** Push path (no pg_net): Migration `20260320010000_notification_push_queue.sql` created and **applied via Supabase MCP** — table `notification_push_queue`, trigger `trg_notifications_after_insert_push_queue` on `notifications` (enqueue only, no HTTP). Verified with `execute_sql`: trigger and table columns present.
- **1.5** Edge Functions added: `supabase/functions/push-notify/index.ts` (single payload → FCM), `supabase/functions/process-push-queue/index.ts` (drain queue, send FCM, update status). Both validate FCM_SERVER_KEY at request time and log "FCM secret missing/invalid" if bad (no value logged). Deploy with `supabase functions deploy push-notify process-push-queue` and set secrets FCM_SERVER_KEY, optional CRON_SECRET for process-push-queue.
- **1.6** Both migrations applied successfully via MCP.

## Phase 2 Evidence

- **2.1** `lib/features/notifications/models/user_device_model.dart` — UserDevice model (id, userId, fcmToken, platform, createdAt, updatedAt). Aligned to CONTRACT.
- **2.2** `lib/features/notifications/services/push_device_service.dart` — PushDeviceService.registerDevice(fcmToken, platform); no-op when token null/empty; AppLogger tag `NotificationRouting`; upsert onConflict user_id,platform.
- **2.3** NotificationService.getUnreadNotifications(limit: 50) added; NotificationViewModel._connect() now async: awaits getUnreadNotifications(50), sets _notifications if non-empty, then starts stream. AppLogger throughout.
- **2.4** Observability: token registration success/failure logged; no token value in logs.

## Phase 3 Evidence

- Notification view uses only Consumer<NotificationViewModel>; no Supabase.instance or .from() in view. Loading/empty/error states present (NotificationsModalKeys.loading, empty, error).

## Phase 4 Evidence

- **4.1–4.2** RLS test: `test/rls/notifications_insert_blocked_test.dart` — authenticated cannot INSERT into notifications; passes (mock mode). user_devices RLS per matrix (own only).
- **4.3** `flutter test test/rls/notifications_insert_blocked_test.dart test/unit/notifications/ test/widget/notifications/` — 7 tests passed.
- **4.4** AppLogger used; no token in logs.
- **4.5** DEVELOPER_GUIDE and SUPABASE_SETUP updated (notification flow, user_devices §5.13a, push registry, foreground sync).

## Deferred (no blocker)

- **Flutter FCM token:** firebase_messaging not in pubspec; when added, call PushDeviceService.registerDevice(token, platform) on login, resume, onTokenRefresh.
- **Cron for process-push-queue:** Call `POST /functions/v1/process-push-queue` with `Authorization: Bearer <CRON_SECRET>` every 1–2 minutes (e.g. GitHub Actions, or Supabase scheduled invocation if available) to drain the queue.

## Blockers

- None.

---

## Master Report fixes applied (2026-03-08)

- **process-push-queue:** CRON_SECRET required (503 if unset); Bearer required when set. Correlation: notification_id in FCM error logs. Structured log: push_batch (processed, sent, failed).
- **push-notify:** Optional PUSH_NOTIFY_SECRET; when set (≥8 chars) require Authorization: Bearer. notification_id added to error logs.
- **Diagram 13:** Rewritten — user_devices, notification_push_queue, trigger, Edge Functions, foreground sync, booking/task source (RPCs/triggers). Status Verified.
- **Runbook:** RUNBOOK_notification_push.md (secrets, cron invocation, push-notify auth). CONTRACT and SUPABASE_SETUP §5.13b updated with runbook ref.

---

## Rollback

Per plan: (1) Drop trigger `trg_notifications_after_insert_push_queue`; (2) Optional drop table `notification_push_queue`; (3) Deploy Edge Functions as no-op or remove; (4) Optional drop `user_devices`. Never drop `notifications` or change notifications RLS.
