# 📌 Plan Segment: 70-Test Baseline (T61-T70) — Re-improved with @PlanCritic

- Source master plan: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22.md`
- Segment file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22_T61-T70.md`
- Included phases/tests: `T61` to `T70` (`3` widget tests + `7` integration tests)
- Audit method applied: `@PlanCritic` from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.agent/workflows/plan_critic.md`
- Skills applied during review: `flutter-testing` (test-type/harness discipline), `architecture-guard` (MVVM boundary enforcement for `CreateTaskScreen`)

## Purpose

- Turn the `T61-T70` slice into an execution-safe, gate-based mini-plan that covers both widget and staging-backed integration tests.
- Make each test phase implementation-ready: what we need, what to do, how to do it, what to expect, and what input you should provide.
- Preserve strict scope: `1 phase = 1 test`, and keep production changes limited to default-preserving testability seams/keys or small architecture-safe boundary fixes.

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- This slice is mixed test-type and test-heavy (`3` widget + `7` integration), so `@PlanCritic` v2.1 **Gate 0: Test Infrastructure Gate** must block execution until shared harnesses and dev dependencies exist.
- Repo currently has no `integration_test/` directory and `pubspec.yaml` only shows `flutter_test` in dev dependencies (no confirmed `mocktail` / `integration_test`).
- `T61` depends on `ChatScreen`, which currently has lifecycle side effects in `initState()/dispose()` and lacks stable keys for composer input/send controls.
- `T62-T63` depend on `CreateTaskScreen`, which currently violates MVVM/testability boundaries by creating `CategoriesRepository(Supabase.instance.client)` inside the view (`_loadCategories()` in `initState()`). This causes hidden Supabase IO in widget tests.
- `T64-T70` are staging-backed integration tests and require deterministic accounts, seed/reset, and fail-fast preflight checks (credentials + IDs + environment + selectors).
- `SupabaseConfig` currently hardcodes one Supabase project URL/key in code. This is acceptable only if that project is the intended staging environment for integration tests.
- `T69` is scoped to **in-app notification list tap deep-linking** (not OS push delivery/system tray behavior), consistent with the prior segment draft and lower flake risk.
- `T68` booking flow currently passes through `BookingSheet`, whose `_submit()` contains test-oriented shortcuts (e.g., forced `txnId` and `status: BookingStatus.active`), so status expectations must be locked to current code behavior or explicitly deferred.

### Decision Needed (Blocking)

- Missing decision: **Supabase environment source for `T64-T70`**
  - Options:
  - Current hardcoded `SupabaseConfig` project is the staging test project (recommended if true)
  - Refactor app to use `--dart-define` for Supabase URL/key before integration work
  - Run against production project (not recommended)
  - Recommended: first option only if you confirm the hardcoded project is staging. Otherwise block and refactor config before integration tests.
  - Plan impact: determines whether `T64-T70` can start or require an app-config change first.

- Missing decision: **`T61` ChatScreen lifecycle side-effects strategy**
  - Options:
  - Add `enableLifecycleEffects = true` seam (recommended)
  - Mock/spy all lifecycle calls on `ChatViewModel` and accept extra noise
  - Use real `ChatViewModel` in widget test (not recommended)
  - Recommended: seam + fake/mock VM for deterministic widget testing.
  - Plan impact: blocks clean T61 setup without unrelated subscription/receipt behavior.

- Missing decision: **`T62-T63` CreateTaskScreen category-loading fix strategy**
  - Options:
  - Add default-preserving categories loader/repository seam (recommended for this slice)
  - Move category loading fully into a ViewModel before tests (architecturally best, larger change)
  - Keep direct Supabase call and initialize backend in widget tests (not recommended)
  - Recommended: first option now, with architecture debt follow-up if full refactor is deferred.
  - Plan impact: blocks T62/T63 until hidden Supabase IO is removed from widget test path.

- Missing decision: **`T64` auth-clear strategy for true unauthenticated cold start**
  - Options:
  - Android-first `adb shell pm clear com.example.sline_app` before run (recommended for emulator stabilization)
  - In-app sign-out + relaunch (weaker “cold start” guarantee)
  - Custom test-only auth-reset hook in app (more code surface)
  - Recommended: first option for Android emulator baseline, then document iOS equivalent later.
  - Plan impact: determines T64 reliability and preflight tooling requirements.

- Missing decision: **`T66` exact “task/order surfaces” scope**
  - Options:
  - One surface only (e.g., task list or dashboard) for strict one-behavior test
  - Two locked surfaces (recommended if title remains plural and selectors are stable)
  - “Any visible location” (not recommended; weak contract)
  - Recommended: lock exactly two surfaces or rename the behavior in the master inventory; for this slice, lock the two surfaces explicitly.
  - Plan impact: affects selectors, test duration, and flake risk for T66.

- Missing decision: **`T67` conversation source**
  - Options:
  - Seeded conversation ID/participants (recommended)
  - Create a conversation during the test (broadens scope and time)
  - Open first available conversation from list (not deterministic)
  - Recommended: seeded conversation.
  - Plan impact: blocks deterministic T67 if unresolved.

- Missing decision: **`T68` booking status expectation under current `BookingSheet` code**
  - Options:
  - Assert current code behavior (likely immediate `active` status due test shortcut) (recommended for now)
  - Force production-like pending/request path first by code change (broader refactor)
  - Avoid status assertion and only assert presence (weaker)
  - Recommended: lock to current code behavior for this baseline and record debt to remove test shortcuts later.
  - Plan impact: prevents false failures caused by mismatch between title wording and actual implementation.

- Missing decision: **`T69` target entity type for deep-link verification**
  - Options:
  - `task` (recommended: good coverage, deterministic with seeded task)
  - `booking` (good, but overlaps with T68 data dependencies)
  - `conversation` (good, but adds chat/realtime timing sensitivity)
  - `profile` (low value; simpler but weaker deep-link coverage)
  - Recommended: `task` unless your staging seed already has a stronger `conversation` scenario.
  - Plan impact: defines seed data, destination selector, and async wait profile.

- Missing decision: **`T70` persistence check depth**
  - Options:
  - Switch role + leave/re-enter dashboard in same app session (recommended baseline)
  - Switch role + full app relaunch (stronger, slower, more harness complexity)
  - Switch role only (too weak for “persists”)
  - Recommended: first option now; add relaunch variant later if stable.
  - Plan impact: affects harness complexity and test duration.

### What Input You Should Provide Me (For This Slice)

- Confirm whether the hardcoded Supabase project in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/supabase_config.dart` is the staging test project.
- Approve widget seam package:
  - `ChatScreen` lifecycle seam + composer keys (`T61`)
  - `CreateTaskScreen` categories loader/repository seam + wizard/tier field keys (`T62-T63`)
- Confirm Android-first auth-clear strategy for `T64` (recommended: `adb pm clear` for package `com.example.sline_app`).
- Lock `T66` exact surfaces to verify (2 explicit surfaces if keeping plural wording).
- Provide deterministic seed choices/IDs for `T67`, `T68`, `T69`, `T70` (conversation, slot, notification target, multi-role user).
- Confirm `T68` status expectation under current code (recommended: assert current `active` behavior and document why).
- Confirm `T69` target entity type (recommended: `task`).
- Confirm `T70` persistence depth (recommended: same-session leave/re-enter dashboard).

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate (before all other gates)

