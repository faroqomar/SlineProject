# 📌 Plan Segment: 70-Test Baseline (T51-T60) — Re-improved with @PlanCritic

- Source master plan: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22.md`
- Segment file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22_T51-T60.md`
- Included phases/tests: `T51` to `T60` (MainNavigation + Home + Dashboard + Chat widget tests)
- Audit method applied: `@PlanCritic` from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.agent/workflows/plan_critic.md`

## Purpose

- Turn the `T51-T60` slice into an execution-safe, gate-based mini-plan with explicit widget-test seams, harness requirements, and hidden-side-effect controls.
- Make each test phase implementation-ready: what we need, what to do, how to do it, what to expect, and what input you should provide.
- Preserve strict scope: `1 phase = 1 test` and no production behavior changes beyond approved testability seams.

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- This slice is widget-test-heavy (`10/10` widget tests) and must be planned with `@PlanCritic` v2.1 **Gate 0: Test Infrastructure Gate** before test phases start.
- `MainNavigationScreen`, `HomeScreen`, `DashboardScreen`, and `ChatScreen` currently build real widgets with side effects or heavy dependencies by default; clean widget tests require small default-preserving seams.
- `HomeScreen` has hidden side effects that can break offline tests:
  - `initState()` post-frame calls `HomeViewModel.loadFeaturedTasks(...)` and `ProfileViewModel.loadProfile()`.
  - It creates `SavedTasksViewModel(service: SavedTasksService())` inside the view and immediately calls `vm.load()`.
  - Header always renders `SignedAvatar`, which currently initializes `AvatarService(Supabase.instance.client)` in `initState()` even when avatar is null.
  - Header renders `NotificationBadgeButton`, which expects a `NotificationViewModel` provider and the real VM auto-subscribes on construction.
- `DashboardScreen` expects a provided `DashboardViewModel`, but its body builds heavy tab widgets (`OverviewTab`, `BookingsTab`, `WorkTab`, `InboxTab`) that can cascade into unrelated providers/services during simple wiring tests.
- `ChatScreen` has lifecycle side effects in `initState()` and `dispose()` (subscribe/unsubscribe/mark receipts) that are unrelated to render-branch tests `T59-T60` and can make tests flaky.
- `AttachmentMessageTile` currently creates `SupabaseAttachmentUploader()` and calls `createSignedUrl(...)` in `initState()`, which makes `T60` a hidden Supabase/network test unless a seam is added.
- `pubspec.yaml` currently shows `flutter_test` but no confirmed `mocktail` entry, so mock-based widget tests need a test foundation decision.

### Decision Needed (Blocking)

- Missing decision: **T51 route target seam for FAB navigation**
  - Options:
  - Add `MainNavigationScreen` `createTaskScreenBuilder` (or route builder) seam with production default (recommended)
  - Push real `CreateTaskScreen` in tests and satisfy its category/Supabase dependencies (not recommended)
  - Assert only `Navigator.push` count without verifying destination (weaker)
  - Recommended: first option because `CreateTaskScreen` loads categories and is too heavy for a nav-wiring widget test.
  - Plan impact: blocks a deterministic T51.

- Missing decision: **T52 interaction style for nav index switching**
  - Options:
  - Change `NavigationProvider.currentIndex` in test and assert active child swap (recommended)
  - Tap `CustomBottomNavBar` items directly (more brittle, couples to nav-bar internals)
  - Both in one test (scope creep)
  - Recommended: first option because the title is “changing nav index swaps active screen,” not “tapping nav bar.”
  - Plan impact: determines T52 selectors and seam scope.

- Missing decision: **HomeScreen test seam package for T53-T55**
  - Options:
  - Add `autoLoadOnInit` + `savedTasksVmFactory` seams (recommended)
  - Keep current screen and mock every hidden dependency path indirectly (fragile)
  - Large refactor moving provider creation out of view immediately (good architecture, too large for this slice)
  - Recommended: first option now, with follow-up debt item if provider-creation remains in view.
  - Plan impact: blocks T53-T55 if unresolved.

- Missing decision: **SignedAvatar hidden Supabase init mitigation (HomeScreen blocker)**
  - Options:
  - Fix `SignedAvatar` to lazily create `AvatarService` only when a private storage path must be resolved (recommended)
  - Add HomeScreen-only avatar seam to bypass `SignedAvatar` in tests (works, worse architecture)
  - Initialize Supabase in widget tests (not recommended)
  - Recommended: first option because it is a small behavior-preserving fix with broad testability benefit.
  - Plan impact: blocks reliable HomeScreen widget tests if unresolved.

- Missing decision: **DashboardScreen tab-content override seam for T56-T58**
  - Options:
  - Add optional `tabViews` (or tab view builder) override seam with production defaults (recommended)
  - Pump real tab content and satisfy all nested providers/services (not recommended)
  - Mock only `DashboardViewModel` and hope heavy tabs stay inert (fragile)
  - Recommended: first option because T56-T58 test wiring, tabs, and role switching, not tab implementation internals.
  - Plan impact: blocks stable T56-T58.

- Missing decision: **ChatScreen lifecycle-effects strategy for T59-T60**
  - Options:
  - Add `enableLifecycleEffects` / `disableLifecycleEffects` seam (recommended)
  - Rely on a fully mocked `ChatViewModel` to absorb all side effects (possible, still noisy and brittle)
  - Use real `ChatViewModel` (not recommended)
  - Recommended: seam + fake/mock VM for clarity and determinism.
  - Plan impact: blocks reliable T59-T60 setup.

- Missing decision: **T60 hidden signed-URL path seam (AttachmentMessageTile)**
  - Options:
  - Add `AttachmentMessageTile` signed-url resolver seam and pass through from `ChatScreen` (recommended)
  - Add global/static override in tests (not recommended; state leak risk)
  - Keep real uploader path in widget test (not recommended)
  - Recommended: resolver callback seam because it preserves MVVM boundaries and keeps tests offline.
  - Plan impact: blocks T60 entirely if unresolved.

- Missing decision: **Widget selector policy for this slice**
  - Options:
  - Stable keys for primary interactions + type/text for passive assertions (recommended)
  - Text-only selectors (brittle)
  - Runtime-only finders with no shared key strategy (high maintenance)
  - Recommended: first option.
  - Plan impact: affects T51-T58 and reduces flake/review churn.

### What Input You Should Provide Me (For This Slice)

- Approve `MainNavigationScreen` seams:
  - optional `List<Widget> screens`
  - `createTaskScreenBuilder` (or equivalent destination builder) for T51
- Approve `HomeScreen` seams for T53-T55:
  - `autoLoadOnInit` (default `true`)
  - `savedTasksVmFactory` (or equivalent provider/factory seam)
- Approve `SignedAvatar` lazy-init fix (recommended) to avoid hidden Supabase client init in HomeScreen widget tests.
- Approve `DashboardScreen` tab-content override seam (recommended: `tabViews` or `tabViewsBuilder`).
- Approve `ChatScreen` lifecycle-effects seam (recommended: `enableLifecycleEffects = true` default).
- Approve `AttachmentMessageTile` signed-url resolver seam and `ChatScreen` pass-through for T60.
- Choose selector/assertion strictness defaults:
  - Widget keys for interactions (recommended)
  - `exact` vs `contains` for any snackbar/text assertions in later slices (this slice is mostly type/wiring assertions)
- Optional: confirm whether T55 should assert `SavedTasksViewModel.refresh()` in addition to the required `home.refresh(...)` + `profile.loadProfile()` (recommended: yes as nearby side effect, but keep title scope explicit).

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate (before all other gates)

- Status: ❌ FAIL
- Reason: This slice is test-heavy and depends on a shared widget harness (`pumpApp`), mock registration, fake navigator observer, and stable widget key conventions that are not yet locked in this segment.
- Reason: `mocktail` is not yet confirmed in `pubspec.yaml` for mock/verify patterns across `DashboardViewModel`, `ChatViewModel`, and `NotificationViewModel` widget tests.
- What to add/fix to pass:
  - Add/lock `test/test_support/pump_app.dart` (or equivalent)
  - Confirm mock package (`mocktail`) and base mock registrations
  - Lock widget key constants for this slice
  - Add a placeholder widget test proving offline pump

### 1) Data/Contracts Gate

- Status: ❌ FAIL
- Reason: Seams and contracts are not locked for T51 (FAB destination), T53-T55 (Home auto-load/saved VM), T56-T58 (tabViews override), and T60 (signed-url resolver).
- Reason: T59-T60 chat fixtures need explicit conversation/message fixture contracts (especially `Conversation.taskId == null` to avoid `ChatContextWidget` task fetch path).
- What to add/fix to pass: resolve decisions in Section A and document fixture/minimum payload shapes in test helpers.

### 2) Security Gate

- Status: ⚠️ PARTIAL
- Reason: This slice should be offline widget tests, but current hidden `Supabase.instance.client` paths in `SignedAvatar` and `AttachmentMessageTile` can cause accidental backend access.
- Reason: `HomeScreen` and `ChatScreen` lifecycle side effects can trigger real subscriptions/network-like behavior if seams are not applied.
- What to add/fix to pass: add the listed seams/fixes and explicitly prohibit live Supabase/network access in widget tests.

### 3) Backend/API Gate

- Status: ❌ FAIL
- Reason: `HomeScreen` constructs `SavedTasksViewModel(service: SavedTasksService())` in the view and `SignedAvatar` initializes `AvatarService(Supabase.instance.client)` unconditionally.
- Reason: `AttachmentMessageTile` creates `SupabaseAttachmentUploader()` in `initState()` with no injection path.
- What to add/fix to pass: add default-preserving seams and lazy-init fixes so widget tests use only fake/mocked dependencies.

### 4) UI/Integration Gate

- Status: ❌ FAIL
- Reason: No explicit plan exists yet for stable selectors/keys on main nav FAB, dashboard settings path, role toggle path, and Home search field.
- Reason: `DashboardScreen` and `MainNavigationScreen` render heavy nested widgets by default, which blurs the test scope.
- What to add/fix to pass: lock key strategy and inject placeholder tab/screens where the test intent is screen-wiring only.

### 5) Release/QA Gate

- Status: ❌ FAIL
- Reason: There is no slice-specific flake strategy for `RefreshIndicator`, `TabBar`, and `AnimatedSwitcher` behaviors.
- Reason: Traceability (`T51`-`T60` test names, files, and assertions) is not yet enforced in this segment.
- What to add/fix to pass: define bounded pump rules, retry/re-run checks, and per-test traceability naming before marking the slice complete.

## C) Critical Gaps (Must-Fix)

- **Gap:** `MainNavigationScreen` hardcodes `CreateTaskScreen()` in FAB route
- **Why it will break:** T51 becomes a hidden integration test because `CreateTaskScreen` loads categories and touches Supabase paths.
- **Fix (exact step(s) to add / reorder):** Add a default-preserving `createTaskScreenBuilder` (or destination builder) seam to `MainNavigationScreen` and use a stub destination widget in T51.
- **Owner:** @Architect / @Pixel
- **Acceptance check:** T51 taps FAB and verifies navigation to a lightweight stub destination with no real `CreateTaskScreen` construction.

- **Gap:** `MainNavigationScreen` has no injected `screens` list
- **Why it will break:** T52 (and T51 support setup) must build heavy real children (`HomeScreen`, `DashboardScreen`, etc.) and inherit unrelated dependencies.
- **Fix (exact step(s) to add / reorder):** Add optional `List<Widget> screens` constructor seam with current production list as default.
- **Owner:** @Architect / @Pixel
- **Acceptance check:** T52 injects simple placeholder screens and asserts active screen swap via `NavigationProvider` changes only.

- **Gap:** `HomeScreen` auto-loads and constructs `SavedTasksViewModel` inside the view
- **Why it will break:** T53-T55 can trigger real service calls and async side effects before assertions even run.
- **Fix (exact step(s) to add / reorder):** Add `autoLoadOnInit` and `savedTasksVmFactory` (or equivalent provider seam) with default current behavior preserved.
- **Owner:** @Architect / @Pixel
- **Acceptance check:** T53-T55 can pump `HomeScreen` without any real `SavedTasksService` or post-frame data loads.

- **Gap:** `SignedAvatar` unconditionally initializes `AvatarService(Supabase.instance.client)`
- **Why it will break:** HomeScreen widget tests can hit Supabase init even when profile avatar is null and no signed URL should be resolved.
- **Fix (exact step(s) to add / reorder):** Make `SignedAvatar` lazily construct `AvatarService` only when resolving a non-http storage path (default behavior unchanged for real use).
- **Owner:** @Architect
- **Acceptance check:** `SignedAvatar(storagePathOrUrl: null)` renders placeholder without touching Supabase client.

- **Gap:** `DashboardScreen` builds heavy real tabs by default
- **Why it will break:** T56-T58 may fail on nested provider dependencies unrelated to tab count/wiring/role switch behavior.
- **Fix (exact step(s) to add / reorder):** Add optional tab-content override seam for lightweight placeholders while preserving default production tab widgets.
- **Owner:** @Architect / @Pixel
- **Acceptance check:** T56-T58 can run with a fake `DashboardViewModel` and placeholder tab bodies only.

- **Gap:** `ChatScreen` lifecycle side effects run on every widget test pump
- **Why it will break:** T59-T60 branch-render tests can subscribe/unsubscribe and mark receipts, creating unnecessary async flake and mock noise.
- **Fix (exact step(s) to add / reorder):** Add `enableLifecycleEffects` boolean seam (default `true`) and disable it in T59-T60.
- **Owner:** @Architect / @Pixel
- **Acceptance check:** T59-T60 pump `ChatScreen` with fake `ChatViewModel` without verifying subscription/receipt calls.

- **Gap:** `AttachmentMessageTile` signs URLs in `initState()` with no injection path
- **Why it will break:** T60 cannot render the image-message branch offline; it will hit `SupabaseAttachmentUploader()` immediately.
- **Fix (exact step(s) to add / reorder):** Add signed-url resolver seam to `AttachmentMessageTile` and pass-through seam from `ChatScreen` for tests.
- **Owner:** @Architect
- **Acceptance check:** T60 provides a fake resolver and renders `AttachmentMessageTile` without Supabase/network access.

- **Gap:** HomeScreen and DashboardScreen selectors are not locked
- **Why it will break:** Tests will overuse text selectors and become brittle to UI wording changes.
- **Fix (exact step(s) to add / reorder):** Add stable widget keys for primary interactions (main-nav FAB, home search, dashboard settings/button paths). Use text/type finders only for passive labels.
- **Owner:** @Pixel
- **Acceptance check:** T51-T58 primary interactions use keys or stable provider triggers, not fragile text-only taps.

- **Gap:** No explicit bounded-pump strategy for animations/refresh/tab dialogs
- **Why it will break:** AnimatedSwitcher/RefreshIndicator/TabBar/dialog interactions can hang on `pumpAndSettle()` if not bounded.
- **Fix (exact step(s) to add / reorder):** Document bounded pump patterns and per-test preferred interaction/verification strategy in this slice.
- **Owner:** @Sentinel
- **Acceptance check:** Test implementations use bounded waits and avoid indefinite settles unless proven safe.

## D) Invariants & Success Criteria (Non-Negotiable)

- **Invariant:** T51 verifies FAB-to-create-task navigation wiring, not `CreateTaskScreen` internals
- **How to enforce:** Use a stub destination via builder seam.
- **How to verify:** FAB tap pushes expected stub route/widget.

- **Invariant:** T52 verifies active-screen swap when nav index changes
- **How to enforce:** Use injected placeholder screens and mutate `NavigationProvider` index.
- **How to verify:** Visible placeholder changes with provider index updates.

- **Invariant:** T53 verifies Home shell rendering without triggering live IO
- **How to enforce:** Disable `HomeScreen` auto-load and inject fake saved-tasks VM; avoid `SignedAvatar` Supabase init path.
- **How to verify:** Search UI, categories shell, and list shell render offline.

- **Invariant:** T54 verifies typing delegates to `TaskFilterViewModel.searchTasks(...)`
- **How to enforce:** Use fake/mock `TaskFilterViewModel` and `enterText` on search field.
- **How to verify:** `searchTasks` receives the typed query.

- **Invariant:** T55 verifies refresh orchestration calls required viewmodels
- **How to enforce:** Trigger `RefreshIndicator` path with fake `HomeViewModel`, `ProfileViewModel`, and saved VM.
- **How to verify:** `home.refresh(...)` and `profile.loadProfile()` are called (and optionally `saved.refresh()`).

- **Invariant:** T56 verifies `DashboardScreen` tab labels count/wiring shell only
- **How to enforce:** Use placeholder tab bodies and fake `DashboardViewModel`.
- **How to verify:** Exactly the 4 expected tabs are present and screen pumps without heavy tab dependencies.

- **Invariant:** T57 verifies `TabBar` tap forwards index to `DashboardViewModel.setTab(index)`
- **How to enforce:** Tap a tab and verify the fake/mock VM call.
- **How to verify:** `setTab(targetIndex)` called once with expected index.

- **Invariant:** T58 verifies settings dialog path leads to role switch action calls
- **How to enforce:** Open settings dialog first, then tap role options.
- **How to verify:** `setRole(UserRole...)` called for the expected transition(s).

- **Invariant:** T59 verifies ChatScreen offer-message branch renders `OfferMessageBubble`
- **How to enforce:** Use a conversation fixture with `taskId == null` and a message fixture with `messageType == MessageType.offer` + payload.
- **How to verify:** `OfferMessageBubble` is rendered in message list.

- **Invariant:** T60 verifies ChatScreen image-message branch renders `AttachmentMessageTile` offline
- **How to enforce:** Use attachment message fixture and fake signed-url resolver via seam.
- **How to verify:** `AttachmentMessageTile` renders without hitting real Supabase/network.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|--------------|------------|----------|
| FAB test pushes real `CreateTaskScreen` | T51 | High | High | Feature | Missing providers / Supabase init during route push | Add `createTaskScreenBuilder` seam | Temporary observer-only assertion (weaker) |
| No `screens` seam causes heavy child dependencies | T51-T52 | High | High | Feature | `ProviderNotFound` / side effects during pump | Add `List<Widget> screens` seam | Defer T52 until seam lands |
| `CustomBottomNavBar` tap path is brittle | T52 | Med | Med | Local | Tap finder breaks after nav UI changes | Use provider index mutation strategy | Add stable nav keys later if needed |
| HomeScreen auto-load triggers real service calls | T53-T55 | High | High | Feature | Async exceptions before assertions | `autoLoadOnInit=false` seam | Skip to shell-only placeholders (temporary) |
| `SavedTasksViewModel` constructed in view hits IO | T53-T55 | High | High | Feature | Supabase/service errors on pump | `savedTasksVmFactory` seam | Follow-up refactor moving provider creation out of view |
| `SignedAvatar` initializes Supabase client even with null avatar | T53-T55 | High | High | Feature | Supabase initialization failure on header render | Lazy-init `AvatarService` only when needed | Temporary HomeScreen avatar bypass seam |
| Dashboard heavy tabs pull unrelated dependencies | T56-T58 | High | Med | Feature | Pump fails before tab assertions | `tabViews` placeholder seam | Over-provide dependencies (costly) |
| Settings dialog path not selectable reliably | T58 | Med | Med | Feature | Cannot tap settings/role controls | Add stable keys for settings and role buttons | Use `find.byIcon`/text fallback |
| Chat lifecycle side effects pollute render tests | T59-T60 | High | Med | Feature | Unexpected mock interactions / async waits | `enableLifecycleEffects=false` seam | Verify and ignore noisy calls (brittle) |
| Attachment tile signs URLs in initState | T60 | High | High | Feature | Supabase/network attempt on pump | Resolver seam + pass-through from ChatScreen | Defer T60 until seam implemented |
| `ChatContextWidget` triggers TaskViewModel fetch | T59-T60 | Med | Med | Feature | Missing `TaskViewModel` provider | Use `Conversation(taskId: null)` fixture | Add TaskViewModel fake provider |
| Unbounded `pumpAndSettle` hangs on animations | T51-T60 | Med | Med | Local | Test hangs/timeouts | Use bounded pumps and explicit waits | Replace with targeted `pump(Duration)` |

## F) Pre-Mortem (How this fails in real life)

- This fails when T51 is written against the real FAB route and silently becomes a `CreateTaskScreen` integration test.
- This fails when T52 taps `CustomBottomNavBar` instead of testing the stated contract (index change), and a nav UI refactor breaks the test without changing behavior.
- This fails when T53-T55 are implemented before `HomeScreen` seams and `SavedTasksViewModel`/`SignedAvatar` trigger real Supabase paths during pump.
- This fails when the team patches HomeScreen tests by over-mocking instead of fixing `SignedAvatar` lazy init, leaving the root hidden dependency intact.
- This fails when T56-T58 load real tab content and the tests become unstable because `BookingsTab`/`WorkTab` require deeper app state.
- This fails when T58 skips the settings-dialog interaction path and verifies `setRole` by directly calling the VM, missing the UI wiring contract.
- This fails when T59-T60 use a conversation with a non-empty `taskId` and `ChatContextWidget` unexpectedly requires `TaskViewModel` + loading flows.
- This fails when T60 adds only an `AttachmentMessageTile` seam but no `ChatScreen` pass-through, so the actual `ChatScreen` test still calls the default Supabase uploader.
- This fails when selectors are text-only and UI copy changes cause false failures.
- This fails when `pumpAndSettle()` is used blindly around animations/dialogs and hangs intermittently in CI.

## G) Plan Fixes (Concrete Additions / Expansions)

- **Goal:** Establish widget-test foundation (Gate 0) before touching T51-T60
- **Why:** This slice is 100% widget tests and depends on shared harness/mocks/keys.
- **How:** Add `pumpApp`, mock/fake registrations, fake navigator observer, and one offline placeholder test proof.
- **Output artifact:** `test/test_support/pump_app.dart`, `test/test_support/mocks/`, `test/test_support/fixtures/`
- **Stop condition:** A placeholder widget test pumps with no Supabase/plugin/network calls.

- **Goal:** Add minimal seams for `MainNavigationScreen` and `DashboardScreen`
- **Why:** T51-T52 and T56-T58 are wiring tests and should not pull heavy children.
- **How:** Add default-preserving `screens`, `createTaskScreenBuilder`, and `tabViews` seams; add stable keys for primary interactions.
- **Output artifact:** Small seam/key updates in `MainNavigationScreen` and `DashboardScreen`
- **Stop condition:** Both screens can be pumped with placeholder content and fake providers only.

- **Goal:** Add minimal seams for `HomeScreen` hidden side effects
- **Why:** T53-T55 cannot be deterministic while HomeScreen creates real VMs/services and auto-loads on init.
- **How:** Add `autoLoadOnInit`, `savedTasksVmFactory`, and provide fake `NotificationViewModel`; fix `SignedAvatar` lazy init.
- **Output artifact:** HomeScreen seam updates + `SignedAvatar` lazy-init safety improvement
- **Stop condition:** HomeScreen renders header/search/categories shell offline with fake VMs.

- **Goal:** Isolate ChatScreen render-branch tests from lifecycle and signed-url IO
- **Why:** T59-T60 target render branching only, not realtime or storage signing.
- **How:** Add `enableLifecycleEffects` seam to `ChatScreen`, signed-url resolver seam to `AttachmentMessageTile`, and pass-through seam from `ChatScreen`.
- **Output artifact:** Small seam updates in `ChatScreen` and `AttachmentMessageTile`
- **Stop condition:** T59-T60 can run offline with fake `ChatViewModel` and resolver stub.

- **Goal:** Lock per-test implementation contracts and required user inputs
- **Why:** Reduces decision churn during execution and keeps one-phase-one-test discipline.
- **How:** Add `What Input You Should Provide Me` + `GATE CHECK` for every phase.
- **Output artifact:** Per-phase execution-ready sections below
- **Stop condition:** Each phase can start with no hidden dependency/decision work.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Slice Dependency Order (T51-T60)

1. Gate 0 test foundation: harness, mock package, fake navigator observer, shared fixtures, key conventions.
2. Lock seam signatures and selector strategy (Section A decisions).
3. Apply seam-only production changes: `MainNavigationScreen`, `HomeScreen`, `SignedAvatar`, `DashboardScreen`, `ChatScreen`, `AttachmentMessageTile`.
4. Implement tests in this order:
   - `T51-T52` MainNavigation
   - `T53-T55` HomeScreen
   - `T56-T58` DashboardScreen
   - `T59-T60` ChatScreen
5. Stabilization and QA gate: reruns, bounded pump review, traceability signoff.

### Shared Implementation Rules (Applies to T51-T60)

- [ ] (@Architect) Production changes are limited to keys/DI/seams/lazy-init fixes with default-preserving behavior only.
- [ ] (@Sentinel) Widget tests stay offline: no live Supabase/network/plugin calls.
- [ ] (@Pixel) Use stable widget keys for primary interactions; use text/type assertions for passive UI labels and render branches.
- [ ] (@Architect) Prefer placeholder child widgets (`screens`, `tabViews`) over over-provisioning heavy dependencies.
- [ ] (@Sentinel) Use bounded `pump`/`pumpAndSettle`; do not rely on indefinite settle around animated widgets or refresh gestures.
- [ ] (@Architect) Keep `Conversation(taskId: null)` in T59-T60 fixtures unless the test explicitly targets `ChatContextWidget`.
- [ ] (@Sentinel) One phase = one test contract. Local subcases allowed only when the title itself implies multiple transitions (e.g., T58).

### Slice QA/Release Gate (Before Marking T51-T60 Complete)

- [ ] (@Sentinel) `flutter test /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/chat` passes for `T51-T60`.
- [ ] (@Sentinel) Re-run `home_screen_test.dart`, `dashboard_screen_test.dart`, and `chat_screen_test.dart` once to detect obvious flake (refresh/tab/dialog/lifecycle interactions).
- [ ] (@Sentinel) Confirm all blocking decisions from Section A are resolved and reflected in code comments/assertions.
- [ ] (@Sentinel) Review checklist passes:
  - no hidden Supabase calls in widget tests
  - seam changes are default-preserving
  - placeholders used for non-target child content
  - `Txx` IDs map cleanly to test names
- **GATE CHECK:** `T51-T60` is stable and merge-ready before starting `T61-T70`.

## Phase 51: T51 - MainNavigationScreen FAB opens create task screen

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T51` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app/main_navigation_screen_test.dart`.

### Why

- This protects a high-frequency navigation entry point (FAB create-task action) while keeping the test scoped to route wiring rather than create-task feature internals.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app/main_navigation_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/app/main_navigation_screen.dart`.
- Test case target: `MainNavigationScreen FAB opens create task screen`.
- `MainNavigationScreen` seams:
  - optional `List<Widget> screens` (placeholder children)
  - `createTaskScreenBuilder` (or equivalent destination builder) for FAB route target
