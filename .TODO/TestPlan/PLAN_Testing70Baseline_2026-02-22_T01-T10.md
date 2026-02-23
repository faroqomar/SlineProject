# 📌 Plan Segment: 70-Test Baseline (T01-T10) — Re-improved with @PlanCritic

- Source master plan: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22.md`
- Segment file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22_T01-T10.md`
- Included phases/tests: `T01` to `T10` (AuthViewModel + TaskFilterViewModel + TaskViewModel image cap)
- Audit method applied: `@PlanCritic` from `.agent/workflows/plan_critic.md`

## Purpose

- Turn the first 10 tests into an execution-safe, gate-based mini-plan with no hidden dependencies.
- Make each test phase implementation-ready: what we need, what to do, how to do it, what to expect, and what input you should provide.
- Preserve strict scope: `1 phase = 1 test` and no behavior changes beyond approved testability seams.

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- This slice (`T01-T10`) is implemented before widget or integration tests and can remain fully offline.
- Small testability seams are allowed if they are default-preserving and do not change runtime behavior.
- `mocktail` or manual fakes are acceptable; recommendation is manual fakes for `T01-T10` because the behavior is simple and clearer to read.
- User-facing auth error strings are considered stable enough to assert, unless you choose semantic assertions instead.
- `TaskFilterViewModel` defaults (`sortBy = Relevance`, empty filters) are intentional product behavior and not accidental.

### Decision Needed (Blocking)

- Missing decision: **AuthViewModel test seam signature**
  - Options:
  - `AuthViewModel({AuthRepository? authRepo, Stream<AuthState>? authStateChanges})` (recommended)
  - `AuthViewModel.test(...)` named constructor (acceptable, but adds parallel API surface)
  - Keep current constructor and use global Supabase initialization in unit tests (not recommended)
  - Recommended: first option because it is explicit, small, and default-preserving.
  - Plan impact: blocks `T01-T05` if not approved because auth listener setup currently binds to the Supabase singleton.

- Missing decision: **TaskViewModel offline construction seam**
  - Options:
  - Inject `TaskRepository` (recommended; also future-proofs `T10-T13`)
  - Add test-only constructor bypassing repo initialization
  - Initialize Supabase in unit tests (not recommended)
  - Recommended: repository injection with default constructor fallback.
  - Plan impact: blocks `T10` if not approved because `TaskViewModel` currently requires `Supabase.instance.client` at construction.

- Missing decision: **Auth message assertion strictness for T02/T03/T05**
  - Options:
  - Exact string assertions (recommended if product copy is contract)
  - Semantic contains/regex assertions (recommended if copy changes frequently)
  - Non-null only (not recommended; too weak)
  - Recommended: exact for this slice if you want stable UX copy; semantic if copy is still changing weekly.
  - Plan impact: affects test fragility and future maintenance cost.

### What Input You Should Provide Me (For This Slice)

- Approve or edit the **AuthViewModel seam signature** (blocking for `T01-T05`).
- Approve or edit the **TaskViewModel seam signature** (blocking for `T10`).
- Choose **auth error message assertion mode**: exact vs semantic (affects `T02`, `T03`, `T05`).
- Optional: confirm whether you want **strict notifyListeners count assertions** (recommended: no for this slice).
- Optional: provide preferred fixture labels/categories/budget examples to match your product language (for `T06-T09`).

## B) Gate Status (Pass/Fail)

### 1) Data/Contracts Gate

- Status: ✅ PASS
- Reason: This slice mostly tests local ViewModel/model utility behavior, not live DB contracts.
- Reason: Contract risk exists only for auth message wording and Task fixture defaults, which are manageable via explicit assertions.
- What to add/fix to pass: maintain current scope discipline and keep the slice offline.

### 2) Security Gate

- Status: ⚠️ PARTIAL
- Reason: No direct RLS/storage/backend calls in `T01-T10`, so security exposure is low.
- Reason: Auth session-expiry callback behavior (`T04`) is security-sensitive and must be tested behaviorally to avoid redirect regressions.
- What to add/fix to pass: keep auth/session behavior assertions explicit and avoid private-field assertions.

### 3) Backend/API Gate

- Status: ❌ FAIL
- Reason: `AuthViewModel` and `TaskViewModel` constructors have singleton coupling that blocks reliable offline unit tests.
- Reason: Required fix: approve and implement default-preserving seams before starting `T01-T05` and `T10`.
- What to add/fix to pass: implement the two constructor seams and add offline fake test setup utilities.

### 4) UI/Integration Gate

- Status: ✅ PASS (N/A for slice)
- Reason: This slice contains unit tests only (`T01-T10`).
- Reason: No UI/integration infra needed beyond keeping tests isolated and deterministic.
- What to add/fix to pass: maintain current scope discipline and keep the slice offline.

### 5) Release/QA Gate

- Status: ❌ FAIL
- Reason: No agreed command/run policy for this slice yet (single file run vs grouped run).
- Reason: No defined reviewer checklist for behavioral vs implementation-detail assertions.
- What to add/fix to pass: define a slice command (`flutter test test/unit/auth test/unit/tasks`) and review checklist before merging the slice.

## C) Critical Gaps (Must-Fix)

