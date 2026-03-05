# Contract — Bookin Payment — 2026-02-28

- Basis: live Supabase baseline from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/BookinExecution/LIVE_DB_BASELINE_2026-02-28.md`
- Scope: Bookin remediation only

## Canonical Booking Row Shape

All booking list/detail/refresh paths should consume one row shape:

- `id`
- `task_id`
- `provider_id`
- `client_id`
- `slot_id` nullable
- `status`
- `payment_status`
- `note`
- `price`
- `package_id`
- `requirements`
- `created_at`
- `completed_at`
- `availability_slots(starts_at)`
- `tasks(*)`

## Canonical Amount

- Live booking amount field: `bookings.price`
- Ledger mapping: `price -> p_amount_gross`
- Decision:
  - App-facing amount remains `price`
  - Server-side payment and ledger code maps `price` into `p_amount_gross`

## Booking Status Contract

- Live enum is broader than the original doc contract.
- Remediation release preserves live DB values to avoid destructive enum churn.

Authoritative meanings used by the server-backed flow:

- `pending`: draft exists, payment not yet held
- `paid_request_pending`: payment held, waiting for provider action
- `active`: provider accepted and workflow is active
- `delivered`: provider marked delivered
- `completed`: funds released / workflow closed
- `canceled`: canceled before held funds were returned
- `refunded`: held funds were returned
- `expired_unanswered`: timed out / unrecovered terminal draft

Inference:
- Live `confirmed` and `in_progress` are treated as legacy/compatibility states for this remediation.

## Correlation IDs

- Create: `booking:<booking_id>:create`
- Recover: `booking:<booking_id>:recover`
- Refund: `booking:<booking_id>:refund`

## Edge Function Contracts

### `qicard_payment_create`

- Auth: required
- Input:
  - `task_id`
  - `slot_id`
  - `note`
  - `package_id`
  - `requirements`
- Output:
  - `booking_id`
  - `payment_request_id`
  - `form_url`
  - `amount`
  - `provider_id`
  - `expires_at`
  - `correlation_id`

### `qicard_payment_recovery`

- Auth: required
- Input:
  - `booking_id`
- Output:
  - `booking_id`
  - `booking_status`
  - `payment_status`
  - `recovery_result`
  - `correlation_id`

### `booking_decline_refund`

- Auth: required
- Input:
  - `booking_id`
  - `reason`
- Output:
  - `booking_id`
  - `booking_status`
  - `payment_status`
  - `refund_result`
  - `correlation_id`

## RPC Contracts

### `rpc_create_booking_draft_validated`

- Auth context: `auth.uid()` required
- Input:
  - `p_task_id uuid`
  - `p_slot_id uuid`
  - `p_note text`
  - `p_package_id text`
  - `p_requirements jsonb`
- Output:
  - one canonical `bookings` row
- Validation:
  - slot exists
  - slot is not blocked
  - task exists
  - task is `booking`
  - task owner matches slot provider
  - no non-terminal booking already occupies the slot
  - price is derived from task package or task budget

### `rpc_finalize_booking_refund`

- Input:
  - `p_booking_id uuid`
  - `p_reason text`
  - `p_correlation_id text`
- Output:
  - one canonical `bookings` row
- Effect:
  - terminal `refunded` booking state
  - terminal `refunded` payment state

## Webhook Contract

- Accepted only with a valid signature unless explicit local-dev override is enabled
- Booking hold idempotency key:
  - `qicard:<payment_id>:gateway_escrow:SUCCESS`
- Successful hold side effects:
  - ledger hold via `process_payment_event_ledger`
  - booking promotion from `pending` to `paid_request_pending`
  - audit insert
