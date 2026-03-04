# 📌 Plan: Search Full Remediation (Critic-Revised)

## 1) Goal

- Goal: fix the full `search` feature surface, including security, data correctness, architecture drift, reachability, testing gaps, and documented server contracts. [File Reference: `lib/features/search/view/search_screen.dart:17-289`, `lib/features/search/viewmodels/search_view_model.dart:9-108`, `lib/features/search/services/search_service.dart:13-138`, `.TODO/search.TODO.md:35-112`]
- Why: current repo state still shows moderation gaps in safe-summary RPCs, missing checked-in `search_tasks` SQL, stale task-owner hydration logic, placeholder row taps, and an orphaned runtime surface. [File Reference: `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`, `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `lib/features/search/services/search_service.dart:31-75`, `lib/features/search/view/search_screen.dart:231-265`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`, `.TODO/search.TODO.md:39-51`]
- Result: one deliberate search surface whose Flutter contracts, SQL/RLS reality, route ownership, and automated coverage all agree before release. [File Reference: `Sline_everything/DEVELOPER_GUIDE.md:41-68`, `Sline_everything/CODE_REVIEW.md:12-25`, `.TODO/search.TODO.md:157-204`]

## 2) Scope

### In-Scope

- `lib/features/search/**` full remediation. [File Reference: `lib/features/search/view/search_screen.dart:1-289`, `lib/features/search/viewmodels/search_view_model.dart:1-108`, `lib/features/search/services/search_service.dart:1-138`, `lib/features/search/view/widgets/search_result_profile_card.dart:1-121`]
- Direct dependencies touched by search: `ProfileSummaryService`, `ProfileModel`, `Task`, `TaskService`, `TaskCard`, `TaskDetailsScreen`, `PublicProfileScreen`, `SignedAvatar`, `SignedImage`, `AvatarService`, `TaskImageService`, and app-shell route/navigation files. [File Reference: `lib/features/search/services/search_service.dart:1-6`, `lib/features/profile/services/profile_summary_service.dart:1-129`, `lib/features/profile/models/profile_model.dart:1-100`, `lib/features/tasks/models/task_model.dart:130-180`, `lib/features/tasks/services/task_service.dart:20-113`, `lib/features/tasks/view/task_details_screen.dart:1-80`, `lib/features/profile/view/public_profile_screen.dart:1-80`, `lib/core/widgets/signed_avatar.dart:1-145`, `lib/core/widgets/signed_image.dart:1-214`, `lib/features/profile/services/avatar_service.dart:1-62`, `lib/features/tasks/services/task_image_service.dart:1-134`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`]
- Search-related SQL/RLS/storage reality for `search_tasks`, `search_profiles`, `rpc_get_profile_summaries`, `profiles`, `categories`, `avatars`, and `task-images`. [File Reference: `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:1-63`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:1-49`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:10-31`, `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `Sline_everything/SUPABASE_SETUP.md:1192-1212`]

### Out-of-Scope

- Broad redesign of unrelated discovery features beyond the shared summary/hydration contracts search directly reuses. [File Reference: `Sline_everything/MVP_ROADMAP.md:31-39`, `Sline_everything/STRUCTURE.md:130-154`]
- Full rewrite of global signed-media infrastructure outside the minimum changes required to stop search-specific list churn and UI-owned async work. [File Reference: `lib/core/widgets/signed_avatar.dart:71-145`, `lib/core/widgets/signed_image.dart:51-133`, `.TODO/search.TODO.md:44`, `.TODO/search.TODO.md:51`]
- Product expansion of filters/sorting beyond the currently shipped task/profile query contract unless required for compatibility. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/services/search_service.dart:85-89`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:5-20`]

## 3) Blocking Decisions & Assumptions

### Assumptions

- Existing widget and integration harnesses under `test/test_support/` and `test/integration_test/support/` are the baseline to extend, not replace. [File Reference: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`, `test/integration_test/support/preflight.dart:5-56`, `pubspec.yaml:60-72`]
- Strict MVVM and RLS remain non-negotiable: views must not talk to Supabase directly, and authorization must remain server-side. [File Reference: `Sline_everything/DEVELOPER_GUIDE.md:43-68`, `lib/features/search/view/search_screen.dart:21-25`, `lib/features/search/services/search_service.dart:17-20`]
- The storage rule remains “store paths, not signed URLs,” so search fixes cannot persist signed URLs back into task/profile rows. [File Reference: `Sline_everything/DEVELOPER_GUIDE.md:66-68`, `lib/core/widgets/signed_avatar.dart:82-145`, `lib/core/widgets/signed_image.dart:67-133`]
- Live Supabase remains the source of truth for `search_tasks`, `search_profiles`, `rpc_get_profile_summaries`, and `categories`, but authenticated live scan evidence is UNVERIFIED in this session because no checked-in file can prove current live object state. [UNVERIFIED: missing authenticated `@mcp:supabase-mcp-server:` or `supabase` CLI evidence for the current session]

### Blocking Decisions

- Decision: is search a live user-facing surface or an intentionally parked feature.
  - Options: expose an explicit route/nav surface; keep a QA-only route hidden from navigation; decommission the runtime surface and remove the feature. [File Reference: `lib/features/search/view/search_screen.dart:17-25`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`, `Sline_everything/MVP_ROADMAP.md:31-39`, `Sline_everything/CODE_REVIEW.md:12-25`]
  - Recommended: keep search live, but only behind one deliberate route or launcher after Phase 5 passes. [File Reference: `Sline_everything/MVP_ROADMAP.md:31-39`, `Sline_everything/CODE_REVIEW.md:12-25`]
  - Why: the roadmap still lists search as active work, and the code-review guardrail explicitly rejects compiled-but-unreachable runtime surfaces. [File Reference: `Sline_everything/MVP_ROADMAP.md:31-39`, `Sline_everything/CODE_REVIEW.md:12-25`]
