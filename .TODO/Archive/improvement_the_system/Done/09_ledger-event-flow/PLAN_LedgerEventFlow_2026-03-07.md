# Plan: Ledger Event Flow Implementation (09_ledger-event-flow) — Plan Critic v2.1

**Role:** @PlanCritic. This document is the **execution-ready, gate-based** rewrite of the original plan, with assumptions, gates, gaps, invariants, risks, pre-mortem, concrete fixes, and change report.

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (inferred)

- Stack: Flutter + Supabase; MVVM; Provider; tests in `test/unit`, `test/widget`, `test/integration_test`, `test/rls`; mocktail + `test/helpers/mock_supabase.dart`, `test/helpers/ledger_rpc_invoker.dart`.
- Single developer or small team; no separate staging DB for integration tests (tests may run against dev Supabase or with mocks).
- "Additive only" means no DROP/ALTER on existing ledger columns; new RPC branches or one new RPC are allowed.
- Forensics = at least one stable key in `p_meta` (e.g. `request_id` or `session_id`) stored in `journal_entries.meta`; device_id is optional if not available on all clients.
- Admin flow: if `admin_adjustment` is implemented, it is service_role or admin-only (no authenticated user call).

### Decision Needed (Blocking)

| # | Decision | Options | Recommended | Plan impact |
|---|----------|---------|-------------|-------------|
| 1 | **Withdrawal flow** | (A) Keep two-phase + cleanup + runbook  (B) Implement atomic RPC (insert withdrawal_request + ledger in one transaction) | **A** for this phase: document runbook and accept residual orphan risk; **B** only if product requires zero orphan guarantee. | If A: add runbook step and "orphan detection" query in docs. If B: add Phase 1 migration and WalletService refactor. |
| 2 | **admin_adjustment** | (A) Implement RPC branch + contract + restrict to service_role  (B) Scope out: document "not implemented" and leave enum only | **B** unless there is a concrete admin UX requirement. | If A: new migration, contract, and Phase 4 negative test. If B: document in DEVELOPER_GUIDE and close. |
| 3 | **Test environment for DB integration** | (A) Real Supabase (dev)  (B) Supabase local + seed  (C) Mock only (no real RPC for balance/replay) | **A or B** for idempotency/replay and RLS; **C** acceptable for unit only. | Plan must state: "DB integration tests require [dev Supabase | local + seed]"; fixture/reset contract if B. |

---

## B) Gate Status (Pass / Fail)

### Gate 0: Test Infrastructure Gate (required — plan is test-heavy)

- **Status:** ❌ FAIL
- **Reasons:**
  - No explicit test **directory** for wallet/ledger (`test/unit/wallet/`, `test/rls/ledger_*`).
  - No **fixture/manifest** for ledger tests (e.g. minimal user + account rows for balance/replay).
  - No **run commands** documented (e.g. `flutter test test/unit/wallet/`).
  - 04_TEST_PLAN does not specify **timeout/retry** for integration or RLS tests.
- **To pass:** Add Phase 0 steps: create `test/unit/wallet/`, document fixture contract and run commands, add timeout/retry policy for integration/RLS tests; then Gate 0 → PASS.

### Gate 1: Data/Contracts Gate

- **Status:** ❌ FAIL
- **Reasons:**
  - `p_meta` forensics **keys** not fixed (device_id vs session_id vs request_id); contract file does not exist yet.
  - admin_adjustment **caller role** and **required meta** not defined if implemented.
- **To pass:** Publish contract (`.TODO/` or 09 folder) with (1) `process_payment_event_ledger` params and (2) `p_meta` required/optional keys; if admin_adjustment in scope, add caller role and meta.

### Gate 2: Security Gate

- **Status:** ⚠️ CONDITIONAL PASS
- **Reasons:**
  - Ledger RLS (system-only, no direct insert) is stated but not yet **verified** by an automated or scripted check.
  - admin_adjustment branch, if added, must be restricted; not yet implemented.
