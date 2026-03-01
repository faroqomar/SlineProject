# Live DB Baseline — Bookin Remediation — 2026-02-28

- Plan reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_Bookin_Remediation_2026-02-28.md`
- Source of truth: live Supabase project `isddrknbjsgaantjojhm` via configured MCP server
- Capture date: 2026-02-28
- Gate result: Pass
- Notes:
  - This artifact replaces the earlier “blocked” assumption after MCP-backed live inspection succeeded.
  - All values below are live observations unless explicitly marked as inference.

## Object Classification

| Object | Live status | Phase 0 classification |
| --- | --- | --- |
| `public.bookings` | Exists | `change` |
| `public.availability_slots` | Exists | `change` |
| `public.notifications` | Exists | `change` |
| `public.booking_status_enum` | Exists | `change` |
| `public.payment_status_enum` | Exists as referenced by `bookings.payment_status` | `change` |
| `public.process_payment_event_ledger(...)` | Exists | `change` |
| `public.fn_booking_guard()` | Exists | `change` |
| `public.fn_log_booking_activity()` | Exists | `change` |
| `public.set_booking_completed_at()` | Exists | `change` |
| `qicard_webhook_handler` edge function | Exists, active, `verify_jwt=false` | `change` |
| `rpc_create_booking_draft_validated` | Not found in live function scan | `create` |
| `rpc_finalize_booking_refund` | Not found in live function scan | `create` |
| `qicard_payment_create` edge function | Not found in live edge-function scan | `create` |
| `qicard_payment_recovery` edge function | Not found in live edge-function scan | `create` |
| `booking_decline_refund` edge function | Not found in live edge-function scan | `create` |

## Live Tables

### `public.availability_slots`

- Columns:
  - `id uuid not null default gen_random_uuid()`
  - `provider_id uuid not null`
  - `starts_at timestamptz not null`
  - `ends_at timestamptz not null`
  - `is_blocked bool not null default false`
  - `created_at timestamptz not null default now()`
- Constraints:
  - PK: `availability_slots_pkey (id)`
  - FK: `fk_slots_provider (provider_id -> auth.users.id on delete cascade)`
  - Check: `chk_slot_time (ends_at > starts_at)`
  - Exclusion: `excl_slots_provider_time` on `(provider_id, tstzrange(starts_at, ends_at, '[)')) where is_blocked = false`
- Indexes:
  - `availability_slots_pkey`
  - `excl_slots_provider_time`

### `public.bookings`

- Columns:
  - `id uuid not null default gen_random_uuid()`
  - `task_id uuid null`
  - `provider_id uuid not null`
  - `client_id uuid not null`
  - `slot_id uuid null`
  - `status booking_status_enum not null default 'pending'`
  - `note text null`
  - `created_at timestamptz not null default now()`
  - `completed_at timestamptz null`
  - `payment_status payment_status_enum null default 'unpaid'`
  - `requirements jsonb null default '{}'::jsonb`
  - `package_id text null`
  - `price numeric null default 0`
  - `delivered_at timestamptz null`
  - `review_expires_at timestamptz null`
  - `revisions_total int4 null default 3`
  - `revisions_used int4 null default 0`
  - `revision_note text null`
  - `revision_requested_at timestamptz null`
- Constraints:
  - PK: `bookings_pkey (id)`
  - FK: `bookings_slot_id_fkey (slot_id -> availability_slots.id on delete cascade)`
  - FK: `bookings_task_id_fkey (task_id -> tasks.id on delete cascade)`
  - FK: `fk_bookings_client (client_id -> auth.users.id on delete cascade)`
  - FK: `fk_bookings_provider (provider_id -> auth.users.id on delete cascade)`
- Indexes:
  - `bookings_pkey`
  - `idx_bookings_client_status (client_id, status)`
  - `idx_bookings_provider_status (provider_id, status)`
  - `idx_bookings_slot_id (slot_id)`

### `public.notifications`

- Columns:
  - `id uuid not null default gen_random_uuid()`
  - `user_id uuid not null`
  - `title text not null`
  - `message text not null`
  - `type text not null`
  - `related_entity_id uuid null`
  - `related_entity_type text null`
  - `is_read bool not null default false`
  - `created_at timestamptz not null default now()`
  - `metadata jsonb null default '{}'::jsonb`
- Constraints:
  - PK: `notifications_pkey (id)`
  - FK: `notifications_user_id_fkey (user_id -> profiles.id on delete cascade)`
  - Check: `notifications_type_check`
- Indexes:
  - `notifications_pkey`
  - `idx_notifications_created_at (created_at desc)`
  - `idx_notifications_user_read (user_id, is_read)`

## Live Booking-Related Enums

- `public.booking_status_enum`
  - `pending`
  - `confirmed`
  - `in_progress`
  - `canceled`
  - `completed`
  - `paid_request_pending`
  - `active`
  - `delivered`
  - `refunded`
  - `expired_unanswered`
- Additional booking-adjacent enum values observed:
  - `public.related_entity_type_enum` includes `booking`
  - `public.task_type_enum` includes `booking`

## Live Triggers

### `public.availability_slots`

- `trg_no_overlap_slots`
  - `BEFORE INSERT`
  - `BEFORE UPDATE`
  - executes `fn_reject_overlapping_slots()`

### `public.bookings`

- `t_activate_contract_bookings`
  - `AFTER UPDATE`
  - executes `trg_activate_contract()`
- `t_freeze_contract_bookings`
  - `BEFORE UPDATE`
  - executes `trg_freeze_contract_fields()`
- `trg_booking_guard`
  - `BEFORE UPDATE`
  - executes `fn_booking_guard()`
- `trg_log_booking_activity`
  - `AFTER INSERT`
  - `AFTER UPDATE`
  - executes `fn_log_booking_activity()`
- `trg_set_booking_completed_at`
  - `BEFORE UPDATE`
  - executes `set_booking_completed_at()`

### `public.notifications`

- No live triggers were returned.

## Live RLS State

- `public.availability_slots`: `rls_enabled=true`, `rls_forced=false`
- `public.bookings`: `rls_enabled=true`, `rls_forced=false`
- `public.notifications`: `rls_enabled=true`, `rls_forced=false`

## Live Policies

### `public.availability_slots`

- `slots_select_read`
  - role set: `{authenticated}`
  - command: `SELECT`
  - using: `true`
- `slots_write_owner`
  - role set: `{authenticated}`
  - command: `ALL`
  - using / check: `provider_id = auth.uid()`

### `public.bookings`

- `bookings_cancel_by_client`
  - role set: `{authenticated}`
  - command: `UPDATE`
  - using: `client_id = auth.uid()`
  - with check: `client_id = auth.uid() and status = 'canceled'`
- `bookings_deny_delete`
  - role set: `{public}`
  - command: `DELETE`
  - using: `false`
- `bookings_insert_by_client`
  - role set: `{authenticated}`
  - command: `INSERT`
  - with check: `client_id = auth.uid()` and slot must not be blocked
- `bookings_insert_client`
  - role set: `{public}`
  - command: `INSERT`
  - with check: `auth.uid() = client_id`
- `bookings_select_by_parties`
  - role set: `{authenticated}`
  - command: `SELECT`
  - using: `client_id = auth.uid() or provider_id = auth.uid()`
- `bookings_select_parties`
  - role set: `{public}`
  - command: `SELECT`
  - using: `auth.uid() = client_id or auth.uid() = provider_id`
- `bookings_update_by_provider`
  - role set: `{authenticated}`
  - command: `UPDATE`
  - using / check: `provider_id = auth.uid()`
- `bookings_update_status_only`
  - role set: `{public}`
  - command: `UPDATE`
  - using: `auth.uid() = client_id or auth.uid() = provider_id`

### `public.notifications`

- `notifications_insert_any`
  - role set: `{public}`
  - command: `INSERT`
  - with check: `auth.role() = 'authenticated'`
- `notifications_select_own`
  - role set: `{public}`
  - command: `SELECT`
  - using: `user_id = auth.uid()`
- `notifications_update_own`
  - role set: `{public}`
  - command: `UPDATE`
  - using / check: `user_id = auth.uid()`

## Live Grants

- Live grants on all three tables are broad at the SQL-grant layer for `anon`, `authenticated`, and `service_role`:
  - `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `REFERENCES`, `TRIGGER`, `TRUNCATE`
