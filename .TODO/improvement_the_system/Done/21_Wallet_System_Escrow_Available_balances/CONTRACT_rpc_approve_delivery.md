# CONTRACT: rpc_approve_delivery

**Status:** Active  
**Last Updated:** 2026-03-07  
**Owner:** @APIContract  
**Plan:** PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC

---

## Overview

Client approves delivered work and releases escrow (when payment_status = held). Single RPC for **booking**, **task**, and **direct_offer**. Idempotency is enforced by deterministic key (no `now()`).

---

## RPC: rpc_approve_delivery

### Request (Flutter → Supabase)

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `entity_type` | text | Yes | One of: `task`, `booking`, `direct_offer`. |
| `entity_id` | uuid | Yes | ID of the task, booking, or direct_offer. |

**Example (booking):** `{ "entity_type": "booking", "entity_id": "<uuid>" }`  
**Example (direct_offer):** `{ "entity_type": "direct_offer", "entity_id": "<uuid>" }`

### Authorization (enforced in RPC)

- **task:** `auth.uid() = tasks.owner_id` (client). Entity must be `delivered`.
- **booking:** `auth.uid() = bookings.client_id`. Entity must be `delivered`; if `payment_status = 'held'`, ledger release is called.
- **direct_offer:** `auth.uid() = direct_offers.client_id`. Entity must be `delivered` and `payment_status = 'held'`.

### Idempotency

- Key is computed inside RPC from `entity_id`, `v_status`, `v_payment_status` (and for direct_offer equivalent). **No `now()`.** Duplicate calls for the same entity in the same state produce one ledger entry (UNIQUE on `journal_entries.idempotency_key`).

### Response

- **Success:** RPC returns void (no error).
- **Error:** Exception (e.g. `Not authorized`, `Work not delivered`, `Invalid entity type`, `Ledger release failed: ...`).

### Canonical views (read-only for wallet UI)

- Balance: `vw_wallet_balances_user`
- Activity: `vw_wallet_activity_user`

---

## References

- `Sline_everything/SUPABASE_SETUP.md` (rpc_approve_delivery, process_payment_event_ledger)
- `.TODO/improvement_the_system/ImplementReady/09_ledger-event-flow/CONTRACT_ledger_event_flow.md`
- `lib/features/work/services/work_management_service.dart` (approveDelivery)
- `lib/features/direct_offers/services/direct_offers_service.dart` (completeOffer — to call RPC for direct_offer)
