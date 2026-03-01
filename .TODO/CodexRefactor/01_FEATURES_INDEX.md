# Phase 0 Feature Index + Per-Feature Audit Plans (Plan-Only)

## Scope Guard (Phase 0)

- This file inventories features and defines what will be checked.
- It does **not** claim that any issue exists.
- All checks below are written as **verifiable tasks** for later audit execution.

## Detection Method Used (Phase 0)

- Folder structure scan: `lib/features/*`
- Routing/navigation scan:
  - `lib/main.dart` named routes
  - `lib/app/main_navigation_screen.dart` bottom-nav tabs
  - feature route helper files
- State wiring scan:
  - global `MultiProvider` registrations in `lib/main.dart`
  - local `ChangeNotifierProvider` / `Consumer` usage in feature views
- MVVM surface scan:
  - `view/`, `viewmodels/`, `data/`, `services/`, `models/`
- Supabase surface scan (best effort):
  - `.from(...)`, `.rpc(...)`, `.stream(...)`, `storage.from(...)`
  - feature docs in `Sline_everything/*`

## Exact Feature Names (Use These Names When Choosing a Feature)

- `auth` waiting
- `booking` ✅ 
- `categories`
- `chat` waiting
- `dashboard` waiting
- `favorites` waiting
- `home` ✅
- `management` ✅
- `notifications`
- `portfolio` ✅
- `profile` waiting
- `proposals`
- `saved`
- `search`
- `services` waiting
- `tasks` waiting
- `wallet`
- `work`

## Shared Audit Checklist Template (Testable / Verifiable)

Apply this template to each feature, then add the feature-specific checks listed in that feature’s plan section.

### A) Structure & Architecture (Checks `A1`–`A6`)

- [ ] `A1` MVVM boundary import scan for the feature views.
  - Verify with: `rg -n "Supabase\\.instance|SupabaseClient|http\\.|dio\\." lib/features/<FEATURE>/view --glob '*.dart'`
  - Evidence: command output + manual review notes for each hit (if any).
- [ ] `A2` Forbidden dependency direction scan (`service/data/viewmodel` importing feature `view/`).
  - Verify with: `rg -n "^import .*features/.*/view/" lib/features/<FEATURE> --glob '*.dart'`
  - Evidence: command output and disposition per match.
- [ ] `A3` Layer wiring trace from entry screen -> ViewModel -> Service/Repository -> Supabase.
  - Verify with: imports + constructor dependencies in feature files.
  - Evidence: one traced path per primary user flow.
- [ ] `A4` Provider lifecycle ownership check (global provider vs local provider vs passed instance).
  - Verify with: `rg -n "ChangeNotifierProvider|Provider\\(" lib/features/<FEATURE> lib/main.dart --glob '*.dart'`
  - Evidence: provider ownership notes + disposal expectations.
- [ ] `A5` File/module organization check (split/merge candidates identified but not changed).
  - Verify with: `wc -l $(rg --files lib/features/<FEATURE> | tr '\n' ' ')`
  - Evidence: list of unusually large files and rationale for review.
- [ ] `A6` Public API naming consistency review for ViewModel/Service/Repository methods.
  - Verify with: manual scan of exported class APIs and method names.
  - Evidence: naming checklist result (consistent / inconsistent areas to inspect further).

### B) Code Quality & Maintainability (Checks `B1`–`B7`)

- [ ] `B1` Dead code / unreachable / unused scan via analyzer.
  - Verify with: `flutter analyze`
  - Evidence: analyzer output filtered to feature files.
- [ ] `B2` Duplicate logic / copy-paste candidate scan.
  - Verify with: compare similar methods/screens within feature and adjacent features.
  - Evidence: list of candidate duplicate blocks (if any) with file references.
- [ ] `B3` Large file / long method inspection.
  - Verify with: line counts + targeted manual review.
  - Evidence: top N files by size in feature and methods reviewed.
- [ ] `B4` Error handling/logging consistency scan.
  - Verify with: `rg -n "try\\s*\\{|catch\\s*\\(|AppLogger\\.|rethrow|throw Exception" lib/features/<FEATURE> --glob '*.dart'`
  - Evidence: map of major async methods and their error strategy.
- [ ] `B5` Null-safety + async correctness scan.
  - Verify with: `rg -n "!" lib/features/<FEATURE> --glob '*.dart'` and manual review of async state updates.
  - Evidence: list of force-unwrap sites and justification/guards.
- [ ] `B6` Formatting/lint conformance for touched scope (audit phase execution only).
  - Verify with: `dart format --output=none --set-exit-if-changed lib/features/<FEATURE>` (or repo-wide)
  - Evidence: pass/fail command output.
- [ ] `B7` Test coverage expectation review (unit/widget/integration) for feature flows.
  - Verify with: existing tests + missing critical paths documented.
  - Evidence: explicit expected test matrix for the feature.

### C) Security & Privacy (Checks `C1`–`C8`)

- [ ] `C1` Secret/env handling scan in feature + related core wiring.
  - Verify with: `rg -n "(service_role|SUPABASE_SERVICE_ROLE|anonKey|api[_-]?key|secret|token)" lib/features/<FEATURE> lib/core --glob '*.dart'`
  - Evidence: each hit classified as safe/public/config-sensitive/needs deeper review.
- [ ] `C2` Supabase access path to RLS-protected tables/views/functions mapping.
  - Verify with: feature `.from(...)`, `.rpc(...)`, docs references, later `pg_policies`/`pg_proc` queries.
  - Evidence: feature data access matrix (table/view/rpc -> code path -> expected policy checks).
- [ ] `C3` Authorization ownership checks (client-side guards vs server-enforced RLS/RPC).
  - Verify with: manual review of action methods and UI guards, cross-check with expected RLS assumptions.
  - Evidence: list of privileged actions and their enforcement layers.
- [ ] `C4` Injection / unsafe dynamic query review.
  - Verify with: `rg -n "rpc\\(|from\\(|order\\(|select\\(" lib/features/<FEATURE> --glob '*.dart'` + manual inspection for user-controlled strings.
  - Evidence: query construction review notes.
