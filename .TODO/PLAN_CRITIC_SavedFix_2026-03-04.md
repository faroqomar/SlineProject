## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- The target remains the live `saved` feature bounded to `lib/features/saved/**` and the direct dependencies already listed in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md`. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:1-209`
- Existing widget and integration harnesses under `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/support/` are the baseline to extend, not replace. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart:5-18`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/support/helpers.dart:19-228`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/support/preflight.dart:5-56`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/pubspec.yaml:60-72`
- Live Supabase is still the source of truth for `saved_tasks`, `tasks`, and `rpc_get_profile_summaries`, but the current planning session did not obtain an authenticated MCP scan. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/.temp/project-ref:1`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:38-56`
- Strict MVVM remains non-negotiable: views do not call Supabase directly and ViewModels should not own raw backend/session infrastructure. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md:56-66`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/view/saved_tasks_screen.dart:7-9`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/viewmodels/saved_tasks_view_model.dart:106-121`

### Decision Needed (Blocking)

1. Missing decision: what is the canonical orphaned-saved-row UX.
- Options:
  - Silently filter unreadable/deleted task rows out of the saved list.
  - Render an unavailable row with unsave/cleanup action.
  - Block the screen and show a global error.
- Recommended: render an unavailable row with unsave/cleanup action.
- Why: the docs already say “Hide card; allow cleanup removal,” which means the user still needs a cleanup path, and silent filtering loses the only actionable row identity. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:121-126`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/viewmodels/saved_tasks_view_model.dart:25-35`
- What changes in the plan depending on the choice:
  - Silent filter: smaller UI surface, but saved rows can disappear with no explanation and no cleanup affordance.
  - Unavailable row: requires an aggregate model, row-state UI, and explicit cleanup action.
  - Global error: simplest technically, but it keeps the current user-facing failure mode and should be rejected.

2. Missing decision: what is the canonical mutation contract for save/unsave.
- Options:
  - Keep `Future<bool>` and side-channel `error`.
  - Return `bool` plus separate pending/error fields.
  - Return a typed mutation result object/enum.
- Recommended: return a typed mutation result object/enum.
- Why: the current bug is caused by split state and ambiguous mutation outcomes; `bool` is not enough to distinguish duplicate, unauthenticated, forbidden, refresh-failed, and orphan-cleanup results. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/viewmodels/saved_tasks_view_model.dart:62-86`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/saved.TODO.md:31-39`
- What changes in the plan depending on the choice:
  - `Future<bool>`: callers still need side-channel state and will keep making ad hoc UX decisions.
  - `bool` + side-channel: still ambiguous under concurrency and partial refresh failure.
  - Typed result: UI/tests can deterministically assert exact outcomes and recovery paths.

3. Missing decision: what happens if live Supabase MCP auth remains unavailable during implementation.
- Options:
  - Block all work until MCP auth is fixed.
  - Proceed with app-side fixes and tests, but block DB reconcile/release until live scan is completed.
  - Skip live verification and trust docs/local metadata.
- Recommended: proceed with app-side fixes and tests, but block DB reconcile and release until authenticated live scan is completed.
- Why: trusting docs violates the planner workflow and the current repo already has missing `saved_tasks` SQL provenance; blocking all work would stall safe app-side correctness fixes that do not depend on new DB assumptions. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:38-56`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/saved.TODO.md:20-28`
- What changes in the plan depending on the choice:
  - Block all work: safe but unnecessary for local app correctness/test prep.
  - App-only proceed, DB/release blocked: safest practical path.
  - Trust docs: invalid; release blocker remains hidden.

4. Missing decision: release slicing and branch strategy.
- Options:
  - One PR with app, tests, docs, and DB reconcile.
  - Two PRs: app/tests first, DB/docs second.
  - Three PRs: infra/contracts, app fixes/tests, DB/docs/release gate.
- Recommended: three PRs.
- Why: the fix spans a runtime crash path, state contract refactor, possible DB reconciliation, and documentation drift. One or two large slices increase rollback and review risk. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:131-181`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/CODE_REVIEW.md:16-23`
- What changes in the plan depending on the choice:
  - One PR: highest rollback risk.
  - Two PRs: acceptable only if DB changes are definitively not needed.
  - Three PRs: cleanest gate checks and rollback points.

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate
- Status: ❌ FAIL
- Reason:
  - The current plan adds widget/unit tests but does not create a saved-specific test-infrastructure phase before contract/app work. Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:145-158`
  - Saved entry points currently expose no stable keys/selectors in the audited files. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/view/saved_tasks_screen.dart:13-169`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/view/profile_screen.dart:427-443`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/booking_task_card.dart:153-181`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/tender_task_card.dart:253-286`
  - The current plan does not define fixture/preflight requirements for any saved integration path even though reusable integration harnesses already exist. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/support/helpers.dart:19-228`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/support/preflight.dart:5-56`
