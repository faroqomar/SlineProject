# 📌 Plan: Work Contract Revisions (RPC Hardening) — Plan Critic Rewrite

**Source:** `.TODO/PLAN_WorkContractRevisions_2025-03-08.md`  
**Workflow:** `@.agents/workflows/plan_critic.md`  
**Date:** 2025-03-08

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (Inferred)

- **Stack:** Flutter + Supabase; MVVM; Provider; RPC SECURITY DEFINER. No change to stack.
- **Repo state:** Migration `20260305180100_work_revision_and_change_rpcs.sql` is the current RPC source; live DB may already have it applied. Columns `revisions_used` and `revisions_total` exist on both `tasks` and `bookings` (to be confirmed in Gate 1).
- **Exception contract:** Postgres RAISE EXCEPTION text is returned in PostgrestException message; ErrorMapper will use `message.contains('<substring>')` so exact wording can vary slightly (e.g. with error code prefix).
- **Test approach:** Manual SQL verification + manual E2E for UI; no new automated test harness in this plan unless Decision 2 chooses otherwise.
- **Idempotency:** Not in scope for this plan; double-submit mitigated by disabling the "Request revision" button while `_isLoading` is true (ViewModel already sets this).

### Decision Needed (Blocking)

| # | What decision is missing | Options | Recommended | What changes in plan |
|---|---------------------------|---------|-------------|----------------------|
| 1 | If live DB lacks `revisions_total` or `revisions_used` on `tasks` or `bookings` | (A) Add columns in same migration (B) Separate prerequisite migration (C) Block plan until columns exist | **(B)** Separate migration first; this plan then only replaces RPC. | Phase 1 adds explicit step: "If columns missing, create prerequisite migration and apply before RPC migration." |
| 2 | Automated tests for revision RPC and UI | (A) Manual-only (current) (B) Add DB unit tests (e.g. Supabase test helpers) (C) Add Flutter widget/unit test for ErrorMapper + revision error UI | **(C)** At least one Flutter test that mocks RPC throwing "No revisions remaining" and asserts UI shows mapped message. | Phase 4 adds concrete step: write test in `test/` that mocks service, triggers error, asserts displayed message. Gate 0 (Test Infra) passes if `flutter test` runs and test file exists. |

---

## B) Gate Status (Pass / Fail)

| Gate | Status | Reason | What to add/fix to pass |
|------|--------|--------|--------------------------|
| **0) Test Infrastructure** | ⚠️ CONDITIONAL | Plan does not require new harness; if Decision 2 = (C), need one test file and run command. | Add step: "Create `test/features/work/request_revision_error_mapping_test.dart` (or equivalent) that mocks WorkManagementService to throw PostgrestException with 'No revisions remaining', call ViewModel.requestRevision, assert error state or message contains expected string. Document: `flutter test test/features/work/...`." |
| **1) Data/Contracts** | ❌ FAIL | (1) Column existence on tasks/bookings not verified before writing migration. (2) Exception message strings not written as exact contract (ErrorMapper uses contains — acceptable but must be documented). | (1) Add Phase 1.0: Run live Supabase scan; if columns missing, add prerequisite migration and apply. (2) Add contract artifact: list exact exception messages in SUPABASE_SETUP and in plan so backend and app agree. |
| **2) Security** | ✅ PASS | RPC keeps SECURITY DEFINER and client check; new guards only tighten. No new RLS. | None. |
| **3) Backend/API** | ❌ FAIL | (1) COALESCE behavior when `revisions_total` is NULL: guard `COALESCE(revisions_used,0) >= COALESCE(revisions_total,0)` — if both NULL, 0>=0 → true → raise "No revisions remaining". That is correct. But if `revisions_total = 0` (explicit zero), same. Document. (2) Order of checks: client first, then status, then cap, then UPDATE — must be explicit in migration. | (1) Document in migration comment: "When revisions_total is NULL or 0, no revisions allowed." (2) In Phase 1.3, require: SELECT row, then IF client, IF status, IF cap, then UPDATE. |
| **4) UI/Integration** | ❌ FAIL | (1) ViewModel currently sets `_error = 'Failed to request revision'` on any exception — plan says "use ErrorMapper" but doesn't say replace this assignment. (2) UI must disable "Request revision" when `revisions_remaining == 0` using existing `revisionsTotal`/`revisionsUsed` to avoid unnecessary RPC call and better UX. | (1) Add step: "In requestRevision catch block, set _error = ErrorMapper.map(e)." (2) Add step: "In work item detail, hide or disable 'Request revision' when revisionsUsed >= revisionsTotal (and show 'No revisions left' if desired)." |
| **5) Release/QA** | ⚠️ CONDITIONAL | Manual E2E and manual SQL tests are specified; no rollback verification step. | Add step: "After rollback, verify RPC again allows infinite revisions (smoke check) so rollback is proven." |