- Stable key for main-nav FAB trigger (recommended shared key constant).
- `pumpApp` harness + `NavigationProvider` + fake navigator observer.
- Placeholder create-task destination widget (e.g., `Text('stub-create-task')`).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Add/confirm `MainNavigationScreen` `screens` and FAB destination builder seams with production defaults preserved.
- [ ] (@Pixel) Add/confirm stable key for FAB trigger.
- [ ] (@Pixel) Pump `MainNavigationScreen` with placeholder screens and stub create-task destination, tap FAB, and assert navigation to stub destination.
- [ ] (@Sentinel) Review that the test verifies wiring only (not `CreateTaskScreen` internals).
- **Verify (@Sentinel):** `T51` remains one scenario and does not bundle screen-index assertions (covered by T52).

### How To Do It

- Use `pumpApp` with `ChangeNotifierProvider(create: (_) => NavigationProvider())`.
- Inject lightweight placeholder `screens` to avoid building `HomeScreen`, `DashboardScreen`, etc.
- Inject a `createTaskScreenBuilder` returning a simple stub widget and assert either:
  - stub widget is visible after tap, and/or
  - navigator observer recorded one push.
- Use bounded `pump()` / `pumpAndSettle()` because the screen includes `AnimatedSwitcher` and an animated FAB wrapper.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Stable regression protection for the FAB navigation path.
- No dependency on categories loading, Supabase, or `CreateTaskScreen` internals.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve the FAB destination seam shape (recommended: `WidgetBuilder? createTaskScreenBuilder`).
- Confirm assertion style for T51 (recommended: stub destination visible + optional observer push count).
- Optional: confirm the shared key name for FAB (recommended: `WidgetTestKeys.mainNavFab`).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T51` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app/main_navigation_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- FAB tap deterministically pushes the stub create-task destination without constructing the real `CreateTaskScreen`.
- This phase is not complete until the test passes locally and reviewer confirms scope is route wiring only.

---

## Phase 52: T52 - MainNavigationScreen changing nav index swaps active screen

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T52` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app/main_navigation_screen_test.dart`.

### Why

- This validates the core screen-switching contract driven by `NavigationProvider.currentIndex`, which is the main purpose of `MainNavigationScreen`.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app/main_navigation_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/app/main_navigation_screen.dart`.
- Test case target: `MainNavigationScreen changing nav index swaps active screen`.
- `MainNavigationScreen` optional `screens` seam for placeholder content.
- `NavigationProvider` instance exposed to the test so index can be changed directly.
- Distinct placeholder screens keyed/labeled by index (`home-stub`, `tenders-stub`, etc.).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Add/confirm `screens` seam (if not already added for T51).
- [ ] (@Pixel) Pump `MainNavigationScreen` with placeholder screens and keep a reference to the injected `NavigationProvider`.
- [ ] (@Pixel) Assert index `0` screen is visible, call `navigationProvider.setCurrentIndex(targetIndex)`, pump, and assert the new active placeholder is shown.
- [ ] (@Sentinel) Review that the test targets index-driven swapping (not custom bottom nav internals).
- **Verify (@Sentinel):** `T52` remains one scenario and does not duplicate FAB route behavior (T51).