- Decision: what is the canonical provenance strategy for `search_tasks`.
  - Options: export the live function and reconcile forward-only; rewrite from docs; leave the function undocumented. [File Reference: `lib/features/search/services/search_service.dart:31-34`, `Sline_everything/SUPABASE_SETUP.md:1196-1200`, `.TODO/search.TODO.md:39`]
  - Recommended: export the live function first and check in a forward-only reconcile migration or compatibility wrapper. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:161-166`, `.TODO/search.TODO.md:198-204`]
  - Why: the repo cannot currently prove the live `search_tasks` contract, so doc-only reconstruction would be guesswork. [File Reference: `lib/features/search/services/search_service.dart:31-34`, `Sline_everything/SUPABASE_SETUP.md:1196-1200`, `.TODO/search.TODO.md:39`]
- Decision: does search ship as a first-page-only surface or does this remediation include pagination.
  - Options: explicitly cap at page one and remove dead pagination expectations; implement load-more/infinite-scroll now; keep dead `limit`/`offset` API shape with no UI owner. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/services/search_service.dart:85-89`, `lib/features/search/viewmodels/search_view_model.dart:9-108`, `lib/features/search/view/search_screen.dart:227-264`]
  - Recommended: make the product decision before app work; if no pagination is required for this release, remove dead pagination expectations from the ViewModel/UI contract and document the cap. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/view/search_screen.dart:231-264`]
  - Why: leaving unowned pagination parameters creates a fake scalability plan and weakens testing. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/viewmodels/search_view_model.dart:9-108`]
- Decision: what happens if live Supabase auth remains blocked during execution.
  - Options: block all work; proceed with app-safe fixes but block DB/release; trust docs/local metadata and continue. [File Reference: `.TODO/search.TODO.md:39`, `.TODO/search.TODO.md:54`, `Sline_everything/SUPABASE_SETUP.md:1196-1212`]
  - Recommended: proceed with app-safe fixes and tests, but block DB reconcile and release until the authenticated live scan succeeds. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:39`, `.TODO/search.TODO.md:181-196`]
  - Why: the repo is already missing `search_tasks` provenance, so trusting docs would create fake progress. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1200`, `.TODO/search.TODO.md:39`]

## 4) Evidence & Findings (From Scan)

### Existing

