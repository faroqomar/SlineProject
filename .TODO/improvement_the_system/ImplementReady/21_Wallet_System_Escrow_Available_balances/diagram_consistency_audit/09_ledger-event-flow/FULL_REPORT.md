# FULL REPORT: 09 Ledger Event Flow

## 0) Skill Selection

- **Skills selected**: DB-First Financial Modeling, Threat Modeling (Security), Invariants & Contracts, State Machine & Lifecycle, Idempotency & Concurrency.
- **Why these fit**: This is the heart of the Double-Entry Ledger. Ensuring entries balance to 0, preventing race conditions, and modeling financial data accurately are the paramount responsibilities here.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/09_ledger-event-flow`
- **What system/feature it describes**: The double-entry accounting engine handling logical events (like "Escrow Hold" or "Release with Fee") and mapping them into balancing `ledger_lines`.
- **Entities involved**: `process_payment_event_ledger` (RPC), `accounts`, `journal_entries`, `ledger_lines`.

## 2) Human Explanation

When an app trigger (e.g., Client pays a booking) or a Webhook (QiCard clears) fires, it calls `process_payment_event_ledger`. This RPC checks if the status of the related entity is valid. If valid, it generates a `journal_entry` locking the transaction, and creates multiple `ledger_lines` (e.g., Debit User Available, Credit Platform Escrow). Before committing, the RPC enforces `Debit_Sum + Credit_Sum = 0` (The Double-Entry rule). If successful, the transaction is committed, making the money movement permanently auditable.

## 3) Symbol Legend

- **Rectangles**: Trigger sources vs Engine Logic vs Ledger Tables.
- **Solid Arrows**: Execution path.
- **Dashed Arrows (DR/CR)**: Debit/Credit line creation mapping to accounts.

## 4) Extracted Contracts & Invariants

1. **Double-Entry Identity**: `Debit_Sum + Credit_Sum = 0` for every transaction.
2. **Positive Magnitude**: All `ledger_lines.amount` entries must be > 0.
3. **Replay Protection**: Every event must have a unique `idempotency_key`.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Legacy diagram relied on `process_payment_event`.
- **Resolution**: Upgraded context strictly maps to `process_payment_event_ledger`.

### 5.2 Logic Drift

- **Conflict**: Zero-Fee release lines caused constraints to fail.
- **Resolution**: Code logic omits 0-amount revenue lines (patched in DB).

### 5.3 Data Model Drift

- None detected within the upgraded v2.16 Ledger schema.

## 6) Security & Failure Modes (Adversarial)

- **Double-Spending (Fast Clicking)**: Client presses 'Pay' exactly twice in 5ms.
  - _Mitigation_: `uq_journal_entries(related_entity_id, event_type, idempotency_key)` rejects the second call.
- **Direct Table Modification**: Attacker attempts to change their own balance.
  - _Mitigation_: `ledger_lines` has no `INSERT` permissions for public roles. Only `SECURITY DEFINER` RPCs can write to it.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Wallet Screen, Checkout, Withdrawals.
- **States**: Uses `vw_wallet_balances` to display aggregates rather than querying raw lines.
- **Guardrails**: Generate `idempotency_key` (UUID v4) on screen load, NOT on button press.

### 7.2 Admin Dashboard UI

- **Pages**: Finance Reconciliation, Dispute Resolution.
- **Metrics**: Total Platform Escrow vs Total Platform Revenue.
- **Drilldowns**: Ability to trace `related_entity_id` to exactly which task/booking created a journal entry.

### 7.3 Implementation Hooks

- `LedgerService.submitPaymentEvent()` invokes the RPC.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9.5/10
- **Best Diagram Type**: State Flowchart + Component Diagram showing the relationship between triggers, RPC bounds, and constraints.

## 9) Upgrade Plan

- **Phase 0: Observability**: Inject UI metadata (`device_id`) into `p_meta` in entries.
- **Phase 1: Contracts**: Cast ENUM types precisely in RPC prepared statements.
- **Phase 2: Hardening**: Run `SELECT FOR UPDATE` on the underlying task row to freeze its state during ledger generation.
- **Phase 3: Admin Tooling**: Formally implement `admin_manual_correction` events for manual tier-3 support fixes.

## 10) Risks

### 10.1 Risks if current version kept

- **N/A**: The ledger is structurally solid if invariants hold.

### 10.2 Risks introduced by fixes

- **Lock Contention**: `SELECT FOR UPDATE` may slow down concurrent webhooks. _Mitigation_: Fast transaction completion.

## 11) Test Plan (High-value)

- **Unit (DB)**: Pass an unbalanced set of debit/credits into the RPC check logic -> verify abort.
- **Concurrency**: Send two requests with the same idempotency key concurrently -> verify exactly 1 success.
- **Security**: Deny direct `INSERT` via standard client JWT.

## 12) Production Checklist

- [ ] Double-entry logic strictly enforced via RPC check.
- [ ] Idempotency key universally provided by client/webhook.
- [ ] Zero-fee calculation logic ignores empty revenue lines.