### How To Do It

- Prefer provider-driven state mutation (`setCurrentIndex`) over tapping `CustomBottomNavBar` to match the exact contract named in the test.
- Use placeholder screens with unique keys/text to make assertions unambiguous.
- Use a bounded `pump(Duration(milliseconds: 300))` or `pumpAndSettle()` only if needed for `AnimatedSwitcher` completion.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Clear protection for screen switching when nav state changes.
- Lower maintenance cost than a nav-bar tap test because it isolates the intended contract.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm T52 should use provider-driven index changes (recommended) instead of tapping `CustomBottomNavBar`.
- Optional: confirm target index coverage (recommended: assert index `0 -> 1` is sufficient; add `1 -> 3` only if concise).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T52` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app/main_navigation_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- Changing `NavigationProvider.currentIndex` updates the active displayed child deterministically using placeholder screens.
- This phase is not complete until the test passes locally and reviewer confirms it is not coupled to `CustomBottomNavBar` internals.

---

## Phase 53: T53 - HomeScreen renders search, categories, and task list shell

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T53` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/home_screen_test.dart`.

### Why

- This protects the core HomeScreen shell structure (header/search/categories/list area) without requiring live data or network paths.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/home_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/home_screen.dart`.
- Test case target: `HomeScreen renders search, categories, and task list shell`.
- `HomeScreen` testability seams:
  - `autoLoadOnInit` (default `true`) to disable post-frame loads in tests
  - `savedTasksVmFactory` (or equivalent) to avoid constructing `SavedTasksViewModel(service: SavedTasksService())`
