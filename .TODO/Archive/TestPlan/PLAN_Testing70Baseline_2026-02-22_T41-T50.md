# 📌 Plan Segment: 70-Test Baseline (T41-T50) — Re-improved with @PlanCritic

- Source master plan: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22.md`
- Segment file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22_T41-T50.md`
- Included phases/tests: `T41` to `T50` (SignedUrlCache + DashboardCacheService + DemoPaymentService + LoginScreen widgets + MainNavigationScreen widget)
- Audit method applied: `@PlanCritic` from `.agent/workflows/plan_critic.md`

## Purpose

- Turn the `T41-T50` slice into an execution-safe, gate-based mini-plan with explicit cache/utility contracts and widget-testability seams.
- Make each test phase implementation-ready: what we need, what to do, how to do it, what to expect, and what input you should provide.
- Preserve strict scope: `1 phase = 1 test` and no production behavior changes beyond approved testability seams.

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- This slice mixes unit tests (`T41-T45`) and widget tests (`T46-T50`) and should still run fully offline.
- `SignedUrlCache` and `CrashReportingService.instance` are global/static state and require explicit cleanup in tests.
- `DashboardCacheService` tests can use `SharedPreferences.setMockInitialValues({})` and a real `SharedPreferences` instance in-memory (no device storage access).
- `LoginScreen` currently constructs `AuthViewModel()` internally and `AuthViewModel` starts a Supabase auth listener on construction, which blocks clean widget tests without seams.
- `MainNavigationScreen` currently builds heavy real child screens by default; widget tests should inject lightweight stub screens for determinism.
- `T44` wording “all keys” is ambiguous unless we lock scope to the keys actually managed by `DashboardCacheService.clearCache()`.

### Decision Needed (Blocking)

- Missing decision: **T44 scope for “all keys”**
  - Options:
  - Dashboard cache keys managed by `clearCache()` only (recommended)
  - Dashboard keys + `user_role` cache key
  - Any SharedPreferences key in the app (not recommended; false contract)
  - Recommended: first option because it matches the current implementation and avoids misleading test expectations.
  - Plan impact: determines T44 assertions and whether `user_role` is asserted as preserved.

- Missing decision: **T45 failure-path “logs” observable**
  - Options:
  - Fake `CrashReportingService` capture (recommended)
  - `debugPrint` output interception (brittle)
  - Throw-only assertion (too weak for title)
  - Recommended: fake crash-report capture because `AppLogger.e` forwards failures there and it is stable to assert.
  - Plan impact: defines test setup and cleanup (singleton restore) for T45.

- Missing decision: **Login/Auth widget test seam package for T46-T49**
  - Options:
  - `LoginScreen` auth VM factory + `AuthViewModel` test-safe listener disable seam (recommended)
  - Try to initialize real Supabase in widget tests (not recommended)
  - Replace `LoginScreen` internals in tests only (not recommended; fake progress)
  - Recommended: first option because it is default-preserving and keeps widget tests offline.
  - Plan impact: blocks T46-T49 if unresolved.

- Missing decision: **T48 success navigation destination seam**
  - Options:
  - Add `LoginScreen` post-login destination builder seam (recommended)
  - Push real `MainNavigationScreen` and satisfy all heavy child dependencies in test (high-friction)
  - Observer-only route checks without destination build guarantees (weaker)
  - Recommended: first option, paired with `MainNavigationScreen` stub-screen injection, to preserve behavior while keeping the test lightweight.
  - Plan impact: blocks stable T48 implementation if unresolved.

- Missing decision: **T50 `MainNavigationScreen` test seam shape**
  - Options:
  - Optional injected `List<Widget> screens` with production defaults (recommended)
  - Per-tab builder callbacks (more flexible, more surface area)
  - No seam and test real `HomeScreen` (not recommended; heavy/flaky)
  - Recommended: optional screen list because it is the smallest seam that solves T50 and supports T48.
  - Plan impact: blocks a clean, deterministic T50 if unresolved.

### What Input You Should Provide Me (For This Slice)

- Confirm T44 scope: dashboard cache keys only (recommended).
- Confirm T45 log observable: fake `CrashReportingService` capture (recommended).
- Approve login/auth widget seams for T46-T49 (recommended: `LoginScreen` auth factory + test-safe `AuthViewModel` listener-disable seam).
- Approve T48 post-login destination seam (recommended: `mainNavigationBuilder`).
- Approve T50 `MainNavigationScreen` screen-list injection seam (recommended: optional `List<Widget> screens`).
- Optional: choose Error/validation/snackbar assertion strictness for T45/T49 (`exact` vs `contains`).
- Optional: confirm T40/T41 cache size assertions and T44 `user_role` preservation assertion (recommended: yes for all if kept concise).

## B) Gate Status (Pass/Fail)

### 1) Data/Contracts Gate

- Status: ❌ FAIL
- Reason: `T44` key scope and `T45` log observable are ambiguous without explicit contract locks.
- Reason: Widget tests (`T46-T50`) need stable key and seam contracts before implementation starts.
- What to add/fix to pass: resolve the blocking decisions in Section A and document seam/key choices in the tests.

### 2) Security Gate

- Status: ⚠️ PARTIAL
- Reason: No RLS/network policy work here, but auth/login widget tests and payment failure logging touch security-sensitive UX paths (error feedback and re-auth boundaries).
- Reason: T45 logging assertions can leak into brittle console-output checks if not constrained.
- What to add/fix to pass: keep T45 on crash-report capture and keep T46-T49 offline with fake auth VM seams.

### 3) Backend/API Gate

- Status: ❌ FAIL
- Reason: `LoginScreen` hardcodes `AuthViewModel()` and `AuthViewModel` starts a Supabase listener, which breaks offline widget tests.
- Reason: `MainNavigationScreen` defaults to heavy real screens that pull deeper providers and side effects.
- What to add/fix to pass: add the minimal default-preserving seams for login auth VM injection, post-login destination, and main-navigation screen list injection.

