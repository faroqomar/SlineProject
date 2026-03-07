# Plan Critic: Escrow Invariants & Idempotency (16_escrow-invariants-idempotency)

**Source plan:** `.TODO/PLAN_EscrowInvariantsIdempotency_2026-03-07.md`  
**Workflow:** `.agents/workflows/plan_critic.md`  
**Date:** 2026-03-07

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (inferred)

- Live `rpc_approve_delivery` body matches or is derived from `supabase/migrations/Archive/20260224_fix_rpc_approve_delivery_digest_schema.sql` (booking branch uses `now()` in digest; task branch has no ledger call).
- `process_payment_event_ledger` on idempotent hit returns existing journal id and does not raise; caller `rpc_approve_delivery` does not re-raise, so app sees success on replay.
- Only entry point for approval is `WorkManagementService.approveDelivery` → `rpc_approve_delivery`; no other callers (e.g. edge functions) for this flow.
- Test runs can be performed in dev/staging Supabase (no production-only verification).
- Single developer or small team; no formal branch strategy mandated unless project rules require it.

### Decision Needed (Blocking)

| # | What is missing | Options | Recommended | What changes in plan |
|---|-----------------|--------|-------------|----------------------|
| 1 | **FOR UPDATE** in `rpc_approve_delivery`: mandatory or optional? | A) Mandatory — add `SELECT ... FOR UPDATE` at start of releasable branch. B) Optional — rely only on stable key + unique constraint. | **A) Mandatory.** Serializes concurrent calls at row level; minimal code; eliminates race where two transactions read same status and both proceed to ledger. | Plan must include one concrete migration step: "Add FOR UPDATE on entity row before reading status and generating key." Remove "optional" wording. |
| 2 | **Pre-flight check** (existing `release_with_fee` journal entry for entity): mandatory or optional? | A) Mandatory — add SELECT before ledger call. B) Optional — rely on unique key + FOR UPDATE. | **B) Optional.** Redundant with idempotency key + unique constraint; adds extra query. Keep as optional in corrected plan. | No change to execution order; leave as optional hardening. |
| 3 | **T1/T2 execution**: how and where are idempotency and concurrency tests run? | A) SQL script in Supabase SQL editor (runbook). B) Dart integration test in repo. C) Manual only (no artifact). | **A or B.** Prefer B if test infra exists; else A with runbook in `.TODO/` or `docs/`. | Plan must add a step: "Define T1/T2 execution (artifact + run command or runbook)." Release gate blocks until T1 passes. |
| 4 | **UI debounce** (one-shot guard in `ReviewDeliveryModal`): mandatory or optional? | A) Mandatory. B) Optional (backend idempotency sufficient). | **B) Optional.** Backend is authority; debounce is defense-in-depth. | Leave optional; no gate dependency. |

---

## B) Gate Status (Pass / Fail)

| Gate | Status | Reason | What to add/fix to pass |
|------|--------|--------|-------------------------|
| **1) Data/Contracts** | ❌ FAIL | Live `rpc_approve_delivery` body and `journal_entries` indexes not confirmed. Key formula not yet committed as contract. | Run Phase 1.0 (live Supabase scan). Document exact key formula in contract (SUPABASE_SETUP or `.TODO/` contract). |
| **2) Security** | ✅ PASS | RLS unchanged; SECURITY DEFINER with client_id = auth.uid(); no new privileges; T4 (bypass) in test plan. | None. |
| **3) Backend/API** | ❌ FAIL | Migration not written; FOR UPDATE and key formula not in a single executable step; "optional" leaves behavior undefined. | Write migration with stable key + FOR UPDATE. Drop optional wording for FOR UPDATE. |
| **4) UI/Integration** | ✅ PASS | UI change is optional; existing wiring (ReviewDeliveryModal, WorkManagementService) is sufficient for idempotency. | None for gate; optional debounce can be post-release. |
| **5) Release/QA** | ❌ FAIL | T1/T2 execution path not defined; no runbook or test file; no explicit "run T1 before release" gate. | Add step: produce T1/T2 artifact (SQL runbook or Dart test) and run T1; block release until T1 passes. |