- `SignedAvatar` lazy-init fix (recommended) so null avatar does not initialize Supabase client.
- Fake/mock providers for:
  - `HomeViewModel`
  - `TaskFilterViewModel`
  - `ProfileViewModel`
  - `NotificationViewModel`
  - `SavedTasksViewModel` (via seam)
- Stable key for Home search field (recommended).
- Shell rendering strategy (recommended: force `homeVm.isLoading == true` to assert list shell via skeletons and avoid `TaskCard` branches).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Add/confirm `HomeScreen` seams and `SignedAvatar` lazy-init fix.
- [ ] (@Pixel) Add/confirm Home search key (and any other primary interaction keys needed for T54/T55 reuse).
- [ ] (@Pixel) Pump `HomeScreen(autoLoadOnInit: false, ...)` with fake providers and assert:
  - search field shell is visible
  - categories shell is visible
  - task list shell area is visible (recommended via loading skeletons)
- [ ] (@Sentinel) Review that no real service calls occur during pump and scope stays on shell rendering.
- **Verify (@Sentinel):** `T53` remains one scenario and does not assert search delegation (T54) or refresh orchestration (T55).

### How To Do It

- Use a fake or mocked `HomeViewModel` returning `isLoading = true` to render skeleton list shell and avoid task-detail navigation branches.
- Provide a simple fake `NotificationViewModel` via `ChangeNotifierProvider.value`; do not construct the real one (it auto-subscribes).
- Provide `ProfileViewModel` with `fullName` and `avatarUrl = null` to exercise header safely.
- Assert shell elements via stable key/type/text mix:
  - search field key
  - category chip row presence (or one known category label + All chip)
  - skeleton list widgets (`SkeletonTaskCard`) or scroll shell (`CustomScrollView`)
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Fast, offline coverage of HomeScreen shell rendering and provider wiring.
- Early detection if Home header/search/category/list shell regresses structurally.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve `HomeScreen` seams: `autoLoadOnInit` + `savedTasksVmFactory` (recommended).
- Approve `SignedAvatar` lazy-init fix (recommended) instead of adding a HomeScreen-only avatar bypass seam.
- Confirm shell assertion mode (recommended: loading skeleton path for stable list shell assertions).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T53` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/home_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- HomeScreen shell renders offline with fake providers and no hidden Supabase/service calls.
- This phase is not complete until the test passes locally and reviewer confirms shell-only scope.

---

## Phase 54: T54 - HomeScreen typing search delegates to TaskFilterViewModel.searchTasks

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T54` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/home_screen_test.dart`.

### Why

- This verifies the user-input wiring from the Home search field to `TaskFilterViewModel.searchTasks(...)`, a frequent interaction with high regression risk after UI refactors.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/home_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/home_screen.dart`.
- Test case target: `HomeScreen typing search delegates to TaskFilterViewModel.searchTasks`.
- Reuse `HomeScreen(autoLoadOnInit: false, savedTasksVmFactory: ...)` seam setup from T53.
- Stable key for Home search field (recommended mandatory for this test).
- Fake/mock `TaskFilterViewModel` with call verification on `searchTasks(String)`.
- Fake/mock `HomeViewModel`, `ProfileViewModel`, `NotificationViewModel`, and `SavedTasksViewModel` to keep the screen pump deterministic.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Pixel) Pump HomeScreen with test seams disabled for auto-load and fake providers.
- [ ] (@Pixel) Enter text into the search field using the stable key.
- [ ] (@Pixel) Verify `TaskFilterViewModel.searchTasks(query)` was called with the typed query.
- [ ] (@Sentinel) Review that the test targets delegation only and not filtering results logic (covered by unit tests in `T06-T09`).
- **Verify (@Sentinel):** `T54` remains one scenario and does not assert category filtering or list rendering outcomes.

