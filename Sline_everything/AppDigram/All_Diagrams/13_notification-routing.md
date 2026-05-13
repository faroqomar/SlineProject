# Notification Routing — Diagram Document

**Diagram name:** 13_notification-routing
**Version:** v2.1 (Implemented + transient realtime reconnect note)
**Date:** 2026-05-13
**Owner/author:** DocsKeeper / Backend + Flutter
**Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`
**Contract:** `.TODO/improvement_the_system/ImplementReady/13_notification-routing/CONTRACT_notification_push.md`
**Runbook:** `.TODO/improvement_the_system/ImplementReady/13_notification-routing/RUNBOOK_notification_push.md`

---

## Purpose

- **What this diagram is showing:** How notifications are created (DB triggers and RPCs), stored in `notifications`, delivered in-app (foreground sync then realtime stream), and pushed to devices (queue + Edge Functions → FCM). It shows the strict server-authority rule: no client INSERT into notifications; push path is server-only.
- **What problem it solves (why it exists):** Ensures a single source of truth for notification creation and delivery; prevents clients from spoofing notifications; documents push plumbing (user_devices, notification_push_queue, Edge) and in-app behaviour (correct unread count via foreground sync before stream).

---

## Scope

- **Included:** Creation paths (messages trigger, booking/task/dispute RPCs and triggers); `notifications`, `user_devices`, `notification_push_queue`; trigger `trg_notifications_after_insert_push_queue`; Edge `push-notify`, `process-push-queue`; Flutter NotificationService (getUnreadNotifications, stream, markAsRead), PushDeviceService (registerDevice), NotificationViewModel (foreground sync then stream); realtime publication; RLS and auth (CRON_SECRET, optional PUSH_NOTIFY_SECRET).
- **Excluded:** FCM payload format details; APNs (future); pg_net-based push (alternative); notification content/localisation; deep-link handling UI (handled by DeepLinkService, not drawn).
- **Assumptions:** (1) All notification rows are created server-side (triggers/RPCs only). (2) Payments/booking/task events are finalised via RPCs or triggers that call `private_create_notification` or `private_upsert_notification`. (3) Push delivery uses FCM; Edge has access to `FCM_SERVER_KEY`. (4) Cron invokes `process-push-queue` with `Authorization: Bearer CRON_SECRET` every 1–2 minutes. (5) Realtime publication includes `notifications`; client subscribes with `user_id = auth.uid()`.

---

## Glossary (human-readable)

| Term | Definition |
|------|------------|
| **notification** | A row in `public.notifications`: title, message, type, recipient user_id, is_read, related_entity_id/type, created_at. |
| **user_devices** | Table storing FCM device tokens per (user_id, platform); one row per user per platform; RLS own-only. |
| **notification_push_queue** | Table holding pending push jobs; one row per notification INSERT; drained by Edge `process-push-queue`; status: pending → sent | failed. |
| **foreground sync** | On connect, ViewModel calls `getUnreadNotifications(50)` before starting the realtime stream so badge and first paint show correct unread set. |
| **private_create_notification** | Server-only function (RPC/trigger) that INSERTs one row into `notifications`. Used by pay_awarded_offer, tasks_after_status_change_notify_parties, dispute/booking flows. |
| **private_upsert_notification** | Server-only function: collapse-on-unread for same (user_id, type, related_entity_id, related_entity_type); used by message trigger. |
| **RPC** | Remote procedure call (Supabase Postgres function). |
| **RLS** | Row-Level Security; policies restrict SELECT/INSERT/UPDATE/DELETE by auth.uid(). |
| **CRON_SECRET** | Secret set in Edge; required to invoke `process-push-queue`; function returns 503 if unset. |
| **PUSH_NOTIFY_SECRET** | Optional secret for `push-notify`; when set, caller must send `Authorization: Bearer <secret>`. |
| **FCM** | Firebase Cloud Messaging; push delivery to iOS/Android. |
| **idempotency** | private_upsert_notification collapses duplicates (unread same entity); queue row is one-per-notification (no idempotency key in current design). |

---

## Legend

- **Nodes/shapes:** Rounded rectangle = process/function; cylinder `[(name)]` = table; `{name}` = trigger/guard; rectangle = app/service component.
- **Arrows:** Solid → = sync call or data flow; dotted -.-> = async delivery (e.g. OS push to device). Label on arrow = condition or payload.
- **Colours/labels:** Subgraphs group DB vs Edge vs App. No special colours; text labels indicate auth (e.g. "Bearer CRON_SECRET").
- **Guards:** Trigger “guards” are DB triggers that run automatically (e.g. AFTER INSERT ON notifications → insert into queue). Validation “guards”: Edge checks CRON_SECRET; push-notify checks PUSH_NOTIFY_SECRET when set.

---

## Actors and responsibilities

| Actor | Allowed | Forbidden |
|-------|--------|-----------|
| **User (app)** | Read own notifications (SELECT); update is_read (UPDATE own); register device (INSERT/UPDATE own row in user_devices). | INSERT into notifications; read other users’ notifications; modify user_devices of others. |
| **System / Cron** | Invoke `process-push-queue` with Bearer CRON_SECRET; read notification_push_queue and user_devices (service_role). | Invoke without CRON_SECRET (receives 503); expose FCM key. |
| **Backend (RPCs/triggers)** | Call private_create_notification / private_upsert_notification; insert into notifications (server-side). | N/A — only server runs these. |
| **Edge (push-notify)** | Accept POST with notification payload; when PUSH_NOTIFY_SECRET set, require Bearer; read user_devices; send to FCM. | Log FCM key or tokens; send push without valid auth when secret is set. |
| **Edge (process-push-queue)** | When CRON_SECRET set, accept Bearer; drain pending queue rows; send FCM; update status to sent/failed. | Run when CRON_SECRET unset (must return 503); expose secrets in logs. |

---

## System components (where it lives)

- **App entry points:** Top bar bell icon → Notification Center (modal); app open/resume/token refresh → PushDeviceService.registerDevice (when FCM token available).
- **Service/ViewModel/Repository:**
  - `lib/features/notifications/services/notification_service.dart` — getUnreadNotifications(limit), streamNotifications(), markAsRead, markAllAsRead.
  - `lib/features/notifications/services/push_device_service.dart` — registerDevice(fcmToken, platform) → user_devices upsert.
  - `lib/features/notifications/viewmodels/notification_view_model.dart` — _connect(): await getUnreadNotifications(50) then streamNotifications().listen(...); transient Supabase Realtime close codes `1002` and `1006` keep cached notifications visible and schedule reconnect.
- **Database objects:**
  - **Tables:** `notifications`, `user_devices`, `notification_push_queue`.
  - **Views:** None specific to this flow.
  - **RPCs:** `private_create_notification`, `private_upsert_notification` (called from other RPCs/triggers).
  - **Triggers:** `trg_messages_after_insert_notify_receiver` (messages → private_upsert_notification); `trg_notifications_after_insert_push_queue` (notifications INSERT → insert into notification_push_queue).
  - **Policies (RLS):** notifications: SELECT/UPDATE own only (no INSERT for anon/authenticated); user_devices: SELECT/INSERT/UPDATE/DELETE own only. notification_push_queue: no RLS (server-only; Edge uses service_role).

---

## Step-by-step flow (human story)

### Happy path — in-app

1. User opens app and is authenticated.
2. NotificationViewModel gets session → calls _connect().
3. _connect() awaits getUnreadNotifications(50) → NotificationService runs SELECT from notifications WHERE user_id = uid AND is_read = false, limit 50.
4. ViewModel sets state with that list (badge and list reflect unread).
5. ViewModel subscribes to streamNotifications() → `.stream(primaryKey: ['id']).eq('user_id', userId).order('created_at', ascending: false).limit(50)`.
6. New server-created notification appears in realtime; list and badge update.
7. User taps “Mark all as read” → markAllAsRead() → UPDATE notifications SET is_read = true WHERE user_id = uid.

### Happy path — push

1. Server (RPC or trigger) inserts a row into `notifications`.
2. Trigger trg_notifications_after_insert_push_queue fires → one row inserted into `notification_push_queue` (notification_id, user_id, title, message, type, status = 'pending').
3. Cron (1–2 min) calls POST process-push-queue with Authorization: Bearer CRON_SECRET.
4. Edge reads pending rows from notification_push_queue; for each, looks up user_devices by user_id; sends to FCM; updates row status to 'sent' (or 'failed').
5. Device receives push via OS; user may open app and see the same notification in the list (foreground sync + stream).

### Common failure paths

- **No session:** getUnreadNotifications and stream return empty; no crash; badge 0.
- **process-push-queue called without CRON_SECRET:** Edge returns 503 "Queue processor disabled; set CRON_SECRET and invoke with Authorization: Bearer <CRON_SECRET>".
- **CRON_SECRET unset:** Function returns 503; queue is not drained until secret is set and cron re-invokes.
- **FCM send fails:** Edge marks queue row status = 'failed'; logs error (no token in logs); no retry in current design (row stays failed).
- **Transient Realtime close in ViewModel:** Realtime close codes `1002`, `1006`, or subscribe timeout are treated as transport interruptions. ViewModel keeps the last known notification list, logs a warning, cancels the stale subscription, and schedules reconnect.
- **Non-transient stream error in ViewModel:** ViewModel logs the hard failure and exposes the existing user-facing notification load error.

---

## State machine (queue and read state)

- **notification_push_queue.status:** `pending` → `sent` | `failed`. Only process-push-queue can transition (reads pending, writes sent/failed). No other transitions.
- **notifications.is_read:** false → true. Only the recipient can UPDATE (RLS). No “unread” transition back in current design.
- **user_devices:** No state machine; upsert by (user_id, platform) on registerDevice.

---

## Invariants (must-always-be-true rules)

- No row in `notifications` is created by the client; only server-side triggers and RPCs insert.
- Client can only SELECT/UPDATE rows in `notifications` where user_id = auth.uid().
- Client can only SELECT/INSERT/UPDATE/DELETE rows in `user_devices` where user_id = auth.uid().
- Every notification INSERT causes at most one row in `notification_push_queue` (trigger is 1:1).
- process-push-queue must not run without CRON_SECRET (enforced by Edge returning 503 when unset).
- FCM_SERVER_KEY and tokens must never appear in logs or client.

---

## Guards and validation rules

| Guard | Where | Source of truth |
|-------|--------|------------------|
| No client INSERT into notifications | RLS (no insert policy for anon/authenticated) | DB |
| User can only read/update own notifications | RLS notifications_select_own, notifications_update_own | DB |
| User can only manage own user_devices | RLS on user_devices (user_id = auth.uid()) | DB |
| process-push-queue requires CRON_SECRET | Edge: if unset return 503; if set require Authorization: Bearer | Edge |
| push-notify optional auth | Edge: if PUSH_NOTIFY_SECRET set, require Bearer | Edge |
| Session required for getUnreadNotifications/stream | Flutter: check auth.currentUser; return empty if null | App (UX only; DB RLS is authority) |

---

## Failure modes (what can go wrong)

| Failure | System behaviour |
|---------|------------------|
| App crash mid-step | No DB commit from client (client only reads/updates). Queue and notifications unchanged. |
| Duplicate webhook/cron | process-push-queue is idempotent per row: read pending, send, set sent/failed. Double invoke may send same push twice (FCM dedup by message id if used). |
| Retry causing duplicates | private_upsert_notification collapses unread same (user_id, type, related_entity_*). private_create_notification has no idempotency key — callers must avoid duplicate calls. |
| Race (two users act at once) | Not applicable to notification creation (server-only). For mark-as-read, last write wins; RLS ensures user only updates own rows. |
| Missing FCM token | registerDevice no-ops if token null; push path skips or fails for that device; queue row can be marked failed. |
| CRON_SECRET unset | process-push-queue returns 503; queue not drained until secret set and cron fixed. |
| Timeout / TTL | No TTL on queue rows; failed rows stay. Optional: admin view or cleanup job for old failed rows (out of scope of this diagram). |

---

## Security and abuse scenarios

- **Spoofing identities:** RLS ensures user only sees/updates own notifications and own user_devices; notification creation is server-only.
- **Unauthorised state changes:** Only server can insert notifications; only recipient can update is_read; only owner can change user_devices.
- **Paying without owning entity:** N/A (notification flow does not move money).
- **User seeing another user’s private data:** RLS notifications_select_own and user_devices own-only prevent cross-user access.
- **Escrow trapped forever:** N/A (no escrow in notification flow).
- **Calling process-push-queue without permission:** 503 when CRON_SECRET unset; 401/403 when Bearer missing or wrong.

---

## Data model mapping

| Diagram / concept | DB / field |
|------------------|------------|
| “Unread” | notifications.is_read = false |
| “Read” | notifications.is_read = true |
| “Device token” | user_devices.fcm_token, user_devices.platform (ios | android) |
| “Pending push” | notification_push_queue.status = 'pending' |
| “Push sent” | notification_push_queue.status = 'sent' |
| “Push failed” | notification_push_queue.status = 'failed' |
| “Foreground sync” | App: getUnreadNotifications(50) before stream (no single DB field). |
| “Stream” | Realtime subscription on notifications with .eq('user_id', userId).limit(50). |

**Indexes:** user_devices(user_id) for lookup when sending push; notification_push_queue(status) or (created_at) for drain query (exact index names in SUPABASE_SETUP).

---

## Observability and forensics

- **Logs:** NotificationService/NotificationViewModel use AppLogger (tags e.g. Notifications); PushDeviceService logs registerDevice success/fail (no token in logs). Edge: process-push-queue logs push_batch (processed, sent, failed); error logs include notification_id (no token).
- **Audit:** No dedicated audit table for notifications; creation is via triggers/RPCs (Postgres logs if enabled). Queue status (sent/failed) is on notification_push_queue.
- **Admin views:** No admin “notification story” view in scope; queue table can be queried for pending/failed for debugging.

---

## Verification checklist

- **Unit tests:** NotificationService getUnreadNotifications, stream (mocked Supabase); ViewModel _connect and stream handling (mocked service).
- **Widget tests:** Notification center opens; list and “mark all read” (mocked ViewModel).
- **DB/RLS tests:** Authenticated user cannot INSERT into notifications (test exists: e.g. test/rls/ or test/unit/notifications/). user_devices RLS: own-only.
- **Concurrency:** Double mark-as-read is safe (last write wins). Duplicate cron invoke: process-push-queue idempotent per row (status update).

---

## Dependencies

- **Depends on:** Auth (session for stream and registerDevice); Realtime publication including `notifications` (SUPABASE_SETUP, diagram 18); FCM/project config for push.
- **Other diagrams that depend on this:** None required; notification deep links may reference work/booking/chat (diagrams 12, 05, 08).
- **Ordering:** user_devices and notification_push_queue migrations must be applied before Edge and cron; diagram 13 can be implemented after notifications table and message trigger exist.

---

## Open questions / missing evidence

- None. Contract, runbook, and code paths are verified. Optional: idempotency key for private_create_notification for callers that might retry; currently not implemented.

---

## Final status

- **Verdict:** PASS (Implemented)
- **Production ready?** YES, provided: (1) CRON_SECRET is set and cron invokes process-push-queue with Bearer; (2) FCM_SERVER_KEY is set for push; (3) PUSH_NOTIFY_SECRET set if push-notify is exposed. RLS and no client INSERT are enforced; foreground sync and queue are implemented and documented.
- **Next actions:** (1) Set secrets in production; (2) Schedule cron for process-push-queue; (3) Optional: add cleanup for old failed queue rows or admin view.

---

# NEW DIAGRAM (Implemented) — Mermaid

```mermaid
flowchart TD
    subgraph DB_Writes ["Database: notification creation"]
        MSG[Message INSERT] --> TRG_MSG{trg_messages_after_insert_notify_receiver}
        TRG_MSG -->|"message / offer / offer_accepted / offer_rejected"| UPSERT[private_upsert_notification]
        RPC[RPCs / Triggers\npay_awarded_offer, tasks_after_status_change_notify_parties, etc.] --> CREATE[private_create_notification]
        UPSERT --> NOTIFS[(notifications)]
        CREATE --> NOTIFS
    end

    subgraph Push_Queue ["Push queue (no pg_net)"]
        NOTIFS --> TRG_PUSH{trg_notifications_after_insert_push_queue}
        TRG_PUSH --> QUEUE[(notification_push_queue)]
    end

    subgraph Edge ["Edge Functions"]
        CRON[Cron 1–2 min] -->|"Authorization: Bearer CRON_SECRET"| DRAIN[process-push-queue]
        DRAIN --> QUEUE
        DRAIN --> DEVICES[(user_devices)]
        DRAIN --> FCM[FCM]
        PUSH[push-notify\noptional Bearer PUSH_NOTIFY_SECRET] --> DEVICES
        PUSH --> FCM
    end

    subgraph App ["Flutter app"]
        SYNC[getUnreadNotifications 50] --> VM[NotificationViewModel]
        NOTIFS --> REALTIME[supabase_realtime]
        REALTIME --> STREAM[.stream().eq user_id .limit 50]
        STREAM --> VM
        VM --> UI[Badge & list]
        REG[PushDeviceService.registerDevice] --> DEVICES
        FCM -.->|"OS push"| UI
    end
