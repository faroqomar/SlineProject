# saved — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does:
  - The feature lets an authenticated user bookmark tasks, list them on a dedicated screen, show a saved-count badge in profile, and toggle save state from tender and booking task cards. File Reference: `lib/features/saved/view/saved_tasks_screen.dart:11-169`, `lib/features/profile/view/profile_screen.dart:427-446`, `lib/features/tasks/view/widgets/booking_task_card.dart:153-181`, `lib/features/tasks/view/widgets/tender_task_card.dart:253-286`
- Boundaries (in scope):
  - Primary feature files under `lib/features/saved/**`. File Reference: `lib/features/saved/view/saved_tasks_screen.dart:1-169`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:1-152`, `lib/features/saved/data/saved_tasks_service.dart:1-137`, `lib/features/saved/models/saved_task_model.dart:1-52`, `lib/features/saved/view/widgets/saved_task_tile.dart:1-31`, `lib/features/saved/routes/saved_routes.dart:1-13`
  - Direct dependencies the feature touches: global provider wiring, profile summary RPC service, task model parsing, task-card consumers, and saved-related docs / SQL contracts. File Reference: `lib/main.dart:166-169`, `lib/features/profile/services/profile_summary_service.dart:6-58`, `lib/features/tasks/models/task_model.dart:18-307`, `lib/features/home/view/home_screen.dart:74-96`, `lib/features/profile/view/profile_screen.dart:427-446`, `lib/features/tasks/view/widgets/booking_task_card.dart:153-181`, `lib/features/tasks/view/widgets/tender_task_card.dart:253-286`, `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:12-137`, `Sline_everything/SUPABASE_SETUP.md:769-778`, `Sline_everything/SUPABASE_SETUP.md:1120-1126`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:10-31`
- Boundaries (out of scope):
  - Task creation, task detail business logic, search, booking workflows, and any backend migration not present in this repository. File Reference: `lib/features/saved/view/saved_tasks_screen.dart:151-159`, `lib/features/tasks/models/task_model.dart:106-307`
  - `saved_tasks` table creation / policy SQL is `UNVERIFIED` because no versioned migration defining that table or its policies was found under `supabase/migrations/`. Missing files: any migration creating `public.saved_tasks` and its RLS policies
- Entry points (screens/routes/calls):
  - Global provider creation at app startup. File Reference: `lib/main.dart:166-169`
  - Saved screen entry from profile menu. File Reference: `lib/features/profile/view/profile_screen.dart:430-443`
  - Saved screen auto-load on open. File Reference: `lib/features/saved/view/saved_tasks_screen.dart:22-28`
  - Refresh entry from Home pull-to-refresh. File Reference: `lib/features/home/view/home_screen.dart:76-90`
  - Save toggle entry from booking and tender task cards. File Reference: `lib/features/tasks/view/widgets/booking_task_card.dart:156-162`, `lib/features/tasks/view/widgets/tender_task_card.dart:257-265`

