# home — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does:
  - Renders the Home feed UI (header, search, category chips, filters modal, task list, refresh) and navigates to task details. File References: `lib/features/home/view/home_screen.dart:21-39`, `lib/features/home/view/home_screen.dart:79-91`, `lib/features/home/view/home_screen.dart:289-318`.
- Boundaries (in scope):
  - Home feature files under `lib/features/home/**`. File References: `lib/features/home/view/home_screen.dart:1-375`, `lib/features/home/view/widgets/filters_modal.dart:1-353`, `lib/features/home/view/widgets/service_card.dart:1-177`, `lib/features/home/viewmodels/home_view_model.dart:1-127`.
  - Direct dependencies invoked/embedded by Home (filters VM, task feed service path, profile VM path, saved-tasks VM/service path, task card, task details screen, notification badge widget). File References: `lib/features/home/view/home_screen.dart:10-19`, `lib/features/home/view/home_screen.dart:48-53`, `lib/features/home/view/home_screen.dart:60-68`, `lib/features/home/view/home_screen.dart:144-145`, `lib/features/home/view/home_screen.dart:160-171`, `lib/features/home/view/home_screen.dart:302-309`.
- Boundaries (out of scope):
  - Internal behavior of `TaskDetailsScreen`, notifications modal internals, and unrelated task/profile/wallet flows beyond what Home directly calls/renders. File References: `lib/features/home/view/home_screen.dart:144-145`, `lib/features/home/view/home_screen.dart:302-309`, `lib/features/tasks/view/task_details_screen.dart:22-34`, `lib/features/notifications/view/widgets/notification_badge_button.dart:10-75`.
- Entry points (screens/routes/calls):
  - Route registration `/home`. File Reference: `lib/main.dart:231-236`.
  - Bottom-nav screen inclusion (`HomeScreen()` in main navigation). File Reference: `lib/app/main_navigation_screen.dart:38-49`.
  - `HomeScreen.initState()` triggers `HomeViewModel.loadFeaturedTasks()` and `ProfileViewModel.loadProfile()`. File Reference: `lib/features/home/view/home_screen.dart:43-53`.
  - Pull-to-refresh triggers home refresh + profile reload + saved refresh. File Reference: `lib/features/home/view/home_screen.dart:79-89`.

## 1) Feature Map (Current Repo State)
- Primary feature files (with references):
  - `lib/features/home/view/home_screen.dart` (main screen + provider composition + list rendering). File Reference: `lib/features/home/view/home_screen.dart:1-375`.
  - `lib/features/home/view/widgets/filters_modal.dart` (advanced filters UI + local form state). File Reference: `lib/features/home/view/widgets/filters_modal.dart:1-353`.
  - `lib/features/home/view/widgets/service_card.dart` (legacy/alternate task card widget in home folder). File Reference: `lib/features/home/view/widgets/service_card.dart:1-177`.
  - `lib/features/home/viewmodels/home_view_model.dart` (feed loading + pagination state). File Reference: `lib/features/home/viewmodels/home_view_model.dart:1-127`.
- Direct dependencies (with references):
  - Route entry points: `lib/main.dart:228-236`, `lib/app/main_navigation_screen.dart:38-49`.
  - Task filtering state: `lib/features/tasks/viewmodels/task_filter_view_model.dart:5-135`.
  - Task feed data query (home path): `lib/features/tasks/services/task_service.dart:42-63`, `lib/features/tasks/services/task_service.dart:416-460`.
  - Task model/card/details navigation targets: `lib/features/tasks/models/task_model.dart:12-73`, `lib/features/tasks/view/widgets/task_card.dart:17-42`, `lib/features/tasks/view/task_details_screen.dart:22-34`.
  - Profile loading path used by Home header refresh: `lib/features/profile/viewmodels/profile_view_model.dart:63-95`, `lib/features/profile/viewmodels/profile_view_model.dart:143-160`, `lib/features/profile/viewmodels/profile_view_model.dart:419-431`.
  - Profile repository/storage calls indirectly triggered by Home profile load: `lib/features/profile/data/profile_repository.dart:24-31`, `lib/features/profile/data/profile_repository.dart:89-100`, `lib/features/profile/data/profile_repository.dart:110-117`, `lib/features/profile/services/avatar_service.dart:10-14`, `lib/features/profile/services/avatar_service.dart:54-62`.
  - Saved/bookmarking state + data path instantiated by Home: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:15-20`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:37-57`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:61-88`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:106-122`, `lib/features/saved/data/saved_tasks_service.dart:23-141`.
  - Notification badge widget embedded in header: `lib/features/notifications/view/widgets/notification_badge_button.dart:10-75`.
  - Category constants rendered by Home chips: `lib/shared/constants/categories.dart:1-11`, `lib/features/home/view/home_screen.dart:201-243`.
