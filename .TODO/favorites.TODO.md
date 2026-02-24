# favorites — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does:
  - Manages client favorites (add/list/remove favorite freelancers) via `FavoritesService` and `FavoritesViewModel`. File Reference: `lib/features/favorites/data/favorites_service.dart:21-107`, `lib/features/favorites/viewmodels/favorites_view_model.dart:13-111`.
  - Renders a favorites list UI and starts a DM from a selected favorite. File Reference: `lib/features/favorites/view/favorites_screen.dart:44-138`, `lib/features/favorites/view/widgets/favorite_card.dart:6-69`.
- Boundaries (in scope):
  - All files under `lib/features/favorites/**`. File Reference: `lib/features/favorites/data/favorites_service.dart:1-108`, `lib/features/favorites/models/favorite_model.dart:1-74`, `lib/features/favorites/viewmodels/favorites_view_model.dart:1-111`, `lib/features/favorites/view/favorites_screen.dart:1-138`, `lib/features/favorites/view/widgets/favorite_card.dart:1-69`, `lib/features/favorites/routes/favorites_routes.dart:1-14`.
  - Direct touchpoints that call/read favorites state or route to favorites. File Reference: `lib/main.dart:160-163`, `lib/main.dart:231-238`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:19-21`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:265-276`, `lib/features/profile/view/public_profile_screen.dart:138-165`.
  - Direct chat dependency used by favorites “Start Chat”. File Reference: `lib/features/favorites/view/favorites_screen.dart:91-121`, `lib/features/chat/viewmodels/chat_view_model.dart:58-60`, `lib/features/chat/viewmodels/chat_view_model.dart:138-149`, `lib/features/chat/data/chat_repository.dart:26-34`, `lib/features/chat/services/message_service.dart:18-87`.
- Boundaries (out of scope for this audit):
  - Chat message sending, notifications, and message realtime behavior after conversation creation (favorites screen only creates/gets a conversation then navigates). File Reference: `lib/features/favorites/view/favorites_screen.dart:91-121`, `lib/features/chat/services/message_service.dart:247-427`.
  - DB implementation details not present in versioned SQL in this repo are `UNVERIFIED` and called out explicitly. UNVERIFIED (missing favorites DDL/RLS migration files under `supabase/migrations/`).
- Entry points (screens/routes/calls):
  - Named route registration for favorites. File Reference: `lib/main.dart:231-238`, `lib/features/favorites/routes/favorites_routes.dart:4-13`.
  - Favorites screen local screen state creation (current implementation). File Reference: `lib/features/favorites/view/favorites_screen.dart:19-40`.
  - Public profile favorite toggle. File Reference: `lib/features/profile/view/public_profile_screen.dart:138-165`.
  - Task request tile “Add to favorites” action. File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:51-56`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:265-276`.

## 1) Feature Map (Current Repo State)
- Primary feature files (with references):
  - `lib/features/favorites/data/favorites_service.dart` — Supabase CRUD for `favorites`, auth check (`_requireUid`). File Reference: `lib/features/favorites/data/favorites_service.dart:6-108`.
  - `lib/features/favorites/models/favorite_model.dart` — `FavoriteModel` and `FavoriteWithProfile` parsing. File Reference: `lib/features/favorites/models/favorite_model.dart:4-74`.
  - `lib/features/favorites/viewmodels/favorites_view_model.dart` — state, load/add/remove, error mapping. File Reference: `lib/features/favorites/viewmodels/favorites_view_model.dart:13-111`.
  - `lib/features/favorites/view/favorites_screen.dart` — screen UI, local VM provider, DM start, remove snackbar. File Reference: `lib/features/favorites/view/favorites_screen.dart:12-138`.
  - `lib/features/favorites/view/widgets/favorite_card.dart` — list row UI. File Reference: `lib/features/favorites/view/widgets/favorite_card.dart:6-69`.
  - `lib/features/favorites/routes/favorites_routes.dart` — route constant + helper. File Reference: `lib/features/favorites/routes/favorites_routes.dart:4-13`.