- What to add/fix to pass:
  - Add a dedicated `Phase 0.0 Test Infrastructure Gate`.
  - Add selector map, fixture manifest, timeout budgets, failure artifact path, and rerun policy before any saved tests are authored.

### Gate 1: Data/Contracts Gate
- Status: ❌ FAIL
- Reason:
  - The current plan does not lock the orphan-row UX decision before introducing a new aggregate model. Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:118-124`
  - The current plan does not define one typed mutation-result contract before refactoring `toggle()` and the save-button callers. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:129-137`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/viewmodels/saved_tasks_view_model.dart:62-86`
  - The plan does not define a state matrix that binds saved list, saved count, and save-button UI to one authoritative transition contract. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/view/profile_screen.dart:427-435`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/view/saved_tasks_screen.dart:115-161`
- What to add/fix to pass:
  - Add blocking contract artifacts for orphan-row UX, typed mutation results, and UI state transitions before Phase 2 starts.

### Gate 2: Security Gate
- Status: ❌ FAIL
- Reason:
  - The current plan records live Supabase auth failure as context but does not make authenticated live scan a release-blocking gate with fallback behavior. Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:76-84`
  - It does not define exact positive/negative RLS verification queries for `saved_tasks`. Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:101-110`
  - It does not include a provenance strategy for missing source-controlled `saved_tasks` SQL beyond a general reconcile note. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:54-59`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/saved.TODO.md:20-28`
- What to add/fix to pass:
  - Add exact live verification queries, release-blocking live scan criteria, and a no-fake-historical-migration provenance rule.

### Gate 3: Backend/API Gate
- Status: ❌ FAIL
- Reason:
  - The current plan does not explicitly choose the canonical read path: aggregate model built from null-safe join rows vs separate raw rows + task hydration helper. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:118-124`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/data/saved_tasks_service.dart:89-135`
  - The order between app-side correctness fixes and DB reconcile is too loose; it does not say what can proceed while MCP auth is blocked. Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:86-115`
  - It does not define idempotency semantics beyond “single-flight / pending protection,” which is not enough to guide service/API decisions. Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:129-137`
- What to add/fix to pass:
  - Add a canonical read-path decision, a local-vs-live dependency order, and an explicit mutation/idempotency matrix.

### Gate 4: UI/Integration Gate
- Status: ❌ FAIL
- Reason:
  - The plan does not include a saved UI state matrix for loading, empty, error, unavailable row, pending, duplicate, unauthenticated, and forbidden outcomes. Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:165-173`
  - It does not require stable keys/selectors for saved screen, saved count entry, and save buttons before widget/integration coverage. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/view/saved_tasks_screen.dart:13-169`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/view/profile_screen.dart:427-443`
  - It does not define the exact visible behavior when a saved task becomes unreadable or when toggle refresh fails after a successful mutation. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/viewmodels/saved_tasks_view_model.dart:72-76`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:121-126`
- What to add/fix to pass:
  - Add a UI state matrix artifact and bind selectors/keys to each tested state.

