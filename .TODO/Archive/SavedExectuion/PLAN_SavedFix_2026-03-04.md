# 📌 Plan: Saved Feature Full Fix

## 1) Goal

- Goal:
  - Repair the saved-task feature so saved rows are safe under task visibility changes, saved state is single-sourced across all app surfaces, MVVM boundaries are restored, and the live `saved_tasks` contract is verified before release. References: `lib/features/saved/view/saved_tasks_screen.dart:13-169`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:15-152`, `lib/features/saved/data/saved_tasks_service.dart:8-137`, `.TODO/saved.TODO.md:1-163`, `.TODO/PLAN_CRITIC_SavedFix_2026-03-04.md:1-191`
- Why:
  - The current runtime can crash on null joined tasks, drift between icon/list/badge state after toggle, race on repeated save taps, and still lacks verified live SQL/RLS provenance for `saved_tasks`. References: `lib/features/saved/data/saved_tasks_service.dart:93-116`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:62-77`, `lib/features/tasks/view/widgets/booking_task_card.dart:156-162`, `lib/features/tasks/view/widgets/tender_task_card.dart:257-265`, `Sline_everything/SUPABASE_SETUP.md:1120-1126`
- Result:
  - One deterministic saved contract, one verified DB/RLS story, one reviewable rollout path, and direct saved test coverage with stable selectors and fixtures. References: `Sline_everything/DEVELOPER_GUIDE.md:31-41`, `Sline_everything/STRUCTURE.md:167-176`, `Sline_everything/CODE_REVIEW.md:16-23`

## 2) Scope

### In-Scope

- Saved feature runtime:
  - `lib/features/saved/view/saved_tasks_screen.dart:13-169`
  - `lib/features/saved/viewmodels/saved_tasks_view_model.dart:15-152`
  - `lib/features/saved/data/saved_tasks_service.dart:8-137`
  - `lib/features/saved/models/saved_task_model.dart:4-52`
  - `lib/features/saved/view/widgets/saved_task_tile.dart:3-31`
  - `lib/features/saved/routes/saved_routes.dart:4-13`
- Direct callers / direct dependencies:
  - `lib/main.dart:166-169`
  - `lib/features/profile/view/profile_screen.dart:427-443`
  - `lib/features/home/view/home_screen.dart:76-90`
  - `lib/features/tasks/view/widgets/booking_task_card.dart:153-181`
  - `lib/features/tasks/view/widgets/tender_task_card.dart:253-286`
  - `lib/features/profile/services/profile_summary_service.dart:6-58`
  - `lib/features/tasks/models/task_model.dart:106-179`
  - `lib/features/tasks/services/task_service.dart:47-88`
- Test/runtime support that must be reused:
  - `test/test_support/pump_app.dart:5-18`
  - `test/integration_test/support/helpers.dart:19-228`
  - `test/integration_test/support/preflight.dart:5-56`
  - `pubspec.yaml:60-72`