- Direct dependencies (with references):
  - Global provider and route registration in app shell. File Reference: `lib/main.dart:160-163`, `lib/main.dart:231-238`.
  - Public profile consumes `FavoritesViewModel` and toggles add/remove. File Reference: `lib/features/profile/view/public_profile_screen.dart:138-165`.
  - Task request UI optionally accepts `FavoritesViewModel`, but has direct service fallback. File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:19-21`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129`.
  - Request list callsite does not pass `favoritesVM` (activates fallback path). File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:265-276`.
  - Favorites “Start Chat” depends on `ChatViewModel` -> `ChatRepository` -> `MessageService`. File Reference: `lib/features/favorites/view/favorites_screen.dart:91-121`, `lib/features/chat/viewmodels/chat_view_model.dart:138-149`, `lib/features/chat/data/chat_repository.dart:26-34`, `lib/features/chat/services/message_service.dart:18-87`.
- Supabase touchpoints (tables/RPC/storage/realtime) (with references to code or SQL docs):
  - `favorites` table (SELECT/INSERT/DELETE) in client service. File Reference: `lib/features/favorites/data/favorites_service.dart:25-29`, `lib/features/favorites/data/favorites_service.dart:50-56`, `lib/features/favorites/data/favorites_service.dart:74-77`, `lib/features/favorites/data/favorites_service.dart:93-97`.
  - `conversations` table (DM create/get path used by favorites “Start Chat” when `taskId: null`). File Reference: `lib/features/favorites/view/favorites_screen.dart:105-109`, `lib/features/chat/services/message_service.dart:46-87`.
  - `start_task_conversation_v1` RPC exists in shared chat service, but favorites screen passes `taskId: null` so this RPC is not used in the favorites DM path. File Reference: `lib/features/favorites/view/favorites_screen.dart:105-109`, `lib/features/chat/services/message_service.dart:28-44`.
  - RLS/schema expectations for `favorites` are documented (docs, not source-controlled SQL in `supabase/migrations`). File Reference: `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:13-34`, `Sline_everything/SUPABASE_SETUP.md:1119-1125`; UNVERIFIED (missing favorites DDL/RLS migration SQL in `supabase/migrations/`).
  - Storage buckets / realtime channels / edge functions directly referenced by favorites feature path: none observed in audited client files. File Reference: `lib/features/favorites/data/favorites_service.dart:1-108`, `lib/features/favorites/view/favorites_screen.dart:1-138`; UNVERIFIED for backend-only indirect usage.

## 2) Evidence Index (Ground Truth)

| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
|---|---|---|---|---|
| FAV-SEC-01 | Favorites RLS/schema contract is documented but not verifiable from versioned SQL in this repo | `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:13-34`, `Sline_everything/SUPABASE_SETUP.md:1119-1125`; `UNVERIFIED` (missing favorites SQL migration files under `supabase/migrations/`) | High | RLS source-of-truth not available in repo SQL files |
| FAV-SEC-02 | DM authorization rule is inconsistent across docs/code comments | `lib/features/chat/services/message_service.dart:429-444`, `Sline_everything/SUPABASE_SETUP.md:81-83`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:32-34`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:152-153` | High | Cannot confirm intended policy behavior |
| FAV-SEC-03 | Raw backend error text is shown to users on chat start failure | `lib/features/favorites/view/favorites_screen.dart:116-120` | Medium | Information disclosure risk |
| FAV-INT-01 | Joined profile parsing can crash when joined `freelancer` row is null/missing | `lib/features/favorites/models/favorite_model.dart:65-73`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:145-150` | Critical | Docs explicitly expect missing-profile handling |
| FAV-INT-02 | Favorites state is split between global provider and local screen-owned provider | `lib/main.dart:160-163`, `lib/features/favorites/view/favorites_screen.dart:19-40` | High | State fragmentation / stale UI |
| FAV-INT-03 | Public profile favorite icon reads global VM cache without guaranteed load in same path | `lib/features/profile/view/public_profile_screen.dart:138-165`, `lib/features/favorites/view/favorites_screen.dart:23-27`, `lib/main.dart:160-163` | High | Can misrender existing favorites / trigger duplicate add |
| FAV-INT-04 | Remove failure can still show success snackbar in Favorites screen | `lib/features/favorites/viewmodels/favorites_view_model.dart:68-85`, `lib/features/favorites/view/favorites_screen.dart:123-129` | High | False success / server state mismatch |
| FAV-INT-05 | Public profile toggle does not await add/remove or surface errors | `lib/features/profile/view/public_profile_screen.dart:153-163`, `lib/features/favorites/viewmodels/favorites_view_model.dart:52-66`, `lib/features/favorites/viewmodels/favorites_view_model.dart:68-85` | Medium | Silent failure / double-tap races |
| FAV-ARC-01 | `RequestTile` performs direct `FavoritesService` call (view-to-service boundary leak) | `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:3-5`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129` | High | MVVM violation |
| FAV-ARC-02 | `RequestTile` fallback path is the active path in current callsite (no `favoritesVM` passed) | `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:265-276`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:98-119` | High | Legacy path is live behavior |
| FAV-ARC-03 | Favorites screen constructs its own service/VM instead of using DI-provided global VM | `lib/features/favorites/view/favorites_screen.dart:23-27`, `lib/main.dart:160-163` | Medium | Improper DI / duplicate lifecycle |
| FAV-QLT-01 | Duplicate favorites error mapping logic exists in VM and request tile | `lib/features/favorites/viewmodels/favorites_view_model.dart:98-110`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:122-127` | Medium | Message drift risk |
| FAV-QLT-02 | `FavoriteModel.toMap()` is a dead-code candidate | `lib/features/favorites/models/favorite_model.dart:39-48` | Low | Candidate only; confirm via usage search |
| FAV-QLT-03 | `FavoritesRoutes.route()` is a dead-code candidate; only route name is used | `lib/features/favorites/routes/favorites_routes.dart:8-13`, `lib/main.dart:237-237` | Low | Candidate only |
| FAV-PERF-01 | `load()` performs two sequential favorites queries | `lib/features/favorites/viewmodels/favorites_view_model.dart:28-37`, `lib/features/favorites/data/favorites_service.dart:21-68` | High | Extra latency / failure surface |
| FAV-PERF-02 | `add()` does insert + full reload (3 requests total in current flow) | `lib/features/favorites/viewmodels/favorites_view_model.dart:52-57`, `lib/features/favorites/data/favorites_service.dart:21-77` | High | Slow add action / redundant reads |
| FAV-PERF-03 | ViewModel always notifies on `_setLoading`/`_setError`, increasing rebuild churn | `lib/features/favorites/viewmodels/favorites_view_model.dart:88-96`, `lib/features/favorites/view/favorites_screen.dart:47-57` | Low | Small but avoidable rebuilds |
| FAV-PERF-04 | Favorite card displays raw `DateTime` string instead of local formatter recommended in docs | `lib/features/favorites/view/widgets/favorite_card.dart:47-50`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:153-155` | Low | UX polish + formatting consistency issue |
| FAV-TST-01 | No favorites-specific unit/widget/integration test files were found in current repo scan | `UNVERIFIED` (absence claim from `rg --files test integration_test | rg 'favorite|favorites'`) | High | Missing coverage for critical flows |

