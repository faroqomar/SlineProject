# Corrected Plan: Home Discovery Navigation Consolidation

## 0. Plan Status

- Gate status: conditional pass after this rewrite.
- Original plan status: fail.
- Reason original failed: it identified the correct files but left execution choices open around navigation source of truth, hidden Wallet handling, duplicate `All` chips, stale index normalization, test harness prerequisites, and UI audit criteria.
- Corrected execution rule: implement the navigation contract first, then the Home UI, then test rewrites, then visual and regression audit.

## 1. Locked Product Decision

Primary Agents: `@Product`, `@Architect`

### Decision

- Bottom navigation will show exactly four destinations:
  - Home
  - Dashboard
  - Messages
  - Profile
- Tenders and Bookings become Home discovery mode chips below the search/filter row.
- Wallet remains out of the bottom navigation and must not be added as part of this change.
- Standalone `TendersScreen` and `BookingsDiscoveryScreen` remain in the codebase for now, but they are no longer bottom-nav destinations.
- The Home discovery row label set is:
  - `All Work`
  - `Bookings`
  - `Tenders`

### Why

- The user specifically asked to remove Tenders and Bookings from the bottom navigation and place them on Home.
- `All Work` prevents ambiguity with the existing category-row `All` chip.
- Keeping standalone discovery screens avoids unnecessary decommissioning risk.

## 2. Non-Negotiable Invariants

- `@Architect`: No View imports or calls Supabase directly.
  - Enforce: Home mode switching must filter already-loaded `TaskFilterViewModel.filteredTasks`.
  - Verify: `rg -n "Supabase|SupabaseClient|from\\(" lib/features/home/view lib/core/widgets/custom_bottom_nav_bar.dart lib/app/main_navigation_screen.dart`
- `@Architect`: No ViewModel gains direct Supabase access for this change.
  - Enforce: do not edit `HomeViewModel` for mode state.
  - Verify: git diff contains no Supabase import additions in Home/navigation ViewModels.
- `@Supabase_Ops`: No database, RLS, RPC, trigger, storage, or migration changes.
  - Enforce: no files under `supabase/migrations`, `supabase/functions`, or `supabase/scripts` are edited.
  - Verify: `git diff --name-only | rg "^supabase/"` returns no implementation changes.
- `@Executor`: Navigation indexes must not drift.
  - Enforce: use named visible-nav indices/constants instead of scattered literals.
  - Verify: stale index grep passes.
- `@Executor`: `AppLogger` remains the logging mechanism.
  - Enforce: no `print()` additions.
  - Verify: `git diff | rg "print\\("` returns no hits.
- `@Pixel`: Text and tap targets must fit on narrow mobile widths.
  - Enforce: chips in horizontal scroll row, stable keys, bounded spacing.
  - Verify: widget tests plus manual visual audit.
- `@Sentinel`: Existing discovery behavior remains available.
  - Enforce: standalone discovery screen tests remain passing unless a later decommission plan removes those screens.
  - Verify: `flutter test test/widget/tasks/tenders_screen_test.dart test/widget/booking/bookings_discovery_screen_test.dart`

## 3. Evidence From Scans

- `@Planner`: `lib/core/widgets/custom_bottom_nav_bar.dart:47-91` currently builds six visible items: Home, Tenders, Bookings, Dashboard, Messages, Profile.
- `@Planner`: `lib/app/main_navigation_screen.dart:130-140` currently builds seven screens: Home, Tenders, Bookings, Dashboard, Messages, Profile, Wallet.
- `@Planner`: `lib/app/main_navigation_screen.dart:142-146` incorrectly ties screen count to `NavView.values.length`, which includes hidden Wallet and legacy entries.
- `@Planner`: `lib/app/main_navigation_screen.dart:217-220` directly indexes `screens[currentIndex]`.
- `@Planner`: `lib/core/app_enums.dart:8` contains `NavView { home, tender, booking, orders, messages, profile, wallet }`.
- `@Planner`: `lib/features/home/view/home_screen.dart:162-219` renders search/filter, and `221-248` renders category chips.
- `@Planner`: `lib/features/home/view/home_screen.dart:258-291` renders `DiscoveryTaskSliver` from `filterController.filteredTasks`.
- `@Planner`: `lib/features/tasks/view/tenders_screen.dart` already filters `task.isTender`.
- `@Planner`: `lib/features/booking/view/bookings_discovery_screen.dart` already filters `task.isBooking`.
- `@Planner`: `lib/features/profile/services/profile_deep_link_handler.dart:24-29` hardcodes Profile index `5`.
- `@Planner`: `test/core/widgets/custom_bottom_nav_bar_test.dart:21-32` expects six nav items.
- `@Planner`: `test/widget/app/main_navigation_screen_test.dart:19-37` uses seven stub screens.
- `@Planner`: `test/integration_test/create_tender_task_flow_test.dart:96-105` uses `CustomBottomNavBar.tendersNavKey`.
- `@Supabase_Ops`: `supabase status` failed because Docker was unavailable.
- `@Supabase_Ops`: `supabase migration list` reached the remote database and showed local/remote migration drift.
- `@Supabase_Ops`: This plan must remain UI/navigation-only.

