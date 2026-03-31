# FULL REPORT: 14 Dispute Lifecycle

## 0) Skill Selection

- **Skills selected**: Evidence-First Reading, State Machine & Lifecycle, Threat Modeling (Security), RLS & Privilege Boundaries, DB-First Financial Modeling, Diagram Crafting.
- **Why these fit**: Disputes are a critical state machine (open -> active -> resolved) intervening directly with the Escrow Ledger. Evidence reading verifies schema logic alignment. RLS ensures privacy during arbitration.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/14_dispute-lifecycle`
- **What system/feature it describes**: The escalation path when a Client and Freelancer disagree on delivered work, placing funds in a locked state until Support arbitrates.
- **Entities involved**: `disputes`, `dispute_evidence`, `tasks` (locked state), Ledger (`process_payment_event_ledger`).

## 2) Human Explanation

When a disagreement occurs, either user can click "Dispute". This fires an `INSERT` into `disputes` marking it as `open`. A database trigger immediately locks the associated `task`, preventing completion or payment release. Admins claim the dispute, changing it to `active`. Evidence is uploaded to `dispute_evidence` storage (sandboxed by RLS). Eventually, an Admin executes a Ledger RPC, forcing a refund or partial release. This marks the dispute `resolved` and releases the task lock.

## 3) Symbol Legend

- **Rectangles**: Application states vs Database Enforcements vs Admin Actions.
- **Solid Arrows**: State transitions (`open` -> `active` -> `resolved`).
- **Dashed Logic**: Trigger locks on underlying financial entities.

## 4) Extracted Contracts & Invariants

1. **Task Lock Invariant**: `rpc_approve_delivery` MUST fail if a related `disputes` row is `status = 'open'` or `'active'`.
2. **State Progression**: `status` MUST strictly transition from 'open' -> 'active' -> 'resolved'.
3. **Complainant Match**: `complainant_id` MUST be the `auth.uid()` that triggers the insertion.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Status values were plain-text strings causing typos.
- **Resolution**: Implement `dispute_status_enum`.

### 5.2 Logic Drift

- **Conflict**: The "Cancel/Withdraw" path generated no records or just deleted the row.
- **Resolution**: Add a `canceled` status to natively handle withdrawn disputes without losing analytical history.

### 5.3 Data Model Drift

- **Conflict**: Original diagram omitted the actual locking mechanics preventing Escrow Bypass.
- **Resolution**: Documented `trg_dispute_guard` explicitly.

## 6) Security & Failure Modes (Adversarial)

- **Escrow Bypass (Race)**: Client disputes, then immediately calls `rpc_approve_delivery` before the admin sees it, trapping the system in a split brain.
  - _Mitigation_: The `rpc_approve_delivery` SQL must explicitly `SELECT status from disputes` before committing release.
- **Evidence Tampering**: User B deletes User A's evidence attachment.
  - _Mitigation_: `dispute_evidence` storage bucket strictly enforces RLS `auth.uid() = owner_id` for DELETE operations.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Safety/Help Center, "Report a Problem" Modal on Task Detail.
- **States**: When task is disputed, hide all standard CTA buttons ("Review", "Re-Submit"), show "Under Investigation" banner.
- **Guardrails**: Complainant can click "Withdraw Dispute" only if `status == 'open'`.

### 7.2 Admin Dashboard UI

- **Pages**: Dispute Arbitration Queue.
- **Metrics**: Time-to-resolution, Volume of disputes per task category.
- **Drilldowns**: Deep links into the specific Task, Chat logs, and `dispute_evidence` files.

### 7.3 Implementation Hooks

- `DisputeService.submitDispute(taskId, reason)`.
- `DisputeService.withdrawDispute(disputeId)`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10
- **Best Diagram Type**: State Diagram + Sequence Logic (for Escrow resolution).

## 9) Upgrade Plan

- **Phase 0: Observability**: Add `assigned_admin_id` column to easily trace workload.
- **Phase 1: Contracts**: Enforce the `dispute_status_enum` migration.
- **Phase 2: Hardening**: Deploy the `trg_dispute_guard` on the `tasks` table blocking status transitions while disputed.
- **Phase 3: Privacy**: Ensure Admin resolution logs are protected and non-editable.

## 10) Risks

### 10.1 Risks if current version kept

- **Financial Risk**: Escrow race conditions if a task isn't rigorously locked.

### 10.2 Risks introduced by fixes

- **Deadlock**: If an Admin forgets to resolve a dispute in the DB after refunding in QiCard, the task remains permanently locked. _Mitigation_: Admin Panel alerts for "stale" active disputes > 14 days.

## 11) Test Plan (High-value)

- **Unit (DB)**: Create open dispute -> Attempt `rpc_approve_delivery` -> Assert exception thrown.
- **Integration**: `submitDispute()` inserts `open` status with correct complainant ID.
- **Security**: As a standard user, attempt to `UPDATE disputes SET status = 'resolved'` -> Assert RLS rejection.

## 12) Production Checklist

- [ ] Task locking trigger is installed.
- [ ] `dispute_status_enum` deployed.
- [ ] Support dashboard maps states accurately.