### 4) UI/Integration Gate

- Status: ❌ FAIL
- Reason: No shared widget harness (`pumpApp`) and fake navigator observer setup is defined for this slice.
- Reason: Widget selectors are brittle without stable keys on login controls and stub assertion targets for main navigation.
- What to add/fix to pass: add widget harness helpers, navigator observer fake, and stable widget keys before implementing T46-T50.

### 5) Release/QA Gate

- Status: ❌ FAIL
- Reason: Global-state cleanup rules are not standardized yet (`SignedUrlCache`, `CrashReportingService.instance`, SharedPreferences mock state).
- Reason: No slice-specific run commands or re-run flake checks are locked for the mixed unit/widget set.
- What to add/fix to pass: define cleanup rules, grouped commands, and a small flake re-run requirement before merge.

## C) Critical Gaps (Must-Fix)

- **Gap:** `LoginScreen` cannot inject a fake/test auth VM
- **Why it will break:** T46-T49 widget tests will instantiate the real `AuthViewModel` and hit Supabase auth listener setup.
- **Fix (exact step(s) to add / reorder):** Add a default-preserving auth VM factory seam to `LoginScreen` before writing T46-T49.
- **Owner:** @Architect / @Pixel
- **Acceptance check:** Widget tests can pump `LoginScreen` with a fake auth VM and no Supabase initialization.

- **Gap:** `AuthViewModel` starts auth listener on construction with no test-safe disable path
- **Why it will break:** Even with a `LoginScreen` factory seam, widget tests still trigger listener startup and flaky/offline failures.
- **Fix (exact step(s) to add / reorder):** Reuse/extend the auth seam from earlier slices to disable listener startup or inject a safe auth-state stream in tests.
- **Owner:** @Architect
- **Acceptance check:** Fake/test auth VMs used by T46-T49 do not subscribe to real Supabase auth events.

- **Gap:** `LoginScreen` hardcodes `MainNavigationScreen()` on success
- **Why it will break:** T48 must navigate to main nav, but the real destination pulls heavy screens/providers and can destabilize the widget test.
- **Fix (exact step(s) to add / reorder):** Add a default-preserving post-login destination builder seam to `LoginScreen` and use it in T48 with a lightweight main-nav instance.
- **Owner:** @Architect / @Pixel
- **Acceptance check:** T48 can assert successful navigation using a lightweight main-nav destination with stub screens.

- **Gap:** `MainNavigationScreen` has no screen-list injection seam
- **Why it will break:** T50 (and T48 support) must build heavy real child screens or add many unrelated providers.
- **Fix (exact step(s) to add / reorder):** Add an optional `screens` injection seam with production defaults preserved.
- **Owner:** @Architect / @Pixel
- **Acceptance check:** T50 renders stub screen at index 0 using injected screens and only `NavigationProvider` wrapper.

- **Gap:** T45 log-path assertion is ambiguous and singleton cleanup is easy to forget
- **Why it will break:** Tests may either overfit `debugPrint` formatting or leak fake crash reporter state into later tests.
- **Fix (exact step(s) to add / reorder):** Lock crash-report capture as the observable and require save/restore of `CrashReportingService.instance`.
- **Owner:** @Architect / @Sentinel
- **Acceptance check:** T45 asserts throw + crash-report capture and restores singleton in cleanup.

- **Gap:** T43 expiry test can become time-flaky if seeded near boundary
- **Why it will break:** `isCacheValid()` uses `DateTime.now()` and a `< 5 min` comparison; boundary tests can flap.
- **Fix (exact step(s) to add / reorder):** Seed timestamp with a safe margin (6+ minutes old) and document the chosen margin.
- **Owner:** @Architect / @Sentinel
- **Acceptance check:** T43 passes consistently across repeated runs with no boundary timing flakes.

- **Gap:** Global state cleanup rules are missing for cache and SharedPreferences mocks
- **Why it will break:** T41/T45/T42-T44 can pass/fail based on prior test order.
- **Fix (exact step(s) to add / reorder):** Add setup/teardown cleanup rules for `SignedUrlCache`, `CrashReportingService.instance`, and `SharedPreferences.setMockInitialValues` usage in this slice.
- **Owner:** @Sentinel / @Architect
- **Acceptance check:** T41-T50 pass alone and in grouped runs without order dependence.

## D) Invariants & Success Criteria (Non-Negotiable)

- **Invariant:** Expired signed-URL cache entries return `null` and are evicted
- **How to enforce:** Enforce with T41 using an already-expired cache entry.
- **How to verify:** `SignedUrlCache.get(path) == null` and cache entry removed (size/key absent).

- **Invariant:** Dashboard work-item cache is partitioned by role
- **How to enforce:** Enforce with T42 caching/restoring distinct client and freelancer work items.
- **How to verify:** Restored lists match the role-specific fixtures with no collision.

- **Invariant:** Dashboard cache validity becomes false after the expiry window
- **How to enforce:** Enforce with T43 by seeding an old timestamp older than `_cacheValidity`.
- **How to verify:** `isCacheValid() == false` for a safely old timestamp.

- **Invariant:** `DashboardCacheService.clearCache()` removes only dashboard-managed keys in this slice scope
- **How to enforce:** Enforce with T44 after populating dashboard cache keys via public methods.
- **How to verify:** Dashboard keys are cleared; optional `user_role` remains if that scope is chosen.

- **Invariant:** `DemoPaymentService(shouldFail: true)` throws and emits failure path logging/reporting
- **How to enforce:** Enforce with T45 using `delay: Duration.zero` and fake `CrashReportingService` capture.
- **How to verify:** `processPayment(...)` throws and fake crash reporter records the failure-path call.