## 3) Findings
### 3.1 Security (Highest Priority)
- `FAV-SEC-01` — Favorites authorization (RLS) contract is doc-backed but not verifiable from versioned SQL in this repo.
  - File Reference: `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:13-34`, `Sline_everything/SUPABASE_SETUP.md:1119-1125`; `UNVERIFIED` (missing favorites DDL/RLS migrations in `supabase/migrations/`).
  - Impact: RLS is the source of truth, but current repo state does not provide the source-controlled SQL needed to verify that `favorites` policies in runtime DB match the documented rules.
  - Exploit/Failure scenario: A drifted DB policy (e.g., broader `SELECT` or broken `DELETE`) would not be caught by repo review and could expose or allow modification of another user’s favorites.
- `FAV-SEC-02` — DM authorization rule tied to favorites is internally inconsistent across code comments and docs.
  - File Reference: `lib/features/chat/services/message_service.dart:429-444`, `Sline_everything/SUPABASE_SETUP.md:81-83`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:32-34`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:152-153`.
  - Impact: The team cannot reliably validate authz behavior for favorites-triggered DM creation because the intended rule is contradictory.
  - Exploit/Failure scenario: Tests and UI behavior may approve one rule (favorites required) while DB enforces another (favorites not required), creating false confidence and production authorization surprises.
- `FAV-SEC-03` — Raw backend exception text is shown in Favorites screen chat-start failure snackbar.
  - File Reference: `lib/features/favorites/view/favorites_screen.dart:116-120`.
  - Impact: Postgrest/RPC/internal errors can leak schema or policy details to end users.
  - Exploit/Failure scenario: A failed conversation insert exposes backend error strings (table names, policy hints, SQL error text) directly in UI copy.

### 3.2 Data Integrity
- `FAV-INT-01` — Joined profile parsing crashes when the joined `freelancer` object is absent.
  - File Reference: `lib/features/favorites/models/favorite_model.dart:65-73`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:145-150`.
  - Impact: One malformed/missing join row can fail the entire favorites list load.
  - Exploit/Failure scenario: A favorited profile is deleted/hidden or filtered by RLS; `freelancer` becomes `null`; `null as String` throws; favorites screen falls into error state instead of rendering placeholders.
- `FAV-INT-02` — Favorites state is split between the global provider and a local favorites-screen provider.
  - File Reference: `lib/main.dart:160-163`, `lib/features/favorites/view/favorites_screen.dart:19-40`.
  - Impact: Different screens can read/write different in-memory favorites states.
  - Exploit/Failure scenario: User removes a favorite in Favorites screen (local VM), then returns to Public Profile and still sees the old favorite icon state (global VM cache stale).
- `FAV-INT-03` — Public profile favorite icon relies on `favoritesVm.items` without a guaranteed load in that interaction path.
  - File Reference: `lib/features/profile/view/public_profile_screen.dart:138-165`, `lib/features/favorites/view/favorites_screen.dart:23-27`, `lib/main.dart:160-163`.
  - Impact: UI may misidentify existing favorites and call the wrong action.
  - Exploit/Failure scenario: Existing favorite appears unfilled because the global favorites VM has not loaded yet; tapping sends an `add`, producing duplicate violation (`23505`) instead of removing.
- `FAV-INT-04` — Favorites screen always shows remove success snackbar even if `remove()` failed.
  - File Reference: `lib/features/favorites/viewmodels/favorites_view_model.dart:68-85`, `lib/features/favorites/view/favorites_screen.dart:123-129`.
  - Impact: UI can claim success while server state remains unchanged.
  - Exploit/Failure scenario: Network/RLS/delete failure is caught in VM and stored in `error`; screen still shows “Removed from favorites”, misleading user and hiding failure.
- `FAV-INT-05` — Public profile favorite toggle does not await add/remove and does not surface failures.
  - File Reference: `lib/features/profile/view/public_profile_screen.dart:153-163`, `lib/features/favorites/viewmodels/favorites_view_model.dart:52-66`, `lib/features/favorites/viewmodels/favorites_view_model.dart:68-85`.
  - Impact: Silent failures and race conditions are more likely.
  - Exploit/Failure scenario: User taps rapidly; multiple async calls overlap; duplicate inserts or remove-after-add sequencing occurs with no explicit user feedback.

### 3.3 Architecture
- `FAV-ARC-01` — `RequestTile` directly imports and calls `FavoritesService` (view -> service boundary leak).
  - File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:3-5`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129`.
  - Impact: Breaks MVVM layering and duplicates favorites behavior outside the feature ViewModel.
  - Exploit/Failure scenario: Error mapping and state updates diverge between `RequestTile` and `FavoritesViewModel`, causing inconsistent UX and harder testing.
- `FAV-ARC-02` — The direct-service fallback is the active runtime path in the current offers list callsite.
  - File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:265-276`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:98-119`.
  - Impact: The architecture violation is not dead code; it is current behavior.
  - Exploit/Failure scenario: Offers list add-to-favorites bypasses centralized VM error handling and shared state updates, causing stale favorites state elsewhere.
- `FAV-ARC-03` — Favorites screen constructs its own `FavoritesService` and `FavoritesViewModel` instead of using the app-level provider.
  - File Reference: `lib/features/favorites/view/favorites_screen.dart:23-27`, `lib/features/favorites/view/favorites_screen.dart:37-40`, `lib/main.dart:160-163`.
  - Impact: Duplicate lifecycle ownership and inconsistent dependency injection.
  - Exploit/Failure scenario: Global provider and local provider diverge on load timing and cached items; profile/task screens observe different state than Favorites screen.
- `FAV-ARC-04` — Favorites view directly imports `ChatScreen`, coupling feature UI to another feature’s concrete screen.
  - File Reference: `lib/features/favorites/view/favorites_screen.dart:7-8`, `lib/features/favorites/view/favorites_screen.dart:111-115`.
  - Impact: Increases cross-feature coupling and refactor cost.
  - Exploit/Failure scenario: Chat route/screen refactor requires direct updates in favorites UI instead of an abstract route/navigation API.

### 3.4 Code Quality
- `FAV-QLT-01` — Favorites error mapping logic is duplicated across files.
  - File Reference: `lib/features/favorites/viewmodels/favorites_view_model.dart:98-110`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:122-127`.
  - Impact: Message drift and inconsistent behavior across entry points.
  - Exploit/Failure scenario: One path updates messages for `23505`/RLS/auth while the other path keeps older logic, producing conflicting UX copy.