- Status: ❌ FAIL
- Reason: No `integration_test/` directory exists yet.
- Reason: `pubspec.yaml` does not show `mocktail` or `integration_test` dev dependencies.
- Reason: No shared widget/integration harness, preflight helper, or artifact-tagging helper is locked for this slice.
- What to add/fix to pass:
  - Add test dependencies (`mocktail`, `integration_test`) and update `pubspec.lock`
  - Create `test/test_support/` and `integration_test/` helper structure
  - Add one smoke widget and one smoke integration harness proof

### 1) Data/Contracts Gate

- Status: ❌ FAIL
- Reason: `T66-T70` need staging seed/reset contract, deterministic IDs, and target selectors, none of which are locked in this slice.
- Reason: `T68` expected booking status is ambiguous because current `BookingSheet` code forces a test shortcut path.
- What to add/fix to pass: lock staging seed manifest + IDs, lock `T66` surfaces, lock `T68` status expectation, and define `T69` entity type/target selector.

### 2) Security Gate

- Status: ❌ FAIL
- Reason: Staging test accounts/roles are not defined for client/provider/multi-role scenarios (`T65-T70`).
- Reason: No explicit RLS/permission preflight checks exist for booking, chat, and dashboard role-switch scenarios.
- What to add/fix to pass: define accounts + roles + seed ownership and add preflight permission validation checks (at least positive-path sanity before running UI steps).

### 3) Backend/API Gate

- Status: ❌ FAIL
- Reason: `CreateTaskScreen` still performs direct Supabase category fetching in the view, which breaks widget-test determinism and violates MVVM boundaries.
- Reason: Integration tests lack preflight helpers for auth/session cleanup, seed validation, and async propagation timing budgets.
- What to add/fix to pass: add widget seams/boundary fix for `CreateTaskScreen`, plus integration preflight + retry/time-budget helpers.

### 4) UI/Integration Gate

- Status: ❌ FAIL
- Reason: Primary selectors/keys for `T61-T63` and several `T64-T70` interactions are not locked (chat composer, create-task wizard controls, notification list rows, dashboard role switch path).
- Reason: `T61` and `T62-T63` still have hidden side effects that can destabilize tests.
- What to add/fix to pass: add key strategy for this slice and the approved widget seams; lock integration selector fallbacks where keys are deferred.

### 5) Release/QA Gate

- Status: ❌ FAIL
- Reason: No slice-level flake policy, timeout budgets, or failure artifact conventions are defined for integration runs.
- Reason: No rerun/stabilization rule exists for the mixed widget + integration batch.
- What to add/fix to pass: define artifact path/tagging, bounded wait policies, rerun thresholds, and exact commands before marking `T61-T70` complete.

## C) Critical Gaps (Must-Fix)

- **Gap:** `CreateTaskScreen` directly creates `CategoriesRepository(Supabase.instance.client)` in the view
- **Why it will break:** `T62-T63` widget tests will hit hidden Supabase IO and violate MVVM boundaries.
- **Fix (exact step(s) to add / reorder):** Add a default-preserving categories loader/repository seam (or move category loading to ViewModel) before implementing `T62-T63`.
- **Owner:** @Architect
- **Acceptance check:** `CreateTaskScreen` can pump in widget tests with a fake categories loader and no Supabase initialization.

- **Gap:** `ChatScreen` lacks stable keys for message composer and send button
- **Why it will break:** `T61` becomes brittle or over-relies on type/text selectors, especially with multiple `GestureDetector`s and inputs.
- **Fix (exact step(s) to add / reorder):** Add stable keys for chat message input and send button (shared test keys file recommended).
- **Owner:** @Pixel
- **Acceptance check:** `T61` interacts via key-based selectors only for composer actions.

- **Gap:** `ChatScreen` lifecycle side effects run in widget tests
- **Why it will break:** `T61` can fail from unrelated subscribe/unsubscribe/receipt logic and mock noise.
- **Fix (exact step(s) to add / reorder):** Add `enableLifecycleEffects` seam (default `true`) and disable it in `T61`.
- **Owner:** @Architect / @Pixel
- **Acceptance check:** `T61` runs with fake `ChatViewModel` without subscription/receipt behavior affecting assertions.

- **Gap:** No integration test harness or `integration_test/` folder
- **Why it will break:** `T64-T70` cannot start, and every test will reinvent launch/login/preflight/retry logic.
- **Fix (exact step(s) to add / reorder):** Create `integration_test/` structure, binding bootstrap, shared helpers, and smoke integration test before any `T64+` implementation.
- **Owner:** @Architect / @Sentinel
- **Acceptance check:** One smoke integration test launches app and exits with tagged logs/artifacts.

- **Gap:** `T64` has no deterministic auth/session reset strategy for cold-start unauthenticated state
- **Why it will break:** Persistent Supabase sessions can cause false failures (app starts on main nav instead of login).
- **Fix (exact step(s) to add / reorder):** Lock Android emulator `adb pm clear com.example.sline_app` pre-step (or approved alternative) and document it in the integration preflight helper.
- **Owner:** @Supabase_Ops / @Sentinel
- **Acceptance check:** Repeated T64 runs consistently start unauthenticated with no manual cleanup.

- **Gap:** `T66` “task/order surfaces” is ambiguous
- **Why it will break:** The test may over-expand or under-test because the success contract is not explicit.
- **Fix (exact step(s) to add / reorder):** Lock two explicit surfaces and selectors before implementation.
- **Owner:** @APIContract / @Pixel / @Sentinel
- **Acceptance check:** Reviewers can state exactly where the created tender must appear.

- **Gap:** `T68` title wording conflicts with current `BookingSheet` test shortcut behavior
- **Why it will break:** Assertions may expect pending/request behavior while code currently forces `BookingStatus.active`.
- **Fix (exact step(s) to add / reorder):** Lock current-code expectation for baseline (`active` path) and document the shortcut in the phase; create follow-up debt to remove test shortcut later.
- **Owner:** @Architect / @APIContract / @Sentinel
- **Acceptance check:** T68 status assertion matches current implementation and is explained in test comments/plan.

- **Gap:** `T69` lacks a locked notification seed/entity contract and stable selectors
- **Why it will break:** In-app notification tap tests become flaky if they depend on arbitrary notifications or changing list order.
- **Fix (exact step(s) to add / reorder):** Seed a deterministic notification (recommended `task` target) and add stable selectors/unique marker for the target row.
- **Owner:** @Supabase_Ops / @APIContract / @Pixel
- **Acceptance check:** Preflight can verify the notification exists and points to a resolvable entity before UI steps run.

- **Gap:** `T70` persistence depth and success cues are not locked
- **Why it will break:** Test may pass on immediate UI toggle only, without proving persistence or data refresh.
- **Fix (exact step(s) to add / reorder):** Lock persistence check style (recommended same-session leave/re-enter) and define role-specific success cues for both states.
- **Owner:** @APIContract / @Pixel / @Sentinel
- **Acceptance check:** T70 asserts role switch + refresh completion + persisted role after re-entry, with no crash.