- **Gap:** AuthViewModel hard-coupled auth listener to Supabase singleton
- **Why it will break:** Unit tests for `T01-T05` will require global Supabase initialization or become flaky/slow, defeating the purpose of unit tests.
- **Fix (exact step(s) to add / reorder):** Add injectable auth state stream seam and repository injection defaults; update plan and implement before writing `T01`.
- **Owner:** @Architect
- **Acceptance check:** `T01-T05` instantiate `AuthViewModel` in pure unit tests with no Supabase init and all tests pass offline.

- **Gap:** TaskViewModel constructor requires Supabase client even for pure image-list logic (`T10`)
- **Why it will break:** `T10` will fail or require unrelated backend initialization for a pure list-truncation rule.
- **Fix (exact step(s) to add / reorder):** Add repository injection (or test constructor) so `TaskViewModel` can be created offline; plan this seam before `T10`.
- **Owner:** @Architect
- **Acceptance check:** `T10` runs offline and only tests image list truncation/order behavior.

- **Gap:** Auth message assertion policy not fixed
- **Why it will break:** `T02/T03/T05` may churn repeatedly if implementation asserts exact copy while product text is still changing.
- **Fix (exact step(s) to add / reorder):** Choose exact vs semantic assertion mode now and apply consistently across auth error tests.
- **Owner:** @Architect / Product
- **Acceptance check:** All auth error tests use one documented assertion mode and reviewers enforce it.

- **Gap:** No explicit fixture contract for TaskFilter tests
- **Why it will break:** `T06-T09` can become unreadable or weak if fixtures are ad-hoc and don’t cover boundary/compat cases clearly.
- **Fix (exact step(s) to add / reorder):** Define a small shared task fixture set for the filter test file with named cases (title-hit, description-hit, legacy-category, budget-boundary, etc.).
- **Owner:** @Architect
- **Acceptance check:** `task_filter_view_model_test.dart` uses a reusable fixture builder and each scenario asserts exact expected IDs.

- **Gap:** No slice-level review checklist (behavior vs implementation assertions)
- **Why it will break:** Tests can pass initially but become brittle if they over-assert internal sequencing or private implementation details.
- **Fix (exact step(s) to add / reorder):** Add a mini review checklist to this segment and require `@Sentinel` signoff before merging `T01-T10`.
- **Owner:** @Sentinel
- **Acceptance check:** Every test in `T01-T10` has behavioral assertions and no private-field assertions.

## D) Invariants & Success Criteria (Non-Negotiable)

- **Invariant:** AuthViewModel methods return stable bool outcomes for handled errors
- **How to enforce:** Enforce with `T01`, `T02`, `T03`, `T05` using fake repo success/failure paths.
- **How to verify:** Unit tests assert exact bool result and final loading/error state.

- **Invariant:** Auth loading state always resets to false after async method completion (success or failure)
- **How to enforce:** Enforce with `T01-T05` assertions on final `isLoading` value.
- **How to verify:** All auth tests assert final `isLoading == false`.

- **Invariant:** Session-expiry callback queue behavior is externally observable and one-shot on callback assignment
- **How to enforce:** Enforce with `T04` using injected error stream and callback counter.
- **How to verify:** Test proves callback fires after assignment, not before, and only once for the scenario.

- **Invariant:** TaskFilter search is case-insensitive over title and description
- **How to enforce:** Enforce with `T06` fixtures using mixed-case strings and assertions on exact included tasks.
- **How to verify:** Filtered results contain expected hits and exclude non-matches for mixed-case query.

- **Invariant:** Category filtering supports backward compatibility (`category` OR `categoryName`)
- **How to enforce:** Enforce with `T07` fixtures covering legacy/new fields independently.
- **How to verify:** Tasks match when either field matches the filter string.

- **Invariant:** Budget filtering is inclusive on boundaries
- **How to enforce:** Enforce with `T08` min/max boundary fixtures.
- **How to verify:** Boundary values are included; outside values excluded.

- **Invariant:** clearFilters resets filter state and restores list output
- **How to enforce:** Enforce with `T09` getter assertions + filtered list restoration assertions.
- **How to verify:** All public filter getters reset to defaults and `filteredTasks` returns full list.

- **Invariant:** Task image selection cap keeps at most first five images in order
- **How to enforce:** Enforce with `T10` using >5 `XFile` fixtures and order assertions.
- **How to verify:** List length is 5 and elements equal first five inputs in original order.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Auth seam not approved quickly | T01-T05 | High | High | Feature | Cannot instantiate AuthViewModel offline in tests | Approve seam signature before implementation starts | Pause auth tests and implement T06-T09 first |
| TaskViewModel still requires Supabase init | T10 | High | Med | Feature | Test crashes on constructor before assertions run | Inject repository/test constructor seam | Temporarily defer T10 and continue with T01-T09 |
| Auth error copy churn | T02/T03/T05 | Med | Med | Feature | Frequent assertion updates with no behavior change | Choose semantic assertion mode or freeze product copy | Loosen to contains assertions with documented reason |
| Over-asserting notifyListeners sequencing | T01-T05/T10 | Med | Med | Local | Tests fail after harmless refactor | Prefer state/output assertions over exact notify counts | Remove brittle listener-count assertions |
| Weak fixtures hide filter regressions | T06-T09 | Med | High | Feature | Tests pass but real filter bugs appear in HomeScreen | Use boundary/compatibility fixture set with exact IDs | Rewrite fixture set before merging slice |
| Shared test setup leakage between auth tests | T01-T05 | Low | Med | Feature | Tests pass individually but fail in suite | Fresh ViewModel and stream controller per test | Reset shared helpers and isolate state explicitly |
| XFile fixture approach accidentally invokes plugin behavior | T10 | Low | Med | Local | Test hangs or throws platform-channel error | Use plain `XFile` objects only, no picker calls | Replace with minimal wrapper fixture and assert list behavior only |

