# Gaps and Fixes: Withdrawals Lifecycle

## GAP-01: Incomplete Cancellation Flow (CRITICAL)

- **Issue**: `cancelWithdrawalRequest` in `WalletService` only updates the DB status. Funds remained locked in `user_pending_withdrawal` account.
- **Risk**: Permanently orphan user funds.
- **Fix**: Call `process_payment_event_ledger` with a new event `withdrawal_cancel` (or reuse `withdrawal_failed` logic) to revert the DR/CR lines.

## GAP-02: Status Enum Synchronization

- **Issue**: `SUPABASE_SETUP.md` (pending, approved, failed) vs `WalletService.dart` (requested, failed, canceled).
- **Risk**: DB constraint violations or UI/Backend status mismatch.
- **Fix**: Standardize on a single Lifecycle Enum: `requested` → `processing` → `completed` | `failed` | `canceled`.

## GAP-03: Race Condition on Request Creation

- **Issue**: `Insert row` then `Call ledger`. If it fails, we try to `Update status = failed`. If app crashes, record stays `requested`.
- **Risk**: Ledger doesn't match DB state.
- **Fix**: Use a database function (RPC) to wrap the insert and the ledger call in a single transaction.

## GAP-04: Handling "Processing" state

- **Issue**: Once an admin starts the transfer, the user should not be able to cancel.
- **Risk**: User cancels while money is already in the bank's wire system.
- **Fix**: Add a `processing` status. Once status is `processing`, `cancelWithdrawalRequest` must return an error.

## GAP-05: Admin/Gateway Logic

- **Issue**: The diagram is vague on _who_ calls `withdrawal_complete`.
- **Risk**: Manual errors by admins or double-crediting if use tries to retry.
- **Fix**: Define clear Gateway Callback handlers that are idempotent based on the `withdrawal_id`.
