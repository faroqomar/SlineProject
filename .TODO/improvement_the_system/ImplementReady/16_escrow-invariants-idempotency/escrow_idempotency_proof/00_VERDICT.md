# VERDICT: Escrow Idempotency Verification

> **Date**: 2026-03-06  
> **Auditor**: SLine Escrow Idempotency Verifier (One-Shot)  
> **Scope**: `rpc_approve_delivery` → `process_payment_event_ledger` → `journal_entries` + `ledger_lines`

---

## OLD vs NEW Score

> The "OLD" system is the **current production code** (what's deployed now).  
> The "NEW" system is the **design proposed in the previous audit** (`16_escrow-invariants-idempotency` improvement folder).

| Criterion                       | OLD (Current) | NEW (Proposed) | Evidence                                                                                            |
| ------------------------------- | :-----------: | :------------: | --------------------------------------------------------------------------------------------------- |
| **Idempotency key stability**   |    🔴 2/10    |    ✅ 9/10     | OLD uses `now()` in key; NEW proposes stable key from status                                        |
| **FOR UPDATE locking**          |    ✅ 8/10    |    ✅ 9/10     | OLD has `FOR UPDATE` inside `process_payment_event_ledger`; NEW proposes adding it in outer RPC too |
| **Status gate enforcement**     |    ✅ 9/10    |    ✅ 9/10     | Both enforce `status='delivered' AND payment_status='held'`                                         |
| **UNIQUE constraint on key**    |   ✅ 10/10    |    ✅ 10/10    | Live DB constraint verified                                                                         |
| **EXCEPTION handler for races** |    ✅ 9/10    |    ✅ 9/10     | `unique_violation → safe no-op` proven                                                              |
| **Double-entry balance**        |    ✅ 9/10    |    ✅ 9/10     | Lines use `WHERE amount > 0` to skip 0-fee                                                          |
| **Audit logging**               |    ✅ 9/10    |    ✅ 9/10     | `audit_logs` INSERT on every release                                                                |
| **UI double-tap protection**    |    🟡 6/10    |    ✅ 8/10     | OLD uses `isLoading` state; NEW proposes one-shot guard                                             |
| **Admin observability**         |    🔴 2/10    |    🟡 5/10     | No admin dashboard exists; NEW recommends queries                                                   |
| **Fee correctness**             |    🟡 5/10    |    🟡 5/10     | `fee_rate_bps = 0` — neither system addresses this                                                  |
| **Overall**                     |  **6.5/10**   |   **8.5/10**   |                                                                                                     |

---

## Is NEW Truly Safer?

### ✅ YES — but with an important caveat

The previous audit correctly identified the `now()` key as a design flaw. However, **the current system is NOT vulnerable to double-release** due to three independent defense layers:

1. **`FOR UPDATE` inside `process_payment_event_ledger`** — serializes concurrent calls
2. **Status gate (`delivered` + `held`)** inside the ledger function — blocks after first success
3. **Outer RPC status check** (`status != 'delivered'`) — catches sequential retries

The NEW design would make the idempotency key **actually work as designed**, which is the correct thing to do. But it's not a **production blocker** — it's a **correctness improvement**.

---

## Production Blockers

| #   | Issue        | Severity | Status |
| --- | ------------ | -------- | ------ |
| —   | _None found_ | —        | —      |

There are **zero production blockers**. The system is safe for production use today.

---

## Recommended Improvements (Not Blockers)

| Priority | Issue                       | Fix                                                         | Effort            |
| -------- | --------------------------- | ----------------------------------------------------------- | ----------------- |
| 🟡 P2    | `now()` in idempotency key  | Replace with stable key (`entity_id:status:payment_status`) | 10 min SQL patch  |
| 🟡 P2    | `fee_rate_bps = 0` override | Confirm if intentional; if not, remove override             | Business decision |
| 🟢 P3    | Duplicate UNIQUE index      | `DROP INDEX idx_journal_entries_idempotency`                | 1 min             |
| 🟢 P3    | UI one-shot guard           | Add `_hasApproved` flag in `ReviewDeliveryModal`            | 5 min Dart patch  |
| 🟢 P3    | No admin dashboard          | Build escrow monitor + double-release detector              | ~2-4 hours        |

---

## Invariants Verification Summary

| Invariant                                                        | Enforced? | Where                                                        | Evidence            |
| ---------------------------------------------------------------- | --------- | ------------------------------------------------------------ | ------------------- |
| Release only if `status='delivered' AND payment_status='held'`   | ✅ Yes    | `process_payment_event_ledger` §5.2 + `rpc_approve_delivery` | Live SQL            |
| After success: `payment_status='released'`, `status='completed'` | ✅ Yes    | `process_payment_event_ledger` §5.2                          | Live SQL            |
| Ledger lines balance to 0 (double-entry)                         | ✅ Yes    | DEBIT escrow = CREDIT provider + CREDIT revenue              | Live SQL            |
| Only client can approve                                          | ✅ Yes    | `v_client_id != v_uid → raise exception`                     | Live SQL            |
| Rapid double-tap → single release                                | ✅ Yes    | `FOR UPDATE` + status gate + `isLoading` UI guard            | Live SQL + app code |
| Network retry → safe no-op                                       | ✅ Yes    | Status changes to `completed` → outer RPC blocks retry       | Live SQL            |
| Replay after completion → blocked                                | ✅ Yes    | `status != 'delivered'` in outer RPC                         | Live SQL            |

---

## Threat Model Summary

| Threat                                    | Outcome                                                           | Guard                               |
| ----------------------------------------- | ----------------------------------------------------------------- | ----------------------------------- |
| Retry spam from app                       | Blocked after first success (status gate)                         | `rpc_approve_delivery` status check |
| Concurrency race (two simultaneous calls) | Second call blocked by `FOR UPDATE`, then rejected by status gate | `process_payment_event_ledger` §5.2 |
| Replay after completion                   | Blocked: `status != 'delivered'`                                  | `rpc_approve_delivery`              |
| Mismatched `entity_type`/`entity_id`      | Returns error (entity NOT FOUND or wrong type)                    | Both RPCs validate                  |
| Freelancer attempts to approve            | `v_client_id != v_uid` → `RAISE EXCEPTION 'Not authorized'`       | `rpc_approve_delivery`              |
| Direct API call bypassing UI              | Backend enforces ALL guards regardless of UI                      | All guards are server-side          |

---

## Deliverables

| File                                                                                                                                                 | Purpose                                      |
| ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------- |
| [01_EVIDENCE_MAP.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/escrow_idempotency_proof/01_EVIDENCE_MAP.md)                         | Code paths, DB objects, constraint proofs    |
| [02_IDEMPOTENCY_PROOF.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/escrow_idempotency_proof/02_IDEMPOTENCY_PROOF.md)               | Key stability proof, UNIQUE constraint proof |
| [03_CONCURRENCY_PROOF.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/escrow_idempotency_proof/03_CONCURRENCY_PROOF.md)               | FOR UPDATE proof, parallel-call trace        |
| [04_RISK_REGISTER.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/escrow_idempotency_proof/04_RISK_REGISTER.md)                       | Current + introduced risks                   |
| [05_UI_SURFACES_AND_WIRING.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/escrow_idempotency_proof/05_UI_SURFACES_AND_WIRING.md)     | App + admin surface mapping                  |
| [06_UI_SCREENSHOTS_CHECKLIST.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/escrow_idempotency_proof/06_UI_SCREENSHOTS_CHECKLIST.md) | Visual proof checklist                       |
| [07_MINIMAL_PATCH_PLAN.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/escrow_idempotency_proof/07_MINIMAL_PATCH_PLAN.md)             | Non-urgent fixes                             |