## F) Pre-Mortem (How this fails in real life)

- This fails when `AuthViewModel` tests are written before adding the auth stream seam and the team starts initializing real Supabase in unit tests “just for now”.
- This fails when auth error wording changes and exact-string assertions were chosen without freezing the UX copy contract.
- This fails when `T06-T09` use weak fixtures (for example all tasks match the query) and the tests stop detecting real filter bugs.
- This fails when `T04` asserts private queue state instead of callback behavior and a harmless refactor breaks the test while behavior stays correct.
- This fails when `T10` only checks `length == 5` and misses an order regression (for example keeping last five instead of first five).
- This fails when test helpers are shared across auth tests and stream controllers are not closed/reset, causing suite-order flakiness.
- This fails when reviewers accept implementation-detail assertions (exact notify count/order) and later refactors create false negatives that reduce trust in the suite.

## G) Plan Fixes (Concrete Additions / Expansions)

- **Goal:** Lock seam decisions for auth and task viewmodels
- **Why:** Without this, `T01-T05` and `T10` are blocked or become fake unit tests that hit real backends.
- **How:** Approve default-preserving constructor seams and document them in this segment before implementation starts.
- **Output artifact:** Updated plan segment + eventual code seam changes
- **Stop condition:** Both constructors can be instantiated offline in tests and no Supabase init is required for `T01-T10`.

- **Goal:** Create shared auth test harness for T01-T05
- **Why:** Auth tests share dependencies and failure modes; ad-hoc setup will drift and become brittle.
- **How:** Implement a small local fake auth repo + stream controller helper inside `auth_view_model_test.dart` or `test_support/fakes`.
- **Output artifact:** Test helper/fake classes
- **Stop condition:** Auth tests reuse one clear setup path and remain isolated per test.

- **Goal:** Create shared filter fixtures for T06-T09
- **Why:** These tests need boundary and compatibility cases; duplicated fixtures increase inconsistency.
- **How:** Define named task fixtures and helper to seed `TaskFilterViewModel` before each scenario.
- **Output artifact:** Task fixture builder/helper
- **Stop condition:** Filter tests assert exact IDs using the same fixture vocabulary.

- **Goal:** Add slice-level review checklist for T01-T10
- **Why:** Without a review gate, brittle tests are likely to be merged and later distrusted.
- **How:** Require `@Sentinel` review on behavior-first assertions, isolation, and deterministic execution before merge.
- **Output artifact:** Checklist in plan + PR template notes
- **Stop condition:** All `T01-T10` tests pass review checklist before merge.

- **Goal:** Add “What Input You Should Provide Me” to every phase
- **Why:** This avoids repeated back-and-forth and makes blockers explicit per test.
- **How:** Document blocking and optional user inputs in each phase below.
- **Output artifact:** Per-phase plan content
- **Stop condition:** Implementer can start each test with known approvals/inputs.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Slice Dependency Order (T01-T10)

1. Data/Contracts for this slice: lock auth message assertion mode + task fixture defaults (no live DB dependency).
2. Security-sensitive behavior coverage: auth error and session-expiry queue semantics (`T02-T05`).
3. Backend/App logic unit tests: auth, filter, and task image-cap logic (`T01-T10`).
4. UI/Integration for this slice: not applicable (deferred to later segments).
5. QA/release gate for this slice: deterministic local run + review checklist signoff.

### Shared Implementation Rules (Applies to T01-T10)

- [ ] (@Architect) No production behavior changes; only testability seams with default-preserving behavior.
- [ ] (@Sentinel) Tests must run offline and deterministically; no Supabase init, no platform channels, no plugin calls.
- [ ] (@Architect) Prefer behavioral assertions (return values, public state, outputs) over private-field or exact notify-order assertions.
- [ ] (@Sentinel) Every phase closes with a mini gate check before moving to the next test.

### Slice QA/Release Gate (Before Marking T01-T10 Complete)

- [ ] (@Sentinel) `flutter test /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks` passes consistently for `T01-T10`.
- [ ] (@Sentinel) All blocking decisions in Section A are resolved and reflected in test assertions.
- [ ] (@Sentinel) Review checklist passes: no hidden network, no private-field assertions, exact scenario scope respected.
- **GATE CHECK:** This 10-test slice is stable, offline, and merge-ready before moving to `T11-T20`.

## Phase 1: T01 - AuthViewModel login success sets loading and clears error

> Primary: @Architect
> Supporting: @Sentinel

### Goal

- Implement and stabilize `T01` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.

### Why

- This is the core auth happy path and the fastest regression signal for auth state transitions and bool-return behavior used by the UI.

### What We Need