- `FAV-QLT-02` — `FavoriteModel.toMap()` is an unused API candidate.
  - File Reference: `lib/features/favorites/models/favorite_model.dart:39-48`.
  - Impact: Extra API surface without a verified caller increases maintenance noise.
  - Exploit/Failure scenario: Future changes maintain an unused serializer incorrectly, creating confusion without test coverage.
- `FAV-QLT-03` — `FavoritesRoutes.route()` is an unused route helper candidate.
  - File Reference: `lib/features/favorites/routes/favorites_routes.dart:8-13`, `lib/main.dart:237-237`.
  - Impact: Dead helper path duplicates route construction behavior.
  - Exploit/Failure scenario: A future route change updates only `routeName` registration or only `route()` helper, leaving inconsistent route behavior if helper becomes used later.
- `FAV-QLT-04` — Favorites screen remove success/error handling is split between screen and VM without a clear success contract.
  - File Reference: `lib/features/favorites/viewmodels/favorites_view_model.dart:68-85`, `lib/features/favorites/view/favorites_screen.dart:123-129`.
  - Impact: Weak method contract makes caller behavior error-prone.
  - Exploit/Failure scenario: Callers assume `await vm.remove()` implies success, but VM swallows failures and sets `error` side-channel only.

### 3.5 Performance
- `FAV-PERF-01` — Favorites load performs two sequential Supabase reads for the same logical list.
  - File Reference: `lib/features/favorites/viewmodels/favorites_view_model.dart:28-37`, `lib/features/favorites/data/favorites_service.dart:21-68`.
  - Impact: Added latency, redundant network work, and larger failure surface.
  - Exploit/Failure scenario: First query succeeds and second fails; user gets error despite having enough data for a partial list.
- `FAV-PERF-02` — Add favorite triggers insert plus full reload, resulting in redundant calls.
  - File Reference: `lib/features/favorites/viewmodels/favorites_view_model.dart:52-57`, `lib/features/favorites/data/favorites_service.dart:21-77`.
  - Impact: Slow add interaction and unnecessary DB traffic.
  - Exploit/Failure scenario: On poor networks, add feels slow because insert waits for two subsequent reads before UI updates.
- `FAV-PERF-03` — `notifyListeners()` is called on `_setLoading`/`_setError` even when value is unchanged.
  - File Reference: `lib/features/favorites/viewmodels/favorites_view_model.dart:88-96`, `lib/features/favorites/view/favorites_screen.dart:47-57`.
  - Impact: Extra rebuilds for the entire `FavoritesScreen` body watcher.
  - Exploit/Failure scenario: Repeated refreshes or error clears trigger unnecessary rebuilds, increasing UI churn.
