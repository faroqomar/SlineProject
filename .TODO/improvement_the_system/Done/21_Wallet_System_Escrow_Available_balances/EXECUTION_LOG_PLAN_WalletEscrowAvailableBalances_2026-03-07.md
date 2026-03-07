# Execution Log: Plan Wallet Escrow Available Balances (Critic)

**Plan:** `.TODO/PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC.md`  
**Started:** 2026-03-07  
**Executor:** @Executor (with AppLogger, tests, Supabase MCP)

---

## Status by Phase

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 0: Data & Contracts | Done | Live scan, contract, grep (comment fix in view_security_test) |
| Phase 1: Security & Backend | Done | RLS matrix, migration direct_offer applied via MCP; RLS + wallet tests pass |
| Phase 2: App Layer (MVVM) | Done | DirectOffersService uses rpc_approve_delivery; AppLogger in completeOffer + getWalletBalance |
| Phase 3: UI & Integration | Done | Already: loading states, approve disabled in modal/direct offer |
| Phase 4: QA & Release | Done | Ledger + wallet + view_security tests pass; analyze clean |
| Phase 5: Documentation | Done | Diagram 21: Withdraw = Upcoming; process_payment_event_ledger / rpc_approve_delivery wording |

---

## Phase 0: Data & Contracts

### Step 0.1 Live scan (Supabase MCP)

- **Tool:** `plugin-supabase-supabase` execute_sql (project_id: isddrknbjsgaantjojhm).
- **Views:** `vw_wallet_balances_user`, `vw_wallet_activity_user` exist. No `wallet_balances` view in public schema.
- **Tables:** accounts, journal_entries, ledger_lines, wallet_transactions (frozen).
- **rpc_approve_delivery:** Signature (entity_type text, entity_id uuid). Body: task + booking only; idempotency key already deterministic (`entity_id || ':release_with_fee:' || v_status || ':' || v_payment_status`), no `now()`. **direct_offer:** NOT supported (else branch raises 'Invalid entity type').
- **Decision D3:** direct_offer supported: **NO** → Migration required for Phase 1.

### Step 0.2 Contract

- **Done.** Created `.TODO/.../21_Wallet_System_Escrow_Available_balances/CONTRACT_rpc_approve_delivery.md` (params, entity_type, idempotency, canonical views).

### Step 0.3 Grep (wallet_transactions / view layer)

- **lib:** No `.from('wallet_transactions')`. Only ledger_service.dart mentions `uq_journal_entries` (string in error handling). No view layer `.from('ledger_lines')` or `.from('journal_entries')`.
- **test:** view_security_test.dart comment updated to "ledger/views; canonical vw_wallet_balances_user, vw_wallet_activity_user".

---

## Observability (AppLogger)

- WalletService: already uses AppLogger (getActivity, getWalletBalance, requestWithdrawal).
- LedgerService: already uses AppLogger (submitPaymentEvent success/error).
- WorkManagementService.approveDelivery: already uses AppLogger (request, success, error).
- DirectOffersService.completeOffer: has AppLogger.i on success; adding explicit log at start and on error (tagged).
- ReviewDeliveryModal: already uses AppLogger (approve/reject).
- All new or touched flows will use AppLogger; no print().

---

## Phase 5: Documentation

- Diagram 21: Withdraw marked **Upcoming feature**; entry point text updated to process_payment_event_ledger / rpc_approve_delivery.
- Contract and LIVE_SCAN in `.TODO/.../21_Wallet_System_Escrow_Available_balances/`.

## Final completion summary

- **Phase 0–5 done.** Data/contracts gate passed (live scan, contract, no wallet_transactions in code). Idempotency was already fixed in DB (20260307000001). direct_offer added to rpc_approve_delivery via migration 20260307120000 (applied with Supabase MCP). DirectOffersService.completeOffer now uses rpc_approve_delivery (single exit point). AppLogger added in completeOffer (start, validation, error, success) and in WalletService.getWalletBalance (error path). RLS matrix and tests (ledger_rls_test, view_security_test, wallet unit tests) pass. Diagram 21 updated: Withdraw = Upcoming feature; process_payment_event_ledger / rpc_approve_delivery wording.
- **Rollback:** Revert migration 20260307120000 (replace rpc_approve_delivery with previous version without direct_offer); revert DirectOffersService to use LedgerService.submitPaymentEvent for completeOffer if needed.
- **Tests run:** `flutter test test/rls/ledger_rls_test.dart test/rls/view_security_test.dart test/unit/wallet/` — 13 passed. `flutter analyze` clean for touched files.

## Blockers

- None.

---

## Evidence / Artifacts

- LIVE_SCAN: `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/LIVE_SCAN_2026-03-07.md`
- Contract: `.TODO/.../21_Wallet_System_Escrow_Available_balances/CONTRACT_rpc_approve_delivery.md`
- RLS matrix: `.TODO/.../21_Wallet_System_Escrow_Available_balances/RLS_CHECK_MATRIX_wallet_ledger.md`
- Migration: `supabase/migrations/20260307120000_rpc_approve_delivery_direct_offer.sql` (applied via Supabase MCP)
- Verification: `flutter test test/rls/ledger_rls_test.dart test/unit/wallet/ test/rls/view_security_test.dart` — all passed

## All plan SQL implemented via Supabase MCP (verified 2026-03-07)

| Plan item | Local migration | Applied on Supabase | How |
|-----------|-----------------|---------------------|-----|
| Idempotency (no `now()`) | `20260307000001_escrow_idempotency_stable_key.sql` | Yes | Already in remote history as `escrow_idempotency_stable_key` (version 20260307010953). Live DB has deterministic key. |
| direct_offer in rpc_approve_delivery | `20260307120000_rpc_approve_delivery_direct_offer.sql` | Yes | Applied in this execution via MCP `apply_migration`. Remote `pg_get_functiondef(rpc_approve_delivery)` confirms task + booking + **direct_offer** branches and deterministic idempotency. |

No further SQL migrations from the plan remain. RLS matrix and tests are documentation/automated only (no DDL).