- Saved-related docs and DB contract references:
  - `Sline_everything/DEVELOPER_GUIDE.md:65-69`
  - `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:12-137`
  - `Sline_everything/SUPABASE_SETUP.md:769-778`
  - `Sline_everything/SUPABASE_SETUP.md:1120-1126`
  - `Sline_everything/SUPABASE_SETUP.md:1208-1212`
  - `Sline_everything/SUPABASE_SETUP.md:1574-1575`
  - `Sline_everything/MVP_ROADMAP.md:35-39`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md:14-23`
  - `Sline_everything/CODE_REVIEW.md:16-23`
  - `Sline_everything/STRUCTURE.md:167-176`
  - `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`
  - `supabase/migrations/20260301_harden_home_related_read_policies.sql:10-31`
  - `supabase/.temp/project-ref:1`

### Out-of-Scope

- Task-details business logic beyond replacing the saved feature’s direct screen construction with a route/helper seam. Reference: `lib/features/saved/view/saved_tasks_screen.dart:151-159`
- Broader task-feed architecture beyond the shared hydration/helper extraction needed by saved. Reference: `lib/features/tasks/services/task_service.dart:47-88`
- Booking, notifications, wallet, and search behavior not directly imported or called by saved. References: `lib/features/saved/view/saved_tasks_screen.dart:1-169`, `lib/features/saved/data/saved_tasks_service.dart:1-137`
- Any live Supabase object outside the saved/touched contract unless required to validate saved behavior. Reference: `.TODO/saved.TODO.md:6-18`

## 3) Evidence & Findings (From Scan)

### Existing

- Saved state is globally provided at app boot. Reference: `lib/main.dart:166-169`
- Saved screen auto-loads on open and renders loading/error/empty/list branches. Reference: `lib/features/saved/view/saved_tasks_screen.dart:22-28`, `lib/features/saved/view/saved_tasks_screen.dart:95-163`
- Saved service performs `saved_tasks` CRUD, joins `tasks`, and enriches author data through `rpc_get_profile_summaries`. References: `lib/features/saved/data/saved_tasks_service.dart:27-68`, `lib/features/saved/data/saved_tasks_service.dart:89-135`, `lib/features/profile/services/profile_summary_service.dart:13-33`
- Profile badge uses `savedTasks.length`; booking/tender cards use `isSaved(task.id)`. References: `lib/features/profile/view/profile_screen.dart:427-435`, `lib/features/tasks/view/widgets/booking_task_card.dart:156-162`, `lib/features/tasks/view/widgets/tender_task_card.dart:257-265`
- Saved docs already describe owner-only `saved_tasks` access and a missing-task-row cleanup expectation. References: `Sline_everything/SUPABASE_SETUP.md:1120-1126`, `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:121-126`
- Widget and integration harnesses already exist and are reusable. References: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-228`, `test/integration_test/support/preflight.dart:5-56`, `pubspec.yaml:60-72`

### Missing

- Authenticated live Supabase MCP confirmation for `saved_tasks` still does not exist in this planning run. Evidence:
  - `list_mcp_resources(server="supabase")` -> `Auth required`
  - `list_mcp_resource_templates(server="supabase")` -> `Auth required`
- A source-controlled migration defining `public.saved_tasks` DDL/RLS was not found under `supabase/migrations/`. References: `Sline_everything/SUPABASE_SETUP.md:1120-1126`, `Sline_everything/SUPABASE_SETUP.md:1574-1575`
- Dedicated saved-feature unit/widget tests do not exist yet. References: `test/widget/home/home_screen_test.dart:32-68`, `test/widget/tasks/tenders_screen_test.dart:23-25`, `test/widget/booking/bookings_discovery_screen_test.dart:23-25`
- Stable keys/selectors are absent from saved screen, profile saved entry, and both save buttons. References: `lib/features/saved/view/saved_tasks_screen.dart:13-169`, `lib/features/profile/view/profile_screen.dart:427-443`, `lib/features/tasks/view/widgets/booking_task_card.dart:153-181`, `lib/features/tasks/view/widgets/tender_task_card.dart:253-286`

### Must NOT duplicate

- Must not create a second task/profile hydration path. References: `lib/features/saved/data/saved_tasks_service.dart:102-135`, `lib/features/tasks/services/task_service.dart:47-88`
- Must not leave two navigation seams for the saved screen (`SavedRoutes` plus direct screen push). References: `lib/features/saved/routes/saved_routes.dart:4-13`, `lib/features/profile/view/profile_screen.dart:436-443`
- Must not preserve split saved truth sources without synchronized transitions (`savedTasks`, `_savedTaskIds`, and derived badge count). References: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:22-35`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:62-77`
- Must not invent fake historical SQL for `saved_tasks` just to make repo history look complete. References: `.TODO/PLAN_CRITIC_SavedFix_2026-03-04.md:79-88`, `Sline_everything/SUPABASE_SETUP.md:1120-1126`

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Docs say a missing task row should be hidden/cleanable, but current code null-dereferences joined tasks. References: `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:121-126`, `lib/features/saved/data/saved_tasks_service.dart:104-116`
- `saved_tasks` policies are documented, but authenticated live verification and source-controlled DDL/RLS are both missing in this run. References: `Sline_everything/SUPABASE_SETUP.md:1120-1126`, `.TODO/PLAN_CRITIC_SavedFix_2026-03-04.md:47-66`
- Feature naming is inconsistent: `Saved Tasks` vs `Saved Projects`. References: `lib/features/saved/view/saved_tasks_screen.dart:79-83`, `lib/features/profile/view/profile_screen.dart:430-435`
- The current plan cannot safely perform DB reconcile or release without a live-access gate because MCP auth is still blocked. Reference: `.TODO/PLAN_CRITIC_SavedFix_2026-03-04.md:11-34`