- Inference:
  - RLS is currently carrying most of the safety burden, and `notifications_insert_any` is materially permissive for authenticated users.

## Live Functions / RPCs

- `public.process_payment_event_ledger`
  - signature:
    - `p_event_type text`
    - `p_related_entity_type text`
    - `p_related_entity_id uuid`
    - `p_idempotency_key text`
    - `p_amount_gross numeric`
    - `p_currency text`
    - `p_meta jsonb`
  - returns: `jsonb`
  - `security_definer=true`
  - ACL string indicates execute available to `anon`, `authenticated`, and `service_role`
- Other booking-related live functions found:
  - `fn_booking_guard()` -> `trigger`
  - `fn_log_booking_activity()` -> `trigger`, `security_definer=true`
  - `set_booking_completed_at()` -> `trigger`
- No live booking RPCs matching the new remediation names were found.

## Live Edge Functions

- Matching deployed function returned by MCP:
  - `qicard_webhook_handler`
    - status: `ACTIVE`
    - version: `2`
    - `verify_jwt=false`
- No deployed edge functions matching `booking*` or additional `qicard*` names were returned.

## Confirmed Repo-to-Live Drift

1. `bookings.price` is the live amount column on the booking row; there is no live `amount_gross` column on `bookings`.
2. The live booking status enum still contains legacy and expanded states, including `confirmed`, `in_progress`, `completed`, `paid_request_pending`, `active`, `delivered`, `refunded`, and `expired_unanswered`.
3. `slot_id` is nullable in live `bookings`; the app currently masks null with a zero UUID sentinel.
4. Live `notifications_insert_any` allows any authenticated user to insert notifications, which means the current client-side cross-user notification writes are not blocked by RLS.
5. `process_payment_event_ledger` still exposes execute rights broadly and remains the only live booking/payment RPC found.
6. The only live QiCard/booking edge function is `qicard_webhook_handler`; all new remediation edge functions still need to be created.

## Phase 0 Conclusion

Phase 0 is now grounded in live DB reality. The remediation can proceed, but the live baseline confirms that:

- the client-side booking/payment trust boundary is still open
- notification writes are currently too permissive
- amount/status semantics must be normalized at the contract layer before broad app changes
