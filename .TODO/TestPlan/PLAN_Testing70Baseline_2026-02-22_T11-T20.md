# 📌 Plan Segment: 70-Test Baseline (T11-T20) — Re-improved with @PlanCritic

- Source master plan: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22.md`
- Segment file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22_T11-T20.md`
- Included phases/tests: `T11` to `T20` (TaskViewModel image/task state + BookingViewModel pagination/error/payment + DashboardPermissionService actions)
- Audit method applied: `@PlanCritic` from `.agent/workflows/plan_critic.md`

## Purpose

- Turn the `T11-T20` slice into an execution-safe, gate-based mini-plan with explicit blockers and no hidden dependency on real Supabase.
- Make each test phase implementation-ready: what we need, what to do, how to do it, what to expect, and what input you should provide.
- Preserve strict scope: `1 phase = 1 test` and no production behavior changes beyond approved testability seams.

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- This slice is still unit-test only and should run fully offline.
- `TaskViewModel` and `BookingViewModel` may require constructor seams to avoid Supabase singleton initialization during unit tests.
- `PaymentService` injection already exists in `BookingViewModel` and can be used directly for `T18` once offline construction is solved.
- Dashboard permission tests (`T19-T20`) are pure static logic and do not require backend or UI setup.
- Page-size contract for `BookingViewModel.loadSlots` is currently `_pageSize = 50` and `hasMore = data.length == _pageSize`.

### Decision Needed (Blocking)

- Missing decision: **TaskViewModel offline construction seam (shared blocker for T10-T13)**
  - Options:
  - Inject `TaskRepository` (recommended; default-preserving and useful beyond this slice)
  - Add test-only constructor bypassing repository initialization
  - Use real Supabase initialization in unit tests (not recommended)
  - Recommended: repository injection with default fallback.
  - Plan impact: blocks `T11-T13` if unresolved.

- Missing decision: **BookingViewModel offline seams for repository/chat**
  - Options:
  - Inject `BookingRepository` + `ChatRepository` + existing `PaymentService` (recommended)
  - Accept fake `SupabaseClient` approach for unit tests (not recommended; too heavy/brittle)
  - Defer `T14-T18` until integration tests (not recommended; loses unit-value coverage)
  - Recommended: explicit repository injections with default-preserving constructor behavior.
  - Plan impact: blocks `T14-T18` if unresolved.

- Missing decision: **Booking error/message assertion strictness (`T14`, `T18`)**
  - Options:
  - Exact string assertions (good if UX copy is stable)
  - Semantic contains/regex assertions (recommended if copy may evolve)
  - Non-null only (not recommended)
  - Recommended: semantic for booking/payment errors unless you have frozen product copy.
  - Plan impact: affects test brittleness and review expectations.

- Missing decision: **T15/T16 pagination test granularity**
  - Options:
  - One scenario with local subcases for page-size/guard branches (recommended; preserves 70-test count)
  - Split into more tests (not allowed without changing the 70-test plan)
  - Minimal single-branch only (weaker coverage)
  - Recommended: one test with subcases where needed, but keep one primary assertion focus per phase.
  - Plan impact: defines how much branch coverage can be packed into `T15` and `T16` without scope drift.

### What Input You Should Provide Me (For This Slice)

- Approve or edit the **TaskViewModel offline seam** (blocking for `T11-T13`).
- Approve or edit the **BookingViewModel repository/chat injection seams** (blocking for `T14-T18`).
- Choose **booking/payment error assertion mode** for `T14` and `T18`: exact vs semantic contains.
- Confirm whether `100.0` default price in `T17` should be locked as a contract (recommended for current code, but label it as simulation default).
- Optional: confirm if `T19-T20` should assert both primary action and permission flags (recommended: yes).

## B) Gate Status (Pass/Fail)

### 1) Data/Contracts Gate

- Status: ⚠️ PARTIAL
- Reason: Task and booking fixture contracts are needed for `T11-T18` but are not yet standardized for this slice.
- Reason: Dashboard permission tests (`T19-T20`) are low-risk and pure enum-based.
- What to add/fix to pass: Define slice-level fixture builders and lock booking pagination/error assertion expectations before coding.

### 2) Security Gate

- Status: ⚠️ PARTIAL
- Reason: `T14` and `T18` touch user-facing error handling for booking/payment paths and should prevent raw DB/payment error leakage.
- Reason: `T19-T20` encode workflow-critical action decisions tied to client payment/review actions.
- What to add/fix to pass: Keep error assertions behavioral and explicitly verify payment/review action decisions and precedence.

### 3) Backend/API Gate

- Status: ❌ FAIL
- Reason: `TaskViewModel` and `BookingViewModel` still depend on runtime-backed construction unless seams are added.
- Reason: `T14-T18` cannot be reliable unit tests without fake repositories and deterministic exceptions.
- What to add/fix to pass: Approve and implement default-preserving seams for TaskViewModel and BookingViewModel before test implementation starts.

### 4) UI/Integration Gate

- Status: ✅ PASS (N/A for slice)
- Reason: This slice contains unit tests only.
- Reason: No widget or staging integration setup is required if seams are added correctly.
- What to add/fix to pass: Maintain offline-only scope and do not leak widget/backend concerns into the tests.

### 5) Release/QA Gate