- **Invariant:** Login form validation surfaces required-field messages on empty submit
- **How to enforce:** Enforce with T46 using login widget keys and sign-in tap with empty fields.
- **How to verify:** Validation messages for email and password are visible.

- **Invariant:** Login UI trims email/password before delegating to `AuthViewModel.login(...)`
- **How to enforce:** Enforce with T47 using a fake auth VM that captures arguments.
- **How to verify:** Captured email/password match exact trimmed values.

- **Invariant:** Login success path navigates to main navigation flow
- **How to enforce:** Enforce with T48 using success fake auth VM and a lightweight main-nav destination builder.
- **How to verify:** Navigator route/destination assertion confirms post-login transition.

- **Invariant:** Login failure path surfaces snackbar error text from auth VM
- **How to enforce:** Enforce with T49 using failure fake auth VM and controlled `error` message.
- **How to verify:** Snackbar displays the expected error text and success navigation is not taken.

- **Invariant:** Main navigation initial render shows index-0 home content
- **How to enforce:** Enforce with T50 using injected stub screens and `NavigationProvider` default index 0.
- **How to verify:** Stub home content at index 0 is visible immediately after pump.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Real AuthViewModel starts Supabase listener in widget tests | T46-T49 | High | High | Feature | Widget tests fail/hang during pump | Add login/auth test seams first | Block widget phase until seam lands |
| Hardcoded main-nav destination boots heavy screens | T48 | High | High | Feature | Missing providers/side effects crash on successful login | Add post-login destination seam + stub main nav | Observer-only route assertion (weaker temporary fallback) |
| MainNavigationScreen no screens seam | T50 | High | Med | Feature | Test requires HomeScreen dependencies | Inject optional screens list | Temporarily defer T50 until seam added |
| T43 boundary timing flake | T43 | Med | Med | Local | Intermittent false/true around cache window | Use 6+ minute margin and document it | Increase margin and rerun |
| T44 scope mismatch on `user_role` | T44 | Med | Med | Feature | Review churn: test expects key removal not implemented | Lock dashboard-only scope | Add explicit negative assertion and note scope |
| T45 logger assertion overfits console output | T45 | Med | Med | Local | Fails after harmless logger formatting changes | Use fake crash reporter capture | Relax to minimal observable capture only |
| CrashReporting singleton leak | T45 | High | Med | Local | Later tests unexpectedly hit fake reporter | Save/restore singleton in setup/teardown | Add explicit reset in all affected tests |
| SignedUrlCache static state leak | T41 | Med | Med | Local | T41/T40 fail only in suite order | Clear cache before/after tests | Add tearDown cleanup and rerun slice |
| Widget selectors break on text/style changes | T46-T50 | Med | Med | Feature | Tests fail after UI copy tweaks | Add stable widget keys and stub keys | Switch to key-based assertions entirely |
| `pumpApp` harness misses theme/provider setup | T46-T50 | Med | High | Feature | `ProviderNotFound` / extension null errors during pump | Centralize harness with `AppTheme.light()` + providers | Patch harness before continuing widget tests |

## F) Pre-Mortem (How this fails in real life)

- This fails when T46-T49 are written before login/auth seams and the tests silently start real Supabase listeners.
- This fails when T48 pushes the real `MainNavigationScreen` and crashes on missing providers from heavy child screens.
- This fails when T43 seeds a timestamp too close to the 5-minute boundary and passes locally but flakes in CI.
- This fails when T44 claims `clearCache()` removes `user_role` even though the implementation intentionally leaves it untouched.
- This fails when T45 asserts `debugPrint` formatting and every logger formatting change breaks the test for no product reason.
- This fails when T45 forgets to restore `CrashReportingService.instance` and later tests observe the wrong global singleton.
- This fails when T41/T40 do not clear `SignedUrlCache` and test order changes the result.
- This fails when login widget tests rely on text-only selectors and UI copy changes break tests unrelated to behavior.
- This fails when T50 uses real `HomeScreen` and the test becomes a hidden integration test with provider/network side effects.

## G) Plan Fixes (Concrete Additions / Expansions)

- **Goal:** Add minimal widget-testability seams for login and main navigation
- **Why:** T46-T50 cannot be deterministic/offline without them.
- **How:** Add default-preserving `LoginScreen` auth VM factory + post-login destination builder seams, and `MainNavigationScreen` optional screen-list injection.
- **Output artifact:** Small production seam updates in `LoginScreen`, `AuthViewModel`, and `MainNavigationScreen`
- **Stop condition:** T46-T50 can run with fakes/stubs and no Supabase initialization or heavy child screens.

- **Goal:** Standardize widget harness and selectors for T46-T50
- **Why:** Repeated ad-hoc widget setup creates flake and slows implementation.
- **How:** Add `pumpApp` helper, fake navigator observer, and stable widget keys for login controls plus stub screen keys for main nav tests.
- **Output artifact:** `test/test_support/pump_app.dart` (or equivalent) + key constants + test fakes
- **Stop condition:** Widget tests share one deterministic harness and key strategy.

- **Goal:** Lock cache and global-state cleanup rules for T41-T45
- **Why:** `SignedUrlCache`, `CrashReportingService.instance`, and SharedPreferences mocks are global/static state prone to order-dependent failures.
- **How:** Add explicit setup/teardown cleanup rules and require them in review checklist.
- **Output artifact:** Test setup helpers + slice checklist notes
- **Stop condition:** T41-T45 pass alone and in grouped runs without order dependence.

- **Goal:** Clarify scope/observables for T44 and T45
- **Why:** “all keys” and “logs failure path” are ambiguous and will produce review churn or weak tests.
- **How:** Lock T44 to dashboard-managed keys and T45 to crash-report capture as the logging observable.
- **Output artifact:** Plan decisions + test assertions/comments
- **Stop condition:** Reviewers can explain each test contract in one sentence.

