# Audit Notes: Withdrawals Lifecycle

**Auditor**: SLine System Improvement Auditor
**Skills applied**: State Machine & Lifecycle, Idempotency & Concurrency, DB-First Financial Modeling, Threat Modeling, Diagram Crafting.

## 1. Evidence Findings

### 1.1 Database Schema (`withdrawal_requests`)

- **Path**: `SUPABASE_SETUP.md:850`
- **Current Columns**: `id`, `user_id`, `status`, `amount`, `currency`, `created_at`.
- **Status Enum Gap**: `SUPABASE_SETUP.md` lists `['pending', 'approved', 'failed']` but `WalletService.dart` uses `requested`, `failed`, `canceled`.

### 1.2 Ledger Integration

- **Path**: `lib/features/wallet/services/wallet_service.dart:89`
- **Contract**: `submitPaymentEvent(eventType: 'withdrawal_request', ...)`
- **Ledger Behavior**: The diagram claims it debits `user_available` and credits `user_pending_withdrawal`.

### 1.3 Cancellation Logic

- **Path**: `lib/features/wallet/services/wallet_service.dart:144`
- **Risk**: `cancelWithdrawalRequest` updates the database status to `canceled` but **omits** the ledger call.
- **Evidence**: Line 162-165 only does a DB update:
  ```dart
  await _client
      .from('withdrawal_requests')
      .update({'status': 'canceled'})
      .eq('id', withdrawalId);
  ```

## 2. Structural Gaps

- **Atomic Sequence**: The current flow is `DB Insert` -> `Ledger Call`. If the process crashes between these, the DB shows a request that has no funds locked.
- **Admin/Gateway Layer**: The diagram shows an "Admin/Gateway" actor, but there is no evidence of the server-side code that handles `withdrawal_complete` or `withdrawal_failed`.
- **Idempotency**: `LedgerService` uses `Uuid().v5` for idempotency, which is excellent. However, the `requestWithdrawal` method in `WalletService` does not accept a client-side idempotency key, meaning a UI retry could create duplicate rows in `withdrawal_requests`.

## 3. Financial Invariants

- **Invariant 1**: Total balance (Available + Pending + Gateway) must remain constant during the lifecycle until the bank transfer is confirmed.
- **Invariant 2**: A user cannot cancel a withdrawal that has already been dispatched to a gateway.
- **Invariant 3**: A withdrawal request cannot move to `completed` without a corresponding ledger entry moving funds from `user_pending_withdrawal` to `system_clearing`.
