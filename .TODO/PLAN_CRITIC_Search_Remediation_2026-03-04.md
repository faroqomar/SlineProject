## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- The target remains the `search` feature bounded to `lib/features/search/**` plus the direct dependencies already identified in the current remediation plan and audit. [File Reference: `lib/features/search/view/search_screen.dart:17-289`, `lib/features/search/viewmodels/search_view_model.dart:9-108`, `lib/features/search/services/search_service.dart:13-138`, `.TODO/PLAN_Search_Remediation_2026-03-04.md:13-15`]
- Existing widget and integration harnesses under `test/test_support/` and `test/integration_test/support/` are the baseline to extend, not replace. [File Reference: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`, `test/integration_test/support/preflight.dart:5-56`, `pubspec.yaml:60-72`]
- Strict MVVM and RLS remain the governing architecture rules for search remediation. [File Reference: `Sline_everything/DEVELOPER_GUIDE.md:43-68`, `lib/features/search/view/search_screen.dart:21-25`, `lib/features/search/services/search_service.dart:17-20`]
- The current session still has no file-backed proof of authenticated live Supabase scan results for `search_tasks`, `search_profiles`, `rpc_get_profile_summaries`, `categories`, or storage policies. [UNVERIFIED: missing authenticated live Supabase evidence in repo files for the current session]

### Decision Needed (Blocking)

1. Missing decision: is search a live runtime surface or an intentionally parked feature.
- Options:
  - Expose one deliberate app route or launcher.
  - Keep a QA-only route hidden from navigation.
  - Decommission the runtime surface and remove the feature.
- Recommended: expose one deliberate app route or launcher only after the release gate passes. [File Reference: `Sline_everything/MVP_ROADMAP.md:31-39`, `Sline_everything/CODE_REVIEW.md:12-25`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`]
- Why: the roadmap still marks search as active work, and the code-review guardrail explicitly rejects orphaned runtime surfaces. [File Reference: `Sline_everything/MVP_ROADMAP.md:31-39`, `Sline_everything/CODE_REVIEW.md:12-25`]
- What changes in the plan depending on the choice:
  - Live route: Phase 4 must wire navigation and add route coverage. [File Reference: `lib/main.dart:455-474`, `lib/features/search/view/search_screen.dart:237-261`]
  - QA-only route: release checklist must block user exposure and tests must use a non-prod entry path. [File Reference: `test/integration_test/support/helpers.dart:48-74`]
  - Decommission: the plan changes from remediation to removal/doc cleanup. [File Reference: `Sline_everything/CODE_REVIEW.md:20-25`, `lib/features/search/view/search_screen.dart:17-25`]

2. Missing decision: what is the canonical provenance strategy for `search_tasks`.
- Options:
  - Export the live function and reconcile forward-only.
  - Reconstruct the function from docs.
  - Leave the function undocumented and trust production.
- Recommended: export the live function first, then reconcile forward-only. [File Reference: `lib/features/search/services/search_service.dart:31-34`, `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:39`, `.TODO/search.TODO.md:198-204`]
- Why: the repo currently cannot prove the actual `search_tasks` contract. [File Reference: `lib/features/search/services/search_service.dart:31-34`, `Sline_everything/SUPABASE_SETUP.md:1196-1200`, `.TODO/search.TODO.md:39`]
- What changes in the plan depending on the choice:
  - Live export: Phase 1 stays safe and reviewable. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1212`]
  - Docs-only rewrite: security and compatibility assumptions become untrustworthy. [File Reference: `.TODO/search.TODO.md:39`, `.TODO/search.TODO.md:58`]
  - Leave undocumented: release remains blocked because repo and live DB still drift. [File Reference: `.TODO/search.TODO.md:39`, `.TODO/search.TODO.md:198-204`]

3. Missing decision: does this remediation ship pagination or explicitly cap search at one page.
- Options:
  - Implement load-more/infinite-scroll now.
  - Explicitly cap at one page and document it.
  - Keep `limit`/`offset` in services with no UI owner.
- Recommended: decide now; if pagination is not a release requirement, cap it explicitly and remove dead expectations from the UI/ViewModel contract. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/services/search_service.dart:85-89`, `lib/features/search/view/search_screen.dart:231-264`, `lib/features/search/viewmodels/search_view_model.dart:9-108`]
- Why: the current plan leaves pagination as an implementation choice, which is not execution-safe. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:77-103`, `.TODO/PLAN_Search_Remediation_2026-03-04.md:211-216`]
- What changes in the plan depending on the choice:
  - Implement now: tests and selectors need append/load-more states. [File Reference: `lib/features/search/view/search_screen.dart:231-264`]
  - Cap now: service/API expectations and acceptance criteria must say “first page only.” [File Reference: `lib/features/search/services/search_service.dart:25-29`]
  - Leave ambiguous: stale product scope leaks into Phase 3 and Phase 5. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:211-216`]