## 4) System Impact Map

- UI:
  - Saved screen, saved profile entry, booking/tender save buttons, and task-details navigation seam. References: `lib/features/saved/view/saved_tasks_screen.dart:42-169`, `lib/features/profile/view/profile_screen.dart:427-443`, `lib/features/tasks/view/widgets/booking_task_card.dart:153-181`, `lib/features/tasks/view/widgets/tender_task_card.dart:253-286`
- MVVM/App Logic:
  - `SavedTasksViewModel` state ownership, session binding, typed mutation results, pending state, and aggregate saved-row model. References: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:15-152`, `.TODO/PLAN_CRITIC_SavedFix_2026-03-04.md:67-88`
- Database:
  - `public.saved_tasks` existence, policies, indexes, and compatibility with current `tasks` visibility rules. References: `Sline_everything/SUPABASE_SETUP.md:769-778`, `Sline_everything/SUPABASE_SETUP.md:1120-1126`, `Sline_everything/SUPABASE_SETUP.md:1574-1575`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:10-21`
- RLS/Security:
  - owner-only saved access plus authenticated-only `rpc_get_profile_summaries`; live verification remains mandatory. References: `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:14-47`, `.TODO/PLAN_CRITIC_SavedFix_2026-03-04.md:47-66`
- Realtime/Notifications (if any):
  - none expected for saved. Reference: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:1-152`
- Storage:
  - none expected for saved. Reference: `lib/features/saved/data/saved_tasks_service.dart:1-137`
- Observability (if any):
  - existing `AppLogger` should remain the instrumentation path; no raw backend text should surface in UI. References: `lib/features/saved/data/saved_tasks_service.dart:17-24`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:46-53`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:78-86`
- Compatibility & Migration:
  - app-side correctness fixes can proceed before DB reconcile, but DB changes and release are blocked until authenticated live scan completes. Reference: `.TODO/PLAN_CRITIC_SavedFix_2026-03-04.md:11-34`
- Contracts:
  - orphan-row UX, typed mutation results, saved UI state matrix, and DB provenance all need explicit artifacts before implementation. References: `.TODO/PLAN_CRITIC_SavedFix_2026-03-04.md:35-88`

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.0 Test Infrastructure Gate

- [ ] (@Sentinel) Create `.TODO/TEST_INFRA_Saved_2026-03-04.md` extending the existing widget/integration harnesses instead of inventing new ones. References: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-228`, `test/integration_test/support/preflight.dart:5-56`
- [ ] (@Pixel) Define a selector/key map in `.TODO/TEST_INFRA_Saved_2026-03-04.md` and then implement those selectors in:
  - `lib/features/saved/view/saved_tasks_screen.dart`
  - `lib/features/profile/view/profile_screen.dart`
  - `lib/features/tasks/view/widgets/booking_task_card.dart`
  - `lib/features/tasks/view/widgets/tender_task_card.dart`
- [ ] (@Sentinel) Create `.TODO/FIXTURES_Saved_2026-03-04.md` with deterministic requirements for:
  - client account credentials
  - at least one open saved task
  - at least one unsaved task
  - one task made unreadable/deleted for orphan-row verification
  - cleanup/reset steps
- [ ] (@Sentinel) Define timeout budgets, rerun policy, and failure artifact path/tagging in `.TODO/TEST_INFRA_Saved_2026-03-04.md`.
- **Verify (@Sentinel):** selectors, fixtures, commands, bounded waits, and failure artifact rules exist before any saved tests are written.

### 0.1 Live Access Gate

- [ ] (@Supabase_Ops) Retry authenticated `@mcp:supabase-mcp-server:` access and capture live evidence for `saved_tasks`, `tasks`, and `rpc_get_profile_summaries`.
- [ ] (@Supabase_Ops) If MCP auth is still blocked, record the blocker in `.TODO/DB_PROVENANCE_Saved_2026-03-04.md` and explicitly mark the plan as “app/test prep allowed, DB reconcile and release blocked.”
- [ ] (@Sentinel) Add stop/go criteria to `.TODO/RELEASE_CHECKLIST_Saved_2026-03-04.md` so no DB reconcile or release step can proceed without authenticated live scan evidence.
- **Verify (@Sentinel):** either live scan evidence exists, or DB/release work is explicitly blocked with no hidden assumptions.