## 4. Gate-Based Execution Plan

### Phase 0: Test Infrastructure Gate

Primary Agents: `@Sentinel`, `@Executor`

Goal: prevent late failures from missing widget harness assumptions, unstable integration selectors, or stale test helpers.

Why: this change rewires bottom navigation and modifies Home widget behavior; tests that depend on old nav keys will fail unless selectors and fixtures are prepared first.

How:

#### 0.1 Confirm test harness files

- `@Sentinel`: Open `test/test_support/pump_app.dart`.
- `@Sentinel`: Confirm it provides `MaterialApp`, theme, providers, and navigator observer support needed by existing widget tests.
- `@Sentinel`: Open `test/widget/home/home_screen_test.dart`.
- `@Sentinel`: Confirm mocked `HomeViewModel`, `TaskFilterViewModel`, `ProfileViewModel`, `NotificationViewModel`, and `SavedTasksViewModel` setup still supports Home with new local UI state.
- `@Sentinel`: Open `test/integration_test/support/helpers.dart`.
- `@Sentinel`: Confirm helper functions can tap Home-screen keys after the Tenders nav key is removed.

#### 0.2 Define stable selectors before UI implementation

- `@Executor`: Add planned static keys to Home in implementation phase:
  - `HomeScreen.discoveryAllWorkKey`
  - `HomeScreen.discoveryBookingsKey`
  - `HomeScreen.discoveryTendersKey`
- `@Sentinel`: Update tests to use these keys, not text-only finders, where the interaction is navigation-critical.

#### 0.3 Define deterministic Home filtering test fixture

- `@Sentinel`: Inspect existing task model test fixtures.
- `@Sentinel`: If there is an existing lightweight `Task` fixture builder, reuse it.
- `@Sentinel`: If no builder exists, add a local helper in `home_screen_test.dart` that constructs one tender task and one booking task using the minimum required `Task` fields.
- `@Sentinel`: Do not add backend fixtures for this UI-only change.

Result: the executor knows exactly which tests and keys must exist before the implementation is considered testable.

GATE CHECK:

- `@Sentinel`: PASS only if Home discovery keys are planned, test fixture strategy is known, and integration selector replacement is explicit.

### Phase 1: Navigation Contract Gate

Primary Agents: `@Architect`, `@Executor`

Goal: create a single visible-nav contract that cannot drift between the bottom nav, main shell, and deep links.

Why: the old implementation uses rendered list positions as navigation state, and the old enum includes hidden/legacy entries.

How:

#### 1.1 Add visible destination constants

- `@Executor`: Create a small private or shared visible-nav index contract.
- `@Architect`: Preferred file: `lib/core/navigation/main_nav_destinations.dart` if adding a shared file is clean.
- `@Architect`: Acceptable fallback: constants colocated in `main_navigation_screen.dart` and imported by `custom_bottom_nav_bar.dart` only if a new file is excessive.
- `@Executor`: Define:
  - `home = 0`
  - `dashboard = 1`
  - `messages = 2`
  - `profile = 3`
  - `visibleCount = 4`
- `@Executor`: Do not use `NavView.values.length` as the visible-nav count.

#### 1.2 Define visible destination metadata