4. Missing decision: what happens if live Supabase auth remains unavailable during execution.
- Options:
  - Block all work.
  - Proceed with app-safe fixes but block DB reconcile and release.
  - Trust docs/local metadata and keep going.
- Recommended: proceed with app-safe fixes but block DB reconcile and release until authenticated live scan succeeds. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:109-136`, `.TODO/search.TODO.md:39`, `.TODO/search.TODO.md:181-196`]
- Why: blocking everything would stall safe app-side work, but trusting docs would create fake DB progress. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:39`]
- What changes in the plan depending on the choice:
  - Block all work: safest but unnecessarily stalls UI/App fixes. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:109-136`]
  - App-only proceed: safest practical path. [File Reference: `.TODO/search.TODO.md:181-196`]
  - Trust docs: invalid because `search_tasks` provenance is already missing. [File Reference: `.TODO/search.TODO.md:39`, `.TODO/search.TODO.md:198-204`]

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate
- Status: ❌ FAIL
- Reason:
  - The current plan has no dedicated search-specific test infrastructure gate before implementation, even though it expects new unit/widget/integration coverage later. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:180-221`, `.TODO/PLAN_Search_Remediation_2026-03-04.md:248-255`]
  - Search UI files currently expose no stable keys/selectors for the input, tab toggle, or result rows. [File Reference: `lib/features/search/view/search_screen.dart:79-92`, `lib/features/search/view/search_screen.dart:129-143`, `lib/features/search/view/search_screen.dart:231-264`, `lib/features/search/view/widgets/search_result_profile_card.dart:26-96`]
  - Search-specific test files are UNVERIFIED because the current repo scan found no `test/**/search/**` files. [UNVERIFIED: missing files under `test/unit/search/`, `test/widget/search/`, `test/integration_test/search/`]
- What to add/fix to pass:
  - Add `Phase 0.0 Test Infrastructure Gate`.
  - Create `.TODO/TEST_INFRA_Search_2026-03-04.md` and `.TODO/FIXTURES_Search_2026-03-04.md`.
  - Define stable selectors before any new search tests are authored. [File Reference: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`]

### Gate 1: Data/Contracts Gate
- Status: ❌ FAIL
- Reason:
  - The current plan does not lock the route-ownership decision before app and UI work. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:79-101`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`]
  - The plan does not freeze the pagination decision before Phase 3 even though the service contract already exposes `limit`/`offset` and the UI does not. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:160-161`, `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/view/search_screen.dart:231-264`]
  - The plan does not explicitly lock the shared hydration contract before splitting services, even though the current search hydrator already drifts from `TaskService`. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:146-155`, `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:72-87`]
- What to add/fix to pass:
  - Add blocking decision docs for reachability and pagination.
  - Expand `.TODO/CONTRACT_Search_2026-03-04.md` to include the shared task-hydration contract and degraded-enrichment semantics.
  - Add `.TODO/UI_STATE_MATRIX_Search_2026-03-04.md` before app/UI changes.

### Gate 2: Security Gate
- Status: ❌ FAIL
- Reason:
  - Authenticated live Supabase evidence is still unavailable, so the plan cannot prove current DB/security reality for `search_tasks`, `categories`, or storage. [UNVERIFIED: missing authenticated live scan evidence in repo files for the current session]
  - The current safe-summary functions still do not filter moderated accounts. [File Reference: `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`]
  - The current plan asks for security checks, but it does not give a hard stop/go rule for DB reconcile and release when live scan remains blocked. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:109-136`, `.TODO/PLAN_Search_Remediation_2026-03-04.md:203-216`]