- Test case target: `AuthViewModel login success sets loading and clears error`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/auth/viewmodels/auth_view_model.dart`.
- AuthViewModel test seam for auth state stream injection so tests do not bind to `Supabase.instance.client.auth.onAuthStateChange`.
- Fake `AuthRepository` that returns successful sign-in and optional profile payload without network access.
- Test helper to observe state transitions (`isLoading`, `error`) without relying on UI widgets.
- **Verify (@Sentinel):** prerequisites are available and no unrelated dependencies are introduced.

### What To Do

- [ ] (@Architect) Add/confirm `AuthViewModel` constructor seam for injected auth state stream and repository (default-preserving).
- [ ] (@Architect) Implement a fake auth repository success path and verify `login()` returns `true`.
- [ ] (@Architect) Assert `error` is cleared before login and `isLoading` is false after completion.
- [ ] (@Architect) Optionally assert listener notifications occurred, but do not lock exact notify count unless user asks for it.
- [ ] (@Sentinel) Review the test for isolation, deterministic execution, and behavior-first assertions.
- **Verify (@Sentinel):** `T01` still covers one behavior only and does not bundle extra scenarios.

### How To Do It

- Arrange: instantiate `AuthViewModel` with fake repository + inert auth stream; pre-set an error state if needed to verify clearing behavior.
- Act: call `login(email, password)` with valid values.
- Assert: `result == true`, `error == null`, `isLoading == false`, and fake repo captured the expected credentials.
- Keep assertions behavioral (state + return value), not implementation-specific (private methods, internal notify sequence).
- **Verify (@Sentinel):** implementation steps are reproducible by another engineer without extra decisions.

### What To Expect From This Test

- A fast offline test that protects the login happy path contract relied on by `LoginScreen` navigation logic.
- Regression detection if future refactors break loading lifecycle, bool return semantics, or error clearing.
- **Verify (@Sentinel):** regression value is clear and maintenance cost is acceptable for the scenario risk.

### What Input You Should Provide Me

- Approve auth test seam: `AuthViewModel({AuthRepository? authRepo, Stream<AuthState>? authStateChanges})` (recommended).
- Tell me if you want exact `notifyListeners()` count assertions (recommended: no, keep test less brittle).
- If you provide nothing, I will proceed with the defaults/recommendations documented in Section A (after you approve the blocking seam decisions).

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block) implementing `T01` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.
- Any required seam/fake helper introduced for this test remains reusable and default-preserving.

### GATE CHECK

- `Seam merged or approved, fake auth repo available, and test runs without Supabase initialization.`
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 2: T02 - AuthViewModel invalid credentials maps friendly message

> Primary: @Architect
> Supporting: @Sentinel, @APIContract

### Goal

- Implement and stabilize `T02` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.

### Why

- The login failure message is user-facing and easy to regress when auth provider error strings change.

### What We Need

- Test case target: `AuthViewModel invalid credentials maps friendly message`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/auth/viewmodels/auth_view_model.dart`.
- Same auth seam/fake setup as T01.
- Fake auth repository failure path that throws an invalid-credentials shaped error string.
- Decision on assertion strictness for user-facing text (exact string vs contains/semantic match).
- **Verify (@Sentinel):** prerequisites are available and no unrelated dependencies are introduced.

### What To Do

- [ ] (@Architect) Implement failing fake auth repo response for invalid credentials.
- [ ] (@Architect) Write test to call `login()` and assert `false` return value.
- [ ] (@Architect) Assert mapped message is the friendly invalid-credentials text and loading resets.
- [ ] (@Sentinel) Review the test for isolation, deterministic execution, and behavior-first assertions.
- **Verify (@Sentinel):** `T02` still covers one behavior only and does not bundle extra scenarios.

### How To Do It

- Throw a controlled exception string like `invalid login credentials` from the fake repo to hit the intended mapper branch.
- Assert `result == false`, `error` is non-null and equals/contains the friendly message based on chosen string-strictness policy.
- Also assert `isLoading == false` in the final state to prevent hidden stuck-spinner regressions.
- **Verify (@Sentinel):** implementation steps are reproducible by another engineer without extra decisions.

### What To Expect From This Test

- Protection for the most common auth error UX path without requiring widget tests to validate mapping behavior.
- Early signal if `_mapAuthError` changes or raw technical messages leak to UI.
- **Verify (@Sentinel):** regression value is clear and maintenance cost is acceptable for the scenario risk.

### What Input You Should Provide Me

- Choose message assertion mode: exact string (strict, recommended if you treat copy as contract) or semantic contains (less brittle).
- If you have approved product copy for auth errors, provide it so tests lock the final wording.
- If you provide nothing, I will proceed with the defaults/recommendations documented in Section A (after you approve the blocking seam decisions).

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block) implementing `T02` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.
- Any required seam/fake helper introduced for this test remains reusable and default-preserving.

### GATE CHECK

- `Chosen assertion mode documented and fake invalid-credentials error shape confirmed.`
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 3: T03 - AuthViewModel register duplicate email maps account-exists error

> Primary: @Architect
> Supporting: @Sentinel, @APIContract

### Goal

- Implement and stabilize `T03` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.

### Why

- Registration failure messaging is another user-facing contract and often breaks when backend wording drifts.

### What We Need

