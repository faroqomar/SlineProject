# Notification Contract (2026-03-01)

## DB: `public.notifications`

- **Columns (live)**: `id`, `user_id`, `title`, `message`, `type`, `related_entity_id`, `related_entity_type`, `is_read`, `metadata`, `created_at`.
- **App mapping**: `NotificationItem` uses `message`, `is_read`, `metadata`. Unknown `type` → `NotificationType.system`.
- **Legacy/alias**: Some migrations (e.g. 20260226 before patch) used `body`/`data`/`read`; repo is aligned to `message`/`metadata`/`is_read` for fresh bootstrap.

## Server-emitted types (from migrations / triggers)

- `message`, `offer` (messages trigger).
- `task` (tasks status change).
- `offer_awarded`, `payment_required`, `work_active`, `award_expired` (tender/payment flow in 20260226).
- App enum: `offer`, `message`, `system`, `booking`, `task`, `payment`, `review`. Unsupported DB types map to `system` and should be logged (no PII).

## related_entity_type and routing

Supported deep-link entity types: task, offer, booking, conversation, message, direct_offer, profile, user (see `DeepLinkService.supportedEntityTypes`); task_request is routed via metadata in `handleNotification`.

- **task**: navigate to task details.
- **booking**: navigate to booking details.
- **conversation** / **message**: navigate to chat.
- **direct_offer** / **directoffer**: navigate to direct offer details.
- **task_request**: resolve from metadata — `conversation_id` first, else `task_id`; then open conversation or task details accordingly.
- **profile** / **user**: profile screens.
- Unsupported: log type, show SnackBar "Cannot open this item type"; no crash.

## Producer matrix (server-side only)

- **Chat**: `trg_messages_after_insert_notify_receiver` → `private_upsert_notification`.
- **Tasks (status)**: `trg_tasks_after_status_change_notify_parties` → `private_create_notification`.
- **Tender/award/payment**: RPCs in 20260226 / reconcile / harden migrations → `private_create_notification` or INSERT (patched to use message/is_read/metadata).
- Client: no direct INSERT; read/update only.

## Realtime

- `public.notifications` in `supabase_realtime`; app streams by primaryKey `id`; RLS limits to own rows.
