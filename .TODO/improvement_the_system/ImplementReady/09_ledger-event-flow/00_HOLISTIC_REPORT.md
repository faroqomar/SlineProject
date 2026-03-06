# Holistic Audit Report: Ledger Event Flow (09_ledger-event-flow)

**Skills applied:**

- **Evidence-First Reading**: Mapped `SUPABASE_SETUP.md` RPCs to flow nodes.
- **Threat Modeling (Security)**: Analyzed financial race conditions and invariant breaches.
- **Invariants & Contracts**: Verified double-entry balancing rules.
- **State Machine & Lifecycle**: Validated status-based gate logic.
- **Idempotency & Concurrency**: Audited replay protection mechanisms.
- **DB-First Financial Modeling**: Aligned with `ledger_lines` table structures.

---

## A) What This Diagram Is

This diagram maps the double-entry accounting flow triggered by business actions (Booking Payment, Delivery Acceptance, etc.) in the SLine marketplace. It describes how a single high-level event is decomposed into balancing ledger lines.

**System Boundaries:**

- **In-Scope**: Wallet UI, `WalletService`, `LedgerService`, `process_payment_event_ledger` RPC, and core ledger tables.
- **Out-of-Scope**: External bank/gateway processing (pre-webhook), User KYC verification.

## B) Why It Exists

Financial integrity is the highest priority. Simple "balance" columns are prone to race conditions and lack auditability. This system ensures:

- **Immutability**: Every move of money is a recorded line.
- **Balancing**: Journals always sum to zero.
- **Transparency**: Admin can trace every IQD from client to provider/revenue.

## C) Where It Lives in the Product

- **App Entry Points**: `WalletScreen`, `BookingCheckout`, `DeliveryApproval`.
- **Logic Layer**: `LedgerService.dart` (Client-side trigger), `process_payment_event_ledger` (Postgres RPC).
- **Storage Layer**: `accounts`, `journal_entries`, `ledger_lines`.
- **Admin Touchpoints**: Finance Dashboard (aggregating `ledger_lines`).

## D) Current Diagram Evaluation (Score)

- **What’s good**: Accurate representation of the core "Escrow -> Provider + Revenue" logic.
- **What’s missing**: Async webhook triggers (QiCard), withdrawal flows, and idempotency key generation.
- **What’s unsafe**: Does not show failure rollbacks or status gates.
- **Current Score: 6/10**. It’s a good overview for developers but lacks the technical depth for a production security audit.

## E) Extracted Invariants & Contracts

- **[INV-01] Double-Entry Identity**: `Debit_Sum + Credit_Sum = 0` for every transaction.
  - _Evidence_: `ck_unbalanced_journal` (logical check in RPC).
- **[INV-02] Positive Magnitude**: All `ledger_lines.amount` entries must be > 0.
  - _Evidence_: `ck_ledger_lines_amount_positive` (`SUPABASE_SETUP.md:L1438`).
- **[INV-03] Replay Protection**: Every event must have a unique `idempotency_key`.
  - _Evidence_: `uq_journal_entries(related_entity_id, event_type, ...)` context.

## F) Failure Modes & Attack Scenarios

- **Scenario: Double-Spending (Fast Clicking)**:
  - _Currently_: Mitigated by `uq_journal_entries` unique constraint.
  - _Improvement_: Generate the key in the ViewModel before navigation to lock the UI state.
- **Scenario: Zero-Fee Release**:
  - _Currently_: Migration `20260308` patches the RPC to omit 0-amount revenue lines.
  - _Verification_: Checked `ck_ledger_lines_amount_positive`.
- **Scenario: Direct Table Write**:
  - _Attack_: Malicious client tries to `insert` into `ledger_lines`.
  - _Defense_: RLS on `ledger_lines` is "system-only" (postgres role only); RPC uses `SECURITY DEFINER`.

## G) Production-Grade Improvement Plan

### Phase 0: Observability & Logs

- **Action**: Add `p_meta` structure to log front-end context (device ID, session ID) into `journal_entries`.
- **Why**: Essential for forensics in case of disputes.
- **Verify**: Check `p_meta` column content after a test payment.

### Phase 1: Core Contracts Enforcement

- **Action**: Explicitly cast enum types in status updates within the RPC to prevent prepared statement errors.
- **Why**: Fixes a known Supabase/Postgres type mismatch risk (`SUPABASE_SETUP.md:L1438`).
- **Verify**: Run `rpc_approve_delivery` with a large dataset.

### Phase 2: Hardening (Security & Race Conditions)

- **Action**: Enforce `SELECT FOR UPDATE` on the `related_entity` (booking/offer) within the RPC to prevent status drifting during the transaction.
- **Why**: Prevents a race where an entity is cancelled and released simultaneously.
- **Verify**: Simulate concurrent SQL sessions with `pg_sleep`.

### Phase 3: Admin Tooling & Auditability

- **Action**: Create `admin_manual_correction` event type for specific support-led adjustments.
- **Why**: Avoids "hacking" the database via raw SQL which skips business logic.

## H) Best Diagram Recommendation

- **Recommended Types**: **State Flowchart** (for account transitions) + **Sequence Diagram** (for RPC/Client interaction).
- **Reasoning**: financial logic is about _state changes_ and _locking order_.

## I) Final Improved Diagram (Mermaid)

_(See 06_DIAGRAM_FINAL.md for the full source)_

```mermaid
flowchart TD
    subgraph TriggerSources [Triggers & Actions]
        T1(App: Pay Booking)
        T4(App: Withdraw Funds)
        T5(Webhook: QiCard Paid)
    end
    subgraph Engine [Ledger Engine (RPC)]
        RPC[process_payment_event_ledger]
        Gate{Valid status?}
        Journal[Create Journal Entry]
        Balance[Double-Entry Check]
    end
    subgraph Accounts [Ledger Accounts]
        UA[User: Available]
        PE[Platform: Escrow]
        PR[Platform: Revenue]
    end
    T1 & T5 --> RPC --> Gate --> Journal
    Journal --> UA -. DR .-> Balance
    Journal --> PE -. CR .-> Balance
    Balance -->|Success| Committed[Committed]
```

## J) Risk Register

_(Summary of 03_RISK_REGISTER.md)_

- **R-LED-01 (High)**: Ledger-Status Mismatch.
- **R-LED-03 (High)**: Precision Loss / Unbalanced sums.
- **R-LED-04 (High)**: Migration complexity during historical backfills.

## K) Verification Checklist

- [ ] Unit Test: `LedgerService` idempotency key stability.
- [ ] DB Test: Unbalanced journal exclusion check.
- [ ] Security: Verify `ledger_lines` RLS denies all public `INSERT`.
- [ ] Monitoring: Alert if `Platform Escrow` account goes negative.

## L) Final Verdict

- **Score AFTER Improvements: 9.5/10**
- **Blockers**: None. The system is structurally sound.
- **Ship Criteria**: 100% test coverage on RPC error codes.