### Gate 5: Release/QA Gate
- Status: ❌ FAIL
- Reason:
  - The current plan has no explicit PR slicing artifact, review checklist, or per-slice definition of done. Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_SavedFix_2026-03-04.md:1-209`
  - It does not define a final go/no-go release checklist tying together live DB verification, tests, docs sync, and manual scenarios.
  - It does not define failure artifact capture or rerun thresholds for saved integration work.
- What to add/fix to pass:
  - Add PR slicing, reviewer checklist, release checklist, and flake/failure artifact policy.

## C) Critical Gaps (Must-Fix)

### Gap 1
- Gap: No Test Infrastructure Gate.
- Why it will break: new saved tests will be written against unstable text/layout and ad hoc fixture assumptions.
- Fix (exact step(s) to add / reorder):
  - Add `Phase 0.0 Test Infrastructure Gate` before spec lock.
  - Create `.TODO/TEST_INFRA_Saved_2026-03-04.md`.
  - Create `.TODO/FIXTURES_Saved_2026-03-04.md`.
- Owner: Frontend
- Acceptance check: selector map, fixture manifest, timeout budgets, rerun policy, and failure artifact path exist before new saved tests are written.

### Gap 2
- Gap: Canonical orphan-row UX is not locked.
- Why it will break: the plan can still produce a technically valid aggregate model with the wrong user behavior or no cleanup affordance.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/DECISION_SavedOrphanUX_2026-03-04.md` in Phase 0.
  - Block service/model/UI work until it is written.
- Owner: Product
- Acceptance check: one orphan-row UX decision is documented and reused across contract, service, UI, and test tasks.

### Gap 3
- Gap: Mutation result semantics are too vague.
- Why it will break: `toggle()` and caller behavior can still diverge under duplicate, unauthenticated, forbidden, refresh-failed, or cleanup outcomes.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/CONTRACT_SavedMutation_2026-03-04.md` before app-layer changes.
  - Require a typed mutation result and list every caller to update.
- Owner: Backend
- Acceptance check: all saved mutations return deterministic typed outcomes that UI/tests can assert.

### Gap 4
- Gap: Live Supabase auth blocker is not operationalized.
- Why it will break: the plan can drift into DB assumptions or stall without a stop/go rule while MCP auth remains unavailable.
- Fix (exact step(s) to add / reorder):
  - Add `Phase 0.1 Live Access Gate`.
  - Explicitly allow app-side fixes/test prep to proceed, but block DB reconcile and release until authenticated live scan completes.
- Owner: Backend
- Acceptance check: the revised plan contains a hard gate and a fallback working mode rather than a passive warning.

### Gap 5
- Gap: No provenance strategy for missing `saved_tasks` SQL migration history.
- Why it will break: the team can be tempted to invent fake historical migrations or silently ignore repo/live drift.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/DB_PROVENANCE_Saved_2026-03-04.md`.
  - State explicitly that only forward reconcile is allowed; no fake backfill migration will be created.
- Owner: Backend
- Acceptance check: repo/live drift handling is documented and reviewable.

### Gap 6
- Gap: No UI state matrix.
- Why it will break: saved screen, profile entry, and task-card buttons will still implement inconsistent visible behavior.
- Fix (exact step(s) to add / reorder):
  - Create `.TODO/UI_STATE_MATRIX_Saved_2026-03-04.md` before Phase 3.
- Owner: Frontend
- Acceptance check: every user-visible state has one expected render path and one test target.

### Gap 7
- Gap: No PR slicing or release checklist.
- Why it will break: DB contract work, state refactor, test infra, and docs can land in one hard-to-review batch with weak rollback.
- Fix (exact step(s) to add / reorder):
  - Create `.TODO/PR_PLAN_Saved_2026-03-04.md`.
  - Create `.TODO/RELEASE_CHECKLIST_Saved_2026-03-04.md`.
- Owner: Product
- Acceptance check: each slice has definition of done, reviewers, gate checks, and rollback points.

## D) Invariants & Success Criteria (Non-Negotiable)

1. Invariant: one shared source of truth owns saved membership, saved list rows, and saved count.
- How to enforce: one ViewModel state contract with synchronized transitions and typed mutation outcomes.
- How to verify: unit/widget tests prove icon, list, and badge stay aligned. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/view/profile_screen.dart:427-435`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/view/saved_tasks_screen.dart:115-161`

2. Invariant: unreadable/deleted tasks never crash the saved feature.
- How to enforce: null-safe aggregate mapping and explicit unavailable-row behavior.
- How to verify: service/unit/widget tests for null joined task rows. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/data/saved_tasks_service.dart:93-116`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:121-126`