### How To Do It

- Use `tester.enterText` on the keyed search field; HomeScreen wires `onChanged: filterController.searchTasks`, so no submit action is required.
- Use `mocktail` `verify(...)` (or a simple fake recorder) to assert the exact query string passed through.
- Keep the query simple and deterministic (e.g., `design`) unless you intentionally want whitespace behavior assertions.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Strong signal if the search field loses its VM wiring during UI refactors.
- No overlap with filter logic unit tests; this is strictly UI-to-ViewModel delegation.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm query assertion style for T54 (recommended: exact argument match, e.g., `design`).
- Optional: if you want whitespace behavior covered here, specify whether to assert raw pass-through vs trimmed input (current UI passes raw `onChanged` value; recommended: raw pass-through).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T54` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/home_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- Typing in the Home search field calls `TaskFilterViewModel.searchTasks(...)` with the expected query and no hidden side effects.
- This phase is not complete until the test passes locally and reviewer confirms it does not duplicate filter logic unit coverage.

---

## Phase 55: T55 - HomeScreen pull-to-refresh calls home refresh and profile reload

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T55` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/home_screen_test.dart`.

### Why

- This protects HomeScreen refresh orchestration, which coordinates multiple ViewModels and is easy to regress when changing loading or header behavior.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/home_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/home_screen.dart`.
- Test case target: `HomeScreen pull-to-refresh calls home refresh and profile reload`.
- Reuse HomeScreen seams from T53/T54: `autoLoadOnInit` + `savedTasksVmFactory`.
- Fake/mock providers for `HomeViewModel`, `TaskFilterViewModel`, `ProfileViewModel`, `NotificationViewModel`, and `SavedTasksViewModel`.
- Refresh trigger strategy (recommended): real pull gesture on `CustomScrollView` / `RefreshIndicator` with bounded pumps.
- Optional fallback strategy if gesture is flaky: expose a test key on `RefreshIndicator` and call `RefreshIndicatorState.show()` (fallback only).
- Decision on assertion scope for the extra side effect `saved.refresh()` (HomeScreen currently also calls it).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Pixel) Pump HomeScreen with auto-load disabled and fake providers.
- [ ] (@Pixel) Trigger pull-to-refresh and await completion with bounded pumps.
- [ ] (@Pixel) Assert required calls:
  - `homeViewModel.refresh(filterController: ...)`
  - `profileViewModel.loadProfile()`