- `FAV-PERF-04` — Favorite timestamp is rendered as raw `DateTime`, violating documented local formatting guidance.
  - File Reference: `lib/features/favorites/view/widgets/favorite_card.dart:47-50`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:153-155`.
  - Impact: UX inconsistency and harder-to-read timestamps (not a compute bottleneck).
  - Exploit/Failure scenario: Users see UTC/raw object formatting instead of localized date text used elsewhere in the app.

### 3.6 Testing Gaps
- `FAV-TST-01` — No favorites-specific test files were found in `test/` or `integration_test/` by name scan.
  - File Reference: `UNVERIFIED` (absence claim from repository file scan `rg --files test integration_test | rg 'favorite|favorites'`).
  - Impact: Critical favorites flows have no explicit regression safety net.
  - Exploit/Failure scenario: Provider unification, parser changes, or error-handling fixes regress behavior without failing CI.
- Missing unit tests for favorites parser and VM state transitions.
  - File Reference (feature code requiring tests): `lib/features/favorites/models/favorite_model.dart:65-73`, `lib/features/favorites/viewmodels/favorites_view_model.dart:28-110`.
  - Impact: Crash and side-effect bugs are easy to reintroduce.
  - Failure scenario: Null join parsing and duplicate add/remove flows regress silently.
- Missing widget tests for Favorites screen state branches and failure UX.
  - File Reference (feature UI branches): `lib/features/favorites/view/favorites_screen.dart:57-133`.
  - Impact: Loading/error/empty/list/remove/chat-failure behaviors are unverified.
  - Failure scenario: False-success snackbars or raw error leakage returns after refactor.
- Missing integration coverage for cross-screen favorites consistency.
  - File Reference (cross-feature touchpoints): `lib/features/profile/view/public_profile_screen.dart:138-165`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129`, `lib/features/favorites/view/favorites_screen.dart:91-129`.
  - Impact: Shared-state regressions are likely during provider refactor.
  - Failure scenario: Add/remove works in one screen but not another due provider fragmentation.

## 4) Dead/Unused Code Candidates
- Candidate: `FavoriteModel.toMap()` may be unused.
  - File Reference: `lib/features/favorites/models/favorite_model.dart:39-48`.
  - Why candidate: No caller was identified during this audit’s feature/direct-dependency review.
  - How to confirm: Run repo-wide usage search for `toMap()` on `FavoriteModel` and remove only if no serialization path/tests depend on it. `UNVERIFIED` until repo-wide confirmation.
- Candidate: `FavoritesRoutes.route()` may be unused.
  - File Reference: `lib/features/favorites/routes/favorites_routes.dart:8-13`, `lib/main.dart:237-237`.
  - Why candidate: Current route registration uses `FavoritesRoutes.routeName` with inline builder, not `FavoritesRoutes.route()`.
  - How to confirm: Run repo-wide search for `FavoritesRoutes.route(` before removal. `UNVERIFIED` until repo-wide confirmation.

## 5) Duplicate Code Candidates
- Duplicate error mapping for favorites add errors.
  - File Reference: `lib/features/favorites/viewmodels/favorites_view_model.dart:98-110`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:122-127`.
  - Proposed shared abstraction: `lib/features/favorites/utils/favorites_error_mapper.dart` with a single `String humanizeFavoritesError(Object error)` function.
- Duplicate provider/service construction for favorites state.
  - File Reference: `lib/main.dart:160-163`, `lib/features/favorites/view/favorites_screen.dart:23-27`.
  - Proposed shared abstraction: single app-level `FavoritesViewModel` provider; favorites screen should consume existing provider instead of constructing a new VM.
- Duplicate query shape (same table/filter/order) across list methods.
  - File Reference: `lib/features/favorites/data/favorites_service.dart:25-29`, `lib/features/favorites/data/favorites_service.dart:50-56`.
  - Proposed shared abstraction: a single base query helper or a single joined list method with derivation logic in VM.

## 6) Refactor Plan (Exact Paths)
- Split joined-row model parsing from base model file.
  - Move `FavoriteWithProfile` out of `lib/features/favorites/models/favorite_model.dart`.
  - Create `lib/features/favorites/models/favorite_with_profile_model.dart`.
  - Keep `FavoriteModel` in `lib/features/favorites/models/favorite_model.dart`.
  - Migration strategy: update imports in `FavoritesViewModel`, `FavoriteCard`, and any future consumers in one patch; no compatibility wrapper needed because only local feature files currently import this model file. File Reference: `lib/features/favorites/models/favorite_model.dart:51-74`, `lib/features/favorites/viewmodels/favorites_view_model.dart:10-11`, `lib/features/favorites/view/widgets/favorite_card.dart:1-2`.
- Extract favorites error mapping to a shared utility.
  - Create `lib/features/favorites/utils/favorites_error_mapper.dart`.
  - Edit `lib/features/favorites/viewmodels/favorites_view_model.dart` to use the shared mapper.
  - Edit `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` to use the shared mapper (temporary until callback refactor lands).
  - Migration strategy: keep function signature simple (`Object -> String`) to avoid circular dependencies. File Reference: `lib/features/favorites/viewmodels/favorites_view_model.dart:98-110`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:120-127`.
- Split favorites screen rendering and action orchestration.
  - Keep `lib/features/favorites/view/favorites_screen.dart` as route/screen shell only.
  - Create `lib/features/favorites/view/widgets/favorites_list_body.dart` for loading/error/empty/list branches.
  - Create `lib/features/favorites/view/widgets/favorite_actions.dart` (or `favorites_snackbar_actions.dart`) to centralize chat-start/remove snackbar handling.
  - Migration strategy: first extract widgets without behavior changes, then refactor provider usage. File Reference: `lib/features/favorites/view/favorites_screen.dart:44-138`.