- Supabase touchpoints (tables/RPC/storage/realtime) (with references to code or SQL docs):
  - Table `public.tasks` (home feed read, filtered by status=open). File Reference: `lib/features/tasks/services/task_service.dart:421-443`.
  - Table `public.profiles` (task profile hydration for home feed). File Reference: `lib/features/tasks/services/task_service.dart:42-63`.
  - Table `public.saved_tasks` (home-created saved/bookmark VM/service load/toggle path). File References: `lib/features/saved/data/saved_tasks_service.dart:23-93`, `lib/features/home/view/home_screen.dart:60-68`.
  - Table `public.tasks` + `public.profiles` joined through saved-task details hydration. File Reference: `lib/features/saved/data/saved_tasks_service.dart:85-141`.
  - Table `public.profiles` (Home header profile load path). File References: `lib/features/profile/viewmodels/profile_view_model.dart:66-95`, `lib/features/profile/data/profile_repository.dart:24-31`, `lib/features/profile/data/profile_repository.dart:89-96`.
  - Table `public.portfolio_items` (indirect heavy fetch triggered by Home `loadProfile`). File References: `lib/features/profile/viewmodels/profile_view_model.dart:86-86`, `lib/features/profile/viewmodels/profile_view_model.dart:143-160`, `lib/features/profile/data/profile_repository.dart:110-117`.
  - Storage bucket `avatars` (signed URL generation triggered by Home `loadProfile`). File References: `lib/features/profile/viewmodels/profile_view_model.dart:86-86`, `lib/features/profile/viewmodels/profile_view_model.dart:419-431`, `lib/features/profile/data/profile_repository.dart:98-100`, `lib/features/profile/services/avatar_service.dart:10-14`, `lib/features/profile/services/avatar_service.dart:54-62`.
  - RPCs / realtime channels / edge functions in Home call path: none observed in scoped code paths above. File References: `lib/features/tasks/services/task_service.dart:416-460`, `lib/features/saved/data/saved_tasks_service.dart:23-141`, `lib/features/profile/viewmodels/profile_view_model.dart:63-95`, `lib/features/profile/data/profile_repository.dart:24-31`, `lib/features/profile/data/profile_repository.dart:89-117`.
  - RLS policy source for `public.tasks`, `public.profiles`, `public.saved_tasks`: **UNVERIFIED** (missing visible base schema/RLS SQL in current repo snapshot under `supabase/migrations/*.sql`; only recent wallet/ledger/tender migration files are present). Missing files: baseline migrations or schema policy SQL for those tables.

## 2) Evidence Index (Ground Truth)

| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
| --- | --- | --- | --- | --- |
| SEC-01 | Home authorization contract depends on DB RLS, but repo snapshot does not expose `tasks`/`profiles`/`saved_tasks` policy SQL for verification. | UNVERIFIED — expected under `supabase/migrations/*.sql` (missing base policy/schema files) | High | Missing files prevent repo-level authz verification. |
| SEC-02 | Home feed query enforces only `status = open` on client query path. | `lib/features/tasks/services/task_service.dart:421-425` | High | Visibility beyond status must be enforced by RLS/view. |
| DI-01 | Home pagination cursor uses only `created_at` with `<` filter + single-field order. | `lib/features/tasks/services/task_service.dart:426-433` | Medium | Tied timestamps can skip/duplicate rows. |
| DI-02 | Home UI has no visible pagination trigger but ViewModel implements `loadMoreTasks()`. | `lib/features/home/view/home_screen.dart:90-91`, `lib/features/home/view/home_screen.dart:297-318`, `lib/features/home/viewmodels/home_view_model.dart:93-121` | Medium | First-page-only behavior risk. |
| DI-03 | Advanced delivery-time and seller-level filters are exposed in UI but no-op in filter VM. | `lib/features/home/view/widgets/filters_modal.dart:207-257`, `lib/features/home/view/widgets/filters_modal.dart:260-346`, `lib/features/tasks/viewmodels/task_filter_view_model.dart:110-120` | Medium | User can believe filters applied when results are unchanged. |
| DI-04 | `Reset All` sets slider state to `1000` but clears max-budget text; apply reads text controllers. | `lib/features/home/view/widgets/filters_modal.dart:73-85`, `lib/features/home/view/widgets/filters_modal.dart:164-205`, `lib/features/home/view/widgets/filters_modal.dart:336-345` | Medium | UI state and applied filter payload can diverge. |
| DI-05 | Max-budget text input writes raw parsed value to slider-backed state without clamping to `0..5000`. | `lib/features/home/view/widgets/filters_modal.dart:165-167`, `lib/features/home/view/widgets/filters_modal.dart:197-200` | Medium | Invalid slider values can assert in debug / destabilize UI. |
| ARC-01 | `HomeScreen` directly instantiates `SavedTasksService` and `SavedTasksViewModel` in the view layer. | `lib/features/home/view/home_screen.dart:60-68` | Medium | MVVM/DI boundary leak and duplicated init behavior risk. |
| ARC-02 | Home triggers `ProfileViewModel.loadProfile()`, which fetches profile + avatar URL + portfolio. | `lib/features/home/view/home_screen.dart:52-53`, `lib/features/home/view/home_screen.dart:86-86`, `lib/features/profile/viewmodels/profile_view_model.dart:63-95`, `lib/features/profile/viewmodels/profile_view_model.dart:143-160`, `lib/features/profile/viewmodels/profile_view_model.dart:419-431` | Medium | Home header depends on broad profile feature workload. |
| ARC-03 | `HomeViewModel` mutates `TaskFilterViewModel` state via method parameters. | `lib/features/home/viewmodels/home_view_model.dart:57-59`, `lib/features/home/viewmodels/home_view_model.dart:81-83`, `lib/features/home/viewmodels/home_view_model.dart:93-94`, `lib/features/home/viewmodels/home_view_model.dart:112-114` | Low | Cross-feature coupling increases coordination complexity. |
| CQ-01 | `HomeViewModel` logs errors but exposes no error state to UI. | `lib/features/home/viewmodels/home_view_model.dart:35-42`, `lib/features/home/viewmodels/home_view_model.dart:84-89`, `lib/features/home/viewmodels/home_view_model.dart:115-120`, `lib/features/home/view/home_screen.dart:264-288` | Medium | Failure can present as empty feed. |
| CQ-02 | `TaskFilterViewModel.applyAdvancedFilters()` stores incoming list references directly. | `lib/features/tasks/viewmodels/task_filter_view_model.dart:48-61` | Low | Mutable aliasing risk from UI-owned lists. |
| CQ-03 | `_applyFilters()` always calls `notifyListeners()` regardless of actual state change. | `lib/features/tasks/viewmodels/task_filter_view_model.dart:74-75`, `lib/features/tasks/viewmodels/task_filter_view_model.dart:132-133` | Low | Rebuild noise and harder performance tuning. |
| CQ-04 | Multiple interactive home controls use `GestureDetector` instead of semantic Material controls. | `lib/features/home/view/home_screen.dart:164-171`, `lib/features/home/view/home_screen.dart:338-373`, `lib/features/home/view/widgets/filters_modal.dart:72-85`, `lib/features/home/view/widgets/filters_modal.dart:278-325` | Low | Accessibility/focus/feedback debt. |
| PERF-01 | Saved tasks may load twice on Home startup (`HomeScreen` calls `vm.load()` and `SavedTasksViewModel` auth listener also calls `load()`). | `lib/features/home/view/home_screen.dart:60-67`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:18-20`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:106-122` | Medium | Duplicate network requests and extra rebuilds. |
| PERF-02 | Pull-to-refresh performs feed, profile, and saved refresh sequentially. | `lib/features/home/view/home_screen.dart:81-89` | Medium | Longer refresh latency than necessary. |
| PERF-03 | Broad `Consumer3` wraps header + feed list, widening rebuild scope. | `lib/features/home/view/home_screen.dart:73-75`, `lib/features/home/view/home_screen.dart:92-318` | Medium | Profile/filter changes rebuild more UI than needed. |
| PERF-04 | Home header refresh path triggers portfolio fetch and avatar signed URL refresh (heavy for header-only usage). | `lib/features/home/view/home_screen.dart:52-53`, `lib/features/profile/viewmodels/profile_view_model.dart:66-95`, `lib/features/profile/viewmodels/profile_view_model.dart:143-160`, `lib/features/profile/viewmodels/profile_view_model.dart:419-431`, `lib/features/profile/data/profile_repository.dart:110-117` | Medium | Unnecessary DB/storage work on Home load/refresh. |
| PERF-05 | Saved-task toggle reloads full saved-task details list after optimistic ID update. | `lib/features/saved/viewmodels/saved_tasks_view_model.dart:61-77`, `lib/features/saved/data/saved_tasks_service.dart:85-141` | Low | Expensive for frequent bookmark interactions. |
| TEST-01 | Home widget tests cover shell/search/refresh only; no pagination/error/filter-modal correctness tests. | `test/widget/home/home_screen_test.dart:98-145` | Medium | Critical UI flows can regress undetected. |
| TEST-02 | Task filter tests omit sort-mode coverage, invalid ranges, and placeholder-filter behavior expectations. | `test/unit/tasks/task_filter_view_model_test.dart:31-213`, `lib/features/tasks/viewmodels/task_filter_view_model.dart:110-130` | Medium | Filter regressions may ship silently. |
| TEST-03 | No visible HomeViewModel unit tests for pagination/cursor/error states in current repo snapshot. | UNVERIFIED — no `test/**` file found for `HomeViewModel` during scoped static search | Medium | Missing unit coverage for core feed state machine. |

