# FULL REPORT: 21 Wallet System Balances

## 0) Skill Selection

- **Skills selected**: DB-First Financial Modeling, Invariants & Contracts, Idempotency & Concurrency, Threat Modeling (Security), Evidence-First Reading, Diagram Crafting.
- **Why these fit**: This represents the actual math underpinning the app. The Double-Entry Ledger ensures that Escrow holding and Platform Revenue remain perfectly accounted for without balance-drift.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/21_Wallet_System_Escrow_Available_balances`
- **What system/feature it describes**: How user available balances are calculated in UI, and the flow of funds during a Pay-First checkout (Hold -> Work -> Release -> Net).
- **Entities involved**: `ledger_lines`, `journal_entries`, `accounts`, `wallet_balances` (View).

## 2) Human Explanation

To prevent bugs, balances are NEVER stored as fixed numbers. The `wallet_balances` view dynamically calculates the sum of all a user's `ledger_lines`. When a Client pays for a booking, the Ledger debits their available balance and credits the `platform_escrow` account. When the Freelancer delivers the work, the Client approves it. The Ledger then debits the Escrow, credits the Platform's Revenue account for the fee, and credits the Freelancer's Available account for the Net Payout.

## 3) Symbol Legend

- **Rectangles**: Clients, Edge Functions, Ledger RPC.
- **Solid Arrows**: Explicit RPC action paths.
- **Dashed Logic**: Financial ledger movement (DR/CR).

## 4) Extracted Contracts & Invariants

1. **Ledger Parity**: Every created `journal_entry` must ensure its associated `ledger_lines` sum exactly to 0. (Double-entry axiom).
2. **Frozen Wallet Rule**: The legacy `wallet_transactions` table is obsolete and strictly frozen.
3. **Idempotency Requirement**: Every ledger API call requires an explicit UUID/Digest `idempotency_key` (e.g., entity_id + event_type).

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Legacy API references (`process_payment_event`).
- **Resolution**: Codebase enforces `process_payment_event_ledger`.

### 5.2 Logic Drift

- **Conflict**: The original diagram relied heavily on the frozen `wallet_transactions` table.
- **Resolution**: Fully transition the analytical view to aggregate only `ledger_lines` (which provides double-entry protections).

### 5.3 Data Model Drift

- None currently detected in mapping out `views` directly built over the ledger schema.

## 6) Security & Failure Modes (Adversarial)

- **Direct Balance Hacking**: Attacker attempting to `INSERT` fake credits to their account.
  - _Mitigation_: Clients cannot write to `ledger_lines`. The RPC `process_payment_event_ledger` runs as `SECURITY DEFINER` and requires strict payment gateway verification upstream or explicit `is_client` UI validation for internal transfers.
- **Event Replay**: Rapid-clicking the "Release Funds" button.
  - _Mitigation_: `p_idempotency_key` unique constraints on `journal_entries`.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Wallet Screen (`Available Balance`, `Pending Escrow`).
- **States**: Rendering pure sums from the `wallet_balances` View.
- **Guardrails**: No client-side recalculation of net totals. UI solely reflects the DB View.

### 7.2 Admin Dashboard UI

- **Pages**: Platform Reconciliation.
- **Metrics**: Total Platform Escrow vs Total Available Pool to verify platform solvency.

### 7.3 Implementation Hooks

- DB `vw_wallet_balances`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 10/10 (Post-fixes)
- **Best Diagram Type**: Sequence Diagram heavily documenting the DR/CR lines mapping directly over the lifecycle phases (Escrow -> Work -> Release).

## 9) Upgrade Plan

- **Phase 0: Observability**: Ensure `journal_entries.meta` tracks `device_ip` strings for anti-fraud mapping.
- **Phase 1: Contracts**: Finalize the deletion/lockdown of legacy `wallet_transactions` queries in Dart code.
- **Phase 2: Hardening**: Run strict integration tests proving idempotency blocks replay attacks exactly on payment events.
- **Phase 3: Scale**: Add Materialized Views if the `ledger_lines` calculation becomes slow for highly active accounts.

## 10) Risks

### 10.1 Risks if current version kept

- **Legacy Crash**: Legacy system usage guarantees unbalanced books if new features run half-and-half against the v2.16 ledger.

### 10.2 Risks introduced by fixes

- **Long Load Times**: Counting 10,000 ledger rows might delay the Wallet Screen. _Mitigation_: Materialized views refreshed async.

## 11) Test Plan (High-value)

- **Unit (DB)**: Validate `sum(amount) = 0` constraint by trying to pass an unbalanced payload.
- **Security**: As a standard user, attempt `INSERT INTO ledger_lines`. Verify rejection.

## 12) Production Checklist

- [ ] `process_payment_event_ledger` adopted universally.
- [ ] Idempotency keys generated uniquely and reliably.
- [ ] `wallet_balances` accurately reflects only cleared `ledger_lines`.