- [ ] `C5` PII/logging/privacy review.
  - Verify with: `rg -n "AppLogger\\.|print\\(" lib/features/<FEATURE> lib/core --glob '*.dart'`
  - Evidence: logging field inventory (IDs vs emails vs payloads).
- [ ] `C6` File upload / storage handling review (if feature uploads or serves files).
  - Verify with: `rg -n "storage\\.from\\(|upload|pick|compress|mime" lib/features/<FEATURE> --glob '*.dart'`
  - Evidence: bucket, path, content-type, size validation, signed/public URL usage notes.
- [ ] `C7` Role-based / admin / privileged action review.
  - Verify with: `rg -n "role|admin|owner|provider|client|freelancer" lib/features/<FEATURE> --glob '*.dart'`
  - Evidence: action matrix by role.
- [ ] `C8` Service-role usage prohibition verification (client app should not embed service-role keys).
  - Verify with repo-wide scan during audit workflow.
  - Evidence: repo-wide grep output + classification.

### D) Performance & UX (Checks `D1`–`D5`)

- [ ] `D1` Rebuild scope review (`Consumer`/provider usage breadth).
  - Verify with: `rg -n "Consumer<|context\\.watch<|AnimatedBuilder" lib/features/<FEATURE> --glob '*.dart'`
  - Evidence: screens with large rebuild scopes identified for runtime profiling.
- [ ] `D2` List rendering/pagination strategy review.
  - Verify with: manual review for `ListView.builder`, pagination cursors/offsets, lazy loading.
  - Evidence: list of list screens + pagination behavior.
- [ ] `D3` Network call redundancy / N+1 pattern review.
  - Verify with: service methods + ViewModel call chains + refresh triggers.
  - Evidence: sequence diagrams or request chain notes per primary flow.
- [ ] `D4` Realtime subscription lifecycle review (if feature streams/realtime).
  - Verify with: `rg -n "stream\\(|channel\\(|listen\\(" lib/features/<FEATURE> --glob '*.dart'`
  - Evidence: subscribe/unsubscribe lifecycle notes.
- [ ] `D5` Image/media/asset handling review (if feature renders media).
  - Verify with: `rg -n "Image|CachedNetworkImage|signed|createSignedUrl|decode" lib/features/<FEATURE> lib/core/widgets --glob '*.dart'`
  - Evidence: media loading/caching behavior notes.

### E) Data Integrity & Domain Logic (Checks `E1`–`E5`)

- [ ] `E1` Status/enum/state-machine transition review.
  - Verify with: `rg -n "status|enum|switch \\(" lib/features/<FEATURE> --glob '*.dart'`
  - Evidence: transition table (allowed transitions inferred from code + docs).
- [ ] `E2` Race condition / double-submit / concurrent refresh review.
  - Verify with: loading flags, optimistic updates, sequential awaits, stream interactions.
  - Evidence: action-by-action concurrency notes.
- [ ] `E3` Offline/empty/error edge-case coverage review.
  - Verify with: UI state branches + service exception handling.
  - Evidence: matrix of loading/empty/error/success states.
- [ ] `E4` Schema/RPC contract compatibility review.
  - Verify with: model parsing + select columns + RPC return parsing assumptions.
  - Evidence: contract assumptions list for later DB verification.
- [ ] `E5` Backward compatibility/migration assumption review.
  - Verify with: docs (`Sline_everything/SUPABASE_SETUP.md`) vs code references.
  - Evidence: code-only vs docs-only schema objects list.

### F) Fix Strategy Blueprint (Checks `F1`–`F5`) — Plan for Later, No Changes Yet

- [ ] `F1` Draft feature-specific remediation phases:
  - Phase 1: safety/security/correctness fixes
  - Phase 2: architecture refactor
  - Phase 3: tests
  - Phase 4: UX/perf/polish
  - Evidence: per-feature staged plan with sequencing.
- [ ] `F2` Define verification commands/tests after fixes (no execution in Phase 0).
  - Evidence: exact command list + manual test flows.
- [ ] `F3` Define rollback/blast-radius notes for risky changes.
  - Evidence: impacted modules/routes/providers list.
- [ ] `F4` Define acceptance criteria for the feature audit and any eventual fixes.
  - Evidence: checklist with pass conditions.
- [ ] `F5` Confirm no code changes performed before explicit `APPLY FIXES`.
  - Evidence: audit notes and git diff review at audit time.

## Feature Inventory (Summary)