## 3) Findings

### 3.1 Security (Highest Priority)
- `SEC-01` — **UNVERIFIED RLS contract for Home data path**. File Reference: `UNVERIFIED` (missing base policy/schema SQL for `public.tasks`, `public.profiles`, `public.saved_tasks` under `supabase/migrations/*.sql`). Impact: repo audit cannot confirm authorization source of truth for Home feed, profile hydration, and saved-task reads. Exploit/Failure scenario: if deployed RLS is permissive, Home and saved-task queries can return unauthorized rows even though client code appears filtered.
- `SEC-02` — **Home feed query filters by status only, not by explicit visibility rule**. File Reference: `lib/features/tasks/services/task_service.dart:421-425`. Impact: Home feed access semantics are incomplete at client query layer and must rely on RLS/view logic for true authorization. Exploit/Failure scenario: an "open" task that should remain private can appear in Home if backend policies do not additionally constrain visibility.

### 3.2 Data Integrity
- `DI-01` — **Cursor pagination is not stable for timestamp ties**. File Reference: `lib/features/tasks/services/task_service.dart:426-433`. Impact: feed pages can skip or duplicate tasks when multiple rows share the same `created_at`. Failure scenario: page 1 ends on timestamp `T`; page 2 uses `lt(created_at, T)` and drops sibling rows also created at `T`.
- `DI-02` — **Pagination implementation exists but Home UI does not trigger it**. File References: `lib/features/home/view/home_screen.dart:90-91`, `lib/features/home/view/home_screen.dart:297-318`, `lib/features/home/viewmodels/home_view_model.dart:93-121`. Impact: Home feed behaves as single-page despite pagination state, causing silent truncation of results. Failure scenario: users only ever see first `TaskService.defaultPageSize` tasks even when more open tasks exist.
- `DI-03` — **Delivery-time and seller-level filters are exposed but not applied**. File References: `lib/features/home/view/widgets/filters_modal.dart:207-257`, `lib/features/home/view/widgets/filters_modal.dart:260-346`, `lib/features/tasks/viewmodels/task_filter_view_model.dart:110-120`. Impact: filter UI can misrepresent result set correctness. Failure scenario: user selects delivery/seller filters, taps "Apply Filters," and sees unchanged results while assuming constraints are active.
- `DI-04` — **Reset/apply mismatch between slider state and text fields**. File References: `lib/features/home/view/widgets/filters_modal.dart:73-85`, `lib/features/home/view/widgets/filters_modal.dart:164-205`, `lib/features/home/view/widgets/filters_modal.dart:336-345`. Impact: applied max-budget filter can differ from on-screen slider value. Failure scenario: after "Reset All," slider shows `1000` but max-budget text is empty, so apply submits `null` max budget.
- `DI-05` — **Budget text input can set out-of-range slider value**. File References: `lib/features/home/view/widgets/filters_modal.dart:165-167`, `lib/features/home/view/widgets/filters_modal.dart:197-200`. Impact: invalid UI state and debug assertions under common manual input. Failure scenario: entering `900000` updates `_maxBudget` beyond slider `max=5000`, producing runtime assertion in debug mode.