### 0.2 Spec Lock

- [ ] (@Architect) Create `.TODO/DECISION_SavedOrphanUX_2026-03-04.md` and lock the canonical orphan-row UX. Recommended target from critique: render an unavailable row with an unsave/cleanup action, not silent disappearance.
- [ ] (@APIContract) Create `.TODO/CONTRACT_SavedMutation_2026-03-04.md` and lock a typed mutation result contract for save/unsave outcomes.
- [ ] (@Pixel) Create `.TODO/UI_STATE_MATRIX_Saved_2026-03-04.md` covering:
  - loading
  - empty
  - recoverable load error
  - unavailable/orphan row
  - duplicate mutation outcome
  - unauthenticated
  - forbidden/RLS denied
  - refresh-failed-after-mutation
  - pending save-button state
- [ ] (@Sentinel) Create `.TODO/DONE_CRITERIA_Saved_2026-03-04.md` with measurable non-regression conditions: no null-join crash, no icon/list/badge drift, no overlapping mutation per task id, no raw auth/session access in the ViewModel, and verified live DB release gate.
- **Verify (@Sentinel):** orphan-row UX, mutation contract, state matrix, and done criteria are all written before Phase 1 or Phase 2 work starts.

### 0.3 Migration / Provenance Plan

- [ ] (@DataMigration) Create `.TODO/DB_PROVENANCE_Saved_2026-03-04.md` documenting that `saved_tasks` is described in docs/live metadata but not found in checked-in repo migrations.
- [ ] (@DataMigration) Create `.TODO/MIGRATION_Saved_2026-03-04.md` with a forward-only reconcile strategy:
  - verify live reality first
  - if drift exists, add forward-safe reconcile migration
  - no fake historical migration backfill
- [ ] (@Sentinel) Add explicit before/after verify queries for `saved_tasks` table, policies, and indexes into the migration plan.
- **Verify (@Sentinel):** provenance strategy is explicit and disallows unsafe history repair.

### 0.4 Delivery Slicing / Workflow

- [ ] (@Architect) Create `.TODO/PR_PLAN_Saved_2026-03-04.md` with 3 slices:
  - PR1: contracts + test infrastructure + selectors
  - PR2: app-layer correctness/state fixes + unit/widget tests
  - PR3: live DB reconcile (if needed) + docs sync + integration/release gate
- [ ] (@Sentinel) Add reviewer checklist and definition of done per PR into `.TODO/PR_PLAN_Saved_2026-03-04.md`.
- [ ] (@DocsKeeper) Create `.TODO/RELEASE_CHECKLIST_Saved_2026-03-04.md` and include release-blocking items for live DB verification, tests, manual scenarios, docs sync, and rollback notes.
- **Verify (@Sentinel):** slicing, reviewers, DoD, and release checklist exist before implementation begins.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via `@mcp:supabase-mcp-server:` and confirm reality for:
  - `public.saved_tasks` columns/defaults
  - unique `(user_id, task_id)` enforcement
  - active RLS policies on `saved_tasks`
  - live `tasks_select_authenticated_open_or_involved`
  - live grants and definition for `rpc_get_profile_summaries(uuid[])`
- [ ] (@Supabase_Ops) Record exact live object names and any drift against `Sline_everything/SUPABASE_SETUP.md`.
- [ ] (@Sentinel) Fail this gate if live scan is still unavailable and any later step tries to assume DB truth beyond already-safe local app fixes.
- **Verify (@Sentinel):** live scan evidence is captured or DB/release remain blocked.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) If live scan shows missing or drifted schema/indexes, prepare additive-first forward reconcile SQL only.
- [ ] (@DataMigration) Ensure the reconcile path preserves live data and uses no drops/renames unless explicitly approved after live confirmation.
- [ ] (@Sentinel) Verify index alignment for current query shapes: `user_id`, `task_id`, unique pair.
- **Verify (@Sentinel):** naming is consistent, queries are supported, and no destructive SQL enters the plan by accident.

