# search — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- This feature renders a search UI for two modes, `Find Work` and `Find Talent`, and sends user queries through `SearchViewModel` into `SearchService` / `ProfileSummaryService`. [File Reference: `lib/features/search/view/search_screen.dart:79-97`, `lib/features/search/view/search_screen.dart:127-143`, `lib/features/search/viewmodels/search_view_model.dart:42-106`, `lib/features/search/services/search_service.dart:25-101`, `lib/features/profile/services/profile_summary_service.dart:60-127`]
- In scope for this audit: `lib/features/search/**` plus direct dependencies imported or called by search files, and app-shell files needed to verify whether the feature is wired into navigation. [File Reference: `lib/features/search/view/search_screen.dart:1-15`, `lib/features/search/viewmodels/search_view_model.dart:1-7`, `lib/features/search/services/search_service.dart:1-6`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`]
- Entry points observed: the `SearchScreen` widget exists, `SearchViewModel.onSearchChanged()` is the primary query trigger, and `SearchService.searchTasks()` / `SearchService.searchProfiles()` are the primary data calls. No route registration or main-navigation registration for `SearchScreen` was found in the app shell files audited here. [File Reference: `lib/features/search/view/search_screen.dart:17-25`, `lib/features/search/view/search_screen.dart:83-92`, `lib/features/search/viewmodels/search_view_model.dart:59-106`, `lib/features/search/services/search_service.dart:25-101`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`]

## 1) Feature Map (Current Repo State)
- Primary feature files:
  - `SearchScreen` owns provider creation, query field wiring, tab selection, and result rendering. [File Reference: `lib/features/search/view/search_screen.dart:17-289`]
  - `SearchViewModel` owns debounce, active tab state, loading/error state, and retry. [File Reference: `lib/features/search/viewmodels/search_view_model.dart:9-108`]
  - `SearchService` owns task RPC calls, profile RPC calls, and task/category enrichment. [File Reference: `lib/features/search/services/search_service.dart:13-138`]
  - `SearchResultProfileCard` renders profile rows and delegates avatar rendering to `SignedAvatar`. [File Reference: `lib/features/search/view/widgets/search_result_profile_card.dart:10-121`]
- Direct dependencies touched by the feature:
  - `ProfileSummaryService` provides `search_profiles` and `rpc_get_profile_summaries`. [File Reference: `lib/features/profile/services/profile_summary_service.dart:7-129`]
  - `Task` parses task rows and resolves owner fallback from `owner_id` / `client_id` / `user_id`. [File Reference: `lib/features/tasks/models/task_model.dart:18-179`]
  - `ProfileModel` is the DTO currently used for safe summary search results even though it also models private/self-only fields. [File Reference: `lib/features/profile/models/profile_model.dart:1-100`]
  - `TaskCard` delegates to `TenderTaskCard` or `BookingTaskCard` for search task rows. [File Reference: `lib/features/tasks/view/widgets/task_card.dart:17-87`]
  - `BookingTaskCard` renders task media through `SignedImage` and author avatars through `SignedAvatar` for booking results. [File Reference: `lib/features/tasks/view/widgets/booking_task_card.dart:15-25`, `lib/features/tasks/view/widgets/booking_task_card.dart:66-77`, `lib/features/tasks/view/widgets/booking_task_card.dart:204-237`]
  - `TaskDetailsScreen` is the concrete task-detail target that search should navigate to. [File Reference: `lib/features/tasks/view/task_details_screen.dart:27-35`]
  - `PublicProfileScreen` is the concrete profile-detail target that search should navigate to. [File Reference: `lib/features/profile/view/public_profile_screen.dart:24-32`]
  - `SignedAvatar` resolves storage paths into signed URLs inside widget state through `AvatarService`. [File Reference: `lib/core/widgets/signed_avatar.dart:71-145`, `lib/features/profile/services/avatar_service.dart:10-14`, `lib/features/profile/services/avatar_service.dart:54-61`]
  - `SignedImage` resolves storage paths into signed URLs inside widget state through `Supabase.instance.client.storage` or `TaskImageService`. [File Reference: `lib/core/widgets/signed_image.dart:51-133`, `lib/features/tasks/services/task_image_service.dart:13-18`, `lib/features/tasks/services/task_image_service.dart:106-118`]