- **Gap:** No failure artifact / timeout / retry standards for integration tests
- **Why it will break:** Failures become hard to diagnose and flake triage stalls.
- **Fix (exact step(s) to add / reorder):** Add tagged logging, artifact path convention, bounded retry helper, and per-test timeout budgets before `T64-T70` execution.
- **Owner:** @Observability / @Sentinel
- **Acceptance check:** Failed integration runs produce tagged logs/artifacts with `Txx` identifier and timing info.

## D) Invariants & Success Criteria (Non-Negotiable)

- **Invariant:** `T61` verifies chat composer UI wiring only (send button -> `ChatViewModel.sendMessage`) and remains offline
- **How to enforce:** Add composer keys + lifecycle seam; use fake `ChatViewModel`.
- **How to verify:** `sendMessage` called with trimmed text and input clears; no realtime/subscription side effects required.

- **Invariant:** `T62` empty submit shows validation snackbar and does not call task create/update
- **How to enforce:** Use fake `TaskViewModel` with non-null user id and categories loader seam.
- **How to verify:** Snackbar appears and no `createTask`/`updateTask` calls occur.

- **Invariant:** `T63` package tier switching preserves per-tier form data
- **How to enforce:** Use keyed tier tabs/fields and switch across at least two tiers.
- **How to verify:** Previously entered values for each tier are restored when switching back.

- **Invariant:** `T64` unauthenticated cold start lands on `LoginScreen`
- **How to enforce:** Deterministic auth/session reset before app launch.
- **How to verify:** Login screen selector is visible and main-navigation selector is absent.

- **Invariant:** `T65` valid login reaches main app shell
- **How to enforce:** Use dedicated staging login account and stable login/main-nav selectors.
- **How to verify:** Main navigation success selector appears after login submit.

- **Invariant:** `T66` tender creation flow produces a uniquely identifiable task and that task appears in the locked verification surfaces
- **How to enforce:** Submit deterministic unique marker and verify exact surfaces only.
- **How to verify:** Unique marker appears in both locked surfaces within bounded wait windows.

- **Invariant:** `T67` sent chat message becomes visible in the target conversation
- **How to enforce:** Use seeded conversation + unique message marker + bounded realtime wait.
- **How to verify:** Marker text appears in conversation thread (immediately or after one bounded refresh/reopen fallback).

- **Invariant:** `T68` booking request flow reflects the booking in list/details according to current code contract
- **How to enforce:** Lock current status expectation (recommended `active` until shortcut removed) and seeded open slot.
- **How to verify:** Booking appears in list/details with the expected identifying details/status contract.

- **Invariant:** `T69` in-app notification tap navigates to the correct seeded entity screen
- **How to enforce:** Seed deterministic notification with resolvable `relatedEntityType` + `relatedEntityId` and stable target selector.
- **How to verify:** After tapping the seeded notification row, the expected destination screen selector appears.

- **Invariant:** `T70` dashboard role switch persists across the locked re-entry strategy and refreshes without crash
- **How to enforce:** Use multi-role user, role-switch UI path, and re-entry step (same-session leave/re-enter by default).
- **How to verify:** Role-specific cue after switch, role remains selected after re-entry, and no crash/error state blocks dashboard.

- **Invariant:** Integration tests fail fast on missing preconditions
- **How to enforce:** Preflight helper validates emulator/device, credentials, seed IDs, and required records before UI actions.
- **How to verify:** Missing precondition exits early with `Txx`-tagged message instead of long timeout.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|--------------|------------|----------|
| No integration harness/dev deps | T64-T70 | High | High | Feature | Tests fail to compile/run | Gate 0 bootstrap first | Block slice until harness lands |
| Hidden Supabase IO in `CreateTaskScreen` widget tests | T62-T63 | High | High | Feature | Pump fails before assertions | Categories loader seam / MVVM fix | Defer T62-T63 until seam lands |
| Chat lifecycle side effects pollute `T61` | T61 | High | Med | Local | Unexpected mock interactions/timeouts | Lifecycle seam + fake VM | Assert call subset only (weaker) |
| Persistent auth session causes false T64 failure | T64 | High | High | Feature | App starts on main nav | Deterministic auth-clear preflight | Retry after forced app data clear |
| Staging seed drift / missing IDs | T66-T70 | High | High | Feature | Preflight finds missing records | Seed/reset contract + preflight verification | Block tests and reseed |
| Realtime propagation delay flakes | T67, T69 | Med | High | Feature | Intermittent timeout after send/tap | Bounded retry helpers + timing logs | One controlled refresh/reopen fallback |
| Booking status mismatch due forced `active` shortcut | T68 | High | Med | Feature | Assertion mismatch on status | Lock current-code status expectation | Relax to presence-only temporarily (weaker) |
| UI selectors change or are ambiguous | T61-T70 | Med | Med | Feature | Finder matches multiple widgets / none | Add stable keys for primary interactions | Use unique markers + tighter finders |
| Dashboard role switch races with backend sync | T70 | Med | High | Feature | Role flips back / stale data after switch | Bounded waits + role-specific cues + re-entry check | Increase timing budget and log sync timing |
| Wrong Supabase project targeted | T64-T70 | Med | High | App-wide | Tests mutate/inspect unexpected data | Confirm hardcoded config is staging or refactor to defines | Block execution until env source fixed |
| Emulator/device performance causes wait flake | T64-T70 | Med | Med | Local | Timeouts vary by machine | Device baseline + timeout budgets | Raise budgets with telemetry, not infinite waits |
| Notification list order changes | T69 | Med | Med | Feature | Wrong notification tapped | Seed unique notification marker + row key | Filter/search by unique marker if UI allows |

## F) Pre-Mortem (How this fails in real life)

- This fails when `T62-T63` are written before removing `CreateTaskScreen`’s direct Supabase category fetch and the widget tests crash during `initState()`.
- This fails when `T61` verifies `sendMessage` but `ChatScreen` subscription/receipt side effects generate extra mock calls and hide the real regression.
- This fails when `T64` is run after a previous authenticated session and the app cold-starts into main nav, causing a false failure.
- This fails when `T64-T70` start before seed/reset is formalized and the tests spend minutes timing out on missing data.
- This fails when `T66` is implemented with vague “appears somewhere” assertions and passes even though the intended surface regressed.
- This fails when `T68` expects a pending/request status while current `BookingSheet` code forces `BookingStatus.active` for test shortcuts.
- This fails when `T69` uses an arbitrary notification row and list order changes, sending the test to the wrong destination.
- This fails when `T70` only verifies the immediate role toggle and never proves persistence after leaving/re-entering dashboard.
- This fails when integration waits rely on broad `pumpAndSettle()` and hang on spinners/realtime delays.
- This fails when the hardcoded Supabase project is not staging and test actions hit the wrong environment.

## G) Plan Fixes (Concrete Additions / Expansions)

