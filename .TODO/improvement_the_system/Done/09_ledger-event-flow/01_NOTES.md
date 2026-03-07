# Ledger Event Flow Audit Notes

**Skills selected:**

- **Evidence-First Reading**: Mapping direct code/DB implementations to flow.
- **Threat Modeling**: Analyzing financial leakage and race conditions.
- **Invariants & Contracts**: Verifying double-entry balancing rules.
- **State Machine & Lifecycle**: Checking event status gates.
- **Idempotency & Concurrency**: Validating replay protection.
- **DB-First Financial Modeling**: Aligning with `ledger_lines` architecture.

---

## 1. Evidence Map

### 1.1 Database (Supabase)

- **Tables**: `accounts`, `journal_entries`, `ledger_lines`.
  - _Reference_: `SUPABASE_SETUP.md:L39-41`, `L597`.
- **Core Engine**: `process_payment_event_ledger(p_event_type, ...)` RPC.
  - _Reference_: `SUPABASE_SETUP.md:L1430`.
- **Enums**: `payment_event_type_enum` defines permitted transitions.
  - _Reference_: `SUPABASE_SETUP.md:L272`, `L1438`.
- **Aggregate View**: `vw_wallet_balances_user` for real-time balance calculations.
  - _Reference_: `SUPABASE_SETUP.md:L966`.

### 1.2 Code (Flutter)

- **Service Layer**: `WalletService` reads via `vw_wallet_balances_user`.
  - _Reference_: `lib/features/wallet/services/wallet_service.dart:L37`.
- **Transaction Engine**: `LedgerService.submitPaymentEvent` wraps the RPC.
  - _Reference_: `lib/features/wallet/services/ledger_service.dart:L22`.
- **Idempotency**: Deterministic UUIDv5 based on `entity_id` and `event_type`.
  - _Reference_: `lib/features/wallet/services/ledger_service.dart:L13-19`.

---

## 2. Invariants & Contracts

1. **Double-Entry Balance**: Sum of `amount` for all `ledger_lines` in a single `journal_entry` MUST be 0.
2. **Positive Amounts**: `ledger_lines.amount` must be > 0 (signed direction handled via `DEBIT`/`CREDIT` type).
   - _Evidence_: `ck_ledger_lines_amount_positive` in `SUPABASE_SETUP.md:L1438`.
3. **Immutability**: Once recorded, `ledger_lines` are never updated. Corrections require new contra-entries.
4. **Status Gates**: `process_payment_event_ledger` must validate that the `related_entity` (booking/offer) is in a valid state for the requested event (e.g., cannot `release_with_fee` if not `held`).

---

## 3. Initial Gaps & Risks

### 3.1 Gaps in Current Diagram

- **Missing Event Types**: The diagram omits `withdrawal_request` and `gateway_escrow` (QiCard), which are critical for the full lifecycle.
- **Idempotency Flow**: Does not show how the caller provides the idempotency key (client-side vs server-side generation).
- **Failure Branches**: No representation of what happens if the RPC fails (e.g., insufficient funds).
- **Admin/Manual Adjustments**: No visibility into how admin "adjust" events interact with the ledger.

### 3.2 Risks

- **Race Condition (Booking/Offer)**: If a client cancels _exactly_ as a provider completes, the ledger must ensure only one winner moves funds.
- **Negative Balance via Fees**: If the fee calculation allows the provider's credit to be negative (unlikely with `ck` but possible if logic is flawed), it breaks integrity.
- **System-Account Depletion**: Platform revenue or escrow accounts must be monitored; the diagram doesn't show "Operator" views.

---

## 4. Failure Modes

| Scenario            | Current Handling                                   | Ideal Handling                      |
| ------------------- | -------------------------------------------------- | ----------------------------------- |
| Insufficient Funds  | RPC returns `ERR_INSUFFICIENT_FUNDS`               | Standard behavior (Pass).           |
| Duplicate Call      | Idempotency Replay caught by `uq_journal_entries`  | Return original success (Pass).     |
| RPC partial failure | DB Transaction rollbacks                           | Standard behavior (Pass).           |
| Zero-Amount Fee     | Migration `20260308` forces removal of 0-amt lines | Omit record to satisfy `ck` (Pass). |
