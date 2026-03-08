# Docs Report: Notification Routing

**Scope:** Notification Routing (13_notification-routing)  
**Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`  
**Date:** 2026-03-08  
**Agent:** @SlineDocs

---

## 1) Documentation delta (What changed)

- **DEVELOPER_GUIDE.md:** Notifications bullet updated: foreground sync, user_devices, PushDeviceService, server-only push, plan reference.
- **SUPABASE_SETUP.md:** Quick reference table: added `user_devices`, `notification_push_queue`. New §5.13a user_devices, §5.13b notification_push_queue (columns, trigger, Edge Functions).
- **.TODO/EXECUTION_LOG_Plan_NotificationRouting_2026-03-08.md:** Phase 1 updated with queue + trigger + Edge Functions; Deferred and Rollback updated.
- **.TODO/.../13_notification-routing/CONTRACT_notification_push.md:** Updated with queue + process-push-queue and push-notify behavior.

---

## 2) Reference integrity scan

### Validated references

- Plan path `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md` exists.
- CONTRACT path `.TODO/improvement_the_system/ImplementReady/13_notification-routing/CONTRACT_notification_push.md` exists.
- Code paths referenced in docs (notification_service, PushDeviceService, user_devices, notification_push_queue) exist.
- DB objects: user_devices, notification_push_queue, trg_notifications_after_insert_push_queue — present (per MCP/execution log).

### Broken or outdated references

- **Diagram 13:** `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md` is **outdated**. It does not include:
  - user_devices table or PushDeviceService
  - notification_push_queue or trg_notifications_after_insert_push_queue
  - push-notify / process-push-queue Edge Functions
  - Foreground sync (getUnreadNotifications then stream)
  - Booking/dispute sources (plan and System Critic state they are RPC/trigger via private_create_notification, not "UNVERIFIED")
- **Required update:** Refresh diagram 13 to show: DB triggers + RPCs → notifications; trigger → notification_push_queue; process-push-queue (cron) → FCM; Flutter: getUnreadNotifications then stream, PushDeviceService → user_devices; and correct Booking/Dispute source (RPC/triggers).

---

## 3) Required doc updates (Ordered)

| # | Update | Owner | Verification |
|---|--------|--------|---------------|
| 1 | Update `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md`: add user_devices, notification_push_queue, trigger, Edge Functions, foreground sync, correct booking/dispute source. | @SlineDocs | Diagram matches CONTRACT and execution log. |
| 2 | Optional: Add a short "Notification push" subsection under DEVELOPER_GUIDE feature map pointing to CONTRACT and SUPABASE_SETUP §5.13a/5.13b. | @SlineDocs | Refs valid. |

---

## 4) Reference list (No broken refs except diagram)

- DEVELOPER_GUIDE.md → plan ref: valid.
- SUPABASE_SETUP.md → table names, section numbers: valid.
- CONTRACT → plan ref: valid.
- Execution log → plan, CONTRACT, migrations: valid.
- Diagram 13: **outdated** (see above).

**Conclusion:** One required update (diagram 13). No other broken references. No blocker if diagram update is scheduled; otherwise recommend updating diagram before release.