- Test case target: `AuthViewModel register duplicate email maps account-exists error`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/auth/viewmodels/auth_view_model.dart`.
- AuthViewModel seam from T01/T02 already in place.
- Fake auth repo `signUp` failure path with duplicate-email / already-registered wording variants.
- Decision whether to test one canonical backend message or multiple variants in a table-driven subcase.
- **Verify (@Sentinel):** prerequisites are available and no unrelated dependencies are introduced.

### What To Do

- [ ] (@Architect) Add duplicate-email failure case(s) to fake auth repo.
- [ ] (@Architect) Implement test for `register()` returning `false` and setting the expected friendly message.
- [ ] (@Architect) Assert `isLoading` resets on failure.
- [ ] (@Sentinel) Review the test for isolation, deterministic execution, and behavior-first assertions.
- **Verify (@Sentinel):** `T03` still covers one behavior only and does not bundle extra scenarios.

### How To Do It

- Use one canonical thrown error for the main test and optionally add a parameterized helper for synonym variants (e.g., `already exists`, `already registered`).
- Assert only the duplicate-email mapping branch behavior; do not bundle weak-password or invalid-email in this phase.
- Reuse shared auth test setup to keep the file compact and consistent.
- **Verify (@Sentinel):** implementation steps are reproducible by another engineer without extra decisions.

### What To Expect From This Test

- Stable regression coverage for duplicate-registration UX messaging.
- Clear separation of error-mapping branches, making future mapper changes safer to review.
- **Verify (@Sentinel):** regression value is clear and maintenance cost is acceptable for the scenario risk.

### What Input You Should Provide Me

- Tell me if you want one test only (canonical duplicate-email message) or table-driven subcases for multiple backend wordings (recommended: subcases in same phase/test group helper, still one primary test ID).
- If you provide nothing, I will proceed with the defaults/recommendations documented in Section A (after you approve the blocking seam decisions).

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block) implementing `T03` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.
- Any required seam/fake helper introduced for this test remains reusable and default-preserving.

### GATE CHECK

- `Duplicate-email error variant(s) chosen and mapped expected text documented.`
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 4: T04 - AuthViewModel queued session-expired callback fires after callback set

> Primary: @Architect
> Supporting: @Sentinel, @ThreatModeler

### Goal

- Implement and stabilize `T04` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.

### Why

- This protects a subtle startup timing edge case that can silently break forced re-login when auth errors arrive before UI wiring sets the callback.

### What We Need

- Test case target: `AuthViewModel queued session-expired callback fires after callback set`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/auth/viewmodels/auth_view_model.dart`.
- Injectable auth state stream with error emission control (e.g., `StreamController<AuthState>` with `addError`).
- A deterministic way to observe callback invocation count.
- A test that can assert queued behavior before and after callback assignment.
- **Verify (@Sentinel):** prerequisites are available and no unrelated dependencies are introduced.

### What To Do

- [ ] (@Architect) Emit an auth stream error before setting `onSessionExpired` callback.
- [ ] (@Architect) Assert callback did not fire immediately and pending state is queued behavior (indirectly via delayed callback trigger).
- [ ] (@Architect) Set callback and assert it fires exactly once and queue is cleared (behaviorally).
- [ ] (@Sentinel) Review the test for isolation, deterministic execution, and behavior-first assertions.
- **Verify (@Sentinel):** `T04` still covers one behavior only and does not bundle extra scenarios.

### How To Do It

- Use a stream controller passed to the constructor seam and call `addError(...)` before assigning `onSessionExpired`.
- Capture invocation count in a local integer; assign callback; pump microtasks if needed; assert count increments to 1 only after assignment.
- Avoid asserting private fields directly (`_pendingSessionExpired`); verify externally observable callback behavior only.
- **Verify (@Sentinel):** implementation steps are reproducible by another engineer without extra decisions.

### What To Expect From This Test

- Protection against a hard-to-reproduce startup/session-expiry regression that unit tests can catch cheaply.
- Confidence that auth listener timing races won’t silently bypass the login redirect mechanism.
- **Verify (@Sentinel):** regression value is clear and maintenance cost is acceptable for the scenario risk.

### What Input You Should Provide Me

- No blocking input if auth stream seam is approved in T01. Optional: tell me if you want an extra assertion for “fires only once on repeated callback assignment” (can be added later, not in this phase).
- If you provide nothing, I will proceed with the defaults/recommendations documented in Section A (after you approve the blocking seam decisions).

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block) implementing `T04` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.
- Any required seam/fake helper introduced for this test remains reusable and default-preserving.

### GATE CHECK

- `Auth stream error can be emitted deterministically before callback assignment without using real Supabase auth.`
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 5: T05 - AuthViewModel logout failure sets error and resets loading

> Primary: @Architect
> Supporting: @Sentinel, @APIContract

### Goal

- Implement and stabilize `T05` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.

### Why

- Logout failures can leave the app in a broken loading state and are easy to miss because the happy path is more frequently tested manually.

### What We Need