- Supabase touchpoints:
  - RPC `search_tasks(query, limit_val, offset_val)` is called from the client. The repo documents that it should search open tasks, but the checked-in SQL definition is UNVERIFIED because no migration defining `public.search_tasks(...)` was found in the current repo scan. [File Reference: `lib/features/search/services/search_service.dart:31-34`, `Sline_everything/SUPABASE_SETUP.md:1196-1200`]
  - RPC `search_profiles(query, role_filter, limit_val, offset_val)` is called through `ProfileSummaryService` and is implemented as a `SECURITY DEFINER` function returning safe summary fields. [File Reference: `lib/features/profile/services/profile_summary_service.dart:77-86`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:5-61`]
  - RPC `rpc_get_profile_summaries(p_ids uuid[])` is called for task author enrichment and is implemented as a `SECURITY DEFINER` function returning safe summary fields. [File Reference: `lib/features/profile/services/profile_summary_service.dart:21-25`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`]
  - Table `categories` is read directly for name enrichment after `search_tasks`. The `categories` RLS contract is UNVERIFIED in the current repo scan because no matching `categories` policy migration was found in scoped SQL search. [File Reference: `lib/features/search/services/search_service.dart:117-136`]
  - Table `profiles` is intentionally self-only for direct base-table reads, so cross-user search/profile summary visibility depends on the server-side RPCs above. [File Reference: `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`]
  - Storage bucket `avatars` is touched when profile search rows or booking task author rows render avatars. [File Reference: `lib/features/search/view/widgets/search_result_profile_card.dart:32-37`, `lib/features/tasks/view/widgets/booking_task_card.dart:227-237`, `lib/features/profile/services/avatar_service.dart:10-14`]
  - Storage bucket `task-images` is touched when booking task results render task images. [File Reference: `lib/features/tasks/view/widgets/booking_task_card.dart:66-77`, `lib/core/widgets/signed_image.dart:108-115`, `lib/features/tasks/services/task_image_service.dart:13-18`]
  - No realtime channel or edge function call was observed in audited search feature files. [File Reference: `lib/features/search/services/search_service.dart:1-138`, `lib/features/search/viewmodels/search_view_model.dart:1-108`, `lib/features/search/view/search_screen.dart:1-289`]

## 2) Evidence Index (Ground Truth)

| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
|---|---|---|---|---|
| SE-01 | `search_profiles` and `rpc_get_profile_summaries` bypass the later moderation model because neither function filters `account_status`. | `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`; `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:21-53`; `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:14-40`; `supabase/migrations/20260301_harden_home_related_read_policies.sql:27-31` | High | Cross-user profile visibility now depends entirely on RPC logic. |
| SE-02 | The auth/RLS contract of `search_tasks` cannot be verified from checked-in SQL. | `lib/features/search/services/search_service.dart:31-34`; `Sline_everything/SUPABASE_SETUP.md:1196-1200` | High | UNVERIFIED: no checked-in migration defining `public.search_tasks(...)` was found in the current repo scan. |
| SE-03 | Task search pulls a broader cross-user summary payload than the task result cards require. | `lib/features/search/services/search_service.dart:50-75`; `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-39` | Medium | Least-privilege gap. |
| DI-01 | Search task author hydration only uses `user_id`, while the canonical task path already falls back through `owner_id` / `client_id` / `user_id`. | `lib/features/search/services/search_service.dart:39-66`; `lib/features/tasks/services/task_service.dart:31-41`; `lib/features/tasks/services/task_service.dart:72-87`; `lib/features/tasks/services/task_service.dart:101-113`; `lib/features/tasks/models/task_model.dart:139-150` | High | Search can lose author enrichment on mixed-schema rows. |
| DI-02 | Search silently drops profile/category enrichment on failure and returns partial task rows. | `lib/features/search/services/search_service.dart:104-135` | Medium | Partial failures are hidden from the user and the VM. |
| AR-01 | Search duplicates task hydration logic already implemented in `TaskService`. | `lib/features/search/services/search_service.dart:39-75`; `lib/features/tasks/services/task_service.dart:47-87` | Medium | Duplicate logic is already drifting. |
| AR-02 | Search depends on UI widgets that resolve signed URLs via Supabase/storage inside widget state. | `lib/features/search/view/widgets/search_result_profile_card.dart:32-37`; `lib/core/widgets/signed_avatar.dart:82-145`; `lib/features/tasks/view/widgets/booking_task_card.dart:66-77`; `lib/features/tasks/view/widgets/booking_task_card.dart:227-237`; `lib/core/widgets/signed_image.dart:67-133` | Medium | MVVM boundary leak and repeated async work in UI. |
| CQ-01 | Search result taps only log IDs; they do not navigate to task or profile details. | `lib/features/search/view/search_screen.dart:231-265`; `lib/features/tasks/view/task_details_screen.dart:27-35`; `lib/features/profile/view/public_profile_screen.dart:24-32` | High | Primary flow is incomplete. |
| CQ-02 | `SearchScreen` is not registered in app routes or the main navigation shell. | `lib/features/search/view/search_screen.dart:17-25`; `lib/main.dart:455-474`; `lib/app/main_navigation_screen.dart:42-52` | Medium | Feature appears orphaned in current repo state. |
| CQ-03 | Safe-summary RPC results are parsed into the full `ProfileModel`, which also models private/self-only fields. | `lib/features/profile/services/profile_summary_service.dart:77-93`; `lib/features/profile/models/profile_model.dart:1-70` | Medium | Contract boundaries are blurred. |
| CQ-04 | The profile result card contains a user-facing typo. | `lib/features/search/view/widgets/search_result_profile_card.dart:53-55` | Low | UI polish issue. |
| PF-01 | `SearchViewModel` allows stale async results and duplicate requests on tab switches. | `lib/features/search/viewmodels/search_view_model.dart:43-56`; `lib/features/search/viewmodels/search_view_model.dart:60-99` | Medium | Race condition under rapid input or tab changes. |
| PF-02 | Pagination exists in the service API but not in the ViewModel or UI. | `lib/features/search/services/search_service.dart:25-29`; `lib/features/search/services/search_service.dart:85-89`; `lib/features/search/viewmodels/search_view_model.dart:9-108`; `lib/features/search/view/search_screen.dart:231-264` | Medium | Results are capped at the first page. |
| PF-03 | The whole screen rebuilds on every VM state change, and search rows trigger async media resolution in cell widgets. | `lib/features/search/view/search_screen.dart:45-47`; `lib/features/search/view/search_screen.dart:179-265`; `lib/features/search/view/widgets/search_result_profile_card.dart:32-37`; `lib/core/widgets/signed_avatar.dart:103-145`; `lib/features/tasks/view/widgets/booking_task_card.dart:66-77`; `lib/core/widgets/signed_image.dart:67-133` | Low | Extra rebuilds and many per-row async operations. |
| TG-01 | No search-specific unit, widget, or integration tests were found in the current repo scan. | UNVERIFIED | High | Missing files cannot be cited by path because they do not exist; confirm with repo-wide test file scan. |