---

## B.1) Mandatory Critique Checklist — Failures Found

- **3.1 Scope & Requirements:** Goal measurable ✅. Non-goals stated ✅. Edge cases (null note, network) mentioned; retries/double-submit only partially covered → **failure:** double-submit mitigation not explicit (fixed by relying on _isLoading + optional disable when 0 revisions).
- **3.2 Dependencies & Ordering:** No UI before data ✅. Migration path exists ✅. **Failure:** Column existence not confirmed before writing migration → fixed in Phase 1.0.
- **3.3 Data Model & Contracts:** No new tables ✅. **Failure:** Exception message contract not written as single source of truth → fixed in §Contract and Plan Fixes.
- **3.4 Security:** No new surface ✅. RLS unchanged ✅. Audit logs not in scope (residual risk, acceptable).
- **3.5 Performance:** N/A for single RPC ✅.
- **3.6 Error Handling:** Taxonomy and user-facing messages in plan. **Failure:** ViewModel did not explicitly use ErrorMapper in catch → fixed in Phase 3.2.
- **3.7 UX & State Machine:** **Failure:** Loading state exists but error message was generic; "disable when 0 revisions" not in original plan → fixed in Phase 3.3. Double-submit: button should be disabled while loading (already is) and when 0 remaining (added).
- **3.8 Testing & QA:** **Failure:** No automated test for revision error mapping; no fixture manifest (manual-only); no explicit rollback verification → fixed by adding optional Flutter test (4.4) and rollback verification (4.5). Test infra gate conditional on Decision 2.
- **3.9 Release & Migration:** Rollback plan present ✅. **Failure:** Rollback not verified by step → fixed in 4.5.
- **3.10 Developer Workflow:** Doc update in Phase 5 ✅. Branch/PR/DoD not specified (inferred: single feature branch, standard review).

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix (exact step) | Owner | Acceptance check |
|-----|-------------------|------------------|--------|-------------------|
| ViewModel does not use ErrorMapper on revision failure | User always sees "Failed to request revision" instead of "No revisions remaining" or "Can only request revision on delivered work". | In `WorkItemDetailsViewModel.requestRevision` catch block, set `_error = ErrorMapper.map(e)` (and optionally preserve stack for logger only). | Frontend/Architect | Run app, trigger limit/state error, confirm snackbar/dialog shows mapped message. |
| UI can call RPC when revisions already exhausted | Wasted call and confusing generic error. | In work item detail screen, when `revisionsUsed >= revisionsTotal`, disable "Request revision" and optionally show "No revisions left". | Frontend/Pixel | With 0 remaining, button disabled or hidden; no RPC call. |
| Migration does not enforce order of checks | If UPDATE ran before guards, state could be corrupted. | In new migration, for both task and booking: SELECT row into variable; check client; check status = 'delivered'; check revisions_used < revisions_total; then single UPDATE. | Backend/Supabase_Ops | Read migration SQL; no UPDATE before both IFs. |
| Column existence not confirmed before migration | Applying RPC that references revisions_total could fail if column missing. | Phase 1.0: list columns for tasks and bookings (Supabase MCP or SQL). If either column missing on either table, add prerequisite migration and apply first. | Backend/Supabase_Ops | Migration applies without error on target project. |
| Exception contract not written down | Backend might change message; app might expect different string. | Add "Contract" subsection in plan and in SUPABASE_SETUP: exact three messages. ErrorMapper uses contains(); document substrings. | APIContract/DocsKeeper | SUPABASE_SETUP and plan both list the three messages. |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|-----------------|---------------|
| Revision is allowed only when status = 'delivered'. | RPC: IF status <> 'delivered' THEN RAISE EXCEPTION before any UPDATE. | Manual SQL: call RPC for task/booking with status 'active' or 'completed'; must raise. |
| Revision count never exceeds contract cap (revisions_total). | RPC: IF COALESCE(revisions_used,0) >= COALESCE(revisions_total,0) THEN RAISE EXCEPTION before any UPDATE. | Manual SQL: set revisions_used = revisions_total, call RPC; must raise "No revisions remaining". |
| Only client (auth.uid() = client_id) can request revision. | Existing RPC check; unchanged. | Manual SQL: call as freelancer or other user; must raise. |
| On success, status becomes 'active', revisions_used increments by 1, delivered_at and review_expires_at cleared. | Existing UPDATE in RPC; unchanged. | Manual SQL: call as client on delivered row with revisions left; SELECT after; assert status, revisions_used, delivered_at, review_expires_at. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|-------------|-----------|----------|
| Live DB missing revisions columns | Migration apply | Low | High | Feature | Migration apply fails | Phase 1.0 scan; prerequisite migration | Add columns in separate migration |
| Double-click sends two RPCs | UI | Med | Med | Single user | Two "revision requested" toasts / two increments | Disable button while _isLoading (already set); optional idempotency later | Accept one extra revision consumed |
| Exception message format change | Postgres / driver | Low | Med | App-wide | User sees generic error | Contract doc + contains() in ErrorMapper | Update ErrorMapper when message format known |
| Rollback not tested | Ops | Med | Low | Feature | Post-rollback still broken | Add "Verify rollback" step: re-apply old RPC, smoke test | Document manual rollback SQL |
| Old app version calls new RPC | Compatibility | Low | Low | Old clients | Old app gets new errors when over limit | No backfill; acceptable | None |