| Feature | Brief Description | Entry UI (observed) | State Wiring (observed) | Supabase Surface (best-effort) |
|---|---|---|---|---|
| `auth` | Authentication and session entry flows | `LoginScreen`, `SignupScreen`, `ForgotPasswordScreen` | Global `AuthViewModel` + local providers in auth screens | Auth APIs, `profiles` table |
| `booking` | Availability slots and bookings lifecycle | `BookingsDiscoveryScreen`, `AvailabilityScreen`, booking detail/sheets | Global `BookingViewModel` | `availability_slots`, `bookings`, joined `tasks`, RPC `process_payment_event` |
| `categories` | Categories listing/lookup | `CategoriesScreen` | Local `CategoriesViewModel` (screen provider) | `categories` table |
| `chat` | Conversations, messages, attachments, realtime | `MessagesScreen`, `ChatScreen`, `CreateOfferSheet` | Global `ChatViewModel` | `conversations`, `messages`, realtime streams, RPCs, bucket `chat-attachments` |
| `dashboard` | Aggregated role-based dashboard/work overview | `DashboardScreen` (+ tabs/widgets) | Global `DashboardViewModel` | `profiles`, `activity_log`, view `vw_unified_work_items`; bottom-nav still uses legacy `NavView.orders` enum slot |
| `favorites` | Saved freelancers / favorite contacts | `FavoritesScreen` | Global `FavoritesViewModel` + local `.value` wrappers | `favorites` table |
| `home` | Home feed + filters coordination | `HomeScreen`, `FiltersModal` | Global `HomeViewModel` + global `TaskFilterViewModel` | Indirect via `TaskService` (`tasks`, `profiles`) |
| `management` | Work log / order management panel | `OrderManagementPanel` | Local `OrderManagementViewModel` | `work_logs` table |
| `notifications` | Notification stream, badge, modal UI | `NotificationsModal`, badge widget | Global `NotificationViewModel` | `notifications` table + realtime stream |
| `portfolio` | Portfolio CRUD + media uploads | `PortfolioScreen`, add/edit/detail sheets | Local `PortfolioViewModel` | `portfolio_items`, bucket `portfolio` |
| `profile` | Profile settings, public profile, avatar, related actions | `ProfileScreen`, `PublicProfileScreen`, settings/edit/manage screens | Global `ProfileViewModel` + local `PublicProfileViewModel` | `profiles`, `portfolio_items`, `portfolio`, `tasks`, bucket `avatars` |
| `proposals` | Proposal details modal UI (currently UI-centric) | `ProposalDetailsModal` | No feature VM observed | No direct Supabase usage observed in feature file |
| `saved` | Saved/bookmarked tasks | `SavedTasksScreen` | Global `SavedTasksViewModel` | `saved_tasks`, `profiles`, auth listener in VM |
| `search` | RPC-backed task/profile search | `SearchScreen` | Local `SearchViewModel` | RPCs `search_tasks`, `search_profiles`, tables `profiles`, `categories` |
| `services` | Service catalog/service listing support module | Widget-only UI in feature (`service_card`) | No feature VM observed | `services` table |
| `tasks` | Core task/tender flows, requests/offers, task images | `TendersScreen`, `CreateTaskScreen`, `TaskDetailsScreen`, request screens/sheets | Global `TaskViewModel`, `TaskFilterViewModel`; local `TaskRequestsViewModel` | `tasks`, `task_requests`, `profiles`, RPCs, bucket `task-images` |
| `wallet` | Wallet balances and transaction history UI | `WalletDashboardScreen`, `WalletScreen` | Global `WalletViewModel` | `wallet_balances`, `wallet_transactions` (docs mention broader ledger objects) |
| `work` | Unified work item execution/delivery/revision flows | `WorkItemDetailsScreen`, delivery/review/extension modals | Local `WorkItemDetailsViewModel` | `vw_unified_work_items`, `work_contracts`, `change_requests`, `extension_requests`, `bookings`, `profiles`, multiple RPCs |

## Per-Feature Audit Plans (Plan Only)

Each feature section below includes:

- Inventory scope (what to audit)
- Supabase surface (best-effort)
- `A`–`F` plan outline (references shared check IDs + feature-specific verifications)

---

## Feature: `auth`

### Inventory (Observed)

- Main folders: `lib/features/auth/data`, `lib/features/auth/view`, `lib/features/auth/viewmodels`
- Entry UI screens:
  - `LoginScreen` (app auth gate + `/login`)
  - `SignupScreen` (`/signup`)
  - `ForgotPasswordScreen`
- ViewModels/Controllers:
  - `AuthViewModel` (global provider; also locally provided in auth screens)
- Repositories/Services:
  - `AuthRepository`
- Models/DTOs:
  - none in feature folder (reuses Supabase auth/session objects)
- DB/Auth/RPC/Policies involved (best effort):
  - Supabase Auth methods (`signUp`, `signInWithPassword`, `resetPasswordForEmail`, `signOut`)
  - Table: `profiles`
  - Policies to verify later: `profiles` access/update policies (exact policy names to extract from DB/docs)

### A) Structure & Architecture

- Apply `A1`–`A6` to `lib/features/auth/**`.
- [ ] Verify auth UI widgets call `AuthViewModel` methods (or screen-level composition only), not raw Supabase auth/database APIs directly.
- [ ] Verify `AuthViewModel` subscription lifecycle for `auth.onAuthStateChange` (subscribe/dispose path is traceable and bounded).

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify all auth flows expose explicit loading/error/success states (login, signup, reset password) and the UI renders each state.
- [ ] Verify navigation side-effects after auth events are centralized/consistent (`/login`, `/main`, session expiry handling).

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify signup/profile creation flow does not rely solely on UI role selection for authorization.
- [ ] Verify password reset and session-expiry handling do not log sensitive data (email/token/session payloads).
- [ ] Verify no service-role usage or privileged key paths appear in auth feature/client code.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify auth screens do not rebuild broad subtrees on every field change unnecessarily.
- [ ] Verify auth transition UX for slow network conditions (loading indicators + duplicate submit prevention).

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify signup sequence assumptions (`auth.users` -> `profiles`) and retry/idempotency behavior are documented in audit notes.
- [ ] Verify session-expiry and logout state transitions cannot leave stale UI/provider state.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.
- [ ] Define post-fix verification flows: login, signup, password reset, logout, session expiry redirect.

---

## Feature: `booking`

### Inventory (Observed)

- Main folders: `lib/features/booking/data`, `lib/features/booking/models`, `lib/features/booking/services`, `lib/features/booking/view`, `lib/features/booking/viewmodels`
- Entry UI screens / sheets:
  - `BookingsDiscoveryScreen` (bottom-nav tab)
  - `AvailabilityScreen` (`/availability`)
  - `BookingsListScreen`
  - `BookingDetailsScreen`
  - `PaymentMethodScreen`
  - `AddSlotSheet`, `BookingSheet`
- ViewModels/Controllers:
  - `BookingViewModel` (global provider)
- Repositories/Services:
  - `BookingRepository`
  - `BookingService`
- Models/DTOs:
  - `BookingModel`
  - `SlotModel`