## 1) Feature Map (Current Repo State)
- Primary feature files (with references):
  - `lib/features/saved/view/saved_tasks_screen.dart` — screen shell, load trigger, empty/error/list UI, direct navigation to task details. File Reference: `lib/features/saved/view/saved_tasks_screen.dart:13-169`
  - `lib/features/saved/viewmodels/saved_tasks_view_model.dart` — owns saved ids, saved task list, error/loading state, toggle flow, and auth listener. File Reference: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:15-152`
  - `lib/features/saved/data/saved_tasks_service.dart` — Supabase CRUD against `saved_tasks`, join to `tasks`, profile enrichment via RPC service. File Reference: `lib/features/saved/data/saved_tasks_service.dart:8-137`
  - `lib/features/saved/models/saved_task_model.dart` — row model for `saved_tasks`. File Reference: `lib/features/saved/models/saved_task_model.dart:4-52`
  - `lib/features/saved/view/widgets/saved_task_tile.dart` — alternate tile widget not used by the current screen. File Reference: `lib/features/saved/view/widgets/saved_task_tile.dart:3-31`
  - `lib/features/saved/routes/saved_routes.dart` — route helper for the saved screen. File Reference: `lib/features/saved/routes/saved_routes.dart:4-13`
- Direct dependencies (with references):
  - App-level provider wiring. File Reference: `lib/main.dart:166-169`
  - Cross-user profile summary RPC wrapper used by the service. File Reference: `lib/features/profile/services/profile_summary_service.dart:6-58`
  - Task parsing contract the feature hydrates into. File Reference: `lib/features/tasks/models/task_model.dart:106-179`, `lib/features/tasks/models/task_model.dart:261-306`
  - Task-card save button consumers. File Reference: `lib/features/tasks/view/widgets/booking_task_card.dart:153-181`, `lib/features/tasks/view/widgets/tender_task_card.dart:253-286`
  - Home refresh path calling `saved.refresh()`. File Reference: `lib/features/home/view/home_screen.dart:76-90`
  - Profile badge and screen navigation using saved state directly. File Reference: `lib/features/profile/view/profile_screen.dart:427-443`
  - Shared task/profile hydration pattern duplicated in task service. File Reference: `lib/features/tasks/services/task_service.dart:47-88`
- Supabase touchpoints (tables/RPC/storage/realtime) (with references to code or SQL docs):
  - Table `public.saved_tasks` for `SELECT`, `INSERT`, `DELETE`. File Reference: `lib/features/saved/data/saved_tasks_service.dart:27-68`, `Sline_everything/SUPABASE_SETUP.md:769-778`, `Sline_everything/SUPABASE_SETUP.md:1120-1126`
  - Table `public.tasks` via joined relation `task:tasks(*)`. File Reference: `lib/features/saved/data/saved_tasks_service.dart:89-137`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:10-21`
  - RPC `public.rpc_get_profile_summaries(uuid[])` for safe cross-user author data. File Reference: `lib/features/profile/services/profile_summary_service.dart:13-33`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`, `Sline_everything/SUPABASE_SETUP.md:1208-1212`
  - Storage buckets: none observed in audited saved files. File Reference: `lib/features/saved/data/saved_tasks_service.dart:1-137`
  - Realtime channels: none observed in audited saved files. File Reference: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:1-152`
  - Edge functions: none observed in audited saved files. File Reference: `lib/features/saved/data/saved_tasks_service.dart:1-137`
  - `saved_tasks` DDL / versioned RLS migration is `UNVERIFIED`. Missing files: any `supabase/migrations/*saved*` migration defining `public.saved_tasks`, its indexes, and policies

## 2) Evidence Index (Ground Truth)
| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
| --- | --- | --- | --- | --- |
| `SAV-SEC-01` | `saved_tasks` RLS exists in docs but not in versioned SQL in this repo | `Sline_everything/SUPABASE_SETUP.md:1120-1126`; Missing files: any `supabase/migrations/*saved*` RLS migration | High | Authorization source of truth is not verifiable from repo SQL |
| `SAV-DATA-01` | Saved-task join assumes `task` is always non-null | `lib/features/saved/data/saved_tasks_service.dart:93-116`; `supabase/migrations/20260301_harden_home_related_read_policies.sql:10-21`; `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:121-126` | High | Current code contradicts documented orphan-task handling |
| `SAV-DATA-02` | Toggle updates `_savedTaskIds` but refreshes `_savedTasks` without a second notify | `lib/features/saved/viewmodels/saved_tasks_view_model.dart:62-77`; `lib/features/profile/view/profile_screen.dart:427-435`; `lib/features/saved/view/saved_tasks_screen.dart:115-161` | High | List and badge can drift from icon state |
| `SAV-DATA-03` | Toggle is read-then-write and callers do not debounce or await | `lib/features/saved/data/saved_tasks_service.dart:71-87`; `lib/features/tasks/view/widgets/booking_task_card.dart:156-162`; `lib/features/tasks/view/widgets/tender_task_card.dart:257-265` | High | Rapid taps can race |
| `SAV-ARCH-01` | ViewModel reaches into `Supabase.instance.client.auth` directly | `lib/features/saved/viewmodels/saved_tasks_view_model.dart:106-121` | Medium | MVVM dependency boundary leak |
| `SAV-ARCH-02` | Saved screen depends on another feature's view layer directly | `lib/features/saved/view/saved_tasks_screen.dart:7-9`, `lib/features/saved/view/saved_tasks_screen.dart:151-159` | Medium | Cross-feature UI coupling |
| `SAV-ARCH-03` | Route helper exists but profile screen bypasses it and pushes the screen directly | `lib/features/saved/routes/saved_routes.dart:4-13`; `lib/features/profile/view/profile_screen.dart:436-443` | Low | Route contract drift |
| `SAV-CODE-01` | Unused tile / route helper / row-model path exist | `lib/features/saved/view/widgets/saved_task_tile.dart:3-31`; `lib/features/saved/routes/saved_routes.dart:4-13`; `lib/features/saved/models/saved_task_model.dart:4-52`; `lib/features/saved/data/saved_tasks_service.dart:26-38` | Medium | Dead or partially dead code surface |
| `SAV-CODE-02` | UI naming is inconsistent: "Saved Tasks" vs "Saved Projects" | `lib/features/saved/view/saved_tasks_screen.dart:79-83`; `lib/features/profile/view/profile_screen.dart:430-435` | Low | UX inconsistency |
| `SAV-PERF-01` | The same feature can load on provider init, on screen open, and on home refresh | `lib/main.dart:166-169`; `lib/features/saved/viewmodels/saved_tasks_view_model.dart:106-110`; `lib/features/saved/view/saved_tasks_screen.dart:22-28`; `lib/features/home/view/home_screen.dart:76-90` | Medium | Redundant network work |
| `SAV-PERF-02` | Saved feature duplicates task-profile hydration logic already present in task service | `lib/features/saved/data/saved_tasks_service.dart:102-135`; `lib/features/tasks/services/task_service.dart:47-88` | Low | Maintenance and performance drift risk |
| `SAV-TEST-01` | Current tests only mock `SavedTasksViewModel` in dependent screens; no saved-feature tests were found | `test/widget/home/home_screen_test.dart:32-68`, `test/widget/home/home_screen_test.dart:133-152`; `test/widget/tasks/tenders_screen_test.dart:23-25`, `test/widget/tasks/tenders_screen_test.dart:71-95`; `test/widget/booking/bookings_discovery_screen_test.dart:23-25`, `test/widget/booking/bookings_discovery_screen_test.dart:71-95`; Missing files: dedicated `test/**/saved*` suites | Medium | Critical saved flows are untested directly |