- **Goal:** Add per-phase input requirements and gate checks
- **Why:** Makes blockers explicit and reduces back-and-forth during implementation.
- **How:** Include `What Input You Should Provide Me` and `GATE CHECK` in every phase below.
- **Output artifact:** Per-phase plan content
- **Stop condition:** Implementer can start each phase with no hidden decision work.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Slice Dependency Order (T41-T50)

1. Data/Contracts: lock T44 scope, T45 log observable, widget seam signatures, and selector strategy.
2. Security-sensitive paths: T45 failure-path reporting and T46-T49 auth/login feedback/navigation behavior.
3. Backend/App logic unit tests: cache and utility tests T41-T45.
4. UI wiring/widget tests: T46-T50 after seams and harness are in place.
5. QA/Release: grouped runs, flake re-run, and traceability signoff before moving to T51-T60.

### Shared Implementation Rules (Applies to T41-T50)

- [ ] (@Architect) No production behavior changes beyond approved testability seams with default-preserving behavior.
- [ ] (@Sentinel) All tests run offline and deterministically; no hidden network or plugin usage.
- [ ] (@Sentinel) Clean up all global/static state in tests (`SignedUrlCache`, `CrashReportingService.instance`, SharedPreferences mock state assumptions).
- [ ] (@Pixel) Use stable widget keys for login controls and stub widgets for main-navigation assertions; avoid text-only selectors for primary interactions.
- [ ] (@Architect) Widget harness must include `MaterialApp`, `AppTheme.light()`, and required providers (`NavigationProvider` where needed).
- [ ] (@Sentinel) Keep one-phase-one-contract scope; local subcases only when explicitly justified.

### Slice QA/Release Gate (Before Marking T41-T50 Complete)

- [ ] (@Sentinel) `flutter test /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app` passes for `T41-T50`.
- [ ] (@Sentinel) Re-run widget tests (`login_screen_test.dart`, `main_navigation_screen_test.dart`) once to detect obvious flake.
- [ ] (@Sentinel) All blocking decisions in Section A are resolved and reflected in seams/assertions/comments.
- [ ] (@Sentinel) Review checklist passes: global-state cleanup present, widget seams default-preserving, no heavy real screen dependencies in T48/T50.
- **GATE CHECK:** `T41-T50` is stable and merge-ready before starting `T51-T60`.

## Phase 41: T41 - SignedUrlCache expired entry returns null and evicts

> Primary: @Architect
> Supporting: @Sentinel

### Goal

- Implement and stabilize `T41` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/signed_url_cache_test.dart`.

### Why

- This locks the eviction path, not just cache hits. If expired entries are not removed, stale URLs can accumulate and hide refresh bugs.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/signed_url_cache_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/signed_url_cache.dart`.
- Test case target: `SignedUrlCache expired entry returns null and evicts`.
- Static cache isolation via `SignedUrlCache.clear()` before and after the test.
- Deterministic expiry trigger strategy (recommended: `SignedUrlCache.set(..., duration: Duration(milliseconds: -1))`).
- Decision on whether to assert eviction via `SignedUrlCache.size` in addition to `get(...) == null` (recommended: yes).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Clear the cache, insert one entry with an already-expired duration, then call `SignedUrlCache.get(path)`.
- [ ] (@Architect) Assert the result is `null` and (if approved) cache size drops to `0` to prove eviction occurred.
- [ ] (@Sentinel) Review for deterministic expiry setup and no dependence on wall-clock race timing.
- **Verify (@Sentinel):** `T41` remains one scenario and does not duplicate the hit-path coverage from `T40`.

### How To Do It

- Use a negative duration instead of `Duration.zero` to avoid edge timing flakiness around equality with `DateTime.now()`.
- Use a unique fake storage path and URL string; no network calls are involved.
- Always clear cache state before/after to prevent test-order leakage.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Fast and stable coverage for cache expiry + eviction behavior.
- Early detection if expired entries stop being removed and stale cache state persists incorrectly.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm the expiry trigger strategy: use negative duration (recommended) instead of waiting/sleeping.
- Optional: confirm whether to assert cache eviction via `SignedUrlCache.size == 0` in addition to `get(...) == null` (recommended: yes).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T41` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/signed_url_cache_test.dart`.
- Any helper/fake/seam added for this phase remains reusable and does not change production behavior beyond approved default-preserving testability seams.

### GATE CHECK

- Expired cache entry deterministically returns `null` and is removed from static cache state.
- This phase is not complete until the test passes locally and reviewer confirms no timing flake risk.

---

## Phase 42: T42 - DashboardCacheService caches and restores role-specific work items

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T42` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/dashboard_cache_service_test.dart`.

### Why