- **To pass:** Add at least one RLS test (or scripted check) that INSERT into `ledger_lines` as authenticated fails; document result. If admin_adjustment is added, add negative test (authenticated must not call).

### Gate 3: Backend/API Gate

- **Status:** ❌ FAIL
- **Reasons:**
  - Live Supabase **scan** not done at plan time; RPC branch for `admin_adjustment` unknown.
  - Forensics **implementation** (where device_id/session_id come from in Flutter) not specified (core util vs platform channel).
- **To pass:** Execute Phase 1.0 (live scan); add explicit step for "forensics source" (e.g. `AppForensicsProvider` or existing session id) and where it is passed into LedgerService.

### Gate 4: UI/Integration Gate

- **Status:** ✅ PASS
- **Reasons:** No new screens required except optional admin; Wallet already uses ViewModels; no UI-before-data ordering issue.

### Gate 5: Release/QA Gate

- **Status:** ❌ FAIL
- **Reasons:**
  - No **smoke test list** (exact flows: Pay Booking, Approve Delivery, Withdraw) with expected outcomes.
  - No **flake/retry policy** or **artifact capture** for failing tests.
- **To pass:** Add smoke checklist (manual or automated) and document retry policy (e.g. integration tests: 1 retry, 30s timeout) and where failure artifacts are stored.

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix (exact steps) | Owner | Acceptance |
|-----|-------------------|--------------------|-------|------------|
| **No test harness/dir for ledger** | Tests will be ad-hoc or never written; no single place to run wallet/ledger tests. | Create `test/unit/wallet/`; add `ledger_service_test.dart` and `wallet_service_test.dart` stubs; document `flutter test test/unit/wallet/` in plan and README if needed. | Backend / QA | `flutter test test/unit/wallet/` exists and runs. |
| **p_meta forensics source undefined** | Implementer will guess; forensics may be empty or inconsistent. | Add step: "Define forensics source (e.g. session_id from auth, optional device_id from platform); add to LedgerService.submitPaymentEvent meta in one place; document keys in contract." | Backend | Contract lists keys; one test payment shows keys in journal_entries.meta. |
| **DB integration test environment undefined** | Tests will be written against wrong env or will flake. | Add step: "Define DB integration env: [dev Supabase | local]. If dev: document test user and reset/side-effect policy. If local: add seed/fixture manifest." | Backend / Infra | 04_TEST_PLAN or plan lists env and reset. |
| **Withdrawal decision not locked** | Two-phase vs atomic affects migration and WalletService; scope creep. | Lock Decision 1 (Withdrawal) before Phase 1: either "document two-phase + runbook" or "implement atomic RPC". | Product / Architect | Decision recorded in plan; subsequent steps match. |
| **RLS verification not automated** | Security gate relies on manual check; regressions possible. | Add at least one test or script: authenticated client attempts INSERT into ledger_lines; expect failure. Reuse pattern from `test/rls/`. | Backend / QA | RLS test exists and passes. |
| **No smoke checklist for release** | Release may ship with broken Pay/Approve/Withdraw. | Add "Smoke checklist" step before Phase 5: (1) Pay Booking → ledger lines created, (2) Approve Delivery → provider balance up, (3) Withdraw → request + ledger. | QA | Checklist in plan or doc; signed off before doc sync. |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|----------------|---------------|
| **Double-entry balance:** Sum of signed amounts per journal = 0. | DB constraint / RPC logic (existing); no direct insert. | Run balance-check SQL after any test that calls RPC; expect 0 rows. |
| **Ledger tables append-only; no user INSERT.** | RLS denies INSERT on ledger_lines and journal_entries for authenticated/anon. | RLS test: INSERT as user → fail. |
| **Single source of truth for user balance.** | Balance read from `vw_wallet_balances_user` only; no client-side balance cache that bypasses it. | Code review + test: balance after event matches view. |
| **Idempotency: same key → same result.** | RPC uses idempotency_key; unique constraint on journal_entries. | Unit test: same entity+event → same key; integration: call RPC twice with same key → second returns success or replay, no duplicate lines. |
| **Status transitions and ledger are atomic.** | Entity status update and ledger write in same RPC (existing). | No code path that updates status without calling ledger; review + test. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|--------------|------------|----------|
| Live DB drift vs docs | Phase 1.0 | Med | Med | Feature | RPC or column missing in scan | Run scan first; reconcile additively | Document drift; do not drop/rename |
| Withdrawal orphan rows | WalletService two-phase | Med | Low | Feature | Orphan withdrawal_requests with status=requested | Runbook + optional cron to mark stale | Manual or script to set failed |
| Forensics empty in production | LedgerService meta | Low | Med | App-wide audit | Sample journal_entries.meta null/empty | Contract + unit test that meta is passed | Backfill not in scope; fix forward |
| RLS regression (user can insert ledger) | Ledger RLS | Low | High | Security-breach | RLS test fails | RLS test in CI; no GRANT INSERT to authenticated | Revoke + patch; audit logs |
| Test flakiness (integration) | DB integration tests | Med | Low | Local | CI red or skip | Timeout/retry policy; deterministic seed | Retry once; capture logs; fix env |
| admin_adjustment misuse | If implemented | Low | High | Data-loss | Audit log / alert | service_role only; contract | Revoke; investigate |