```

**Caption:** Notifications are created only server-side. In-app: ViewModel does foreground sync (getUnreadNotifications) then stream. Push: trigger enqueues to notification_push_queue; cron calls process-push-queue (CRON_SECRET); Edge reads user_devices and sends FCM.

---

# OLD DIAGRAM (Pre–checklist, retained for reference)

Below is the previous diagram document content (sections 1–6 and evidence table) before the full checklist and implemented diagram were added.

---

## OLD — Frontmatter

```yaml
---
title: "Notification Routing"
type: "Flowchart"
status: "Verified"
actors: ["System", "User"]
last_verified: "2026-03-08"
sources:
  code:
    - "lib/features/notifications/services/notification_service.dart — getUnreadNotifications(50), .stream(primaryKey:['id']).eq('user_id', userId).limit(50)"
    - "lib/features/notifications/services/push_device_service.dart — registerDevice → user_devices upsert"
    - "lib/features/notifications/viewmodels/notification_view_model.dart — foreground sync then stream"
  database:
    - "notifications table — destination for all notification inserts"
    - "user_devices table — FCM token registry (user_id, platform)"
    - "notification_push_queue table — pending push jobs"
    - "trg_messages_after_insert_notify_receiver ON messages → private_upsert_notification"
    - "trg_notifications_after_insert_push_queue ON notifications → enqueue to notification_push_queue"
    - "RPCs/triggers (pay_awarded_offer, tasks_after_status_change_notify_parties, etc.) → private_create_notification"
  edge:
    - "push-notify — single payload → FCM (optional PUSH_NOTIFY_SECRET)"
    - "process-push-queue — drain queue → FCM (requires CRON_SECRET)"
