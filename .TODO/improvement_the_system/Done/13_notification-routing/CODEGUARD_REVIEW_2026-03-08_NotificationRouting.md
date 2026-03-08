# CodeGuard Review: Notification Routing

**Scope:** Notification Routing (13_notification-routing)  
**Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`  
**Date:** 2026-03-08  
**Agent:** @CodeGuard

---

## 1) Risk rating

- **Overall:** MEDIUM (new DB objects, new Edge Functions, push path; no wallet/booking state machine change).
- **Security:** MEDIUM (push path server-only; CRON_SECRET optional).
- **Performance:** LOW (trigger is insert-only; no N+1 in Flutter).
- **Compatibility:** LOW (additive only).

---

## 2) Security

- **RLS:** user_devices has SELECT/INSERT/UPDATE/DELETE own only. notifications: no INSERT for anon/authenticated. notification_push_queue: no RLS (server-only; Edge uses service_role). **OK.**
- **Secrets:** FCM_SERVER_KEY only in Edge env; never in client or logs. **OK.**
- **process-push-queue auth:** When `CRON_SECRET` is empty, the check `if (CRON_SECRET && auth !== ...)` does not run, so **anyone can call** the function and drain the queue (and trigger FCM sends). **Finding (MED):** In production, set `CRON_SECRET` and invoke with `Authorization: Bearer <CRON_SECRET>`. Document in deployment/runbook.
- **push-notify:** No auth check; intended for server-side (pg_net or internal) callers. If exposed publicly, anyone could POST and send pushes to users. **Recommendation:** Deploy with Supabase Edge Function auth or restrict by IP/secret in production; document.

---

## 3) Performance

- **Trigger:** notifications_after_insert_push_queue only inserts one row; no HTTP, no heavy work. **OK.**
- **Flutter:** Single stream + one getUnreadNotifications(50) per connect; no duplicate subscriptions. **OK.**
- **process-push-queue:** Fetches up to 50 rows, then one user_devices select per row. For 50 users this is 51 queries. **LOW:** Acceptable for batch size 50; if scaling, consider batching user_devices lookups.

---

## 4) Compatibility / Freshness

- Flutter: No new dependencies (firebase_messaging not added). Supabase client usage matches existing patterns.
- Edge: Uses existing _shared/bookin_payment.ts (createAdminClient, jsonResponse, corsHeaders). FCM legacy HTTP API (fcm.googleapis.com/fcm/send) used; still supported for server key.
- **No blocker.**

---

## 5) Verification commands

```bash
flutter analyze lib/features/notifications/
flutter test test/rls/notifications_insert_blocked_test.dart test/unit/notifications/ test/widget/notifications/
```

- RLS test: Confirms authenticated cannot INSERT into notifications (mock mode; with real client would assert 42501).

---

## 6) Blockers and findings

| Severity | Finding | Fix |
|----------|---------|-----|
| MED | process-push-queue callable by anyone when CRON_SECRET unset | Set CRON_SECRET in production; document. |
| MED | push-notify has no auth | Restrict to internal/cron or add secret header; document. |
| LOW | Diagram 13 outdated | Update diagram (see DOCS_REPORT). |

**No BLOCKER** that halts the pipeline. Recommendations are hardening and docs.

---

## 7) Decision

**APPROVED** with recommendations:
- Set `CRON_SECRET` for process-push-queue in production.
- Document push-notify as internal-only or add auth.
- Update diagram 13 per SlineDocs report.