- This validates the role-key separation in dashboard cache storage. If role-specific keys collide, users can see the wrong work items after switching roles.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/dashboard_cache_service_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/dashboard_cache_service.dart`.
- Test case target: `DashboardCacheService caches and restores role-specific work items`.
- SharedPreferences test setup using `SharedPreferences.setMockInitialValues({})` and `SharedPreferences.getInstance()`.
- A minimal `WorkItem` fixture builder (can reuse fields from T35 plan) with distinct IDs/titles per role.
- Decision on scope: one-role cache/restore only vs both client+freelancer separation in the same test (recommended: both roles to prove role-specific behavior).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Initialize mock SharedPreferences, construct `DashboardCacheService`, and cache distinct work-item lists for `UserRole.client` and `UserRole.freelancer`.
- [ ] (@Architect) Call `getCachedWorkItems(role)` for each role and assert the restored lists match the correct role-specific fixtures.
- [ ] (@Architect) Optionally assert cross-role isolation by checking client/freelancer IDs differ and remain separated.
- [ ] (@Sentinel) Review for role-key isolation coverage and no reliance on private constants directly unless necessary.
- **Verify (@Sentinel):** `T42` remains one scenario and does not drift into cache expiry coverage (T43).

### How To Do It

- Use public `cacheWorkItems` and `getCachedWorkItems` methods rather than writing raw JSON strings into prefs; this keeps the test at the service contract layer.
- Build very small `WorkItem` fixtures with distinct IDs to make role mix-ups obvious in assertions.
- No clock seam is needed for T42 because `cacheWorkItems` updates the timestamp to a valid value immediately.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- High-value coverage for dashboard cache partitioning by user role.
- Early detection if cache keys, JSON roundtrip, or role restoration behavior regresses.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm T42 scope: test both client and freelancer cache/restore in one scenario (recommended) vs one role only.
- Optional: confirm whether to assert explicit cross-role mismatch (recommended: yes, simple ID/title check).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T42` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/dashboard_cache_service_test.dart`.
- Any helper/fake/seam added for this phase remains reusable and does not change production behavior beyond approved default-preserving testability seams.

### GATE CHECK

- Dashboard cache stores and restores distinct work-item lists per role without key collision.
- This phase is not complete until the test passes locally and reviewer confirms role-specific behavior is explicit.

---

## Phase 43: T43 - DashboardCacheService isCacheValid false after expiry window

> Primary: @Architect
> Supporting: @Sentinel

### Goal

- Implement and stabilize `T43` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/dashboard_cache_service_test.dart`.

### Why

- Cache validity controls stale-while-revalidate behavior. If expiry logic regresses, dashboard may serve stale data too long or invalidate too aggressively.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/dashboard_cache_service_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/dashboard_cache_service.dart`.
- Test case target: `DashboardCacheService isCacheValid false after expiry window`.
- SharedPreferences mock setup and a way to seed an old timestamp under the dashboard timestamp key.
- A deterministic expiry strategy without adding a production clock seam (recommended: seed `dashboard_timestamp` older than 5 minutes with a safe margin like 6+ minutes).
- Decision on whether raw timestamp-key string usage in tests is acceptable (recommended: yes, with a local test constant and comment).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Seed SharedPreferences with an old `dashboard_timestamp` value older than the service validity window.
- [ ] (@Architect) Instantiate `DashboardCacheService` and assert `isCacheValid()` returns `false`.
- [ ] (@Sentinel) Review for stable margin (avoid near-boundary times) and no hidden wall-clock flake.
- **Verify (@Sentinel):** `T43` remains one scenario and does not bundle cache-hit restore behavior from `T42`.

### How To Do It

- Use a large margin beyond 5 minutes (for example 6 or 10 minutes) to avoid boundary flakiness.
- Mirror the private timestamp key string as a local test constant with a short comment documenting why direct access is used.
- Do not add a production clock injection seam unless you decide to change utility testability policy globally.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Deterministic coverage of cache expiry semantics without network or UI dependencies.
- Fast detection if the cache validity window logic changes unexpectedly.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm T43 should use raw timestamp-key seeding (`dashboard_timestamp`) with a local test constant (recommended) instead of adding a clock seam.
- Optional: choose expiry margin for the test (recommended: at least 6 minutes old).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T43` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/dashboard_cache_service_test.dart`.
- Any helper/fake/seam added for this phase remains reusable and does not change production behavior beyond approved default-preserving testability seams.

### GATE CHECK

- A seeded timestamp older than the validity window deterministically yields `isCacheValid() == false`.
- This phase is not complete until the test passes locally and reviewer confirms boundary-safe timing setup.

---

## Phase 44: T44 - DashboardCacheService clearCache removes all keys

> Primary: @Architect
> Supporting: @Sentinel

### Goal

- Implement and stabilize `T44` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/dashboard_cache_service_test.dart`.

### Why

- Dashboard cache cleanup is important for role/user transitions. Ambiguity around which keys are in scope must be resolved or this test will be misleading.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/dashboard_cache_service_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/dashboard_cache_service.dart`.
- Test case target: `DashboardCacheService clearCache removes all keys`.
- Explicit scope definition for this slice: `all keys` means dashboard cache keys managed by `clearCache()` (`dashboard_work_items_*`, `dashboard_activity_feed`, `dashboard_counters`, `dashboard_timestamp`) only.
- SharedPreferences mock setup plus minimal fixtures for work items/activity feed/counters to populate cache through public methods.
- Decision on whether to assert `user_role` is preserved as an out-of-scope key (recommended: yes, strong scope lock).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Populate dashboard cache via public methods (`cacheWorkItems`, `cacheActivityFeed`, `cacheCounters`) and optionally set `cacheUserRole`.
- [ ] (@Architect) Call `clearCache()` and assert dashboard cache state is cleared (via `getCacheStats()` and/or direct key checks).
- [ ] (@Architect) If approved, assert `user_role` remains cached to prove scope is dashboard-only.
- [ ] (@Sentinel) Review for precise scope wording and ensure the test does not claim behavior not implemented by `clearCache()`.
- **Verify (@Sentinel):** `T44` remains one scenario and does not bundle `cacheUserRole` delete behavior (not part of this method).

### How To Do It

- Prefer public cache methods to seed keys, then use `getCacheStats()` for readable assertions on cleared state.
- If asserting `user_role` preservation, use `prefs.getString('user_role')` or `getCachedUserRole()` after clear and document why it is out of scope.
- Keep exception/catch-path behavior out of this phase; this phase is about successful cleanup contract only.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Clear protection for dashboard-cache cleanup semantics and scope boundaries.
- Reduced risk of stale dashboard UI data surviving logout/role transitions while preserving unrelated cached role if that is the chosen contract.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm T44 scope lock: `clearCache()` should be tested against dashboard keys only (recommended: yes).
- Optional: confirm whether to assert `user_role` remains untouched after `clearCache()` (recommended: yes, useful negative assertion).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T44` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/dashboard_cache_service_test.dart`.
- Any helper/fake/seam added for this phase remains reusable and does not change production behavior beyond approved default-preserving testability seams.

### GATE CHECK

- `clearCache()` removes all dashboard-managed keys and, if chosen, preserves out-of-scope `user_role`.
- This phase is not complete until the test passes locally and reviewer confirms scope matches actual implementation.

---

## Phase 45: T45 - DemoPaymentService shouldFail true throws and logs failure path

> Primary: @Architect
> Supporting: @Sentinel, @ThreatModeler

### Goal

- Implement and stabilize `T45` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/demo_payment_service_test.dart`.

