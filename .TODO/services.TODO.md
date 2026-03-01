# services — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview

- What this feature does:
  - Reads and models freelancer service rows from `public.services`, then renders them in profile and dashboard management surfaces. File References: `lib/features/services/services/services_service.dart:11-19`, `lib/features/services/models/service_model.dart:1-59`, `lib/features/profile/view/my_services_screen.dart:19-73`, `lib/features/dashboard/view/widgets/manage_service_list.dart:9-136`.
- Boundaries (in scope):
  - Feature-owned files under `lib/features/services/**`. File References: `lib/features/services/models/service_model.dart:1-59`, `lib/features/services/services/services_service.dart:1-53`, `lib/features/services/view/widgets/service_card.dart:1-53`.
  - Direct consumers and state owners outside the feature folder. File References: `lib/features/profile/view/my_services_screen.dart:1-75`, `lib/features/profile/view/profile_screen.dart:412-425`, `lib/features/dashboard/view/widgets/manage_service_list.dart:1-136`, `lib/features/dashboard/view/tabs/manage_tab.dart:64-75`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:24-52`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:108-118`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:392-476`, `lib/main.dart:136-185`.
- Boundaries (out of scope):
  - Unrelated task, booking, chat, and wallet behaviors inside `DashboardViewModel` were not audited beyond the service-loading paths that this feature directly touches. File References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-418`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:460-476`.
- Entry points (screens/routes/calls):
  - Profile menu pushes `MyServicesScreen`. File Reference: `lib/features/profile/view/profile_screen.dart:412-425`.
  - Freelancer dashboard manage tab mounts `ManageServiceList` for `active`, `draft`, and `paused` states. File Reference: `lib/features/dashboard/view/tabs/manage_tab.dart:64-72`.
  - Global `DashboardViewModel` is created in `main.dart` and immediately loads management data, including services. File References: `lib/main.dart:166-167`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:33-51`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-418`.

## 1) Feature Map (Current Repo State)

- Primary feature files:
  - `lib/features/services/models/service_model.dart` — service row model and JSON mapping. File Reference: `lib/features/services/models/service_model.dart:1-59`.
  - `lib/features/services/services/services_service.dart` — direct Supabase table reads/writes for `public.services`. File Reference: `lib/features/services/services/services_service.dart:1-53`.
  - `lib/features/services/view/widgets/service_card.dart` — shared service card widget used by the profile surface. File Reference: `lib/features/services/view/widgets/service_card.dart:1-53`.
- Direct dependencies:
  - `lib/features/profile/view/my_services_screen.dart` — profile-owned screen that reads `DashboardViewModel.myServices` and renders `ServiceCard`. File Reference: `lib/features/profile/view/my_services_screen.dart:13-73`.
  - `lib/features/profile/view/profile_screen.dart` — launches `MyServicesScreen`. File Reference: `lib/features/profile/view/profile_screen.dart:412-425`.
  - `lib/features/dashboard/view/widgets/manage_service_list.dart` — dashboard-owned service list and private card implementation. File Reference: `lib/features/dashboard/view/widgets/manage_service_list.dart:9-136`.
  - `lib/features/dashboard/view/tabs/manage_tab.dart` — dashboard entry point for service tabs. File Reference: `lib/features/dashboard/view/tabs/manage_tab.dart:64-72`.
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart` — current owner of `_myServices`, constructor-time loading, and service refresh hooks. File References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:24-52`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:108-118`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:392-476`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:588-639`.
  - `lib/main.dart` — global provider registration for `DashboardViewModel` and `SupabaseClient`. File Reference: `lib/main.dart:136-185`.
  - `lib/core/services/logger_service.dart` — token masking used by error logging. File Reference: `lib/core/services/logger_service.dart:59-74`.