- What to add/fix to pass:
  - Add an explicit Live Access Gate that allows app-only work but blocks DB/release without authenticated evidence.
  - Add exact positive/negative RLS queries and live-export requirements.
  - Add categories/storage access verification to the same gate.

### Gate 3: Backend/API Gate
- Status: ❌ FAIL
- Reason:
  - The plan proposes splitting `search_service.dart` before explicitly choosing the canonical shared hydrator. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:152-155`, `lib/features/search/services/search_service.dart:13-138`, `lib/features/tasks/services/task_service.dart:47-87`]
  - Partial enrichment failures still have no locked visible behavior. [File Reference: `lib/features/search/services/search_service.dart:104-136`, `.TODO/search.TODO.md:42`, `.TODO/search.TODO.md:63`]
  - The plan does not freeze stale-request semantics before ViewModel refactor. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:160-161`, `lib/features/search/viewmodels/search_view_model.dart:42-106`]
- What to add/fix to pass:
  - Move the shared hydrator contract ahead of service splits.
  - Add explicit degraded-enrichment behavior to the contract/state matrix.
  - Add a request-ordering contract before ViewModel changes.

### Gate 4: UI/Integration Gate
- Status: ❌ FAIL
- Reason:
  - Search row taps are still placeholders, so the current UX contract is incomplete. [File Reference: `lib/features/search/view/search_screen.dart:237-243`, `lib/features/search/view/search_screen.dart:256-261`]
  - Search is not reachable from audited app-shell files, and the plan leaves that as an early decision without binding it to a release gate. [File Reference: `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`, `.TODO/PLAN_Search_Remediation_2026-03-04.md:79-101`, `.TODO/PLAN_Search_Remediation_2026-03-04.md:178-181`]
  - The plan has no search-specific UI state matrix even though the ViewModel has race-prone loading/error transitions. [File Reference: `lib/features/search/view/search_screen.dart:179-289`, `lib/features/search/viewmodels/search_view_model.dart:42-106`]
- What to add/fix to pass:
  - Add `.TODO/UI_STATE_MATRIX_Search_2026-03-04.md`.
  - Tie the route-ownership decision to Gate 4 and Gate 5.
  - Require selectors/keys to remain present through UI refactors.

### Gate 5: Release/QA Gate
- Status: ❌ FAIL
- Reason:
  - The current plan has no PR slicing artifact, reviewer checklist, or release checklist. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:1-281`, `Sline_everything/CODE_REVIEW.md:20-25`]
  - The plan lists acceptance criteria and test goals, but it does not define a go/no-go artifact that joins live DB evidence, manual scenarios, and docs sync. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:228-247`]
  - The current plan does not define failure artifact capture or rerun thresholds for search integration work. [File Reference: `test/integration_test/support/helpers.dart:78-127`, `.TODO/PLAN_Search_Remediation_2026-03-04.md:209-216`]
- What to add/fix to pass:
  - Add `.TODO/PR_PLAN_Search_2026-03-04.md`.
  - Add `.TODO/RELEASE_CHECKLIST_Search_2026-03-04.md`.
  - Add failure artifact and rerun policy to the test infrastructure gate.

## C) Critical Gaps (Must-Fix)

### Gap 1
- Gap: no search-specific Test Infrastructure Gate exists.
- Why it will break: tests will be authored against unstable text/layout and ad hoc fixture assumptions. [File Reference: `lib/features/search/view/search_screen.dart:79-92`, `lib/features/search/view/search_screen.dart:129-143`, `test/integration_test/support/helpers.dart:78-127`]
- Fix (exact step(s) to add / reorder):
  - Add `Phase 0.0 Test Infrastructure Gate`.
  - Create `.TODO/TEST_INFRA_Search_2026-03-04.md`.
  - Create `.TODO/FIXTURES_Search_2026-03-04.md`.
