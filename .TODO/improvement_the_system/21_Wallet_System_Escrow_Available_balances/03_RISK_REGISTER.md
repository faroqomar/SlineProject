# Risk Register: Wallet System

## 1. Risks if Current (Legacy) System is Kept

| Risk ID      | Description                                                                                            | Severity | Likelihood | Impact             | Evidence                 |
| :----------- | :----------------------------------------------------------------------------------------------------- | :------- | :--------- | :----------------- | :----------------------- |
| **R-LEG-01** | **Data Drift**: Writing to `wallet_transactions` will fail due to frozen trigger, causing app crashes. | Critical | High       | System Failure     | `SUPABASE_SETUP.md:1456` |
| **R-LEG-02** | **Race Conditions**: Single-table updates without double-entry parity lead to balance corruption.      | High     | Medium     | Financial Loss     | `SUPABASE_SETUP.md:93`   |
| **R-LEG-03** | **Audit Blindness**: No `journal_entries` means impossible to reconstruct why a balance changed.       | Medium   | High       | Compliance Failure | `SUPABASE_SETUP.md:584`  |

---

## 2. Infrastructure & Logic Risks

| Risk ID      | Description                                                                                      | Severity | Likelihood | Mitigation                                                                    |
| :----------- | :----------------------------------------------------------------------------------------------- | :------- | :--------- | :---------------------------------------------------------------------------- |
| **R-INF-01** | **Idempotency Failure**: Duplicate webhook calls could result in double-escrow or double-payout. | Critical | Low        | Always use `idempotency_key` based on `booking_id + event_type`.              |
| **R-INF-02** | **Unauthorized Release**: Malicious user releases funds prematurely.                             | High     | Low        | Enforce `auth.uid()` checks in `process_payment_event_ledger` or its callers. |
| **R-INF-03** | **Zero-Fee Bug**: `release_with_fee` might fail if fee is 0 and amount check is missing.         | Low      | Low        | `ck_ledger_lines_amount_positive` handled in v2.16 logic.                     |

---

## 3. Migration Risks (Upgrading to Ledger)

| Risk ID      | Description                                                                                 | Severity | Likelihood | Mitigation                                                                     |
| :----------- | :------------------------------------------------------------------------------------------ | :------- | :--------- | :----------------------------------------------------------------------------- |
| **R-MIG-01** | **Balance Mismatch**: Migrating old `wallet_transactions` to new ledger might miss entries. | High     | Medium     | Dual-read view `wallet_balances` (if necessary) or a one-time migration audit. |
| **R-MIG-02** | **RPC signature change**: Breaking changes for front-end callers.                           | Medium   | Medium     | Maintain the legacy RPC as a shim that throws clear migration errors.          |