---

## F) Pre-Mortem (How this fails in real life)

- **This fails when** tests are written but never run in CI because no test directory or run command was agreed → Gate 0 fix.
- **This fails when** forensics keys are not defined and the app ships with empty meta → contract + forensics source step.
- **This fails when** withdrawal is left "optional" and two-phase cleanup fails in production, leaving orphan rows and no runbook → Decision 1 + runbook.
- **This fails when** RLS is only "manually verified" and a later migration grants INSERT by mistake → RLS automated test.
- **This fails when** DB integration tests hit real DB with wrong user or no reset and cause cross-test pollution → fixture/env step.
- **This fails when** release is cut without running Pay Booking + Approve Delivery + Withdraw once → smoke checklist.
- **This fails when** admin_adjustment is implemented without restricting to service_role and a client calls it → contract + negative test.

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|-----------------|-----------------|
| Test infra for wallet/ledger | Gate 0 pass; one place for ledger tests | Create `test/unit/wallet/`; add stub files for LedgerService and WalletService; document run command | `test/unit/wallet/ledger_service_test.dart`, `wallet_service_test.dart`; plan or README line | `flutter test test/unit/wallet/` runs (stubs can skip or pass) |
| Forensics contract and source | Gate 1; no ambiguous meta | Write contract (`.TODO/` or 09): p_meta keys (e.g. session_id, request_id); decide source in app (auth session, optional device); add to LedgerService | Contract file; LedgerService passes meta from single source | Contract in repo; one test payment has meta in DB |
| DB integration env and fixture | Deterministic integration tests | Document: "Ledger DB tests use [dev Supabase \| local]"; if dev: test user + "no destructive reset"; if local: seed manifest | 04_TEST_PLAN update or plan appendix | Env and reset policy written |
| Withdrawal decision | No scope creep | Product/Architect choose: (A) two-phase + runbook or (B) atomic RPC; record in plan | Plan section "Decisions" with Decision 1 outcome | All withdrawal steps align with choice |
| RLS automated check | Gate 2 pass | Add test (e.g. in `test/rls/`) that as authenticated user, INSERT into ledger_lines fails | `test/rls/ledger_rls_test.dart` or extend existing | Test in CI; passes |
| Smoke checklist | Gate 5 pass | Add to plan: "Pre-release smoke: (1) Pay Booking → ledger rows, (2) Approve Delivery → balance, (3) Withdraw → request + ledger" | Plan section or DEVELOPER_GUIDE | Checklist executed before release |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Preconditions, Decisions, Test Infra

**Goal:** Lock decisions, contracts, and test foundation so later phases do not rework.

**Why:** Prevents wrong ordering (e.g. implementing withdrawal RPC before deciding two-phase vs atomic) and test flakiness (no harness).

**How:**

