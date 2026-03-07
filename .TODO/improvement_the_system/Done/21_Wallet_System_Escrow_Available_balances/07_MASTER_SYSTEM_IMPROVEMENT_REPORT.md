# Master System Improvement Report

Date: 2026-03-07

## A) System-wide Architecture Verdict

The SLine application possesses an exceptionally strong and secure double-entry ledger foundation. The backend successfully decouples gross balances from raw transaction lists, providing a mathematically sound single-source-of-truth.
**Current Systemic Risks Identified**:

1. **Frontend Calculation Drift**: The UI layer attempts to calculate total balances locally instead of treating the `WalletViewModel` as an absolute mathematical oracle, leading to UI/Data inconsistencies.
2. **Taxonomy Misalignment**: Transaction labeling incorrectly maps neutral escrow events to "Money Spent", directly harming user trust.
3. **Ghost Balances**: Valid ledger states (Pending withdrawals, Held escrow) lack explicit frontend rendering arrays, creating invisible money pits.

## B) The "Golden Path" (Single Source of Truth Flow)

All financial motions (Booking payments, Tender/Task payments, Direct chat offers) strictly follow this non-negotiable path:

1. `payment_intents` records the desire to move funds.
2. `payment_events` captures the webhook / authorization lock.
3. `process_payment_event_ledger()` acts as the single execution chokepoint.
4. `journal_entries` and `ledger_lines` immutably map the Debits and Credits.
5. Aggregation views (`vw_wallet_balances_user`) stream the net sum to the `WalletViewModel`.
6. The UI blindly renders the View, performing ZERO local summation.

## C) Unified Data Model Proposal

_This model is currently implemented safely. No schema breakage is recommended._

- **Required Columns**: Enforced universally. `amount` limits checked via constraints (`>0`); `account_type` defined strictly inside Enums.
- **Indexes**: `ix_ledger_lines_account_currency` exists and is highly optimized.
- **RLS Principles**: `security_invoker` views strictly enforce `auth.uid() = user_id`, guaranteeing cross-tenant data leakage is structurally impossible.
- **Append-Only Policy**: `journal_entries` are IMMUTABLE. Updates/Deletes are blocked via DB triggers. Corrections require compensatory reverse-ledger entries.

## D) Migration Plan

_No database downtime or destructive migrations are necessary for the UI integration phase._

- **Safe Rollout**: Push patches to `wallet_tab.dart` and `wallet_snapshot_card.dart`. Ensure the UI falls back gracefully if `held_balance` is null (treat as `0.0`).
- **Data Initialization**: Because the Views already calculate `held_balance` natively from existing escrow records, no backfilling is required. UI adoption is instant upon deployment.
- **Rollback Plan**: Revert Flutter widget commits. Since no ledger schemas are altered, the app remains 100% operational throughout toggling.

## E) Admin Dashboard Requirements (Future Phase)

To oversee this system without exposing internal ledgers to end-users, an Admin Dashboard is strictly required consisting of:

- **Finance Overview**: Total Platform GMV, Total Escrow Liabilities, Total Platform Fees Captured (via `platform_revenue`).
- **Escrow Monitor**: List of all open bookings holding active escrow strings.
- **Orphan Payment Quarantine**: Monitor for received webhooks lacking a valid `payment_intent`.
- **Alerts**: Alerts triggered if a ledger entry attempts a withdrawal placing an account into negative numbers (yielding an `ERR_INSUFFICIENT_FUNDS` rejection).

## F) Final Recommendation

- **Release Readiness Decision**: **PARTIAL / BLOCKED ON UI PATCHES**. The backend is completely ready. The frontend must implement the Taxonomy and ViewModel Math patches before releasing to real users.
- **Critical Path Phases Ordering**:
  1. Patch `WalletViewModel` Total Balance calculations (+Clamp protection).
  2. Implement `_buildHeldCard` and `_buildPendingCard` in Wallet Tabs and Dashboards.
  3. Overhaul Transaction List Labels (`escrow_hold` -> "Held for Task").
  4. End-to-end UX edge-case validation.
- **Top Must-Fix Items**:
  1. UI rendering missing `pending_withdrawal_balance`.
  2. UI rendering missing `held_balance`.
  3. UI Transaction History falsely labeling escrow drops as "Spent/Loss".
  4. Enforcing withdrawal button lock until Gateway integration is formalized in Phase 2.