- `@Executor`: Build a destination list containing:
  - Home: key `CustomBottomNavBar.homeNavKey`, label `Home`, icons `home_outlined`/`home`
  - Dashboard: key `CustomBottomNavBar.dashboardNavKey`, label `Dashboard`, icons `dashboard_outlined`/`dashboard`
  - Messages: key `CustomBottomNavBar.messagesNavKey`, label `Messages`, icons `message_outlined`/`message`, notification badge enabled
  - Profile: key `CustomBottomNavBar.profileNavKey`, label `Profile`, icons `person_outline`/`person`
- `@Executor`: Remove Tenders and Bookings from the visible metadata list.
- `@Executor`: Remove or deprecate `tendersNavKey` and `bookingsNavKey`.
- `@Architect`: Preferred: remove the keys after all references are replaced so no code can target hidden nav destinations.

#### 1.3 Normalize stale indexes

- `@Executor`: Clamp `NavigationProvider.currentIndex` before indexing into the screen list.
- `@Executor`: If an index is outside `0..3`, render Home.
- `@Executor`: Log stale index normalization with `AppLogger.w`.
- `@Executor`: Schedule `navigationProvider.setCurrentIndex(0)` in a post-frame callback only when the incoming value is invalid.
- `@Executor`: Avoid calling `setCurrentIndex` synchronously during build.

Result: all visible navigation consumers share the same four-destination contract.

GATE CHECK:

- `@Sentinel`: Run `rg -n "NavView\\.tender|NavView\\.booking|NavView\\.wallet|NavView\\.values\\.length|setCurrentIndex\\(5\\)|index 5" lib test integration_test`.
- `@Sentinel`: PASS only if any remaining hits are documented non-runtime references or intentionally untouched standalone screens.

### Phase 2: Main Shell Implementation

Primary Agents: `@Executor`, `@Architect`

Goal: make `MainNavigationScreen` host only the four visible bottom-nav screens.

Why: bottom-nav item removal is unsafe unless the active-screen list is updated in the same patch.

How:

#### 2.1 Update imports

- `@Executor`: Remove `BookingsDiscoveryScreen` import from `lib/app/main_navigation_screen.dart`.
- `@Executor`: Remove `TendersScreen` import from `lib/app/main_navigation_screen.dart`.
- `@Executor`: Remove `WalletDashboardScreen` import from `lib/app/main_navigation_screen.dart` unless another still-valid code path in the file uses it.
- `@Executor`: Keep `HomeScreen`, `DashboardScreen`, `MessagesScreen`, `ProfileScreen`, and `CreateTaskScreen`.

#### 2.2 Update default screen list

- `@Executor`: Replace the default screen list with:
  - `HomeScreen()`
  - `DashboardScreen()`
  - `MessagesScreen()`
  - `ProfileScreen()`
- `@Executor`: Keep the `widget.screens` override for tests.
- `@Executor`: Validate overridden screen list against the visible-nav count, not `NavView.values.length`.
- `@Executor`: Log a warning if overridden screen count differs from visible count.

#### 2.3 Update active screen indexing

- `@Executor`: Compute `rawIndex = navigationProvider.currentIndex`.
- `@Executor`: Compute `activeIndex = rawIndex.clamp(0, screens.length - 1)`.
- `@Executor`: Use `activeIndex` for `ValueKey<int>` and `screens[activeIndex]`.
- `@Executor`: Use `activeIndex` for transition direction comparison.
- `@Executor`: Preserve the FAB animation and runtime banner behavior.

Result: main navigation can no longer open old Tenders/Bookings tabs via visible bottom-nav positions.

GATE CHECK:

- `@Sentinel`: Widget test must prove index `1` opens Dashboard.
- `@Sentinel`: Widget test must prove stale index does not crash.

### Phase 3: Bottom Navigation Implementation

Primary Agents: `@Executor`, `@Pixel`

Skill: frontend-design

Goal: render a balanced four-item bottom navigation bar.

Why: the user's main UX request is freeing space in the bottom nav.

How:

#### 3.1 Remove visible secondary destinations

- `@Executor`: Edit `lib/core/widgets/custom_bottom_nav_bar.dart`.
- `@Executor`: Remove `_NavItem` entries for `Tenders`.
- `@Executor`: Remove `_NavItem` entries for `Bookings`.
- `@Executor`: Remove `tendersNavKey` and `bookingsNavKey` if all references are updated in the same patch.
- `@Executor`: Keep the deprecated `ordersNavKey` alias only if existing tests still depend on it; otherwise leave unchanged because it aliases Dashboard.