0.1 **Decisions (blocking)**  
- [ ] (@Architect) Lock **Withdrawal**: (A) Two-phase + runbook + orphan query in docs, or (B) Atomic RPC. Record in plan.  
- [ ] (@Architect) Lock **admin_adjustment**: (A) Implement RPC branch + contract + service_role only, or (B) Scope out and document. Record in plan.  
- [ ] (@Architect) Lock **DB test env**: Dev Supabase vs local; document test user and reset/side-effect policy.

0.2 **Contract**  
- [ ] (@APIContract) Create contract file (e.g. `.TODO/improvement_the_system/ImplementReady/09_ledger-event-flow/CONTRACT_ledger_event_flow.md`): `process_payment_event_ledger` params; `p_meta` forensics keys (required: e.g. session_id or request_id; optional: device_id); if admin_adjustment in scope: caller role, required meta, idempotency.

0.3 **Test infrastructure**  
- [ ] (@Sentinel) Create `test/unit/wallet/`; add `ledger_service_test.dart` (idempotency key deterministic; submitPaymentEvent params); add `wallet_service_test.dart` (getWalletBalance with mocked view).  
- [ ] (@Sentinel) Document run: `flutter test test/unit/wallet/`.  
- [ ] (@Sentinel) Document integration/RLS: timeout (e.g. 30s) and retry (e.g. 1) for ledger integration tests; where failure logs go.

**GATE CHECK 0:** Contract exists; Decisions 1–3 recorded; `flutter test test/unit/wallet/` runs; timeout/retry documented. If any FAIL → block Phase 1.

---

### Phase 1: Data & Security (DB + RLS + Contracts)

**Goal:** Align with live DB; additive schema only; security verified.

**Why:** Prevents building on wrong schema or leaking writes.

**How:**

1.0 **Live Supabase confirmation (mandatory)**  
- [ ] (@Supabase_Ops) Supabase MCP (or equivalent): list tables `accounts`, `journal_entries`, `ledger_lines`; columns and enums; RPC signature `process_payment_event_ledger`; RLS on ledger tables (no INSERT for anon/authenticated).  
- [ ] (@Supabase_Ops) Check `payment_event_type_enum` for `admin_adjustment`; check if current RPC has branch for it.  
- [ ] (@Supabase_Ops) Record drift (if any) in Evidence section; no drops/renames.

1.1 **Schema (additive only)**  
- [ ] (@Supabase_Ops) If admin_adjustment chosen and RPC branch missing: migration adding only that branch; restrict execution to service_role (or admin).  
- [ ] (@Supabase_Ops) If withdrawal = atomic: add RPC that creates withdrawal_request + ledger in one transaction; document.  
- [ ] (@Supabase_Ops) Else: no new migration for withdrawal; document two-phase + runbook + orphan query.

1.2 **RLS**  
- [ ] (@Supabase_Ops) Ledger tables remain system-only. If admin_adjustment branch added: RPC executable by service_role only (no GRANT to authenticated).  
- [ ] (@Sentinel) Add RLS test or script: authenticated INSERT into `ledger_lines` → must fail. File: e.g. `test/rls/ledger_rls_test.dart`.

1.3 **Migration execution**  
- [ ] (@DataMigration) Apply any new migration in target env.  
- [ ] (@Sentinel) Smoke: one existing ledger flow still works (e.g. escrow_hold or balance read).

**GATE CHECK 1:** Live scan done; drift recorded; RLS test passes; migrations applied and smoke OK. If FAIL → block Phase 2.

---

### Phase 2: App Layer (MVVM)

**Goal:** Forensics in meta; WalletService aligned with withdrawal decision; no UI → Supabase.

**Why:** Observability and correctness; MVVM preserved.

**How:**

2.1 **Forensics source**  
- [ ] (@Architect) Implement single source for forensics (e.g. session_id from auth, optional device_id); pass into LedgerService.submitPaymentEvent meta for every call.  
- [ ] (@Architect) Ensure journal_entries.meta receives p_meta (RPC already merges); no PII in logs.