- **Goal:** Establish a mixed widget+integration test foundation (Gate 0)
- **Why:** This slice cannot start without shared harnesses, helpers, and dev dependencies.
- **How:** Add `mocktail` + `integration_test`, create `test/test_support/` and `integration_test/support/`, and prove both harnesses with smoke tests.
- **Output artifact:** test/integration harness helpers + smoke tests + updated `pubspec.yaml`
- **Stop condition:** Gate 0 passes and smoke tests run offline/widget + on emulator/integration.

- **Goal:** Remove widget-test blockers in `ChatScreen` and `CreateTaskScreen`
- **Why:** `T61-T63` are blocked by hidden side effects and direct Supabase usage in views.
- **How:** Add default-preserving lifecycle/categories seams and stable keys; apply architecture-guard fix for category loading boundary.
- **Output artifact:** seam/key updates in `ChatScreen` and `CreateTaskScreen` (and supporting classes if needed)
- **Stop condition:** `T61-T63` screens pump with fake providers and no backend IO.

- **Goal:** Build integration preflight + seed contract for `T64-T70`
- **Why:** Deterministic staging tests require account/ID validation and fail-fast checks.
- **How:** Add preflight helper that validates emulator, credentials, seed IDs, and required records before each `Txx` flow.
- **Output artifact:** `integration_test/support/preflight.dart` (or equivalent) + seed manifest/contract doc
- **Stop condition:** Missing preconditions fail in <10s with clear `Txx`-tagged messages.

- **Goal:** Lock selectors/keys and success cues for integration flows
- **Why:** Integration tests are too expensive to debug when selectors are unstable or ambiguous.
- **How:** Add stable keys for critical interactions (login, chat send, create-task wizard, notifications, dashboard role switch), and document approved text fallbacks.
- **Output artifact:** key constants + selector map notes in this plan / test helpers
- **Stop condition:** Each integration phase names a stable primary selector and a fallback.

- **Goal:** Add flake controls + failure artifact conventions
- **Why:** `T64-T70` involve network/realtime and need bounded waits and diagnosable failures.
- **How:** Add retry/time-budget helpers, tagged logging (`Txx`), and artifact path convention.
- **Output artifact:** integration retry helper + artifact/logging helper + run docs
- **Stop condition:** Failed runs show `Txx`, step name, and timing budget exceeded reason.

- **Goal:** Add per-phase input requirements and gate checks
- **Why:** Makes staging/account/seed blockers explicit before implementation starts.
- **How:** Include `What Input You Should Provide Me` and `GATE CHECK` in every phase.
- **Output artifact:** Per-phase execution-ready content below
- **Stop condition:** Implementer can start each phase with no hidden decision work.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Slice Dependency Order (T61-T70)

1. Gate 0 foundation: dev dependencies, widget/integration harnesses, smoke tests.
2. Lock blocking decisions (Section A): environment source, seams, T66/T68/T69/T70 scope details.
3. Apply seam-only/widget boundary fixes for `T61-T63` (`ChatScreen`, `CreateTaskScreen`).
4. Implement widget tests `T61-T63` and stabilize.
5. Build integration preflight + seed contract + artifact/retry helpers.
6. Implement integration tests `T64-T70` in dependency order (startup/auth -> create/chat/booking -> deep link -> role persistence).
7. Run slice QA gate (reruns, flake check, traceability signoff) before moving on.

### Shared Implementation Rules (Applies to T61-T70)

- [ ] (@Architect) Production code changes are limited to default-preserving keys/DI/seams and architecture-safe boundary fixes.
- [ ] (@Sentinel) Widget tests (`T61-T63`) must not hit live Supabase/network/plugin paths.
- [ ] (@Supabase_Ops) Integration tests (`T64-T70`) run only against confirmed staging environment with seeded deterministic data.
- [ ] (@Observability) All integration failures are tagged with `Txx` and emit bounded-wait timing logs.
- [ ] (@Pixel) Use keys for primary interactions; text/type finders are fallback only when the label is part of the user-visible contract.
- [ ] (@Sentinel) One phase = one test contract. Local subcases allowed only when the title explicitly implies multiple transitions (e.g., `T70` re-entry persistence check).

### Slice QA/Release Gate (Before Marking T61-T70 Complete)

- [ ] (@Sentinel) `flutter test /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/chat /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/tasks` passes for `T61-T63`.
- [ ] (@Sentinel) `flutter test /Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test` passes for `T64-T70` on the locked Android emulator profile.
- [ ] (@Sentinel) Re-run flaky candidates once: `T67`, `T68`, `T69`, `T70` with same seed/reset baseline.
- [ ] (@Observability) Failed-run artifacts/logs (if any) are present and tagged by `Txx`.
- [ ] (@Sentinel) All blocking decisions from Section A are resolved and reflected in helper code/comments/assertions.
- **GATE CHECK:** `T61-T70` is stable and merge-ready before closing the 70-test baseline plan.

## Phase 61: T61 - ChatScreen sending text triggers sendMessage call

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T61` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/chat/chat_screen_test.dart`.

### Why

- This protects the core chat composer wiring (`send` action -> `ChatViewModel.sendMessage`) and catches regressions in a high-frequency interaction.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/chat/chat_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/view/chat_screen.dart`.
- Test case target: `ChatScreen sending text triggers sendMessage call`.
- `ChatScreen` lifecycle seam (recommended: `enableLifecycleEffects = true` default) to disable subscribe/receipt calls in widget tests.
- Stable keys for message input and send button.
- Fake/mock `ChatViewModel` with `sendMessage(String, ...)` verification and safe defaults for `currentMessages`, `currentUserId`, and active conversation handling.
- `Conversation` fixture with `taskId: null` (avoid `ChatContextWidget` TaskViewModel dependency).
- `pumpApp` widget harness with `ChangeNotifierProvider<ChatViewModel>`.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Add/confirm `ChatScreen` lifecycle seam and stable composer keys (default behavior preserved).
- [ ] (@Pixel) Pump `ChatScreen` with lifecycle disabled, fake/mock `ChatViewModel`, and a no-task conversation fixture.
- [ ] (@Pixel) Enter padded text in the message input, tap send, and verify `sendMessage` receives trimmed text.
- [ ] (@Pixel) Assert the input field is cleared after successful send-trigger path.
- [ ] (@Sentinel) Review that the test verifies composer wiring only (not offer/image branches).
- **Verify (@Sentinel):** `T61` remains one scenario and does not duplicate `T59/T60` render branch tests.

### How To Do It

- Use `tester.enterText` on a keyed input and tap the keyed send button.
- Stub the fake/mock `ChatViewModel` so `sendMessage` is a no-op and does not mutate unrelated state.
- After tap, `pump()` once and assert the field text is empty plus verify the call argument is trimmed.
- Keep `Conversation.taskId` null to avoid `ChatContextWidget` dependency path.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Stable regression coverage for chat composer send wiring and trim behavior.
- Fast feedback if send button stops dispatching or input no longer clears.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve `ChatScreen` lifecycle seam + composer keys (recommended).
- Confirm assertion depth (recommended: `sendMessage` trimmed text + input cleared).
- Optional: confirm exact test input string for trim assertion (recommended: `'  hello  '` -> `'hello'`).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T61` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/chat/chat_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- Chat composer send action calls `sendMessage` with trimmed text and clears the input offline with lifecycle side effects disabled.
- This phase is not complete until the test passes locally and reviewer confirms no hidden chat subscription behavior is required.

