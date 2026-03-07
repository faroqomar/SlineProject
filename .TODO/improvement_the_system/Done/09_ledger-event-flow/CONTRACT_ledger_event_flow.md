# CONTRACT: Ledger Event Flow (09_ledger-event-flow)

**Status:** Active  
**Last Updated:** 2026-03-07  
**Owner:** Backend + Mobile; @APIContract

---

## Overview

This contract defines the integration between the Flutter app and the double-entry ledger RPC `process_payment_event_ledger`. It covers parameters, `p_meta` forensics keys for dispute and audit, and the decision to scope out `admin_adjustment` (enum present; RPC branch not implemented for this phase).

---

## RPC: process_payment_event_ledger

Creates journal entries and ledger lines for a single business event. All writes go through this RPC; direct INSERT into `ledger_lines` or `journal_entries` is forbidden by RLS for authenticated users.

### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_event_type` | text (enum) | Yes | One of: escrow_hold, release_with_fee, refund, withdrawal_request, deposit, withdrawal_complete, withdrawal_failed, gateway_escrow. (admin_adjustment scoped out.) |
| `p_related_entity_type` | text (enum) | Yes | booking, task_request, withdrawal_request, direct_offer, etc. |
| `p_related_entity_id` | uuid | Yes | ID of the related entity. |
| `p_idempotency_key` | text | Yes | Deterministic key (e.g. UUIDv5 from entity_id + event_type). Must be unique per (entity, event). |
| `p_amount_gross` | numeric | Yes | Amount in IQD. |
| `p_currency` | text | Yes | Must be `IQD`. |
| `p_meta` | jsonb | No (default `{}`) | Optional metadata merged into `journal_entries.meta`. Must include forensics keys when called from the app. |

### p_meta Forensics (Required from App)

For every call from the Flutter app, `p_meta` must include at least one of the following so that `journal_entries.meta` can be used for dispute forensics:

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `session_id` | string | Yes (one of) | Stable identifier for the session (e.g. auth user id or session token id). Used for correlation. |
| `request_id` | string | Optional | Per-request correlation id (e.g. UUID) for this call. |
| `device_id` | string | Optional | Device or install identifier if available; not required on all platforms. |

**Enforcement:** The app layer (LedgerService or a single forensics source) must inject at least `session_id` (or equivalent) into `p_meta` before calling the RPC. The RPC stores the merged meta in `journal_entries.meta`.

### Success Response (jsonb)

```json
{
  "ok": true,
  "journal_entry_id": "uuid",
  "meta": { ... }
}
```

### Error Response (ok: false)

```json
{
  "ok": false,
  "error": {
    "code": "ERR_*",
    "message": "Human-readable message"
  }
}
```

**Error codes:** ERR_GATE_NOT_ALLOWED, ERR_ENTITY_NOT_FOUND, ERR_MISSING_IDEMPOTENCY_KEY, ERR_IDEMPOTENCY_REPLAY, ERR_AMOUNT_MISMATCH, ERR_CURRENCY_MISMATCH, ERR_INSUFFICIENT_FUNDS, ERR_UNBALANCED_JOURNAL, ERR_WITHDRAWAL_AMOUNT_INVALID.

---

## admin_adjustment (Scoped Out)

- **Enum:** `payment_event_type_enum` includes `admin_adjustment` in the database.
- **RPC branch:** Not implemented in this phase. No client or authenticated user may call the RPC with `p_event_type = 'admin_adjustment'` until a dedicated migration and contract (caller role = service_role only, required meta, idempotency) are added.
- **Documentation:** DEVELOPER_GUIDE and Wallet_Feature will state that admin-led adjustments are out of scope for the current release; manual corrections are not exposed via the app.

---

## Withdrawal Flow (Two-Phase)

- **Decision:** Two-phase: (1) Insert `withdrawal_requests` row, (2) Call `process_payment_event_ledger('withdrawal_request', ...)`. If the ledger call fails, the app marks the withdrawal request as `failed` and logs. Orphaned rows (status = `requested` with no ledger entry) are documented in the runbook with an optional detection query.

---

## Idempotency

- **Key generation:** Deterministic UUIDv5 from (entity_id, event_type) in LedgerService (namespace + string `entityId_eventType`).
- **Replay:** Duplicate key results in RPC returning success (replay) or ERR_IDEMPOTENCY_REPLAY; no duplicate journal lines.

---

## References

- `Sline_everything/SUPABASE_SETUP.md` (ledger tables, RPC, enums)
- `lib/features/wallet/services/ledger_service.dart`
- `.TODO/improvement_the_system/ImplementReady/09_ledger-event-flow/06_DIAGRAM_FINAL.md`, `03_RISK_REGISTER.md`