- Test case target: `AuthViewModel logout failure sets error and resets loading`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/auth/viewmodels/auth_view_model.dart`.
- AuthViewModel seam and fake auth repo from T01-T04.
- Fake `signOut()` failure path with an error string that should map to a friendly message.
- Decision on whether to assert a specific message or just non-null message + loading reset (recommended: specific message if copy is stable).
- **Verify (@Sentinel):** prerequisites are available and no unrelated dependencies are introduced.

### What To Do

- [ ] (@Architect) Implement fake signOut failure behavior.
- [ ] (@Architect) Write `logout()` failure test asserting return `false`, error set, and loading reset.
- [ ] (@Architect) Confirm no crash/throw escapes from `logout()` on handled failures.
- [ ] (@Sentinel) Review the test for isolation, deterministic execution, and behavior-first assertions.
- **Verify (@Sentinel):** `T05` still covers one behavior only and does not bundle extra scenarios.

### How To Do It

- Throw a controlled auth/network error from fake `signOut` and call `logout()`.
- Assert `result == false`, `error` is set to the expected mapped text, and `isLoading == false` in final state.
- Keep this scenario separate from session-expiry callback behavior (covered in T04).
- **Verify (@Sentinel):** implementation steps are reproducible by another engineer without extra decisions.

### What To Expect From This Test

- Protection against stuck loading spinners and raw error leakage during logout failures.
- A reliable unit-level guard for a path that is otherwise expensive to reproduce manually.
- **Verify (@Sentinel):** regression value is clear and maintenance cost is acceptable for the scenario risk.

### What Input You Should Provide Me

- Same message assertion choice as T02/T03: exact copy vs semantic match. If you choose exact, provide or approve the final expected logout failure wording.
- If you provide nothing, I will proceed with the defaults/recommendations documented in Section A (after you approve the blocking seam decisions).

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block) implementing `T05` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/auth/auth_view_model_test.dart`.
- Any required seam/fake helper introduced for this test remains reusable and default-preserving.

### GATE CHECK

- `Logout failure path is handled in fake repo and expected mapped message policy is chosen.`
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 6: T06 - TaskFilterViewModel search filters title and description

> Primary: @Architect
> Supporting: @Sentinel, @APIContract

### Goal

- Implement and stabilize `T06` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`.

### Why

- Task search is a high-frequency user path and filter regressions cause immediate UX quality issues with little compile-time signal.

### What We Need

- Test case target: `TaskFilterViewModel search filters title and description`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart`.
- Task fixture builder that creates tasks with varied titles/descriptions and deterministic IDs/budgets.
- No backend seams required (pure ViewModel logic).
- Clear expectation for case-insensitive matching (the current code is case-insensitive).
- **Verify (@Sentinel):** prerequisites are available and no unrelated dependencies are introduced.

### What To Do

- [ ] (@Architect) Build a small task fixture set with matches in title-only, description-only, both, and no match.
- [ ] (@Architect) Call `setTasks()` then `searchTasks(query)` and assert exact filtered IDs/order.
- [ ] (@Architect) Add negative assertion that unrelated tasks are excluded.
- [ ] (@Sentinel) Review the test for isolation, deterministic execution, and behavior-first assertions.
- **Verify (@Sentinel):** `T06` still covers one behavior only and does not bundle extra scenarios.

### How To Do It

- Use lowercase/uppercase mixed query strings to verify case-insensitive behavior explicitly.
- Keep the fixture set minimal (4-6 tasks) but intentional so failed assertions are readable.
- Assert on task IDs/titles in `filteredTasks`, not just count, to catch incorrect inclusions.
- **Verify (@Sentinel):** implementation steps are reproducible by another engineer without extra decisions.

### What To Expect From This Test

- Fast, deterministic coverage of the core search behavior without UI or backend dependencies.
- Regression signal if future filtering changes accidentally ignore description or break case-insensitivity.
- **Verify (@Sentinel):** regression value is clear and maintenance cost is acceptable for the scenario risk.

### What Input You Should Provide Me

- No blocking input required. Optional: provide real search terms/categories from your product language if you want fixtures to match real usage.
- If you provide nothing, I will proceed with the defaults/recommendations documented in Section A (after you approve the blocking seam decisions).

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block) implementing `T06` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`.
- Any required seam/fake helper introduced for this test remains reusable and default-preserving.

### GATE CHECK

- `Task fixture helper exists and expresses title/description matching cases clearly.`
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 7: T07 - TaskFilterViewModel category matches category or categoryName

> Primary: @Architect
> Supporting: @Sentinel, @APIContract

### Goal

- Implement and stabilize `T07` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`.

### Why

- The code supports both legacy `category` and newer `categoryName`; this is a compatibility rule that can break silently during cleanup/refactors.

### What We Need

- Test case target: `TaskFilterViewModel category matches category or categoryName`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart`.
- Task fixtures that intentionally split values across `category` and `categoryName` fields.
- A fixture case where one field is null and the other matches.
- A clear assertion about inclusion behavior when filtering by legacy vs resolved category values.
- **Verify (@Sentinel):** prerequisites are available and no unrelated dependencies are introduced.

### What To Do

- [ ] (@Architect) Create fixtures for legacy-only category, categoryName-only, both matching, and non-matching tasks.
- [ ] (@Architect) Apply `filterByCategory()` and assert exact included task IDs.
- [ ] (@Architect) Confirm non-matching tasks remain excluded.
- [ ] (@Sentinel) Review the test for isolation, deterministic execution, and behavior-first assertions.
- **Verify (@Sentinel):** `T07` still covers one behavior only and does not bundle extra scenarios.

### How To Do It

- Test the category string exactly as used by the ViewModel (`_selectedCategory`) and avoid mixing search + category in this phase.
- Assert compatibility behavior explicitly: a task should match if either `category` OR `categoryName` equals the filter value.
- Keep this test independent from sorting/budget logic to isolate failures.
- **Verify (@Sentinel):** implementation steps are reproducible by another engineer without extra decisions.

### What To Expect From This Test

- Protection for the legacy-to-new-category compatibility rule during future schema/UI cleanup.
- Immediate signal if category filtering accidentally narrows to one field only.
- **Verify (@Sentinel):** regression value is clear and maintenance cost is acceptable for the scenario risk.

### What Input You Should Provide Me

- No blocking input required. Optional: tell me if there is a preferred canonical category label set (e.g., `Design`, `Development`) you want fixtures to use.
- If you provide nothing, I will proceed with the defaults/recommendations documented in Section A (after you approve the blocking seam decisions).

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block) implementing `T07` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`.
- Any required seam/fake helper introduced for this test remains reusable and default-preserving.

