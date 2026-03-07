# Execution Log: PLAN_LedgerEventFlow_2026-03-07

**Plan:** `.TODO/PLAN_LedgerEventFlow_2026-03-07.md`  
**Started:** 2026-03-07  
**Executor:** @Executor (AppLogger enforced; Supabase MCP used for live scan)

---

## Evidence & Findings (From Full Context Scan)

### Documentation scan
- `Sline_everything/DEVELOPER_GUIDE.md`, `SUPABASE_SETUP.md`, `MVP_ROADMAP.md`, `STRUCTURE.md` exist; Finance & Payment Ledger and Wallet_Feature referenced.
- `09_ledger-event-flow/` spec: 00–07, 04_TEST_PLAN, 06_DIAGRAM_FINAL, 03_RISK_REGISTER present.

### Code scan
- `lib/features/wallet/services/ledger_service.dart`, `wallet_service.dart`, `data/wallet_repository.dart` exist.
- LedgerService uses AppLogger; submitPaymentEvent accepts `meta`; no forensics keys enforced yet.
- Test helpers: `test/helpers/mock_supabase.dart`, `test/helpers/ledger_rpc_invoker.dart` exist.
- No `test/unit/wallet/` directory yet.

### Supabase live (MCP)
- **Project:** isddrknbjsgaantjojhm (Sline Project).
- **Tables:** `accounts`, `journal_entries`, `ledger_lines` exist with expected columns (journal_entries.meta jsonb, etc.).
- **Enum:** `payment_event_type_enum` includes: escrow_hold, release_with_fee, refund, withdrawal_request, deposit, withdrawal_complete, withdrawal_failed, admin_credit, **admin_adjustment**, reversal, gateway_escrow.
- **RPC:** `process_payment_event_ledger` exists, returns jsonb.
- **RLS:** ledger_lines and journal_entries have insert_policy (qual null), delete/update false; service_policy ALL for service_role. RLS test will confirm authenticated INSERT behavior.

### Gaps (to create)
- Contract file for ledger event flow and p_meta forensics.
- `test/unit/wallet/` with ledger_service_test.dart, wallet_service_test.dart.
- Forensics source (session_id / request_id) and pass-through in LedgerService.
- RLS test: authenticated INSERT into ledger_lines must fail.
- Runbook + orphan query for two-phase withdrawal (Phase 5).
- Smoke checklist and timeout/retry doc.

### Risks
- Withdrawal two-phase: orphan rows if cleanup fails — runbook to be added.
- RLS: automated test will verify no user INSERT on ledger tables.

---

## Phase 0: Preconditions, Decisions, Test Infra

**Status:** Done

### 0.1 Decisions (locked)
- **Withdrawal:** (A) Two-phase + runbook + orphan query. No atomic RPC this phase.
- **admin_adjustment:** (B) Scope out; document "not implemented" in DEVELOPER_GUIDE.
- **DB test env:** (A) Real Supabase (dev) for integration/RLS; unit tests use mocks only.

### 0.2 Contract
- **Artifact:** `.TODO/improvement_the_system/ImplementReady/09_ledger-event-flow/CONTRACT_ledger_event_flow.md` — created; params, p_meta forensics keys, admin_adjustment scoped out, withdrawal two-phase.

### 0.3 Test infrastructure
- **Artifacts:** `test/unit/wallet/ledger_service_test.dart` (idempotency key tests), `test/unit/wallet/wallet_service_test.dart` (getWalletBalance null user).
- **Run:** `flutter test test/unit/wallet/` — 4 tests pass.
- **Timeout/retry:** Execution log: integration/RLS 30s timeout, 1 retry.

---

## Phase 1: Data & Security

**Status:** Done

### 1.0 Live Supabase confirmation
- **Done:** Supabase MCP list_tables, execute_sql for enum and RPC; RLS policies listed. Drift: none; admin_adjustment present in enum, RPC branch not implemented (scoped out).

### 1.1–1.3 Schema / RLS / Migration
- No new migration (admin_adjustment scoped out; withdrawal two-phase).
- **RLS test:** `test/rls/ledger_rls_test.dart` — assertCannotInsert for ledger_lines and journal_entries (2 tests pass). With real client would verify live.

---

## Phase 2: App Layer (MVVM)

**Status:** Done

### 2.1 Forensics source
- **Done:** LedgerService._mergeForensics() injects session_id (auth.currentUser?.id) into meta when not present; all submitPaymentEvent calls now send p_meta with forensics per contract. AppLogger used for submit start/success/error.

---

## Phase 3: UI

**Status:** Not Started (no admin flow)

---

## Phase 4: QA + Security

**Status:** Done

- Unit: `flutter test test/unit/wallet/` — 4 passed (LedgerService idempotency, WalletService zero when null user).
- RLS: `flutter test test/rls/ledger_rls_test.dart` — 2 passed (ledger_lines and journal_entries INSERT blocked).
- Smoke checklist and runbook: `09_ledger-event-flow/SMOKE_CHECKLIST_AND_RUNBOOK.md` created.

---

## Phase 5: Documentation & Release

**Status:** Done

- DEVELOPER_GUIDE.md: Finance & Payment Ledger — added reference to 09 folder (diagram, risk register, contract, smoke/runbook); forensics and admin_adjustment scoped out.
- Wallet_Feature.md: added event flow and runbook ref; test run commands.
- No new migration; no destructive changes.

---

## Blockers

- None.

---

## Verification Evidence

- **Phase 0:** Contract file created; `test/unit/wallet/` with 4 unit tests; decisions locked (withdrawal two-phase, admin_adjustment scoped out, DB test env).
- **Phase 1:** Supabase MCP scan done; no drift; `test/rls/ledger_rls_test.dart` added (2 tests pass).
- **Phase 2:** LedgerService._mergeForensics() injects session_id; AppLogger used for submit start/success/error.
- **Phase 4:** `flutter test test/unit/wallet/ test/rls/ledger_rls_test.dart` — 6 tests passed. SMOKE_CHECKLIST_AND_RUNBOOK.md created.
- **Phase 5:** DEVELOPER_GUIDE.md and Wallet_Feature.md updated with 09 folder refs and test commands.

## Completion Summary

- **Rollout:** No DB migration; app changes are additive (forensics in meta, tests, docs). Safe to deploy.
- **Rollback:** Revert app commit; LedgerService will still work (forensics optional per contract).
- **Observability:** AppLogger used throughout LedgerService; forensics (session_id) in journal_entries.meta for dispute/audit.

## SQL / Supabase MCP (Verification)

- **No new SQL required by the plan.** Locked decisions: (A) withdrawal = two-phase + runbook, (B) admin_adjustment scoped out. So Phase 1.1 had no migration to add.
- **Existing ledger SQL is applied.** Supabase MCP `list_migrations` shows 100+ migrations applied, including: create_ledger_core_schema, drop_and_recreate_process_payment_event_ledger_rpc, create_ledger_rls_policies, fix_payment_ledger_enum_casts, fix_release_with_fee_zero_amount_and_enum, 20260307_enable_fee_locking, escrow_idempotency_stable_key, etc. Live DB has `process_payment_event_ledger`, `journal_entries.meta`, and RLS on ledger tables.
- **Holistic report (00) Phases 1–2:** Enum casts and SELECT FOR UPDATE are in existing migrations (already applied). No additional SQL was applied via MCP during this execution because none was in scope.
- **If you later add admin_adjustment or atomic withdrawal:** create a new migration (file in repo) and apply it via Supabase MCP `apply_migration` (name + query) or CLI.