---

## F) Pre-Mortem (How this fails in real life)

- **This fails when** the migration is applied to a project where `bookings` has no `revisions_total` column → RPC compilation or runtime error.
- **This fails when** the ViewModel is not updated to use ErrorMapper → users still see "Failed to request revision" after we add DB guards.
- **This fails when** the UI does not disable the button when revisions are exhausted → user taps, gets error, confusion.
- **This fails when** the migration checks are in wrong order (e.g. UPDATE before IF) → state corruption or cap bypass.
- **This fails when** someone changes the RPC exception text in a later migration and ErrorMapper stops matching → generic error reappears.
- **This fails when** rollback is done but nobody re-verifies that the old RPC is actually deployed → team thinks they rolled back but DB still has new code.

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|------------------|-----------------|
| Contract of exception messages | So backend and app stay in sync | Write in plan and SUPABASE_SETUP: (1) "Can only request revision on delivered work", (2) "No revisions remaining", (3) "Only client can request revision". ErrorMapper uses message.contains() for (1) and (2); (3) if not already mapped. | Plan §Contract; SUPABASE_SETUP §9.2 | Both docs list the three messages |
| Column existence prerequisite | Avoid migration failure | Phase 1.0: run list_tables (verbose) or information_schema query for tasks and bookings; if revisions_used or revisions_total missing, create and apply a separate migration adding them, then proceed. | Prerequisite migration (if needed) | Migration apply succeeds |
| RPC guard order | Prevent any UPDATE before guards | In new migration: for task and booking, SELECT id, status, revisions_used, revisions_total INTO local vars; then IF client, IF status, IF cap; then single UPDATE. No UPDATE in branches that can run before checks. | Migration SQL file | Code review confirms order |
| ViewModel error mapping | User sees specific message | In requestRevision catch: _error = ErrorMapper.map(e). Remove hardcoded 'Failed to request revision'. | work_item_details_view_model.dart | E2E: trigger error, see mapped text |
| UI disable when no revisions left | Avoid useless RPC and better UX | In work item detail, if workItem.revisionsUsed >= workItem.revisionsTotal, disable or hide "Request revision" and optionally show "No revisions left". | work_item_details_screen.dart | With 0 remaining, button not submittable |
| One automated test for revision error | Regression safety | Add test: mock WorkManagementService.requestRevision to throw PostgrestException(message: 'No revisions remaining'); call ViewModel.requestRevision; assert that error state or message contains the mapped user string. | test/.../request_revision_error_test.dart | flutter test passes |
| Rollback verification | Prove rollback works | After documenting rollback, add step: "Post-rollback: re-apply previous RPC body, then call rpc_request_revision with revisions_used = revisions_total; must succeed (old RPC has no cap)." | Runbook or plan §Rollback | Rollback tested once |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Contract (Exception Messages)