---

## Phase 62: T62 - CreateTaskScreen submit with empty fields shows validation snackbar

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T62` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/tasks/create_task_screen_test.dart`.

### Why

- This protects a core form validation path and prevents silent invalid submissions after UI refactors.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/tasks/create_task_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/create_task_screen.dart`.
- Test case target: `CreateTaskScreen submit with empty fields shows validation snackbar`.
- Mandatory widget-test blocker fix: categories loader/repository seam (or ViewModel refactor) so `CreateTaskScreen` does not call `Supabase.instance.client` directly in widget tests.
- Stable keys for wizard navigation actions (Next/Create) and, if needed, step markers.
- Fake/mock `TaskViewModel` with:
  - non-null `currentUserId` (to keep the validation path isolated)
  - spies on `createTask` / `updateTask`
- `pumpApp` harness with `ChangeNotifierProvider<TaskViewModel>` and snackbar-capable `ScaffoldMessenger` context.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Add/confirm categories loader/repository seam for `CreateTaskScreen` and keep default behavior unchanged.
- [ ] (@Pixel) Add/confirm stable keys for the wizard action button(s) used to reach submit.
- [ ] (@Pixel) Pump `CreateTaskScreen` with fake categories loader + fake `TaskViewModel`, advance to submit step, tap submit with empty title/description.
- [ ] (@Pixel) Assert validation snackbar text appears and no task create/update calls occur.
- [ ] (@Sentinel) Review that the test is validating the empty-field branch, not category loading or actual task submission.
- **Verify (@Sentinel):** `T62` remains one scenario and does not overlap with T63 package-tier state behavior.

### How To Do It

- Inject a fake categories loader returning an empty list (or deterministic small list) immediately.
- Use keyed Next/Create button taps to move from step 1 -> step 2 -> step 3 without filling title/description.
- Tap submit and use bounded `pump()` / `pumpAndSettle()` to surface the snackbar.
- Verify zero interactions with `createTask` and `updateTask`.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Reliable coverage of client-side validation feedback on the create-task wizard.
- Early detection if validation is bypassed or the snackbar message disappears.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve the `CreateTaskScreen` categories seam strategy (recommended: default-preserving loader/repository seam for this slice).
- Confirm snackbar assertion mode for T62 (recommended: exact string `Please fill in title and description` if copy is stable).
- Optional: confirm whether to assert both `createTask` and `updateTask` were not called (recommended: yes).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T62` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/tasks/create_task_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- Empty submit path shows validation snackbar and performs no create/update call, with no hidden Supabase category fetch during widget test pump.
- This phase is not complete until the test passes locally and reviewer confirms the MVVM/testability blocker is resolved.

---

## Phase 63: T63 - CreateTaskScreen booking package tier switch preserves entered tier data

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T63` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/tasks/create_task_screen_test.dart`.

### Why

- This protects complex per-tier form-state behavior in the booking package editor, which is easy to regress and difficult to catch manually.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/tasks/create_task_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/create_task_screen.dart`.
- Test case target: `CreateTaskScreen booking package tier switch preserves entered tier data`.
- Same categories loader/repository seam from T62 (mandatory).
- Stable keys for:
  - task-type selector (`Booking`)
  - wizard next actions
  - package tier tabs (`Basic`, `Standard`, `Premium`)
  - package field inputs (price, delivery, revisions, description)
- Fake/mock `TaskViewModel` (no submission needed; can remain mostly inert).
- `pumpApp` harness with `TaskViewModel` provider.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Reuse/confirm categories seam and key additions from T62 for tier tabs and package fields.
- [ ] (@Pixel) Pump `CreateTaskScreen`, switch task type to booking, navigate to booking logistics step.
- [ ] (@Pixel) Enter values in one tier, switch tiers, enter different values, switch back, and assert original values persist.
- [ ] (@Sentinel) Review that the test targets per-tier state preservation and not final submit behavior.
- **Verify (@Sentinel):** `T63` remains one scenario and does not duplicate `T62` validation coverage.

### How To Do It

- Use keys for tier tabs and package fields to avoid label/hint ambiguity.
- Fill at least two fields per tier (recommended: `price` + `description` for clarity), then switch `Basic -> Standard -> Basic`.
- Optionally assert the Standard tier values are also preserved when switching back again if kept concise.
- Use bounded pumps around animated tab/tile state transitions.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Strong regression protection for booking package tier state retention logic.
- Early detection if shared controllers or tier-switch logic starts overwriting per-tier data.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve the `CreateTaskScreen` seam + key package from T62 (required here too).
- Confirm field assertion scope (recommended: assert `price` + `description` per tier; add all 4 fields only if still readable).
- Optional: confirm whether to verify two tiers only (`Basic` + `Standard`) or include `Premium` as well (recommended: two tiers for baseline stability).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing widget test implementing `T63` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/tasks/create_task_screen_test.dart`.
- Any seam/key added remains reusable and default-preserving in production behavior.

### GATE CHECK

- Booking package tier switching preserves previously entered per-tier values in the keyed fields, with no hidden category IO during widget tests.
- This phase is not complete until the test passes locally and reviewer confirms tier-state behavior (not visual styling) is the asserted contract.

---

## Phase 64: T64 - Cold start unauthenticated lands on login

> Primary: @Supabase_Ops
> Supporting: @Observability, @Sentinel

### Goal

- Implement and stabilize `T64` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/app_startup_login_flow_test.dart`.

### Why

- Startup auth routing is a critical reliability path. A persistent session or misrouted startup can mask auth bugs across the entire app.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/app_startup_login_flow_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart`.
- Test case target: `Cold start unauthenticated lands on login`.
- Integration harness bootstrap (`integration_test` binding + app launch helper).
- Deterministic auth/session reset strategy for **cold** start (recommended Android-first: `adb shell pm clear com.example.sline_app`).
- Locked Android emulator target (name/id) for the first-pass stabilization run.
- Stable login-screen selector (prefer key from earlier login-widget slice; fallback to a strong text signal if key not yet available).
- Preflight helper that fails fast if emulator or reset command is unavailable.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Supabase_Ops) Lock and document the auth-clear pre-step (recommended `adb pm clear`) for Android emulator runs.
- [ ] (@Architect) Add integration harness + preflight helper support used by `T64`.
- [ ] (@Observability) Add `T64`-tagged logging/artifact capture on startup and selector wait failure.
- [ ] (@Sentinel) Implement `T64`: run preflight/reset, cold-launch app, assert login screen appears.
- **Verify (@Sentinel):** `T64` remains one scenario and does not include login submission (covered by T65).

### How To Do It

