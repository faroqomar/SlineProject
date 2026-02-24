# PAYMENT LEDGER SYSTEM - EXECUTION PLAN

This is the critical path to safely and effectively migrate the platform to the new double-entry ledger without disrupting ongoing operations or integrity.

## Critical Path Checklist

- [x] **Phase A (Schema):** Create `accounts`, `journal_entries`, `ledger_lines`, `audit_logs`, `withdrawal_requests`.
- [x] **Phase A (Security):** Apply `append-only` triggers blocking updates/deletes, configure RLS.
- [x] **Phase A (Seed):** Initialize `platform_cash`, `platform_escrow`, `platform_revenue`, `platform_test_float`.
- [x] **Phase B (Engine):** Deploy `process_payment_event_ledger` RPC (locks, gates, funds, idempotency, balancing).
- [x] **Phase C (Views Contract):** Deploy `vw_wallet_balances_user`, `vw_wallet_activity_user`, `vw_financial_metrics_period`, `vw_financial_metrics_realtime`.
- [x] **Phase D (Integration):** Update `BookingService`, `TaskService`, `WalletService`, and `DashboardRepository` in Flutter to point to new views/RPC.
- [x] **Phase E (Cutover):** Execute backfill mapping `wallet_transactions` to journals, run reconciliation, freeze legacy writes.

---

## Phases Breakdown

### Phase A: DB Schema + Security

**Deliverables:**

- Migration scripts to create tables: `accounts`, `journal_entries`, `ledger_lines`, `audit_logs`, `withdrawal_requests`.
- Implementation of strict constraint triggers (append-only ledger, balance enforcement).
- RLS policies enforcing read-only access for authenticated users via views, and write-only via RPC.

**Acceptance Criteria:**

- Direct `INSERT` of an unbalanced journal fails.
- Direct `UPDATE` or `DELETE` on ledger tables fails (even for `service_role`).
- New users with no transaction history see balance as `0` instead of `null` from the views.

---

### Phase B: RPC Engine (The Core)

**Deliverables:**

- The `process_payment_event_ledger(p_entity_id, p_type, p_event, p_idempotency_key)` PostgreSQL function.
- Internal RPC blocks: Row-level `FOR UPDATE` lock, Gate Validation (status + payment_status + actor), Funds Check, Idempotency Check, DB Insertion, Audit Logging.

**Acceptance Criteria:**

- Concurrency test: Rapid-fire double clicks resolving identically to `1` written journal.
- Logical test: Attempting to `release_with_fee` on a booking not in `delivered` status throws a designated error.
- Logical test: Attempting to `refund` on a booking where payment is not `held` throws a designated error.

---

### Phase C: Views Contract

**Deliverables:**

- Materialized or Standard Views defining exact queries for `wallet balances`, `wallet activity`, and `dashboard financials`: `vw_wallet_balances_user`, `vw_wallet_activity_user`, `vw_financial_metrics_realtime`, `vw_financial_metrics_period`.

**Acceptance Criteria:**

- Querying a brand-new user returns `0` balances (not `null`).
- External joins from views work seamlessly with `profiles` purely for UI rendering.

---

### Phase D: App Wiring

**Deliverables:**

- Flutter refactoring. `BookingService`, `TaskService` generate and pass UUID v4 as `idempotency_key` per RPC call.
- `WalletService` bound to new `vw_` interfaces.
- `DashboardRepository` routes completely to `vw_financial_metrics`.

**Acceptance Criteria:**

- Wallet UI reads _only_ from `vw_wallet_balances_user` and `vw_wallet_activity_user` (no base tables).
- Dashboard financial widgets read _only_ from `vw_financial_metrics_*`.
- Every RPC call from the app includes a new UUIDv4 `idempotency_key`.

---

### Phase E: Backfill + Cutover

**Deliverables:**

- Migration script iterating over legacy `wallet_transactions` and creating valid `journal_entries` + `ledger_lines` matched exactly in sum (meta: legacy_tx_id).
- DB Trigger added to permanently freeze `wallet_transactions`.

**Acceptance Criteria:**

- `legacy wallet_balances` equals natively derived `vw_wallet_balances_user` across a randomly sampled subset of 100 users.
- `freeze legacy writes` trigger actively prevents insertions into old tables.

**Rollback Strategy:**

1. Disable trigger freezing `wallet_transactions`.
2. Revert Flutter App Git state to pre-Phase D.
3. Any variance after rollback MUST be corrected using compensating journals (never by mutating history).

---

## Testing Matrix

| Testing Vector          | Methodology                                                                 | Expected Outcome                                                                                         |
| :---------------------- | :-------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------- |
| **Idempotency**         | Call `escrow_hold` RPC twice using the identical `idempotency_key`.         | Transaction 1 commits lines. Transaction 2 gracefully returns `200 Success` doing nothing.               |
| **Concurrency**         | Fire `release_with_fee` concurrently via 2 thread pools.                    | Request 1 locks entity row. Request 2 blocks until 1 finishes, then fails gate check (already released). |
| **Gating Restrictions** | Attempt to trigger `refund` when `payment_status != held`.                  | Gate Validation throws fatal Exception & Rolls Back.                                                     |
| **Negative Balance**    | Call `withdrawal_request` for $200 on an account with $50 `user_available`. | Funds Check throws fatal Exception & Rolls Back.                                                         |
| **Reconciliation Base** | Sum `platform_escrow` lines.                                                | Exactly equates to the collective `held` aggregate.                                                      |
