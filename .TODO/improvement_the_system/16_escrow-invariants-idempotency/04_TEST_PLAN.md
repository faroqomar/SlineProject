# Test Plan: 16_escrow-invariants-idempotency.md

## Skills applied:

- Test Design (High-Value Tests)
- State Machine & Lifecycle
- Idempotency & Concurrency

---

## 1. Unit Tests (Logic Level)

### T1: Idempotency Retrieval

- **Intent**: Verify that calling the release function twice with the same business state results in a single ledger entry.
- **Scenario**:
  1. Call `rpc_approve_delivery` for Entity A.
  2. Verify `journal_entries` has 1 row with key based on `EntityA:held`.
  3. Call `rpc_approve_delivery` again.
  4. Verify `journal_entries` still has 1 row.
  5. Verify no duplicate `ledger_lines`.

### T2: Race Condition Simulation

- **Intent**: Verify that concurrent requests don't bypass the guard.
- **Scenario**:
  1. Start two parallel transactions calling `rpc_approve_delivery` for the same ID.
  2. Verify one succeeds and one fails with a handled `unique_violation` (or returns the existing result).

---

## 2. Integration Tests (Full Flow)

### T3: Network Retry Resilience (End-to-End)

- **Intent**: Verify that the app service can recover from network failure without double-charging.
- **Steps**:
  1. Mock Supabase to return "Network Error" _after_ successful DB commit.
  2. Trigger `WorkManagementService.approveDelivery`.
  3. Catch exception in app logic.
  4. Call `approveDelivery` again (simulate user retry).
  5. Verify final balance in `wallet_balances` view is exactly `Original - Amount`, not `Original - (2 * Amount)`.

---

## 3. Security Tests (Adversarial)

### T4: Bypass Attempt

- **Intent**: Try to release escrow for a task that is already `completed`.
- **Steps**:
  1. Manually set task status to `completed` but ledger still `held`.
  2. Call `rpc_approve_delivery`.
  3. Verify it fails or ignores (Invariant: Cannot release what is already completed).
