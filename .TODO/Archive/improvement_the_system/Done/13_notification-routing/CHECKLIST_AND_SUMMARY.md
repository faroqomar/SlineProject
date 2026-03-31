# Notification Routing — What Changed & How to Check

**Plan:** 13_notification-routing (Plan Critic)  
**Date:** 2026-03-08

---

## In short: what we did and why

- **Why:** Notifications today only work when the app is open (realtime). We added the plumbing for **push when the app is closed** and made the **unread count correct** even with many notifications.
- **What:** We added a **device registry** in the DB, a **push queue** filled by a DB trigger, **Edge Functions** to send push via FCM, and in the app: **fetch unread first** then stream, plus a **device registration service** (used once you add Firebase).

Nothing was **removed**. Existing notification list, badge, mark-as-read, and realtime stream **behave as before**; we only added steps and new code.

---

## What was ADDED

| Where | What | Why |
|-------|------|-----|
| **Database** | Table `user_devices` (user_id, fcm_token, platform) | Store FCM tokens so the server can send push to the right device. |
| **Database** | Table `notification_push_queue` + trigger on `notifications` INSERT | Every new notification is queued; a cron job drains the queue and calls FCM (no heavy work in the trigger). |
| **Flutter** | `UserDevice` model | Matches `user_devices` row. |
| **Flutter** | `PushDeviceService` (register device token) | When you add Firebase, this will save the token to `user_devices` on login/resume. Right now it no-ops if no token is passed. |
| **Flutter** | `getUnreadNotifications(50)` in NotificationService | Load unread first so the badge isn’t wrong when there are more than 50 unread. |
| **Flutter** | ViewModel: on connect, **fetch unread first, then start stream** | Same as above: correct unread count before the 50-item stream takes over. |
| **Backend** | Edge Functions `push-notify` and `process-push-queue` | Send notifications to FCM. Cron calls `process-push-queue` every 1–2 min. |
| **Tests** | RLS test: authenticated user cannot INSERT into `notifications` | So we don’t accidentally allow client-side notification creation. |
| **Docs** | CONTRACT, RLS matrix, threat checklist, runbook, diagram 13 update | So the push flow and secrets are defined and findable. |

---

## What was REMOVED

- **Nothing.** All existing notification behaviour (list, stream, mark read, badge) is unchanged.

---

## What was MODIFIED

| Where | Change | Why |
|-------|--------|-----|
| **NotificationViewModel** | `_connect()` now **awaits** `getUnreadNotifications(50)` before starting the stream | So the first paint shows the right unread set and badge. |
| **NotificationService** | New method `getUnreadNotifications(limit: 50)` | Used by ViewModel for the initial unread fetch. |
| **DEVELOPER_GUIDE** | Notifications bullet: added push, user_devices, foreground sync, plan ref | Keep docs in sync with behaviour. |
| **SUPABASE_SETUP** | New tables §5.13a `user_devices`, §5.13b `notification_push_queue`; runbook ref | Single place to look up schema and push runbook. |
| **Diagram 13** | Full update: queue, trigger, Edge Functions, foreground sync, booking/task source | Diagram matches current implementation. |

---

## Checklist: check on the actual app

Use this on a running app (device or simulator).

### 1) Notifications still work (no regression)

- [ ] Open the app and log in.
- [ ] Tap the **bell** in the top bar.
- [ ] Notification center opens (list or empty state).
- [ ] If you have notifications: list shows, **Mark all as read** works.
- [ ] Badge on the bell shows unread count (or hides when 0).

### 2) Foreground “unread first” (new behaviour)

- [ ] With **no** notifications: open bell → empty state, no error.
- [ ] With **some** unread: open bell → list shows; count in badge matches list.
- [ ] (Optional) With 50+ unread: after opening, badge reflects full unread count, not capped at 50.

### 3) No crashes or errors in console

- [ ] Open notification center a few times.
- [ ] Mark one as read, then mark all as read.
- [ ] In debug console you see AppLogger lines (e.g. `Notifications`, `foreground sync then stream`) and **no** red errors or stack traces.

### 4) Backend / push (only if you deployed Edge and set secrets)

- [ ] Set Supabase secrets: `FCM_SERVER_KEY`, `CRON_SECRET` (see runbook).
- [ ] Deploy: `supabase functions deploy process-push-queue push-notify`.
- [ ] Call process-push-queue with `Authorization: Bearer <CRON_SECRET>` (e.g. cron or manual curl).
- [ ] When you add Firebase and register a device token, new notifications should be pushed when the app is in the background (test with a second user or a test notification).

### 5) Tests (from repo)

- [ ] Run:  
  `flutter test test/rls/notifications_insert_blocked_test.dart test/unit/notifications/ test/widget/notifications/`  
  All 7 tests should pass.

---

## One-line summary

We **added** push infrastructure (DB queue + trigger, Edge Functions, device table and service) and **foreground unread sync** so the badge is correct; we **did not remove or break** existing notification list, stream, or mark-as-read.