#### 3.2 Preserve behavior

- `@Executor`: Keep haptic feedback on tap.
- `@Executor`: Keep `AppLogger.i` nav tap logging.
- `@Executor`: Keep notification badge behavior for Messages.
- `@Executor`: Keep Semantics label, selected state, and button role.

#### 3.3 Audit layout

- `@Pixel`: Verify four labels fit within `AppLayout.bottomNavHeight`.
- `@Pixel`: Verify item width and label opacity still look intentional.
- `@Pixel`: Verify the Create Task FAB does not hide Profile or Messages.
- `@Pixel`: Do not change the color palette.
- `@Pixel`: Do not introduce nested cards or decorative backgrounds.

Result: bottom nav contains only primary destinations and keeps the existing visual language.

GATE CHECK:

- `@Sentinel`: `custom_bottom_nav_bar_test.dart` must assert Tenders and Bookings are absent.
- `@Pixel`: Manual or screenshot audit must be recorded in the session log during execution.

### Phase 4: Home Discovery Mode UI

Primary Agents: `@Executor`, `@Pixel`, `@Architect`

Skill: frontend-design

Goal: add Tenders and Bookings as Home discovery controls below the search/filter row.

Why: users still need fast access to these discovery modes after they leave the bottom nav.

How:

#### 4.1 Add Home state and keys

- `@Executor`: Add static keys to `HomeScreen`:
  - `discoveryAllWorkKey`
  - `discoveryBookingsKey`
  - `discoveryTendersKey`
- `@Executor`: Add private enum `_HomeDiscoveryMode`.
- `@Executor`: Add local state `_selectedDiscoveryMode = _HomeDiscoveryMode.allWork`.
- `@Architect`: Keep this state in the View because it is presentation filtering over already-loaded ViewModel data.

#### 4.2 Add display metadata

- `@Executor`: Add a private helper that returns label, semantic label, icon, and empty-state metadata for each mode.
- `@Executor`: Use:
  - `All Work` with `Icons.work_outline`
  - `Bookings` with `Icons.calendar_today_outlined`
  - `Tenders` with `Icons.assignment_outlined`
- `@Executor`: Use empty titles:
  - `No tasks found`
  - `No booking services`
  - `No active tenders`

#### 4.3 Render chips below search

- `@Pixel`: Insert the discovery chip row after the search/filter row and before the category row.
- `@Pixel`: Use a horizontally scrolling row.
- `@Pixel`: Use compact pill styling aligned with `_buildCategoryChip`.
- `@Pixel`: Keep spacing stable:
  - one gap after search row
  - one gap between discovery row and category row
- `@Pixel`: Use icons only if they fit cleanly; otherwise keep text chips consistent with existing category chips.
- `@Pixel`: Do not add explanatory copy.

#### 4.4 Apply filtering

- `@Executor`: Compute `visibleTasks` inside the Consumer builder.
- `@Executor`: For `All Work`, use `filterController.filteredTasks`.
- `@Executor`: For `Bookings`, use `filterController.filteredTasks.where((task) => task.isBooking).toList()`.
- `@Executor`: For `Tenders`, use `filterController.filteredTasks.where((task) => task.isTender).toList()`.
- `@Executor`: Pass `visibleTasks` to `DiscoveryTaskSliver`.
- `@Executor`: Keep `homeViewModel.loadMoreTasks(...)` unchanged.
- `@Architect`: Do not add new service or repository calls.

#### 4.5 Add interaction behavior

- `@Executor`: On chip tap, call `AppInteractionStates.hapticSelection()`.
- `@Executor`: On chip tap, update local state with `setState`.
- `@Executor`: Log mode change through `AppLogger.d` with `surface: home` and `mode`.
- `@Executor`: Mark active chip through Semantics `selected: true`.

#### 4.6 Audit UX edge cases

- `@Pixel`: Confirm duplicate `All` ambiguity is avoided by using `All Work`.
- `@Pixel`: Confirm chip text fits at small widths.
- `@Pixel`: Confirm category chips remain accessible after the new row is added.
- `@Pixel`: Confirm selected state is visible in light and dark themes.