3. Invariant: `saved_tasks` access remains owner-only under RLS.
- How to enforce: verified live policies and no client-side privilege assumptions.
- How to verify: positive/negative SQL checks after authenticated live scan. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md:1120-1126`

4. Invariant: only one mutation per task id is allowed in flight at a time.
- How to enforce: per-task pending guard in ViewModel and pending-aware save-button wiring.
- How to verify: unit/widget tests and manual rapid-tap scenario. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/booking_task_card.dart:156-162`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/tender_task_card.dart:257-265`

5. Invariant: saved ViewModel does not own raw Supabase auth/session infrastructure.
- How to enforce: injected session service or equivalent adapter.
- How to verify: grep check for `Supabase.instance.client.auth` in `lib/features/saved`. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/saved/viewmodels/saved_tasks_view_model.dart:106-121`

6. Invariant: no fake historical migration is created to explain live `saved_tasks`.
- How to enforce: provenance artifact and forward-only reconcile rule.
- How to verify: review of new migration files and provenance doc.

7. Invariant: docs match code and verified live DB reality in the same release slice.
- How to enforce: docs-sync gate blocks release.
- How to verify: final docs diff and release checklist.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| MCP auth stays unavailable and DB verification stalls | Supabase live scan | High | High | Feature | repeated `Auth required` from MCP initialize | Add live-access gate and separate app-only work from DB/release work | pause DB reconcile/release and ship nothing requiring new DB assumptions |
| Aggregate model refactor still loses cleanup path | saved service / screen | Med | High | Feature | orphaned row disappears or crashes instead of showing cleanup state | lock orphan UX contract before coding | fall back to safe unavailable-row rendering with unsave only |
| Typed mutation result is underspecified and callers diverge | ViewModel + save buttons + saved screen | Med | High | Feature | icon, badge, and list react differently to the same mutation | write mutation contract and consumer matrix first | keep current API shape temporarily but add adapter layer until all callers migrate |
| Pending-state refactor breaks booking/tender cards | task-card widgets | Med | Med | Feature | save button becomes non-responsive or double-tap still races | extract shared pending-aware button or shared contract with tests | revert UI extraction only, keep ViewModel single-flight guard |
| Repo/live DB drift for `saved_tasks` is “fixed” with unsafe fake history | supabase/migrations | Med | High | App-wide | new migration looks retroactive or contradicts live object timestamps | add provenance artifact and review gate | revert fake migration and replace with forward reconcile note |
| Saved tests remain brittle due missing selectors/fixtures | widget/integration tests | High | Med | Delivery | tests depend on copy/layout or skip late on missing data | add test infra gate and fixture manifest | restrict release evidence to unit/widget/manual until selectors/fixtures land |
| Silent refresh failure still leaks through after mutation | ViewModel state sync | Med | High | Feature | saved count or list lags after successful icon toggle | typed mutation contract plus explicit refresh-failed branch | fall back to hard `load()` retry and visible error state |

## F) Pre-Mortem (How this fails in real life)

- This fails when the team implements an aggregate saved-row model but never decides what the user should see for a missing task, so the unavailable state varies across screens.
- This fails when `toggle()` returns “success” but one caller interprets refresh-failed as success and another does not.
- This fails when the save buttons gain pending UI in one task card but not the other, and concurrency bugs survive in the untouched surface.
- This fails when app-side fixes land and everyone assumes `saved_tasks` RLS is correct even though live DB was never re-authenticated and verified.
- This fails when someone adds a fake “historical” migration for `saved_tasks` just to make the repo look complete.
- This fails when tests are added without selectors and later get rewritten or skipped because the UI text changes.
- This fails when docs update before live DB verification and end up repeating the same unverified contract.

## G) Plan Fixes (Concrete Additions / Expansions)

1. Goal: add a Test Infrastructure Gate.
- Why: current plan schedules tests without selectors, fixtures, or failure policy.
- How: create `TEST_INFRA_Saved`, `FIXTURES_Saved`, and require selectors/keys before saved test files are added.
- Output artifact: test infra doc, fixture manifest, selector map.
- Stop condition: every planned saved test references stable selectors and documented preconditions.