### 1.2 RLS

- [ ] (@Supabase_Ops) Validate or add least-privilege `saved_tasks` policies for select/insert/delete scoped to `user_id = auth.uid()`.
- [ ] (@Supabase_Ops) Create `.TODO/RLS_MATRIX_Saved_2026-03-04.md` covering:
  - authenticated owner select/insert/delete allowed
  - authenticated non-owner denied
  - unauthenticated denied
  - joined `tasks` visibility interaction documented separately from saved-row ownership
- [ ] (@Sentinel) Add exact verification queries and expected outcomes to the matrix.
- **Verify (@Sentinel):** positive/negative policy checks pass and no unauthorized saved-row access is possible.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Decide, based on live scan and mutation contract, whether client-side single-flight plus unique constraint is sufficient or whether a server-side idempotent RPC is required.
- [ ] (@APIContract) If any RPC is introduced, define request/response/error shape in `.TODO/CONTRACT_SavedMutation_2026-03-04.md` before implementation.
- **Verify (@Sentinel):** idempotency strategy is explicit and minimal.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Execute the forward reconcile plan only after live scan confirms it is necessary.
- [ ] (@DataMigration) Capture verification output for table, policies, and indexes in `.TODO/MIGRATION_Saved_2026-03-04.md`.
- **Verify (@Sentinel):** post-migration queries pass and docs/live DB drift is reduced, not obscured.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Implement one aggregate saved-list model that can represent:
  - healthy saved row with hydrated `Task`
  - unavailable/orphaned saved row with retained `task_id`
  - user-safe row state defined by `DECISION_SavedOrphanUX`
- [ ] (@APIContract) Align the aggregate model, `SavedTaskModel`, and `Task.fromJson()` assumptions with the locked contracts.
- [ ] (@Architect) Add explicit domain error mapping for typed mutation outcomes and unavailable-row states.
- **Verify (@Sentinel):** nullability, row state, and mutation result types match the contract and remove the null-join crash path.

### 2.2 Services/Repositories

- [ ] (@Architect) Refactor `SavedTasksService.listMineWithDetails()` into the canonical null-safe read path and stop crashing on unreadable/deleted tasks.
- [ ] (@Architect) Extract or reuse one shared task/profile hydration helper so saved and task feed code do not diverge.
- [ ] (@Architect) Keep all Supabase access in service/data layers only; no new UI-side backend calls.
- [ ] (@Sentinel) Add a grep-based verification step proving there are still no `Supabase.instance` reads in `lib/features/saved/view/**`.
- **Verify (@Sentinel):** service is RLS-safe, aggregate rows are deterministic, and no UI→Supabase boundary violation is introduced.

### 2.3 ViewModels

- [ ] (@Architect) Refactor `SavedTasksViewModel` into one authoritative state contract for:
  - saved membership
  - saved rows
  - saved count
  - per-task pending state
  - typed recoverable errors
- [ ] (@Architect) Replace direct `Supabase.instance.client.auth` access with an injected saved-session service.
- [ ] (@Architect) Implement per-task single-flight mutation behavior and explicit handling for `refresh-failed-after-mutation`.
- [ ] (@Architect) Remove silent swallow behavior for post-mutation refresh failures.
- **Verify (@Sentinel):** icon/list/badge remain synchronized and one in-flight mutation per task id is enforced.

### 2.4 Observability (If needed)

- [ ] (@Observability) Create `.TODO/OBSERVABILITY_Saved_2026-03-04.md` with a minimal event list:
  - saved load started/succeeded/failed
  - toggle started/succeeded/failed
  - orphan row encountered
  - session clear executed