---
```

## OLD — 1) What this diagram is

Flowchart showing how notifications are created (DB triggers + RPCs), stored, delivered in-app (realtime + foreground sync), and pushed to devices (queue + Edge Functions → FCM).

## OLD — 2) Why it exists

Notifications are strictly backend-driven. No client INSERT into notifications. Push path is server-only (queue + cron-invoked Edge Function). Foreground sync ensures correct unread count before stream.

## OLD — 3) Where it lives in the product

- App: Top Bar Bell Icon, Notification Center.
- Service: `notification_service.dart` (getUnreadNotifications, stream, markAsRead); `push_device_service.dart` (registerDevice → user_devices).
- ViewModel: Foreground sync (getUnreadNotifications(50)) then stream(50); single source of truth.
- Supabase: Triggers on messages and notifications; RPCs call private_create_notification for booking/task/dispute; Edge Functions push-notify, process-push-queue.

## OLD — 4) Diagram (Mermaid)

```mermaid
flowchart TD
    subgraph DB_Writes ["Database: notification creation"]
        MSG[Message INSERT] --> TRG_MSG{trg_messages_after_insert_notify_receiver}
        TRG_MSG -->|"message / offer / offer_accepted / offer_rejected"| UPSERT[private_upsert_notification]
        RPC[RPCs / Triggers\npay_awarded_offer, tasks_after_status_change_notify_parties, etc.] --> CREATE[private_create_notification]
        UPSERT --> NOTIFS[(notifications)]
        CREATE --> NOTIFS
    end

    subgraph Push_Queue ["Push queue (no pg_net)"]
        NOTIFS --> TRG_PUSH{trg_notifications_after_insert_push_queue}
        TRG_PUSH --> QUEUE[(notification_push_queue)]
    end

    subgraph Edge ["Edge Functions"]
        CRON[Cron 1–2 min] -->|"Authorization: Bearer CRON_SECRET"| DRAIN[process-push-queue]
        DRAIN --> QUEUE
        DRAIN --> DEVICES[(user_devices)]
        DRAIN --> FCM[FCM]
        PUSH[push-notify\noptional Bearer PUSH_NOTIFY_SECRET] --> DEVICES
        PUSH --> FCM
    end

    subgraph App ["Flutter app"]
        NOTIFS --> REALTIME[supabase_realtime]
        REALTIME --> STREAM[.stream().eq user_id .limit 50]
        SYNC[getUnreadNotifications 50] --> VM[NotificationViewModel]
        STREAM --> VM
        VM --> UI[Badge & list]
        REG[PushDeviceService.registerDevice] --> DEVICES
        FCM -.->|"OS push"| UI
    end
