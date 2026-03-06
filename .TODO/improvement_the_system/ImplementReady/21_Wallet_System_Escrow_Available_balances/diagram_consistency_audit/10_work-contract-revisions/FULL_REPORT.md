# FULL REPORT: 10 Work Contract Revisions

## 0) Skill Selection

- **Skills selected**: Evidence-First Reading, Invariants & Contracts, State Machine & Lifecycle, Threat Modeling (Security), DB-First Financial Modeling.
- **Why these fit**: Revisions push an entity backward from `delivered` to `active`. Validating state guards prevents malicious clients from trapping escrowed payouts forever in infinite revision loops.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/10_work-contract-revisions`
- **What system/feature it describes**: The iteration loop where a freelancer submits work, and a client requests changes before the escrow is released.
- **Entities involved**: `tasks`, `bookings`, `rpc_submit_delivery`, `rpc_request_revision`.

## 2) Human Explanation

A Freelancer finishes work and calls `rpc_submit_delivery`. The state changes to `delivered`. The Client reviews the work. The Client can either approve (releasing funds) or request a revision. If the Client requests a revision, `rpc_request_revision` runs. It checks if `revisions_used < revisions_total`. If valid, it increments the used counter, resets the state to `active`, and clears the delivery timestamp so the Freelancer can resubmit. If revisions run out, the RPC throws an exception.

## 3) Symbol Legend

- **Rectangles**: Processing actors (Service Layer vs Postgres).
- **Solid Arrows**: Explicit RPC calls (`submit_delivery`, `request_revision`).
- **Dotted Arrows / Alts**: Guard conditions checking state and limits.

## 4) Extracted Contracts & Invariants

1. **Client-Only Revision**: Only the user matching `client_id` can trigger `requestRevision`.
2. **Limit Counter**: A successful revision increases `revisions_used` by 1.
3. **State Rollback**: The task status resets to `active`, unfreezing the delivery lock.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: The `revisions_total` field is sometimes loosely referenced as "unlimited".
- **Resolution**: Use an explicit integer `99` or `NULL` to represent unlimited, properly checked via `COALESCE`.

### 5.2 Logic Drift

- **Conflict**: Old RPC blindly allowed revisions without enforcing the limit inside DB transactions.
- **Resolution**: All limits MUST be checked within the Postgres RPC (`IF t.revisions_used >= t.revisions_total...`).

### 5.3 Data Model Drift

- None detected within the revision variables themselves.

## 6) Security & Failure Modes (Adversarial)

- **Infinite Revision Loop**: Malicious client endlessly hits the revision endpoint, trapping freelancer funds.
  - _Mitigation_: The hard cap variable (`revisions_total`) in the RPC protects against infinite looping.
- **State Bypass**: Revising an already completed or active task.
  - _Mitigation_: The RPC pre-checks `IF status <> 'delivered' THEN RAISE EXCEPTION`.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: "Review Delivery" Modal.
- **States**: Rendering logic checking `remaining_revisions = task.revisions_total - task.revisions_used`.
- **Guardrails**: Hide the "Request Changes" button if `remaining_revisions <= 0`. Show a "Dispute/Support" fallback link instead.

### 7.2 Admin Dashboard UI

- **Pages**: Dispute Resolution.
- **Metrics**: Average revisions requested per task type.
- **Drilldowns**: Check `revisions_used` on disputed tasks to gauge difficulty.

### 7.3 Implementation Hooks

- `WorkManagementService.requestRevision()` -> `rpc('rpc_request_revision')`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10
- **Best Diagram Type**: Sequence Diagram captures the temporal "ping pong" of revisions perfectly.

## 9) Upgrade Plan

- **Phase 0: Observability**: Add basic flutter logs for when a user hits the revision cap.
- **Phase 1: Contracts**: Enforce `revisions_total` limit strictly in Postgres.
- **Phase 2: Hardening**: Add idempotency to `rpc_request_revision` so bad networks don't trigger 2 revisions.
- **Phase 3: Disputes**: Build graceful UI off-ramp to manual dispute resolution if revisions max out.

## 10) Risks

### 10.1 Risks if current version kept

- **Escrow Trapping**: Highly dangerous to allow unlimited iteration without automated boundaries.

### 10.2 Risks introduced by fixes

- **Hard caps**: Strict logic prevents nice clients from asking for one final tiny fix. _Mitigation_: Direct Messaging can facilitate out-of-band updates, or they can use the formal `change_requests` feature.

## 11) Test Plan (High-value)

- **Unit (DB)**: Setup `revisions_used` = 2, `revisions_total` = 2. Run RPC. Assert throws exception.
- **Integration**: Request revision on `active` status task -> assert failure.

## 12) Production Checklist

- [ ] Ensure `rpc_request_revision` safely checks `status = 'delivered'`.
- [ ] UI hides the button when `revisions_used == revisions_total`.