- [ ] (@Pixel) If approved, also assert `savedTasksViewModel.refresh()` as a nearby side effect.
- [ ] (@Sentinel) Review gesture stability and ensure the test remains orchestration-focused.
- **Verify (@Sentinel):** `T55` remains one scenario and does not test `HomeViewModel.refresh()` internals.

### How To Do It

- Disable HomeScreen auto-load to prevent initialization calls from polluting refresh call counts.
- Use a fake/mock `HomeViewModel` and capture the `filterController` argument for `refresh(...)` (optionally assert same instance as provided filter VM).
- Trigger `RefreshIndicator` with a downward drag/fling on the scrollable body and bounded `pump` cycles.
- If CI proves flaky, switch to a keyed `RefreshIndicatorState.show()` invocation while documenting why (still same refresh contract).
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Coverage of the Home refresh orchestration contract across ViewModels.
- Early detection if one of the required refresh/reload calls is removed from the pull-to-refresh path.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm refresh trigger strategy (recommended: gesture first, keyed `RefreshIndicatorState.show()` only if flaky).
- Confirm assertion scope for `savedTasksViewModel.refresh()` (recommended: assert it too, but keep required contract centered on home + profile calls).
- Optional: confirm whether to assert the exact `TaskFilterViewModel` instance passed into `homeViewModel.refresh(...)` (recommended: yes if concise).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T55` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/home_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- Pull-to-refresh triggers the required ViewModel calls offline and deterministically.
- This phase is not complete until the test passes locally and reviewer confirms the refresh path is exercised (not manually calling VMs in the test body).

---

## Phase 56: T56 - DashboardScreen shows 4 tabs Overview Bookings Work Inbox

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T56` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/dashboard_screen_test.dart`.

### Why

- This protects the dashboard top-level navigation shell and catches accidental tab removal/renaming or layout regressions before deeper dashboard tests run.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/dashboard_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/dashboard_screen.dart`.
- Test case target: `DashboardScreen shows 4 tabs Overview Bookings Work Inbox`.
- Fake/mock `DashboardViewModel` provider (do not construct real `DashboardViewModel` because constructor auto-loads cache/backend data).
- `DashboardScreen` optional `tabViews` override seam (placeholder tab bodies) to avoid heavy child tab dependencies.
- Stable key for settings button is helpful for T58 reuse (optional for T56 but recommended in same seam batch).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Add/confirm `DashboardScreen` tab-content override seam with production defaults preserved.
- [ ] (@Pixel) Pump `DashboardScreen` with fake `DashboardViewModel` and placeholder tab bodies.
- [ ] (@Pixel) Assert the four expected tab labels are present (`Overview`, `Bookings`, `Work`, `Inbox`).
- [ ] (@Sentinel) Review that the test targets the tab shell only, not tab content internals.
- **Verify (@Sentinel):** `T56` remains one scenario and does not verify `setTab(...)` calls (T57).