## 3) Findings

### 3.1 Security (Highest Priority)
- `SE-01` — Cross-user profile search and profile-summary reads ignore moderation state. [File Reference: `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:21-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:14-40`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:27-31`] Impact: suspended or banned accounts can still be discovered by search or author enrichment. Exploit/Failure scenario: an authenticated user searches a banned freelancer name and still receives that profile in `search_profiles`, or a banned seller still appears as a task author via `rpc_get_profile_summaries`.
- `SE-02` — The `search_tasks` authorization contract is UNVERIFIED because the client calls it but the repo does not contain a checked-in SQL definition. [File Reference: `lib/features/search/services/search_service.dart:31-34`, `Sline_everything/SUPABASE_SETUP.md:1196-1200`] Impact: the repository cannot prove that `search_tasks` enforces authenticated-only access, `status = 'open'`, or RLS-compatible filtering. Exploit/Failure scenario: the live function could drift from the documented contract and expose task rows outside the intended visibility rules without the repo catching it.
- `SE-03` — Task search fetches a broader cross-user summary payload than the task cards need. [File Reference: `lib/features/search/services/search_service.dart:50-75`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-39`] Impact: search task results depend on `bio`, `skills`, `created_at`, and `seller_level` exposure even though the cards only need author display data. Exploit/Failure scenario: future consumers can start using extra returned fields without revisiting the server-side minimum-data contract.

### 3.2 Data Integrity
- `DI-01` — Task author enrichment in search is schema-stale because it only keys by `user_id`. [File Reference: `lib/features/search/services/search_service.dart:39-66`, `lib/features/tasks/services/task_service.dart:72-87`, `lib/features/tasks/services/task_service.dart:101-113`, `lib/features/tasks/models/task_model.dart:139-150`] Impact: search can show tasks without author name/avatar even when other task surfaces render them correctly. Failure scenario: a row populated through `owner_id` or `client_id` bypasses search enrichment and reaches `Task.fromJson()` without a `profiles` object.
- `DI-02` — Search suppresses enrichment failures and returns partial task data. [File Reference: `lib/features/search/services/search_service.dart:104-135`] Impact: author/category metadata can disappear silently while the screen still renders the base task row as if the request succeeded. Failure scenario: a transient categories or profile-summary failure yields tasks with missing names/avatars/category labels and no error state to explain the degraded result.