## 3) Findings
### 3.1 Security (Highest Priority)
- `SAV-SEC-01` — File Reference: `Sline_everything/SUPABASE_SETUP.md:1120-1126`; Missing files: any `supabase/migrations/*saved*` migration defining `saved_tasks` policies. Impact: The repo cannot prove that owner-only RLS for `saved_tasks` actually exists in the deployed schema, even though the docs claim it does. Exploit/Failure scenario: If the live DB policy differs from the docs, users could read or mutate another user's saved rows and the client would not prevent it because client checks are not the auth source of truth.
- `SAV-SEC-01` — File Reference: `lib/features/saved/data/saved_tasks_service.dart:89-137`, `lib/features/profile/services/profile_summary_service.dart:13-33`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:19-47`. Impact: The current client correctly routes cross-user profile access through `rpc_get_profile_summaries` instead of direct `profiles` reads, which is the right boundary, but the saved table policy remains `UNVERIFIED`. Exploit/Failure scenario: A future refactor that bypasses this RPC would violate the self-only `profiles` policy shown in `supabase/migrations/20260301_harden_home_related_read_policies.sql:27-31`.

### 3.2 Data Integrity
- `SAV-DATA-01` — File Reference: `lib/features/saved/data/saved_tasks_service.dart:93-116`; `supabase/migrations/20260301_harden_home_related_read_policies.sql:10-21`; `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:121-126`. Impact: The service dereferences `row['task']` and `r['task']['user_id']` without null checks, but task reads are allowed only for open or involved tasks. Failure scenario: A user saves an open task, the task later closes or becomes unreadable, and one null joined row crashes the whole saved list instead of being skipped or cleaned up.
- `SAV-DATA-01` — File Reference: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:25-35`, `lib/features/saved/view/saved_tasks_screen.dart:149-161`, `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:125-126`. Impact: The feature stores only `List<Task>` for the saved screen, so it cannot represent an orphaned saved row while still keeping `task_id` available for cleanup. Failure scenario: When a task relation is missing, the UI has no model to render a "task unavailable" state or allow unsave cleanup, even though the docs explicitly call for that behavior.
- `SAV-DATA-02` — File Reference: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:62-77`; `lib/features/profile/view/profile_screen.dart:427-435`; `lib/features/saved/view/saved_tasks_screen.dart:115-161`. Impact: After a successful toggle, `_savedTaskIds` changes and listeners are notified, but `_savedTasks` is refreshed silently afterward. Failure scenario: The save icon updates immediately, but the profile badge and saved list remain stale because those consumers depend on `savedTasks.length` and `savedTasks[index]`.
- `SAV-DATA-02` — File Reference: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:72-76`. Impact: The refresh failure after toggle is swallowed. Failure scenario: The mutation succeeds server-side, `_savedTaskIds` changes locally, the full reload fails, and the user gets no surfaced error even though different app surfaces now disagree.
- `SAV-DATA-03` — File Reference: `lib/features/saved/data/saved_tasks_service.dart:71-87`; `lib/features/tasks/view/widgets/booking_task_card.dart:156-162`; `lib/features/tasks/view/widgets/tender_task_card.dart:257-265`. Impact: Toggle is non-idempotent under concurrency because it does a read followed by a write and the callers allow repeated taps while the first request is in flight. Failure scenario: Rapid taps produce overlapping `isSaved()` snapshots, duplicate insert attempts, or last-write-wins local state that does not match the server.

