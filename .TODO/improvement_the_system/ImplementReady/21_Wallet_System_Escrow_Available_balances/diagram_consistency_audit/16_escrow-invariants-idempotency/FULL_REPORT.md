# FULL REPORT: 16 Escrow Invariants & Idempotency

## 0) Skill Selection

- **Skills selected**: Evidence-First Reading, Threat Modeling (Security), Invariants & Contracts, Idempotency & Concurrency, Diagram Crafting, DB-First Financial Modeling.
- **Why these fit**: The prevention of race conditions ("double release") during financial transactions is paramount. Assessing the idempotency constraint correctly prevents massive financial bleeding.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/16_escrow-invariants-idempotency`
- **What system/feature it describes**: The exact mechanism that ensures `rpc_approve_delivery` (Escrow Release) can never inadvertently run twice for the same entity, even under heavy network retries.
- **Entities involved**: `rpc_approve_delivery`, `process_payment_event_ledger`, `journal_entries.idempotency_key`.

## 2) Human Explanation

When a client hits "Approve Delivery", the app sends a request to release escrow funds. If the network drops, the app might retry. To prevent double-paying the freelancer, the database assigns a unique `idempotency_key` to each event (`entity_id + source_status`). When the transaction hits the Ledger, it attempts to `INSERT INTO journal_entries`. If it's a retry, the Postgres `UNIQUE` constraint catches the duplicate key and gracefully ignores it. Crucially, a `SELECT FOR UPDATE` locks the task row during processing so two parallel requests don't slip past each other.

## 3) Symbol Legend

- **Rectangles**: RPC functions vs Database Constraints.
- **Solid Arrows**: Main execution line.
- **Dashed Alts**: Conflict rejections ("Safe Idempotent Replay").

## 4) Extracted Contracts & Invariants

1. **Stable Key Contract**: The `idempotency_key` cannot include `now()`. It must be stable for retries (`digest(entity_id || status)`).
2. **Serialization**: `SELECT ... FOR UPDATE` must serialize concurrent calls trying to release the same underlying task lock.
3. **Escrow State**: Release can only occur if the underlying entity `payment_status` is explicitly `'held'`.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Vague reference to how keys were generated.
- **Resolution**: Solidify `extensions.digest` based hashing using explicitly identified variables.

### 5.2 Logic Drift

- **Conflict**: The most critical flaw. Previous implementations used `now()` in the payload for the idempotency key, generating a brand new key on every retry, destroying the idempotent protection.
- **Resolution**: Remove all temporal elements from hash digests in Ledger RPCs.

### 5.3 Data Model Drift

- None detected. The key generation logic itself was the issue.

## 6) Security & Failure Modes (Adversarial)

- **Rapid Double-Tap (Parallel Race)**: Client presses the exact same button twice resulting in two requests processed at the exact same millisecond.
  - _Mitigation_: The `FOR UPDATE` lock forces request B to wait for request A. When B executes, it sees `payment_status = released` and aborts safely as a No-Op.
- **Network Cut-Off Retry**: Client's connection drops after Server creates Key A. App retries.
  - _Mitigation_: Server computes identical Key A without Time variables. `UNIQUE` constraint gracefully rejects it but returns success to the client (who just wanted to know it was done).

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: "Approve Delivery" button, "Release Funds".
- **States**: Rendering loading spinners, explicitly handling standard `200` vs `409` conflict responses from PostgREST identically if idempotent.
- **Guardrails**: Disable button locally while request operates.

### 7.2 Admin Dashboard UI

- **Pages**: Financial reconciliation.
- **Metrics**: Count of idempotency collisions (to track potential scraping or attack vectors).

### 7.3 Implementation Hooks

- `WorkManagementService` calling standard RPCs.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 10/10 (Post-fixes)
- **Best Diagram Type**: Sequence Diagram mixed with State Logic tracking the exact Postgres Lock mechanisms.

## 9) Upgrade Plan

- **Phase 0: Observability**: Track `Rpc Exception` alerts explicitly for `payment_status` mismatches.
- **Phase 1: Contracts**: Strip `now()` from all Ledger event RPC hash generators.
- **Phase 2: Hardening**: Run `SELECT status FOR UPDATE` as the very first line inside `rpc_approve_delivery`.
- **Phase 3: Scale**: Ensure `idempotency_key` has a fast B-Tree index on `journal_entries` for `ON CONFLICT` speeds.

## 10) Risks

### 10.1 Risks if current version kept

- **Total Financial Ruin**: "Idempotent" keys using `now()` guarantee that double-spending occurs on retry.

### 10.2 Risks introduced by fixes

- **Lock Deadlock**: `FOR UPDATE` can slow DB threads if transactions take too long. _Mitigation_: Ensure the RPC executes instantly, without massive sub-queries.

## 11) Test Plan (High-value)

- **Concurrency / Unit**: Programmatically fire two `rpc_approve_delivery` calls for the exact same `task_id` essentially simultaneously in Postgres. Assert only 1 Ledger event generated.
- **Integration**: Send a request string with a pre-computed stable key twice to verify exact identical payload generates a safe "No-op" success.

## 12) Production Checklist

- [ ] No `now()` or random elements in `v_key` generation for Ledger.
- [ ] `FOR UPDATE` serialization on specific task locked inside transaction.
- [ ] PostgREST mapping handles rejections correctly instead of throwing scary errors to the UI.