- Remove view-layer direct favorites service access in tasks request tile.
  - Edit `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` to remove `FavoritesService` import and fallback.
  - Edit `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` to pass a callback or `FavoritesViewModel` explicitly.
  - Optional create `lib/features/tasks/view/widgets/requests/actions/request_tile_favorites_action.dart` only if multiple request widgets need the same action.
  - Migration strategy: introduce callback parameter (`Future<void> Function(String bidderId)? onAddFavorite`) and deprecate `favoritesVM` field in the same patch. File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:3-5`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:19-21`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:265-276`.
- Clean route helper dead code.
  - Option A (preferred): keep `lib/features/favorites/routes/favorites_routes.dart`, remove unused `route()` method.
  - Option B: remove route helper file entirely and inline `routeName` constant in a feature barrel (only if team prefers).
  - Migration strategy: confirm repo-wide usage first; remove in same patch as route cleanup. File Reference: `lib/features/favorites/routes/favorites_routes.dart:4-13`, `lib/main.dart:237-237`.

## 7) Fix Plan (Phases)
- Phase 1: Critical security & correctness
  - Item 1: Fix null join parsing crash and preserve `freelancer_id` fallback.
    - What to change: Update favorites joined select to include top-level `freelancer_id`, and change `FavoriteWithProfile.fromMap` to tolerate `freelancer == null` while still parsing `freelancerId` from root row.
    - Exact file(s) to edit/create: `lib/features/favorites/data/favorites_service.dart`, `lib/features/favorites/models/favorite_model.dart` (or new `lib/features/favorites/models/favorite_with_profile_model.dart` if split first).
    - Acceptance criteria: Favorites list renders even when a joined freelancer profile is missing; no `null as String` crash; placeholder UI remains functional for remove/chat actions. File Reference (current bug): `lib/features/favorites/models/favorite_model.dart:65-73`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:145-150`.
  - Item 2: Remove false-success delete UX and define explicit success contract.
    - What to change: Make `FavoritesViewModel.remove()` return success/failure (or rethrow) and update `FavoritesScreen` to show success snackbar only on success; show mapped error otherwise.
    - Exact file(s) to edit/create: `lib/features/favorites/viewmodels/favorites_view_model.dart`, `lib/features/favorites/view/favorites_screen.dart`.
    - Acceptance criteria: Delete failures no longer show success snackbar; UI and server state remain aligned. File Reference (current bug): `lib/features/favorites/viewmodels/favorites_view_model.dart:68-85`, `lib/features/favorites/view/favorites_screen.dart:123-129`.
  - Item 3: Sanitize chat-start error messages shown to users.
    - What to change: Replace `'$e'` snackbar text with generic user-safe copy and log details via logger only.
    - Exact file(s) to edit/create: `lib/features/favorites/view/favorites_screen.dart` (and optional shared mapper utility if reused).
    - Acceptance criteria: User sees English-only generic error text; backend exception details are not shown in UI. File Reference (current bug): `lib/features/favorites/view/favorites_screen.dart:116-120`.
  - Item 4: Resolve favorites/DM authz rule documentation mismatch (repo documentation contract).
    - What to change: Align comments/docs to the actual DB behavior and mark DB rule as verified only after DB-side validation.
    - Exact file(s) to edit/create: `lib/features/chat/services/message_service.dart`, `Sline_everything/SUPABASE_SETUP.md`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md`.
    - Acceptance criteria: Code comments and docs state one consistent DM rule; any remaining uncertainty is marked `UNVERIFIED` until DB validation is completed. File Reference (current mismatch): `lib/features/chat/services/message_service.dart:429-444`, `Sline_everything/SUPABASE_SETUP.md:81-83`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:32-34`.
- Phase 2: Refactor/structure
  - Item 1: Unify favorites provider ownership and remove local VM duplication.
    - What to change: `FavoritesScreen` should consume the app-level `FavoritesViewModel` instead of constructing a local VM; add an `ensureLoaded()`-style method or equivalent lazy load guard in VM.
    - Exact file(s) to edit/create: `lib/features/favorites/view/favorites_screen.dart`, `lib/features/favorites/viewmodels/favorites_view_model.dart`, (possibly `lib/main.dart` if load timing is centralized).
    - Acceptance criteria: One `FavoritesViewModel` instance is used across favorites/profile/tasks screens; cross-screen favorite state stays consistent. File Reference (current split state): `lib/main.dart:160-163`, `lib/features/favorites/view/favorites_screen.dart:19-40`, `lib/features/profile/view/public_profile_screen.dart:138-165`.
  - Item 2: Remove view->service direct access from task request tile.
    - What to change: Replace `FavoritesService` fallback in `RequestTile` with a callback or required VM injection from parent.
    - Exact file(s) to edit/create: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart`.
    - Acceptance criteria: `RequestTile` no longer imports `FavoritesService`; add-to-favorites still works in offers list and updates shared favorites state. File Reference (current violation): `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:3-5`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:265-276`.
  - Item 3: Extract shared favorites error mapper and clear API contracts.
    - What to change: Centralize favorites error message mapping and remove duplicated inline parsing logic.
    - Exact file(s) to edit/create: `lib/features/favorites/utils/favorites_error_mapper.dart` (new), `lib/features/favorites/viewmodels/favorites_view_model.dart`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart`.
    - Acceptance criteria: One mapping source is used by favorites feature and request-tile entry point; message text matches across flows. File Reference (current duplication): `lib/features/favorites/viewmodels/favorites_view_model.dart:98-110`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:122-127`.
  - Item 4: Split models/screen widgets for maintainability.
    - What to change: Split `FavoriteWithProfile` model and extract favorites list body widget(s) from `favorites_screen.dart`.
    - Exact file(s) to edit/create: `lib/features/favorites/models/favorite_with_profile_model.dart` (new), `lib/features/favorites/models/favorite_model.dart`, `lib/features/favorites/view/widgets/favorites_list_body.dart` (new), `lib/features/favorites/view/favorites_screen.dart`.
    - Acceptance criteria: Smaller files with unchanged runtime behavior before Phase 3 tests are added. File Reference (current mixed responsibilities): `lib/features/favorites/models/favorite_model.dart:4-74`, `lib/features/favorites/view/favorites_screen.dart:44-138`.