**Verdict:** Execution blocked until Data/Contracts, Backend/API, and Release/QA gates pass (fixes below).

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix (exact steps) | Owner | Acceptance check |
|-----|-------------------|--------------------|--------|-------------------|
| T1/T2 not executable | QA will not run idempotency tests; regression can ship. | Add step: "Produce T1/T2 execution artifact." Option A: SQL runbook (steps + expected row counts) in `.TODO/improvement_the_system/ImplementReady/16_escrow-invariants-idempotency/` or `docs/`. Option B: Dart integration test that creates booking in delivered/held, calls RPC twice, asserts single journal_entry. Document run command (e.g. `flutter test integration_test/escrow_idempotency_test.dart` or "Run SQL in Supabase as in RUNBOOK_T1_T2.md"). | Backend + Sentinel | Artifact exists; run command documented; T1 run once and passes. |
| FOR UPDATE left "optional" | Two concurrent requests may both read status, both generate same key; one INSERT wins, one hits unique_violation. Handler returns existing — correct. But without FOR UPDATE, both do full work up to INSERT; no functional bug but wasted work and unclear "required" behavior. | Make FOR UPDATE a required migration step: "In `rpc_approve_delivery`, for booking branch with payment_status = 'held', add at start of branch: lock entity row (e.g. SELECT id FROM bookings WHERE id = entity_id FOR UPDATE). Use locked row for status/payment_status read if re-reading." | Supabase_Ops | Migration includes FOR UPDATE; applied on dev; T2 (concurrent) run and one succeeds, one gets handled unique_violation or success. |
| RPC return on replay unspecified | If `process_payment_event_ledger` throws on unique_violation instead of returning existing id, app will show error on retry and user will think approval failed. | Add verification step: "Confirm in DB that on idempotent key collision, `process_payment_event_ledger` returns existing journal id (ok: true) and does not raise. Confirm `rpc_approve_delivery` does not re-raise in that path." If it raises, add plan step to change handler to return instead of raise. | Supabase_Ops + Sentinel | Replay call returns success to client; no exception. |
| No GATE CHECK between phases | Executor may run Phase 2 before Phase 1 complete; drift or wrong order. | Add at end of each phase a "GATE CHECK" box: concrete conditions that must hold before starting next phase. | Planner / Sentinel | Each phase ends with "GATE CHECK: [list]; proceed only if all true." |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|-----------------|---------------|
| At most one successful release (journal_entry with event_type = 'release_with_fee') per entity (task/booking) in releasable state. | Stable idempotency key (entity_id + immutable context); UNIQUE on `journal_entries.idempotency_key`; FOR UPDATE on entity row before key gen. | T1: second call creates no new journal_entry/ledger_lines. Query: `SELECT COUNT(*) FROM journal_entries WHERE related_entity_type = 'booking' AND related_entity_id = :id AND event_type = 'release_with_fee'` = 1 after two calls. |
| Only the client (owner) can approve delivery. | `rpc_approve_delivery` SECURITY DEFINER checks client_id = auth.uid() for task/booking. | T4: call as non-owner; must fail. RLS tests (allowed/forbidden) if present. |
| Status transitions: release only when status = delivered and (for booking) payment_status = held. | RPC guards at start of releasable branch. | T4 and existing E2E: cannot approve when not delivered or not held. |
| Ledger balance: sum of ledger_lines per journal_entry balances (DR = CR). | DB constraint / process_payment_event_ledger logic (existing). | No new constraint; existing ledger tests remain. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|--------------|------------|----------|
| Live DB differs from Archive migration (different function body or extra indexes) | Phase 1.0 | Med | High | Feature | Migration fails or wrong object changed | Mandatory live scan before writing migration | Save current function def; compare with Archive; reconcile. |
| Typo in key formula (e.g. wrong variable, still using now()) | Migration 1.1 | Low | High | Data integrity | T1 fails (two rows for same entity) | Code review; T1 run before merge | Revert migration; redeploy previous function. |
| Idempotent replay returns error to app | process_payment_event_ledger / rpc_approve_delivery | Med | Med | UX (user sees error on retry) | User report; E2E retry shows error | Verify return-on-replay in Phase 1; add test | Fix RPC to return success on replay. |
| T1/T2 never run, regression ships | Release/QA | Med | High | App-wide | Post-release double-release report | Gate 5: block release until T1 run and passed | Run T1 post-release; if fail, revert migration. |
| Concurrent calls: both succeed (double release) | Without FOR UPDATE or with key bug | Low | High | Data-loss | Duplicate journal_entries for same entity | FOR UPDATE + stable key; T2 run | Revert; fix key/FOR UPDATE; compensate if needed. |
| Docs not updated; next dev reintroduces now() | Diagram / SUPABASE_SETUP | Med | Low | Local/Feature | Code review catches digest(..., now()) | Phase 5 mandatory doc update; diagram shows formula | Doc update in follow-up PR. |