### 3.3 Architecture
- `ARC-01` — **View-layer DI violation (Home constructs service + VM)**. File Reference: `lib/features/home/view/home_screen.dart:60-68`. Impact: presentation layer owns data-layer construction and lifecycle details, reducing composability/testability and increasing accidental duplicate initialization. Failure scenario: future route reuse/nesting creates multiple saved-task listeners/loads because Home always instantiates a new provider locally.
- `ARC-02` — **Home header depends on broad Profile feature loading path**. File References: `lib/features/home/view/home_screen.dart:52-53`, `lib/features/home/view/home_screen.dart:86-86`, `lib/features/profile/viewmodels/profile_view_model.dart:63-95`, `lib/features/profile/viewmodels/profile_view_model.dart:143-160`, `lib/features/profile/viewmodels/profile_view_model.dart:419-431`. Impact: Home feature boundary expands to portfolio and avatar-refresh concerns unrelated to feed rendering. Failure scenario: profile portfolio query failure/noise degrades Home refresh even when header only needs name/avatar.
- `ARC-03` — **Cross-feature state mutation coupling (`HomeViewModel` -> `TaskFilterViewModel`)**. File References: `lib/features/home/viewmodels/home_view_model.dart:57-59`, `lib/features/home/viewmodels/home_view_model.dart:81-83`, `lib/features/home/viewmodels/home_view_model.dart:112-114`. Impact: Home feed loading has hidden side effects and increases coordination complexity. Failure scenario: later reuse of `HomeViewModel` without filter VM leaves UI state stale or creates duplicated filtering orchestration elsewhere.

### 3.4 Code Quality
- `CQ-01` — **No explicit Home error state; failures collapse into empty-state UX**. File References: `lib/features/home/viewmodels/home_view_model.dart:35-42`, `lib/features/home/viewmodels/home_view_model.dart:84-89`, `lib/features/home/viewmodels/home_view_model.dart:115-120`, `lib/features/home/view/home_screen.dart:264-288`. Impact: users cannot distinguish network failure from genuinely empty feed. Failure scenario: transient backend outage shows "No tasks found" and hides retry intent.
- `CQ-02` — **Mutable list aliasing risk in advanced filters assignment**. File Reference: `lib/features/tasks/viewmodels/task_filter_view_model.dart:48-61`. Impact: UI-owned lists can mutate VM state unexpectedly after apply. Failure scenario: caller mutates `_deliveryTimes` list after `applyAdvancedFilters()`, changing filter behavior without explicit VM method call.
- `CQ-03` — **Unconditional `notifyListeners()` in filter pipeline**. File References: `lib/features/tasks/viewmodels/task_filter_view_model.dart:74-75`, `lib/features/tasks/viewmodels/task_filter_view_model.dart:132-133`. Impact: avoidable rebuilds and noisy state-change semantics. Failure scenario: repeated same query/category values still trigger listeners and downstream widget rebuilds.
- `CQ-04` — **Interactive controls implemented with `GestureDetector` instead of semantic controls**. File References: `lib/features/home/view/home_screen.dart:164-171`, `lib/features/home/view/home_screen.dart:338-373`, `lib/features/home/view/widgets/filters_modal.dart:72-85`, `lib/features/home/view/widgets/filters_modal.dart:278-325`. Impact: weaker accessibility semantics/focus behavior and inconsistent Material feedback. Failure scenario: keyboard/focus navigation and assistive technologies miss actionable elements.