### Why

- This test protects the simulated payment failure path used in booking/payment flows. It must both throw and emit the failure path through logging/reporting hooks.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/demo_payment_service_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/demo_payment_service.dart`.
- Test case target: `DemoPaymentService shouldFail true throws and logs failure path`.
- A fake `CrashReportingService` to capture `AppLogger.e(...)` error reporting without asserting brittle `debugPrint` formatting.
- Global singleton isolation for `CrashReportingService.instance` (save/restore original instance).
- `DemoPaymentService(shouldFail: true, delay: Duration.zero)` to keep the test fast and deterministic.
- Decision on assertion scope for the log path: crash-report capture only (recommended) vs crash-report capture + console output interception.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Install a fake `CrashReportingService`, construct `DemoPaymentService(shouldFail: true, delay: Duration.zero)`, and call `processPayment(...)`.
- [ ] (@Architect) Assert the method throws (prefer message contains `Payment declined (Demo)` or exact if you choose strictness).
- [ ] (@Architect) Assert the fake crash reporter captured the failure-path record call caused by `AppLogger.e(...)`.
- [ ] (@Architect) Restore the original `CrashReportingService.instance` in cleanup to avoid cross-test leakage.
- [ ] (@Sentinel) Review for global-singleton cleanup and avoidance of brittle console-format assertions.
- **Verify (@Sentinel):** `T45` remains one scenario and does not test the success path or initialization path.

### How To Do It

- Use `Duration.zero` to avoid unnecessary waits in unit tests.
- Capture the failure log path through `CrashReportingService` because `AppLogger.e` always forwards errors there in debug mode and this is easier to assert than `debugPrint` output.
- Keep assertions focused on throw + observable failure reporting; do not snapshot logger text formatting, emojis, or timestamps.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Reliable coverage of demo payment failure semantics and failure-path logging/reporting behavior.
- Fast signal if the demo service stops throwing on `shouldFail` or stops emitting the failure path through `AppLogger.e`.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm the log-path observable for T45: fake `CrashReportingService` capture (recommended) instead of `debugPrint` matching.
- Optional: choose exception assertion mode for thrown error (`exact` vs `contains`, recommended: contains to reduce brittleness).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T45` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/demo_payment_service_test.dart`.
- Any helper/fake/seam added for this phase remains reusable and does not change production behavior beyond approved default-preserving testability seams.

### GATE CHECK

- `DemoPaymentService(shouldFail: true)` throws and triggers a captured failure-path report via the fake crash reporter.
- This phase is not complete until the test passes locally and reviewer confirms singleton cleanup is in place.

---

## Phase 46: T46 - LoginScreen form shows required validation messages

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T46` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart`.

### Why

- This covers a high-traffic UI validation path. Broken form validation creates immediate UX regressions before any backend interaction happens.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/auth/view/login_screen.dart`.
- Test case target: `LoginScreen form shows required validation messages`.
- Default-preserving test seam in `LoginScreen` to inject a test-safe `AuthViewModel` (or factory) instead of constructing a real `AuthViewModel()` internally.
- Test-safe `AuthViewModel` construction path (disable auth listener startup or inject safe auth stream) to prevent Supabase listener initialization in widget tests.
- Stable widget keys for email field, password field, and sign-in button (recommended via shared key constants).
- `pumpApp` widget harness using `MaterialApp`, `AppTheme.light()`, and any minimal providers needed.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Add/confirm `LoginScreen` auth-injection seam and test-safe auth VM seam (default behavior preserved).
- [ ] (@Pixel) Add/confirm stable widget keys for login controls and implement the widget test using the shared harness.
- [ ] (@Pixel) Tap sign-in with empty fields and assert required validation messages for email and password.
- [ ] (@Sentinel) Review for offline execution and ensure validation assertions are not coupled to unrelated UI polish.
- **Verify (@Sentinel):** `T46` remains one scenario and does not assert login-call or navigation behavior (covered by T47/T48).

### How To Do It

- Pump `LoginScreen` inside `pumpApp` with a fake/test-safe auth VM factory even though the validators block login, so the widget remains offline and deterministic.
- Use widget keys for interactions and validation assertions where possible; use text finders for error messages only as needed.
- Use bounded `pump` / `pumpAndSettle` calls after tapping sign-in to surface form validation.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Stable coverage for empty-form validation on the login screen with no backend dependencies.
- Immediate regression signal if form validators are removed, renamed, or not triggered by sign-in.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve the `LoginScreen` auth-injection seam (recommended: `AuthViewModel Function()? authViewModelFactory`) and a test-safe `AuthViewModel` listener-disable seam.
- Confirm stable key strategy for login controls (recommended: shared key constants for email/password/sign-in).
- Optional: confirm whether to assert both validation messages in one test (recommended: yes, same scenario).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T46` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart`.
- Any helper/fake/seam added for this phase remains reusable and does not change production behavior beyond approved default-preserving testability seams.

### GATE CHECK

- Empty login form submit deterministically shows required validation messages without starting real auth listeners.
- This phase is not complete until the test passes locally and reviewer confirms offline widget execution.

---

## Phase 47: T47 - LoginScreen sign-in tap calls login with trimmed email/password

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T47` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart`.

### Why