- DB/Auth/RPC/Policies involved (best effort):
  - Tables: `availability_slots`, `bookings`
  - Joined table references: `tasks`
  - RPC: `process_payment_event`
  - Code comments reference RLS ownership constraints (`provider_id = auth.uid()`, `client_id = auth.uid()`)
  - Docs/comments reference booking guard function/trigger behavior (to verify in DB/docs)

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify booking screens and sheets delegate booking mutations/status transitions to `BookingViewModel`/services instead of embedding business logic in UI callbacks.
- [ ] Verify payment/notification side effects remain below the ViewModel boundary (service/repository layer).

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify status mapping methods and repeated booking query shapes are centralized (or intentionally duplicated with rationale).
- [ ] Verify booking list/detail screens handle missing route arguments and invalid states consistently.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify booking create/update/approve/decline flows are backed by RLS/RPC expectations and not only UI role checks.
- [ ] Verify payment-event RPC call paths (`process_payment_event`) are documented with expected authorization contract and error handling.
- [ ] Verify notifications triggered from booking actions do not leak private booking details to non-participants.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify booking list pagination/query limits and refresh behavior are bounded (no unbounded fetch loops).
- [ ] Verify slot loading/reloading on availability screens avoids redundant duplicate queries after navigation returns.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify booking status transition assumptions (`pending/active/delivered/refunded/...`) are documented against service methods and docs.
- [ ] Verify slot overlap prevention is enforced server-side (RLS/function/constraint assumption documented) and not only UI-side.
- [ ] Verify payment/escrow status assumptions remain compatible with current schema/RPC contract.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.
- [ ] Define post-fix manual flows: create slot, book slot, provider accept/decline, deliver/approve/refund path checks.

---

## Feature: `categories`

### Inventory (Observed)

- Main folders: `lib/features/categories/data`, `lib/features/categories/models`, `lib/features/categories/services`, `lib/features/categories/view`, `lib/features/categories/viewmodels`
- Entry UI screens:
  - `CategoriesScreen` (`/categories`)
- ViewModels/Controllers:
  - `CategoriesViewModel` (screen-level provider observed)
- Repositories/Services:
  - `CategoriesRepository`
  - `CategoriesService`
- Models/DTOs:
  - `CategoryModel`
- DB/Auth/RPC/Policies involved (best effort):
  - Table: `categories`
  - Policies to verify later: read/update policies if categories are admin-managed

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify the screen does not bypass the repository/service path for category fetching.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify category mapping/parsing and fallback handling are centralized and reused.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify category write paths (if present) are role-restricted and not exposed unintentionally in client flows.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify category list loading/caching strategy is appropriate for app startup/filtering reuse.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify category ID/name assumptions remain compatible with task/search/profile features that reuse categories.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.

---

## Feature: `chat`

### Inventory (Observed)

- Main folders: `lib/features/chat/attachments`, `lib/features/chat/data`, `lib/features/chat/models`, `lib/features/chat/services`, `lib/features/chat/view`, `lib/features/chat/viewmodels`
- Entry UI screens / sheets:
  - `MessagesScreen` (bottom-nav tab)
  - `ChatScreen`
  - `CreateOfferSheet`
- ViewModels/Controllers:
  - `ChatViewModel` (global provider)
- Repositories/Services:
  - `ChatRepository`
  - `MessageService`
  - `AttachmentService`
  - attachment helper services (`compress_service`, `pick_image_service`, `upload_service`, `send_attachment_usecase`)
- Models/DTOs:
  - `ConversationModel`
  - `MessageModel`
  - attachment payload/errors models
- DB/Auth/RPC/Policies involved (best effort):
  - Tables: `conversations`, `messages`
  - RPCs: `start_task_conversation_v1`, `mark_conversation_delivered`, `mark_conversation_seen`
  - Realtime: streams on `messages`, `conversations`
  - Storage bucket: `chat-attachments`
  - Docs/logs mention chat attachment policies (exact names to confirm from DB/docs)

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify chat UI widgets (message tiles, compose actions, attachment widgets) delegate message send/receipt logic to ViewModel/service layers.
- [ ] Verify attachment upload/compress/pick logic stays out of core chat UI widgets except composition glue.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify message parsing/RPC result parsing paths are consistent across list/detail/realtime code paths.
- [ ] Verify realtime error handling/logging is consistent and non-silent for subscription failures.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify conversation/message read/write access assumptions are documented per action (create conversation, send, mark delivered/seen).
- [ ] Verify attachment upload path, bucket path construction, MIME validation, and signed URL usage are reviewed.
- [ ] Verify message/attachment logs do not emit sensitive payload content/URLs beyond what is intended.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify realtime subscription lifecycle and disposal on screen transitions (messages list vs chat detail).
- [ ] Verify message list rendering handles long conversations without full refetch on each update.
- [ ] Verify attachment thumbnail/signed URL caching behavior and expiration refresh strategy.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify message receipt state transitions (`sent` -> `delivered` -> `seen`) align with RPCs and UI indicators.
- [ ] Verify conversation creation idempotency assumptions in `start_task_conversation_v1` usage.
- [ ] Verify offer-message payload parsing compatibility for older/newer message schemas.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.
- [ ] Define post-fix manual flows: start conversation, send text, send attachment, receive realtime message, mark delivered/seen.

---

## Feature: `dashboard`

### Inventory (Observed)

- Main folders: `lib/features/dashboard/data`, `lib/features/dashboard/models`, `lib/features/dashboard/services`, `lib/features/dashboard/view`, `lib/features/dashboard/viewmodels`
- Entry UI screens:
  - `DashboardScreen` (bottom-nav tab)
  - internal tabs: `overview`, `bookings`, `work`, `manage`, `inbox`
- ViewModels/Controllers:
  - `DashboardViewModel` (global provider)
- Repositories/Services:
  - `DashboardRepository`
  - `mock_dashboard_repository.dart` (test/demo support path)
  - `DashboardPermissionService`
- Models/DTOs:
  - `DashboardCounters`, `WorkItem`, `ActivityLog`, `InboxTaskGroup`, etc.
