# Contract: Escrow Idempotency Key (rpc_approve_delivery)

**Plan:** PLAN_EscrowInvariantsIdempotency_2026-03-07_CRITIC  
**Date:** 2026-03-07

## Scope

- **RPC:** `public.rpc_approve_delivery(entity_type text, entity_id uuid)`
- **Branch:** Booking only, when `payment_status = 'held'`. Task branch has no ledger call and no idempotency key.

## Idempotency Key Formula (Stable)

Key must be deterministic for the same entity and releasable state so that retries produce the same key and hit the UNIQUE constraint on `journal_entries.idempotency_key`.

**Formula:**

```sql
encode(
  extensions.digest(
    entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status,
    'sha256'
  ),
  'hex'
)
```

- **Inputs:** `entity_id` (uuid), `v_status` (text), `v_payment_status` (text) — all from the entity row **after** `SELECT ... FOR UPDATE`.
- **Must NOT include:** `now()` or any time-based value.

## Serialization

- **FOR UPDATE:** Before generating the key and calling `process_payment_event_ledger`, the booking row must be locked:  
  `SELECT id, status, payment_status, client_id, provider_id, price FROM bookings WHERE id = entity_id FOR UPDATE;`
- Use the locked row values for auth checks and key generation.

## Replay Behavior

- On idempotent key collision, `process_payment_event_ledger` returns existing journal id (ok: true) and does not raise. `rpc_approve_delivery` must not re-raise; app sees success on retry.