Result: Home now hosts the removed discovery destinations below search with no new backend access.

GATE CHECK:

- `@Sentinel`: Home widget tests must find all three discovery chips.
- `@Sentinel`: Home widget tests must verify mode selection and filtered rendering.

### Phase 5: Deep Links and Stale Reference Cleanup

Primary Agents: `@Executor`, `@Sentinel`, `@Architect`

Goal: remove old navigation index assumptions from runtime code and tests.

Why: a hidden hardcoded index will send users to the wrong tab after the nav order changes.

How:

#### 5.1 Update profile deep link

- `@Executor`: Edit `lib/features/profile/services/profile_deep_link_handler.dart`.
- `@Executor`: Replace `setCurrentIndex(5)` with the named Profile visible-nav index.
- `@Executor`: Update the comment to say Profile is the visible Profile destination, not "index 5".

#### 5.2 Search stale runtime references

- `@Sentinel`: Run `rg -n "tendersNavKey|bookingsNavKey|setCurrentIndex\\([456]\\)|index [456]|NavView\\.tender|NavView\\.booking|WalletDashboardScreen" lib test integration_test`.
- `@Executor`: Remove or update every stale reference created by this nav consolidation.
- `@Architect`: Leave standalone screen class names alone if they are not bottom-nav references.

#### 5.3 Confirm no direct nav bypass remains

- `@Sentinel`: Run `rg -n "BottomNav|bottom_nav_tenders|bottom_nav_bookings|Tenders list surface|Bookings list surface" test integration_test lib`.
- `@Executor`: Update comments and test names that still describe Tenders/Bookings as bottom-nav tabs.

Result: runtime and test code agree on the new navigation model.

GATE CHECK:

- `@Sentinel`: PASS only when stale references are removed or explicitly documented as standalone-screen tests.

### Phase 6: Test Rewrite and New Coverage

Primary Agents: `@Sentinel`, `@Executor`

Skill: flutter-testing

Goal: make tests enforce the new UX instead of preserving old Tenders/Bookings tabs.

Why: without test updates, future changes can accidentally reintroduce hidden nav items or break Home discovery modes.

How:

#### 6.1 Bottom nav tests

- `@Sentinel`: Update `test/core/widgets/custom_bottom_nav_bar_test.dart`.
- `@Sentinel`: Rename "renders 6 navigation items" to "renders 4 primary navigation items".
- `@Sentinel`: Assert Home, Dashboard, Messages, and Profile are present.
- `@Sentinel`: Assert Tenders and Bookings are absent.
- `@Sentinel`: Keep no-BackdropFilter test.
- `@Sentinel`: Keep Semantics test.
- `@Sentinel`: Update tap test to verify the provider index changes to Profile's named index.

#### 6.2 Main navigation tests

- `@Sentinel`: Update `_stubScreens()` to four screens.
- `@Sentinel`: Update index-change test so `setCurrentIndex(1)` renders Dashboard.
- `@Sentinel`: Update dashboard test to expect Dashboard at named Dashboard index.
- `@Sentinel`: Add stale-index test:
  - create provider
  - call `setCurrentIndex(6)`
  - pump shell
  - expect no exception
  - expect Home or normalized active screen

#### 6.3 Home tests

- `@Sentinel`: Update `test/widget/home/home_screen_test.dart`.
- `@Sentinel`: Add assertion that `HomeScreen.discoveryAllWorkKey`, `HomeScreen.discoveryBookingsKey`, and `HomeScreen.discoveryTendersKey` are present.
- `@Sentinel`: Add test that tapping Bookings selects Bookings.
- `@Sentinel`: Add test that tapping Tenders selects Tenders.
- `@Sentinel`: Add fixture-backed test that Bookings mode shows booking task and hides tender task.
- `@Sentinel`: Add fixture-backed test that Tenders mode shows tender task and hides booking task.
- `@Sentinel`: Keep search delegation test.
- `@Sentinel`: Keep pull-to-refresh test.

#### 6.4 Standalone discovery tests

- `@Sentinel`: Keep `test/widget/tasks/tenders_screen_test.dart` passing.
- `@Sentinel`: Keep `test/widget/booking/bookings_discovery_screen_test.dart` passing.
- `@Sentinel`: Do not rewrite standalone screen tests to bottom-nav behavior.