- DB/Auth/RPC/Policies involved (best effort):
  - Tables/views: `profiles`, `activity_log`, `vw_unified_work_items`
  - Indirect dependencies on wallet/notifications/deep links (UI composition level)
  - Policies to verify later: aggregated view access and role-based visibility

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify dashboard tabs/widgets do not directly fetch Supabase data and rely on `DashboardViewModel` / repository methods.
- [ ] Verify mock repository usage is isolated and does not leak into production wiring unintentionally.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify dashboard view widgets stay presentation-only while action dispatch remains in ViewModel.
- [ ] Verify role-switch logic and tab composition remain readable and split appropriately.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify aggregated dashboard queries do not expose data across roles beyond allowed view/policy scope.
- [ ] Verify activity feed payload/logging avoids PII leakage in debug logs and UI traces.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify dashboard refresh paths avoid duplicate queries across tabs and widgets.
- [ ] Verify counters/cards/lists use bounded queries and efficient rebuild scopes.
- [ ] Verify cached dashboard data behavior (`DashboardCacheService`) is documented for cache invalidation checks.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify dashboard-derived status/action mappings align with source feature enums (`booking`, `work`, `tasks`).
- [ ] Verify aggregated view contract (`vw_unified_work_items`) fields match model parsing assumptions.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.
- [ ] Define post-fix flows: dashboard load, tab switch, refresh, primary action execution, deep-link navigation.

---

## Feature: `favorites`

### Inventory (Observed)

- Main folders: `lib/features/favorites/data`, `lib/features/favorites/models`, `lib/features/favorites/routes`, `lib/features/favorites/view`, `lib/features/favorites/viewmodels`
- Entry UI screens:
  - `FavoritesScreen`
  - Route helper: `/favorites`
- ViewModels/Controllers:
  - `FavoritesViewModel` (global provider; `.value` wrappers in feature screen)
- Repositories/Services:
  - `FavoritesService` (under `data/`)
- Models/DTOs:
  - `FavoriteModel`
- DB/Auth/RPC/Policies involved (best effort):
  - Table: `favorites`
  - Business-rule coupling: favorites may gate/directly support chat DM creation (to verify via code flows)
  - Policies to verify later: owner-only favorite rows

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify `FavoritesScreen` delegates add/remove/refresh behavior to `FavoritesViewModel`.
- [ ] Verify chat-navigation side effects from favorites remain UI orchestration only (not data mutation logic).

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify optimistic update/revert patterns (if implemented) are consistent and recover on failure.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify favorites data access is scoped to current user and no other users’ favorites are displayed through client-side filtering alone.
- [ ] Verify DM enablement logic is not treated as authorization in place of backend checks.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify favorites list reloads and avatar/image rendering are efficient and cached where applicable.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify duplicate favorite prevention assumptions (client + DB/RLS/constraint expectations) are documented.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.

---

## Feature: `home`

### Inventory (Observed)

- Main folders: `lib/features/home/view`, `lib/features/home/viewmodels`
- Entry UI screens/modals:
  - `HomeScreen` (bottom-nav tab and `/home`)
  - `FiltersModal`
- ViewModels/Controllers:
  - `HomeViewModel` (global provider)
  - feature coordination with global `TaskFilterViewModel` (from `tasks` feature)
- Repositories/Services:
  - none in feature folder (uses `TaskService` from `tasks`)
- Models/DTOs:
  - none in feature folder (uses `Task` model from `tasks`)
- DB/Auth/RPC/Policies involved (best effort):
  - Indirect via `TaskService`: task feed queries (`tasks`) + profile enrichment (`profiles`)

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify Home feature remains orchestration/presentation and task fetching logic stays in `TaskService`.
- [ ] Verify dual-ViewModel coordination (`HomeViewModel` + `TaskFilterViewModel`) remains explicit and bounded.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify pagination state (`cursor`, `hasMore`, loading flags) is encapsulated and consistently reset on refresh.
- [ ] Verify filter handoff logic avoids duplication with `TaskFilterViewModel`.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify home feed visibility assumptions (open/public tasks) are enforced by backend query/policy contracts, not only client filtering.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify infinite-scroll pagination avoids redundant loads and duplicate page fetches.
- [ ] Verify filter changes do not trigger unnecessary network refetches when local filtering is intended.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify task-feed ordering and cursor semantics remain stable with task creation/update changes.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.
- [ ] Define post-fix flows: home load, paginate, apply filters, refresh, navigate to task details.

---

## Feature: `management`

### Inventory (Observed)

- Main folders: `lib/features/management/models`, `lib/features/management/services`, `lib/features/management/view`, `lib/features/management/viewmodels`
- Entry UI panels:
  - `OrderManagementPanel`
- ViewModels/Controllers:
  - `OrderManagementViewModel`
- Repositories/Services:
  - `WorkLogService`
- Models/DTOs:
  - `WorkLogModel`
- DB/Auth/RPC/Policies involved (best effort):
  - Table: `work_logs`
  - Policies to verify later: who can read/create logs for a given entity/order

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify management panel UI does not perform raw work-log writes/reads outside ViewModel/service.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify work-log formatting/parsing and list rendering are centralized and reusable.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify work logs do not expose internal/private notes to unauthorized roles through client-only filtering.
- [ ] Verify entity ID handling is validated and not trusted solely from UI arguments.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify panel load/refresh is bounded and not repeatedly fetching logs on rebuilds.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify work-log append semantics and ordering assumptions are documented.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.

---

## Feature: `notifications`

### Inventory (Observed)

- Main folders: `lib/features/notifications/models`, `lib/features/notifications/services`, `lib/features/notifications/view`, `lib/features/notifications/viewmodels`
- Entry UI:
  - `NotificationsModal`
  - `NotificationBadgeButton`
- ViewModels/Controllers:
  - `NotificationViewModel` (global provider)
- Repositories/Services:
  - `NotificationService`
- Models/DTOs:
  - `NotificationModel`