- [ ] (@Architect) Instrument service/ViewModel only, not UI widgets.
- [ ] (@Sentinel) Add privacy check to ensure logs contain no raw profile payloads or auth/session secrets.
- **Verify (@Sentinel):** logs are actionable and privacy-safe.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Split `SavedTasksScreen` into a screen shell plus testable state widgets without changing feature scope.
- [ ] (@Pixel) Implement the unavailable/orphan-row UI exactly as locked in `DECISION_SavedOrphanUX`.
- [ ] (@Pixel) Replace direct `TaskDetailsScreen` construction with a stable task-details route/helper seam.
- [ ] (@Pixel) Introduce a shared pending-aware save-button contract for both booking and tender task cards.
- [ ] (@Pixel) Normalize the user-facing label to one English name across saved screen and profile entry.
- [ ] (@Pixel) Add the selectors/keys from `TEST_INFRA_Saved`.
- **Verify (@Sentinel):** loading/empty/error/unavailable/pending states all map to the UI state matrix and selectors are present.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Add only low-risk micro-feedback for disabled save buttons while a mutation is in flight.
- [ ] (@Pixel) Keep visuals aligned with existing theme/components and avoid expanding saved scope into broader task-card redesign.
- **Verify (@Sentinel):** no performance regression or UX surprise is introduced.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Verify aggregate saved-row shapes against `CONTRACT_SavedMutation` and `DECISION_SavedOrphanUX`.
- [ ] (@Sentinel) Run the exact live DB verify queries from `RLS_MATRIX_Saved` and `MIGRATION_Saved`.
- [ ] (@Sentinel) Re-check `rpc_get_profile_summaries` grants and payload assumptions against the current app mapper.
- **Verify (@Sentinel):** no schema/shape mismatch remains.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute negative checks for:
  - unauthenticated save/unsave
  - non-owner saved row access
  - orphan-row handling after task visibility change
  - repeated rapid taps on one save button
- [ ] (@Sentinel) Run a targeted RLS audit for `saved_tasks` and confirm saved still has no storage surface.
- **Verify (@Sentinel):** unauthorized access is impossible and abuse does not corrupt state.

### 4.3 Functional QA

- [ ] (@Sentinel) Add direct saved tests:
  - `test/unit/saved/saved_tasks_service_test.dart`
  - `test/unit/saved/saved_tasks_view_model_test.dart`
  - `test/widget/saved/saved_tasks_screen_test.dart`
- [ ] (@Sentinel) Extend dependent widget tests so they assert save interaction behavior, not just mocked `isSaved(...)`.
- [ ] (@Sentinel) Add a saved integration scenario only if `FIXTURES_Saved` is satisfied; otherwise keep it blocked with an explicit preflight reason, not a silent omission.
- [ ] (@Sentinel) Run manual E2E:
  - open profile -> saved screen
  - save from tender card
  - save from booking card
  - unsave from saved screen
  - sign out with saved data present
  - verify unavailable-row behavior for unreadable/deleted task
- **Verify (@Sentinel):** no crashes, no stale count/list drift, and no flaky hidden prerequisites.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Confirm required saved logs/events exist and are useful for debugging failures.
- [ ] (@Sentinel) Confirm privacy redaction rules remain intact.
- **Verify (@Sentinel):** telemetry is actionable without leaks.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @DocsKeeper