#### 6.5 Integration test

- `@Sentinel`: Update `test/integration_test/create_tender_task_flow_test.dart`.
- `@Sentinel`: Replace `CustomBottomNavBar.tendersNavKey` tap with:
  - tap `CustomBottomNavBar.homeNavKey`
  - wait for `HomeScreen.searchFieldKey`
  - enter marker
  - tap `HomeScreen.discoveryTendersKey`
  - wait for marker in the Home feed
- `@Sentinel`: Update test comments from "Tenders list surface" to "Home Tenders discovery mode".
- `@Sentinel`: Keep task-details assertion unchanged.

Result: test suite protects the new navigation and Home discovery behavior.

GATE CHECK:

- `@Sentinel`: PASS only after targeted tests pass locally or skip reasons are recorded for integration environment gaps.

### Phase 7: Static Verification

Primary Agents: `@Sentinel`, `@Executor`

Goal: catch analyzer, formatting, dead import, and stale-reference failures before manual QA.

Why: navigation changes often leave unused imports and outdated test helpers.

How:

#### 7.1 Format changed files

- `@Sentinel`: Run `dart format` on every changed Dart file.
- `@Sentinel`: Include app files and updated test files.

#### 7.2 Analyze

- `@Sentinel`: Run `flutter analyze`.
- `@Executor`: Fix all new analyzer errors.
- `@Executor`: Fix all unused imports introduced by removing old screens from main navigation.

#### 7.3 Grep invariants

- `@Sentinel`: Run `rg -n "tendersNavKey|bookingsNavKey|setCurrentIndex\\(5\\)|index 5|NavView\\.values\\.length" lib test integration_test`.
- `@Sentinel`: Run `git diff --name-only | rg "^supabase/"`.
- `@Sentinel`: Run `git diff | rg "print\\("`.
- `@Executor`: Fix any unexpected hits.

Result: no static or obvious architecture regressions remain.

GATE CHECK:

- `@Sentinel`: PASS only if format, analyze, and invariant grep checks pass.

### Phase 8: Visual, Accessibility, and Responsive Audit

Primary Agents: `@Pixel`, `@Sentinel`

Skill: frontend-design

Goal: verify the actual rendered experience, not just widget tree behavior.

Why: the user's reference is visual, and chip/nav density issues can pass widget tests while still looking wrong.

How:

#### 8.1 Launch app

- `@Executor`: Start the app using the project's normal local run target.
- `@Pixel`: If Flutter web is configured, inspect via browser tooling.
- `@Pixel`: If only mobile simulator is available, inspect there and record viewport/device.

#### 8.2 Bottom-nav audit

- `@Pixel`: Confirm only Home, Dashboard, Messages, Profile render.
- `@Pixel`: Confirm labels do not clip.
- `@Pixel`: Confirm the FAB does not overlap the Profile label.
- `@Pixel`: Confirm tap targets are usable.

#### 8.3 Home audit

- `@Pixel`: Confirm discovery chips appear directly below search/filter.
- `@Pixel`: Confirm the category row still appears below discovery chips.
- `@Pixel`: Confirm `All Work`, `Bookings`, and `Tenders` states are visually distinct.
- `@Pixel`: Confirm selected state is visible.
- `@Pixel`: Confirm text does not overflow on narrow width.

#### 8.4 Accessibility audit

- `@Sentinel`: Confirm Semantics exist for all bottom-nav items.
- `@Sentinel`: Confirm Semantics selected state exists for the active discovery chip.
- `@Sentinel`: Confirm the discovery chips are reachable by key in widget tests.

Result: visual behavior matches the user's requested structure.

GATE CHECK:

- `@Pixel`: PASS only after recording the audit result in the session log.

### Phase 9: Release QA and Rollback Readiness

Primary Agents: `@Sentinel`, `@DocsSync`, `@Executor`

Goal: finish with explicit verification evidence and a rollback path.

Why: the change affects app navigation, a high-visibility surface.

How:

#### 9.1 Targeted test commands

- `@Sentinel`: Run:
  - `flutter test test/core/widgets/custom_bottom_nav_bar_test.dart`
  - `flutter test test/widget/app/main_navigation_screen_test.dart`
  - `flutter test test/widget/home/home_screen_test.dart`
  - `flutter test test/widget/tasks/tenders_screen_test.dart`
  - `flutter test test/widget/booking/bookings_discovery_screen_test.dart`