- Status: ❌ FAIL
- Reason: No slice-specific run command and review checklist is locked for `T11-T20` yet.
- Reason: No explicit stop condition for branch/subcase scope in pagination tests.
- What to add/fix to pass: Define run command, subcase policy, and reviewer checklist before merge.

## C) Critical Gaps (Must-Fix)

- **Gap:** TaskViewModel offline construction still unresolved
- **Why it will break:** `T11-T13` will either fail at construction or force real Supabase initialization in unit tests.
- **Fix (exact step(s) to add / reorder):** Add/approve repository injection seam before any TaskViewModel test in this slice.
- **Owner:** Backend/Frontend (@Architect)
- **Acceptance check:** TaskViewModel tests instantiate offline and run without Supabase setup.

- **Gap:** BookingViewModel lacks repository/chat injection seams
- **Why it will break:** `T14-T18` depend on fake repository behaviors (errors, slots, booking returns, call counters) that are impractical without explicit seams.
- **Fix (exact step(s) to add / reorder):** Add `BookingRepository` and `ChatRepository` injectable parameters with default fallbacks; reuse existing `PaymentService` injection.
- **Owner:** Backend/Frontend (@Architect)
- **Acceptance check:** BookingViewModel unit tests run with fake repos and no real Supabase client.

- **Gap:** PostgrestException test construction strategy undefined
- **Why it will break:** `T14` can fail to hit the intended `_mapError` branch if the test uses the wrong exception type/shape.
- **Fix (exact step(s) to add / reorder):** Decide and document how to construct a valid `PostgrestException` for current package version, or create a helper tested once.
- **Owner:** Backend (@Architect) + QA (@Sentinel)
- **Acceptance check:** T14 reliably triggers code `23505` branch in unit test.

- **Gap:** Booking pagination boundary assertions are not locked
- **Why it will break:** `T15/T16` can become weak or inconsistent if page-size/guard expectations vary by reviewer.
- **Fix (exact step(s) to add / reorder):** Define page-size contract (`50`) and subcase policy in this segment before implementation.
- **Owner:** Backend (@Architect) + QA (@Sentinel)
- **Acceptance check:** T15/T16 assertions explicitly match current page-size and guard semantics.

- **Gap:** No slice-level review checklist for behavior vs implementation assertions
- **Why it will break:** Brittle tests may pass review if they over-assert internals (especially call order/notify counts).
- **Fix (exact step(s) to add / reorder):** Add reviewer checklist and enforce it in this segment before merge.
- **Owner:** QA (@Sentinel)
- **Acceptance check:** All `T11-T20` tests pass checklist and avoid private-field assertions.

## D) Invariants & Success Criteria (Non-Negotiable)

- **Invariant:** Out-of-range image removal is safe and does not mutate `pickedImages`
- **How to enforce:** Enforce with `T11` using invalid indices and exact list equality assertions.
- **How to verify:** List content/order unchanged and no exception thrown.

- **Invariant:** Task creation prepends new task to local list and resets loading
- **How to enforce:** Enforce with `T12` using fake repo success and pre-seeded list.
- **How to verify:** Created task is index 0; final `isLoading == false`; prior tasks remain.

- **Invariant:** Task status update optimistically updates only the matching local task
- **How to enforce:** Enforce with `T13` using fake repo call capture and seeded list.
- **How to verify:** Target task status changes; non-target tasks unchanged.

- **Invariant:** Booking duplicate/unique violation errors are mapped to user-friendly text
- **How to enforce:** Enforce with `T14` using `PostgrestException` code `23505` through a public method path.
- **How to verify:** Final error state contains mapped user-facing message, not raw DB error leakage.

- **Invariant:** `loadSlots()` success updates list + cursor + `hasMore` deterministically from repo response size
- **How to enforce:** Enforce with `T15` using ordered slot fixtures and page-size boundary expectations.
- **How to verify:** Cursor equals ISO string of last slot start time; `slotsHasMore` matches length==50 logic.

- **Invariant:** `loadMoreSlots()` guard branches must not trigger repository calls when blocked
- **How to enforce:** Enforce with `T16` and fake repo call counters.
- **How to verify:** No new `listSlots` calls under loading/no-cursor/no-more guard states.

- **Invariant:** `bookSlot(price: null)` uses default price and prepends booking to client list
- **How to enforce:** Enforce with `T17` using fake repo price capture and deterministic booking return.
- **How to verify:** Captured price is `100.0` (if contract approved) and new booking is at list index 0.

- **Invariant:** Payment failure clears processing state and surfaces error
- **How to enforce:** Enforce with `T18` using failing fake PaymentService.
- **How to verify:** Result is null; `isProcessingPayment == false`; `bookingsError` is set.

- **Invariant:** Unified delivered client state resolves to review CTA
- **How to enforce:** Enforce with `T19` against `getPrimaryAction` (and optionally `canReview`).
- **How to verify:** `reviewDelivery` returned and `canReview` remains true if asserted.