- A dedicated search module exists with separate task/profile modes and local provider composition. [File Reference: `lib/features/search/view/search_screen.dart:17-25`, `lib/features/search/view/search_screen.dart:112-143`, `lib/features/search/viewmodels/search_view_model.dart:13-34`]
- Search task results call `search_tasks` and then separately enrich profile summaries and categories. [File Reference: `lib/features/search/services/search_service.dart:25-75`, `lib/features/search/services/search_service.dart:104-136`]
- Search profile results use `ProfileSummaryService.searchProfiles()` backed by `public.search_profiles(...)`. [File Reference: `lib/features/search/services/search_service.dart:84-101`, `lib/features/profile/services/profile_summary_service.dart:60-127`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:5-61`]
- Cross-user profile summaries are intentionally served through server-side RPCs, not direct `profiles` reads. [File Reference: `Sline_everything/DEVELOPER_GUIDE.md:45-58`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`]
- Reusable widget and integration harnesses already exist. [File Reference: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`, `test/integration_test/support/preflight.dart:5-56`, `pubspec.yaml:60-72`]

### Missing

- Checked-in SQL for `public.search_tasks(...)` is still missing from repo state. [File Reference: `lib/features/search/services/search_service.dart:31-34`, `Sline_everything/SUPABASE_SETUP.md:1196-1200`, `.TODO/search.TODO.md:39`]
- Search result taps are still placeholders that only log IDs. [File Reference: `lib/features/search/view/search_screen.dart:237-243`, `lib/features/search/view/search_screen.dart:256-261`]
- Search has no route or shell registration in the audited app entry files. [File Reference: `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`, `.TODO/search.TODO.md:46`]
- Search-specific unit/widget/integration test files are UNVERIFIED because no `test/**/search/**` paths exist in the current repo scan. [UNVERIFIED: missing files under `test/unit/search/`, `test/widget/search/`, and `test/integration_test/search/`]
- A safe-summary-specific DTO is missing; cross-user summary rows are still parsed into `ProfileModel`. [File Reference: `lib/features/profile/services/profile_summary_service.dart:60-93`, `lib/features/profile/models/profile_model.dart:1-100`, `.TODO/search.TODO.md:47`]

### Must NOT Duplicate

- Do not add another parallel task-hydration path; search and tasks must share one owner/profile/category merge contract. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:47-87`, `.TODO/search.TODO.md:43`, `.TODO/search.TODO.md:64-67`]
- Do not parse safe-summary search rows into the full-profile model once a dedicated summary DTO exists. [File Reference: `lib/features/profile/services/profile_summary_service.dart:88-93`, `lib/features/profile/models/profile_model.dart:1-100`, `.TODO/search.TODO.md:47`]
- Do not invent `search_tasks` SQL from docs alone. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1200`, `.TODO/search.TODO.md:39`, `.TODO/search.TODO.md:161-166`]
- Do not ship search as a compiled-but-unreachable surface. [File Reference: `lib/features/search/view/search_screen.dart:17-25`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`, `Sline_everything/CODE_REVIEW.md:12-25`]

### Conflicts / Risks

- The roadmap says search is still in progress, but the current app shell does not expose the screen. [File Reference: `Sline_everything/MVP_ROADMAP.md:31-39`, `lib/features/search/view/search_screen.dart:17-25`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`]
- Moderation fields now exist on `profiles`, but neither safe-summary function filters `account_status`. [File Reference: `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`]
- Search task hydration only uses `user_id`, while the canonical task flow falls back through `owner_id` and `client_id`. [File Reference: `lib/features/search/services/search_service.dart:39-66`, `lib/features/tasks/services/task_service.dart:72-87`, `lib/features/tasks/models/task_model.dart:139-150`]
- Search silently swallows profile/category enrichment failures and returns degraded task rows without surfacing the partial-failure state. [File Reference: `lib/features/search/services/search_service.dart:104-136`, `.TODO/search.TODO.md:42`, `.TODO/search.TODO.md:63`]
- Current live DB reality for `search_tasks`, `categories` policies, and storage policies remains UNVERIFIED until authenticated live scan is restored. [UNVERIFIED: missing authenticated live Supabase evidence for the current session]

## 5) System Impact Map

- UI: search input, tab toggle, loading/error/empty/result branches, row navigation, and app entry wiring. [File Reference: `lib/features/search/view/search_screen.dart:45-289`, `lib/features/search/view/widgets/search_result_profile_card.dart:20-96`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`]
- MVVM/App Logic: debounce, request sequencing, retry, pagination ownership, task/profile service split, and shared task hydration. [File Reference: `lib/features/search/viewmodels/search_view_model.dart:42-106`, `lib/features/search/services/search_service.dart:13-138`, `lib/features/tasks/services/task_service.dart:47-87`]
- Database: `search_tasks`, `search_profiles`, `rpc_get_profile_summaries`, and `categories` reads used for enrichment. [File Reference: `lib/features/search/services/search_service.dart:31-34`, `lib/features/profile/services/profile_summary_service.dart:21-25`, `lib/features/profile/services/profile_summary_service.dart:77-86`, `lib/features/search/services/search_service.dart:117-136`, `Sline_everything/SUPABASE_SETUP.md:1196-1212`]
- RLS/Security: self-only `profiles`, moderated-account exclusion, authenticated-only RPCs, and storage visibility boundaries for avatars/task images. [File Reference: `supabase/migrations/20260301_harden_home_related_read_policies.sql:10-31`, `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `lib/features/profile/services/avatar_service.dart:54-61`, `lib/features/tasks/services/task_image_service.dart:106-118`]
- Testing/Release: search has reusable harnesses but no feature-specific selectors, fixtures, or release checklist yet. [File Reference: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`, `test/integration_test/support/preflight.dart:5-56`, `lib/features/search/view/search_screen.dart:79-92`, `lib/features/search/view/search_screen.dart:129-143`, `lib/features/search/view/search_screen.dart:231-264`]

## 6) Execution Gates

- Gate 0: Test Infrastructure Gate
  - Pass condition: search selectors/keys, fixture manifest, timeout budgets, and failure artifact policy exist before any new search tests are written. [File Reference: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`, `test/integration_test/support/preflight.dart:5-56`, `lib/features/search/view/search_screen.dart:79-92`, `lib/features/search/view/search_screen.dart:129-143`, `lib/features/search/view/search_screen.dart:231-264`]
- Gate 1: Data/Contracts Gate
  - Pass condition: route ownership, `search_tasks` provenance, pagination decision, safe-summary DTO shape, and shared task-hydration contract are written in `.TODO/` and approved before app changes begin. [File Reference: `lib/features/search/services/search_service.dart:25-75`, `lib/features/profile/services/profile_summary_service.dart:60-93`, `lib/features/tasks/services/task_service.dart:72-87`, `.TODO/search.TODO.md:39-51`]
- Gate 2: Security Gate
  - Pass condition: authenticated live scan evidence exists for touched objects, moderated-account exclusion is proven for search summary RPCs, and categories/storage access checks are documented. [File Reference: `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`, `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `lib/features/search/services/search_service.dart:117-136`]
- Gate 3: Backend/API Gate
  - Pass condition: one shared task-hydration path exists, the ViewModel is stale-request-safe, and service contracts match the locked DTO/SQL shape. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:47-87`, `lib/features/search/viewmodels/search_view_model.dart:42-106`]
- Gate 4: UI/Integration Gate
  - Pass condition: search is either deliberately reachable or deliberately removed, row taps navigate correctly, and all UI states map to a documented state matrix with stable selectors. [File Reference: `lib/features/search/view/search_screen.dart:186-289`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`]
- Gate 5: Release/QA Gate
  - Pass condition: unit/widget/manual checks pass, live DB verification is recorded, docs are synced, and the release checklist is signed off. [File Reference: `.TODO/search.TODO.md:181-204`, `Sline_everything/CODE_REVIEW.md:20-25`]

---

# ✅ Execution Phases (Checklist)

## Phase 0.0: Test Infrastructure Gate

> Primary: @Sentinel

### 0.0.1 Harness + Selectors

- [ ] (@Sentinel) Create `.TODO/TEST_INFRA_Search_2026-03-04.md` describing the widget and integration harnesses search will reuse, bounded timeouts, rerun policy, and failure artifact path/tagging. [File Reference: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`, `test/integration_test/support/preflight.dart:5-56`, `pubspec.yaml:60-72`]
- [ ] (@Pixel) Define stable keys/selectors for the search input, tab toggle buttons, result lists, and result rows before any widget/integration tests are written. [File Reference: `lib/features/search/view/search_screen.dart:79-92`, `lib/features/search/view/search_screen.dart:129-143`, `lib/features/search/view/search_screen.dart:231-264`, `lib/features/search/view/widgets/search_result_profile_card.dart:26-96`]
- [ ] (@Sentinel) Create `.TODO/FIXTURES_Search_2026-03-04.md` listing minimum search test fixtures, account roles, moderated-account fixtures, and expected task/profile markers. [File Reference: `test/integration_test/support/preflight.dart:10-56`, `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`]
- **Verify (@Sentinel):** Gate 0 passes only when selectors, fixture manifest, timeout budgets, and failure artifact rules exist.

## Phase 0.1: Live Access Gate

> Primary: @Supabase_Ops

### 0.1.1 Stop/Go Rule

- [ ] (@Supabase_Ops) Retry the planner-required authenticated live scan for `search_tasks`, `search_profiles`, `rpc_get_profile_summaries`, `profiles`, `categories`, `avatars`, and `task-images`, and store results in `.TODO/LIVE_SCAN_Search_2026-03-04.md`. [UNVERIFIED until execution restores authenticated live access]
- [ ] (@Sentinel) Record the stop/go rule in `.TODO/LIVE_SCAN_Search_2026-03-04.md`: app-safe fixes may proceed while live access is blocked, but DB reconcile and release remain blocked. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:39`, `.TODO/search.TODO.md:181-196`]
- **Verify (@Sentinel):** either authenticated live evidence exists, or the plan is explicitly in app-only mode with DB/release blocked.

## Phase 0.2: Contract Lock

> Primary: @APIContract

### 0.2.1 Product / Data Contracts

- [ ] (@Sentinel) Create `.TODO/DONE_CRITERIA_Search_2026-03-04.md` from the audit findings so non-regression checks are measurable. [File Reference: `.TODO/search.TODO.md:35-204`]
- [ ] (@Architect) Create `.TODO/DECISION_SearchReachability_2026-03-04.md` locking the product decision for live route/nav ownership versus decommission. [File Reference: `lib/features/search/view/search_screen.dart:17-25`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`, `Sline_everything/MVP_ROADMAP.md:31-39`]
- [ ] (@Architect) Create `.TODO/DECISION_SearchPagination_2026-03-04.md` locking whether this release is capped at one page or must implement load-more. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/services/search_service.dart:85-89`, `lib/features/search/view/search_screen.dart:231-264`]
- [ ] (@APIContract) Create `.TODO/CONTRACT_Search_2026-03-04.md` for Flutter ↔ SQL shape alignment, including the safe-summary DTO, `search_tasks` return shape, and the shared task-hydration fallback rules. [File Reference: `lib/features/search/services/search_service.dart:25-101`, `lib/features/profile/services/profile_summary_service.dart:60-93`, `lib/features/tasks/models/task_model.dart:139-178`, `lib/features/tasks/services/task_service.dart:72-87`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:11-20`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:4-13`]
- [ ] (@Pixel) Create `.TODO/UI_STATE_MATRIX_Search_2026-03-04.md` covering loading, empty, error, no-results, stale-request suppression, navigation-ready success, and degraded enrichment states. [File Reference: `lib/features/search/view/search_screen.dart:179-289`, `lib/features/search/viewmodels/search_view_model.dart:42-106`, `lib/features/search/services/search_service.dart:104-136`]
- **Verify (@Sentinel):** Gate 1 passes only when reachability, pagination, payload contract, and UI states are frozen.

## Phase 0.3: Delivery / Provenance Planning

> Primary: @DataMigration

### 0.3.1 Rollout Safety

- [ ] (@DataMigration) Create `.TODO/DB_PROVENANCE_Search_2026-03-04.md` documenting the forward-only reconciliation strategy for `search_tasks`; fake historical migrations are forbidden. [File Reference: `lib/features/search/services/search_service.dart:31-34`, `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:161-166`, `.TODO/search.TODO.md:198-204`]
- [ ] (@Sentinel) Create `.TODO/PR_PLAN_Search_2026-03-04.md` splitting work into reviewable slices with rollback points. [File Reference: `Sline_everything/CODE_REVIEW.md:20-25`, `.TODO/search.TODO.md:198-204`]
- [ ] (@Sentinel) Create `.TODO/RELEASE_CHECKLIST_Search_2026-03-04.md` tying together live DB evidence, automated tests, manual scenarios, docs sync, and rollback artifacts. [File Reference: `.TODO/search.TODO.md:181-204`, `Sline_everything/CODE_REVIEW.md:20-25`]
- **Verify (@Sentinel):** provenance, PR slicing, and release checklist exist before data/security work begins.

## Phase 1: Data / Contracts

> Primary: @Supabase_Ops

### 1.1 Live Contract Export

- [ ] (@Supabase_Ops) Export the live definition, grants, and dependencies for `public.search_tasks(text, integer, integer)` and store them in `.TODO/LIVE_SCAN_Search_2026-03-04.md` before writing any migration. [UNVERIFIED until authenticated live scan succeeds]
- [ ] (@DataMigration) Prepare an additive-first migration or compatibility wrapper for `search_tasks` only after the live definition is exported and compared to docs. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:161-166`, `.TODO/search.TODO.md:198-204`]
- [ ] (@APIContract) Lock the exact fields the task search contract may expose and remove any undocumented dependencies on broader summary payloads. [File Reference: `lib/features/search/services/search_service.dart:50-75`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:4-39`, `.TODO/search.TODO.md:40`]
- **Verify (@Sentinel):** Gate 1 remains open until checked-in SQL, exported live SQL, and Flutter contract docs agree.

### 1.2 Shared Hydration Contract

- [ ] (@Architect) Define the shared task summary hydration contract in `.TODO/CONTRACT_Search_2026-03-04.md`, using the same owner fallback order as `TaskService`. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:72-87`, `lib/features/tasks/models/task_model.dart:139-150`]
- [ ] (@Sentinel) Add exact degraded-enrichment expectations to `.TODO/UI_STATE_MATRIX_Search_2026-03-04.md` so category/profile lookup failures are visible and testable. [File Reference: `lib/features/search/services/search_service.dart:104-136`, `.TODO/search.TODO.md:42`, `.TODO/search.TODO.md:63`]
- **Verify (@Sentinel):** search and tasks now have one owner/profile/category merge contract.

## Phase 2: Security / RLS

> Primary: @Supabase_Ops

### 2.1 Moderation-Safe Summary Paths

- [ ] (@Supabase_Ops) Harden `search_profiles` and `rpc_get_profile_summaries` so `profiles.account_status <> 'active'` users do not appear unless a signed-off exception is documented. [File Reference: `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`]
- [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_Search_2026-03-04.md` covering moderated-user discoverability, unauthorized summary access, orphan-route exposure, and signed-media abuse cases. [File Reference: `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:21-60`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:18-47`, `lib/core/widgets/signed_avatar.dart:82-145`, `lib/core/widgets/signed_image.dart:67-133`]
- [ ] (@Supabase_Ops) Create `.TODO/RLS_Search_2026-03-04.md` with exact positive/negative queries for `search_profiles`, `rpc_get_profile_summaries`, `search_tasks`, and `categories` access. [File Reference: `supabase/migrations/20260301_harden_home_related_read_policies.sql:10-31`, `lib/features/search/services/search_service.dart:117-136`, `.TODO/search.TODO.md:181-196`]
- **Verify (@Sentinel):** Gate 2 passes only when negative cases fail, positive cases pass, and categories/storage access is documented.

### 2.2 Storage / Least Privilege

- [ ] (@Supabase_Ops) Verify the storage policies search can trigger for `avatars` and `task-images`, and record any policy drift in `.TODO/LIVE_SCAN_Search_2026-03-04.md`. [UNVERIFIED until authenticated live scan succeeds]
- [ ] (@Sentinel) Confirm search logs and UI do not expose sensitive payloads or tokens while security fixes are applied. [File Reference: `lib/features/profile/services/profile_summary_service.dart:34-52`, `lib/features/profile/services/profile_summary_service.dart:66-125`, `lib/core/services/supabase_config.dart:6-21`]
- **Verify (@Sentinel):** least-privilege access remains intact and logging stays privacy-safe.

## Phase 3: App Layer (MVVM)

> Primary: @Architect

### 3.1 Models & Services

- [ ] (@Architect) Add `lib/features/profile/models/profile_summary_model.dart` and migrate safe-summary consumers off `ProfileModel` for cross-user search/profile-summary paths. [File Reference: `lib/features/profile/services/profile_summary_service.dart:60-93`, `lib/features/profile/models/profile_model.dart:1-100`, `.TODO/search.TODO.md:47`, `.TODO/search.TODO.md:157-176`]
- [ ] (@Architect) Extract one shared hydrator under `lib/features/tasks/services/task_summary_hydrator.dart` and route both search and task feature enrichment through it. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:47-87`, `.TODO/search.TODO.md:43`]
- [ ] (@Architect) Split `lib/features/search/services/search_service.dart` only after the shared hydrator contract is locked, keeping a temporary facade if needed for low-risk migration. [File Reference: `lib/features/search/services/search_service.dart:13-138`, `.TODO/search.TODO.md:141-156`]
- [ ] (@Observability) If degraded enrichment remains possible, document request correlation and failure taxonomy in `.TODO/OBSERVABILITY_Search_2026-03-04.md` at the service/ViewModel layer, not in widgets. [File Reference: `lib/features/search/services/search_service.dart:76-136`, `lib/features/profile/services/profile_summary_service.dart:34-52`, `lib/features/search/view/search_screen.dart:237-260`]
- **Verify (@Sentinel):** Gate 3 passes only when duplicate hydration logic is removed and DTO boundaries are explicit.

### 3.2 ViewModel Contract

- [ ] (@Architect) Refactor `SearchViewModel` so only the latest request may win, tab changes cannot rehydrate stale results, and retry respects the active tab/query snapshot. [File Reference: `lib/features/search/viewmodels/search_view_model.dart:42-106`, `.TODO/search.TODO.md:49`]
- [ ] (@Architect) Implement the locked pagination decision: either add load-more state/append behavior or remove dead pagination expectations from the ViewModel/UI contract. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/services/search_service.dart:85-89`, `lib/features/search/view/search_screen.dart:231-264`, `.TODO/search.TODO.md:50`]
- [ ] (@Architect) Surface degraded enrichment explicitly if the contract requires visible fallback instead of silently returning partial task rows. [File Reference: `lib/features/search/services/search_service.dart:104-136`, `.TODO/search.TODO.md:42`, `.TODO/search.TODO.md:63`]
- **Verify (@Sentinel):** state transitions match `.TODO/UI_STATE_MATRIX_Search_2026-03-04.md`.

## Phase 4: UI Wiring

> Primary: @Pixel

### 4.1 Reachability + Navigation

- [ ] (@Pixel) Implement the reachability decision: add one deliberate `/search` route or launcher, or remove the orphaned runtime surface entirely. [File Reference: `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`, `lib/features/search/view/search_screen.dart:17-25`, `Sline_everything/MVP_ROADMAP.md:31-39`]
- [ ] (@Pixel) Replace log-only row taps with actual navigation to `TaskDetailsScreen` and `PublicProfileScreen`. [File Reference: `lib/features/search/view/search_screen.dart:237-243`, `lib/features/search/view/search_screen.dart:256-261`, `lib/features/tasks/view/task_details_screen.dart:27-35`, `lib/features/profile/view/public_profile_screen.dart:24-32`]
- [ ] (@Pixel) Add the stable keys/selectors from Phase 0 directly into the final search UI. [File Reference: `lib/features/search/view/search_screen.dart:79-92`, `lib/features/search/view/search_screen.dart:129-143`, `lib/features/search/view/search_screen.dart:231-264`, `lib/features/search/view/widgets/search_result_profile_card.dart:26-96`]
- **Verify (@Sentinel):** Gate 4 passes only when search is deliberately reachable or deliberately removed and row taps no longer dead-end.

### 4.2 State Matrix Compliance

- [ ] (@Pixel) Split `SearchScreen` into smaller widgets only after behavior is corrected, so selector ownership and state branches remain testable. [File Reference: `lib/features/search/view/search_screen.dart:17-289`, `.TODO/search.TODO.md:141-156`]
- [ ] (@Pixel) Keep loading, empty, no-results, and error states explicit and English-only, and remove the bio typo in the profile card. [File Reference: `lib/features/search/view/search_screen.dart:179-289`, `lib/features/search/view/widgets/search_result_profile_card.dart:53-55`]
- [ ] (@Pixel) Keep list-heavy polish low-risk: narrower rebuild scope, no widget-owned backend calls beyond existing signed-media resolver boundaries, and no new cross-feature UI coupling. [File Reference: `lib/features/search/view/search_screen.dart:45-47`, `lib/features/search/view/search_screen.dart:179-265`, `lib/core/widgets/signed_avatar.dart:82-145`, `lib/core/widgets/signed_image.dart:67-133`]
- **Verify (@Sentinel):** every visible state maps to `.TODO/UI_STATE_MATRIX_Search_2026-03-04.md`.

## Phase 5: QA / Release

> Primary: @Sentinel

### 5.1 Automated Coverage

- [ ] (@Sentinel) Add `test/unit/search/search_view_model_test.dart` for debounce, stale-response suppression, retry, tab-switch behavior, and empty-query reset. [File Reference: `lib/features/search/viewmodels/search_view_model.dart:42-106`, `.TODO/search.TODO.md:168-171`]
- [ ] (@Sentinel) Add `test/unit/search/task_search_service_test.dart` and `test/unit/search/profile_search_service_test.dart` for safe-summary DTO parsing, owner fallback, categories enrichment, and degraded enrichment behavior. [File Reference: `lib/features/search/services/search_service.dart:25-136`, `lib/features/profile/services/profile_summary_service.dart:60-127`, `.TODO/search.TODO.md:172-175`]
- [ ] (@Sentinel) Add `test/widget/search/search_screen_test.dart` for loading/error/empty/success branches, selectors, and row navigation. [File Reference: `lib/features/search/view/search_screen.dart:179-289`, `.TODO/search.TODO.md:176-180`]
- [ ] (@Sentinel) Add integration coverage only if fixtures and live-preflight requirements from `.TODO/FIXTURES_Search_2026-03-04.md` are satisfied; otherwise record the blocker instead of faking coverage. [File Reference: `test/integration_test/support/helpers.dart:19-239`, `test/integration_test/support/preflight.dart:10-56`]
- **Verify (@Sentinel):** Gate 5 remains closed until automated coverage matches the Gate 0 selector/fixture contract.

### 5.2 Security / Contract Verification

- [ ] (@Sentinel) Run the exact verify queries from the locked RLS query pack against live Supabase after DB changes land. [File Reference: `.TODO/search.TODO.md:181-196`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:10-31`, `lib/features/search/services/search_service.dart:117-136`]
- [ ] (@Sentinel) Validate moderated-user exclusion and `search_tasks` live-definition parity before release sign-off. [File Reference: `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:181-196`]
- [ ] (@Sentinel) Execute the final manual script: open search, search tasks, open task detail, search profiles, open profile detail, recover from error, and clear the query. [File Reference: `lib/features/search/view/search_screen.dart:179-289`, `.TODO/search.TODO.md:188-193`]
- [ ] (@Sentinel) Complete the release checklist and stop the release if live evidence is still UNVERIFIED. [File Reference: `.TODO/search.TODO.md:181-204`, `Sline_everything/CODE_REVIEW.md:20-25`]
- **Verify (@Sentinel):** release evidence exists, or the feature remains blocked.

## Phase 6: Documentation Sync

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/SUPABASE_SETUP.md`, `Sline_everything/MVP_ROADMAP.md`, `Sline_everything/STRUCTURE.md`, and `Sline_everything/Sline_Log.md` only after the final code and live DB evidence are verified. [File Reference: `Sline_everything/DEVELOPER_GUIDE.md:41-68`, `Sline_everything/SUPABASE_SETUP.md:1192-1212`, `Sline_everything/MVP_ROADMAP.md:31-39`, `Sline_everything/CODE_REVIEW.md:20-25`]
- **Verify (@Sentinel):** docs match final code and authenticated live DB reality, not interim assumptions.

## 7) PR Slices

- PR 1: test infrastructure, blocking decision docs, contract docs, and release/provenance artifacts only. [File Reference: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`, `.TODO/search.TODO.md:157-204`]
- PR 2: DB/RLS/search contract reconciliation plus safe-summary DTO and shared hydrator changes. [File Reference: `lib/features/search/services/search_service.dart:31-75`, `lib/features/profile/services/profile_summary_service.dart:60-93`, `lib/features/tasks/services/task_service.dart:72-87`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`]
- PR 3: route/navigation wiring, row navigation, state-matrix UI cleanup, tests, docs sync, and release checklist completion. [File Reference: `lib/features/search/view/search_screen.dart:179-289`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`, `.TODO/search.TODO.md:176-204`]

## 8) Acceptance Criteria

- Search is either deliberately reachable through one explicit app surface or deliberately removed from the runtime. [File Reference: `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`, `Sline_everything/CODE_REVIEW.md:12-25`]
- Task and profile result taps navigate to `TaskDetailsScreen` and `PublicProfileScreen`; no primary result tap remains log-only. [File Reference: `lib/features/search/view/search_screen.dart:237-243`, `lib/features/search/view/search_screen.dart:256-261`, `lib/features/tasks/view/task_details_screen.dart:27-35`, `lib/features/profile/view/public_profile_screen.dart:24-32`]
- Cross-user search/profile summary paths no longer return moderated accounts unless an explicit exception is added to the checked-in contract docs and SQL. [File Reference: `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`]
- The repo contains a checked-in, verified `search_tasks` definition or compatibility wrapper whose live parity is recorded. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:39`, `.TODO/search.TODO.md:181-196`]
- Search task hydration uses the same owner/profile/category merge rules as the task feature, and degraded enrichment behavior is explicit. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:72-87`, `lib/features/tasks/models/task_model.dart:139-150`, `.TODO/search.TODO.md:42`, `.TODO/search.TODO.md:63`]
- Search-specific unit and widget coverage exists for stale request ordering, empty/error states, and navigation, and integration coverage is either shipped or explicitly blocked with documented reasons. [File Reference: `lib/features/search/viewmodels/search_view_model.dart:42-106`, `lib/features/search/view/search_screen.dart:179-289`, `test/integration_test/support/preflight.dart:10-56`]
- No new UI-to-Supabase direct access is introduced, and the storage-path rule is preserved. [File Reference: `Sline_everything/DEVELOPER_GUIDE.md:54-68`, `lib/core/widgets/signed_avatar.dart:82-145`, `lib/core/widgets/signed_image.dart:67-133`]

## 9) Verification & Release Commands

- `flutter analyze`
- `flutter test`
- `flutter test test/unit/search/search_view_model_test.dart`
- `flutter test test/unit/search/task_search_service_test.dart`
- `flutter test test/unit/search/profile_search_service_test.dart`
- `flutter test test/widget/search/search_screen_test.dart`
- `rg -n "SearchScreen|/search" lib`
- `rg -n "search_tasks|search_profiles|rpc_get_profile_summaries" supabase/migrations Sline_everything`
- `rg -n "account_status|moderation_reason|force_logout_after" supabase/migrations lib/features/profile`
- `rg -n "ValueKey|Key\\(" lib/features/search`
- Live verification queries after DB changes:
  - `select pg_get_functiondef('public.search_tasks(text, integer, integer)'::regprocedure);`
  - `select pg_get_functiondef('public.search_profiles(text, text, integer, integer)'::regprocedure);`
  - `select pg_get_functiondef('public.rpc_get_profile_summaries(uuid[])'::regprocedure);`
  - `select * from pg_policies where schemaname = 'public' and tablename = 'categories';`
  - `select * from public.search_profiles('name', null, 20, 0);`
  - `select * from public.rpc_get_profile_summaries(array['<active-id>'::uuid, '<restricted-id>'::uuid]);`

## 10) Rollback Plan

- DB rollback:
  - Export pre-change definitions for `search_tasks`, `search_profiles`, and `rpc_get_profile_summaries` before any replacement or compatibility wrapper is applied. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `.TODO/search.TODO.md:198-204`]
  - If moderation-safe changes break sibling summary consumers, roll forward with compatibility-versioned functions instead of destructive drops. [File Reference: `lib/features/profile/services/profile_summary_service.dart:7-129`, `lib/features/tasks/services/task_service.dart:20-29`]
- App rollback:
  - Re-hide or remove the search route/launcher independently from service/DTO changes if the feature becomes unstable after exposure. [File Reference: `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`]
  - Keep a temporary facade around search service splits until all search callers are stable. [File Reference: `lib/features/search/services/search_service.dart:13-138`]
- Release rollback:
  - If live DB evidence is still UNVERIFIED, stop at PR 1 or PR 2 and do not expose the route. [UNVERIFIED: depends on authenticated live scan completion]

## 11) References

- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/SUPABASE_SETUP.md`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/CODE_REVIEW.md`
- `Sline_everything/STRUCTURE.md`
- `.TODO/search.TODO.md`
- `lib/main.dart`
- `lib/app/main_navigation_screen.dart`
- `lib/core/services/supabase_config.dart`
- `lib/core/widgets/signed_avatar.dart`
- `lib/core/widgets/signed_image.dart`
- `lib/features/search/view/search_screen.dart`
- `lib/features/search/viewmodels/search_view_model.dart`
- `lib/features/search/services/search_service.dart`
- `lib/features/search/view/widgets/search_result_profile_card.dart`
- `lib/features/profile/services/profile_summary_service.dart`
- `lib/features/profile/models/profile_model.dart`
- `lib/features/tasks/models/task_model.dart`
- `lib/features/tasks/services/task_service.dart`
- `test/test_support/pump_app.dart`
- `test/integration_test/support/helpers.dart`
- `test/integration_test/support/preflight.dart`
- `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql`
- `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql`
- `supabase/migrations/20260301_harden_home_related_read_policies.sql`
- `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql`