### 3.3 Architecture
- `AR-01` — Search re-implements task hydration logic instead of sharing the canonical task hydration path. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:47-87`] Impact: search has its own schema assumptions, its own enrichment error behavior, and its own drift surface. Failure scenario: the task feature evolves owner-id handling or summary mapping, but search remains on the older logic and diverges again.
- `AR-02` — Search renders through UI widgets that perform Supabase/storage signed-URL work inside widget state. [File Reference: `lib/features/search/view/widgets/search_result_profile_card.dart:32-37`, `lib/core/widgets/signed_avatar.dart:82-145`, `lib/features/tasks/view/widgets/booking_task_card.dart:66-77`, `lib/features/tasks/view/widgets/booking_task_card.dart:227-237`, `lib/core/widgets/signed_image.dart:67-133`] Impact: network/storage work occurs in UI-layer widgets rather than a dedicated service/viewmodel boundary, which weakens MVVM isolation and complicates testing. Failure scenario: scrolling a results list spawns many widget-local async URL resolutions with no shared feature-level lifecycle control.

### 3.4 Code Quality
- `CQ-01` — Search result rows do not complete the feature’s primary action because taps only log IDs. [File Reference: `lib/features/search/view/search_screen.dart:231-265`, `lib/features/tasks/view/task_details_screen.dart:27-35`, `lib/features/profile/view/public_profile_screen.dart:24-32`] Impact: users can see results but cannot open the corresponding task or profile from search. Failure scenario: tapping a result appears to do nothing beyond internal logging.
- `CQ-02` — `SearchScreen` appears orphaned in the current app shell. [File Reference: `lib/features/search/view/search_screen.dart:17-25`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`] Impact: the feature may be dead code in production because no route or shell slot points to it. Failure scenario: fixes applied only inside the search folder still do not surface to users because the screen remains unreachable.
- `CQ-03` — Safe cross-user summary rows are parsed into the full `ProfileModel`. [File Reference: `lib/features/profile/services/profile_summary_service.dart:77-93`, `lib/features/profile/models/profile_model.dart:1-70`] Impact: the type system does not distinguish safe summary data from self/private profile data. Failure scenario: a downstream widget starts reading fields such as `email` or `accountStatus` from a DTO that search never truly receives.
- `CQ-04` — The profile result fallback copy has a typo: `No bio avaliable.` [File Reference: `lib/features/search/view/widgets/search_result_profile_card.dart:53-55`] Impact: visible polish defect. Failure scenario: users see misspelled empty-state text in profile results.

### 3.5 Performance
- `PF-01` — `SearchViewModel` can apply stale responses and can double-fire around tab switches. [File Reference: `lib/features/search/viewmodels/search_view_model.dart:43-56`, `lib/features/search/viewmodels/search_view_model.dart:60-99`] Impact: result sets can flicker or regress after rapid typing or tab changes. Failure scenario: the user types a query, switches tabs before the debounce fires, and an older request finishes after the newer request and overwrites the current tab’s results.
- `PF-02` — The service exposes pagination, but the ViewModel and UI never use it. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/services/search_service.dart:85-89`, `lib/features/search/viewmodels/search_view_model.dart:9-108`, `lib/features/search/view/search_screen.dart:231-264`] Impact: only the first page can ever be reached from the current UI. Failure scenario: a query with more than 20 matches silently truncates results with no load-more path.
- `PF-03` — The entire screen rebuilds for every search state change, and media rows trigger independent async URL resolution in cells. [File Reference: `lib/features/search/view/search_screen.dart:45-47`, `lib/features/search/view/search_screen.dart:179-265`, `lib/features/search/view/widgets/search_result_profile_card.dart:32-37`, `lib/core/widgets/signed_avatar.dart:103-145`, `lib/features/tasks/view/widgets/booking_task_card.dart:66-77`, `lib/core/widgets/signed_image.dart:67-133`] Impact: avoidable rebuild and async churn increases as result counts grow. Failure scenario: the first profile/task page triggers a screen rebuild plus per-cell signed URL resolution bursts.

### 3.6 Testing Gaps
- `TG-01` — No search-specific tests were found for ViewModel logic, service enrichment, widget states, or navigation. [UNVERIFIED: missing test files cannot be cited by path because they do not exist in the current repo scan] Impact: the current repo has no automated protection for debounce behavior, result navigation, pagination, or the RPC/data-shape contracts. Failure scenario: refactors to shared task/profile code break search silently because no search test suite exists.
- Missing test coverage that follows directly from the current code paths:
  - ViewModel tests for debounce timing, retry behavior, tab-switch request ordering, and stale-response suppression. [File Reference: `lib/features/search/viewmodels/search_view_model.dart:42-106`]
  - Service tests for author-id fallback, category enrichment, and partial enrichment failure handling. [File Reference: `lib/features/search/services/search_service.dart:25-138`]
  - Widget tests for initial/loading/error/empty/success states and row-tap navigation. [File Reference: `lib/features/search/view/search_screen.dart:179-289`]
  - SQL/RLS contract checks for `search_profiles`, `rpc_get_profile_summaries`, and `search_tasks`. [File Reference: `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:5-61`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`, `Sline_everything/SUPABASE_SETUP.md:1196-1200`]