---

## F) Pre-Mortem (How this fails in real life)

- **This fails when** the live function body is not the one from Archive and the migration assumes wrong starting point, so the patch applies to the wrong branch or misses a second definition. → **Gate 1 + Phase 1.0.**
- **This fails when** FOR UPDATE is not added and two users (or one user with two tabs) approve the same delivery concurrently; both get same key and one INSERT wins, one hits unique_violation — correct. But if the handler were to raise, the second user would see an error. → **Verify replay returns success; add FOR UPDATE.**
- **This fails when** T1 is never run and a typo in the key formula (e.g. still using `now()`) ships; first retry causes double release. → **Define T1 artifact and block release on T1 pass.**
- **This fails when** the app treats idempotent replay as an error and shows "Approval failed" on retry, so the user tries again or contacts support. → **Verify RPC returns success on replay.**
- **This fails when** documentation is not updated and a future change reintroduces `now()` in the digest. → **Mandatory doc update in Phase 5; diagram shows exact formula.**
- **This fails when** task path is accidentally given a key or ledger call (task has no ledger in current design); duplicate or wrong logic. → **Invariant: task branch unchanged; only booking branch with payment_status = 'held' gets key + ledger.** Explicit step in migration: "Do not modify task branch."

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|------------------|----------------|
| Lock execution order and pass Gate 1 | Avoid migrating against wrong schema. | Run live Supabase scan; document current `rpc_approve_delivery` body and all indexes on `journal_entries`. | Execution log or snippet in `.TODO/` with current function def and index list. | Scan done; contract (key formula) written; Gate 1 PASS. |
| Make FOR UPDATE required | Eliminate ambiguity; serialize concurrent approval. | In migration: for booking branch when payment_status = 'held', add `SELECT id, status, payment_status FROM bookings WHERE id = entity_id FOR UPDATE` (or equivalent) before generating key and calling ledger. Use locked row for key input. | Migration SQL. | Migration includes FOR UPDATE; applied; T2 run. |
| Make T1/T2 runnable and gate release | Prevent shipping without idempotency proof. | Create runbook (SQL steps for T1 and T2) or Dart integration test. Document: "Run T1 before release; T2 recommended." | `RUNBOOK_EscrowIdempotency_T1_T2.md` or `integration_test/.../escrow_idempotency_test.dart` + README run command. | Artifact exists; run command documented; T1 executed and passed. |
| Verify replay returns success | Avoid user-visible error on retry. | Read `process_payment_event_ledger` and `rpc_approve_delivery`; confirm on unique_violation handler they return (ok, existing_id) and do not raise. If they raise, add step to change to return. | Verification note in execution log or test. | Replay call from app returns success; no throw. |
| Add GATE CHECK after each phase | Enforce dependency order; no fake progress. | After each phase, add block: "GATE CHECK: [list]. Do not proceed until all true." | Corrected plan Section H. | Each phase has explicit gate check. |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Plan: Escrow Invariants & Idempotency — Execution-Ready

**Goal:** Escrow release is idempotent under retry and concurrency: stable server-side idempotency key, FOR UPDATE serialization, tests run and passing, docs updated.