### 3.3 Architecture
- `SAV-ARCH-01` — File Reference: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:106-121`. Impact: The ViewModel depends directly on Supabase auth state, which breaks the intended MVVM direction and makes session IO harder to test. Failure scenario: Any future auth-session change requires touching the ViewModel instead of an injected feature service, and unit tests must mock the whole Supabase auth surface.
- `SAV-ARCH-02` — File Reference: `lib/features/saved/view/saved_tasks_screen.dart:7-9`, `lib/features/saved/view/saved_tasks_screen.dart:151-159`. Impact: The saved feature view imports and constructs another feature's view widgets directly (`TaskCard`, `TaskDetailsScreen`). Failure scenario: Task feature UI refactors become breaking changes for saved because there is no stable route/helper boundary between features.
- `SAV-ARCH-03` — File Reference: `lib/features/saved/routes/saved_routes.dart:4-13`; `lib/features/profile/view/profile_screen.dart:436-443`. Impact: The route helper is not the actual navigation seam because the profile screen bypasses it and constructs `SavedTasksScreen` directly. Failure scenario: Route-level changes can drift out of sync because callers are not forced through one entry point.

### 3.4 Code Quality
- `SAV-CODE-01` — File Reference: `lib/features/saved/view/widgets/saved_task_tile.dart:3-31`; `lib/features/saved/routes/saved_routes.dart:4-13`; `lib/features/saved/models/saved_task_model.dart:4-52`; `lib/features/saved/data/saved_tasks_service.dart:26-38`. Impact: The feature contains dead or partially dead code paths that do not participate in the current screen flow. Failure scenario: Future changes update the live path but miss unused files, leaving misleading or stale code in the repo.
- `SAV-CODE-02` — File Reference: `lib/features/saved/view/saved_tasks_screen.dart:79-83`; `lib/features/profile/view/profile_screen.dart:430-435`. Impact: The UI names the same feature as both "Saved Tasks" and "Saved Projects". Failure scenario: Users see inconsistent labels across entry points, and future tests or copy updates can diverge further.
- `SAV-CODE-01` — File Reference: `lib/features/saved/view/saved_tasks_screen.dart:31-34`. Impact: The screen keeps an empty `dispose()` override that adds no behavior. Failure scenario: It creates maintenance noise and suggests lifecycle work exists when it does not.

### 3.5 Performance
- `SAV-PERF-01` — File Reference: `lib/main.dart:166-169`; `lib/features/saved/viewmodels/saved_tasks_view_model.dart:106-110`; `lib/features/saved/view/saved_tasks_screen.dart:22-28`; `lib/features/home/view/home_screen.dart:76-90`. Impact: The feature can load multiple times for the same session without any freshness guard. Failure scenario: App start loads saved state, opening the screen loads it again, and home refresh loads it again, multiplying identical queries and RPC calls.
- `SAV-PERF-01` — File Reference: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:37-56`, `lib/features/saved/viewmodels/saved_tasks_view_model.dart:141-150`. Impact: `load()` always emits at least two notifications (`_setLoading(true)` and `_setLoading(false)`), plus error-state notifications when relevant, even when no data changes. Failure scenario: Consumers rebuild more often than needed during repeated refreshes.
- `SAV-PERF-02` — File Reference: `lib/features/saved/data/saved_tasks_service.dart:71-87`, `lib/features/saved/data/saved_tasks_service.dart:89-135`, `lib/features/tasks/services/task_service.dart:47-88`. Impact: Each toggle may trigger an existence read, a mutation, a full saved-list reload, and a profile-summary RPC; the profile hydration logic is also duplicated in task service. Failure scenario: Save/unsave interactions remain heavier than necessary and the two hydration paths drift over time.