2. Goal: lock orphan-row UX before contract/model work.
- Why: aggregate-model implementation is impossible to execute safely without a user-facing decision.
- How: create `DECISION_SavedOrphanUX` and make it a blocker.
- Output artifact: decision doc.
- Stop condition: one canonical unavailable-row behavior is written and reused by later phases.

3. Goal: lock a typed mutation contract.
- Why: current `toggle()` bug is a contract bug, not just an implementation bug.
- How: create `CONTRACT_SavedMutation`, list outcomes, and update all consumers against it.
- Output artifact: mutation contract doc.
- Stop condition: all callers consume deterministic typed results.

4. Goal: operationalize the live DB auth blocker.
- Why: passive warnings are fake progress.
- How: add a Live Access Gate that explicitly separates app-safe work from DB/release-blocked work.
- Output artifact: revised plan phase plus release gate dependency.
- Stop condition: no DB reconcile or release step is allowed without authenticated live scan evidence.

5. Goal: prevent unsafe migration-history repair.
- Why: repo/live drift exists and can trigger bad cleanup decisions.
- How: add `DB_PROVENANCE_Saved` and a forward-only reconcile rule.
- Output artifact: provenance doc.
- Stop condition: migration strategy is reviewable and disallows fake historical backfill.

6. Goal: make release reviewable.
- Why: current plan has no PR slicing or release checklist.
- How: add PR plan, reviewer checklist, release checklist, and per-slice gate checks.
- Output artifact: `PR_PLAN_Saved`, `RELEASE_CHECKLIST_Saved`.
- Stop condition: work is split into reviewable slices with rollback points.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0.0: Test Infrastructure Gate
- Goal: make saved testing deterministic before contract/app changes.
- Why: selectors, fixtures, and failure policy are currently missing.
- How:
  - Reuse `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart:5-18`.
  - Reuse `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/support/helpers.dart:19-228` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/support/preflight.dart:5-56`.
  - Create `TEST_INFRA_Saved` and `FIXTURES_Saved`.
  - Add stable keys/selectors to saved screen, profile entry, and both save buttons.
- Result: saved-specific tests have deterministic prerequisites.
- GATE CHECK:
  - selectors exist
  - fixture manifest exists
  - timeout/retry/failure artifact policy exists

### Phase 0.1: Live Access Gate
- Goal: turn the Supabase auth blocker into an explicit stop/go rule.
- Why: live DB confirmation is mandatory for DB reconcile and release.
- How:
  - Retry authenticated `@mcp:supabase-mcp-server:` scan.
  - If still blocked, record the blocker and allow only app/test/docs prep that does not assume new DB truth.
  - Block any DB reconcile or release step until live scan succeeds.
- Result: no fake progress on DB/security work.
- GATE CHECK:
  - either authenticated live scan evidence exists
  - or the plan is explicitly in app-only mode with DB/release blocked

### Phase 0.2: Contract Lock
- Goal: freeze the saved feature decisions and contracts.
- Why: orphan-row UX, mutation semantics, and UI states are currently ambiguous.
- How:
  - Create `DECISION_SavedOrphanUX`
  - Create `CONTRACT_SavedMutation`
  - Create `UI_STATE_MATRIX_Saved`
  - Create `DONE_CRITERIA_Saved`
- Result: implementation has one contract path.
- GATE CHECK:
  - orphan-row UX locked
  - mutation contract locked
  - UI state matrix exists
  - done criteria exist

### Phase 0.3: Delivery / Provenance Planning
- Goal: make rollout reviewable and safe.
- Why: repo/live DB drift and cross-surface UI changes raise rollback risk.
- How:
  - Create `DB_PROVENANCE_Saved`
  - Create `PR_PLAN_Saved`
  - Create `RELEASE_CHECKLIST_Saved`
- Result: slice plan and rollback path are explicit.
- GATE CHECK:
  - provenance strategy documented
  - PR slices documented
  - release checklist drafted

### Phase 1: Data / Security
- Goal: verify or reconcile live `saved_tasks` contract safely.
- Why: `saved_tasks` policies/indexes are documented but not source-controlled in repo migrations.
- How:
  - Run authenticated live scan for `saved_tasks`, `tasks`, and `rpc_get_profile_summaries`
  - Capture exact verify queries and results
  - If drift exists, prepare forward-only reconcile migration or docs correction
- Result: live DB contract is explicit and reviewable.
- GATE CHECK:
  - live scan evidence captured
  - RLS verify queries pass
  - no fake historical migration introduced

### Phase 2: Backend / App Logic
- Goal: fix crash/state/idempotency issues behind one contract.
- Why: current service and ViewModel can crash, drift, or race.
- How:
  - choose canonical read path
  - implement null-safe aggregate row mapping
  - refactor ViewModel to one source of truth
  - inject session service
  - add per-task single-flight mutation guard
  - define explicit refresh-failed handling
- Result: saved data behavior is deterministic and MVVM-safe.
- GATE CHECK:
  - orphan rows are safe
  - icon/list/badge stay aligned
  - no raw auth/session IO remains in saved VM

### Phase 3: UI Wiring
- Goal: wire all saved surfaces to the corrected logic contract.
- Why: saved screen, profile badge, and task-card buttons currently diverge.
- How:
  - split saved screen shell/body/state widgets
  - add unavailable-row UI if chosen
  - unify labels
  - use shared save-button contract
  - route through a stable task-details helper
- Result: one coherent saved UX.
- GATE CHECK:
  - all UI states map to the state matrix
  - stable selectors remain present
  - no cross-feature view leakage remains where a route/helper seam should exist

### Phase 4: QA / Security / Release
- Goal: prove the saved fix is safe to ship.
- Why: saved spans RLS, cross-surface state, and repeated user interactions.
- How:
  - run unit/widget tests
  - add saved integration scenario if fixtures are ready
  - execute negative RLS/auth tests
  - complete manual saved scenarios
  - run release checklist
- Result: release evidence is explicit.
- GATE CHECK:
  - tests pass
  - negative checks pass
  - live DB verification is present
  - docs sync is complete

### Phase 5: Documentation Sync
- Goal: sync docs to final code and verified DB state.
- Why: current saved DB contract already has drift risk.
- How:
  - update `DEVELOPER_GUIDE.md`, `DEVELOPER_GUIDE/Saved Feature.md`, `SUPABASE_SETUP.md`, `STRUCTURE.md`, `MVP_ROADMAP.md` if needed, and `Sline_Log.md`
- Result: docs no longer restate unverified behavior.
- GATE CHECK:
  - docs match final code and authenticated live DB evidence

## I) Change Report (Diff-Style)

1. Original issues summary
- The original plan had good scope coverage but was still execution-unsafe because it lacked a test infrastructure gate, a live-access operational gate, an orphan-row UX decision, a typed mutation contract, a provenance strategy for missing `saved_tasks` SQL, and delivery/release slicing.

2. Added steps (bullet list)
- Added `Phase 0.0 Test Infrastructure Gate`
- Added `Phase 0.1 Live Access Gate`
- Added blocking decision artifact for orphan-row UX
- Added blocking contract artifact for typed mutation outcomes
- Added saved UI state matrix artifact
- Added DB provenance artifact
- Added PR plan and release checklist artifacts

3. Removed steps (if any)
- Removed the implicit assumption that DB/security work and release can proceed with only local metadata if MCP auth remains blocked.

4. Reordered steps (from → to)
- Moved test infrastructure from an implied later concern → earliest gate
- Moved live DB access from a passive warning inside Phase 1 → explicit Phase 0 gate
- Moved contract decisions from mixed into app work → pre-app blocking artifacts

5. Expanded steps (what became more detailed)
- Expanded mutation work into a typed mutation-result contract and consumer matrix
- Expanded orphan-row handling into an explicit UX/product decision
- Expanded release into PR slicing, provenance, and release checklist work

6. Why (short, practical)
- The prior plan could still produce implementation drift and fake progress. The corrected version blocks ambiguity before code changes and separates app-safe work from DB/release-gated work.

7. Residual risks (what still remains risky even after fixes)
- Authenticated live Supabase scan may remain blocked until the user completes auth.
- Repo/live `saved_tasks` history drift may still require a product/ops decision if live reality differs from docs in non-trivial ways.
- Aggregate-model/UI changes still touch multiple surfaces and need disciplined PR slicing to stay safe.
