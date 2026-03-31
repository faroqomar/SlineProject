# Test Plan: Wallet System (Ledger focus)

## 1. Unit Tests (SQL/RPC)

- **T-UNI-01: Double-Entry Parity**
  - **Step**: Call `process_payment_event_ledger` for `escrow_hold`.
  - **Verify**: `SELECT SUM(CASE WHEN direction='DEBIT' THEN amount ELSE -amount END) FROM ledger_lines WHERE journal_entry_id = ...` should be `0`.
- **T-UNI-02: Idempotency Protection**
  - **Step**: Call `process_payment_event_ledger` twice with the same `idempotency_key`.
  - **Verify**: Second call should fail with unique constraint violation or be ignored (upserted).
- **T-UNI-03: Negative Amount Guard**
  - **Step**: Try to insert a ledger line with a negative amount.
  - **Verify**: `ck_ledger_lines_amount_positive` should trigger an error.

---

## 2. Integration Tests (Booking Flow)

- **T-INT-01: Full Lifecycle (Success)**
  - **Flow**: `Pay` → `Accept` → `Deliver` → `Approve`.
  - **Verify**:
    - After `Pay`: `held_balance` reflects gross amount.
    - After `Approve`: `held_balance` is `0`, `available_balance` (freelancer) reflects net amount.
- **T-INT-02: Refund Flow**
  - **Flow**: `Pay` → `Decline` (by freelancer).
  - **Verify**: `held_balance` returns to `0`, `available_balance` (client) reflects full refund.

---

## 3. Security/RLS Tests

- **T-SEC-01: Unauthorized Read**
  - **Step**: User A tries to `SELECT` from `ledger_lines` for User B's account.
  - **Verify**: Should return 0 results due to RLS.
- **T-SEC-02: Direct Insert Bypass**
  - **Step**: User tries to `INSERT` into `ledger_lines` directly.
  - **Verify**: Should be rejected (only RPC/System access).

---

## 4. Manual Verification

- **M-VER-01: Wallet View Consistency**
  - **Step**: Perform a transaction and refresh the Flutter Wallet Screen.
  - **Verify**: Values match the `wallet_balances` view results in Supabase SQL editor.