- Phase 3: Tests
  - Item 1: Add unit tests for parser and VM behavior.
    - What to change: Add tests for null join parsing, duplicate add error mapping, remove failure behavior, and load state transitions.
    - Exact file(s) to edit/create: `test/features/favorites/models/favorite_with_profile_model_test.dart` (new), `test/features/favorites/viewmodels/favorites_view_model_test.dart` (new).
    - Acceptance criteria: Tests fail on current bugs (before fixes) and pass after fixes; null join case is explicitly covered. File Reference (targets): `lib/features/favorites/models/favorite_model.dart:65-73`, `lib/features/favorites/viewmodels/favorites_view_model.dart:28-110`.
  - Item 2: Add widget tests for favorites screen UX states.
    - What to change: Test loading/error/empty/list branches and remove/chat failure snackbars.
    - Exact file(s) to edit/create: `test/features/favorites/view/favorites_screen_test.dart` (new), `test/features/favorites/view/widgets/favorite_card_test.dart` (new).
    - Acceptance criteria: Screen state branches and user-visible error copy are verified; raw backend error text is not present in UI output. File Reference (targets): `lib/features/favorites/view/favorites_screen.dart:57-133`, `lib/features/favorites/view/widgets/favorite_card.dart:40-50`.
  - Item 3: Add integration coverage for cross-screen favorites consistency.
    - What to change: Add flow tests covering add/remove from profile and task request entry points with shared provider state.
    - Exact file(s) to edit/create: `integration_test/favorites_cross_feature_flow_test.dart` (new) or equivalent feature-scoped files.
    - Acceptance criteria: Favorites state changes in one screen are reflected in other consumers without app restart. File Reference (targets): `lib/features/profile/view/public_profile_screen.dart:138-165`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129`, `lib/features/favorites/view/favorites_screen.dart:91-129`.
- Phase 4: Polish/perf
  - Item 1: Reduce favorites load/add network calls.
    - What to change: Replace dual-query load with a single joined query (or derive simple list from joined response), and avoid full reload after add when safe.
    - Exact file(s) to edit/create: `lib/features/favorites/data/favorites_service.dart`, `lib/features/favorites/viewmodels/favorites_view_model.dart`.
    - Acceptance criteria: `load()` performs one read; add action avoids unnecessary second/third requests while preserving correctness. File Reference (current redundancy): `lib/features/favorites/viewmodels/favorites_view_model.dart:28-37`, `lib/features/favorites/viewmodels/favorites_view_model.dart:52-57`, `lib/features/favorites/data/favorites_service.dart:21-68`.
  - Item 2: Add in-flight guards for favorite toggles.
    - What to change: Track per-item or global pending favorite action state and disable repeated taps until completion.
    - Exact file(s) to edit/create: `lib/features/favorites/viewmodels/favorites_view_model.dart`, `lib/features/profile/view/public_profile_screen.dart`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart`.
    - Acceptance criteria: Rapid taps do not trigger duplicate requests; UI remains responsive with clear pending state. File Reference (current risk): `lib/features/profile/view/public_profile_screen.dart:153-163`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:51-56`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129`.
  - Item 3: Reduce rebuild churn and improve favorites timestamp formatting.
    - What to change: Guard `notifyListeners()` on unchanged values; use local date formatting utility in `FavoriteCard`.
    - Exact file(s) to edit/create: `lib/features/favorites/viewmodels/favorites_view_model.dart`, `lib/features/favorites/view/widgets/favorite_card.dart`.
    - Acceptance criteria: Fewer redundant rebuilds in traces/manual testing and user-friendly local date text shown in favorite rows. File Reference (current behavior): `lib/features/favorites/viewmodels/favorites_view_model.dart:88-96`, `lib/features/favorites/view/widgets/favorite_card.dart:47-50`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:153-155`.

## 8) Verification Checklist
### Commands
- Static analysis (feature + direct touchpoints):
  - `flutter analyze lib/features/favorites lib/features/tasks/view/widgets/requests/widgets/request_tile.dart lib/features/tasks/view/widgets/requests/requests_list_screen.dart lib/features/profile/view/public_profile_screen.dart lib/main.dart`
- Tests (targeted after adding tests):
  - `flutter test test/features/favorites`
  - `flutter test test/features/tasks`
  - `flutter test integration_test/favorites_cross_feature_flow_test.dart` (or your actual integration test file path)
- Format check (touched files):
  - `dart format --output=none --set-exit-if-changed lib/features/favorites lib/features/tasks/view/widgets/requests/widgets/request_tile.dart lib/features/tasks/view/widgets/requests/requests_list_screen.dart lib/features/profile/view/public_profile_screen.dart`
- Grep/rg regression guards:
  - `rg -n "FavoritesService\(" lib/features/tasks/view --glob '*.dart'` (should not hit `RequestTile` after refactor)
  - `rg -n "Failed to start chat: \$e" lib/features/favorites --glob '*.dart'` (should return no hits)
  - `rg -n "FavoritesViewModel\(service: FavoritesService\(\)\)" lib/main.dart lib/features/favorites --glob '*.dart'` (should return one app-level provider hit only, or the expected final count)
  - `rg --files test integration_test | rg 'favorite|favorites'` (should return newly added test files)
### Manual Scenarios
- Favorites list baseline load (placeholder-safe parser)
  - Open Favorites screen via route. File Reference: `lib/main.dart:231-238`, `lib/features/favorites/routes/favorites_routes.dart:4-13`.
  - Verify loading -> list/empty/error branches render correctly. File Reference: `lib/features/favorites/view/favorites_screen.dart:57-133`.
  - Validate missing joined profile row does not crash and renders placeholder name/avatar. File Reference: `lib/features/favorites/models/favorite_model.dart:65-73`, `lib/features/favorites/view/widgets/favorite_card.dart:26-42`.
- Public profile favorite toggle (shared-state correctness)
  - Open a freelancer public profile and inspect current favorite icon state. File Reference: `lib/features/profile/view/public_profile_screen.dart:138-152`.
  - Toggle add/remove and verify feedback plus state consistency after navigating to Favorites screen. File Reference: `lib/features/profile/view/public_profile_screen.dart:153-163`, `lib/features/favorites/view/favorites_screen.dart:75-133`.
  - Rapid-tap test: confirm duplicate requests are blocked or handled deterministically. File Reference: `lib/features/profile/view/public_profile_screen.dart:153-163`.
- Task offers list add-to-favorites (MVVM boundary enforcement)
  - Trigger “Add to favorites” from `RequestTile` in offers list. File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:265-276`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:51-56`.
  - Confirm UI path no longer directly calls `FavoritesService` from the view after refactor. File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129` (current path to replace).