- DB/Auth/RPC/Policies involved (best effort):
  - Table: `notifications`
  - Realtime stream on `notifications`
  - Policies to verify later: per-user notification row visibility and mutation permissions

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify modal/badge widgets remain presentation-only and notification IO stays in ViewModel/service.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify read/mark-all-as-read/update flows have consistent error handling and UI fallback behavior.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify notification payload fields shown/logged do not include sensitive data beyond intended message content.
- [ ] Verify notification mutations are enforced server-side for current user ownership.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify realtime subscription lifecycle for badge and modal does not create duplicate listeners.
- [ ] Verify notification list rendering and unread count updates avoid unnecessary full refetches.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify notification read/unread state transitions remain consistent across stream updates and manual actions.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.

---

## Feature: `orders` (decommissioned)

### Inventory (Observed)

- The standalone runtime feature was removed on 2026-03-01.
- `lib/features/orders/README.md` is the only remaining file in the folder.
- The live bottom-nav dashboard entry is `DashboardScreen` under the `dashboard` feature.

### Audit Note

- Do not schedule new audit or fix work against `orders` as a live feature.
- If future product work revives this surface, add it back as a new feature contract instead of reusing stale assumptions from the removed module.

---

## Feature: `portfolio`

### Inventory (Observed)

- Main folders: `lib/features/portfolio/data`, `lib/features/portfolio/models`, `lib/features/portfolio/services`, `lib/features/portfolio/view`, `lib/features/portfolio/viewmodels`
- Entry UI screens/sheets:
  - `PortfolioScreen`
  - `AddPortfolioSheet`
  - `EditPortfolioSheet`
  - `PortfolioDetailsSheet`
- ViewModels/Controllers:
  - `PortfolioViewModel` (screen-level provider observed)
- Repositories/Services:
  - `PortfolioRepository`
  - `PortfolioService`
- Models/DTOs:
  - `PortfolioItem`
- DB/Auth/RPC/Policies involved (best effort):
  - Table: `portfolio_items`
  - Storage bucket: `portfolio`
  - Public URL generation observed (`getPublicUrl`)
  - Policies to verify later: portfolio item ownership + bucket access rules

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify upload/delete/storage cleanup logic stays in service/repository layers, not sheet UI code.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify add/edit/detail sheets share validation/mapping logic consistently.
- [ ] Verify image placeholder and tile widgets remain presentation-only.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify upload MIME/type/size handling and storage path generation are reviewed for abuse cases.
- [ ] Verify public-vs-private portfolio media access assumptions match intended product rules and storage policies.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify portfolio grid/list image loading, caching, and scroll performance.
- [ ] Verify add/edit flows do not block UI excessively during compression/upload.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify delete flow data consistency between DB rows and storage objects (cleanup behavior assumptions documented).

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.
- [ ] Define post-fix flows: create/edit/delete item, upload image, view details, refresh list.

---

## Feature: `profile`

### Inventory (Observed)

- Main folders: `lib/features/profile/data`, `lib/features/profile/models`, `lib/features/profile/services`, `lib/features/profile/view`, `lib/features/profile/viewmodels`
- Entry UI screens/modals:
  - `ProfileScreen` (bottom-nav tab)
  - `PublicProfileScreen`
  - `EditProfileScreen`
  - `SettingsScreen`
  - `ManagePortfolioScreen`
  - `MyServicesScreen`
  - `ProfilePreviewModal`
- ViewModels/Controllers:
  - `ProfileViewModel` (global provider)
  - `PublicProfileViewModel`
  - `UserProfileViewModel`
- Repositories/Services:
  - `ProfileRepository`
  - `AvatarService`
- Models/DTOs:
  - `ProfileModel`
  - `FreelancerProfile`
  - `PublicProfile`
- DB/Auth/RPC/Policies involved (best effort):
  - Tables: `profiles`, `portfolio_items`, `portfolio`, `tasks`
  - Storage bucket: `avatars`
  - Auth operations: user email update, sign out, reset password
  - Signed URL creation for avatars
  - Policies to verify later: profile row ownership/public profile visibility/avatar bucket rules

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify profile screens and nested widgets delegate profile mutations/media operations to ViewModel/repository/service layers.
- [ ] Verify public-profile and private-profile flows remain separated by ViewModel/repository methods and not mixed in UI logic.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify profile module’s multiple screens/widgets do not duplicate profile field validation/mapping logic.
- [ ] Verify role-switch/settings/account actions share consistent error/loading feedback patterns.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify PII fields (email/profile metadata) are not over-logged in UI/repository/service layers.
- [ ] Verify avatar upload/signed URL generation paths and bucket policy assumptions are documented and reviewed.
- [ ] Verify role changes and account actions rely on backend authorization, not client role toggles only.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify profile/public profile screen rebuild scope and image loading performance.
- [ ] Verify signed-avatar refresh/caching behavior avoids repeated URL generation where cache should apply.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify profile/portfolio/task aggregation assumptions (cross-feature data shown on public profile) match current schema and nullability.
- [ ] Verify profile edits and avatar updates maintain consistent state across provider listeners and screens.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.
- [ ] Define post-fix flows: view/edit profile, upload avatar, open public profile, manage settings/logout/password reset.

---

## Feature: `proposals`

### Inventory (Observed)

- Main folders: `lib/features/proposals/view`
- Entry UI:
  - `ProposalDetailsModal`
- ViewModels/Controllers:
  - none observed in feature folder
- Repositories/Services:
  - none observed in feature folder
- Models/DTOs:
  - none observed in feature folder (uses inline `Map<String, dynamic>` mock/optional payload)
- DB/Auth/RPC/Policies involved (best effort):
  - No direct Supabase usage observed in feature file
  - Cross-feature navigation to `PublicProfileScreen`

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify this UI-only module stays presentation-only unless/until a dedicated ViewModel/service is introduced.
- [ ] Verify proposal payload parsing/typing plan is documented if this modal is intended for production data later.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify mock/default data usage is clearly isolated from production flow expectations.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify no privileged action or sensitive data exposure paths are introduced through this modal when connected to real proposal data later.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify modal scroll/layout behavior and navigation performance on smaller devices.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify future proposal payload contract assumptions are documented before backend binding.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.

---

## Feature: `saved`

### Inventory (Observed)