### 3.6 Testing Gaps
- `SAV-TEST-01` — File Reference: `test/widget/home/home_screen_test.dart:32-68`, `test/widget/home/home_screen_test.dart:133-152`. Impact: Home coverage only asserts that refresh calls `savedVm.refresh()`. Failure scenario: It does not detect saved-state drift, stale badge counts, or orphaned saved rows.
- `SAV-TEST-01` — File Reference: `test/widget/tasks/tenders_screen_test.dart:23-25`, `test/widget/tasks/tenders_screen_test.dart:71-95`; `test/widget/booking/bookings_discovery_screen_test.dart:23-25`, `test/widget/booking/bookings_discovery_screen_test.dart:71-95`. Impact: Booking/tender tests only mock `isSaved(any())` and never exercise toggle behavior. Failure scenario: Race conditions and pending-state bugs can ship without test coverage.
- `SAV-TEST-01` — Missing files: dedicated `test/**/saved*` suites. Impact: There is no direct unit or widget coverage for `SavedTasksService`, `SavedTasksViewModel`, or `SavedTasksScreen`. Failure scenario: The highest-risk saved flows are only indirectly covered, which is not enough for null join handling, auth listener behavior, or concurrency.

## 4) Dead/Unused Code Candidates
- Candidate: `lib/features/saved/view/widgets/saved_task_tile.dart`. File Reference: `lib/features/saved/view/widgets/saved_task_tile.dart:3-31`. Why candidate: The current saved screen renders `TaskCard`, not `SavedTaskTile`. File Reference: `lib/features/saved/view/saved_tasks_screen.dart:149-160`. How to confirm: run `rg -n "SavedTaskTile" lib test --glob '*.dart'`.
- Candidate: `lib/features/saved/routes/saved_routes.dart`. File Reference: `lib/features/saved/routes/saved_routes.dart:4-13`. Why candidate: The profile screen pushes `SavedTasksScreen` directly instead of going through `SavedRoutes`. File Reference: `lib/features/profile/view/profile_screen.dart:436-443`. How to confirm: run `rg -n "SavedRoutes\\.routeName|SavedRoutes\\.route\\(" lib test --glob '*.dart'`.
- Candidate: `lib/features/saved/models/saved_task_model.dart` and `SavedTasksService.listMine()`. File Reference: `lib/features/saved/models/saved_task_model.dart:4-52`, `lib/features/saved/data/saved_tasks_service.dart:26-38`. Why candidate: The active flow uses `listMineWithDetails()` and `List<Task>`, not `SavedTaskModel`. File Reference: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:37-45`. How to confirm: run `rg -n "SavedTaskModel|listMine\\(" lib test --glob '*.dart'`.
- Candidate: `SavedTasksViewModel.savedTaskIds`. File Reference: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:31-35`. Why candidate: external consumers in audited scope use `isSaved(...)` or `savedTasks.length`, not the exposed list getter. File Reference: `lib/features/profile/view/profile_screen.dart:427-435`, `lib/features/tasks/view/widgets/booking_task_card.dart:156-162`, `lib/features/tasks/view/widgets/tender_task_card.dart:257-265`. How to confirm: run `rg -n "savedTaskIds\\b" lib test --glob '*.dart'`.

## 5) Duplicate Code Candidates
- Duplicate: task save-button rendering and `toggle(task.id)` call pattern. File Reference: `lib/features/tasks/view/widgets/booking_task_card.dart:153-181`, `lib/features/tasks/view/widgets/tender_task_card.dart:253-286`. Proposed shared abstraction: `lib/features/tasks/view/widgets/task_save_button.dart`.
- Duplicate: task/profile hydration via `ProfileSummaryService.fetchByIds(...)` and task mutation through `Task.copyWith(...)`. File Reference: `lib/features/saved/data/saved_tasks_service.dart:102-135`, `lib/features/tasks/services/task_service.dart:47-88`. Proposed shared abstraction: `lib/features/tasks/services/task_profile_hydrator.dart`.
- Duplicate: direct `TaskDetailsScreen(task: task)` navigation from screen code instead of a route helper. File Reference: `lib/features/saved/view/saved_tasks_screen.dart:153-157`; `UNVERIFIED` broader duplicates outside audited scope are not included here. Proposed shared abstraction: `lib/features/tasks/routes/task_details_route.dart`.