- Favorites screen remove + chat start failure UX
  - Simulate/remove under failure (network or auth issue) and verify no false-success snackbar. File Reference: `lib/features/favorites/view/favorites_screen.dart:123-129`, `lib/features/favorites/viewmodels/favorites_view_model.dart:68-85`.
  - Simulate chat-start failure and verify sanitized snackbar text (no raw exception). File Reference: `lib/features/favorites/view/favorites_screen.dart:91-121`.
### Supabase/RLS Contract Checks
- `UNVERIFIED` in current repo: favorites table/policies are not present in `supabase/migrations` SQL files for this audit. Missing files: favorites DDL/RLS migration(s) under `supabase/migrations/`.
- Validate actual DB policies (RLS source of truth) with SQL against the target environment:
  - `select schemaname, tablename, policyname, cmd, qual, with_check from pg_policies where schemaname = 'public' and tablename = 'favorites';`
  - Expect semantics matching docs (owner-only select/insert/delete). File Reference (doc expectation): `Sline_everything/SUPABASE_SETUP.md:1119-1125`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:25-34`.
- Validate DM authorization rule (favorites-required vs not-required) against actual DB trigger/function/policies:
  - Inspect trigger/function backing conversation inserts (e.g., `trg_conversations_guard` or equivalent) in the database.
  - Confirm behavior for non-task DM insertion with and without a favorites relation.
  - Reconcile docs/comments after DB verification. File Reference (current mismatch): `lib/features/chat/services/message_service.dart:429-444`, `Sline_everything/SUPABASE_SETUP.md:81-83`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:32-34`.
- Validate no privileged client keys are used for favorites access path (client should use anon/auth session only):
  - Review favorites service usage of `Supabase.instance.client`. File Reference: `lib/features/favorites/data/favorites_service.dart:6-10`.
  - Review Supabase client config note for anon key and no service role in client config. File Reference: `lib/core/services/supabase_config.dart:6-10`, `lib/core/services/supabase_config.dart:17-28`.

## 9) Risks & Rollback Notes
- What could break:
  - Provider unification may change favorites load timing and expose screens that implicitly relied on stale/default state. File Reference: `lib/main.dart:160-163`, `lib/features/favorites/view/favorites_screen.dart:19-40`, `lib/features/profile/view/public_profile_screen.dart:138-165`.
  - Removing `RequestTile` direct-service fallback can break offers-list add-to-favorites if callback/VM wiring is incomplete. File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:265-276`.
  - Parser changes may break assumptions in code that expects joined profile fields to always exist. File Reference: `lib/features/favorites/models/favorite_model.dart:65-73`, `lib/features/favorites/view/widgets/favorite_card.dart:28-42`.
  - Documentation alignment work can be wrong if DB behavior is not validated first. File Reference: `lib/features/chat/services/message_service.dart:429-444`, `Sline_everything/SUPABASE_SETUP.md:81-83`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md:32-34`.
- Rollback steps:
  - Roll back parser and UI changes separately from provider refactor if needed; keep parser null-safety fix if stable because it addresses a crash-risk path. File Reference: `lib/features/favorites/models/favorite_model.dart:65-73`.
  - If provider unification regresses cross-screen behavior, temporarily restore previous provider wiring while keeping request-tile MVVM and error-sanitization fixes isolated. File Reference: `lib/main.dart:160-163`, `lib/features/favorites/view/favorites_screen.dart:19-40`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:92-129`.
  - Do not finalize docs comment changes about DM authz until DB policy/trigger behavior is verified (`UNVERIFIED` until checked). File Reference: `lib/features/chat/services/message_service.dart:429-444`, `Sline_everything/SUPABASE_SETUP.md:81-83`.
