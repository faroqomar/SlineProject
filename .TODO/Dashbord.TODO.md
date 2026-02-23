# Dashbord Feature Audit (Dashboard)

## Overview (what feature does, boundaries, dependencies)

- Feature purpose: role-based dashboard that aggregates overview counters, activity feed, bookings, work items, inbox offers, and wallet snapshot for client/freelancer flows.
- Primary entry UI: `lib/features/dashboard/view/dashboard_screen.dart`
- Primary state owner: `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (global provider from `lib/main.dart`)
- Feature-local data access:
  - `lib/features/dashboard/data/dashboard_repository.dart` (`profiles`, `vw_unified_work_items`, `activity_log`)
  - `lib/features/dashboard/services/dashboard_permission_service.dart` (pure permission/action mapping)
- Direct dependencies touched by dashboard ViewModel/UI:
  - `lib/core/services/dashboard_cache_service.dart`
  - `lib/core/services/deep_link_service.dart`
  - `lib/features/tasks/services/task_service.dart`
  - `lib/features/booking/services/booking_service.dart`
  - `lib/features/services/services/services_service.dart`
  - `lib/features/wallet/viewmodels/wallet_view_model.dart` (dashboard widget dependency)
- Static analysis executed:
  - `flutter analyze lib/features/dashboard lib/core/services/dashboard_cache_service.dart` -> `No issues found`
- Scope notes:
  - Audit focused on `lib/features/dashboard/**` plus directly called services/modeled contracts above.
  - No DB/RLS runtime verification executed in this phase (code + docs audit only).

## Findings

### Security (highest priority)

- `HIGH` Client-driven status transitions rely on broad table updates instead of transition-validating RPCs.
  - `lib/features/tasks/services/task_service.dart:168` updates `tasks.status` directly.
  - `lib/features/booking/services/booking_service.dart:220` updates `bookings.status` directly.
  - `Sline_everything/SUPABASE_SETUP.md:804` documents `tasks_update_involved` (`client_id OR freelancer_id`) and `Sline_everything/SUPABASE_SETUP.md:857` documents `bookings_update_status_only` for both parties.
  - Risk: UI permissions are only UX; invalid or unauthorized transitions can be attempted by a modified client unless DB-side transition logic is enforced.

- `HIGH` Reject-offer path is not server-authoritative and is already known to fail under RLS in some environments.
  - `lib/features/tasks/services/task_service.dart:611` performs direct update on `task_requests`.
  - `lib/features/tasks/services/task_service.dart:621` explicitly throws `"Need reject_task_request RPC"` when RLS blocks.
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart:607` still exposes this action path via dashboard inbox.
  - Impact: broken action + inconsistent authorization model (accept uses RPC, reject does not).

- `MEDIUM` Activity feed query relies entirely on RLS and overfetches with `select('*')`.
  - `lib/features/dashboard/data/dashboard_repository.dart:226`-`234`
  - No explicit `.eq('user_id', currentUser)` filter is applied.
  - Impact: if `activity_log` RLS is misconfigured or broadened later, dashboard could read cross-user activity data.

- `MEDIUM` Latent PII/privacy leak in dashboard cache design (currently not active because cache is not injected).
  - Cache keys are role-scoped / global, not user-scoped: `lib/core/services/dashboard_cache_service.dart:20`-`23`, `lib/core/services/dashboard_cache_service.dart:29`, `lib/core/services/dashboard_cache_service.dart:206`-`223`
  - Raw activity metadata is cached to local SharedPreferences: `lib/features/dashboard/models/activity_log.dart:48`-`63` and `lib/core/services/dashboard_cache_service.dart:76`-`89`
  - Risk if cache is enabled: cross-account data flash on shared device + local persistence of potentially sensitive metadata.

- `PASS` No service-role key or obvious hardcoded secret usage found in dashboard/client feature scan.
  - Grep found only masked token handling and anon-key config elsewhere, not dashboard feature code.

### Data Integrity

- `HIGH` “Pending Payment Tenders” query is logically inconsistent and likely returns wrong records.
  - `lib/features/tasks/services/task_service.dart:650`-`690`
  - Code filters `assigned_freelancer_id = uid` and `status = 'open'` (`:663`-`:671`), which conflicts with comments and typical task lifecycle.
  - Impact: pending counters/sections derived from this can be incorrect or empty.

- `HIGH` Work-tab primary buttons can be rendered but execute a no-op for several action types.
  - Work tab always delegates buttons to VM: `lib/features/dashboard/view/tabs/work_tab.dart:211`, `lib/features/dashboard/view/tabs/work_tab.dart:244`, `lib/features/dashboard/view/tabs/work_tab.dart:298`
  - `WorkItemCard` renders button for `approveClose` / `payEscrow` etc: `lib/features/dashboard/view/widgets/work_item_card.dart:233`-`251`
  - `DashboardViewModel.performPrimaryAction()` intentionally returns early for `approveClose`, `reviewDelivery`, `payEscrow`, `submitEvidence`, `viewDetails`: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:667`-`685`
  - Impact: visible CTA appears actionable but does nothing in Work tab (except logs).

- `MEDIUM` Role-switch protection is incomplete; `_loadData()` can still override recent manual role change.
  - Constructor fires multiple async flows concurrently: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:49`-`51`
  - `_syncRoleFromBackend()` has a 15s guard: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:293`-`301`
  - `_loadData()` always re-fetches role and assigns it with no recent-change guard: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:381`-`387`
  - Impact: transient role/data flicker after manual switch, especially on slow backend/profile propagation.

- `MEDIUM` Dashboard cache TTL uses one shared timestamp for all users/roles/cache domains.
  - `lib/core/services/dashboard_cache_service.dart:23`, `lib/core/services/dashboard_cache_service.dart:152`-`172`
  - Impact: a fresh write for one role/user can mark stale data in another role/user key as “valid.”

- `LOW` Unified work item mapping fabricates timestamps with `DateTime.now()` when view data is missing.
  - `lib/features/dashboard/data/dashboard_repository.dart:184`-`187`
  - Impact: incorrect ordering / misleading “posted” timing if `last_activity_at` is null.

- `LOW` `DashboardCounters.newMessages` is always `0` (placeholder data shipped as real metric).
  - `lib/features/dashboard/data/dashboard_repository.dart:258`, `lib/features/dashboard/data/dashboard_repository.dart:309`
  - Impact: misleading dashboard KPI.

### Architecture

- `HIGH` `DashboardViewModel` is a multi-domain “god ViewModel” (817 LOC) mixing role sync, cache orchestration, dashboard aggregation, inbox actions, work actions, and list derivation.
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
  - This increases regression risk and makes targeted tests difficult.

- `MEDIUM` Repository contains pure business/presentation aggregation logic (`fetchCounters`) in addition to IO.
  - `lib/features/dashboard/data/dashboard_repository.dart:250`-`315`
  - MVVM boundary drift: counters are derived from in-memory `WorkItem`/`TaskRequest`, not database persistence.

- `MEDIUM` Dashboard cache infrastructure is wired globally but not actually injected into dashboard ViewModel.
  - Provider exists: `lib/main.dart:138`-`139`
  - DashboardViewModel provider ignores it: `lib/main.dart:127`
  - VM supports injection but receives `null`: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:33`-`40`
  - Result: stale-while-revalidate path is dead code today.

- `LOW` Dashboard still contains removed `Manage` tab artifacts and comments, creating navigation drift.
  - Removed tab comments in active UI: `lib/features/dashboard/view/dashboard_screen.dart:9`, `lib/features/dashboard/view/dashboard_screen.dart:128`
  - Orphaned tab implementation remains: `lib/features/dashboard/view/tabs/manage_tab.dart`

- `LOW` Cross-feature UI navigation is inconsistent (direct screen push vs deep-link service).
  - `BookingCard` directly pushes `WorkItemDetailsScreen`: `lib/features/dashboard/view/widgets/booking_card.dart` (navigation path in widget)
  - `WorkItemCard` routes via `DeepLinkService`: `lib/features/dashboard/view/widgets/work_item_card.dart`
  - Increases duplicated navigation logic and inconsistent refresh behavior.

### Code Quality

- `HIGH` Multiple unused state/getters/helpers remain in `DashboardViewModel`.
  - Unused booking filter state: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:119`-`120`, setter at `:636`-`:640`
  - Unused grouped inbox getter: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:126`-`155`
  - Unused pending action state/getters: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:178`-`183`
  - Unused legacy active buckets: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:233`-`236` + calculators at `:779`-`:817`

- `MEDIUM` Orphaned mock stack remains in production feature tree.
  - `lib/features/dashboard/data/mock/mock_dashboard_repository.dart`
  - `lib/features/dashboard/models/activity_item.dart`

- `MEDIUM` TODO placeholders remain in user-reachable widgets (and in dead manage widgets).
  - `lib/features/dashboard/view/widgets/booking_card.dart:220`
  - `lib/features/dashboard/view/widgets/manage_service_list.dart:96`, `:103`
  - `lib/features/dashboard/view/widgets/manage_task_list.dart:98`, `:105`

- `LOW` Duplicated small UI helper patterns (section headers/empty states) across tabs increase churn.
  - `lib/features/dashboard/view/tabs/overview_tab.dart:75`-`94`
  - `lib/features/dashboard/view/tabs/bookings_tab.dart:92`-`103`

### Performance

- `HIGH` Dashboard SWR cache/perf path is disabled by construction bug (provider not injected).
  - `lib/main.dart:127`, `lib/main.dart:138`-`139`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:33`-`40`
  - Impact: every dashboard load is cold network fetch; cache service code adds maintenance without benefit.

- `MEDIUM` Background refresh hides existing content in some widgets/tabs, causing avoidable flicker.
  - `lib/features/dashboard/view/tabs/bookings_tab.dart:17`-`19` blocks list even when data exists.
  - `lib/features/dashboard/view/widgets/next_actions_list.dart:19`-`21` blocks actions even when cached/current items exist.
  - Inconsistent with `InboxTab`/`ActivityFeedPreview`, which only show spinner when empty.

- `MEDIUM` Dashboard refresh path over-fetches all tab data on every refresh/role switch.
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart:394`-`401`
  - Includes bookings, inbox, pending items, and management data even if user only needs overview/work.

- `MEDIUM` Broad `watch` usage rebuilds large trees frequently.
  - `lib/features/dashboard/view/dashboard_screen.dart:74` (entire scaffold/app bar/tabs)
  - Multiple tab/widget-level `watch` consumers over full VM state (`overview_tab`, `work_tab`, counters, activity, manage lists)
  - Consider `Selector`/segmented notifiers for high-churn lists.

- `LOW` Wallet snapshot depends on global `WalletViewModel` but does not trigger load; dashboard often shows zeroed data until wallet screen loads.
  - `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart:18`
  - `lib/features/wallet/viewmodels/wallet_view_model.dart:21`
  - `loadWallet()` only found in wallet screen usage.

- `LOW` Activity feed query overfetches `*` columns; dashboard UI renders a small subset.
  - `lib/features/dashboard/data/dashboard_repository.dart:228`-`233`

### Testing gaps

- No dashboard-specific tests found (`test/**` scan returned no dashboard files).
- Missing unit tests for:
  - `DashboardPermissionService` action matrix per role/status
  - `DashboardRepository` unified-status mapping and profile enrichment fallback
  - `DashboardCacheService` key scoping/TTL behavior (especially multi-user + multi-role)
  - `DashboardViewModel` role-switch race conditions and `_loadData()` sequencing
- Missing widget tests for:
  - Work tab primary action behavior (pay/review/approve buttons must navigate or execute)
  - Bookings tab loading-with-existing-data behavior (no flicker regression)
  - Next Actions loading state behavior
  - Counter-card navigation intents (`workSubTab` routing)
- Missing integration/manual scripted checks for:
  - cross-account logout/login on shared device (cache isolation)
  - reject-offer flow under real RLS policies
  - unauthorized status transition attempts blocked server-side

## Dead/Unused code candidates (with file paths)

- `lib/features/dashboard/data/mock/mock_dashboard_repository.dart` (no references outside itself)
- `lib/features/dashboard/models/activity_item.dart` (used only by mock repository above)
- `lib/features/dashboard/view/tabs/manage_tab.dart` (not imported into active dashboard UI)
- `lib/features/dashboard/view/widgets/manage_service_list.dart` (only referenced by orphaned `ManageTab`)
- `lib/features/dashboard/view/widgets/manage_task_list.dart` (only referenced by orphaned `ManageTab`)
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (`bookingFilter` getter/setter and backing field)
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (`inboxGroupedByTask` getter + `InboxTaskGroup` model not consumed by current `InboxTab`)
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (`pendingRequests` / `pendingPaymentTenders` getters not consumed by current UI)
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (`activeUpNext`, `activeInProgress`, `activeInReview` + calculators appear unreferenced legacy paths)

## Duplicate code candidates (with file paths)

- Section header components duplicated:
  - `lib/features/dashboard/view/tabs/overview_tab.dart`
  - `lib/features/dashboard/view/tabs/bookings_tab.dart`
- Action-dispatch logic duplicated/inconsistent across:
  - `lib/features/dashboard/view/widgets/next_actions_list.dart`
  - `lib/features/dashboard/view/tabs/work_tab.dart`
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (`performPrimaryAction`)
- Card-shell / status-badge style patterns duplicated in orphaned manage widgets:
  - `lib/features/dashboard/view/widgets/manage_service_list.dart`
  - `lib/features/dashboard/view/widgets/manage_task_list.dart`
- Loading/empty-state logic duplicated and inconsistent across:
  - `lib/features/dashboard/view/tabs/bookings_tab.dart`
  - `lib/features/dashboard/view/tabs/inbox_tab.dart`
  - `lib/features/dashboard/view/widgets/next_actions_list.dart`
  - `lib/features/dashboard/view/widgets/activity_feed_preview.dart`

## Refactor plan (exact file moves/splits)

### Proposed splits

- Split `lib/features/dashboard/viewmodels/dashboard_view_model.dart` into:
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (public state + small command surface only)
  - `lib/features/dashboard/viewmodels/dashboard_role_controller.dart` (role cache/sync/switch sequencing)
  - `lib/features/dashboard/viewmodels/dashboard_data_loader.dart` (load/refresh orchestration + partial refresh helpers)
  - `lib/features/dashboard/viewmodels/dashboard_inbox_actions.dart` (accept/reject/withdraw offer flows)
  - `lib/features/dashboard/viewmodels/dashboard_work_actions.dart` (primary action execution + navigation intent mapping)
  - `lib/features/dashboard/viewmodels/dashboard_derived_lists.dart` (pure bucket/next-action derivation)

- Split `lib/features/dashboard/data/dashboard_repository.dart` into IO vs pure domain logic:
  - Keep IO in `lib/features/dashboard/data/dashboard_repository.dart`
  - Move counter derivation from `fetchCounters(...)` to new `lib/features/dashboard/services/dashboard_counters_service.dart`
  - Optionally move unified -> `WorkItem` mapping to `lib/features/dashboard/services/dashboard_work_item_mapper.dart`

### Proposed moves / consolidation

- Move or archive unused mock code out of runtime feature path:
  - `lib/features/dashboard/data/mock/mock_dashboard_repository.dart` -> `test/fixtures/dashboard/mock_dashboard_repository.dart` (if retained for tests)
  - `lib/features/dashboard/models/activity_item.dart` -> `test/fixtures/dashboard/activity_item.dart` or delete if unused

- Remove orphaned Manage tab files or relocate to a future feature module:
  - `lib/features/dashboard/view/tabs/manage_tab.dart` -> `lib/features/management/view/dashboard_manage_tab.dart` (if intended reuse)
  - `lib/features/dashboard/view/widgets/manage_service_list.dart` -> `lib/features/management/view/widgets/manage_service_list.dart`
  - `lib/features/dashboard/view/widgets/manage_task_list.dart` -> `lib/features/management/view/widgets/manage_task_list.dart`

- Consolidate duplicated tab UI helpers:
  - Create `lib/features/dashboard/view/widgets/dashboard_section_header.dart`
  - Replace local `_SectionHeader` classes in:
    - `lib/features/dashboard/view/tabs/overview_tab.dart`
    - `lib/features/dashboard/view/tabs/bookings_tab.dart`

### Provider wiring refactor (exact target)

- Replace dashboard provider wiring in `lib/main.dart` with a dependency-injected provider chain:
  - Keep/create `Provider<DashboardCacheService>` before dashboard VM
  - Convert dashboard VM provider to `ChangeNotifierProxyProvider<DashboardCacheService, DashboardViewModel>` (or equivalent)
  - Ensure `DashboardViewModel` receives `cacheService` explicitly

## Fix Plan (Phases)

### Phase 1: critical security & correctness

- Replace dashboard-exposed status transitions with server-validated RPC/use-case endpoints (or add DB transition guards before UI rollout).
  - Prioritize `TaskService.updateTaskStatus(...)` and `BookingService.updateBookingStatus(...)`.
- Implement `reject_task_request` RPC path and switch `TaskService.rejectOffer(...)` to RPC (match accept flow).
- Fix broken Work tab primary action dispatch:
  - Route navigation-only actions via `DeepLinkService` from Work tab or return navigation intents from VM.
- Fix `getPendingPaymentTenders()` query logic to match actual domain status(es) and documented business rule.
- Add explicit user scoping to `activity_log` query (`user_id = auth.uid`) unless DB contract guarantees filtered view/table semantics.

### Phase 2: refactor/structure

- Wire `DashboardCacheService` into `DashboardViewModel` via provider injection (after cache key hardening below).
- Harden cache keys before enabling cache path:
  - namespace all keys by authenticated user id
  - separate timestamps per cache domain and per user/role
  - clear cache on logout/account switch
- Split `DashboardViewModel` responsibilities (role sync, data load, inbox actions, work actions, derived lists).
- Move pure `fetchCounters` logic out of repository into a dashboard service.
- Remove or relocate orphaned `ManageTab`/manage widgets and mock artifacts.

### Phase 3: tests

- Unit tests:
  - permission/action matrix and unified-status mapping
  - pending tenders query behavior (mocked repository/service)
  - cache scoping/TTL (multi-user, role switch)
  - role-switch race handling in `DashboardViewModel`
- Widget tests:
  - Work tab action buttons (pay/review/approve/start/complete)
  - Bookings/NextActions refresh should preserve existing content
  - counter-card navigation and `workSubTab` consumption
- Integration tests (or manual scripted smoke if integration tests not ready):
  - accept/reject/withdraw offer paths under real RLS
  - role switch persistence and refresh behavior

### Phase 4: polish/perf

- Reduce over-fetching by lazy-loading tab datasets (overview first, others on tab entry or explicit refresh).
- Replace broad `watch` with `Selector`/smaller state slices for counters/activity/work lists.
- Normalize loading-state UX across tabs (spinner only when data is empty).
- Trim activity feed select columns (avoid `*`) and review logging verbosity.
- Decide wallet snapshot strategy (dashboard-triggered wallet load vs explicit placeholder state).

## Verification steps (commands + manual scenarios)

### Commands

- `flutter analyze lib/features/dashboard lib/core/services/dashboard_cache_service.dart lib/features/tasks/services/task_service.dart lib/features/booking/services/booking_service.dart`
- `flutter test test/features/dashboard` (after adding tests)
- `flutter test test/features/tasks` (offer accept/reject/update status coverage)
- `flutter test test/features/booking` (booking status transition coverage)
- `dart format --output=none --set-exit-if-changed lib/features/dashboard lib/core/services/dashboard_cache_service.dart lib/features/tasks/services/task_service.dart lib/features/booking/services/booking_service.dart`

### Manual scenarios

- Dashboard initial load with existing data:
  - Overview, Work, Bookings, Inbox render expected content.
  - No full-screen flicker on refresh when content already exists.
- Role switch:
  - Switch freelancer <-> client repeatedly on slow network.
  - Verify no role reversion/flicker and counters/work/bookings match selected role.
- Work tab primary actions:
  - `Pay & Confirm`, `Complete & Close`, `Review Delivery`, `Start Work`, `Mark Completed`.
  - Confirm each button either navigates correctly or executes server action and refreshes state.
- Inbox actions:
  - Accept offer (RPC), reject offer (new RPC path), withdraw offer.
  - Confirm list updates and task/work data refresh correctly.
- Pending payment data:
  - Validate “Pending Requests / Pending Payment” counters against actual DB state.
- Security / privacy:
  - Attempt unauthorized status transition from non-owner/non-allowed role (must fail server-side).
  - Logout user A, login user B on same device, open dashboard immediately (must not show user A cached data).
- Activity feed:
  - Confirm only current user’s activity appears and sensitive metadata is not unnecessarily cached/exposed.

## Risks & rollback notes

- Shared-service blast radius:
  - `TaskService` and `BookingService` are used by other features; status-transition changes can affect tasks/work/orders/booking screens.
- Cache activation risk:
  - Wiring `DashboardCacheService` without first fixing user-scoped keys can introduce privacy leaks; fix cache design before enabling.
- Refactor risk:
  - Splitting `DashboardViewModel` may break provider lifecycle/notify behavior if done in one large change.
- Recommended rollback approach for future fix implementation:
  - Land Phase 1 fixes in small commits (reject RPC path, action dispatch fix, pending tenders query).
  - Gate cache wiring behind a temporary flag until key scoping tests pass.
  - Keep old ViewModel API surface stable while moving internals to new files.
- Phase-1 audit only:
  - No code changes applied in this step; report/plan generated only.