- Execute preflight that validates emulator connectivity and reset capability.
- Clear app data/session using the locked strategy, then launch app via `app.main()` (or a shared launch helper wrapping it).
- Wait on a bounded login selector; also assert main-navigation success selector is absent to avoid false positives.
- Log startup timing and auth-reset method under `T64` tag.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Deterministic startup auth-route coverage with strong signal when session cleanup or startup routing regresses.
- Fast failure if the environment/preconditions are not ready.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm Android emulator target for baseline integration stabilization (name/id).
- Confirm `T64` auth-clear strategy (recommended: `adb shell pm clear com.example.sline_app`).
- Confirm login-screen success selector (recommended: keyed login button/field from earlier slices if available).
- If you provide nothing, I will use the defaults/recommendations documented in Section A (and keep `T64` blocked until emulator/reset details are provided).

### Result (Expected Output Artifact)

- One passing integration test implementing `T64` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/app_startup_login_flow_test.dart`.
- Shared preflight/reset helper introduced for this phase remains reusable for `T65-T70`.

### GATE CHECK

- App starts cold in an unauthenticated state and lands on `LoginScreen` deterministically on the locked emulator.
- This phase is not complete until the test passes on repeated runs with no manual cleanup between runs.

---

## Phase 65: T65 - Login happy path lands on main navigation

> Primary: @Supabase_Ops
> Supporting: @Observability, @Sentinel

### Goal

- Implement and stabilize `T65` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/app_startup_login_flow_test.dart`.

### Why

- This validates the core auth success path and ensures users can reach the main app shell from login.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/app_startup_login_flow_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart`.
- Test case target: `Login happy path lands on main navigation`.
- Reuse `T64` harness/preflight/auth-reset helpers.
- Dedicated staging login account credentials (email + password secret reference).
- Stable selectors for login fields/button and main-navigation success state.
- Bounded auth/login wait timeout and failure tagging (`T65`).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Supabase_Ops) Provide and validate staging login account credentials in the integration secret/input path.
- [ ] (@Pixel) Confirm stable selectors for login form and main nav success surface (prefer keys if available).
- [ ] (@Sentinel) Implement `T65`: start from unauthenticated state, enter creds, submit, assert main nav surface.
- [ ] (@Observability) Add `T65` timing and failure artifact tags.
- **Verify (@Sentinel):** `T65` remains one scenario and does not test post-login feature flows (covered in later phases).

### How To Do It

- Use the same auth-reset preflight as `T64` to ensure test independence.
- Launch app, wait for login selector, enter credentials, tap login, and wait on bounded main-navigation selector.
- Record the login duration and capture tagged failure artifacts if the selector times out.
- Keep assertions focused on successful transition to app shell, not downstream feature content.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- High-value integration coverage of login success routing and auth wiring.
- Clear failure separation between auth-preconditions (`T64`) and login action/result (`T65`).
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Provide staging login account email + password secret reference (or exact local secret injection path).
- Confirm main-navigation success selector (recommended: a keyed main-nav element like FAB or a unique nav shell control).
- Optional: confirm login timeout budget (recommended initial: 15-20s on emulator, tuned after first run).
- If you provide nothing, I will keep `T65` blocked on missing credentials.

### Result (Expected Output Artifact)

- One passing integration test implementing `T65` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/app_startup_login_flow_test.dart`.
- Login helper utilities remain reusable for `T66-T70`.

### GATE CHECK

- Valid login credentials consistently transition from login screen to main navigation on the locked emulator.
- This phase is not complete until the test passes with tagged logs/artifacts and no manual intervention.

---

## Phase 66: T66 - Create tender task flow form submit appears in task/order surfaces

> Primary: @Supabase_Ops
> Supporting: @APIContract, @Pixel, @Observability, @Sentinel

### Goal

- Implement and stabilize `T66` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/create_tender_task_flow_test.dart`.

### Why

- This is a high-value cross-layer flow: form input, submission, backend persistence, and downstream visibility.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/create_tender_task_flow_test.dart`.
- Primary implementation targets:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/create_task_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/app/main_navigation_screen.dart`
- Test case target: `Create tender task flow form submit appears in task/order surfaces`.
- Locked staging account authorized to create tender tasks.
- Locked category seed data and selectors for form completion.
- Stable selectors/keys for main-nav create-task entry and create-task wizard actions/fields (`T51-T63` seam pack dependencies).
- **Blocking scope lock:** exact two verification surfaces for “task/order surfaces” (must be explicit).
- Unique marker strategy for created task title (e.g., `T66_<timestamp>` prefix).
- Bounded retry helper for eventual visibility after create.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@APIContract) Lock the two verification surfaces and their success selectors for `T66`.
- [ ] (@Supabase_Ops) Provide task-creator staging account + category seed details.
- [ ] (@Pixel) Confirm selectors/keys for create-task flow interactions.
- [ ] (@Sentinel) Implement `T66`: create tender task with unique marker, then verify appearance in the two locked surfaces.
- [ ] (@Observability) Tag all waits/retries and failures with `T66`.
- **Verify (@Sentinel):** `T66` remains one scenario and does not add unrelated edit/delete assertions.

### How To Do It

- Start from logged-in state (using shared login helper) with the correct test account.
- Open `CreateTaskScreen`, keep/select tender mode, fill deterministic required fields (title/description/category/budget as needed), and submit.
- Capture the unique marker and verify it appears in each locked surface using bounded retries only where propagation is expected.
- Avoid bundling cleanup/delete behavior unless required by seed policy; prefer reset/seed cleanup outside the test.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- High-confidence validation that tender creation persists and becomes visible in the app’s expected follow-up surfaces.
- Strong regression signal for create-task flow wiring and downstream data refresh.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Lock the exact two `T66` verification surfaces (required).
- Provide staging task-creator account credentials/secret reference.
- Provide category seed IDs/names and any other deterministic form inputs required by your staging data.
- Optional: confirm timeout/retry budget for downstream visibility (recommended initial: 10-20s bounded with logging).
- If you provide nothing, `T66` remains blocked due ambiguous success contract.

### Result (Expected Output Artifact)

- One passing integration test implementing `T66` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/create_tender_task_flow_test.dart`.
- Reusable create-task and visibility assertion helpers for later flows (if any) are added without changing production behavior.

### GATE CHECK

- A uniquely identifiable tender task is created and appears in the two locked verification surfaces within bounded waits.
- This phase is not complete until the test passes from a reset/seed baseline with tagged logs/artifacts.

---

## Phase 67: T67 - Chat flow open conversation send message message visible

> Primary: @Supabase_Ops
> Supporting: @APIContract, @Observability, @Sentinel

### Goal