2.2 **WalletService**  
- [ ] (@Architect) If withdrawal = atomic RPC: switch to it; remove two-phase cleanup.  
- [ ] (@Architect) If withdrawal = two-phase: keep current flow; add runbook and orphan query to docs (in Phase 5).

2.3 **ViewModels**  
- [ ] (@Architect) No change unless admin_adjustment implemented (then admin-only ViewModel).

2.4 **Observability**  
- [ ] (@Observability) Confirm LedgerService logs (e.g. tag, idempotency_key) and no sensitive data; correlation usable.

**GATE CHECK 2:** Forensics keys in contract present in one test payment row; WalletService behavior matches decision; no direct Supabase in UI. If FAIL → block Phase 3.

---

### Phase 3: UI

**Goal:** No regression; optional admin screen only if admin_adjustment in scope.

**How:**

- [ ] (@Pixel) If admin_adjustment implemented: wire admin-only screen to ViewModel only; loading/error states.  
- [ ] (@Pixel) Else: no UI change.

**GATE CHECK 3:** Wallet flows (balance, withdraw) stable; no perf regression. If FAIL → block Phase 4.

---

### Phase 4: QA + Security

**Goal:** Contract compliance; security and RLS; functional and smoke checks.

**How:**

4.1 **Contract + migration**  
- [ ] (@Sentinel) Flutter meta and RPC p_meta match contract; one test payment shows forensics in journal_entries.meta.  
- [ ] (@Sentinel) If new migration: run balance-check query (0 unbalanced journals).

4.2 **Security**  
- [ ] (@Sentinel) RLS test: user cannot INSERT ledger_lines/journal_entries.  
- [ ] (@Sentinel) vw_wallet_balances_user: only auth.uid() rows.  
- [ ] (@Sentinel) If admin_adjustment: negative test that authenticated cannot call.

4.3 **Functional**  
- [ ] (@Sentinel) Unit: LedgerService idempotency deterministic; submitPaymentEvent params; WalletService getWalletBalance mocked.  
- [ ] (@Sentinel) DB integration (or manual): idempotency replay; insufficient funds; balance check query 0 rows.  
- [ ] (@Sentinel) **Smoke checklist:** (1) Pay Booking → ledger lines created, (2) Approve Delivery → provider balance up, (3) Withdraw → request + ledger (or runbook step).

4.4 **Observability**  
- [ ] (@Sentinel) Logs have expected tags; p_meta in DB; no PII leak.

**GATE CHECK 4:** All above pass; smoke checklist executed. If FAIL → block Phase 5.

---

### Phase 5: Documentation & Release

**Goal:** Docs match code and live DB; release gate passed.

**How:**

- [ ] (@SlineDocs) Update DEVELOPER_GUIDE (Finance & Payment Ledger): link 06_DIAGRAM_FINAL, 03_RISK_REGISTER; p_meta forensics; admin_adjustment if in scope.  
- [ ] (@SlineDocs) Update Wallet_Feature.md: event types and flow match diagram; test plan and run commands.  
- [ ] (@SlineDocs) Update SUPABASE_SETUP.md if new RPC/enum.  
- [ ] (@SlineDocs) If two-phase withdrawal: add runbook and orphan detection query to docs.

**GATE CHECK 5:** Docs updated; smoke checklist signed off; no destructive migrations. If FAIL → do not release.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- Test infrastructure not explicit (no wallet test dir, no run command, no timeout/retry).
- p_meta forensics keys and source undefined; contract missing.
- Withdrawal and admin_adjustment left "optional" without a binding decision.
- DB integration environment and fixture/reset not defined.
- RLS verification only manual; no automated test.
- No smoke checklist for release; no flake/retry policy.
- Gates not evaluated; ordering and stop conditions not strict.

### 2) Added steps