- `@Sentinel`: Run integration test only when credentials/environment are present:
  - `flutter test integration_test/create_tender_task_flow_test.dart`
- `@Sentinel`: Record any skipped integration test reason.

#### 9.2 Documentation/session log

- `@DocsSync`: Update `docs/LOG/SESSION_HomeDiscoveryNavConsolidation_2026-04-30.md` with:
  - files changed
  - tests run
  - tests skipped and why
  - visual audit result
  - Supabase no-change confirmation
- `@DocsSync`: Update broader docs only if runtime navigation docs currently claim Tenders/Bookings are bottom-nav tabs.

#### 9.3 Rollback instructions

- `@Executor`: Roll back by reverting these files only:
  - `lib/core/widgets/custom_bottom_nav_bar.dart`
  - `lib/app/main_navigation_screen.dart`
  - `lib/features/home/view/home_screen.dart`
  - `lib/features/profile/services/profile_deep_link_handler.dart`
  - affected tests
  - any added visible-nav helper file
- `@Executor`: Do not revert unrelated dirty worktree files.
- `@Supabase_Ops`: No database rollback needed.

Result: implementation is verified, documented, and rollback-scoped.

GATE CHECK:

- `@Sentinel`: PASS only if targeted tests and analyzer pass, or any skipped integration coverage has a concrete environment reason.

## 5. Acceptance Criteria

- `@Sentinel`: Bottom nav renders exactly Home, Dashboard, Messages, Profile.
- `@Sentinel`: Bottom nav does not render Tenders.
- `@Sentinel`: Bottom nav does not render Bookings.
- `@Sentinel`: Dashboard opens at visible index `1`.
- `@Sentinel`: Messages opens at visible index `2`.
- `@Sentinel`: Profile opens at visible index `3`.
- `@Sentinel`: Invalid stale index does not crash `MainNavigationScreen`.
- `@Sentinel`: Profile deep link selects the Profile destination.
- `@Sentinel`: Home renders `All Work`, `Bookings`, and `Tenders` discovery chips below the search/filter row.
- `@Sentinel`: Bookings mode filters to booking tasks.
- `@Sentinel`: Tenders mode filters to tender tasks.
- `@Sentinel`: Search and category filters still work with the selected discovery mode.
- `@Sentinel`: Task-card tap still pushes `TaskDetailsScreen`.
- `@Sentinel`: `flutter analyze` passes.
- `@Sentinel`: Targeted widget tests pass.
- `@Supabase_Ops`: No Supabase migration or function changes are present.

## 6. Rollback Plan

- `@Executor`: Revert the visible-nav helper file if added.
- `@Executor`: Revert bottom-nav item list to six visible items.
- `@Executor`: Revert main navigation screen list to the previous seven-screen order.
- `@Executor`: Revert profile deep-link index only if the old six-item nav order is restored.
- `@Executor`: Revert Home discovery chip additions.
- `@Executor`: Revert test expectation changes tied to the new UX.
- `@Executor`: Do not touch unrelated `.TODO`, archive, screenshot, or Supabase drift files.
- `@Supabase_Ops`: No backend rollback is required.

## 7. References

- `.cursor/Agents/Planner.md`
- `.cursor/Agents/PlanCritic.md`
- `.TODO/PLAN_CRITIQUE_2026-04-30_HomeDiscoveryNavConsolidation.md`
- `lib/app/main_navigation_screen.dart`
- `lib/core/widgets/custom_bottom_nav_bar.dart`
- `lib/core/app_enums.dart`
- `lib/core/providers/navigation_provider.dart`
- `lib/features/home/view/home_screen.dart`
- `lib/features/tasks/view/tenders_screen.dart`
- `lib/features/booking/view/bookings_discovery_screen.dart`
- `lib/features/profile/services/profile_deep_link_handler.dart`
- `test/core/widgets/custom_bottom_nav_bar_test.dart`
- `test/widget/app/main_navigation_screen_test.dart`
- `test/widget/home/home_screen_test.dart`
- `test/integration_test/create_tender_task_flow_test.dart`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`
- `Sline_everything/SUPABASE_SETUP.md`
