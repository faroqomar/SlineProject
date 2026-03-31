# Observability Report: Notification Routing

**Scope:** Notification Routing (13_notification-routing)  
**Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`  
**Date:** 2026-03-08  
**Agent:** @Observability

---

## 1) What to log (Current State)

### Flutter (AppLogger)

- **Tag:** `Notifications` (notification_service, notification_view_model) and `NotificationRouting` (push_device_service).
- **Events:** getNotifications / getUnreadNotifications (fetch, count), streamNotifications (connect, received count), markAsRead / markAllAsRead, session/no-session; registerDevice (no session, no token, upserting platform, success, failed); ViewModel (session ready, signed out, foreground sync, initial unread count, stream error).
- **No token in logs:** FCM token and device tokens are never passed to AppLogger or printed. Compliant with THREAT_CHECKLIST_push.md.

### Edge Functions (console)

- **push-notify:** "FCM secret missing or invalid (value not logged)", "user_devices lookup failed:", "FCM send non-2xx (no token logged)", "FCM request failed:". No FCM key or token value logged.
- **process-push-queue:** Same FCM secret message; "Queue select failed:"; no token or key in logs.

**Verdict:** Privacy-safe; no secrets or tokens in logs.

---

## 2) What NOT to log

- FCM_SERVER_KEY, FCM token, fcm_token column value, CRON_SECRET.  
- **Verified:** No log statement includes token or key value. Edge uses generic "FCM secret missing/invalid (value not logged)".

---

## 3) Telemetry gaps

- **MED:** Push delivery outcome (sent/failed) is not persisted in a way that is easily queryable for metrics (queue status is updated but no aggregate "push_failures" event). Optional: log a structured event (e.g. `{ event: 'push_batch', processed, sent, failed }`) for dashboarding.
- **LOW:** Flutter: token registration failure is logged but not surfaced as a user-visible event (toast/snackbar). Plan allows "silent retry or toast"; current code is silent after log.
- **LOW:** Correlation: Edge Functions log error messages but not notification_id or user_id in the same line. Adding a correlation field (e.g. notification_id) to error logs would help trace failures.

---

## 4) Event taxonomy (Recommendation)

| Event / area | Where | Suggested fields | Do not log |
|--------------|--------|-------------------|------------|
| notification_fetch | NotificationService | tag, limit, count | - |
| notification_stream_connect | NotificationViewModel | tag | - |
| push_device_register | PushDeviceService | tag, platform, success/fail | token |
| push_batch | process-push-queue | processed, sent, failed | tokens, key |
| push_single | push-notify | sent, total | tokens, key |

---

## 5) Correlation strategy

- Current: Tag-based (`Notifications`, `NotificationRouting`). No correlation ID across request.
- Optional: Pass `notification_id` or `user_id` in Edge Function error logs (e.g. "user_devices lookup failed for user_id=<uuid>") to trace without logging tokens.

---

## 6) Evidence

- `lib/features/notifications/services/notification_service.dart`: AppLogger.d/i/e with tag 'Notifications'.
- `lib/features/notifications/services/push_device_service.dart`: AppLogger.d/i/e with tag 'NotificationRouting'; no token in any message.
- `lib/features/notifications/viewmodels/notification_view_model.dart`: AppLogger.d/e/w tag 'Notifications'.
- `supabase/functions/push-notify/index.ts`: console.error with fixed strings; FCM_SERVER_KEY not logged.
- `supabase/functions/process-push-queue/index.ts`: same.

**Conclusion:** Observability is sufficient and privacy-safe. Gaps are MED/LOW; no blocker. Optional: add correlation (e.g. notification_id) in Edge error logs and a structured push_batch event.