- **Invariant:** Unified pendingPayment client state resolves to escrow CTA
- **How to enforce:** Enforce with `T20` against `getPrimaryAction` (and optionally `canPayEscrow`).
- **How to verify:** `payEscrow` returned and `canPayEscrow` remains true if asserted.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| TaskViewModel seam delayed | T11-T13 | High | High | Feature | Unit tests crash at constructor or require Supabase setup | Approve and implement seam first | Temporarily pause T11-T13 and work T19-T20 |
| BookingViewModel seam delayed | T14-T18 | High | High | Feature | Cannot fake repo behaviors or call counters | Inject BookingRepository/ChatRepository with defaults | Defer booking tests and document blocker explicitly |
| Wrong PostgrestException shape used in T14 | T14 | Med | High | Feature | Test does not hit 23505 branch or fails on type mismatch | Create helper to construct package-correct exception instance | Switch to another public method path with controlled exception helper |
| Pagination boundary expectation mismatch | T15 | Med | Med | Feature | Review churn over `hasMore` expected value | Lock `_pageSize=50` and `==` semantics in plan | Use semantic assertions + document contract change if code changes intentionally |
| Guard branch test accidentally triggers repo call | T16 | Med | High | Feature | Fake repo call counter increments unexpectedly | Use fail-fast fake repo and subcase setup for each blocked state | Split debugging locally, keep one final test phase with subcases |
| Default price contract changes from 100.0 | T17 | Med | Med | Feature | Assertion fails after business change | Document value as simulation default and get user approval | Update test + plan explicitly if business rule changes |
| Payment error copy churn | T18 | Med | Med | Feature | Frequent assertion edits without behavior change | Choose semantic assertion mode unless copy frozen | Relax to contains assertions with documented rationale |
| Permission tests assert too little | T19-T20 | Low | Med | Feature | Primary action passes but permission flags regress silently | Assert both action and permission flags in same phase | Add stronger assertions before merge |
| Brittle internal assertions reduce trust | T11-T20 | Med | Med | Local | Tests fail after harmless refactor | Behavior-first review checklist enforced by @Sentinel | Refactor tests to public-state assertions before merge |

## F) Pre-Mortem (How this fails in real life)

- This fails when the team starts writing `T14-T18` before adding BookingViewModel repo seams and ends up trying to mock a full Supabase client in unit tests.
- This fails when `T15` asserts only list count and ignores cursor/hasMore, so pagination regressions slip through.
- This fails when `T16` does not verify repo call counts and the guard clauses regress silently, causing duplicate backend requests in production.
- This fails when `T17` checks only local list prepend but never verifies the default price passed to the repository, missing a business-rule regression.
- This fails when `T18` asserts only exception throwing and misses the real UX contract (`isProcessingPayment` reset + `bookingsError` set).
- This fails when `T19-T20` only assert permissions or only primary actions, leaving action-precedence regressions undetected.
- This fails when auth/task seam decisions from earlier slices are ignored and inconsistent seam styles spread across the codebase.

## G) Plan Fixes (Concrete Additions / Expansions)

- **Goal:** Lock TaskViewModel and BookingViewModel seam decisions for this slice
- **Why:** These are hard blockers for unit-test isolation in `T11-T18`.
- **How:** Approve default-preserving constructor injections before implementation.
- **Output artifact:** Plan approvals + code seam changes
- **Stop condition:** All slice tests instantiate ViewModels offline without Supabase init.

- **Goal:** Create booking test fixtures + fake repository helpers
- **Why:** Booking tests require slots/bookings/error/code/call-count scenarios that are too complex for ad-hoc setup.
- **How:** Build reusable fake repo + fixture helpers in `booking_view_model_test.dart` or `test_support/fakes`.
- **Output artifact:** Fakes/fixtures helpers
- **Stop condition:** T14-T18 tests are readable and deterministic with minimal duplication.

- **Goal:** Define pagination and default-price contracts explicitly in the slice
- **Why:** Without explicit contracts, reviewers will disagree on expected behavior and tests will churn.
- **How:** Document `_pageSize=50`, `hasMore == length`, and default price `100.0` decision in this segment and tests.
- **Output artifact:** Plan text + test comments
- **Stop condition:** T15-T17 assertions match documented behavior and changes are intentional if updated later.

- **Goal:** Strengthen permission tests to cover action + permission flags
- **Why:** Primary action alone may pass while permission flags regress, or vice versa.
- **How:** Assert both outputs in `T19-T20` without adding extra test IDs.
- **Output artifact:** Permission service tests
- **Stop condition:** Dashboard action/permission regressions are caught by the same slice.

- **Goal:** Add per-phase user input requirements
- **Why:** This reduces repeated back-and-forth and exposes blockers before implementation starts.
- **How:** Document blocking and optional inputs in each phase below.
- **Output artifact:** Per-phase plan updates
- **Stop condition:** Implementer can start each phase with no hidden decision-making.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Slice Dependency Order (T11-T20)

1. Data/Contracts: lock booking error assertion mode, pagination boundary expectations, and default-price contract for `T14-T18`.
2. Security-sensitive behavior coverage: booking error/payment and dashboard client action decisions (`T14`, `T18-T20`).
3. Backend/App logic unit tests: TaskViewModel and BookingViewModel state/guard/pagination behavior (`T11-T18`).
4. UI/Integration: not applicable for this slice (unit tests only).
5. QA/Release: deterministic grouped run + review checklist signoff before moving to `T21-T30`.

### Shared Implementation Rules (Applies to T11-T20)