**Why:** Current key uses `now()`, so retries get different keys and the UNIQUE constraint does not prevent double release. System is currently safe only via status gates; key + FOR UPDATE make it robust and verifiable.

**Result:** One migration (stable key + FOR UPDATE + optional index drop); T1/T2 artifact and run; diagram and SUPABASE_SETUP updated; no duplicate ledger entries on retry or concurrency.

---

### Phase 0: Decisions & Gates (Blocking)

**Goal:** Resolve blocking decisions and confirm gates.

**Why:** Without decisions, FOR UPDATE and test execution are ambiguous; gates block unsafe progress.

**How:**

1. **Decision 1 (FOR UPDATE):** Adopt Option A — FOR UPDATE mandatory in migration (see G).
2. **Decision 2 (Pre-flight):** Keep optional; do not add to mandatory steps.
3. **Decision 3 (T1/T2):** Choose runbook (SQL) or Dart integration test; assign owner to produce artifact (see G).
4. **Decision 4 (UI debounce):** Optional; not required for release.

**Result:** Decisions recorded; executor knows what to implement.

**GATE CHECK (Phase 0):** Decisions 1 and 3 recorded; Gate 1 (Data/Contracts) and Gate 5 (Release/QA) fixes are in the plan. Proceed only if yes.

---

### Phase 1: Data / Contracts

**Goal:** Confirm live DB state and lock contract for idempotency key.

**Why:** Prevents migrating against wrong function body or missing index.

**How:**

1. **(1.0) Live Supabase confirmation (mandatory)**  
   - Run Supabase MCP or SQL: list function body for `rpc_approve_delivery`; list indexes on `journal_entries` (especially `idempotency_key`).  
   - Record in execution log: current digest expression (expect `now()` in booking branch); list of index names.  
   - Confirm no conflicting migration in flight.

2. **(1.1) Contract**  
   - Document exact key formula: `encode(extensions.digest(entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status, 'sha256'), 'hex')` for booking branch only; task branch unchanged.  
   - Add to SUPABASE_SETUP or `.TODO/` contract sheet.

**Result:** Scan done; contract written; Gate 1 passable.

**GATE CHECK (Phase 1):** Live scan completed; current function body and indexes recorded; key formula documented. Proceed only if all true.

---

### Phase 2: Security (Confirm Only)

**Goal:** Confirm no new security surface; RLS and auth unchanged.

**Why:** Escrow release must remain client-only; no new privileges.

**How:**

1. Confirm `rpc_approve_delivery` remains SECURITY DEFINER with same auth checks (client_id = auth.uid()).
2. Confirm no new RLS policies or grants for this change.
3. Confirm T4 (bypass attempt) is in test plan and will be run.

**Result:** Security unchanged; Gate 2 remains PASS.

**GATE CHECK (Phase 2):** No RLS/auth change; T4 in scope. Proceed only if true.

---

### Phase 3: Backend / API (Migration)

**Goal:** Deploy stable key and FOR UPDATE; drop duplicate index if present.

**Why:** Idempotency and serialization live in DB.

**How:**

1. **(3.1) Save current function**  
   - `SELECT pg_get_functiondef('public.rpc_approve_delivery(text,uuid)'::regprocedure)` (or equivalent); save to execution log or file for rollback.

2. **(3.2) Migration: stable key + FOR UPDATE**  
   - Create migration (e.g. `YYYYMMDD_escrow_idempotency_stable_key.sql`).  
   - In `rpc_approve_delivery`, **booking branch only** when `payment_status = 'held'`:  
     - Add: `SELECT id, status, payment_status FROM bookings WHERE id = entity_id FOR UPDATE` (reuse existing read if already locked; ensure FOR UPDATE before key gen).  
     - Replace idempotency key with: `encode(extensions.digest(entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status, 'sha256'), 'hex')`.  
   - Do **not** change task branch (no ledger call).

3. **(3.3) Verify replay behavior**  
   - Confirm `process_payment_event_ledger` on idempotent key collision returns existing journal id and does not raise; confirm `rpc_approve_delivery` does not re-raise. If it raises, add migration step to return instead.