## 4) Dead/Unused Code Candidates
- `lib/features/search/view/search_screen.dart` is a dead-entry candidate because no app-shell route or main-nav registration for `SearchScreen` was found in the audited shell files. [File Reference: `lib/features/search/view/search_screen.dart:17-25`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`] How to confirm: run `rg -n "SearchScreen\\(" lib`.
- The commented-out navigation placeholders inside `SearchScreen` are dead code candidates because the actual navigation was never implemented. [File Reference: `lib/features/search/view/search_screen.dart:239-241`, `lib/features/search/view/search_screen.dart:258-260`] How to confirm: replace with real navigation or delete and verify behavior with widget tests.
- `roleFilter`, `limit`, and `offset` in the search service are unused by the current ViewModel/UI path. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/services/search_service.dart:85-89`, `lib/features/search/viewmodels/search_view_model.dart:9-108`] How to confirm: run `rg -n "roleFilter|offset|limit" lib/features/search`.

## 5) Duplicate Code Candidates
- Task hydration duplication exists between `SearchService` and `TaskService`. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:47-87`] Proposed shared abstraction: create `lib/features/tasks/services/task_summary_hydrator.dart` and move owner-id resolution plus profile/category merge logic there.
- Safe summary projection duplication exists across `search_profiles` and `rpc_get_profile_summaries`. [File Reference: `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`] Proposed shared abstraction: centralize the safe profile projection behind one SQL helper or view consumed by both functions.

## 6) Refactor Plan (Exact Paths)
- Split `lib/features/search/view/search_screen.dart` into:
  - keep `lib/features/search/view/search_screen.dart` as the provider/bootstrap shell
  - create `lib/features/search/view/widgets/search_header.dart`
  - create `lib/features/search/view/widgets/search_tab_toggle.dart`
  - create `lib/features/search/view/widgets/search_results_list.dart`
  - migration strategy: keep `SearchScreen` public API unchanged and move only private widget helpers first
- Split `lib/features/search/services/search_service.dart` into:
  - create `lib/features/search/services/task_search_service.dart`
  - create `lib/features/search/services/profile_search_service.dart`
  - keep `lib/features/search/services/search_service.dart` as a compatibility façade until callers are migrated
- Extract shared task hydration into:
  - create `lib/features/tasks/services/task_summary_hydrator.dart`
  - edit `lib/features/search/services/task_search_service.dart`
  - edit `lib/features/tasks/services/task_service.dart`
  - migration strategy: land the shared hydrator first, then switch both callers without changing `Task` JSON shape
- Separate safe summary DTOs from full profile DTOs:
  - create `lib/features/profile/models/profile_summary_model.dart`
  - edit `lib/features/profile/services/profile_summary_service.dart`
  - edit `lib/features/search/view/widgets/search_result_profile_card.dart`
  - migration strategy: add the new summary model alongside `ProfileModel`, update cross-user summary callers incrementally, then remove ambiguous parsing
- Restore feature wiring explicitly:
  - create `lib/features/search/routes/search_routes.dart`
  - edit `lib/main.dart`
  - edit `lib/app/main_navigation_screen.dart` or the chosen route launcher
  - migration strategy: choose one entry path first (`/search` route or a shell slot) and add tests around that chosen contract
- Check in the missing server contract:
  - create `supabase/migrations/20260304120000_search_contract_hardening.sql`
  - migration strategy: export the current live `search_tasks` definition first, then version or replace it in source control instead of re-creating it from docs alone

## 7) Fix Plan (Phases)

### Phase 1: Critical security & correctness
1. Harden cross-user profile visibility so moderated accounts are excluded from `search_profiles` and `rpc_get_profile_summaries` unless product requirements explicitly document a different rule.  
Files: `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql`, `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql`  
Acceptance criteria: suspended/banned users are not returned by either function; authenticated active users still resolve correctly; SQL definitions remain checked in and reviewable. [File Reference: `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:5-61`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`, `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`]
2. Export, check in, and verify the real `search_tasks` SQL contract before any client-side search-task fix ships.  
Files: create `supabase/migrations/20260304120000_search_contract_hardening.sql`, edit `Sline_everything/SUPABASE_SETUP.md` only if the checked-in contract changes  
Acceptance criteria: the repo contains a checked-in `public.search_tasks(...)` definition, grants are explicit, and the function’s visibility rules are no longer UNVERIFIED. [File Reference: `lib/features/search/services/search_service.dart:31-34`, `Sline_everything/SUPABASE_SETUP.md:1196-1200`]
3. Restore actual navigation from search results to `TaskDetailsScreen` and `PublicProfileScreen`.  
Files: `lib/features/search/view/search_screen.dart`, optionally create `lib/features/search/routes/search_routes.dart`  
Acceptance criteria: tapping a task row opens `TaskDetailsScreen(task: ...)`; tapping a profile row opens `PublicProfileScreen(userId: ...)`; logging-only placeholders are removed. [File Reference: `lib/features/search/view/search_screen.dart:231-265`, `lib/features/tasks/view/task_details_screen.dart:27-35`, `lib/features/profile/view/public_profile_screen.dart:24-32`]
4. Align task author enrichment with the canonical owner fallback order.  
Files: `lib/features/search/services/search_service.dart` or `lib/features/search/services/task_search_service.dart`, `lib/features/tasks/services/task_summary_hydrator.dart`  
Acceptance criteria: search task results hydrate author data using `owner_id`, then `client_id`, then `user_id`, matching the current task model/service contract. [File Reference: `lib/features/search/services/search_service.dart:39-66`, `lib/features/tasks/services/task_service.dart:72-87`, `lib/features/tasks/models/task_model.dart:139-150`]
5. Prevent stale responses and duplicate request races in `SearchViewModel`.  
Files: `lib/features/search/viewmodels/search_view_model.dart`  
Acceptance criteria: debounced requests are sequence-guarded or cancelled, tab switches cannot cause older results to overwrite newer ones, and tests prove the ordering behavior. [File Reference: `lib/features/search/viewmodels/search_view_model.dart:43-99`]