- Main folders: `lib/features/saved/data`, `lib/features/saved/models`, `lib/features/saved/routes`, `lib/features/saved/view`, `lib/features/saved/viewmodels`
- Entry UI screens:
  - `SavedTasksScreen`
  - Route helper: `/saved`
- ViewModels/Controllers:
  - `SavedTasksViewModel` (global provider)
- Repositories/Services:
  - `SavedTasksService` (under `data/`)
- Models/DTOs:
  - `SavedTaskModel`
- DB/Auth/RPC/Policies involved (best effort):
  - Tables: `saved_tasks`, `profiles`
  - Auth listener in ViewModel for state reset/sync
  - Policies to verify later: owner-only saved rows and task visibility joins

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify saved-task screens/widgets use `SavedTasksViewModel` methods only for CRUD/refresh operations.
- [ ] Verify auth-state subscription lifecycle in `SavedTasksViewModel` is bounded and cleaned up.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify optimistic toggle and refresh paths are consistent and recover from failures.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify saved rows and joined profile/task data are not exposed via client-only filtering assumptions.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify saved list refresh, pull-to-refresh, and badge/state syncing avoid duplicate fetches.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify duplicate-save prevention and unsave/delete semantics are documented against DB constraints/RLS expectations.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.

---

## Feature: `search`

### Inventory (Observed)

- Main folders: `lib/features/search/services`, `lib/features/search/view`, `lib/features/search/viewmodels`
- Entry UI screens:
  - `SearchScreen`
- ViewModels/Controllers:
  - `SearchViewModel` (screen-level provider observed)
- Repositories/Services:
  - `SearchService`
- Models/DTOs:
  - none feature-local (reuses `Task` and `ProfileModel`)
- DB/Auth/RPC/Policies involved (best effort):
  - RPCs: `search_tasks`, `search_profiles`
  - Tables for enrichment: `profiles`, `categories`
  - RPC policies/SECURITY DEFINER assumptions to verify later in DB metadata

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify search screen delegates all query execution and enrichment to `SearchViewModel`/`SearchService`.
- [ ] Verify RPC result enrichment logic remains in service layer (not UI).

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify task/profile search paths share pagination and error-handling patterns consistently.
- [ ] Verify RPC parsing assumptions are isolated and easy to adjust if return shape changes.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify user-controlled search input is passed via RPC params (not dynamic SQL string construction in client).
- [ ] Verify RPC authorization/policy assumptions are documented, including result visibility by role.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify debounce/throttling behavior (if any) and repeated search requests under fast typing.
- [ ] Verify offset/limit pagination avoids duplicate pages and handles empty results gracefully.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify enrichment joins (`profiles`, `categories`) stay compatible with RPC row schemas and missing-reference cases.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.
- [ ] Define post-fix flows: search tasks, search profiles, paginate, empty/error states, filter by role.

---

## Feature: `services`

### Inventory (Observed)

- Main folders: `lib/features/services/models`, `lib/features/services/services`, `lib/features/services/view`
- Entry UI:
  - no standalone screen observed in feature folder
  - reusable widget(s): `service_card.dart` (used by profile/service-management flows)
- ViewModels/Controllers:
  - none observed in feature folder
- Repositories/Services:
  - `ServicesService`
- Models/DTOs:
  - `ServiceModel`
- DB/Auth/RPC/Policies involved (best effort):
  - Table: `services`
  - Policies to verify later: freelancer ownership + visibility by status

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify this module’s reusable widget(s) stay presentation-focused and data mutations stay in `ServicesService` or consuming feature ViewModels.
- [ ] Verify absence of a dedicated ViewModel is intentional and not causing UI -> service coupling in consuming screens.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify create/update/status methods in `ServicesService` share consistent return/error semantics.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify service create/update status actions are constrained by backend ownership/role policies.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify service list/card rendering and refresh behavior in consuming features (especially profile) are efficient.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify service status values and transitions are documented and consistent with any profile/dashboard displays.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.

---

## Feature: `tasks`

### Inventory (Observed)

- Main folders: `lib/features/tasks/data`, `lib/features/tasks/models`, `lib/features/tasks/services`, `lib/features/tasks/view`, `lib/features/tasks/viewmodels`
- Entry UI screens/sheets:
  - `TendersScreen` (bottom-nav tab)
  - `CreateTaskScreen` (FAB from main nav shell)
  - `TaskDetailsScreen`
  - `RequestsListScreen`
  - `SubmitRequestSheet`
- ViewModels/Controllers:
  - `TaskViewModel` (global provider)
  - `TaskFilterViewModel` (global provider)
  - `TaskRequestsViewModel` (local provider)
- Repositories/Services:
  - `TaskRepository`
  - `TaskService`
  - `TaskRequestsService`
  - `TaskImageService`
- Models/DTOs:
  - `TaskModel`
  - `TaskRequestModel`
- DB/Auth/RPC/Policies involved (best effort):
  - Tables: `tasks`, `task_requests`, `profiles`
  - RPCs (observed across task services): `accept_task_request`, `replace_task_request`, `reject_task_request`
  - Storage bucket: `task-images`
  - Feature flows navigate into booking (`/availability`) and chat integrations
  - Code comments reference RLS policy names for task requests in some paths (to verify against DB/docs)

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify task screens (especially create/details/requests widgets/sheets) delegate task CRUD/offer actions to ViewModel/services.
- [ ] Verify task image upload/delete/signed URL logic remains in `TaskImageService`.
- [ ] Verify mixed-feature orchestration (tasks -> booking/chat/categories) preserves dependency direction and avoids service calls from deep UI widgets.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify large task service methods are partitioned/organized clearly enough for safe auditing (query, mapping, mutations, RPCs).
- [ ] Verify repeated task select strings/model mapping logic is centralized or tracked as duplication candidates.
- [ ] Verify request/offer handling methods use consistent error mapping and user feedback.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify task create/edit/delete/update actions rely on backend ownership/RLS, not UI ownership checks alone.
- [ ] Verify task request/offer accept/reject/replace actions document RPC authorization expectations and fallback behavior when RLS blocks direct updates.
- [ ] Verify task image upload path, file validation, bucket paths, and signed URL exposure rules.
- [ ] Verify any direct Supabase references inside `view/` files are reviewed and classified as composition vs boundary violations during audit execution.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify task list/tender list pagination and filtering avoid duplicate network calls and excessive rebuilds.
- [ ] Verify task detail loading + request list/open sheet flows avoid redundant refetch loops.
- [ ] Verify task image loading, signed URL refresh, and cache usage for lists/detail pages.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify task status transitions and offer acceptance/rejection semantics align across `TaskService`, `TaskRequestsService`, `Orders`, and `Dashboard`.
- [ ] Verify one-offer-per-bidder and assignment assumptions are enforced server-side and reflected correctly in client state.
- [ ] Verify model parsing handles schema drift (missing fields/new enums) safely.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.
- [ ] Define post-fix flows: create task, browse tenders, open details, submit/replace/withdraw request, accept/reject offer, upload/remove image.