- [ ] (@Architect) No production behavior changes; only default-preserving testability seams.
- [ ] (@Sentinel) All tests run offline and deterministically; no real Supabase init, no platform channels, no picker plugin usage.
- [ ] (@ThreatModeler) Booking error and payment tests must verify user-facing behavior and safe failure paths (not raw backend leakage).
- [ ] (@Sentinel) Pagination tests must assert cursor/guard semantics explicitly, not only list counts.

### Slice QA/Release Gate (Before Marking T11-T20 Complete)

- [ ] (@Sentinel) `flutter test /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard` passes for `T11-T20`.
- [ ] (@Sentinel) All blocking decisions in Section A are resolved and reflected in the test assertions/comments.
- [ ] (@Sentinel) Review checklist passes: no private-field assertions, no hidden network/plugin usage, one-phase-one-test scope maintained.
- **GATE CHECK:** `T11-T20` is stable and merge-ready before starting `T21-T30`.

## Phase 11: T11 - TaskViewModel removePickedImageAt ignores out-of-range index safely

> Primary: @Architect
> Supporting: @Sentinel

### Goal

- Implement and stabilize `T11` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_view_model_test.dart`.

### Why

- This is a defensive-state test that prevents crashes from invalid UI indices and protects against accidental list mutation when users remove images quickly.

### What We Need

- Test case target: `TaskViewModel removePickedImageAt ignores out-of-range index safely`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_view_model.dart`.
- Offline TaskViewModel construction seam (repository injection or equivalent default-preserving approach).
- Deterministic `XFile` fixtures (plugin-free, no picker invocation).
- A clear decision on whether to assert only “no mutation + no throw” or also listener notification behavior (recommended: no throw + no mutation only).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Approve/confirm TaskViewModel offline seam before writing the test.
- [ ] (@Architect) Seed `pickedImages` with a small known list using `setPickedImages()`.
- [ ] (@Architect) Call `removePickedImageAt()` with an out-of-range index (and optionally negative index as local subcase).
- [ ] (@Architect) Assert no exception, unchanged list length, and unchanged item order/content.
- [ ] (@Sentinel) Review the test for deterministic execution, behavior-first assertions, and scope discipline.
- **Verify (@Sentinel):** `T11` remains one scenario and does not hide extra branch coverage requirements.

### How To Do It

- Arrange with 2-3 deterministic `XFile` fixtures and snapshot the original paths/names.
- Act using an invalid index (`-1` and/or `>= length`) while keeping this phase scoped to out-of-range safety behavior.
- Assert exact list equality (not just count) to prevent silent mutation bugs.
- Avoid exact `notifyListeners()` count assertions unless you explicitly ask for them, because they are brittle for this scenario.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- A stable offline unit test that prevents index-related crashes and unintended state mutation in image-selection flows.
- Safer future refactors around task image list operations and UI remove actions.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve the TaskViewModel offline seam (same blocker as T10/T12/T13).
- Confirm assertion policy for this test: behavior-only (`no throw + unchanged list`) vs behavior + listener assertions (recommended: behavior-only).
- If you provide nothing, I will use the defaults/recommendations documented in Section A after blocking seam approvals are resolved.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T11` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_view_model_test.dart`.
- Any helper/fake added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- TaskViewModel can be instantiated offline and out-of-range remove leaves `pickedImages` unchanged with no exception.
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 12: T12 - TaskViewModel createTask prepends created task and resets loading

> Primary: @Architect
> Supporting: @Sentinel, @APIContract

### Goal

- Implement and stabilize `T12` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_view_model_test.dart`.

### Why

- This protects a high-value optimistic UX path and ensures task creation updates local state immediately without leaving loading stuck.

### What We Need

- Test case target: `TaskViewModel createTask prepends created task and resets loading`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_view_model.dart`.
- TaskViewModel repository seam with a fake repository that captures `createTask()` input and returns a controlled created task.
- Task fixtures for both an existing list state and a newly created task result.
- A deterministic pre-seed strategy for `_tasks` (recommended: use public `loadTasks()` with fake repo in arrange, not test-only state hacks).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Implement/confirm fake TaskRepository with `getTasks()` and `createTask()` call recording.
- [ ] (@Architect) Preload one or more tasks into the ViewModel (recommended via `loadTasks()` in arrange).
- [ ] (@Architect) Call `createTask()` and assert returned task, list prepend behavior (`index 0`), and final `isLoading == false`.
- [ ] (@Architect) Assert previously existing tasks remain after the new task at subsequent indices.
- [ ] (@Sentinel) Review the test for deterministic execution, behavior-first assertions, and scope discipline.
- **Verify (@Sentinel):** `T12` remains one scenario and does not hide extra branch coverage requirements.

### How To Do It

- Use a fake repository that returns a distinct `created` task object so prepend order is unambiguous.
- Arrange -> optional preload -> Act -> Assert exact list IDs order (`created` first, old tasks after).
- Assert behavior (return value, list state, loading reset) rather than exact internal notification ordering.
- Keep error path out of this phase; failure behavior belongs in a separate test ID later if needed.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Reliable coverage for optimistic task creation state updates and loading reset semantics.
- Faster detection of regressions that would otherwise surface as delayed or missing task cards in UI flows.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve using `loadTasks()` as the arrange-step preseed method (recommended) instead of adding a test-only task seeding helper.
- Optional: choose whether this test should assert exact list order or just `created` is first (recommended: exact order).
- If you provide nothing, I will use the defaults/recommendations documented in Section A after blocking seam approvals are resolved.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T12` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_view_model_test.dart`.
- Any helper/fake added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Fake TaskRepository can seed existing tasks and return created task; test proves prepend + loading reset offline.
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 13: T13 - TaskViewModel updateTaskStatus updates local task status optimistically