- Owner: Frontend
- Acceptance check: selectors, fixture manifest, timeout budgets, rerun policy, and failure artifact path exist before new search tests are written. [File Reference: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/preflight.dart:10-56`]

### Gap 2
- Gap: route ownership is not locked.
- Why it will break: the team can fix internals and still leave search as a compiled-but-unreachable feature. [File Reference: `lib/features/search/view/search_screen.dart:17-25`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`, `Sline_everything/CODE_REVIEW.md:12-25`]
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/DECISION_SearchReachability_2026-03-04.md` in Phase 0.
  - Block Phase 4 until the decision is signed off.
- Owner: Product
- Acceptance check: one explicit route/nav/decommission decision is documented and reused across UI, tests, and release checklist.

### Gap 3
- Gap: `search_tasks` provenance is still undocumented.
- Why it will break: the team can “fix” the function from docs alone and ship a contract mismatch. [File Reference: `lib/features/search/services/search_service.dart:31-34`, `Sline_everything/SUPABASE_SETUP.md:1196-1200`, `.TODO/search.TODO.md:39`]
- Fix (exact step(s) to add / reorder):
  - Add `Phase 0.1 Live Access Gate`.
  - Add `.TODO/DB_PROVENANCE_Search_2026-03-04.md`.
  - Forbid fake historical migrations; allow only forward reconcile after live export.
- Owner: Backend
- Acceptance check: live function export exists and reconcile strategy is reviewable before any search-task migration is authored.

### Gap 4
- Gap: the shared task-hydration contract is not locked before service splits.
- Why it will break: search and tasks can keep diverging on owner fallback and degraded enrichment behavior. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:72-87`, `.TODO/PLAN_Search_Remediation_2026-03-04.md:152-155`]
- Fix (exact step(s) to add / reorder):
  - Expand `.TODO/CONTRACT_Search_2026-03-04.md` to include shared hydration.
  - Move hydrator contract work ahead of service splitting.
- Owner: Backend
- Acceptance check: search and tasks use one documented owner/profile/category merge contract.

### Gap 5
- Gap: pagination is still ambiguous.
- Why it will break: tests and UI state handling cannot be finalized while page ownership remains undefined. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/services/search_service.dart:85-89`, `lib/features/search/view/search_screen.dart:231-264`]
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/DECISION_SearchPagination_2026-03-04.md` before ViewModel/UI work.
- Owner: Product
- Acceptance check: the release scope explicitly says either “page one only” or “pagination shipped,” and tests match that decision.

### Gap 6
- Gap: no UI state matrix exists for race/degraded-result behavior.
- Why it will break: loading/error/empty/degraded states will stay inconsistent across ViewModel and screen refactors. [File Reference: `lib/features/search/view/search_screen.dart:179-289`, `lib/features/search/viewmodels/search_view_model.dart:42-106`, `lib/features/search/services/search_service.dart:104-136`]
- Fix (exact step(s) to add / reorder):
  - Create `.TODO/UI_STATE_MATRIX_Search_2026-03-04.md` before Phase 3.
- Owner: Frontend
- Acceptance check: every user-visible state has one expected render path and one test target.

### Gap 7
- Gap: no PR slicing or release checklist exists.
- Why it will break: DB/RLS changes, DTO/hydrator work, UI wiring, and tests can land in one high-risk batch. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:1-281`, `Sline_everything/CODE_REVIEW.md:20-25`]
- Fix (exact step(s) to add / reorder):
  - Create `.TODO/PR_PLAN_Search_2026-03-04.md`.
  - Create `.TODO/RELEASE_CHECKLIST_Search_2026-03-04.md`.
- Owner: Product
- Acceptance check: each slice has definition of done, gate checks, and rollback points.

## D) Invariants & Success Criteria (Non-Negotiable)

1. Invariant: moderated or restricted accounts never appear in search profile results or task-author summaries unless a signed-off exception is checked in.
- How to enforce: server-side filters in `search_profiles` and `rpc_get_profile_summaries`, not Flutter UX checks. [File Reference: `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`]
- How to verify: positive/negative SQL checks in `.TODO/RLS_Search_2026-03-04.md`. [File Reference: `.TODO/search.TODO.md:181-196`]

2. Invariant: search task author enrichment uses the same fallback order as the main task feature.
- How to enforce: one shared hydrator contract and one shared implementation. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:72-87`, `lib/features/tasks/models/task_model.dart:139-150`]
- How to verify: unit tests prove owner fallback and category/profile merge behavior match. [File Reference: `.TODO/search.TODO.md:172-175`]