## 6) Refactor Plan (Exact Paths)
- Split saved screen shell from render-state body.
  - Keep: `lib/features/saved/view/saved_tasks_screen.dart`
  - Create: `lib/features/saved/view/widgets/saved_tasks_body.dart`
  - Create: `lib/features/saved/view/widgets/saved_tasks_state_view.dart`
  - Migration strategy: move loading/error/empty/list branches first without changing business logic; keep `SavedTasksScreen` as the only public screen export during the transition.
- Add an aggregate model that can represent an orphaned saved row.
  - Keep: `lib/features/saved/models/saved_task_model.dart` for raw row data
  - Create: `lib/features/saved/models/saved_task_list_item.dart`
  - Migration strategy: make `SavedTasksService.listMineWithDetails()` return `List<SavedTaskListItem>` and adapt `SavedTasksViewModel` + saved screen in the same patch; do not leave mixed `Task` / saved-row states.
- Move auth-session binding out of the ViewModel.
  - Keep: `lib/features/saved/viewmodels/saved_tasks_view_model.dart`
  - Create: `lib/features/saved/data/saved_tasks_session_service.dart`
  - Migration strategy: inject the session service into the ViewModel through `lib/main.dart` and remove direct `Supabase.instance.client.auth` usage from the ViewModel in one patch.
- Extract shared save button UI/behavior for task cards.
  - Create: `lib/features/tasks/view/widgets/task_save_button.dart`
  - Edit: `lib/features/tasks/view/widgets/booking_task_card.dart`
  - Edit: `lib/features/tasks/view/widgets/tender_task_card.dart`
  - Migration strategy: introduce the shared widget with the same visuals first, then add pending-state disablement without changing card layout.
- Add a stable task-details route helper.
  - Create: `lib/features/tasks/routes/task_details_route.dart`
  - Edit: `lib/features/saved/view/saved_tasks_screen.dart`
  - Migration strategy: adopt the helper in saved first; keep `TaskDetailsScreen` public until other callers are migrated.
- Remove or wire current dead code.
  - Delete after confirmation: `lib/features/saved/view/widgets/saved_task_tile.dart`
  - Delete after confirmation: `lib/features/saved/routes/saved_routes.dart`
  - Delete or repurpose after aggregate-model rollout: `lib/features/saved/models/saved_task_model.dart` if raw-row cleanup is not needed separately
  - Migration strategy: confirm usage with `rg` before deletion; if a compatibility period is needed, keep thin wrappers for one patch only.

## 7) Fix Plan (Phases)
### Phase 1: Critical security & correctness
- Item 1. What to change: add or verify the versioned SQL migration that creates/hardens `saved_tasks` owner-only RLS and the unique `(user_id, task_id)` constraint. Exact file(s) to edit/create: create `supabase/migrations/<timestamp>_create_or_harden_saved_tasks_rls.sql`; optionally update `Sline_everything/SUPABASE_SETUP.md`. Acceptance criteria: repo contains executable SQL for `saved_tasks_select_own`, `saved_tasks_insert_own`, `saved_tasks_delete_own`, and the unique index/constraint documented in `Sline_everything/SUPABASE_SETUP.md:1120-1126`, `Sline_everything/SUPABASE_SETUP.md:1574-1575`.
- Item 2. What to change: make `listMineWithDetails()` null-safe for missing joined tasks and carry enough saved-row metadata to support cleanup. Exact file(s) to edit/create: `lib/features/saved/data/saved_tasks_service.dart`, `lib/features/saved/models/saved_task_model.dart`, create `lib/features/saved/models/saved_task_list_item.dart`, edit `lib/features/saved/viewmodels/saved_tasks_view_model.dart`, edit `lib/features/saved/view/saved_tasks_screen.dart`. Acceptance criteria: a null `task:tasks(*)` row does not crash the saved screen; the feature can either hide orphaned rows safely or render an unavailable state with an unsave action.
- Item 3. What to change: normalize state updates after toggle and stop swallowing post-mutation refresh failures. Exact file(s) to edit/create: `lib/features/saved/viewmodels/saved_tasks_view_model.dart`, `lib/features/profile/view/profile_screen.dart`, `lib/features/saved/view/saved_tasks_screen.dart`. Acceptance criteria: save icon, saved list, and profile badge update from one authoritative state path; refresh failures surface a user-safe error instead of silent drift.
- Item 4. What to change: add per-task in-flight protection and await toggle from UI callers. Exact file(s) to edit/create: `lib/features/saved/viewmodels/saved_tasks_view_model.dart`, `lib/features/tasks/view/widgets/booking_task_card.dart`, `lib/features/tasks/view/widgets/tender_task_card.dart`, optionally create `lib/features/tasks/view/widgets/task_save_button.dart`. Acceptance criteria: repeated taps while a mutation is active are ignored or disabled; no overlapping toggle requests for the same task id.