4. **(3.4) Index cleanup**  
   - If live DB has duplicate index on `journal_entries.idempotency_key` (e.g. `idx_journal_entries_idempotency`), add `DROP INDEX IF EXISTS ...` in same migration. Keep constraint `uq_journal_entries_idempotency_key`.

5. **Apply migration** on dev/staging.

**Result:** Migration applied; stable key and FOR UPDATE in place; Gate 3 passable.

**GATE CHECK (Phase 3):** Migration applied; function body contains no `now()` in digest and contains FOR UPDATE for booking branch; replay returns success. Proceed only if all true.

---

### Phase 4: UI (Optional)

**Goal:** Optional defense-in-depth: one-shot debounce on Approve button.

**Why:** Reduces double-tap RPC; backend remains authority.

**How:**

1. In `lib/features/work/view/widgets/review_delivery_modal.dart`: add `_hasApproved` guard in state; in handler that calls `onApprove`, if `_hasApproved` return; set `_hasApproved = true` before async call; on catch, set `_hasApproved = false` to allow retry.

**Result:** Optional; not required for Gate 4 or release.

**GATE CHECK (Phase 4):** N/A or "Optional step done if chosen." Proceed to Phase 5.

---

### Phase 5: QA & Release

**Goal:** T1 (idempotent replay) and T2 (concurrent) run; T4 (bypass) run; E2E smoke; release unblocked only when T1 passes.

**Why:** Proof of idempotency and no regression.

**How:**

1. **T1 (mandatory):** Run T1 using runbook or Dart test. Steps: create/set booking in delivered/held; call `rpc_approve_delivery` twice; assert exactly one `journal_entry` (and corresponding `ledger_lines`) for that entity with event_type `release_with_fee`. Document result.

2. **T2 (recommended):** Run T2 (concurrent calls); expect one success and one handled unique_violation or success (no double release).

3. **T4:** Run T4 (bypass: already completed); expect RPC to reject or no-op.

4. **E2E:** Manual or automated: approve delivery once from app; verify completed and balance; retry from UI; verify no duplicate credit and no error (replay success).

**Result:** T1 passed; T2/T4/E2E run; Gate 5 passable.

**GATE CHECK (Phase 5):** T1 run and passed; T2/T4/E2E run; no double release observed. Proceed to Phase 6 only if true.

---

### Phase 6: Documentation & Release

**Goal:** Diagram and SUPABASE_SETUP match implementation; release.

**Why:** Next developer must see correct key formula and behavior.

**How:**

1. Update `Sline_everything/AppDigram/All_Diagrams/16_escrow-invariants-idempotency.md`: diagram and evidence table show key formula without `now()`; verification date and result.
2. Update `Sline_everything/SUPABASE_SETUP.md`: `rpc_approve_delivery` section documents stable key formula and FOR UPDATE.
3. Optional: DEVELOPER_GUIDE note that escrow release is idempotent under retry.

**Result:** Docs match code and DB; release approved.

**GATE CHECK (Phase 6):** Doc updates merged; diagram and SUPABASE_SETUP reflect stable key and FOR UPDATE. Release complete.

---

### Acceptance Criteria (Non-Negotiable)

- Second `rpc_approve_delivery` call for same entity (releasable state) creates no additional `journal_entries` or `ledger_lines`.
- Diagram 16 and SUPABASE_SETUP show stable key (no `now()` in digest).
- E2E: approve once → completed and correct balance; retry → same outcome, no error.
- RLS/security: only client can approve; T4 passes.
- T1 executed and passed before release.

---

### Rollback Plan

- **DB:** Redeploy previous `rpc_approve_delivery` (saved in 3.1 or from Archive). No data migration to undo.
- **App:** If UI debounce added, revert that commit.
- **Emergency:** If double-release observed, revert RPC; investigate; re-deploy fixed function.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- FOR UPDATE and pre-flight were "optional" with no decision, so executor could skip FOR UPDATE.
- T1/T2 had no defined execution path (no artifact or run command); release could happen without running T1.
- RPC return behavior on idempotent replay was not verified (risk of app error on retry).
- No explicit GATE CHECK between phases; dependency order could be broken.
- No "Decision Needed" or Assumptions section; blocking choices were implicit.