### GATE CHECK

- `Fixture set includes legacy and new category field variants and test asserts both paths.`
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 8: T08 - TaskFilterViewModel min/max budget filter works

> Primary: @Architect
> Supporting: @Sentinel, @APIContract

### Goal

- Implement and stabilize `T08` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`.

### Why

- Budget filters are business-critical for task discovery and regressions directly affect matching quality and conversion.

### What We Need

- Test case target: `TaskFilterViewModel min/max budget filter works`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart`.
- Task fixtures with budgets around the boundaries (below min, on min, mid-range, on max, above max).
- Clarified expectation for inclusive boundaries (current code uses `>= min` and `<= max`, so inclusive).
- A test setup isolated from search/category filters.
- **Verify (@Sentinel):** prerequisites are available and no unrelated dependencies are introduced.

### What To Do

- [ ] (@Architect) Build budget-boundary fixtures and call `applyAdvancedFilters(minBudget, maxBudget)`.
- [ ] (@Architect) Assert inclusive boundary behavior explicitly (`min` and `max` values are kept).
- [ ] (@Architect) Assert outside-range tasks are excluded.
- [ ] (@Sentinel) Review the test for isolation, deterministic execution, and behavior-first assertions.
- **Verify (@Sentinel):** `T08` still covers one behavior only and does not bundle extra scenarios.

### How To Do It

- Use round-number budgets to make failures easy to read (for example 50, 100, 150, 200, 250).
- Run one scenario with both min and max; if needed, add local subcases for min-only and max-only without changing the phase scope.
- Assert resulting IDs and order (default order should be preserved unless sort is set).
- **Verify (@Sentinel):** implementation steps are reproducible by another engineer without extra decisions.

### What To Expect From This Test

- Stable coverage of inclusive budget range logic and prevention of off-by-one / boundary regressions.
- Better confidence in task filtering before widget tests exercise home/search UI integration.
- **Verify (@Sentinel):** regression value is clear and maintenance cost is acceptable for the scenario risk.

### What Input You Should Provide Me

- No blocking input required. Optional: confirm you want inclusive boundaries locked as contract (recommended: yes, matches current code).
- If you provide nothing, I will proceed with the defaults/recommendations documented in Section A (after you approve the blocking seam decisions).

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block) implementing `T08` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`.
- Any required seam/fake helper introduced for this test remains reusable and default-preserving.

### GATE CHECK

- `Boundary fixtures and inclusive-range expectation are explicitly documented in the test.`
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 9: T09 - TaskFilterViewModel clearFilters resets query/category/sort/budgets

> Primary: @Architect
> Supporting: @Sentinel, @APIContract

### Goal

- Implement and stabilize `T09` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`.

### Why

- Reset behavior often regresses when new filter fields are added; this test prevents stale filter state bugs.

### What We Need

- Test case target: `TaskFilterViewModel clearFilters resets query/category/sort/budgets`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart`.
- Fixture tasks plus a preloaded filter state using search/category/advanced filters.
- Assertions for reset values (`search`, `category`, `min/max`, seller levels, delivery times, `sortBy`).
- Expected post-reset `filteredTasks` behavior (all tasks restored in baseline order).
- **Verify (@Sentinel):** prerequisites are available and no unrelated dependencies are introduced.

### What To Do

- [ ] (@Architect) Set up a non-default filter state by applying search, category, and advanced filters.
- [ ] (@Architect) Call `clearFilters()` and assert all filter fields reset to defaults.
- [ ] (@Architect) Assert `filteredTasks` matches full task list again (same count and expected order).
- [ ] (@Sentinel) Review the test for isolation, deterministic execution, and behavior-first assertions.
- **Verify (@Sentinel):** `T09` still covers one behavior only and does not bundle extra scenarios.

### How To Do It

- Use getters to validate reset state rather than reaching into private fields.
- Assert list restoration after reset, not just control state reset, because UI depends on the resulting data list.
- Keep the test isolated from HomeScreen widget behavior (that wiring is covered later in T53-T55).
- **Verify (@Sentinel):** implementation steps are reproducible by another engineer without extra decisions.

### What To Expect From This Test

- Protection against stale-filter bugs when adding future advanced filters or sort options.
- Executable documentation of filter defaults for the TaskFilterViewModel contract.
- **Verify (@Sentinel):** regression value is clear and maintenance cost is acceptable for the scenario risk.

### What Input You Should Provide Me

- No blocking input required. Optional: confirm whether `sortBy = Relevance` should remain the reset default (recommended: yes, current behavior).
- If you provide nothing, I will proceed with the defaults/recommendations documented in Section A (after you approve the blocking seam decisions).

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block) implementing `T09` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_filter_view_model_test.dart`.
- Any required seam/fake helper introduced for this test remains reusable and default-preserving.