- **Backend (exact RAISE EXCEPTION text):**
  - `Can only request revision on delivered work`
  - `No revisions remaining`
  - `Only client can request revision`
- **App:** ErrorMapper maps via `message.contains(...)` for the first two; third if not already present. User-facing strings can be slightly different (e.g. "You have no revisions remaining") as long as consistent.

---

### Phase 0: Preconditions & Decisions

**Goal:** Lock scope and decisions so execution is unambiguous.  
**Why:** Avoid mid-execution discovery of missing columns or wrong test strategy.  
**How:** Resolve Decision 1 (column prerequisite) and Decision 2 (automated test).  
**Result:** Prerequisite migration exists if needed; test file path and run command decided.

- [ ] (@Sentinel) Acceptance criteria documented: RPC raises on non-delivered and on cap; UI shows mapped messages; client-only unchanged; success path unchanged.
- [ ] (@Supabase_Ops) Decision 1: Confirm column existence (Phase 1.0); if missing, create prerequisite migration and apply before proceeding.
- [ ] (@Architect) Decision 2: Add at least one Flutter test for revision error mapping (mock service, assert UI message).
- [ ] (@APIContract) Contract: Document the three exception messages in plan and in SUPABASE_SETUP §9.2.

**GATE CHECK (Phase 0):** Decisions recorded; contract written; acceptance list agreed.

---

### Phase 1: Data/Contracts & Backend (Database)

**Goal:** Safe migration that enforces state and cap guards in RPC.  
**Why:** Escrow and state integrity depend on DB enforcing rules.  
**How:** Verify columns → write migration with correct guard order → apply.  
**Result:** `rpc_request_revision` enforces status = 'delivered' and revisions_used < revisions_total for task and booking.

#### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) List columns for `tasks` and `bookings` (Supabase MCP `list_tables` verbose or `information_schema.columns`). Confirm `revisions_used`, `revisions_total`, `status` exist on both.
- [ ] (@Supabase_Ops) If any missing: create prerequisite migration adding column(s) with sensible default (e.g. 0 for counts, or NULL and guard with COALESCE); apply it; then proceed.
- [ ] (@Supabase_Ops) Confirm current `rpc_request_revision` exists and matches repo `20260305180100` body (for rollback reference).

**GATE CHECK (1.0):** Columns present or added; no apply failure.

#### 1.1 Migration: Harden RPC

- [ ] (@Supabase_Ops) New migration file (e.g. `YYYYMMDD_harden_rpc_request_revision.sql`). Content:
  - For **task**: SELECT id, status, revisions_used, revisions_total INTO locals WHERE id = entity_id. Check client. Then IF status <> 'delivered' RAISE. Then IF COALESCE(revisions_used,0) >= COALESCE(revisions_total,0) RAISE. Then UPDATE tasks SET ...
  - For **booking**: same pattern (SELECT, client check, status check, cap check, UPDATE).
  - Comment in migration: "When revisions_total is NULL or 0, no revisions allowed."
- [ ] (@Sentinel) Review: no UPDATE before both IF guards in either branch.

#### 1.2 Apply Migration

- [ ] (@DataMigration) Apply migration to target project. Verify no compile/run error.
- [ ] (@Sentinel) Manual SQL smoke: call RPC for task with status 'active' → expect "Can only request revision on delivered work"; for delivered with revisions_used >= revisions_total → "No revisions remaining"; as client with delivered and revisions left → success.