3. Invariant: search result taps are never log-only in a live feature.
- How to enforce: row taps navigate to task/profile detail or the feature is explicitly removed from runtime. [File Reference: `lib/features/search/view/search_screen.dart:237-243`, `lib/features/search/view/search_screen.dart:256-261`, `lib/features/tasks/view/task_details_screen.dart:27-35`, `lib/features/profile/view/public_profile_screen.dart:24-32`]
- How to verify: widget/manual tests cover both task and profile row taps. [File Reference: `.TODO/search.TODO.md:176-180`, `.TODO/search.TODO.md:188-193`]

4. Invariant: only the latest query/tab request may update visible search state.
- How to enforce: request sequencing/tokening in `SearchViewModel`. [File Reference: `lib/features/search/viewmodels/search_view_model.dart:42-106`]
- How to verify: unit tests for stale-result suppression and rapid tab switching. [File Reference: `.TODO/search.TODO.md:168-171`]

5. Invariant: safe-summary rows are parsed into an explicit summary DTO, not `ProfileModel`.
- How to enforce: add `profile_summary_model.dart` and restrict safe-summary consumers to it. [File Reference: `lib/features/profile/services/profile_summary_service.dart:60-93`, `lib/features/profile/models/profile_model.dart:1-100`]
- How to verify: compile-time usage and unit tests for summary parsing. [File Reference: `.TODO/search.TODO.md:157-176`]