### 3.5 Performance
- `PERF-01` — **Duplicate saved-task loads on Home startup are likely**. File References: `lib/features/home/view/home_screen.dart:60-67`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:18-20`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:106-122`. Impact: extra network calls and repeated `notifyListeners()` at app entry/return to Home. Failure scenario: signed-in user opens Home and both `HomeScreen` and auth listener call `load()`.
- `PERF-02` — **Refresh operations are serialized**. File Reference: `lib/features/home/view/home_screen.dart:81-89`. Impact: longer pull-to-refresh duration and slower perceived responsiveness. Failure scenario: slow profile load blocks saved-task refresh completion and spinner dismissal.
- `PERF-03` — **Rebuild scope is broader than necessary (`Consumer3` wraps header + list)**. File References: `lib/features/home/view/home_screen.dart:73-75`, `lib/features/home/view/home_screen.dart:92-318`. Impact: frequent filter/profile changes rebuild unrelated UI sections. Failure scenario: profile avatar/name update rebuilds the entire task list sliver tree.
- `PERF-04` — **Home header load path overfetches portfolio data**. File References: `lib/features/home/view/home_screen.dart:52-53`, `lib/features/profile/viewmodels/profile_view_model.dart:66-95`, `lib/features/profile/viewmodels/profile_view_model.dart:143-160`, `lib/features/profile/data/profile_repository.dart:110-117`. Impact: unnecessary DB work during Home init/refresh. Failure scenario: large `portfolio_items` history increases Home tab open time despite no portfolio UI on Home.
- `PERF-05` — **Saved-task toggle reloads full saved-task details list**. File References: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:61-77`, `lib/features/saved/data/saved_tasks_service.dart:85-141`. Impact: avoidable heavy query path after every bookmark action. Failure scenario: rapid save/unsave interactions cause repeated `saved_tasks` + `tasks` + `profiles` fetches.

### 3.6 Testing Gaps
- `TEST-01` — **Home widget coverage is narrow (shell/search/refresh only)**. File Reference: `test/widget/home/home_screen_test.dart:98-145`. Gap: no tests for pagination trigger, error-state UI, filter modal reset/apply correctness, or autoload init behavior.
- `TEST-02` — **Task filter tests omit sort-mode and invalid-input edge cases**. File References: `test/unit/tasks/task_filter_view_model_test.dart:31-213`, `lib/features/tasks/viewmodels/task_filter_view_model.dart:110-130`. Gap: no assertions for `Newest`/price sort branches, invalid min/max ranges, or placeholder-filter behavior expectations.
- `TEST-03` — **HomeViewModel state-machine tests are missing in current repo snapshot**. File Reference: `UNVERIFIED` (no visible `HomeViewModel` unit test file in scoped `test/**` search). Gap: no direct tests for cursor paging, `hasMore`, and error handling transitions.
- `TEST-04` — **RLS contract checks for Home tables are missing from visible repo SQL/test assets**. File Reference: `UNVERIFIED` (missing visible policy SQL for `public.tasks`, `public.profiles`, `public.saved_tasks`). Gap: no repo-verifiable authorization tests/policies for Home data path.

## 4) Dead/Unused Code Candidates
- Candidate: `lib/features/home/view/widgets/service_card.dart:1-177`
  - Why suspected unused: Home list renders `TaskCard`, not `ServiceCard`. File Reference: `lib/features/home/view/home_screen.dart:299-313`.
  - How to confirm: run `rg -n "ServiceCard\\(" lib test`; if only declaration remains (excluding unrelated `features/services` widget), delete file. Confirmation status: `UNVERIFIED` from file-only evidence until search command is rerun.
- Candidate: `HomeViewModel.loadMoreTasks()` in `lib/features/home/viewmodels/home_view_model.dart:93-121`
  - Why suspected unused in Home flow: no invocation in `HomeScreen` list/scroll code path. File References: `lib/features/home/view/home_screen.dart:90-91`, `lib/features/home/view/home_screen.dart:297-318`.
  - How to confirm: run `rg -n "loadMoreTasks\\(" lib test`; if declaration-only, either wire pagination or remove method.
- Candidate: `HomeViewModel.featuredTasks` getter in `lib/features/home/viewmodels/home_view_model.dart:44-45`
  - Why suspected unused in Home UI: Home renders `filterController.filteredTasks` instead. File Reference: `lib/features/home/view/home_screen.dart:300-315`.
  - How to confirm: run `rg -n "featuredTasks\b" lib test`; remove if no external consumer remains. Confirmation status: `UNVERIFIED` from file-only evidence until search command is rerun.

## 5) Duplicate Code Candidates
- Duplicate card responsibility:
  - `lib/features/home/view/widgets/service_card.dart:7-177` and `lib/features/tasks/view/widgets/task_card.dart:17-42` both implement task/service card rendering entry points.
  - Proposed shared abstraction: standardize on `TaskCard` in tasks feature; delete home-local duplicate or wrap `TaskCard` with a thin `HomeTaskCard` if Home-specific styling is needed.
- Duplicate task+profile hydration logic:
  - `TaskService` batch fetches `profiles` and merges into task JSON. File References: `lib/features/tasks/services/task_service.dart:42-78`, `lib/features/tasks/services/task_service.dart:435-443`.
  - `SavedTasksService` repeats `profiles` fetch + task merge after `saved_tasks` join. File References: `lib/features/saved/data/saved_tasks_service.dart:98-141`.
  - Proposed shared abstraction: create a shared task hydration utility/service in tasks domain (e.g., `lib/features/tasks/services/task_profile_hydrator.dart`) used by both services.

## 6) Refactor Plan (Exact Paths)
- Split Home screen composition from presentation to restore DI boundaries:
  - Create `lib/features/home/view/home_screen_scope.dart` (provider composition for Home-scoped dependencies, including saved-task VM if Home owns it).
  - Keep `lib/features/home/view/home_screen.dart` as presentation-only screen consuming injected providers.
  - Migration strategy: temporarily keep existing `HomeScreen` constructor API (`autoLoadOnInit`, `savedTasksVmFactory`) while moving default provider construction into `HomeScreenScope`; update call sites in `lib/main.dart` and `lib/app/main_navigation_screen.dart` last.
- Split `HomeScreen` UI into narrower widgets to reduce rebuild scope:
  - Create `lib/features/home/view/widgets/home_header_section.dart` (profile + notifications + search/filter launcher).
  - Create `lib/features/home/view/widgets/home_category_chips.dart` (category chips row).
  - Create `lib/features/home/view/widgets/home_task_feed_sliver.dart` (loading/empty/list/error slivers + pagination trigger).
  - Keep `lib/features/home/view/home_screen.dart` as shell composing slivers.
  - Migration strategy: extract pure widgets first without behavior changes; then add `Selector`/narrow `Consumer` scopes.
- Rename the modal for feature-specific clarity:
  - Move `lib/features/home/view/widgets/filters_modal.dart` -> `lib/features/home/view/widgets/home_filters_bottom_sheet.dart`.
  - Migration strategy: keep a temporary shim file `lib/features/home/view/widgets/filters_modal.dart` exporting the new widget until imports are updated, then remove shim.
- Introduce a lightweight Home header profile path (optional but recommended after correctness fixes):
  - Create `lib/features/home/viewmodels/home_header_view_model.dart` (name/avatar only).
  - Create `lib/features/home/data/home_profile_summary_repository.dart` (minimal profile + avatar-path fetches) or reuse profile repository through a narrow interface.
  - Migration strategy: land new VM alongside existing `ProfileViewModel` usage; switch `HomeScreen` after parity tests pass.
- Deduplicate task/profile hydration code:
  - Create `lib/features/tasks/services/task_profile_hydrator.dart`.
  - Edit `lib/features/tasks/services/task_service.dart` and `lib/features/saved/data/saved_tasks_service.dart` to consume the shared hydrator.
  - Migration strategy: no API changes to callers; internal refactor only.

## 7) Fix Plan (Phases)

Phase 1: Critical security & correctness
- Item 1 — Verify and enforce Home RLS contract
  - What to change:
    - Audit deployed policies for `public.tasks`, `public.profiles`, `public.saved_tasks`; add/commit missing policy SQL if absent.
    - Ensure Home visibility rules are enforced by RLS (not only `status='open'`).
  - Exact file(s) to edit/create:
    - Create `supabase/migrations/20260224_home_feed_rls_contract.sql` (or next available timestamp) with policy definitions/adjustments for Home tables.
    - If base policies already exist outside repo: add documentation pointer in `/.TODO/home.TODO.md` or project DB docs file (UNVERIFIED doc path until located).
  - Acceptance criteria:
    - Policies for `public.tasks`, `public.profiles`, and `public.saved_tasks` are present in repo SQL or linked as authoritative source.
    - Authenticated user cannot read another user's `saved_tasks` rows.
    - Home feed returns only intended visible/open tasks under anon/auth roles.
- Item 2 — Fix misleading advanced filters and budget-state inconsistencies
  - What to change:
    - Either implement delivery/seller filters in `TaskFilterViewModel` or disable/hide those UI options until supported.
    - Clamp/validate budget inputs and unify slider/text source of truth.
    - Make "Reset All" keep visible state and applied payload consistent.
  - Exact file(s) to edit/create:
    - Edit `lib/features/home/view/widgets/filters_modal.dart` (or renamed `home_filters_bottom_sheet.dart`).
    - Edit `lib/features/tasks/viewmodels/task_filter_view_model.dart`.
    - Add tests in `test/unit/tasks/task_filter_view_model_test.dart` and `test/widget/home/home_screen_test.dart` (or new modal widget test file).
  - Acceptance criteria:
    - Selecting unsupported filters no longer silently no-ops (implemented or visibly disabled).
    - Invalid budget inputs cannot push slider state out of range.
    - "Reset All" then "Apply Filters" yields default filter state deterministically.
- Item 3 — Make Home pagination behavior correct (wire or remove)
  - What to change:
    - Add pagination trigger in Home feed UI (scroll threshold / sliver-based trigger) calling `HomeViewModel.loadMoreTasks()`.
    - Stabilize paging cursor ordering (prefer composite order/cursor; if not possible, document tie behavior and add safeguard).
  - Exact file(s) to edit/create:
    - Edit `lib/features/home/view/home_screen.dart` (or extracted `home_task_feed_sliver.dart`).
    - Edit `lib/features/home/viewmodels/home_view_model.dart`.
    - Edit `lib/features/tasks/services/task_service.dart`.
    - Add `test/unit/home/home_view_model_test.dart` (new) and extend `test/widget/home/home_screen_test.dart`.
  - Acceptance criteria:
    - More than one page of tasks loads in Home when available.
    - No duplicate/skipped rows across page boundaries in test fixture with tied timestamps.
    - `hasMore` and loading-more states are observable and correct.
- Item 4 — Add explicit Home error state (distinct from empty results)
  - What to change:
    - Add error field/state in `HomeViewModel` and render an error UI with retry action.
  - Exact file(s) to edit/create:
    - Edit `lib/features/home/viewmodels/home_view_model.dart`.
    - Edit `lib/features/home/view/home_screen.dart` (or extracted feed sliver widget).
    - Extend `test/widget/home/home_screen_test.dart`; add `test/unit/home/home_view_model_test.dart`.
  - Acceptance criteria:
    - Network failure path shows error UI (not "No tasks found").
    - Retry action invokes reload and clears error state on success.

Phase 2: Refactor/structure
- Item 1 — Move provider/service construction out of `HomeScreen`
  - What to change:
    - Create `HomeScreenScope` (or use app-level provider composition) and stop constructing `SavedTasksService` inside the view.
  - Exact file(s) to edit/create:
    - Create `lib/features/home/view/home_screen_scope.dart`.
    - Edit `lib/features/home/view/home_screen.dart`.
    - Edit `lib/main.dart` and `lib/app/main_navigation_screen.dart` if route/tab should mount `HomeScreenScope` instead of `HomeScreen`.
  - Acceptance criteria:
    - `HomeScreen` no longer instantiates `SavedTasksService`/`SavedTasksViewModel` directly.
    - Existing Home tests can inject mocks without constructor-level factory workaround (or with simpler override pattern).
- Item 2 — Reduce rebuild scope with widget extraction/selectors
  - What to change:
    - Split header/chips/feed slivers and use narrower `Consumer`/`Selector` scopes.
  - Exact file(s) to edit/create:
    - Create `lib/features/home/view/widgets/home_header_section.dart`.
    - Create `lib/features/home/view/widgets/home_category_chips.dart`.
    - Create `lib/features/home/view/widgets/home_task_feed_sliver.dart`.
    - Edit `lib/features/home/view/home_screen.dart`.
  - Acceptance criteria:
    - Profile updates no longer rebuild full task list widget tree.
    - Filter-only updates avoid rebuilding unrelated header subtrees where possible.
- Item 3 — Decouple Home header from full `ProfileViewModel.loadProfile()` path
  - What to change:
    - Introduce minimal header profile loader and stop portfolio fetch on Home init/refresh.
  - Exact file(s) to edit/create:
    - Create `lib/features/home/viewmodels/home_header_view_model.dart` (or equivalent narrow adapter).
    - Edit `lib/features/home/view/home_screen.dart` / `home_header_section.dart`.
    - Optional: create `lib/features/home/data/home_profile_summary_repository.dart`.
  - Acceptance criteria:
    - Home init/refresh no longer triggers `portfolio_items` query for header-only rendering.
    - Header still shows name/avatar correctly.
- Item 4 — Deduplicate task hydration code
  - What to change:
    - Extract shared task/profile hydration helper used by `TaskService` and `SavedTasksService`.
  - Exact file(s) to edit/create:
    - Create `lib/features/tasks/services/task_profile_hydrator.dart`.
    - Edit `lib/features/tasks/services/task_service.dart`.
    - Edit `lib/features/saved/data/saved_tasks_service.dart`.
  - Acceptance criteria:
    - No duplicated profile batch-fetch + merge logic remains across the two services.
    - Existing behavior remains unchanged (same task parsing outputs).
- Item 5 — Remove/retire duplicate home `ServiceCard`
  - What to change:
    - Delete unused home-local card or convert to compatibility wrapper around `TaskCard` if actively referenced outside scoped files.
  - Exact file(s) to edit/create:
    - Delete `lib/features/home/view/widgets/service_card.dart` (preferred) or replace contents with thin wrapper.
  - Acceptance criteria:
    - No remaining references to deleted widget in `lib/` or `test/`.
    - Home uses only `TaskCard` path for task rendering.

Phase 3: Tests
- Item 1 — Add HomeViewModel unit tests
  - What to change:
    - Test initial load, error state, `hasMore`, `loadMoreTasks`, and cursor boundary behavior.
  - Exact file(s) to edit/create:
    - Create `test/unit/home/home_view_model_test.dart`.
    - Add/extend test doubles for `TaskService` as needed.
  - Acceptance criteria:
    - Failing and success load paths are both covered.
    - Pagination tests include tied `created_at` boundary fixture.
- Item 2 — Expand Home widget tests
  - What to change:
    - Add tests for `autoLoadOnInit`, error-vs-empty UI, pagination trigger, and filters modal reset/apply validation.
  - Exact file(s) to edit/create:
    - Edit `test/widget/home/home_screen_test.dart`.
    - Optional new file: `test/widget/home/home_filters_bottom_sheet_test.dart`.
  - Acceptance criteria:
    - Widget tests fail if pagination trigger is removed or if error UI regresses to empty state.
    - Modal tests cover reset/apply consistency and invalid budget inputs.
- Item 3 — Expand filter VM tests
  - What to change:
    - Add sort-branch tests, invalid budget range handling, and behavior for delivery/seller filters (implemented or disabled expectation).
  - Exact file(s) to edit/create:
    - Edit `test/unit/tasks/task_filter_view_model_test.dart`.
  - Acceptance criteria:
    - All filter branches in `TaskFilterViewModel` have explicit expected behavior tests.
- Item 4 — Add/verify RLS contract checks (if local Supabase harness exists)
  - What to change:
    - Add SQL policy assertions or documented manual checks for Home tables.
  - Exact file(s) to edit/create:
    - Create `supabase/tests/home_rls_checks.sql` (if project uses SQL test scripts) or document in project DB test docs (UNVERIFIED target path until DB test convention is confirmed).
  - Acceptance criteria:
    - Home-table policy behavior is testable/reproducible by command or script in repo.

Phase 4: Polish/perf
- Item 1 — Eliminate duplicate saved-task startup load
  - What to change:
    - Remove one of the startup `load()` triggers (view or auth-listener path), preserving auth sign-in refresh behavior.
  - Exact file(s) to edit/create:
    - Edit `lib/features/home/view/home_screen.dart` and/or `lib/features/saved/viewmodels/saved_tasks_view_model.dart`.
  - Acceptance criteria:
    - Home startup produces a single saved-task load for signed-in users.
- Item 2 — Parallelize independent refresh work safely
  - What to change:
    - Use `Future.wait` or staged refresh pattern for Home feed/profile/saved refresh where dependencies are independent.
  - Exact file(s) to edit/create:
    - Edit `lib/features/home/view/home_screen.dart`.
  - Acceptance criteria:
    - Pull-to-refresh latency decreases (measured locally) without race regressions.
- Item 3 — Optimize bookmark toggle behavior for Home cards
  - What to change:
    - Avoid reloading full saved-task details list on every toggle when only ID state is required in Home feed.
  - Exact file(s) to edit/create:
    - Edit `lib/features/saved/viewmodels/saved_tasks_view_model.dart`.
    - Optional: edit `lib/features/saved/data/saved_tasks_service.dart` for lighter toggle/status APIs.
  - Acceptance criteria:
    - Save/unsave action updates card state immediately and avoids full-list fetch unless a saved-list screen needs it.
- Item 4 — Accessibility polish for Home interactions
  - What to change:
    - Replace `GestureDetector` controls with `IconButton`, `InkWell`, `ChoiceChip`, or semantic wrappers where appropriate.
  - Exact file(s) to edit/create:
    - Edit `lib/features/home/view/home_screen.dart`.
    - Edit `lib/features/home/view/widgets/filters_modal.dart` (or `home_filters_bottom_sheet.dart`).
  - Acceptance criteria:
    - Interactive elements expose semantics/focus and retain expected visual feedback.

## 8) Verification Checklist

### Commands
- Static analysis (home + direct dependencies touched in this audit):
  - `flutter analyze lib/features/home lib/features/tasks/viewmodels/task_filter_view_model.dart lib/features/tasks/services/task_service.dart lib/features/saved/viewmodels/saved_tasks_view_model.dart lib/features/saved/data/saved_tasks_service.dart lib/features/profile/viewmodels/profile_view_model.dart lib/features/profile/data/profile_repository.dart lib/features/profile/services/avatar_service.dart`
- Existing tests to run before/after fixes:
  - `flutter test test/widget/home/home_screen_test.dart`
  - `flutter test test/unit/tasks/task_filter_view_model_test.dart`
- Additional grep/rg checks (dead code / pagination wiring / duplication):
  - `rg -n "loadMoreTasks\\(" lib test`
  - `rg -n "ServiceCard\\(" lib test`
  - `rg -n "featuredTasks\b" lib test`
  - `rg -n "from\('tasks'\)|from\('profiles'\)|from\('saved_tasks'\)|rpc\(" lib/features/home lib/features/tasks/services/task_service.dart lib/features/saved lib/features/profile`
- SQL/policy visibility check in repo (expected failure until baseline policies are present):
  - `rg -n "CREATE POLICY|ALTER TABLE .* ENABLE ROW LEVEL SECURITY|public\\.(tasks|profiles|saved_tasks)" supabase/migrations -g '*.sql'`

### Manual Scenarios
- Home initial load (signed-in user)
  - Open Home and verify header name/avatar, search/chips, and feed load. File References (behavior entry points): `lib/features/home/view/home_screen.dart:43-53`, `lib/features/home/view/home_screen.dart:79-91`.
  - Confirm no duplicate saved/bookmark loading flicker on first render. File References: `lib/features/home/view/home_screen.dart:60-67`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:106-122`.
- Pagination
  - Seed more than one page of open tasks and scroll to list end repeatedly. File References: `lib/features/tasks/services/task_service.dart:416-460`, `lib/features/home/viewmodels/home_view_model.dart:93-121`.
  - Verify no duplicates/skips across boundaries (especially same `created_at` timestamps). File Reference: `lib/features/tasks/services/task_service.dart:426-433`.
- Filters modal correctness
  - Apply min/max budget via slider and text, then reset and apply again; results and UI should match. File References: `lib/features/home/view/widgets/filters_modal.dart:73-85`, `lib/features/home/view/widgets/filters_modal.dart:164-205`, `lib/features/home/view/widgets/filters_modal.dart:336-345`.
  - Enter invalid max budget (`-1`, `999999`, non-numeric`) and verify no crash/assert. File References: `lib/features/home/view/widgets/filters_modal.dart:165-167`, `lib/features/home/view/widgets/filters_modal.dart:197-200`.
  - Delivery/seller filters should either work or be disabled/clearly labeled unsupported. File References: `lib/features/home/view/widgets/filters_modal.dart:207-257`, `lib/features/home/view/widgets/filters_modal.dart:260-346`, `lib/features/tasks/viewmodels/task_filter_view_model.dart:110-120`.
- Error handling
  - Simulate feed/network failure and verify explicit error UI (not empty state) plus retry path. Current conflation evidence: `lib/features/home/viewmodels/home_view_model.dart:84-89`, `lib/features/home/view/home_screen.dart:264-288`.
- Refresh performance
  - Pull-to-refresh under slow network and verify spinner duration/regressions after parallelization changes. Current sequential path: `lib/features/home/view/home_screen.dart:81-89`.

### Supabase/RLS Contract Checks
- Repo-level policy source validation
  - Confirm policy SQL for `public.tasks`, `public.profiles`, and `public.saved_tasks` exists in `supabase/migrations/*.sql`. Current status: `UNVERIFIED` / missing in visible repo snapshot.
- Database policy introspection (run against Supabase/Postgres)
  - Query `pg_policies` for the three tables and record `qual`/`with_check` predicates.
  - Validate `saved_tasks` owner-only access with two distinct authenticated users.
  - Validate Home feed visibility (anon/auth as applicable) matches product rules for "open" tasks.
- Client authorization rule check
  - Ensure any client-side filtering remains UX-only and does not replace DB policy enforcement. Evidence of client-only status filter: `lib/features/tasks/services/task_service.dart:421-425`.

## 9) Risks & Rollback Notes
- Risk: Tightening RLS can block legitimate Home feed/profile/saved reads if predicates are too strict. File References (affected paths): `lib/features/tasks/services/task_service.dart:416-460`, `lib/features/saved/data/saved_tasks_service.dart:23-141`, `lib/features/profile/data/profile_repository.dart:24-31`, `lib/features/profile/data/profile_repository.dart:89-117`.
  - Rollback steps:
    - Revert the new Home RLS migration file (e.g., `supabase/migrations/20260224_home_feed_rls_contract.sql`) and redeploy policies.
    - Re-run Supabase/RLS contract checks and Home manual scenarios.
- Risk: Pagination query changes can alter feed ordering/visibility and create regressions around infinite scroll. File References: `lib/features/tasks/services/task_service.dart:426-433`, `lib/features/home/viewmodels/home_view_model.dart:93-121`.
  - Rollback steps:
    - Revert pagination query changes in `TaskService` and UI trigger changes in Home feed widget.
    - Keep tests for duplicate/skip boundaries to verify restored behavior.
- Risk: Provider composition refactor can break route/tab integration and tests. File References (current entry points): `lib/main.dart:231-236`, `lib/app/main_navigation_screen.dart:38-49`, `lib/features/home/view/home_screen.dart:60-68`, `test/widget/home/home_screen_test.dart:76-96`.
  - Rollback steps:
    - Restore `HomeScreen` direct provider composition temporarily.
    - Re-point routes/tabs back to `HomeScreen` while keeping extracted widgets inert.
- Risk: Disabling unsupported filters changes visible UI behavior. File References: `lib/features/home/view/widgets/filters_modal.dart:207-257`, `lib/features/home/view/widgets/filters_modal.dart:260-346`, `lib/features/tasks/viewmodels/task_filter_view_model.dart:110-120`.
  - Rollback steps:
    - Re-enable controls only if paired with implemented filter semantics and tests.