### Phase 2: Refactor/structure
- Item 1. What to change: move auth/session listening into an injected feature service. Exact file(s) to edit/create: create `lib/features/saved/data/saved_tasks_session_service.dart`, edit `lib/features/saved/viewmodels/saved_tasks_view_model.dart`, edit `lib/main.dart`. Acceptance criteria: `SavedTasksViewModel` no longer imports or references `Supabase.instance.client.auth`.
- Item 2. What to change: split `SavedTasksScreen` into screen shell and render-state widgets. Exact file(s) to edit/create: `lib/features/saved/view/saved_tasks_screen.dart`, create `lib/features/saved/view/widgets/saved_tasks_body.dart`, create `lib/features/saved/view/widgets/saved_tasks_state_view.dart`. Acceptance criteria: state-branch rendering becomes independently testable without changing screen behavior.
- Item 3. What to change: replace direct `TaskDetailsScreen` construction with a route helper. Exact file(s) to edit/create: create `lib/features/tasks/routes/task_details_route.dart`, edit `lib/features/saved/view/saved_tasks_screen.dart`. Acceptance criteria: saved feature no longer imports `lib/features/tasks/view/task_details_screen.dart` directly.
- Item 4. What to change: either delete `SavedRoutes` / `SavedTaskTile` or wire them into the active flow. Exact file(s) to edit/create: `lib/features/saved/routes/saved_routes.dart`, `lib/features/saved/view/widgets/saved_task_tile.dart`, `lib/features/profile/view/profile_screen.dart`. Acceptance criteria: no dead route/widget remains in the feature after repo-wide usage confirmation.

### Phase 3: Tests
- Item 1. What to change: add unit tests for service null-join handling and toggle concurrency/state synchronization. Exact file(s) to edit/create: create `test/features/saved/data/saved_tasks_service_test.dart`, create `test/features/saved/viewmodels/saved_tasks_view_model_test.dart`. Acceptance criteria: tests cover null joined task rows, duplicate-save behavior, sign-out clearing, and per-task pending protection.
- Item 2. What to change: add widget tests for saved screen state branches and profile badge synchronization. Exact file(s) to edit/create: create `test/features/saved/view/saved_tasks_screen_test.dart`, create `test/features/saved/view/widgets/saved_tasks_state_view_test.dart`, edit `test/widget/home/home_screen_test.dart` and/or create a focused profile badge test. Acceptance criteria: loading, error, empty, populated, and orphan-row states are all exercised directly.
- Item 3. What to change: extend task-card tests to assert save interaction behavior, not just `isSaved`. Exact file(s) to edit/create: edit `test/widget/tasks/tenders_screen_test.dart`, edit `test/widget/booking/bookings_discovery_screen_test.dart`. Acceptance criteria: tests verify the save button disables or ignores repeated taps while a mutation is in flight.

### Phase 4: Polish/perf
- Item 1. What to change: replace unconditional `load()` on screen open with `ensureLoaded()` or staleness-based refresh. Exact file(s) to edit/create: `lib/features/saved/viewmodels/saved_tasks_view_model.dart`, `lib/features/saved/view/saved_tasks_screen.dart`, `lib/features/home/view/home_screen.dart`. Acceptance criteria: opening the saved screen after a fresh app load does not reissue the same request unnecessarily.
- Item 2. What to change: reuse shared task/profile hydration instead of duplicating it locally. Exact file(s) to edit/create: create `lib/features/tasks/services/task_profile_hydrator.dart`, edit `lib/features/saved/data/saved_tasks_service.dart`, edit `lib/features/tasks/services/task_service.dart`. Acceptance criteria: one hydration path is used in both saved and task-feed code.
- Item 3. What to change: align user-facing naming to one label. Exact file(s) to edit/create: `lib/features/profile/view/profile_screen.dart`, `lib/features/saved/view/saved_tasks_screen.dart`. Acceptance criteria: the same English label is used at every saved-feature entry point.