> Primary: @Architect
> Supporting: @Sentinel, @APIContract

### Goal

- Implement and stabilize `T13` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_view_model_test.dart`.

### Why

- Task status changes drive multiple UI surfaces; this test locks the local optimistic update behavior that users see immediately after an action.

### What We Need

- Test case target: `TaskViewModel updateTaskStatus updates local task status optimistically`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_view_model.dart`.
- TaskViewModel repository seam and fake repository that records `updateTaskStatus` calls.
- Seeded local task list containing the target task ID and an unaffected sibling task.
- Clear contract choice for optimistic update scope (recommended: assert target changes and non-target items remain unchanged).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Seed ViewModel with tasks (recommended via fake `getTasks()` + `loadTasks()` arrange step).
- [ ] (@Architect) Call `updateTaskStatus(taskId, status)` on an existing task ID.
- [ ] (@Architect) Assert repository was invoked with the same ID/status and local list reflects the updated status immediately after completion.
- [ ] (@Architect) Assert unaffected tasks remain unchanged.
- [ ] (@Sentinel) Review the test for deterministic execution, behavior-first assertions, and scope discipline.
- **Verify (@Sentinel):** `T13` remains one scenario and does not hide extra branch coverage requirements.

### How To Do It

- Use a fake repo that succeeds immediately and records the last call parameters for verification.
- Assert exact target task status after update and verify list identity/order remains stable unless intentionally changed by implementation.
- Do not bundle “missing task ID” behavior into this phase; keep it strictly focused on optimistic update for an existing item.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Protection for optimistic status updates used by task list/detail UI interactions.
- A clear regression signal if local task mutation is removed, delayed, or applied to the wrong item.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm optimistic update contract scope: update only matching task and leave others untouched (recommended).
- Optional: confirm if list order should remain unchanged after status update (recommended: yes for this test).
- If you provide nothing, I will use the defaults/recommendations documented in Section A after blocking seam approvals are resolved.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T13` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/tasks/task_view_model_test.dart`.
- Any helper/fake added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Existing-task optimistic update works offline and only mutates the intended task item.
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 14: T14 - BookingViewModel Postgres 23505 maps to already exists/booked message

> Primary: @Architect
> Supporting: @ThreatModeler, @Sentinel, @APIContract

### Goal

- Implement and stabilize `T14` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.

### Why

- Unique-violation handling is a critical booking safety path (double-booking prevention) and the error message must stay user-friendly under backend errors.

### What We Need

- Test case target: `BookingViewModel Postgres 23505 maps to already exists/booked message`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart`.
- BookingViewModel offline seam to inject fake `BookingRepository` (and ideally fake `ChatRepository`) without constructing real Supabase-backed repositories.
- A reliable way to generate a `PostgrestException` (or equivalent test double that passes the `is PostgrestException` branch) with code `23505`.
- Decision on exact vs semantic message assertion for the user-facing duplicate-booking text.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Add/confirm constructor seams for `BookingRepository` and `ChatRepository` injection (default-preserving).
- [ ] (@Architect) Choose a public method path that triggers `_mapError` with a repository-thrown `PostgrestException` (recommended: `bookSlot()` or `loadSlots()` failure path).
- [ ] (@Architect) Implement test to assert the final `bookingsError` or `slotsError` contains the expected friendly duplicate message.
- [ ] (@Architect) Assert the method fails gracefully (null/false/no throw as appropriate to the chosen method).
- [ ] (@Sentinel) Review the test for deterministic execution, behavior-first assertions, and scope discipline.
- **Verify (@Sentinel):** `T14` remains one scenario and does not hide extra branch coverage requirements.

### How To Do It

- Use a fake repository that throws a `PostgrestException` with code `23505` and a representative duplicate-booking message.
- Prefer `bookSlot()` if you want the business meaning to stay explicit (“already booked”); keep fixtures minimal and deterministic.
- Assert user-facing mapped error text and avoid raw DB code/message leakage in final state.
- Do not test other Postgres codes in this phase; keep 23505 coverage isolated.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Protection for a high-risk booking conflict path with direct UX impact.
- Early detection if backend exception handling changes and raw DB errors start leaking to UI.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Approve BookingViewModel seam: inject `BookingRepository` and `ChatRepository` (recommended, default-preserving).
- Choose assertion mode for mapped message: exact string vs semantic contains (same policy style as auth tests).
- If you know the exact user-facing wording you want for duplicate bookings, provide it now to lock the test.
- If you provide nothing, I will use the defaults/recommendations documented in Section A after blocking seam approvals are resolved.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T14` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.
- Any helper/fake added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- BookingViewModel can be instantiated offline with fake repositories and a controlled 23505 error path hits `_mapError` behaviorally.
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 15: T15 - BookingViewModel loadSlots sets list, cursor, and hasMore correctly

> Primary: @Architect
> Supporting: @ThreatModeler, @Sentinel, @APIContract

### Goal

- Implement and stabilize `T15` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.

### Why