- Implement and stabilize `T67` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/chat_message_flow_test.dart`.

### Why

- This validates a core messaging flow across UI, ViewModel, backend persistence, and realtime/refresh visibility.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/chat_message_flow_test.dart`.
- Primary implementation targets:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/view/messages_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/view/chat_screen.dart`
- Test case target: `Chat flow open conversation send message message visible`.
- Seeded deterministic conversation (recommended) with accessible participants for the logged-in account.
- Stable selectors/keys for opening the conversation row, chat input, and send button (chat composer keys from `T61` should be reused).
- Unique message marker strategy (e.g., `T67_<timestamp>`).
- Bounded realtime visibility wait budget + fallback strategy (e.g., one refresh/reopen if immediate echo is not reliable).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@APIContract) Lock seeded conversation contract (IDs/participants/visible cue) for `T67`.
- [ ] (@Supabase_Ops) Provide chat-capable staging account and seed/reset details.
- [ ] (@Sentinel) Implement `T67`: open seeded conversation, send unique marker message, assert marker visible in thread.
- [ ] (@Observability) Log realtime wait timings and fallback usage under `T67`.
- **Verify (@Sentinel):** `T67` remains one scenario and does not include message deletion/read receipt assertions.

### How To Do It

- Use preflight to verify the seeded conversation exists and is visible/openable for the account.
- Navigate to Messages, open the seeded conversation, enter unique message marker, tap send.
- Wait on bounded message visibility in the thread; if needed, perform one controlled refresh/reopen fallback and log that it was used.
- Assert the unique marker text is visible in the conversation view.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Valuable end-to-end coverage of chat send and UI visibility under realistic backend timing.
- Clear regression signal if message send or thread rendering breaks.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Provide seeded conversation ID/participants and the visible cue used to open the correct conversation row.
- Provide the staging account credentials/secret reference for this conversation.
- Confirm realtime fallback policy (recommended: one bounded refresh/reopen fallback only).
- Optional: confirm timeout budget (recommended initial: 10-15s bounded with timing logs).
- If you provide nothing, `T67` remains blocked on deterministic conversation seed details.

### Result (Expected Output Artifact)

- One passing integration test implementing `T67` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/chat_message_flow_test.dart`.
- Reusable chat open/send/wait helpers are added for integration stability.

### GATE CHECK

- The seeded conversation opens, a unique marker message is sent, and the marker becomes visible within the bounded wait strategy.
- This phase is not complete until the test passes from a reset/seed baseline with realtime timing logged.

---

## Phase 68: T68 - Booking request flow select slot book list/details reflect booking

> Primary: @Supabase_Ops
> Supporting: @APIContract, @ThreatModeler, @Observability, @Sentinel

### Goal

- Implement and stabilize `T68` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/booking_request_flow_test.dart`.

### Why

- This is a high-risk transactional path covering slot selection, booking creation, and downstream booking visibility in list/details UI.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/booking_request_flow_test.dart`.
- Primary implementation targets:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/view/availability_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/view/booking_sheet.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/view/bookings_list_screen.dart`
- Test case target: `Booking request flow select slot book list/details reflect booking`.
- Seeded deterministic provider/task/slot IDs with an open slot available to the test client account.
- Stable selectors/keys (or locked fallback text) for:
  - slot row/card
  - `BookingSheet` request button (`Request Booking`)
  - booking list/details entry selectors
- **Blocking contract lock:** current booking status expectation under `BookingSheet` shortcut behavior (recommended: assert current `active` path or presence-only if status is unstable).
- Bounded wait helper for post-submit list/details visibility.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@APIContract) Lock `T68` expected booking status/contract to match current `BookingSheet` implementation.
- [ ] (@Supabase_Ops) Provide client account + seeded provider/task/slot data and reset policy preventing slot conflicts across reruns.
- [ ] (@Sentinel) Implement `T68`: open availability, select seeded slot, submit booking, verify booking in list and details.
- [ ] (@ThreatModeler) Confirm the test account has valid permissions for the booking action and is not using elevated/manual state.
- [ ] (@Observability) Tag waits and failures with `T68` and include slot/task identifiers in logs.
- **Verify (@Sentinel):** `T68` remains one scenario and does not expand into accept/decline/payment paths.

### How To Do It

- Run preflight to verify the seeded slot is present and open before launching the UI flow.
- Navigate to the booking availability flow (via locked route/UI entry), tap the seeded slot, and submit from `BookingSheet`.
- Capture a deterministic identifier (slot range, note marker if used, task/provider combo) and verify the booking appears in the booking list and its details screen.
- Use bounded retries for backend propagation only where necessary, and log whether current-code shortcut status (`active`) was observed.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- High-value coverage of booking request creation and downstream booking visibility.
- Early detection of breakage in availability -> sheet -> booking creation -> list/details flow.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Provide seeded provider/task/slot IDs and the client account used for the booking request.
- Confirm `T68` status expectation under current code (recommended: lock to current `active` behavior if that is what staging produces).
- Confirm entry strategy (recommended: start from the app flow that reaches `AvailabilityScreen`; if too unstable, approve a helper route entry and document it).
- Optional: confirm list/details success selectors and timeout budget.
- If you provide nothing, `T68` remains blocked on seed/status contract ambiguity.

### Result (Expected Output Artifact)

- One passing integration test implementing `T68` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/booking_request_flow_test.dart`.
- Reusable booking flow helpers/preflight checks are added without changing production behavior.

### GATE CHECK

- Selecting the seeded slot and submitting the booking results in a verifiable booking entry in list/details under the locked status contract, with no flaky unbounded waits.
- This phase is not complete until the test passes on a clean seed/reset baseline and the status expectation is documented.

---

## Phase 69: T69 - Notification tap deep-links to correct entity screen

> Primary: @Supabase_Ops
> Supporting: @APIContract, @Pixel, @Observability, @Sentinel

### Goal

- Implement and stabilize `T69` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/notification_deeplink_flow_test.dart`.

### Why

- This validates a multi-layer chain: in-app notification UI -> NotificationViewModel -> `DeepLinkService` -> destination navigation.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/notification_deeplink_flow_test.dart`.
- Primary implementation targets:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/notifications/view/notifications_modal.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/deep_link_service.dart`
- Test case target: `Notification tap deep-links to correct entity screen`.
- Scope lock: **in-app notification list tap** only (not OS push/system tray).
- Seeded deterministic notification row for the logged-in account with resolvable `relatedEntityType` + `relatedEntityId`.
- **Blocking contract lock:** chosen entity type for this baseline (recommended: `task`).
- Stable selectors/keys (or locked fallback text) for notification bell/button, notifications modal row, and target destination screen cue.
- Bounded wait helper for `DeepLinkService` loading dialog + destination fetch/navigation.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@APIContract) Lock `T69` entity type and destination selector (recommended `task`).
- [ ] (@Supabase_Ops) Provide seeded notification + target entity IDs and account credentials.
- [ ] (@Pixel) Confirm selectors for opening notifications UI and tapping the seeded row (keys preferred if available).
- [ ] (@Sentinel) Implement `T69`: open notifications, tap seeded notification, assert destination screen.
- [ ] (@Observability) Tag deep-link timing and failures with `T69` (including entity type/id in logs).
- **Verify (@Sentinel):** `T69` remains one scenario and does not test notification delivery/streaming reliability.

### How To Do It

- Run preflight to verify the seeded notification exists and the target entity is resolvable.
- Open the in-app notifications UI, locate the seeded notification row by unique marker, and tap it.
- Account for modal-close + deep-link loading dialog sequencing with bounded waits.
- Assert the destination screen cue for the locked entity type (e.g., task details title/marker if `task`).
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Valuable coverage of in-app deep-link navigation from notifications.
- Clear signal if notification tap no longer routes correctly or deep-link fetch/navigation breaks.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm `T69` target entity type (recommended: `task`).
- Provide seeded notification ID/details + related entity ID and account credentials.
- Confirm destination success selector for the chosen entity type.
- Optional: approve adding stable keys for notification bell and/or notification rows if selector stability is currently weak.
- If you provide nothing, `T69` remains blocked on seed/entity contract.

### Result (Expected Output Artifact)

- One passing integration test implementing `T69` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/notification_deeplink_flow_test.dart`.
- Shared deep-link wait/assert helpers are added for integration diagnostics.