- This locks input normalization at the UI boundary. If trimming regresses, valid credentials with whitespace can fail unexpectedly and create support noise.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/auth/view/login_screen.dart`.
- Test case target: `LoginScreen sign-in tap calls login with trimmed email/password`.
- A fake auth ViewModel that records `login(email, password)` arguments and can return a controlled result without network calls.
- The same `LoginScreen` seam and widget keys from T46.
- Decision on fake login result for this phase (recommended: return `false` with a harmless error to avoid testing navigation here).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Create a fake/test auth VM that captures login args and returns a controlled result.
- [ ] (@Pixel) Enter email/password with leading/trailing whitespace, tap sign-in, and assert captured login args are trimmed.
- [ ] (@Sentinel) Review the test for boundary focus (trimmed delegation only) and no accidental navigation assertions.
- **Verify (@Sentinel):** `T47` remains one scenario and does not overlap with success navigation (T48) or failure snackbar message content (T49).

### How To Do It

- Use a fake auth VM subclass or adapter that captures the exact values passed into `login(...)`.
- Choose a non-success return (recommended false) so the test stays focused on delegation arguments and avoids route assertions.
- Assert exact trimmed strings, not just substring contains, because trimming is the contract under test.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Targeted protection for login input normalization at the UI-to-ViewModel boundary.
- Fast detection if whitespace trimming is removed or moved incorrectly.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm T47 should use a fake auth VM that returns `false` to avoid navigation side effects (recommended).
- Optional: confirm whether to assert exact trimmed values for both fields (recommended: yes).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T47` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart`.
- Any helper/fake/seam added for this phase remains reusable and does not change production behavior beyond approved default-preserving testability seams.

### GATE CHECK

- Sign-in tap delegates to `login(...)` with trimmed email/password values captured by the fake auth VM.
- This phase is not complete until the test passes locally and reviewer confirms delegation-only scope.

---

## Phase 48: T48 - LoginScreen successful login navigates to main navigation screen

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T48` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart`.

### Why

- This covers the primary login success UX path. If navigation regresses, users can authenticate successfully and still remain stuck on the login screen.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/auth/view/login_screen.dart`.
- Test case target: `LoginScreen successful login navigates to main navigation screen`.
- A fake auth VM that returns success and does not touch real Supabase listeners.
- A default-preserving `LoginScreen` post-login destination seam (recommended: `WidgetBuilder? mainNavigationBuilder`) so tests can push a lightweight `MainNavigationScreen` configured with stub screens.
- A default-preserving `MainNavigationScreen` screen-list injection seam (used here and by T50) to avoid building heavy real child screens.
- Widget test harness with `NavigatorObserver` and `NavigationProvider` for the destination screen.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Add/confirm login post-success destination seam and main navigation screen-list injection seam with production defaults preserved.
- [ ] (@Pixel) Pump login screen with a success-returning fake auth VM and a lightweight main-navigation destination builder using stub child screens.
- [ ] (@Pixel) Enter valid credentials, tap sign-in, and assert navigation to main navigation route/destination (observer and/or destination finder).
- [ ] (@Sentinel) Review for route assertion strength and ensure the test remains offline without heavy child screen providers.
- **Verify (@Sentinel):** `T48` remains one scenario and does not absorb T50 initial-content assertions beyond minimal destination detection.

### How To Do It

- Use a fake auth VM that returns `true` immediately to trigger the success branch deterministically.
- Inject `mainNavigationBuilder` that returns a `MainNavigationScreen` with stub screens so the test still exercises main-navigation routing semantics without heavy feature dependencies.
- Use a navigator observer and/or a stable stub widget key inside the destination to prove navigation occurred after success.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Reliable coverage for the login success navigation path without real backend or heavy screen bootstrapping.
- Early detection if pushReplacement routing or success branch handling regresses.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve the `LoginScreen` post-login destination seam (recommended: `mainNavigationBuilder`) so T48 can stay lightweight and still target main-navigation routing.
- Approve `MainNavigationScreen` screen-list injection seam reuse in T48 and T50 (recommended).
- Choose navigation assertion style for T48: observer-only, destination-finder-only, or both (recommended: both if kept concise).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T48` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart`.
- Any helper/fake/seam added for this phase remains reusable and does not change production behavior beyond approved default-preserving testability seams.

### GATE CHECK

- Successful fake login deterministically pushes/replaces to a main-navigation destination without booting heavy real child screens.
- This phase is not complete until the test passes locally and reviewer confirms route behavior is asserted clearly.

---

## Phase 49: T49 - LoginScreen failed login shows snackbar error text

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T49` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart`.

### Why

- This protects the user-visible failure feedback path. If snackbar error messaging regresses, login failures become confusing and feel like silent failures.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/auth/view/login_screen.dart`.
- Test case target: `LoginScreen failed login shows snackbar error text`.
- A fake auth VM that returns `false` and exposes a controlled `error` string.
- The same login seams, widget keys, and `pumpApp` harness used in T46-T48.
- Decision on snackbar assertion strictness: exact error text vs semantic contains (recommended: exact if your UI copy is stable).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Prepare a fake auth VM that returns failure and exposes a known `error` message.
- [ ] (@Pixel) Enter valid credentials, tap sign-in, and assert the snackbar displays the fake error text.
- [ ] (@Pixel) Optionally assert no success navigation occurs in the same scenario if it stays concise.
- [ ] (@Sentinel) Review the test for failure-feedback scope and no overlap with validation-only T46.
- **Verify (@Sentinel):** `T49` remains one scenario and does not bundle trimming delegation coverage from `T47`.

### How To Do It

- Use a fake auth VM with deterministic `error` text and `login(...)` return value `false`.
- Assert snackbar content after bounded pumps; avoid overly broad screen snapshots.
- Prefer exact text if product copy is stable; otherwise use semantic contains consistently with your chosen policy.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Stable coverage for login failure feedback UX.
- Fast detection if the error snackbar stops showing or displays the wrong message source.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Choose snackbar text assertion mode for T49: exact vs semantic contains (recommended: exact if copy is stable).
- Optional: confirm whether to include a concise no-navigation assertion in the same phase (recommended: optional, only if simple).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T49` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart`.
- Any helper/fake/seam added for this phase remains reusable and does not change production behavior beyond approved default-preserving testability seams.

### GATE CHECK

- Failed fake login deterministically shows snackbar error text without triggering the success navigation path.
- This phase is not complete until the test passes locally and reviewer confirms failure-feedback scope is isolated.

---

## Phase 50: T50 - MainNavigationScreen renders with initial home content

> Primary: @Pixel
> Supporting: @Architect, @Sentinel

### Goal

- Implement and stabilize `T50` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app/main_navigation_screen_test.dart`.