- Supabase touchpoints (tables/RPC/storage/realtime):
  - Table: `public.services` via `.from('services')` select/insert/update. File References: `lib/features/services/services/services_service.dart:13-17`, `lib/features/services/services/services_service.dart:28-32`, `lib/features/services/services/services_service.dart:43-46`.
  - Local schema doc for `public.services`. File Reference: `Sline_everything/SUPABASE_SETUP.md:862-876`.
  - RLS / policy SQL for `public.services`: `UNVERIFIED` — no repo-local file reference was found under `supabase/migrations/*.sql` or in a `services` policy section of `Sline_everything/SUPABASE_SETUP.md`. Missing files: any migration or SQL doc that defines `public.services` `SELECT` / `INSERT` / `UPDATE` policies.
  - RPCs / storage buckets / realtime channels / edge functions: `UNVERIFIED` — no in-scope file reference was found for this feature. Missing files: any `services` RPC, storage, realtime, or Edge Function implementation if it exists outside the current repo.

## 2) Evidence Index (Ground Truth)

| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
| --- | --- | --- | --- | --- |
| SVC-SEC-001 | Client write path sends caller-controlled `freelancer_id` and free-form `status` to `public.services`. | `lib/features/services/services/services_service.dart:26-46`; `lib/features/services/models/service_model.dart:48-57` | High | Safe only if RLS is strict. Live policy state is `UNVERIFIED`. |
| SVC-SEC-002 | Read path authorizes by caller-supplied `userId`, not a server-owned contract. | `lib/features/services/services/services_service.dart:11-17`; `lib/features/dashboard/viewmodels/dashboard_view_model.dart:460-468` | Medium | Current caller uses current user id, but the API shape is unsafe-by-design. |
| SVC-SEC-003 | Repo-local `services` table contract is documented, but repo-local RLS/policy SQL is missing. | `Sline_everything/SUPABASE_SETUP.md:862-876` | High | `UNVERIFIED` — missing `services` policy files under `supabase/migrations/*.sql`. |
| SVC-DAT-001 | `MyServicesScreen` passes a `ServiceModel` into a widget that only reads `Map`, so rendered titles/descriptions fall back to placeholders. | `lib/features/profile/view/my_services_screen.dart:51-64`; `lib/features/services/view/widgets/service_card.dart:17-23` | High | This is a verified rendering defect. |
| SVC-DAT-002 | Code treats `draft` as a service status, but the local schema doc only lists `active` and `paused`. | `lib/features/services/models/service_model.dart:8`; `lib/features/dashboard/view/tabs/manage_tab.dart:68-71`; `Sline_everything/SUPABASE_SETUP.md:874` | High | Live DB acceptance of `draft` is `UNVERIFIED`. |
| SVC-DAT-003 | Model parsing force-casts fields that the schema doc marks nullable. | `lib/features/services/models/service_model.dart:30-41`; `Sline_everything/SUPABASE_SETUP.md:868-876` | High | One malformed row can throw and collapse the full list. |
| SVC-ARCH-001 | Service state is stored in global `DashboardViewModel`, not a feature-local ViewModel. | `lib/features/dashboard/viewmodels/dashboard_view_model.dart:24-52`; `lib/features/dashboard/viewmodels/dashboard_view_model.dart:108-118`; `Sline_everything/DEVELOPER_GUIDE.md:42-57` | High | Violates the documented per-feature MVVM structure. |
| SVC-ARCH-002 | Global dashboard provider eagerly loads services from app startup. | `lib/main.dart:166-167`; `lib/features/dashboard/viewmodels/dashboard_view_model.dart:33-51`; `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-418` | Medium | Service data is loaded before service UI is visited. |
| SVC-DAT-004 | Role sync updates `_currentRole` after initial load without reloading management data. | `lib/features/dashboard/viewmodels/dashboard_view_model.dart:47-51`; `lib/features/dashboard/viewmodels/dashboard_view_model.dart:286-316`; `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-418` | High | Wrong-role management data can remain in memory until manual refresh. |
| SVC-QUAL-001 | Service-card rendering is duplicated in two incompatible implementations. | `lib/features/services/view/widgets/service_card.dart:7-53`; `lib/features/dashboard/view/widgets/manage_service_list.dart:38-115` | Medium | One card is untyped; the other is private to dashboard. |
| SVC-QUAL-002 | Service failures are flattened to `[]`, `null`, or `false`, and the UI only renders empty-state branches. | `lib/features/services/services/services_service.dart:20-22`; `lib/features/services/services/services_service.dart:35-37`; `lib/features/services/services/services_service.dart:48-50`; `lib/features/profile/view/my_services_screen.dart:31-65`; `lib/features/dashboard/view/widgets/manage_service_list.dart:19-34` | Medium | Permission, network, and parsing failures are indistinguishable from “no services”. |
| SVC-PERF-001 | Service UI rebuild scope is tied to `DashboardViewModel` via broad `context.watch`. | `lib/features/profile/view/my_services_screen.dart:14-17`; `lib/features/dashboard/view/widgets/manage_service_list.dart:14-17` | Medium | Unrelated dashboard changes rebuild service UI. |
| SVC-TEST-001 | The repo documents unit/widget/integration expectations, but no service-specific test files exist. | `Sline_everything/DEVELOPER_GUIDE.md:169-173` | High | `UNVERIFIED` by file reference for absence; missing files: `test/unit/services/*`, `test/widget/services/*`, and any service integration test. Existing adjacent tests are only under `test/unit/dashboard`, `test/unit/profile`, and `test/widget/dashboard`. |