- [ ] (@DocsKeeper) Update:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/STRUCTURE.md`
  - `Sline_everything/MVP_ROADMAP.md` if status/coverage wording changes
  - `Sline_everything/Sline_Log.md`
- [ ] (@DocsKeeper) Document:
  - final orphan-row UX
  - typed mutation result contract
  - final saved route/helper seam
  - verified live DB/provenance status
- [ ] (@Sentinel) Compare docs against final code and authenticated live DB evidence before closing the release checklist.
- **Verify (@Sentinel):** docs match final code and verified live DB reality, not prior assumptions.

---

## 7) Acceptance Criteria (MANDATORY)

- Saved screen never crashes when a joined task row is null, unreadable, or deleted.
- Saved icon state, saved list contents, and profile badge count remain synchronized after every successful mutation.
- Only one mutation per task id can be in flight at a time.
- Saved ViewModel no longer reaches into `Supabase.instance.client.auth` directly.
- Saved feature has one intentional navigation seam and no dead parallel route helper left in runtime usage.
- The orphan-row UX is implemented exactly as locked in `DECISION_SavedOrphanUX`.
- Live `saved_tasks` schema/RLS/indexes are verified through authenticated Supabase scan before release, or the release remains blocked.
- No fake historical migration is created to explain live `saved_tasks`.
- Direct saved unit/widget coverage exists, and any integration coverage follows explicit selectors/fixtures/preflight rules.
- `flutter analyze` remains clean and saved-related tests pass.

## 8) Rollback Plan

- DB rollback/forward-fix steps:
  - If a forward reconcile migration is added, rollback by forward-fixing with a corrective migration rather than dropping live objects.
  - If live scan reveals no DB changes are needed, do not create a migration just for parity.
  - If authenticated live scan never completes, no DB reconcile or release work proceeds.
- App rollback (flag/revert):
  - Revert aggregate saved-row UI/state changes first if the saved screen regresses visually or behaviorally, while preserving any low-risk null-guard fix if it remains safe.
  - Revert shared save-button extraction independently if booking/tender cards regress.
  - Revert saved-session-service injection if startup/session behavior regresses, while keeping typed mutation/result fixes if possible.
- Emergency disable strategy (if applicable):
  - Disable unavailable-row special rendering and fall back to safe filtering only if the locked orphan-row UX proves unstable.
  - Keep per-task pending protection enabled even in emergency mode because it is low-risk correctness protection.

## 9) References (From Scan)

- Workflows / critique:
  - `.agents/workflows/planner.md:1-176`
  - `.agents/workflows/plan_critic.md:1-191`
  - `.TODO/saved.TODO.md:1-163`
  - `.TODO/PLAN_CRITIC_SavedFix_2026-03-04.md:1-191`
- Docs:
  - `Sline_everything/DEVELOPER_GUIDE.md:31-41`
  - `Sline_everything/DEVELOPER_GUIDE.md:65-69`
  - `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:12-137`
  - `Sline_everything/SUPABASE_SETUP.md:31-39`
  - `Sline_everything/SUPABASE_SETUP.md:769-778`
  - `Sline_everything/SUPABASE_SETUP.md:1120-1126`
  - `Sline_everything/SUPABASE_SETUP.md:1208-1212`
  - `Sline_everything/SUPABASE_SETUP.md:1574-1575`
  - `Sline_everything/MVP_ROADMAP.md:35-39`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md:14-23`
  - `Sline_everything/CODE_REVIEW.md:16-23`
  - `Sline_everything/STRUCTURE.md:167-176`
- App code:
  - `lib/main.dart:166-169`
  - `lib/features/saved/view/saved_tasks_screen.dart:13-169`
  - `lib/features/saved/viewmodels/saved_tasks_view_model.dart:15-152`
  - `lib/features/saved/data/saved_tasks_service.dart:8-137`
  - `lib/features/saved/models/saved_task_model.dart:4-52`
  - `lib/features/saved/view/widgets/saved_task_tile.dart:3-31`
  - `lib/features/saved/routes/saved_routes.dart:4-13`
  - `lib/features/profile/view/profile_screen.dart:427-443`
  - `lib/features/home/view/home_screen.dart:76-90`
  - `lib/features/tasks/view/widgets/booking_task_card.dart:153-181`
  - `lib/features/tasks/view/widgets/tender_task_card.dart:253-286`
  - `lib/features/profile/services/profile_summary_service.dart:6-58`
  - `lib/features/tasks/models/task_model.dart:106-179`
  - `lib/features/tasks/services/task_service.dart:47-88`
- Tests / support:
  - `test/test_support/pump_app.dart:5-18`
  - `test/integration_test/support/helpers.dart:19-228`
  - `test/integration_test/support/preflight.dart:5-56`
  - `test/widget/home/home_screen_test.dart:32-68`
  - `test/widget/home/home_screen_test.dart:133-152`
  - `test/widget/tasks/tenders_screen_test.dart:23-25`
  - `test/widget/tasks/tenders_screen_test.dart:71-95`
  - `test/widget/booking/bookings_discovery_screen_test.dart:23-25`
  - `test/widget/booking/bookings_discovery_screen_test.dart:71-95`
  - `pubspec.yaml:60-72`
- Repo-linked live metadata:
  - `supabase/.temp/project-ref:1`
  - `supabase/.temp/postgres-version:1`
  - `supabase/.temp/rest-version:1`
  - `supabase/.temp/storage-version:1`
- Live Supabase scan evidence:
  - `@mcp:supabase-mcp-server:` scan attempted in planning, but initialization failed with `Auth required`; authenticated live confirmation remains a gate, not completed evidence.