- Phase 0: Decisions (withdrawal, admin_adjustment, DB test env); contract file; test dir `test/unit/wallet/` and stubs; run command and timeout/retry.
- Phase 1: RLS automated test (INSERT ledger_lines as user → fail).
- Phase 4: Smoke checklist (Pay Booking, Approve Delivery, Withdraw).
- Sections A–G (Assumptions, Gates, Gaps, Invariants, Risk Register, Pre-Mortem, Plan Fixes).

### 3) Removed steps

- None; original phases retained but reordered and tightened.

### 4) Reordered steps

- **Before:** Phase 0 (Spec Lock, Threat Model, Contracts, Migration, Feature Flag) then Phase 1 (DB).  
- **After:** Phase 0 includes **Decisions** and **Test infra** first; **Contract** is a concrete artifact (file path); then Phase 1 with **Live scan** and **RLS test** before any new migration.

### 5) Expanded steps

- "Contracts" → explicit contract file path and required keys (p_meta, admin_adjustment if any).
- "Tests from 04_TEST_PLAN" → concrete test files, directory, run command, timeout/retry.
- "Withdrawal" → decision table (A vs B) and runbook/orphan query if A.
- "Verify (@Sentinel)" → **GATE CHECK** per phase with block condition.

### 6) Why (short, practical)

- Decisions first avoid rework (withdrawal, admin_adjustment, test env).
- Test infra first avoids untestable or flaky tests.
- Contract and RLS test make security and forensics verifiable.
- Gate checks prevent fake progress (e.g. implementing before scan).

### 7) Residual risks

- Withdrawal orphans if two-phase and cleanup fails (mitigated by runbook, not eliminated).
- Integration tests may still flake if DB env is shared or unstable (timeout/retry and env doc reduce only).
- admin_adjustment, if implemented, requires ongoing access control review.

---

## Mandatory Critique Checklist (Failures Found)

- **3.1 Scope & Requirements:** Goal was measurable but edge cases (orphan withdrawal, replay) were not fully defined → added Decision table and runbook.
- **3.2 Dependencies & Ordering:** Original plan had contracts "in Phase 0" but no contract artifact; DB scan could be skipped → contract file and Live scan made explicit first steps; GATE CHECKs enforce order.
- **3.3 Data Model & Contracts:** DTO/contract boundaries for p_meta were vague → contract with required/optional keys added; forensics source step added.
- **3.4 Security (RLS + AuthZ):** RLS was "verify" only, no automated test → RLS test step and Gate 2 fix added; admin_adjustment restriction called out.
- **3.5 Performance & Scalability:** No failure; ledger is single-RPC, no N+1 in scope.
- **3.6 Error Handling & Observability:** Forensics and correlation were underspecified → contract + observability validation step; LedgerService already logs.
- **3.7 UX & State Machine:** Double submit (idempotency) covered; withdrawal failure UX not detailed → runbook covers orphan state.
- **3.8 Testing & QA:** **Failures:** No test directory for wallet/ledger; no fixture/manifest for DB integration; no timeout/retry; no smoke checklist; no single-behavior test discipline stated → Gate 0, test infra steps, smoke checklist, and timeout/retry doc added.
- **3.9 Release & Migration Safety:** Rollback was stated; feature flag optional → no change; additive-only enforced.
- **3.10 Developer Workflow:** Branch/review/DoD not specified → assumed existing; doc update step is in Phase 5.

---

## References (unchanged)

- `Sline_everything/DEVELOPER_GUIDE.md`, `Wallet_Feature.md`, `SUPABASE_SETUP.md`, `STRUCTURE.md`, `MVP_ROADMAP.md`
- `.TODO/improvement_the_system/ImplementReady/09_ledger-event-flow/` (00–07, 04_TEST_PLAN, 06_DIAGRAM_FINAL, 03_RISK_REGISTER)
- `lib/features/wallet/services/ledger_service.dart`, `wallet_service.dart`, `data/wallet_repository.dart`
- `supabase/migrations/` (and Archive); test helpers: `test/helpers/mock_supabase.dart`, `test/helpers/ledger_rpc_invoker.dart`
- Live Supabase scan at execution: MCP `list_tables`, `execute_sql` for ledger objects and RPC.