### GATE CHECK

- `Reset defaults are asserted via public getters and list restoration is verified.`
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 10: T10 - TaskViewModel setPickedImages enforces max 5 images

> Primary: @Architect
> Supporting: @Sentinel, @ThreatModeler

### Goal

- Implement and stabilize `T10` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_view_model_test.dart`.

### Why

- Image count limits are UX and backend-cost constraints; regressions here can create runtime failures or oversized uploads later.

### What We Need

- Test case target: `TaskViewModel setPickedImages enforces max 5 images`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_view_model.dart`.
- TaskViewModel constructor seam to avoid hard dependency on `Supabase.instance.client` during unit tests (repository injection or test constructor).
- A safe `XFile` fixture approach (no plugin invocation; simple in-memory/file-path `XFile` objects are sufficient).
- Assertion for truncation to exactly the first 5 images (not just count <= 5).
- **Verify (@Sentinel):** prerequisites are available and no unrelated dependencies are introduced.

### What To Do

- [ ] (@Architect) Add/confirm TaskViewModel testability seam (recommended: injectable `TaskRepository`, plus future-ready image picker/service seams).
- [ ] (@Architect) Build 6-7 fake `XFile` items and call `setPickedImages()`.
- [ ] (@Architect) Assert `pickedImages.length == 5` and preserved order of the first 5 inputs.
- [ ] (@Sentinel) Review the test for isolation, deterministic execution, and behavior-first assertions.
- **Verify (@Sentinel):** `T10` still covers one behavior only and does not bundle extra scenarios.

### How To Do It

- Instantiate `TaskViewModel` with fake repository or test constructor so no Supabase initialization is required.
- Create deterministic `XFile` fixtures with unique paths/names and pass a list longer than 5.
- Assert both truncation count and retained order to catch accidental sorting or tail-keep bugs.
- Do not combine with upload behavior or `pickTaskImages()` plugin path in this phase.
- **Verify (@Sentinel):** implementation steps are reproducible by another engineer without extra decisions.

### What To Expect From This Test

- Coverage of the image-cap rule before widget/integration tests touch task creation media flows.
- Early warning if future refactors remove or alter the image limit behavior.
- **Verify (@Sentinel):** regression value is clear and maintenance cost is acceptable for the scenario risk.

### What Input You Should Provide Me

- Approve TaskViewModel seam (recommended): `TaskViewModel({TaskRepository? repo, SupabaseClient? client, ImagePicker? imagePicker, TaskImageService? taskImageService})` or equivalent default-preserving design.
- Confirm whether preserving the first 5 images in original order is the expected contract (recommended: yes).
- If you provide nothing, I will proceed with the defaults/recommendations documented in Section A (after you approve the blocking seam decisions).

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block) implementing `T10` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_view_model_test.dart`.
- Any required seam/fake helper introduced for this test remains reusable and default-preserving.

### GATE CHECK

- `TaskViewModel can be instantiated offline and `XFile` fixtures are plugin-free.`
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- The previous `T01-T10` segment had useful structure but was too generic in several phases (especially auth and filter tests).
- It did not explicitly list the blocking user inputs needed to start implementation (auth/task seams + assertion strictness).
- It lacked gate status, risk prediction, invariants, and failure pre-mortem required by `@PlanCritic`.
- Some generated “How To Do It” guidance was mismatched to the test (for example cache-related advice appearing in an auth callback test).

### 2) Added steps (bullet list)

- Added full `@PlanCritic` audit sections A-I for this slice.
- Added explicit blocking decisions and a direct “What input you should provide me” section for the slice.
- Added gate-based dependency order and slice QA/release gate.
- Added a risk register and pre-mortem focused on real failure modes for `T01-T10`.
- Added per-phase `What Input You Should Provide Me` and `GATE CHECK` sections.

### 3) Removed steps (if any)

- Removed generic/misaligned guidance lines that did not match the specific test intent (for example irrelevant cache timestamp guidance in auth callback testing).

### 4) Reordered steps (from → to)

- From: direct phase list only.
- To: audit/gates/risks/invariants first, then corrected 10-phase test implementation plan.

### 5) Expanded steps (what became more detailed)

- Auth tests `T01-T05`: now specify fake auth stream/repo setup, exact assertions, and blocking seam decisions.
- Filter tests `T06-T09`: now specify fixture design, boundary cases, and compatibility behavior coverage.
- `T10`: now explicitly blocks on TaskViewModel offline constructor seam and asserts order preservation, not only count.

### 6) Why (short, practical)

- The original segment could still fail during execution because key dependencies and decisions were implicit. This version makes them explicit and test-by-test actionable.

### 7) Residual risks (what still remains risky even after fixes)

- If auth error copy is still changing frequently, exact-string assertions will create churn unless you choose semantic mode.
- If seam approvals are delayed, `T01-T05` and `T10` remain blocked even with a strong plan.
- Later slices (`T11+`) may reveal additional seam needs; this segment only hardens `T01-T10`.