### Phase 2: Refactor/structure
1. Remove duplicated task hydration by introducing a shared hydrator.  
Files: create `lib/features/tasks/services/task_summary_hydrator.dart`, edit `lib/features/tasks/services/task_service.dart`, edit `lib/features/search/services/search_service.dart` or split services  
Acceptance criteria: search and task flows use one shared enrichment path for owner/profile/category merge logic. [File Reference: `lib/features/search/services/search_service.dart:39-75`, `lib/features/tasks/services/task_service.dart:47-87`]
2. Split task search and profile search responsibilities into separate services.  
Files: create `lib/features/search/services/task_search_service.dart`, create `lib/features/search/services/profile_search_service.dart`, keep temporary façade at `lib/features/search/services/search_service.dart`  
Acceptance criteria: each service owns one RPC/data shape, and search feature wiring no longer mixes task and profile concerns in one file. [File Reference: `lib/features/search/services/search_service.dart:13-138`]
3. Introduce a dedicated safe-summary DTO for cross-user profile results.  
Files: create `lib/features/profile/models/profile_summary_model.dart`, edit `lib/features/profile/services/profile_summary_service.dart`, edit `lib/features/search/view/widgets/search_result_profile_card.dart`  
Acceptance criteria: cross-user profile summaries are not parsed into `ProfileModel`, and search UI consumes the explicit summary type. [File Reference: `lib/features/profile/services/profile_summary_service.dart:77-93`, `lib/features/profile/models/profile_model.dart:1-70`]
4. Decide whether the feature is meant to be reachable; if yes, register it explicitly, and if no, remove the orphaned screen.  
Files: `lib/main.dart`, `lib/app/main_navigation_screen.dart`, optionally create `lib/features/search/routes/search_routes.dart`, or delete `lib/features/search/view/search_screen.dart` if the product decision is removal  
Acceptance criteria: repo state is no longer ambiguous about whether search is a live feature. [File Reference: `lib/features/search/view/search_screen.dart:17-25`, `lib/main.dart:455-474`, `lib/app/main_navigation_screen.dart:42-52`]
5. Split the screen into smaller widgets after the behavior is corrected.  
Files: `lib/features/search/view/search_screen.dart`, create `lib/features/search/view/widgets/search_header.dart`, create `lib/features/search/view/widgets/search_tab_toggle.dart`, create `lib/features/search/view/widgets/search_results_list.dart`  
Acceptance criteria: the main screen file stops owning all view state branches and private builder methods. [File Reference: `lib/features/search/view/search_screen.dart:17-289`]