6. Invariant: no fake historical migration is created for `search_tasks`.
- How to enforce: provenance artifact plus forward-only reconcile rule. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:198-204`]
- How to verify: migration review shows only additive or compatibility-forward changes.

7. Invariant: views remain free of direct Supabase access.
- How to enforce: search views talk to ViewModels only, and any added instrumentation/resolvers stay in services/viewmodels. [File Reference: `Sline_everything/DEVELOPER_GUIDE.md:54-58`, `lib/features/search/view/search_screen.dart:21-25`, `lib/features/search/services/search_service.dart:17-20`]
- How to verify: grep check for direct Supabase references inside `lib/features/search/view/**`.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Live Supabase auth stays blocked | `search_tasks`, `categories`, storage verification remain UNVERIFIED. [UNVERIFIED: missing authenticated live scan evidence] | High | High | Feature | release checklist cannot attach live export evidence | add Live Access Gate and block DB/release without auth evidence | stop at app-only slices and do not expose route |
| Moderation-safe summary fix breaks sibling consumers | `ProfileSummaryService` is reused outside search. [File Reference: `lib/features/profile/services/profile_summary_service.dart:7-129`, `lib/features/tasks/services/task_service.dart:20-29`] | Med | High | Feature | sibling surfaces lose profile summaries after SQL change | use compatibility wrappers/versioned functions if shapes change | roll forward with compatibility function instead of destructive revert |
| Shared hydrator extraction still diverges from task feature | search and tasks currently hydrate owners differently. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:72-87`] | Med | High | Feature | task cards and search rows show different author data for same task | lock shared hydrator contract before splitting services | revert hydrator extraction only and keep existing task path stable |
| Route exposure happens before row navigation/tests are ready | search screen is currently orphaned and row taps are placeholders. [File Reference: `lib/main.dart:455-474`, `lib/features/search/view/search_screen.dart:237-261`] | Med | High | Feature | users can reach search but taps dead-end | bind route decision to Gate 4 and Gate 5 | keep route hidden until navigation/tests pass |
| Pagination remains ambiguous and half-implemented | services expose `limit`/`offset`, UI does not. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/view/search_screen.dart:231-264`] | Med | Med | Feature | tests and UI disagree on expected result counts | make pagination a blocking decision in Phase 0 | cap release at page one and document it |
| Search tests stay brittle | no selectors/fixtures currently exist. [File Reference: `lib/features/search/view/search_screen.dart:79-92`, `lib/features/search/view/search_screen.dart:129-143`, `lib/features/search/view/widgets/search_result_profile_card.dart:26-96`] | High | Med | Delivery | tests depend on text/layout and fail on cosmetic changes | add Gate 0 selector/fixture docs first | ship only unit/widget/manual evidence and record integration blocker |
| Degraded enrichment stays invisible | category/profile fetch failures are swallowed today. [File Reference: `lib/features/search/services/search_service.dart:104-136`] | Med | Med | Feature | search rows lose author/category data without any visible signal | add degraded-state contract and tests | fall back to visible degraded badge/error copy in UI |

## F) Pre-Mortem (How this fails in real life)

- This fails when the team wires `/search` into the app before row navigation and tests are ready, and users hit taps that only log IDs. [File Reference: `lib/main.dart:455-474`, `lib/features/search/view/search_screen.dart:237-261`]
- This fails when `search_tasks` is reconstructed from docs and later returns a different shape or access rule than production. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1200`, `lib/features/search/services/search_service.dart:31-34`]
- This fails when search and task feature keep separate owner fallback logic and the same task shows different author data depending on the screen. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:72-87`]
- This fails when moderated accounts remain visible in search because the team fixed Flutter-side filtering instead of the RPC SQL. [File Reference: `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`]
- This fails when pagination is left ambiguous and the UI silently caps results while product expects full discovery. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/view/search_screen.dart:231-264`]
- This fails when search tests are written against labels/layout instead of selectors and later get disabled after a copy change. [File Reference: `lib/features/search/view/search_screen.dart:217-218`, `lib/features/search/view/search_screen.dart:279-280`, `test/test_support/pump_app.dart:5-18`]
- This fails when live DB evidence never arrives and the team still claims RLS parity from docs alone. [UNVERIFIED: missing authenticated live scan evidence for the current session]

## G) Plan Fixes (Concrete Additions / Expansions)

1. Goal: add a search-specific Test Infrastructure Gate.
- Why: the current plan schedules tests without selectors, fixtures, or failure policy. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:180-221`]
- How: create `TEST_INFRA_Search`, `FIXTURES_Search`, and a selector map before any new test files are added. [File Reference: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`]
- Output artifact: test infra doc, fixture manifest, selector map.
- Stop condition: every planned search test references stable selectors and documented preconditions.

2. Goal: lock route ownership and pagination before implementation.
- Why: both are currently ambiguous and change release scope materially. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:79-101`, `.TODO/PLAN_Search_Remediation_2026-03-04.md:160-161`]
- How: create `DECISION_SearchReachability` and `DECISION_SearchPagination`.
- Output artifact: two decision docs.
- Stop condition: UI, test, and acceptance work all cite one route and pagination decision.

3. Goal: operationalize the live DB blocker.
- Why: the current plan mentions live scan work but still allows ambiguous DB progress. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:109-136`]
- How: add a Live Access Gate, a provenance artifact, and a hard rule that DB reconcile/release are blocked while live evidence is missing.
- Output artifact: `LIVE_SCAN_Search`, `DB_PROVENANCE_Search`.
- Stop condition: no search DB migration is authored without exported live function evidence.

4. Goal: lock shared search/task hydration and DTO boundaries.
- Why: the current bug set is partly a contract problem, not just an implementation problem. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/profile/services/profile_summary_service.dart:60-93`, `.TODO/search.TODO.md:41-47`]
- How: expand `CONTRACT_Search`, add `profile_summary_model.dart`, and move shared hydrator work before service splits.
- Output artifact: contract doc, summary DTO, shared hydrator plan.
- Stop condition: search and tasks consume one documented owner/profile/category merge contract.

5. Goal: make degraded states and release checks explicit.
- Why: partial enrichment failures and route exposure can otherwise ship invisibly. [File Reference: `lib/features/search/services/search_service.dart:104-136`, `lib/features/search/view/search_screen.dart:237-261`]
- How: create `UI_STATE_MATRIX_Search`, `PR_PLAN_Search`, and `RELEASE_CHECKLIST_Search`.
- Output artifact: state matrix, PR plan, release checklist.
- Stop condition: every visible state and release gate is testable and documented.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0.0: Test Infrastructure Gate
- Goal: make search testing deterministic before contract/app work starts.
- Why: selectors, fixtures, and rerun rules are currently missing. [File Reference: `lib/features/search/view/search_screen.dart:79-92`, `lib/features/search/view/search_screen.dart:129-143`, `test/integration_test/support/helpers.dart:78-127`]
- How:
  - Reuse `test/test_support/pump_app.dart`.
  - Reuse `test/integration_test/support/helpers.dart` and `test/integration_test/support/preflight.dart`.
  - Create `TEST_INFRA_Search` and `FIXTURES_Search`.
  - Add stable selectors to input, tabs, lists, and result rows.
- Result: search-specific tests have deterministic prerequisites.
- GATE CHECK:
  - selectors exist
  - fixture manifest exists
  - timeout/retry/failure artifact policy exists

### Phase 0.1: Live Access Gate
- Goal: turn the missing live DB evidence into an explicit stop/go rule.
- Why: `search_tasks` and categories/storage security cannot be trusted from docs alone. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:39`, `.TODO/search.TODO.md:54`]
- How:
  - Retry authenticated live scan.
  - If still blocked, record the blocker and allow only app-safe work.
  - Block DB reconcile and release until live evidence exists.
- Result: no fake progress on DB/security work.
- GATE CHECK:
  - either authenticated live evidence exists
  - or DB/release work is explicitly blocked

### Phase 0.2: Contract Lock
- Goal: freeze route ownership, pagination, DTOs, shared hydrator behavior, and UI states.
- Why: the current plan leaves all of these execution-critical choices ambiguous. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:79-101`, `.TODO/PLAN_Search_Remediation_2026-03-04.md:146-161`, `lib/features/search/services/search_service.dart:39-75`]
- How:
  - Create `DECISION_SearchReachability`
  - Create `DECISION_SearchPagination`
  - Create `CONTRACT_Search`
  - Create `UI_STATE_MATRIX_Search`
  - Create `DONE_CRITERIA_Search`
- Result: implementation has one contract path.
- GATE CHECK:
  - route ownership locked
  - pagination decision locked
  - DTO/hydrator contract locked
  - UI state matrix exists

### Phase 0.3: Delivery / Provenance Planning
- Goal: make rollout reviewable and forbid fake migration history.
- Why: missing `search_tasks` provenance and multi-surface UI work raise rollback risk. [File Reference: `.TODO/search.TODO.md:39`, `.TODO/search.TODO.md:198-204`, `Sline_everything/CODE_REVIEW.md:20-25`]
- How:
  - Create `DB_PROVENANCE_Search`
  - Create `PR_PLAN_Search`
  - Create `RELEASE_CHECKLIST_Search`
- Result: slice plan and rollback path are explicit.
- GATE CHECK:
  - provenance strategy documented
  - PR slices documented
  - release checklist drafted

### Phase 1: Data / Contracts
- Goal: export and lock the live `search_tasks` contract and the shared search payload rules.
- Why: repo/live drift already exists for `search_tasks`, and search still depends on over-broad or drifting payload assumptions. [File Reference: `lib/features/search/services/search_service.dart:31-75`, `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:39-41`]
- How:
  - export live `search_tasks`
  - prepare forward-only reconcile migration or compatibility wrapper
  - lock the fields search may consume
  - lock shared owner/category/profile merge rules
- Result: checked-in contracts and app payload assumptions are explicit.
- GATE CHECK:
  - live/exported SQL captured
  - no fake historical migration introduced
  - shared hydration contract agreed

### Phase 2: Security / RLS
- Goal: make safe-summary search flows moderation-safe and least-privilege.
- Why: moderated accounts are still discoverable through current summary RPC SQL. [File Reference: `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`]
- How:
  - harden `search_profiles`
  - harden `rpc_get_profile_summaries`
  - add exact positive/negative RLS query pack
  - verify categories/storage access
- Result: search summary visibility matches the moderation model.
- GATE CHECK:
  - moderated accounts excluded
  - query pack exists
  - categories/storage access documented

### Phase 3: Backend / App Logic
- Goal: fix DTO, hydrator, stale-request, and degraded-enrichment behavior behind one contract.
- Why: current search logic still drifts from task logic and allows stale async results. [File Reference: `lib/features/search/services/search_service.dart:39-136`, `lib/features/tasks/services/task_service.dart:72-87`, `lib/features/search/viewmodels/search_view_model.dart:42-106`]
- How:
  - add `profile_summary_model.dart`
  - extract shared hydrator
  - split/facade services only after contract lock
  - refactor `SearchViewModel` for latest-request-wins
  - implement the locked pagination decision
- Result: search app-layer behavior becomes deterministic and contract-compliant.
- GATE CHECK:
  - duplicate hydration removed
  - DTO boundary explicit
  - stale requests cannot overwrite latest state

### Phase 4: UI Wiring
- Goal: make the feature reachable by design and complete the primary navigation path.
- Why: the current runtime surface is orphaned and its primary taps do nothing. [File Reference: `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`, `lib/features/search/view/search_screen.dart:237-261`]
- How:
  - implement the route ownership decision
  - restore task/profile navigation
  - keep selectors intact
  - split screen widgets only after behavior is correct
  - align states to the UI matrix
- Result: one coherent search UX.
- GATE CHECK:
  - search is deliberately reachable or deliberately removed
  - row taps navigate correctly
  - selectors remain present

### Phase 5: QA / Release
- Goal: prove the search fix is safe to ship.
- Why: search spans security, navigation, async races, and live DB drift risk. [File Reference: `.TODO/search.TODO.md:181-204`, `lib/features/search/viewmodels/search_view_model.dart:42-106`]
- How:
  - add unit/widget tests
  - add integration coverage only if fixtures are ready
  - execute live query pack
  - run manual scenarios
  - complete release checklist
- Result: release evidence is explicit.
- GATE CHECK:
  - tests pass
  - live query pack passes
  - route/manual scenarios pass
  - release checklist signed off

### Phase 6: Documentation Sync
- Goal: sync docs to final code and verified DB reality.
- Why: search docs and runtime reachability are currently inconsistent. [File Reference: `Sline_everything/MVP_ROADMAP.md:31-39`, `lib/main.dart:455-474`, `.TODO/search.TODO.md:46`]
- How:
  - update `DEVELOPER_GUIDE.md`
  - update `SUPABASE_SETUP.md`
  - update `MVP_ROADMAP.md`
  - update `STRUCTURE.md`
  - update `Sline_Log.md`
- Result: docs stop restating unverified or outdated behavior.
- GATE CHECK:
  - docs match final code and authenticated live DB evidence

## I) Change Report (Diff-Style)

1. Original issues summary
- The original search plan covered the right surfaces, but it was still execution-unsafe because it lacked a Test Infrastructure Gate, a stop/go live-access gate, a locked route-ownership decision, a locked pagination decision, a shared hydrator contract, and release slicing/checklist artifacts. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:77-247`, `.TODO/search.TODO.md:39-51`]

2. Added steps (bullet list)
- Added `Phase 0.0 Test Infrastructure Gate`.
- Added `Phase 0.1 Live Access Gate`.
- Added blocking decision artifacts for reachability and pagination.
- Added `DB_PROVENANCE_Search`, `PR_PLAN_Search`, and `RELEASE_CHECKLIST_Search`.
- Added a UI state matrix and a stronger shared-hydrator contract.

3. Removed steps (if any)
- Removed the implicit assumption that DB work and release can proceed without authenticated live evidence. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:109-136`]

4. Reordered steps (from → to)
- Moved test infrastructure from an implied later concern → first execution gate.
- Moved live DB access from Phase 1 context → explicit Phase 0 stop/go gate.
- Moved route ownership, pagination, and shared-hydrator decisions from mixed implementation phases → pre-implementation contract lock.

5. Expanded steps (what became more detailed)
- Expanded `CONTRACT_Search` into route, DTO, pagination, and shared-hydrator decisions. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:88-96`, `.TODO/PLAN_Search_Remediation_2026-03-04.md:146-161`]
- Expanded QA into selectors, fixtures, rerun policy, live query pack, and release checklist. [File Reference: `.TODO/PLAN_Search_Remediation_2026-03-04.md:180-221`, `.TODO/PLAN_Search_Remediation_2026-03-04.md:228-247`]

6. Why (short, practical)
- The prior plan could still produce fake DB progress, route ambiguity, brittle tests, and duplicated hydration logic. The corrected version blocks ambiguity before implementation and binds release to verified evidence. [File Reference: `.TODO/search.TODO.md:39-51`, `Sline_everything/CODE_REVIEW.md:12-25`]

7. Residual risks (what still remains risky even after fixes)
- Authenticated live Supabase scan may remain blocked until external auth is restored. [UNVERIFIED: depends on live auth outside repo files]
- Safe-summary SQL hardening may still impact sibling consumers and require compatibility wrappers. [File Reference: `lib/features/profile/services/profile_summary_service.dart:7-129`, `lib/features/tasks/services/task_service.dart:20-29`]
- Search route exposure still touches multiple surfaces and must stay split into small PRs. [File Reference: `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`, `Sline_everything/CODE_REVIEW.md:20-25`]