### Why

- This locks the initial tab rendering contract (`index 0` home) without depending on heavy feature screens. It is a key base test for later navigation widget tests.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app/main_navigation_screen_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/app/main_navigation_screen.dart`.
- Test case target: `MainNavigationScreen renders with initial home content`.
- A default-preserving `MainNavigationScreen` screen-list injection seam so tests can supply lightweight stub screens instead of real `HomeScreen`/others.
- A `NavigationProvider` in the widget harness with default `currentIndex == 0`.
- A stable assertion target for the initial screen (recommended: stub home widget key/text at injected index 0).
- Decision on seam shape: `List<Widget>? screens` constructor param (recommended) vs builder callbacks per index.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Add/confirm a default-preserving screen-list injection seam in `MainNavigationScreen`.
- [ ] (@Pixel) Pump `MainNavigationScreen` with `NavigationProvider` and stub screens, then assert the index-0 home stub is visible initially.
- [ ] (@Sentinel) Review the test for initial-render scope and ensure it does not drift into tab-change/FAB behavior (later tests).
- **Verify (@Sentinel):** `T50` remains one scenario and only proves initial content at home index 0.

### How To Do It

- Inject a small stub screen list (home/tender/booking/etc.) and wrap with `ChangeNotifierProvider(create: (_) => NavigationProvider())` in `pumpApp`.
- Assert a stable stub widget key/text from the first screen rather than relying on real `HomeScreen` internals.
- Do not tap the FAB or bottom nav in this phase; those behaviors belong to later widget phases.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Reliable base coverage for initial main-navigation rendering with low flake risk.
- Early detection if default tab index or screen selection logic regresses.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve `MainNavigationScreen` screen-list injection seam shape (recommended: optional `List<Widget> screens` with production defaults when omitted).
- Confirm initial-content assertion target style: stub key/text at index 0 (recommended).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T50` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app/main_navigation_screen_test.dart`.
- Any helper/fake/seam added for this phase remains reusable and does not change production behavior beyond approved default-preserving testability seams.

### GATE CHECK

- MainNavigationScreen deterministically renders injected index-0 home stub content with `NavigationProvider.currentIndex == 0`.
- This phase is not complete until the test passes locally and reviewer confirms initial-render-only scope.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- The previous `T41-T50` segment was partially customized but not in the full `@PlanCritic` `A-I` format used by the other re-improved slices.
- It mixed useful resolved notes with generic per-phase templates and did not provide per-test `What Input You Should Provide Me` sections.
- It did not fully lock the real blockers for this slice: login/auth widget seams, main-navigation stub-screen seam, and global-state cleanup rules.
- It referenced some chosen defaults (for T44/T45/T50) but did not convert them into gate-based risks, invariants, and per-test implementation contracts.

### 2) Added steps (bullet list)

- Added full `@PlanCritic` audit sections `A-I` for the slice.
- Added explicit blocking decisions for T44 scope, T45 log observable, login/auth seams, T48 post-login destination seam, and T50 screen-list seam.
- Added slice-specific invariants for cache eviction/validity, dashboard cache scope, payment failure logging observable, and login/main-nav widget behavior.
- Added risk register + pre-mortem focused on global state leakage, widget seam absence, and heavy destination bootstrapping.
- Added per-phase `What Input You Should Provide Me` and `GATE CHECK` sections for all 10 tests.
- Added shared slice rules for global cleanup, widget harness requirements, and key-based selectors.

### 3) Removed steps (if any)

- Removed generic repeated placeholders (`seam/fake needed`, `controlled time/cache inputs`) where slice-specific setup and observables could be stated explicitly.
- Replaced the non-Txx “support block” style with gate-based slice rules and concrete fixes while keeping `1 phase = 1 test` intact.

### 4) Reordered steps (from → to)

- From: partial custom notes + generic phase list.
- To: audit + gate failures + critical gaps + corrected gate-based plan + 10 detailed one-test phases.

### 5) Expanded steps (what became more detailed)

- `T41-T44`: now define deterministic cache expiry strategy, role-specific cache assertions, timestamp seeding approach, and clearCache scope boundaries.
- `T45`: now defines crash-report capture as the failure-log observable and requires singleton restore cleanup.
- `T46-T49`: now define exact widget-test seams, key strategy, and separation of validation/delegation/navigation/failure-feedback behaviors.
- `T50`: now defines `MainNavigationScreen` screen-list injection seam and stub-screen assertion strategy for initial render.

### 6) Why (short, practical)

- This slice fails in practice without seam decisions and global-state cleanup rules. The revised plan makes the testability blockers explicit and ties each test to a deterministic, reviewable setup.

### 7) Residual risks (what still remains risky even after fixes)

- If you later change login/main-navigation constructors or screen composition, the widget seam contracts and tests will need synchronized updates.
- Widget tests can still get brittle if key naming is inconsistent across slices; keep a single key-constants strategy.
- T41/T45 rely on cleanup discipline for global state; missing teardown code will still cause order-dependent failures.