## 3) Findings

### 3.1 Security (Highest Priority)

- `SVC-SEC-001` — File References: `lib/features/services/services/services_service.dart:26-46`, `lib/features/services/models/service_model.dart:48-57`. Impact: client code can submit `freelancer_id` and arbitrary `status` values directly into `public.services`. Exploit/Failure scenario: if live `public.services` RLS allows broad `INSERT` or `UPDATE`, a user can create or mutate another freelancer’s service row by changing `freelancer_id` or row `id`.
- `SVC-SEC-002` — File References: `lib/features/services/services/services_service.dart:11-17`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:460-468`. Impact: ownership on reads is expressed as a caller-supplied `userId` filter rather than an API that derives identity from auth context. Exploit/Failure scenario: any future caller can request another user’s services by passing a different id; only live RLS can block it.
- `SVC-SEC-003` — File Reference: `Sline_everything/SUPABASE_SETUP.md:862-876`. Impact: the repo documents the table shape but not the `services` authorization contract. Exploit/Failure scenario: engineers may assume owner-only RLS exists while shipping a client-side direct-write path. `UNVERIFIED`: missing repo-local `services` policy SQL files under `supabase/migrations/*.sql` or equivalent SQL docs.
- `SVC-SEC-004` — File Reference: `lib/core/services/logger_service.dart:59-74`. Impact: no service-role key leakage was verified in the audited code, and token masking exists. Exploit/Failure scenario: none verified in current in-scope files. This is a pass note, not a defect.

### 3.2 Data Integrity

- `SVC-DAT-001` — File References: `lib/features/profile/view/my_services_screen.dart:51-64`, `lib/features/services/view/widgets/service_card.dart:17-23`. Impact: `MyServicesScreen` can never render the actual `ServiceModel` title or description because `ServiceCard` only reads `Map`. Failure scenario: users see generic `"Service"` cards and lose service descriptions even when valid data is returned.
- `SVC-DAT-002` — File References: `lib/features/services/models/service_model.dart:8`, `lib/features/dashboard/view/tabs/manage_tab.dart:68-71`, `Sline_everything/SUPABASE_SETUP.md:874`. Impact: the code and local schema doc disagree on valid service statuses. Failure scenario: rows with `draft` may not be valid in the live database, or valid DB rows may not map cleanly to all UI tabs. Live DB behavior is `UNVERIFIED`.
- `SVC-DAT-003` — File References: `lib/features/services/models/service_model.dart:30-41`, `lib/features/services/services/services_service.dart:19-22`, `Sline_everything/SUPABASE_SETUP.md:868-876`. Impact: parsing assumes non-null `freelancer_id`, `title`, `status`, and `created_at` even though the local schema doc marks them nullable. Failure scenario: one malformed row throws during mapping, `getMyServices()` catches it, and the feature silently returns an empty list.
- `SVC-DAT-004` — File References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:47-51`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:286-316`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-418`. Impact: `DashboardViewModel` starts in freelancer mode, loads services immediately, then may switch role later without reloading data. Failure scenario: client users can start the session with stale or wrong-role management data until a manual refresh occurs.
- `SVC-DAT-005` — File References: `lib/features/services/models/service_model.dart:42-44`, `lib/features/dashboard/view/widgets/manage_service_list.dart:79-88`. Impact: `activeOrdersCount` and `rating` are hardcoded placeholders but are displayed as real metrics. Failure scenario: the management UI misrepresents service performance and can drive wrong user decisions.

### 3.3 Architecture

- `SVC-ARCH-001` — File References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:24-52`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:108-118`, `Sline_everything/DEVELOPER_GUIDE.md:42-57`. Impact: the feature has no dedicated ViewModel and stores `services` state inside a global dashboard VM. Failure scenario: service changes require touching dashboard load orchestration, role sync, and unrelated caches, increasing regression risk.
- `SVC-ARCH-002` — File References: `lib/main.dart:166-167`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:33-51`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-418`. Impact: service loading is coupled to global app boot because `DashboardViewModel` is globally instantiated. Failure scenario: app startup performs service reads for users who never open service management.
- `SVC-ARCH-003` — File References: `lib/features/profile/view/my_services_screen.dart:6-7`, `lib/features/dashboard/view/widgets/manage_service_list.dart:6-7`, `Sline_everything/DEVELOPER_GUIDE.md:42-57`. Impact: service UI is split across profile and dashboard folders instead of being owned by the `services` feature. Failure scenario: future service refactors require cross-feature edits and increase import sprawl.
- `SVC-ARCH-004` — File References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:33-43`, `lib/main.dart:183-184`. Impact: `ServicesService` is instantiated directly inside `DashboardViewModel` instead of using the app-level `SupabaseClient` provider. Failure scenario: dependency injection, mocking, and test isolation are weaker than the documented architecture expects.

### 3.4 Code Quality

- `SVC-QUAL-001` — File References: `lib/features/services/view/widgets/service_card.dart:7-53`, `lib/features/dashboard/view/widgets/manage_service_list.dart:38-115`. Impact: two different service-card implementations exist with different contracts and behavior. Failure scenario: one screen can be fixed while the other diverges or regresses.
- `SVC-QUAL-002` — File References: `lib/features/services/view/widgets/service_card.dart:8-23`, `lib/features/profile/view/my_services_screen.dart:56-63`. Impact: `dynamic` service typing hides contract errors until runtime. Failure scenario: future model changes can silently degrade rendering instead of failing at compile time.
- `SVC-QUAL-003` — File References: `lib/features/services/services/services_service.dart:20-22`, `lib/features/services/services/services_service.dart:35-37`, `lib/features/services/services/services_service.dart:48-50`, `lib/features/profile/view/my_services_screen.dart:31-65`. Impact: data failures are downgraded to empty/null/false with no user-visible error channel. Failure scenario: authorization failures or parser bugs appear as “No services found.”
- `SVC-QUAL-004` — File References: `lib/features/profile/view/my_services_screen.dart:60-69`, `lib/features/dashboard/view/widgets/manage_service_list.dart:95-105`. Impact: create/edit/pause actions are placeholders or disabled while write APIs exist. Failure scenario: dead-end UI paths accumulate and service write methods remain unexercised.

### 3.5 Performance

- `SVC-PERF-001` — File References: `lib/main.dart:166-167`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:33-51`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-404`. Impact: service reads happen during global dashboard startup instead of on feature entry. Failure scenario: unnecessary network/database load increases startup cost and can slow unrelated screens.
- `SVC-PERF-002` — File References: `lib/features/profile/view/my_services_screen.dart:14-17`, `lib/features/dashboard/view/widgets/manage_service_list.dart:14-17`. Impact: both service UIs watch the entire `DashboardViewModel`. Failure scenario: unrelated dashboard state changes rebuild service lists.
- `SVC-PERF-003` — File References: `lib/features/dashboard/view/widgets/manage_service_list.dart:16-17`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:112-113`. Impact: filtering by status is recomputed on every build from the full `myServices` list. Failure scenario: list rebuilds and tab switching do more work than needed as data grows.

### 3.6 Testing Gaps

- `SVC-TEST-001` — File Reference: `Sline_everything/DEVELOPER_GUIDE.md:169-173`. Impact: the repo documents unit/widget/integration expectations, but there is no verified service test surface. Failure scenario: the current rendering bug and status-contract mismatch ship without automated detection. `UNVERIFIED` missing files: `test/unit/services/*`, `test/widget/services/*`, service integration tests.
- `SVC-TEST-002` — File References: `lib/features/services/models/service_model.dart:30-45`, `Sline_everything/SUPABASE_SETUP.md:868-876`. Impact: no verified test covers nullable DB rows against the strict parser. Failure scenario: a schema-compatible null value blanks the feature silently.
- `SVC-TEST-003` — File References: `lib/features/services/services/services_service.dart:26-46`, `Sline_everything/SUPABASE_SETUP.md:862-876`. Impact: no verified test covers cross-user reads/writes against the `public.services` RLS contract. Failure scenario: insecure policy changes are not detected before release.
- `SVC-TEST-004` — File References: `lib/features/profile/view/my_services_screen.dart:31-65`, `lib/features/dashboard/view/widgets/manage_service_list.dart:19-34`. Impact: no verified widget tests cover loading, empty, error, and populated service states. Failure scenario: empty-state masking and placeholder rendering regress unnoticed.

## 4) Dead/Unused Code Candidates

- `lib/features/services/services/services_service.dart:26-38` — `createService()` is a dead/unused candidate. Why: `UNVERIFIED` by file reference for absence, but repo-wide search found no call site outside its own definition. How to confirm: run `rg -n "createService\\(" lib --glob '*.dart'` and verify only this definition remains.
- `lib/features/services/services/services_service.dart:41-50` — `updateStatus()` is a dead/unused candidate. Why: `UNVERIFIED` by file reference for absence, but repo-wide search found no call site outside its own definition. How to confirm: run `rg -n "updateStatus\\(" lib --glob '*.dart'` and verify no services feature caller exists.
- `lib/features/profile/view/my_services_screen.dart:60-69` — tap and FAB callbacks are placeholder-only branches. Why: they do not execute feature behavior today. How to confirm: open the screen and verify both actions are no-ops.

## 5) Duplicate Code Candidates

- Duplicate pair:
  - `lib/features/services/view/widgets/service_card.dart:7-53`
  - `lib/features/dashboard/view/widgets/manage_service_list.dart:38-115`
- Why duplicate:
  - Both files render service summary cards.
  - They do not share a typed contract.
  - They already diverged: one only handles `Map`; the other only handles `ServiceModel`.
- Proposed shared abstraction:
  - Create `lib/features/services/view/widgets/service_summary_card.dart` for typed read-only summary rendering.
  - Create `lib/features/services/view/widgets/service_management_actions.dart` for edit/pause controls used only by management surfaces.

## 6) Refactor Plan (Exact Paths)

- Move `lib/features/profile/view/my_services_screen.dart` -> `lib/features/services/view/my_services_screen.dart`.
  - Migration strategy: keep a temporary wrapper file at the old path that re-exports or forwards to the new screen until all imports are updated.
- Move `lib/features/dashboard/view/widgets/manage_service_list.dart` -> `lib/features/services/view/widgets/manage_service_list.dart`.
  - Migration strategy: keep a temporary export at the old dashboard path until `manage_tab.dart` imports the new path directly.
- Split service state out of `lib/features/dashboard/viewmodels/dashboard_view_model.dart` into `lib/features/services/viewmodels/services_view_model.dart`.
  - Migration strategy: keep a compatibility getter in `DashboardViewModel` that delegates to `ServicesViewModel` during the transition.
- Rename `lib/features/services/services/services_service.dart` -> `lib/features/services/data/services_repository.dart`.
  - Migration strategy: keep `services_service.dart` as a thin adapter or export until all call sites are migrated.
- Add `lib/features/services/models/service_status.dart`.
  - Migration strategy: map legacy string values in one place; reject unsupported statuses before UI rendering or writes.
- Replace `lib/features/services/view/widgets/service_card.dart` with:
  - `lib/features/services/view/widgets/service_summary_card.dart`
  - `lib/features/services/view/widgets/service_management_card.dart`
  - Migration strategy: delete the old dynamic widget after both profile and dashboard call sites are updated.

## 7) Fix Plan (Phases)

Phase 1: Critical security & correctness

1. Enforce a verified owner/status write contract.
   - What to change: remove caller authority over `freelancer_id`; replace raw string statuses with a typed status model; block unsupported statuses such as undocumented `draft` until the DB contract is verified or migrated.
   - Exact file(s) to edit/create: `lib/features/services/models/service_model.dart`, `lib/features/services/models/service_status.dart` (new), `lib/features/services/services/services_service.dart` or `lib/features/services/data/services_repository.dart` (new), `lib/features/dashboard/view/tabs/manage_tab.dart`, `lib/features/dashboard/view/widgets/manage_service_list.dart`.
   - Acceptance criteria: client writes no longer accept arbitrary owner ids; all service status reads/writes use one validated enum/value object; every UI tab uses only statuses that are supported by verified SQL or an explicit migration.
2. Fix the current rendering defect and error masking.
   - What to change: replace `dynamic` `ServiceCard` usage with a typed widget; surface loading and error states instead of collapsing failures into empty lists.
   - Exact file(s) to edit/create: `lib/features/services/view/widgets/service_card.dart` or replacement typed widgets, `lib/features/profile/view/my_services_screen.dart`, `lib/features/dashboard/view/widgets/manage_service_list.dart`, `lib/features/services/services/services_service.dart`.
   - Acceptance criteria: populated service rows render real titles/descriptions/prices; permission or parsing failures render an error state instead of `"No services found."`.
3. Verify or add `public.services` RLS before trusting direct client writes.
   - What to change: audit live SQL; if direct table writes stay client-side, add owner-only `SELECT`, `INSERT`, and `UPDATE` policies; otherwise move writes behind server-side RPC/Edge Function.
   - Exact file(s) to edit/create: `UNVERIFIED` until the missing SQL source is identified; expected location is `supabase/migrations/<timestamp>_*services*.sql`.
   - Acceptance criteria: repo contains SQL for `public.services` RLS; policy review proves that one user cannot read or mutate another user’s services.
4. Remove wrong-role startup loading.
   - What to change: stop loading service management data until the effective role is known, or reload data immediately after `_loadCachedRole()` / `_syncRoleFromBackend()` changes `_currentRole`.
   - Exact file(s) to edit/create: `lib/features/dashboard/viewmodels/dashboard_view_model.dart`.
   - Acceptance criteria: app startup never leaves stale freelancer service data in memory when the user role resolves to client.

Phase 2: Refactor/structure

1. Extract a dedicated `ServicesViewModel`.
   - What to change: move `_myServices`, service loading, status filtering, and service actions out of `DashboardViewModel`.
   - Exact file(s) to edit/create: `lib/features/services/viewmodels/services_view_model.dart` (new), `lib/features/dashboard/viewmodels/dashboard_view_model.dart`, `lib/main.dart`.
   - Acceptance criteria: service state changes no longer require edits to dashboard orchestration logic.
2. Re-home service UI under the feature.
   - What to change: move service screens/widgets out of profile/dashboard folders into `lib/features/services/view/**`.
   - Exact file(s) to edit/create: `lib/features/services/view/my_services_screen.dart` (new path), `lib/features/services/view/widgets/manage_service_list.dart` (new path), `lib/features/profile/view/profile_screen.dart`, `lib/features/dashboard/view/tabs/manage_tab.dart`.
   - Acceptance criteria: the `services` feature owns its own screens and widgets; profile/dashboard only provide entry points.
3. Remove duplicate card implementations.
   - What to change: build a typed summary card and a typed management card from a shared base contract.
   - Exact file(s) to edit/create: `lib/features/services/view/widgets/service_summary_card.dart` (new), `lib/features/services/view/widgets/service_management_card.dart` (new), delete or replace `lib/features/services/view/widgets/service_card.dart`, update `lib/features/dashboard/view/widgets/manage_service_list.dart` or moved equivalent.
   - Acceptance criteria: only one typed rendering path exists for service data.

Phase 3: Tests

1. Add model and repository tests.
   - What to change: cover nullable-row parsing, status mapping, and error propagation.
   - Exact file(s) to edit/create: `test/unit/services/service_model_test.dart` (new), `test/unit/services/services_repository_test.dart` (new).
   - Acceptance criteria: tests fail if a nullable schema-compatible row crashes parsing or if service failures are flattened into false empty states.
2. Add ViewModel and widget tests.
   - What to change: cover loading, empty, error, populated, and status-tab states.
   - Exact file(s) to edit/create: `test/unit/services/services_view_model_test.dart` (new), `test/widget/services/my_services_screen_test.dart` (new), `test/widget/services/manage_service_list_test.dart` (new).
   - Acceptance criteria: the current `ServiceCard` placeholder regression is caught by tests.
3. Add RLS contract verification.
   - What to change: add a staging/integration test or documented SQL verification for cross-user read/write denial.
   - Exact file(s) to edit/create: `UNVERIFIED` until the project’s integration-test location is identified; at minimum add documentation to `Sline_everything/DEVELOPER_GUIDE/Services Feature.md` (new).
   - Acceptance criteria: one verified test or staged SQL checklist proves owner-only access for `public.services`.

Phase 4: Polish/perf

1. Lazy-load services on feature entry.
   - What to change: fetch service data when profile/dashboard service UI opens instead of during global dashboard startup.
   - Exact file(s) to edit/create: `lib/features/services/viewmodels/services_view_model.dart` (new), `lib/features/profile/view/profile_screen.dart`, `lib/features/dashboard/view/tabs/manage_tab.dart`, `lib/main.dart`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart`.
   - Acceptance criteria: opening unrelated screens does not trigger `public.services` reads.
2. Replace fake metrics or remove them.
   - What to change: either source `activeOrdersCount` / `rating` from verified backend data or stop showing them.
   - Exact file(s) to edit/create: `lib/features/services/models/service_model.dart`, `lib/features/dashboard/view/widgets/manage_service_list.dart`, any verified SQL or repository source if added.
   - Acceptance criteria: the UI never displays placeholder metrics as real facts.
3. Finish or remove dead-end actions.
   - What to change: wire create/edit/pause actions to real flows or remove the controls until the flows exist.
   - Exact file(s) to edit/create: `lib/features/profile/view/my_services_screen.dart`, `lib/features/dashboard/view/widgets/manage_service_list.dart`, new create/edit screens if implemented.
   - Acceptance criteria: every visible service action either works end-to-end or is intentionally absent.

## 8) Verification Checklist

### Commands

- `flutter analyze`
- `flutter test test/unit/services`
- `flutter test test/widget/services`
- `rg -n "from\\('services'\\)|from\\(\"services\"\\)" lib --glob '*.dart'`
  - Expectation: service table access is centralized in the service repository layer.
- `rg -n "context\\.watch<DashboardViewModel>" lib/features/services lib/features/profile/view lib/features/dashboard/view --glob '*.dart'`
  - Expectation: service screens no longer watch the global dashboard VM directly.
- `rg -n "\"draft\"|'draft'|status == 'active'|status == \\\"active\\\"" lib/features/services lib/features/dashboard --glob '*.dart'`
  - Expectation: raw status strings are replaced with typed status mapping or one centralized adapter.
- `rg -n "createService\\(|updateStatus\\(" lib --glob '*.dart'`
  - Expectation: every remaining write API has a verified caller or is removed.

### Manual Scenarios

- Profile entry:
  - Open Profile.
  - Tap `My Services`.
  - Verify real service titles/descriptions/prices render instead of placeholders. File References: `lib/features/profile/view/profile_screen.dart:412-425`, `lib/features/profile/view/my_services_screen.dart:51-64`.
- Dashboard manage entry:
  - Open freelancer Manage tab.
  - Switch between service tabs.
  - Verify only supported statuses appear and no undocumented status is required. File Reference: `lib/features/dashboard/view/tabs/manage_tab.dart:64-72`.
- Failure handling:
  - Force a network error or permission failure on `public.services`.
  - Verify the UI shows an error state, not `No services found.`. File References: `lib/features/services/services/services_service.dart:20-22`, `lib/features/profile/view/my_services_screen.dart:31-50`.
- Role resolution:
  - Start the app with a client-role account.
  - Verify the app does not pre-load freelancer service data and that role changes trigger a data reload if needed. File References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:47-51`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:286-316`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-418`.
- Placeholder metrics:
  - Open the dashboard service list.
  - Verify `Active` count and `rating` are either backed by real data or not shown. File References: `lib/features/services/models/service_model.dart:42-44`, `lib/features/dashboard/view/widgets/manage_service_list.dart:79-88`.

### Supabase/RLS Contract Checks

- `UNVERIFIED` repo-local SQL requirement:
  - The repo must contain a migration or SQL doc that defines `public.services` `SELECT`, `INSERT`, and `UPDATE` policies. Missing files today: any `supabase/migrations/*services*.sql` policy definition or equivalent SQL documentation.
- Required policy behavior:
  - `SELECT` must restrict service reads to the intended audience; owner-only is the current safe assumption because all current UI surfaces are owner-management views. File References: `lib/features/services/services/services_service.dart:11-17`, `lib/features/profile/view/my_services_screen.dart:13-73`, `lib/features/dashboard/view/widgets/manage_service_list.dart:9-136`.
  - `INSERT` must enforce `freelancer_id = auth.uid()` if direct client inserts remain. File References: `lib/features/services/services/services_service.dart:26-32`, `lib/features/services/models/service_model.dart:48-57`.
  - `UPDATE` must enforce owner-only row access and allowed status transitions. File Reference: `lib/features/services/services/services_service.dart:41-46`.
- Validation method:
  - Review the live SQL migration or policy file once it exists in repo.
  - Run a staged cross-user read/write test: user A creates a service, user B attempts read/update through the same client path, and both operations must fail.

## 9) Risks & Rollback Notes

- Risk:
  - Extracting service state from `DashboardViewModel` can break both the profile service screen and the dashboard manage tab because both currently depend on `vm.myServices`. File References: `lib/features/profile/view/my_services_screen.dart:16-17`, `lib/features/dashboard/view/widgets/manage_service_list.dart:16-17`.
- Risk:
  - Removing raw `draft` handling can hide existing rows if the live database already stores that value. File References: `lib/features/services/models/service_model.dart:8`, `lib/features/dashboard/view/tabs/manage_tab.dart:69-71`, `Sline_everything/SUPABASE_SETUP.md:874`. Live row values are `UNVERIFIED`.
- Risk:
  - Changing direct client writes to server-side RPC or stricter RLS can break any future caller that depends on the current loose write API. File Reference: `lib/features/services/services/services_service.dart:26-46`.
- Rollback steps:
  - Keep temporary wrapper/export files at the old screen/widget paths until all imports compile against the new `services` feature ownership.
  - Keep a compatibility adapter in `DashboardViewModel` while the new `ServicesViewModel` is phased in.
  - Roll back any `public.services` SQL migration with an explicit down migration if policy or status-contract changes block legitimate owner access.