```

## OLD — 5) Evidence table

| Element | Code / DB evidence | Verified |
|--------|---------------------|----------|
| Trigger on messages | trg_messages_after_insert_notify_receiver → private_upsert_notification | Y |
| Booking/task/dispute notifications | RPCs and triggers call private_create_notification (e.g. pay_awarded_offer, tasks_after_status_change_notify_parties) | Y |
| notifications table | RLS: no INSERT for anon/authenticated; SELECT/UPDATE own only | Y |
| user_devices | Table + RLS (own only); PushDeviceService upsert on login/resume/token refresh | Y |
| notification_push_queue + trigger | trg_notifications_after_insert_push_queue enqueues on notifications INSERT | Y |
| process-push-queue | Drains queue; requires CRON_SECRET; sends FCM; updates status | Y |
| push-notify | Single payload; optional PUSH_NOTIFY_SECRET; sends FCM | Y |
| Foreground sync | ViewModel _connect: getUnreadNotifications(50) then stream(50) | Y |
| Flutter stream | `.stream(primaryKey: ['id']).eq('user_id', userId).order('created_at', false).limit(50)` | Y |

## OLD — 6) Verification result

- Verdict: **VERIFIED**
- Date: 2026-03-08
- Plan: .TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md
- Contract: .TODO/improvement_the_system/ImplementReady/13_notification-routing/CONTRACT_notification_push.md