### 2) Added steps

- **Phase 0:** Explicit decisions (FOR UPDATE mandatory; T1/T2 artifact type; pre-flight and UI debounce optional).
- **Phase 1:** Contract write (key formula) as separate step.
- **Phase 3:** Save current function before migration; verify replay return behavior; FOR UPDATE as mandatory migration step.
- **Phase 5:** T1 mandatory and run before release; T2/T4/E2E listed with run expectation.
- **GATE CHECK** at end of every phase with concrete conditions.
- **Plan Fixes (G):** Test artifact, FOR UPDATE requirement, replay verification, gate checks.

### 3) Removed steps

- None; optional steps (pre-flight, UI debounce) kept but marked optional.

### 4) Reordered steps

- Live Supabase scan (Phase 1.0) remains first in Phase 1; contract (1.1) immediately after.
- "Verify replay returns success" moved into Phase 3 (before Phase 5 run) so behavior is fixed before tests run.
- T1/T2 artifact production is a prerequisite to Phase 5 run (Decision 3 + G plan fix).

### 5) Expanded steps

- **Phase 1:** Scan now requires "record in execution log" and "document key formula in contract."
- **Phase 3:** Migration step now specifies FOR UPDATE exact pattern and "booking branch only; task branch unchanged."
- **Phase 5:** T1/T2/T4/E2E each have explicit pass condition and "run before release" for T1.

### 6) Why (short, practical)

- Decisions remove ambiguity so the same plan can be executed by different people.
- Gate checks prevent moving on with incomplete or wrong state.
- T1 as a release gate prevents shipping a broken key formula.
- FOR UPDATE is low-cost and reduces concurrency risk; making it mandatory is justified.

### 7) Residual risks

- **fee_rate_bps = 0** remains a business decision; not changed in this plan.
- If `process_payment_event_ledger` currently raises on unique_violation, a separate fix is required (captured in Gap 3 and Phase 3.3).
- Test infrastructure (Dart integration vs SQL runbook) depends on Decision 3; if runbook is chosen, flake/retry policy is minimal (manual run).

---

## Mandatory Critique Checklist — Failures Found

- **3.1 Scope & Requirements:** Goal is measurable (second call = no new ledger rows). Edge cases (retry, concurrent) defined. **PASS.** Non-goals stated. **PASS.**
- **3.2 Dependencies & Ordering:** Original plan had Phase 1 before UI/QA but did not enforce "no Phase 2 before Phase 1 complete." **FAIL** — fixed with GATE CHECKs.
- **3.3 Data Model & Contracts:** Key formula was not written as a contract artifact. **FAIL** — fixed with Phase 1.1 contract step.
- **3.4 Security:** No new RLS; SECURITY DEFINER unchanged. **PASS.**
- **3.5 Performance:** FOR UPDATE adds one row lock; acceptable. **PASS.**
- **3.6 Error Handling:** Replay return behavior was unspecified. **FAIL** — fixed with Phase 3.3 and Gap 3.
- **3.7 UX:** Double submit / retry covered by idempotency; optional UI debounce. **PASS.**
- **3.8 Testing & QA:** T1/T2 not executable (no artifact/run command). **FAIL** — fixed with Decision 3, Gap 1, Phase 5, and Plan Fixes. No test infra gate added (tests are SQL or single integration test; no new harness).
- **3.9 Release & Migration:** Rollback documented. **PASS.** No feature flag (correctness fix). **PASS.**
- **3.10 Developer Workflow:** Branch strategy and DoD per PR not in original plan. **Partial** — Corrected plan does not add branch strategy (assumed); DoD is implied by GATE CHECKs and acceptance criteria. Residual: add "Definition of Done for PR: migration applied on dev, T1 run and passed, docs updated" if team requires it.