### Phase 3: Tests
1. Add ViewModel unit tests for debounce, retry, empty-query reset, tab switching, and stale-response suppression.  
Files: create `test/unit/search/search_view_model_test.dart`  
Acceptance criteria: tests fail on current race behavior and pass after request sequencing is added. [File Reference: `lib/features/search/viewmodels/search_view_model.dart:42-106`]
2. Add task/profile search service tests for enrichment and error handling.  
Files: create `test/unit/search/task_search_service_test.dart`, create `test/unit/search/profile_search_service_test.dart`  
Acceptance criteria: tests cover owner-id fallback, category enrichment, summary DTO parsing, and partial enrichment failures. [File Reference: `lib/features/search/services/search_service.dart:25-138`, `lib/features/profile/services/profile_summary_service.dart:13-127`]
3. Add widget tests for screen states and result navigation.  
Files: create `test/widget/search/search_screen_test.dart`  
Acceptance criteria: initial/loading/error/empty/success states are covered, and row taps open the expected detail screens. [File Reference: `lib/features/search/view/search_screen.dart:179-289`]
4. Add SQL / contract verification coverage for search RPCs.  
Files: create `test/integration_test/search_contract_flow_test.dart` or maintain a checked-in SQL verification script under `.TODO/` if integration DB tests are not yet supported  
Acceptance criteria: the repo has an executable verification path proving `search_profiles`, `rpc_get_profile_summaries`, and `search_tasks` match the checked-in contract. [File Reference: `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:5-61`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`, `Sline_everything/SUPABASE_SETUP.md:1196-1212`]

### Phase 4: Polish/perf
1. Narrow rebuild scope inside the screen.  
Files: `lib/features/search/view/search_screen.dart`, `lib/features/search/view/widgets/search_results_list.dart`  
Acceptance criteria: static layout pieces stop rebuilding on every loading/result state change. [File Reference: `lib/features/search/view/search_screen.dart:45-47`, `lib/features/search/view/search_screen.dart:179-265`]
2. Implement pagination in the ViewModel/UI if the product intends search to scale beyond the first page.  
Files: `lib/features/search/viewmodels/search_view_model.dart`, `lib/features/search/view/search_screen.dart` or `lib/features/search/view/widgets/search_results_list.dart`  
Acceptance criteria: the UI can request additional pages and append without duplicating existing results. [File Reference: `lib/features/search/services/search_service.dart:25-29`, `lib/features/search/services/search_service.dart:85-89`, `lib/features/search/view/search_screen.dart:231-264`]
3. Remove visible copy issues and align empty-state messaging.  
Files: `lib/features/search/view/widgets/search_result_profile_card.dart`, `lib/features/search/view/search_screen.dart`  
Acceptance criteria: all search strings remain English-only and the typo is removed. [File Reference: `lib/features/search/view/widgets/search_result_profile_card.dart:53-55`, `lib/features/search/view/search_screen.dart:198`, `lib/features/search/view/search_screen.dart:217`, `lib/features/search/view/search_screen.dart:280`]
4. Reduce per-row media resolution churn if search remains a list-heavy feature.  
Files: `lib/core/widgets/signed_avatar.dart`, `lib/core/widgets/signed_image.dart`, optionally create `lib/core/services/signed_media_resolver.dart`  
Acceptance criteria: signed URL resolution is centralized or better memoized, and search lists do not rely on widget-local Supabase calls for every visible row. [File Reference: `lib/core/widgets/signed_avatar.dart:82-145`, `lib/core/widgets/signed_image.dart:67-133`]

## 8) Verification Checklist

### Commands
- `flutter analyze`
- `flutter test`
- `flutter test test/unit/search/search_view_model_test.dart`
- `flutter test test/unit/search/task_search_service_test.dart`
- `flutter test test/unit/search/profile_search_service_test.dart`
- `flutter test test/widget/search/search_screen_test.dart`
- `rg -n "SearchScreen\\(" lib`
- `rg -n "search_tasks|search_profiles|rpc_get_profile_summaries" supabase/migrations Sline_everything`
- `rg -n "account_status|moderation_reason|force_logout_after" supabase/migrations lib/features/profile`
- `rg -n "service_role|SUPABASE_SERVICE_ROLE|api[_-]?key|secret|token" lib/features/search lib/features/profile/services/profile_summary_service.dart lib/core/widgets/signed_avatar.dart lib/core/widgets/signed_image.dart`

### Manual Scenarios
- Open the actual entry point for search after wiring is restored, then type a query on `Find Work`, confirm visible results load, and tap a row to open `TaskDetailsScreen`. [File Reference: `lib/features/search/view/search_screen.dart:127-143`, `lib/features/search/view/search_screen.dart:227-245`, `lib/features/tasks/view/task_details_screen.dart:27-35`]
- Switch to `Find Talent`, type a query, confirm profile cards load with avatar/bio/skills, and tap a row to open `PublicProfileScreen`. [File Reference: `lib/features/search/view/search_screen.dart:136-143`, `lib/features/search/view/search_screen.dart:246-264`, `lib/features/search/view/widgets/search_result_profile_card.dart:26-95`, `lib/features/profile/view/public_profile_screen.dart:24-32`]
- Type rapidly (`a`, `ab`, `abc`) and switch tabs before the debounce fires; confirm older requests cannot overwrite the latest state. [File Reference: `lib/features/search/viewmodels/search_view_model.dart:43-99`]
- Clear the query and confirm both task and profile lists reset immediately. [File Reference: `lib/features/search/viewmodels/search_view_model.dart:66-72`]
- Force an RPC failure and confirm the UI shows the error state, then retry and confirm the same latest query re-runs. [File Reference: `lib/features/search/view/search_screen.dart:186-201`, `lib/features/search/viewmodels/search_view_model.dart:93-106`]
- Search for a moderated account after server hardening and confirm it does not appear in profile results or task-author summaries. [File Reference: `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`]

### Supabase/RLS Contract Checks
- Validate that direct `profiles` reads remain self-only and that cross-user reads still go only through hardened RPCs. [File Reference: `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:5-61`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`]
- Export and inspect the live definitions after Phase 1:
  - `select pg_get_functiondef('public.search_profiles(text, text, integer, integer)'::regprocedure);`
  - `select pg_get_functiondef('public.rpc_get_profile_summaries(uuid[])'::regprocedure);`
  - `select pg_get_functiondef('public.search_tasks(text, integer, integer)'::regprocedure);`
  - Acceptance: checked-in SQL matches live definitions for the three search functions. [File Reference: `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:5-61`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`, `Sline_everything/SUPABASE_SETUP.md:1196-1212`]
- Validate moderated-account exclusion after hardening:
  - `select * from public.search_profiles('name', null, 20, 0);`
  - `select * from public.rpc_get_profile_summaries(array['<active-id>'::uuid, '<restricted-id>'::uuid]);`
  - Acceptance: active users can appear, restricted users do not. [File Reference: `supabase/migrations/20260310102000_dashboard_core_user_controls_and_reports.sql:8-17`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:31-53`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:28-40`]
- Validate `categories` access explicitly because the current code swallows failures and the policy is UNVERIFIED:
  - `select * from pg_policies where schemaname = 'public' and tablename = 'categories';`
  - Acceptance: authenticated search clients have a documented/selectable path for category-name enrichment. [File Reference: `lib/features/search/services/search_service.dart:117-136`]

## 9) Risks & Rollback Notes
- Tightening `search_profiles` or `rpc_get_profile_summaries` can affect other callers beyond search because the same summary service is reused across tasks, dashboard, saved items, work management, and public profile aggregation. [File Reference: `lib/features/profile/services/profile_summary_service.dart:7-129`, `lib/features/search/services/search_service.dart:17-20`, `lib/features/tasks/services/task_service.dart:21-29`]
- Wiring `SearchScreen` into the app shell can expose previously orphaned behavior and reveal latent runtime issues in navigation, saved-state interactions, or booking task card sub-actions. [File Reference: `lib/features/search/view/search_screen.dart:17-25`, `lib/app/main_navigation_screen.dart:42-52`, `lib/main.dart:455-474`, `lib/features/tasks/view/widgets/booking_task_card.dart:152-181`, `lib/features/tasks/view/widgets/booking_task_card.dart:204-237`]
- Refactoring signed-media resolution out of widgets can affect every screen that renders avatars or signed task images, not just search. [File Reference: `lib/core/widgets/signed_avatar.dart:82-145`, `lib/core/widgets/signed_image.dart:67-133`]
- Rollback step for SQL changes: keep the pre-hardening function definitions exported before replacement and store them in a rollback migration or versioned function names. [File Reference: `Sline_everything/SUPABASE_SETUP.md:1196-1212`, `supabase/migrations/20260301_fix_search_profiles_safe_summary.sql:5-61`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`]
- Rollback step for client changes: land navigation wiring and DTO refactors behind small commits so route registration, hydrator extraction, and summary-model migration can be reverted independently if needed. [File Reference: `lib/features/search/view/search_screen.dart:17-289`, `lib/features/search/services/search_service.dart:13-138`, `lib/features/profile/services/profile_summary_service.dart:7-129`]