### How To Do It

- Provide a fake/mock `DashboardViewModel` with safe getters (`currentTab`, `currentRole`, etc.) stubbed to minimal valid values.
- Use placeholder tab bodies so `TabBarView` renders without requiring dashboard subfeature providers.
- Prefer direct tab-label presence assertions (text/type) because T56 is a shell-structure test.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Quick signal if dashboard tab layout changes accidentally.
- Stable widget test that stays scoped to shell wiring and avoids deep dashboard dependencies.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve `DashboardScreen` tab-content override seam (recommended).
- Optional: confirm whether T56 should assert exactly four tab labels only, or also assert one active placeholder body is visible (recommended: labels only + one body sanity check if concise).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T56` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/dashboard_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- DashboardScreen pumps with fake VM + placeholder tab views and shows the 4 expected tabs.
- This phase is not complete until the test passes locally and reviewer confirms no heavy tab dependencies are required.

---

## Phase 57: T57 - DashboardScreen tab tap calls setTab(index)

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T57` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/dashboard_screen_test.dart`.

### Why

- This protects the UI-to-ViewModel wiring for dashboard tab changes, which is a key coordination path in the dashboard experience.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/dashboard_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/dashboard_screen.dart`.
- Test case target: `DashboardScreen tab tap calls setTab(index)`.
- Fake/mock `DashboardViewModel` with `setTab(int index, {int? workSubTab})` verification support.
- Reuse `DashboardScreen` `tabViews` placeholder seam from T56.
- Stable tab selector strategy (text finder on `Work`/`Inbox` is acceptable here because labels are part of the contract).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Pixel) Pump `DashboardScreen` with fake/mock `DashboardViewModel` and placeholder tab bodies.
- [ ] (@Pixel) Tap one non-default tab (recommended: `Work`) and verify `vm.setTab(expectedIndex)` is called.
- [ ] (@Sentinel) Review that the test verifies the ViewModel call, not just UI label visibility.
- **Verify (@Sentinel):** `T57` remains one scenario and does not duplicate tab-count/labels coverage from T56.

### How To Do It

- Stub the fake/mock `DashboardViewModel.currentTab` to a valid initial state (`DashboardTab.overview`).
- Tap the tab label (e.g., `Work`) and use `mocktail verify` or a recorder fake to assert the exact index (`2` if using current tab order).
- Keep placeholder tab bodies in place to avoid unintended subfeature loading.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Direct coverage of dashboard tab onTap wiring into `DashboardViewModel.setTab(...)`.
- Early detection if tab order or callback wiring changes unexpectedly.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm the target tab/index for assertion (recommended: tap `Work` and assert `setTab(2)`).
- Optional: confirm whether to verify exactly one call or “at least one” call (recommended: exactly one for this tap action).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T57` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/dashboard_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- Tapping the selected dashboard tab label triggers the expected `setTab(index)` call on the VM.
- This phase is not complete until the test passes locally and reviewer confirms the assertion targets callback wiring (not visual state only).

---

## Phase 58: T58 - DashboardScreen role switch triggers setRole transitions

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T58` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/dashboard_screen_test.dart`.

### Why

- This protects the settings-dialog role switch wiring path, which is multi-step UI flow (`settings -> dialog -> role tap`) and easy to break without noticing.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/dashboard_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/dashboard_screen.dart`.
- Test case target: `DashboardScreen role switch triggers setRole transitions`.
- Fake/mock `DashboardViewModel` with async `setRole(UserRole role)` verification support.
- Reuse `DashboardScreen` `tabViews` placeholder seam.
- Stable selectors for:
  - settings action button (`Icons.settings_outlined` or key)
  - role buttons (`Freelancer`, `Client` text or keys in `_RoleButton`)
- Decision whether to cover both transitions in one test (title says transitions; recommended: yes as local subcases within one test).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Pixel) Pump `DashboardScreen` with fake/mock `DashboardViewModel` and placeholder tabs.
- [ ] (@Pixel) Open the settings dialog via the settings icon/button.
- [ ] (@Pixel) Tap role options and verify `vm.setRole(UserRole...)` calls for the intended transition(s).
- [ ] (@Sentinel) Review that the test exercises the actual dialog path and does not call `setRole` directly in the test body.
- **Verify (@Sentinel):** `T58` remains one scenario with local subcases only for the role transitions implied by the title.

### How To Do It

- Stub `currentRole` on the fake/mock VM (recommended initial role: `UserRole.freelancer`).
- Tap settings button, `pumpAndSettle()` for dialog, then tap `Client` and verify `setRole(UserRole.client)`.
- If asserting both transitions, either:
  - use a stateful fake VM that updates `currentRole`, or
  - verify both calls on a mock across repeated dialog opens/taps with controlled stubs.
- Use stable keys for settings and role buttons if added; text/icon finders are acceptable fallback because labels are part of the UX contract.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Strong wiring coverage for a multi-step dashboard settings path.
- Regression detection if the dialog no longer opens or role taps stop invoking `setRole(...)`.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm T58 should cover both role transitions in one test (recommended, because title says `transitions`).
- Confirm selector preference for role buttons (recommended: keys if added; text fallback acceptable).
- Optional: choose fake strategy for `setRole` verification (recommended: stateful fake if you want both transitions with clearer assertions; mocktail verify is also fine).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T58` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/dashboard_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- The settings dialog path opens and role taps trigger the expected `setRole(...)` calls on the VM.
- This phase is not complete until the test passes locally and reviewer confirms the UI path (not direct VM invocation) is exercised.

---

## Phase 59: T59 - ChatScreen renders offer bubble when messageType equals offer

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T59` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/chat/chat_screen_test.dart`.

### Why

- Offer messages are a critical chat branch with specialized rendering (`OfferMessageBubble`). If this branch regresses, users lose offer interaction visibility even though plain text chat may still work.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/chat/chat_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/view/chat_screen.dart`.
- Test case target: `ChatScreen renders offer bubble when messageType equals offer`.
- `ChatScreen` lifecycle-effects seam (recommended: `enableLifecycleEffects = true` default) so T59 can disable subscription/receipt side effects.
- Fake/mock `ChatViewModel` with stubbed getters/fields used by the widget (`currentMessages`, `currentUserId`, `activeConversation` setter if applicable).
- `Conversation` fixture with `taskId: null` (or empty) to prevent `ChatContextWidget` from requiring `TaskViewModel`.
- `Message` fixture with:
  - `messageType: MessageType.offer`
  - non-empty `payload` containing required offer fields (`title`, `description`, `price`, `delivery`, `status`)
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Add/confirm `ChatScreen` lifecycle seam (default-preserving).
- [ ] (@Pixel) Pump `ChatScreen` with a fake/mock `ChatViewModel`, lifecycle effects disabled, and a conversation fixture with no task context.
- [ ] (@Pixel) Seed `currentMessages` with one offer message and assert `OfferMessageBubble` renders.
- [ ] (@Sentinel) Review that the test targets render-branch selection only, not offer accept/decline actions.
- **Verify (@Sentinel):** `T59` remains one scenario and does not bundle send/accept/reject behavior tests.