- Cursor pagination state is foundational for bookings UX and breaks easily if list/cursor/hasMore semantics drift from repository page size behavior.

### What We Need

- Test case target: `BookingViewModel loadSlots sets list, cursor, and hasMore correctly`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart`.
- BookingViewModel seam with fake BookingRepository injection.
- Slot fixtures with deterministic `startsAtUtc` ordering and at least one case for page size boundary semantics.
- Documented page-size contract (`_pageSize = 50` currently) and `hasMore = data.length == _pageSize` behavior to assert correctly.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Build slot fixtures ordered by `startsAtUtc` ascending with deterministic timestamps.
- [ ] (@Architect) Write one scenario where returned count is less than page size (hasMore false) and/or exactly page size (hasMore true) depending test scope chosen.
- [ ] (@Architect) Call `loadSlots(providerId)` and assert `slots`, `slotsCursor`, `slotsHasMore`, `slotsLoading`, and error reset behavior.
- [ ] (@Sentinel) Review the test for deterministic execution, behavior-first assertions, and scope discipline.
- **Verify (@Sentinel):** `T15` remains one scenario and does not hide extra branch coverage requirements.

### How To Do It

- Use a fake repository response already in ascending order to match repository contract and make cursor expectation deterministic.
- Assert `slotsCursor` equals `last.startsAtUtc.toUtc().toIso8601String()` exactly.
- If you include both boundary variants, structure them as local subcases in one test block but keep the primary phase scope focused on state correctness after `loadSlots()`.
- Assert final `slotsLoading == false` and `slotsError == null` for the success path.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Protection for slot list pagination state and cursor calculation logic.
- Fast failure if page-size semantics or cursor derivation regresses, before UI/infinite-scroll tests are added.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm whether you want this phase to assert one page-size variant only (recommended: exact-page-size case for `hasMore == true`) or include both exact and short-page subcases.
- Optional: confirm page-size contract should be treated as fixed `50` at ViewModel level for this test slice (recommended: yes, current code).
- If you provide nothing, I will use the defaults/recommendations documented in Section A after blocking seam approvals are resolved.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T15` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.
- Any helper/fake added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Fake slot fixtures and page-size expectation are documented; `loadSlots()` success state is fully asserted offline.
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 16: T16 - BookingViewModel loadMoreSlots guard prevents request when loading/no cursor/no more

> Primary: @Architect
> Supporting: @ThreatModeler, @Sentinel

### Goal

- Implement and stabilize `T16` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.

### Why

- Guard clauses prevent wasted calls and race conditions; regressions here can create duplicate requests, UI flicker, and backend load spikes.

### What We Need

- Test case target: `BookingViewModel loadMoreSlots guard prevents request when loading/no cursor/no more`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart`.
- BookingViewModel seam and fake repository with call counters for `listSlots()`.
- A way to set/seed `slotsLoading`, `slotsCursor`, and `slotsHasMore` states via public methods or controlled setup.
- Decision on scenario granularity: one test with subcases for all three guards vs separate tests (this phase is one test, recommended: subcases).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Create a fake repo that records slot-list calls and can fail the test if unexpectedly called.
- [ ] (@Architect) Exercise `loadMoreSlots()` under guard states: `slotsLoading=true`, `slotsCursor=null`, and `slotsHasMore=false`.
- [ ] (@Architect) Assert repository call count remains unchanged in each guard case.
- [ ] (@Sentinel) Review the test for deterministic execution, behavior-first assertions, and scope discipline.
- **Verify (@Sentinel):** `T16` remains one scenario and does not hide extra branch coverage requirements.

### How To Do It

- Use one test block with three arrange/act/assert subcases to keep the single-phase scope while covering all guard branches.
- Set state using public methods where possible; if not practical, document minimal test seam/state helper needed and keep it default-preserving.
- Assert zero additional repo calls rather than only asserting unchanged UI state, because the main contract is “no request is made”.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Protection against duplicate pagination requests and unnecessary network churn.
- A precise regression signal if future changes weaken the guard conditions in `loadMoreSlots()`.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm subcase style inside one test for the three guard conditions (recommended) vs splitting later into more tests (would break current 70-count plan).
- If you prefer not to add any state helper seam, approve using controlled prior method calls to reach each guard state where feasible.
- If you provide nothing, I will use the defaults/recommendations documented in Section A after blocking seam approvals are resolved.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T16` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.
- Any helper/fake added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Guard branch assertions prove no repository request occurs in all targeted blocked states.
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 17: T17 - BookingViewModel bookSlot with null price uses default and prepends client list

> Primary: @Architect
> Supporting: @ThreatModeler, @Sentinel, @APIContract

### Goal

- Implement and stabilize `T17` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.

### Why

- This phase locks both a business fallback rule (`default price`) and an optimistic UI behavior (prepend to client bookings), making it high-value and easy to regress.

### What We Need

