# Master Report: Notification Routing (Orchestrator)

**Scope:** Notification Routing (13_notification-routing)  
**Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`  
**Date:** 2026-03-08  
**Pipeline:** Architect → Observability → DocsKeeper → CodeGuard

---

## A) Executive Summary

- **What was reviewed:** All code and docs for Notification Routing: Flutter (models, services, viewmodel, view), migrations (user_devices, notification_push_queue + trigger), Edge Functions (push-notify, process-push-queue), CONTRACT/RLS matrix/threat checklist, tests, and DEVELOPER_GUIDE/SUPABASE_SETUP.
- **Overall risk level:** MEDIUM (push path and optional auth hardening).
- **Final decision:** **Ready** — no pipeline blocker. Proceed with recommended hardening and doc update.

---

## B) Consolidated Findings (Deduplicated)

### Security

| Severity | Owner | Path / object | Finding | Fix |
|----------|--------|----------------|---------|-----|
| MED | CodeGuard | `supabase/functions/process-push-queue/index.ts` | When CRON_SECRET is unset, anyone can call the function. | Set CRON_SECRET in production; invoke with `Authorization: Bearer <CRON_SECRET>`. Document in runbook. |
| MED | CodeGuard | `supabase/functions/push-notify/index.ts` | No auth; if URL is public, anyone could POST and trigger pushes. | Restrict to internal/cron only or add secret header; document. |

### Data integrity

- No findings. RLS on user_devices and notifications is correct; notification_push_queue is server-only.

### Architecture / MVVM

- Architect: MVVM boundaries respected; single source of truth for notification list; paths and contracts validated. No refactor required.

### Performance

- No concerns. Trigger is insert-only; Flutter uses one stream + one initial fetch; batch size 50 is acceptable.

### Observability

| Severity | Owner | Finding | Fix |
|----------|--------|---------|-----|
| MED | Observability | Push batch outcome not easily queryable for metrics. | Optional: log structured event (e.g. push_batch with processed/sent/failed). |
| LOW | Observability | Edge error logs could include notification_id for correlation. | Optional: add notification_id to console.error context. |

### Docs / reference integrity

| Severity | Owner | Path | Finding | Fix |
|----------|--------|------|---------|-----|
| MED | DocsKeeper | `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md` | Diagram outdated: missing user_devices, notification_push_queue, trigger, Edge Functions, foreground sync; booking/dispute source still "UNVERIFIED". | Update diagram to match CONTRACT and implementation (see DOCS_REPORT). |

---

## C) Fix Plan (Ordered, step-by-step)

| Step | Owner | Action | Verification |
|------|--------|--------|--------------|
| 1 | @Supabase_Ops / DevOps | Set `CRON_SECRET` for production and document that process-push-queue must be invoked with `Authorization: Bearer <CRON_SECRET>`. | Runbook updated; secret set in project. |
| 2 | @Architect / Backend | Document push-notify as internal-only or add auth (e.g. secret header); ensure it is not publicly callable in production. | Doc or code review. |
| 3 | @DocsKeeper | Update `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md`: add user_devices, notification_push_queue, trigger, push-notify/process-push-queue, foreground sync; correct booking/dispute source to RPC/triggers. | Diagram matches CONTRACT and execution log. |
| 4 | @Observability (optional) | Add correlation (e.g. notification_id) to Edge Function error logs; optional structured push_batch event. | Log sample checked. |
| 5 | @CodeGuard | Re-run review after steps 1–3 if desired. | CODEGUARD_REVIEW re-run. |

---

## D) Regression checklist

- **Critical flows:** (1) Open app → notification list loads and stream updates. (2) Mark as read / mark all as read. (3) Insert notification (server-side) → row in notification_push_queue. (4) process-push-queue → pending rows processed, status updated.
- **Quick test:** `flutter test test/rls/notifications_insert_blocked_test.dart test/unit/notifications/ test/widget/notifications/`; manual: open notification center, send message from another user, check in-app notification and (if FCM configured) push.

---

## E) Rollback notes

- **DB:** Drop trigger `trg_notifications_after_insert_push_queue`; optionally drop `notification_push_queue`; optionally drop `user_devices`. Never drop `notifications` or change its RLS.
- **Edge:** Deploy no-op versions of push-notify and process-push-queue or remove invocations.
- **Flutter:** Revert NotificationViewModel _connect (remove getUnreadNotifications await) and remove getUnreadNotifications from service if needed; remove PushDeviceService and UserDevice model if needed.

---

## F) Next actions

1. **Before production:** Set `CRON_SECRET`; restrict or document push-notify access.
2. **Docs:** Update diagram 13 per DOCS_REPORT.
3. **Optional:** Add correlation and push_batch event per Observability report.
4. **Deploy:** Deploy Edge Functions (`push-notify`, `process-push-queue`); set `FCM_SERVER_KEY` (and `CRON_SECRET`); schedule cron for process-push-queue.

Pipeline status: **Complete.** No BLOCKER. Ready with recommendations.

---

## G) Fixes applied (2026-03-08)

| Step | Action | Done |
|------|--------|------|
| 1 | process-push-queue: require CRON_SECRET (return 503 if unset); require Bearer when set | ✅ |
| 2 | push-notify: optional PUSH_NOTIFY_SECRET; when set require Authorization: Bearer | ✅ |
| 3 | Diagram 13 updated: user_devices, queue, trigger, Edge, foreground sync, booking source (RPCs/triggers) | ✅ |
| 4 | Observability: notification_id in Edge error logs; structured push_batch log (processed, sent, failed) | ✅ |
| 5 | Runbook: RUNBOOK_notification_push.md (secrets, process-push-queue, push-notify); CONTRACT + SUPABASE_SETUP refs | ✅ |

Tests: `flutter test test/rls/notifications_insert_blocked_test.dart test/unit/notifications/ test/widget/notifications/` — 7 passed.