### How To Do It

- Use a fake/mock `ChatViewModel` provider and stub `currentMessages` to return a list containing exactly one offer message.
- Use `Conversation(taskId: null)` to keep `ChatContextWidget` on the `SizedBox.shrink()` branch and avoid `TaskViewModel` provider requirements.
- Assert `find.byType(OfferMessageBubble)` (and optionally a payload text sanity check like offer title) after pumping the widget.
- Disable lifecycle effects to avoid subscription/receipt interactions that are unrelated to this branch.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Direct coverage of the `messageType == offer` rendering branch in `ChatScreen`.
- Fast detection if chat render routing accidentally falls back to plain `MessageBubble` for offers.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve `ChatScreen` lifecycle seam (recommended).
- Confirm conversation fixture contract for this test (recommended: `taskId: null` to avoid `ChatContextWidget` task fetch path).
- Optional: confirm whether to assert only `OfferMessageBubble` type or type + one payload text sanity check (recommended: type + one text check if concise).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T59` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/chat/chat_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- `ChatScreen` renders `OfferMessageBubble` for an offer-type message offline, with lifecycle side effects disabled.
- This phase is not complete until the test passes locally and reviewer confirms no `TaskViewModel` dependency is accidentally introduced.

---

## Phase 60: T60 - ChatScreen renders attachment tile for image messages

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T60` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/chat/chat_screen_test.dart`.

### Why

- Image-message rendering is a high-value chat branch that depends on attachment UI and signed URL resolution. This test ensures the branch is selected correctly while staying offline and deterministic.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/chat/chat_screen_test.dart`.
- Primary implementation targets:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/view/chat_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/attachments/widgets/attachment_message_tile.dart`
- Test case target: `ChatScreen renders attachment tile for image messages`.
- Reuse `ChatScreen` lifecycle-effects seam from T59.
- `AttachmentMessageTile` signed-url resolver seam (recommended) to avoid `SupabaseAttachmentUploader().createSignedUrl(...)` in `initState()`.
- `ChatScreen` pass-through seam to inject the attachment signed-url resolver into `AttachmentMessageTile` during widget tests (recommended narrow seam).
- Fake/mock `ChatViewModel` with one image attachment message in `currentMessages`.
- `Conversation` fixture with `taskId: null` to bypass `ChatContextWidget` task fetch path.
- Image attachment message fixture with:
  - `attachmentType == 'image'`
  - non-empty `attachmentUrl` storage path
  - optional caption content for branch sanity check
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Add/confirm resolver seam in `AttachmentMessageTile` and pass-through seam in `ChatScreen` (default behavior preserved).
- [ ] (@Pixel) Pump `ChatScreen` with lifecycle effects disabled, fake/mock `ChatViewModel`, and a fake signed-url resolver.
- [ ] (@Pixel) Seed `currentMessages` with an image attachment message and assert `AttachmentMessageTile` renders.
- [ ] (@Sentinel) Review that the test remains offline and does not validate network image loading success (not the goal here).
- **Verify (@Sentinel):** `T60` remains one scenario and does not expand into attachment upload/send flows.

### How To Do It

- Inject a fake signed-url resolver that returns a deterministic value (recommended: delayed or immediate fake URL/empty string depending the assertion path) without any real network/Supabase call.
- Prefer asserting `find.byType(AttachmentMessageTile)` (and optionally caption/time text sanity) rather than waiting for `Image.network` to complete.
- Keep `Conversation.taskId` null to avoid unrelated `ChatContextWidget` dependencies.
- Use bounded pumps only; do not let this test become a network-image load test.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Stable coverage of the ChatScreen image-message render branch and attachment tile selection.
- Early signal if image messages stop routing to `AttachmentMessageTile` or if hidden signed-url IO leaks into widget tests.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve the T60 seam package (recommended):
  - `AttachmentMessageTile` signed-url resolver callback
  - `ChatScreen` pass-through callback for attachment signed-url resolver
- Confirm assertion depth (recommended: `AttachmentMessageTile` type presence + optional caption sanity check; do not assert network image success).
- Optional: confirm resolver stub behavior (recommended: immediate deterministic fake URL; no network dependency).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T60` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/chat/chat_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- ChatScreen renders `AttachmentMessageTile` for image messages offline using the injected resolver seam (no real Supabase/network call).
- This phase is not complete until the test passes locally and reviewer confirms the seam is narrow and default-preserving.

## I) Change Report (Diff-Style)

### What Changed

- Replaced the older generic `T51-T60` segment content with a full `@PlanCritic` v2.1 execution-ready rewrite.
- Added **A-I** audit structure, including **Gate 0: Test Infrastructure Gate** required for test-heavy plans.
- Converted the slice to explicit gate-based execution ordering with shared rules and a slice QA gate.
- Added concrete blocker analysis for real code paths in:
  - `MainNavigationScreen`
  - `HomeScreen`
  - `SignedAvatar`
  - `DashboardScreen`
  - `ChatScreen`
  - `AttachmentMessageTile`
- Rewrote all `10` phases (`T51-T60`) to include:
  - `Goal`
  - `Why`
  - `What We Need`
  - `What To Do`
  - `How To Do It`
  - `What To Expect From This Test`
  - `What Input You Should Provide Me`
  - `Result (Expected Output Artifact)`
  - `GATE CHECK`

### What Was Clarified

- T51/T52 main navigation tests should stay on nav wiring and index-driven screen switching, not heavy child-screen behavior.
- T53-T55 HomeScreen widget tests require explicit seams for auto-load and saved-tasks VM creation, plus `SignedAvatar` lazy-init mitigation.
- T56-T58 Dashboard tests need placeholder tab content to avoid unrelated dependency explosions.
- T59-T60 Chat tests need lifecycle disabling and attachment signed-url seams to remain offline/deterministic.
- `Conversation(taskId: null)` is the recommended fixture default for `T59-T60` to avoid `ChatContextWidget` task fetch path.

### Remaining Decisions (User Input)

- Approve seam signatures and selector strategy listed in Section A.
- Confirm T52 provider-driven strategy, T55 refresh assertion scope (`saved.refresh()` yes/no), and T58 transition coverage style.
- Approve T60 resolver seam + ChatScreen pass-through seam.