- Test case target: `BookingViewModel bookSlot with null price uses default and prepends client list`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart`.
- BookingViewModel seam with fake BookingRepository injection and call parameter capture for `bookSlot()`.
- Booking fixture for repository success result plus an initial `bookingsAsClient` baseline state if testing prepend relative order.
- Documented default price contract (`100.0` in current code) and decision whether to lock that exact value as a test contract.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Set up fake repository to record `price` argument and return a deterministic booking model.
- [ ] (@Architect) Seed `bookingsAsClient` with one existing booking if asserting prepend relative order.
- [ ] (@Architect) Call `bookSlot(..., price: null)` and assert captured price is `100.0`, method returns booking, and local list prepends the new booking.
- [ ] (@Architect) Assert `bookingsError` remains null on success path.
- [ ] (@Sentinel) Review the test for deterministic execution, behavior-first assertions, and scope discipline.
- **Verify (@Sentinel):** `T17` remains one scenario and does not hide extra branch coverage requirements.

### How To Do It

- Use fake repository call capture to prove the fallback price is passed into the data layer, not merely set in local state.
- Assert exact local list order (`newBooking` at index 0, prior items shifted) for the optimistic prepend contract.
- Keep payment processing concerns out of this test; those are covered separately in `T18`.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Coverage of a key booking business rule and immediate user-visible state update in a single high-value scenario.
- Fast detection if default pricing changes unintentionally or optimistic prepend behavior disappears.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm whether `100.0` should be locked as an explicit contract in the test (recommended for current code, but call it out as a “Phase 1 simulation default”).
- Confirm whether this test should pre-seed one existing booking to prove prepend order (recommended: yes).
- If you provide nothing, I will use the defaults/recommendations documented in Section A after blocking seam approvals are resolved.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T17` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.
- Any helper/fake added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Fake booking repo captures `price` and local client booking list prepend is proven after `bookSlot(price: null)`.
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 18: T18 - BookingViewModel processPayment failure sets bookingsError and clears processing flag

> Primary: @Architect
> Supporting: @ThreatModeler, @Sentinel

### Goal

- Implement and stabilize `T18` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.

### Why

- Payment failure handling is high-risk; this test prevents stuck processing indicators and ensures user-facing errors are surfaced instead of silent failures.

### What We Need

- Test case target: `BookingViewModel processPayment failure sets bookingsError and clears processing flag`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart`.
- BookingViewModel offline seam (repo/chat injections or offline-safe constructor) and injectable `PaymentService` (already present in code).
- Fake `PaymentService` that throws a controlled exception on `processPayment`.
- Decision on exact vs semantic assertion for `bookingsError` mapped output (recommended: semantic if provider messages may change).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Instantiate BookingViewModel with fake repositories/offline-safe constructor and failing fake PaymentService.
- [ ] (@Architect) Call `processPayment(...)` and assert returned transaction ID is `null`.
- [ ] (@Architect) Assert `isProcessingPayment` ends as `false` and `bookingsError` is set to a user-facing value.
- [ ] (@Architect) Assert no exception escapes for handled payment failure path.
- [ ] (@Sentinel) Review the test for deterministic execution, behavior-first assertions, and scope discipline.
- **Verify (@Sentinel):** `T18` remains one scenario and does not hide extra branch coverage requirements.

### How To Do It

- Use a fake payment service that throws deterministically on first call to hit the catch/finally path.
- Assert final state after await (`_isProcessingPayment` false) because the core regression risk is stuck payment UI state.
- Prefer semantic error assertion unless you intentionally treat payment copy as fixed product contract.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Protection for payment error handling UX and prevention of stuck processing states in booking flows.
- A fast unit-level signal for a path that is expensive and risky to reproduce manually or in integration tests.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Choose `bookingsError` assertion mode for payment failures: exact string vs semantic contains (recommended: semantic unless copy is frozen).
- Optional: provide the exact payment failure wording you want surfaced if you choose strict assertions.
- If you provide nothing, I will use the defaults/recommendations documented in Section A after blocking seam approvals are resolved.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T18` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`.
- Any helper/fake added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Payment failure path runs offline and ends with `isProcessingPayment == false` plus a visible `bookingsError`.
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 19: T19 - DashboardPermissionService unified delivered (client) gives reviewDelivery primary action

> Primary: @Architect
> Supporting: @ThreatModeler, @Sentinel

### Goal

- Implement and stabilize `T19` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard/dashboard_permission_service_test.dart`.

### Why

- This locks a client-facing decision rule in the unified work dashboard; a wrong primary action here can break the core workflow and confuse users.

### What We Need

- Test case target: `DashboardPermissionService unified delivered (client) gives reviewDelivery primary action`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard/dashboard_permission_service_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/services/dashboard_permission_service.dart`.
- Pure enum-based test inputs (`UserRole.client`, `WorkItemType.booking` or task context, `UnifiedWorkStatus.delivered`).
- Decision on assertion scope: test only primary action or also verify permission flags (`canReview`) in same scenario (recommended: both, still one scenario).
- No seams or fakes required (pure static service logic).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Call `DashboardPermissionService.getPrimaryAction(...)` with unified delivered client inputs.
- [ ] (@Architect) Assert result equals `PrimaryActionType.reviewDelivery`.
- [ ] (@Architect) Optionally in same scenario, assert `calculatePermissions(...).canReview == true` to guard both decision layers.
- [ ] (@Sentinel) Review the test for deterministic execution, behavior-first assertions, and scope discipline.
- **Verify (@Sentinel):** `T19` remains one scenario and does not hide extra branch coverage requirements.

### How To Do It

- Use explicit enum values and avoid fixture objects to keep the test compact and expressive.
- Assert both primary action and permission flags if you want stronger coverage without adding extra test IDs.
- Keep the scenario strictly to client + unified delivered path; other statuses belong to other phases.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Protection for a critical dashboard workflow decision in client-delivery review flows.
- Immediate signal if unified permission/action precedence changes and breaks expected CTA behavior.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm whether this phase should assert only primary action or both primary action + `canReview` permission (recommended: both).
- Optional: confirm if you want to treat action precedence (`reviewDelivery` over generic actions) as explicit contract text in test comments.
- If you provide nothing, I will use the defaults/recommendations documented in Section A after blocking seam approvals are resolved.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T19` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard/dashboard_permission_service_test.dart`.
- Any helper/fake added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Unified delivered client path returns `reviewDelivery` and (if chosen) `canReview` remains true.
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## Phase 20: T20 - DashboardPermissionService unified pendingPayment (client) gives payEscrow primary action

> Primary: @Architect
> Supporting: @ThreatModeler, @Sentinel

### Goal

- Implement and stabilize `T20` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard/dashboard_permission_service_test.dart`.

