# Risk Register: Withdrawals Lifecycle

## 1. Risks in Current System (Pre-Improvement)

| Risk ID | Risk Description                                                                               | Severity | Likelihood | Impact                                                                  | Evidence                                                    |
| :------ | :--------------------------------------------------------------------------------------------- | :------- | :--------- | :---------------------------------------------------------------------- | :---------------------------------------------------------- |
| **R1**  | **Orphan Funds on Cancellation**: Funds stay locked in pending but request is marked canceled. | CRITICAL | HIGH       | Financial loss to user; platform liability.                             | `WalletService.dart:144` missing ledger call.               |
| **R2**  | **Double Withdrawal Race**: User rapid-clicks withdrawal button.                               | HIGH     | MEDIUM     | Multiple `withdrawal_requests` rows created before ledger lock returns. | `WalletService.dart:73` lacks client side idempotency.      |
| **R3**  | **Dangling Status**: App crashes after status insert but before ledger call.                   | MEDIUM   | LOW        | Request stuck in `requested` status without locked funds.               | Service method is multi-step without atomic DB transaction. |
| **R4**  | **Bypass Cancellation**: User cancels after payment is already processed.                      | MEDIUM   | MEDIUM     | Platform pays twice (bank + balance return).                            | No `processing` state/logic in `WalletService.dart:154`.    |

## 2. Risks in Improved System (Post-Fix)

| Risk ID | Risk Description                                                           | Severity | Likelihood | Impact                             | Mitigation                                                                    |
| :------ | :------------------------------------------------------------------------- | :------- | :--------- | :--------------------------------- | :---------------------------------------------------------------------------- |
| **MR1** | **Migration Drift**: Existing `canceled` requests still have locked funds. | HIGH     | HIGH       | Balance mismatch for active users. | One-time cleanup script to reconcile `withdrawal_requests` vs `ledger_lines`. |
| **MR2** | **Complexity Overhead**: Moving logic to RPC makes debugging harder.       | LOW      | MEDIUM     | Developer friction.                | Comprehensive logging in `process_payment_event_ledger`.                      |
| **MR3** | **Auth Sync**: RPC must strictly verify `auth.uid()`.                      | HIGH     | LOW        | Unauthorized fund movement.        | Strict `SECURITY INVOKER` and `uid` checks in SQL.                            |