**GATE CHECK (Phase 1):** Migration applied; manual SQL checks pass. **Data/Contracts Gate = PASS.**

---

### Phase 2: Security (No Change)

**Goal:** Confirm no new security surface.  
**Why:** RPC remains SECURITY DEFINER with same client check.  
**How:** No code change; checklist only.  
**Result:** Security gate satisfied.

- [ ] (@Supabase_Ops) No RLS change; no new policy; RPC still auth.uid() = client_id.
- [ ] (@Sentinel) Confirm: freelancer/third-party cannot request revision (existing check).

**GATE CHECK (Phase 2):** Security Gate = PASS.

---

### Phase 3: App Layer (MVVM)

**Goal:** ViewModel and ErrorMapper surface correct messages; UI can disable when no revisions left.  
**Why:** Users must see "No revisions remaining" / "Can only request revision on delivered work", not generic error.  
**How:** ErrorMapper branches; ViewModel catch uses ErrorMapper; model already has revisionsUsed/revisionsTotal.  
**Result:** Error path shows mapped message; button can be disabled when revisions exhausted.

#### 3.1 ErrorMapper

- [ ] (@Architect) In `lib/core/utils/error_mapper.dart` (_mapPostgrestError): add `if (message.contains('Can only request revision on delivered work')) return '...';` and `if (message.contains('No revisions remaining')) return '...';` and `if (message.contains('Only client can request revision')) return '...';` (or equivalent user strings). Place before switch on error.code.

#### 3.2 ViewModel

- [ ] (@Architect) In `WorkItemDetailsViewModel.requestRevision` catch block: set `_error = ErrorMapper.map(e)` instead of `_error = 'Failed to request revision'`. Keep AppLogger.e with full error/stack.

#### 3.3 UI (Wiring + Disable When No Revisions)

- [ ] (@Pixel) Work item detail: ensure error from ViewModel is shown (snackbar/dialog) when requestRevision fails. Use existing _error and loading state.
- [ ] (@Pixel) When `workItem.revisionsUsed >= workItem.revisionsTotal`, disable "Request revision" (or hide) and optionally show "No revisions left" so no RPC is sent when cap is already reached.

**GATE CHECK (Phase 3):** ErrorMapper has three branches; ViewModel uses it; UI disables when no revisions. **Backend/API + UI/Integration Gates = PASS.**

---

### Phase 4: QA + Release

**Goal:** Verify contract, security, and E2E behavior; optional automated test.  
**Why:** Ensure no regression and that rollback is testable.  
**How:** Manual SQL, manual E2E, optional Flutter test; rollback verification.  
**Result:** All acceptance criteria met; rollback path proven.

#### 4.1 Contract + DB Verification

- [ ] (@Sentinel) Call RPC with status 'active' → message contains "Can only request revision on delivered work". Call with revisions_used >= revisions_total → "No revisions remaining". Call as non-client → "Only client can request revision". Confirm ErrorMapper strings match what UI shows.

#### 4.2 Security / Abuse

- [ ] (@Sentinel) Freelancer cannot request revision; third-party cannot; request on active/completed fails; request when cap reached fails.

#### 4.3 Functional E2E

- [ ] (@Sentinel) Client requests revision on delivered work (success, status → active, revisions_used +1). Client requests when no revisions left → UI shows "No revisions remaining" (and button disabled if implemented). Client requests on non-delivered if reachable → appropriate message. Network error / null note handled without crash.

#### 4.4 Automated Test (if Decision 2 = (C))

- [ ] (@Sentinel) Add test file (e.g. `test/features/work/request_revision_error_mapping_test.dart`): mock WorkManagementService to throw PostgrestException with message containing "No revisions remaining"; trigger requestRevision; assert that error state or displayed message contains the mapped user-facing string. Run: `flutter test test/features/work/...`.

#### 4.5 Rollback Verification

- [ ] (@Sentinel) Document rollback: re-apply previous RPC body from `20260305180100`. Optional: once perform rollback on dev/staging and run one smoke: call RPC with revisions_used = revisions_total → must succeed (old RPC has no cap), then re-apply new migration.