## 8) Verification Checklist
### Commands
- `flutter analyze`
- `dart format --output=none --set-exit-if-changed lib/features/saved lib/features/tasks/view/widgets lib/features/tasks/routes lib/features/tasks/services lib/features/profile/view/profile_screen.dart lib/features/home/view/home_screen.dart`
- `flutter test test/features/saved/data/saved_tasks_service_test.dart`
- `flutter test test/features/saved/viewmodels/saved_tasks_view_model_test.dart`
- `flutter test test/features/saved/view/saved_tasks_screen_test.dart`
- `flutter test test/widget/home/home_screen_test.dart`
- `flutter test test/widget/tasks/tenders_screen_test.dart`
- `flutter test test/widget/booking/bookings_discovery_screen_test.dart`
- `rg -n "SavedTaskTile|SavedRoutes\\.routeName|SavedRoutes\\.route\\(" lib test --glob '*.dart'`
- `rg -n "Supabase\\.instance\\.client\\.auth|onAuthStateChange" lib/features/saved --glob '*.dart'`
- `rg -n "from\\('saved_tasks'\\)|rpc_get_profile_summaries" lib/features/saved lib/features/profile/services/profile_summary_service.dart --glob '*.dart'`

### Manual Scenarios
- Scenario 1. Sign in, open the profile menu, enter the saved screen.
  - Expected: screen loads once, shows either empty state or saved items, and the title text matches the chosen canonical label. File Reference: `lib/features/profile/view/profile_screen.dart:430-443`, `lib/features/saved/view/saved_tasks_screen.dart:79-83`
- Scenario 2. Save a task from a tender card, then check the saved screen and profile badge.
  - Expected: icon, saved screen, and badge count stay in sync. File Reference: `lib/features/tasks/view/widgets/tender_task_card.dart:257-265`, `lib/features/profile/view/profile_screen.dart:427-435`, `lib/features/saved/view/saved_tasks_screen.dart:149-161`
- Scenario 3. Save and unsave rapidly on the same booking card.
  - Expected: only one in-flight mutation is allowed per task id; no duplicate or flickering final state. File Reference: `lib/features/tasks/view/widgets/booking_task_card.dart:156-162`, `lib/features/saved/data/saved_tasks_service.dart:71-87`
- Scenario 4. Save a task, then make the related task unreadable or missing in the database.
  - Expected: saved screen still loads; orphaned saved rows do not crash the feature; cleanup remains possible if that UX is implemented. File Reference: `lib/features/saved/data/saved_tasks_service.dart:93-135`, `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:121-126`
- Scenario 5. Sign out while saved data exists.
  - Expected: saved state clears immediately and no prior-user data remains visible. File Reference: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:112-129`

### Supabase/RLS Contract Checks
- Validate that a versioned migration exists for `public.saved_tasks` creation, unique `(user_id, task_id)`, and the three owner-only policies. Current state is `UNVERIFIED`. Missing files: any `supabase/migrations/*saved*` migration
- Validate that `rpc_get_profile_summaries(uuid[])` remains authenticated-only and security-definer. File Reference: `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:14-47`
- Validate that `tasks_select_authenticated_open_or_involved` still restricts reads the way the saved feature assumes. File Reference: `supabase/migrations/20260301_harden_home_related_read_policies.sql:10-21`
- Validate docs after fixes so the orphan-row behavior documented in `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md:121-126` matches the actual saved screen behavior.

## 9) Risks & Rollback Notes
- What could break:
  - Converting the saved list from `List<Task>` to an aggregate row model changes the ViewModel and screen contract. File Reference: `lib/features/saved/viewmodels/saved_tasks_view_model.dart:25-35`, `lib/features/saved/view/saved_tasks_screen.dart:149-161`
  - Save-button refactoring touches booking and tender cards. File Reference: `lib/features/tasks/view/widgets/booking_task_card.dart:153-181`, `lib/features/tasks/view/widgets/tender_task_card.dart:253-286`
  - Session-listener refactor touches app provider wiring. File Reference: `lib/main.dart:166-169`
- Rollback steps:
  - Revert the aggregate-model and UI refactor first if the saved screen regresses, but keep the RLS migration and null-join guard if those already shipped safely.
  - If the shared save-button extraction causes UI regressions, roll back only `lib/features/tasks/view/widgets/task_save_button.dart` adoption and restore the prior button markup while keeping per-task pending state in the ViewModel.
  - If auth-session injection regresses startup behavior, revert `lib/main.dart` wiring and `saved_tasks_session_service.dart` while preserving the correctness fixes in service null handling and toggle synchronization.
