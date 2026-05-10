# Docs sync — Everything up to date (Notification Routing + references)

**Workflow:** `.agents/workflows/slinedocs.md`  
**Completed:** 2026-03-08  
**Trigger:** User request to ensure everything up to date using DocsKeeper workflow.

## Summary

Full DocsKeeper pass: added missing **Notification Routing (13)** entry to Sline_Log; updated MVP_ROADMAP and STRUCTURE so notifications (push, Edge, foreground sync) are reflected; validated key references; added notification Edge functions to STRUCTURE supabase tree.

## Docs updated

| Doc | Changes |
|-----|--------|
| **Sline_Log.md** | New section "Notification Routing — Push queue, Edge, foreground sync (2026-03-08)": user_devices, notification_push_queue, trigger; PushDeviceService, getUnreadNotifications, ViewModel foreground sync; Edge push-notify, process-push-queue (CRON_SECRET, PUSH_NOTIFY_SECRET); diagram 13, runbook, checklist refs. |
| **MVP_ROADMAP.md** | Notifications row: added notification routing (2026-03-08) — user_devices, notification_push_queue, trigger, foreground sync, Edge functions, runbook and plan paths, diagram 13. |
| **STRUCTURE.md** | Notifications feature highlight: in-app list, PushDeviceService, user_devices, notification_push_queue, Edge (push-notify, process-push-queue), diagram 13 and plan ref. Supabase functions tree: added `push-notify/` and `process-push-queue/` entries. |

## References validated

- **Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md` — exists.
- **Execution log:** `.TODO/EXECUTION_LOG_Plan_NotificationRouting_2026-03-08.md` — exists.
- **Master report:** `.TODO/MASTER_REPORT_2026-03-08_NotificationRouting.md` — exists.
- **Runbook:** `.TODO/improvement_the_system/ImplementReady/13_notification-routing/RUNBOOK_notification_push.md` — exists.
- **Checklist:** `.TODO/improvement_the_system/ImplementReady/13_notification-routing/CHECKLIST_AND_SUMMARY.md` — exists.
- **Diagram 13:** `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md` — exists.
- **SUPABASE_SETUP** §5.13, §5.13a, §5.13b — user_devices, notification_push_queue, Edge refs and runbook path — already accurate.
- **DEVELOPER_GUIDE** §3 Notifications bullet — already describes foreground sync, stream, PushDeviceService, plan ref.

## Why each update was needed

1. **Sline_Log:** Notification Routing was implemented and hardened (CRON_SECRET, diagram 13, runbook) but had no dedicated Sline_Log entry; workflow requires every feature completion to be recorded with plan/execution/key paths.
2. **MVP_ROADMAP:** Notifications row did not mention push (user_devices, queue, Edge); status remains ✅ Completed but notes now match current implementation.
3. **STRUCTURE:** Notifications was listed in the feature folder list but had no "Feature Highlights" bullet; Edge functions push-notify and process-push-queue were missing from the supabase/functions tree.

## No changes needed

- **SUPABASE_SETUP.md** — §5.13a, §5.13b and runbook ref already correct.
- **DEVELOPER_GUIDE.md** — Notifications bullet already includes push and plan ref.
- **PROJECT_CONTEXT.md** — High-level; no notification-specific update required.
- **GEMINI.md**, **.cursor/rules** — Unchanged.

## Sign-off

Sline_everything and .TODO references are aligned with:

- Notification Routing (13): user_devices, notification_push_queue, trigger, PushDeviceService, Edge push-notify/process-push-queue, foreground sync, diagram 13, runbook, checklist.

DocsKeeper workflow (everything up to date) completed.
