# Contract: Notification Push & User Devices (13_notification-routing)

**Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`  
**Status:** Authoritative for Phase 1+ implementation.

---

## 1. Table: `user_devices`

| Column      | Type        | Nullable | Default             | Description                    |
|------------|-------------|----------|----------------------|--------------------------------|
| id         | uuid        | NO       | gen_random_uuid()    | Primary key                    |
| user_id    | uuid        | NO       | -                    | FK to profiles (auth.uid())    |
| fcm_token  | text        | NO       | -                    | FCM device token               |
| platform   | text        | NO       | -                    | 'ios' \| 'android'             |
| created_at | timestamptz | NO       | now()                | First registration             |
| updated_at | timestamptz | NO       | now()                | Last token refresh             |

- **Unique constraint:** `(user_id, platform)` — one row per user per platform; upsert on register.
- **Index:** `user_id` for lookup by recipient when sending push.
- **RLS:** User can SELECT / INSERT / UPDATE / DELETE only own rows (`user_id = auth.uid()`).

---

## 2. Push payload (trigger → Edge Function)

When a row is inserted into `notifications`, the push trigger (or cron job) sends this JSON body to the Edge Function:

```json
{
  "notification_id": "uuid",
  "user_id": "uuid",
  "title": "string",
  "message": "string",
  "type": "string",
  "related_entity_id": "uuid | null",
  "related_entity_type": "string | null"
}
```

- **Source:** `NEW` from `AFTER INSERT ON notifications`.
- **Delivery (no pg_net):** Trigger `trg_notifications_after_insert_push_queue` inserts one row into `notification_push_queue`. Edge Function `process-push-queue` (invoked by cron with `Authorization: Bearer <CRON_SECRET>`) selects pending rows, looks up `user_devices`, sends FCM, updates status to `sent`/`failed`.
- **Single payload (push-notify):** Edge Function `push-notify` accepts POST with the JSON above; validates; looks up `user_devices`; sends to FCM; returns 2xx. Use when pg_net is available (trigger calls this URL).
- **Error handling:** On validation or FCM failure, Edge Function logs (no token or key in logs); returns 4xx/5xx. No retry in trigger (queue row stays pending until process-push-queue processes it).
- **Auth:** process-push-queue requires `CRON_SECRET` to be set and `Authorization: Bearer <CRON_SECRET>`. push-notify: if `PUSH_NOTIFY_SECRET` is set, requires Bearer. See `.TODO/.../13_notification-routing/RUNBOOK_notification_push.md`.

---

## 3. Idempotency behaviour

- **`private_upsert_notification`:** Collapse-on-unread: if an unread notification exists for same (user_id, type, related_entity_id, related_entity_type), it updates that row (e.g. bumps count in metadata) and does not insert. No `idempotency_key` parameter in current signature.
- **`private_create_notification`:** No idempotency key; each call can insert a new row. Callers (RPCs/triggers) rely on transaction and business logic to avoid duplicates. Optional future: add `p_idempotency_key` and upsert semantics.

---

## 4. Flutter ↔ backend

- **Client:** Only reads and updates `notifications` (SELECT, UPDATE is_read). Inserts into `user_devices` (upsert by user_id + platform) with authenticated client; RLS enforces ownership.
- **Push path:** Server-only (trigger/cron → Edge Function → FCM). Client never calls FCM directly; no server key in client.