### GATE CHECK

- Tapping the seeded in-app notification row navigates to the correct destination screen for the locked entity type within bounded waits.
- This phase is not complete until the test passes with deterministic seed data and `T69`-tagged timing logs.

---

## Phase 70: T70 - Dashboard role switch persists and refreshes data without crash

> Primary: @Supabase_Ops
> Supporting: @APIContract, @ThreatModeler, @Observability, @Sentinel

### Goal

- Implement and stabilize `T70` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/dashboard_role_switch_flow_test.dart`.

### Why

- This is a stateful high-risk flow combining UI role switching, backend persistence, cache behavior, and dashboard data refresh under real network conditions.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/dashboard_role_switch_flow_test.dart`.
- Primary implementation targets:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/dashboard_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/viewmodels/dashboard_view_model.dart`
- Test case target: `Dashboard role switch persists and refreshes data without crash`.
- Multi-role staging user with permission to switch between freelancer/client.
- Locked initial role state (or a preflight step that normalizes it before test actions).
- Stable selectors/keys (or fallback text/icon selectors) for dashboard entry, settings button, and role switch controls.
- **Blocking contract lock:** persistence depth (recommended same-session leave/re-enter dashboard) and role-specific success cues.
- Bounded wait helper for post-switch `_loadData(forceRefresh: true)` refresh completion.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@APIContract) Lock `T70` persistence strategy and role-specific success cues.
- [ ] (@Supabase_Ops) Provide multi-role account credentials and initial-role normalization method.
- [ ] (@ThreatModeler) Confirm account permissions and that the flow does not rely on elevated/manual backend mutations outside seed/reset.
- [ ] (@Sentinel) Implement `T70`: enter dashboard, switch role via settings dialog, verify refreshed UI, leave/re-enter dashboard, verify persisted role and no crash.
- [ ] (@Observability) Tag role-switch timing, refresh timing, and re-entry timing under `T70`.
- **Verify (@Sentinel):** `T70` remains one scenario and does not expand into all dashboard tab validations.

### How To Do It

- Run preflight to confirm the multi-role account and initial role state; normalize if required.
- Navigate to Dashboard, open settings, switch role, and wait on a bounded role-specific cue indicating refresh completion.
- Leave Dashboard (navigate to another tab) and return, then assert the selected role persisted and dashboard renders without crash/error overlay.
- If immediate backend sync timing is variable, log timings and use a bounded retry helper keyed to the role-specific cue.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Strong end-to-end coverage of role switch persistence and dashboard stability.
- Early detection of regressions in cache/backend role sync or post-switch reload behavior.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Provide multi-role user credentials and the expected initial role (or permission to normalize it during preflight).
- Confirm `T70` persistence depth (recommended: same-session leave/re-enter dashboard).
- Provide role-specific success cues/selectors for both roles (e.g., labels/counters/cards that reliably differ).
- Optional: approve adding stable keys for dashboard settings and role buttons if selector stability is weak.
- If you provide nothing, `T70` remains blocked on account/cue ambiguity.

### Result (Expected Output Artifact)

- One passing integration test implementing `T70` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/dashboard_role_switch_flow_test.dart`.
- Reusable dashboard role-switch integration helpers are added with tagged observability and bounded waits.

### GATE CHECK

- Dashboard role switch updates the role, refreshes data, and remains stable after the locked re-entry step with no crash.
- This phase is not complete until the test passes on the multi-role account with deterministic cues and `T70`-tagged timing logs.

## I) Change Report (Diff-Style)

### 1) Original Issues Summary

- The previous `T61-T70` file used a useful high-level roadmap, but it was not in `@PlanCritic` A-I format.
- It grouped prerequisites as meta-phases instead of giving **1 phase = 1 test** for `T61-T70`.
- It did not include per-test `Goal/Why/What We Need/What To Do/How/What To Expect/What Input/Result/GATE CHECK` sections.
- It did not explicitly call out the biggest real-code blockers in this slice:
  - `CreateTaskScreen` direct Supabase category fetch in the view
  - `ChatScreen` lifecycle side effects and missing composer keys
  - no `integration_test/` directory or dev deps
  - `T68` current booking status shortcut mismatch risk
- It listed inputs for integration broadly, but not per-test blocking inputs.

### 2) Added Steps (bullet list)

- Added full `@PlanCritic` structure: `A` through `I`.
- Added **Gate 0: Test Infrastructure Gate** and marked it `FAIL` with concrete blockers.
- Added gate assessments for Data/Contracts, Security, Backend/API, UI/Integration, Release/QA.
- Added critical gaps with owners and acceptance checks.
- Added risk register and pre-mortem tied to real code and staging behavior.
- Added shared fixes for harness, seams, seed/preflight, selectors, and artifact/retry policy.
- Rewrote all `10` test phases (`T61-T70`) into one-test execution phases with full required subsections.
- Added per-test blocking input prompts for widget seams and integration accounts/IDs/selectors/timeouts.

### 3) Removed Steps (if any)

- Removed the old prerequisite letter phases (`Phase A`..`Phase G`) as standalone execution phases to preserve `1 phase = 1 test` strictness.
- Removed broad, shared-only per-test descriptions that lacked direct gate checks and input requirements.

### 4) Reordered Steps (from → to)

- From: broad prerequisite phases mixed with grouped test buckets
- To: gate-based shared prerequisites in Section `H`, followed by strictly ordered one-test phases `T61` → `T70`
- From: integration inputs grouped only once
- To: global slice inputs in `A` plus per-phase input requirements for each `T61-T70`

### 5) Expanded Steps (what became more detailed)

- `T61-T63` now explicitly document widget-test seams, keys, fake providers, and hidden side effects.
- `T64-T70` now explicitly document staging preflight, account/seed requirements, selector strategy, bounded waits, and artifact tagging.
- `T68` now explicitly calls out current `BookingSheet` shortcut behavior and blocks status assertions until the contract is locked.
- `T69` now explicitly locks in-app notification tap scope and requires a seeded notification/entity contract.
- `T70` now explicitly requires persistence depth and role-specific success cues, not just a role-toggle tap.

### 6) Why (short, practical)

- This slice is the most execution-sensitive segment because it introduces integration tests. Without strict gates, preflight, and per-test inputs, it will fail late and consume time in flake triage.
- The rewrite converts hidden dependencies and ambiguous expectations into explicit decisions and fail-fast checks.

### 7) Residual Risks (what still remains risky even after fixes)

- Staging drift (schema/data/RLS) can still break `T64-T70` if seed/reset contract is not maintained.
- Realtime timing variability may still require tuning `T67/T69/T70` budgets per emulator/CI environment.
- `T68` remains coupled to current `BookingSheet` shortcut behavior until that code is refactored.
- Selector stability depends on completing key additions from earlier slices and this slice’s seam/key work.