---

## Feature: `wallet`

### Inventory (Observed)

- Main folders: `lib/features/wallet/data`, `lib/features/wallet/models`, `lib/features/wallet/services`, `lib/features/wallet/view`, `lib/features/wallet/viewmodels`
- Entry UI screens:
  - `WalletDashboardScreen` (bottom-nav tab)
  - `WalletScreen`
- ViewModels/Controllers:
  - `WalletViewModel` (global provider)
- Repositories/Services:
  - `WalletRepository`
  - `WalletService`
- Models/DTOs:
  - `WalletBalanceModel`
  - `WalletTransactionModel`
- DB/Auth/RPC/Policies involved (best effort):
  - Tables: `wallet_balances`, `wallet_transactions`
  - README/docs mention broader ledger system objects (`accounts`, `journal_entries`, `ledger_lines`) and payment RPC/engine concepts; confirm active code paths during audit
  - Policies to verify later: account ownership / transaction visibility

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify wallet screens delegate all balance/history loading and future payment actions to ViewModel/service layers.
- [ ] Verify wallet service/repository responsibilities are clearly separated (querying vs mapping vs domain behavior).

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify monetary formatting/parsing and error handling are consistent across wallet UI/service layers.
- [ ] Verify transaction list loading paths are bounded and reusable.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify wallet data visibility is fully server-enforced (RLS) and not assumed from `auth.currentUser` filters only.
- [ ] Verify financial values/transactions are not over-logged.
- [ ] Verify any payment-service/demo-payment hooks are inventoried for privileged action boundaries.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify wallet dashboard and transaction history rendering/caching/refresh behavior under larger histories.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify balance/transaction consistency assumptions and ordering semantics (latest-first, duplicate prevention) are documented.
- [ ] Verify code-vs-doc ledger object mismatch (if any) is recorded as a contract verification task, not a finding, until audit execution.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.
- [ ] Define post-fix flows: load balance, view transactions, refresh, error/empty states.

---

## Feature: `work`

### Inventory (Observed)

- Main folders: `lib/features/work/models`, `lib/features/work/services`, `lib/features/work/view`, `lib/features/work/viewmodels`
- Entry UI screens/modals:
  - `WorkItemDetailsScreen`
  - `SubmitDeliveryModal`
  - `ReviewDeliveryModal`
  - `RequestExtensionModal`
- ViewModels/Controllers:
  - `WorkItemDetailsViewModel` (screen-level provider observed)
- Repositories/Services:
  - `WorkManagementService`
- Models/DTOs:
  - `UnifiedWorkItemModel`
  - `WorkContractModel`
  - `ChangeRequestModel`
  - `ExtensionRequestModel`
- DB/Auth/RPC/Policies involved (best effort):
  - View/table refs: `vw_unified_work_items`, `work_contracts`, `change_requests`, `extension_requests`, `bookings`, `profiles`
  - RPCs: `rpc_submit_delivery`, `rpc_request_revision`, `rpc_approve_delivery`, `rpc_accept_change_request`
  - Code comments reference booking guard trigger/function behavior (verify in DB/docs)
  - Policies to verify later: participant-only access to work items and change/extension requests

### A) Structure & Architecture

- Apply `A1`–`A6`.
- [ ] Verify work modals/screens delegate all status-changing operations to `WorkManagementService` via ViewModel.
- [ ] Verify complex cross-entity logic (bookings/contracts/change requests/extensions) remains in service/domain layer, not UI.

### B) Code Quality & Maintainability

- Apply `B1`–`B7`.
- [ ] Verify work service methods are organized by action type and error handling is consistent across RPC/direct-update paths.
- [ ] Verify UI state for multi-action workflows (deliver/revise/approve/extend) is explicit and testable.

### C) Security & Privacy

- Apply `C1`–`C8`.
- [ ] Verify delivery/revision/approval RPCs document required participant roles and backend authorization expectations.
- [ ] Verify work-item data visibility (including change/extension requests) is not trusted to client-side role checks alone.
- [ ] Verify notes/messages in work flows are not over-logged if they may contain sensitive project content.

### D) Performance & UX

- Apply `D1`–`D5`.
- [ ] Verify work-item detail loading aggregates data efficiently (view + related tables) without redundant fetch chains.
- [ ] Verify modal actions prevent duplicate submissions on slow networks.

### E) Data Integrity & Domain Logic

- Apply `E1`–`E5`.
- [ ] Verify unified work status transitions align across booking/task/work entities and RPC side effects.
- [ ] Verify extension/change request lifecycle assumptions (creation, acceptance, approvals) are documented against DB schema/RPC contracts.
- [ ] Verify direct booking updates inside work flows remain consistent with booking feature status semantics.

### F) Fix Strategy Blueprint (No Changes Yet)

- Apply `F1`–`F5`.
- [ ] Define post-fix flows: open work item, submit delivery, request revision, approve delivery, request/accept extension/change.

## Notes for Next Phase

- This file intentionally stops at planning.
- Actual feature auditing should produce findings/evidence per feature only after you choose the first target feature.