**GATE CHECK (Phase 4):** All checks pass; test (if added) green; rollback documented/verified. **Release/QA Gate = PASS.**

---

### Phase 5: Documentation

**Goal:** Docs match code and DB.  
**Why:** Single source of truth for future changes.  
**How:** Update SUPABASE_SETUP and any work flow doc.  
**Result:** §9.2 and §1 describe guards and three exception messages.

- [ ] (@DocsKeeper) `Sline_everything/SUPABASE_SETUP.md` §9.2: state that `rpc_request_revision` checks status = 'delivered' and revisions_used < revisions_total; list the three exception messages. §1 Key Business Rules: "Revision requests enforce status and limit (rpc_request_revision)."
- [ ] (@DocsKeeper) If DEVELOPER_GUIDE or work flow doc describes revision flow, align with new behavior and error messages.

**GATE CHECK (Phase 5):** Docs updated and consistent with implementation.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- Column existence not verified before migration; risk of apply failure.
- ViewModel did not explicitly use ErrorMapper (hardcoded "Failed to request revision").
- UI did not disable "Request revision" when no revisions left.
- Exception contract not written as single source of truth.
- RPC guard order not explicit (SELECT then IFs then UPDATE).
- No automated test for error mapping; no rollback verification step.
- Optional test infrastructure gate and double-submit mitigation (loading state) not clearly tied to success criteria.

### 2) Added steps

- Phase 1.0: List columns; prerequisite migration if missing.
- Contract subsection: exact three exception messages in plan and SUPABASE_SETUP.
- ViewModel: set _error = ErrorMapper.map(e) in requestRevision catch.
- UI: disable (or hide) "Request revision" when revisionsUsed >= revisionsTotal; optional "No revisions left" copy.
- Migration: explicit order SELECT → client check → status check → cap check → UPDATE; comment for NULL/0 revisions_total.
- Phase 4.4: Optional Flutter test for revision error mapping.
- Phase 4.5: Rollback verification (re-apply old RPC, smoke test).

### 3) Removed steps

- None; all original steps kept, expanded or reordered.

### 4) Reordered steps

- Phase 1: 1.0 (column check) must run before 1.1 (write migration). Migration content order made explicit (SELECT then guards then UPDATE).

### 5) Expanded steps

- Phase 1.3 → 1.1: Migration now specifies variable SELECT and order of IFs.
- Phase 2.3 (ViewModel): Explicit "set _error = ErrorMapper.map(e)".
- Phase 3.1 (UI): Added "disable when no revisions left" and optional copy.
- Phase 4: Added 4.4 (automated test) and 4.5 (rollback verification).
- Contract: New subsection so backend and app share exact message strings.

### 6) Why (short, practical)

- Column check prevents apply failure in production.
- ErrorMapper + ViewModel fix ensures users see the right message after we add DB guards.
- Disabling the button when cap is reached improves UX and avoids unnecessary errors.
- Contract doc prevents message drift between DB and app.
- Guard order in migration prevents accidental bypass or state corruption.
- One automated test catches ErrorMapper/ViewModel regressions.
- Rollback verification proves the rollback path works.

### 7) Residual risks

- Idempotency for double-click is still not in scope; we rely on _isLoading to disable the button. If network is very slow, user might double-tap before loading flips — low probability, acceptable for this plan.
- Old app versions will receive new exceptions when over limit; no backfill. Acceptable.
- Audit logging for "revision requested" is still optional; can be added in a later observability pass.

---

## References (Unchanged)

- `.TODO/improvement_the_system/ImplementReady/10_work-contract-revisions/` (00, 01, 02, 03, 04, 07)
- `Sline_everything/SUPABASE_SETUP.md`, `DEVELOPER_GUIDE.md`, `STRUCTURE.md`, `MVP_ROADMAP.md`
- `supabase/migrations/20260305180100_work_revision_and_change_rpcs.sql`
- `lib/features/work/services/work_management_service.dart`, `viewmodels/work_item_details_view_model.dart`, `view/work_item_details_screen.dart`, `models/unified_work_item_model.dart`
- `lib/core/utils/error_mapper.dart`