### Why

- This locks the escrow payment CTA priority in the unified dashboard; incorrect action routing here directly impacts payment conversion and task progress.

### What We Need

- Test case target: `DashboardPermissionService unified pendingPayment (client) gives payEscrow primary action`.
- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard/dashboard_permission_service_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/services/dashboard_permission_service.dart`.
- Pure enum-based test inputs for client + unified pending payment state.
- Decision on whether to assert `canPayEscrow` permission alongside primary action (recommended: yes).
- Awareness of action precedence in `getPrimaryAction()` so the test verifies the intended branch explicitly.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Call `getPrimaryAction(...)` with client + unified pendingPayment inputs and assert `PrimaryActionType.payEscrow`.
- [ ] (@Architect) Optionally assert `calculatePermissions(...).canPayEscrow == true` in the same phase scope.
- [ ] (@Architect) Document in the test why this action must take precedence over generic actions.
- [ ] (@Sentinel) Review the test for deterministic execution, behavior-first assertions, and scope discipline.
- **Verify (@Sentinel):** `T20` remains one scenario and does not hide extra branch coverage requirements.

### How To Do It

- Use explicit enums and a small helper if needed to reduce repetition with T19 while keeping tests readable.
- Assert action precedence rather than only permission flags; the regression risk is the CTA selection, not just permission calculation.
- Keep status/value naming exact to current enum (`UnifiedWorkStatus.pendingPayment`) to catch accidental enum branch changes.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Stable coverage for the client escrow-payment CTA decision path in the dashboard.
- Fast detection if unified status mapping or action precedence refactors break payment-related actions.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm whether this phase should assert both `payEscrow` primary action and `canPayEscrow` permission (recommended: both).
- Optional: confirm if you want short inline comments in permission tests documenting action precedence intent (recommended: yes, concise).
- If you provide nothing, I will use the defaults/recommendations documented in Section A after blocking seam approvals are resolved.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T20` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard/dashboard_permission_service_test.dart`.
- Any helper/fake added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Client unified pendingPayment path returns `payEscrow` and (if chosen) `canPayEscrow` remains true.
- This phase is not complete until the test passes locally and reviewer confirms deterministic behavior.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- The previous `T11-T20` segment was still generic and did not expose slice-specific blockers (Task/Booking seams, PostgrestException setup, pagination contracts).
- It lacked `@PlanCritic` sections (gates, gaps, invariants, risks, pre-mortem, diff report).
- Per-phase guidance was not specific enough for booking pagination/guard/default-price/payment tests.
- It did not explicitly tell you what inputs/decisions to provide before implementation starts.

### 2) Added steps (bullet list)

- Added full `@PlanCritic` audit sections A-I for this slice.
- Added blocking seam decisions for TaskViewModel and BookingViewModel.
- Added booking-specific contract decisions (error assertion mode, pagination subcase policy, default price contract).
- Added risk register + pre-mortem tailored to booking pagination, error mapping, and payment state handling.
- Added per-phase `What Input You Should Provide Me` and `GATE CHECK` sections for all 10 tests.

### 3) Removed steps (if any)

- Removed generic repeated guidance that did not differentiate task, booking, and permission-service tests enough to be execution-safe.

### 4) Reordered steps (from → to)

- From: direct phase list only.
- To: audit + gate failures + corrected gate-based plan + 10 detailed one-test phases.

### 5) Expanded steps (what became more detailed)

- `T11-T13`: now specify offline TaskViewModel seam, pre-seeding strategy, and exact optimistic-update assertions.
- `T14-T18`: now specify BookingViewModel repo/chat seams, PostgrestException setup, pagination/guard assertions, default price capture, and payment failure state assertions.
- `T19-T20`: now specify action-precedence and optional permission-flag assertions in the same phase scope.

### 6) Why (short, practical)

- The original slice could still fail during implementation because the hardest dependencies (BookingViewModel seams and pagination contracts) were implicit. This version makes them explicit and actionable test-by-test.

### 7) Residual risks (what still remains risky even after fixes)

- `PostgrestException` construction may still be awkward depending on the `supabase_flutter` version; a helper may be needed.
- If business rules intentionally change (default price, error copy, page-size semantics), the tests will need explicit plan and assertion updates.
- Later slices may require additional seams; this document only hardens `T11-T20`.
