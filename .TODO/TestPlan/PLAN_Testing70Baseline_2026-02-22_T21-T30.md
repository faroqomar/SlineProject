# 📌 Plan Segment: 70-Test Baseline (T21-T30) — Re-improved with @PlanCritic

- Source master plan: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22.md`
- Segment file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22_T21-T30.md`
- Included phases/tests: `T21` to `T30` (DashboardPermissionService booking/task permissions + Task/Booking/Message model parsing/serialization)
- Audit method applied: `@PlanCritic` from `.agent/workflows/plan_critic.md`

## Purpose

- Turn the `T21-T30` slice into an execution-safe, gate-based mini-plan with explicit contract assumptions and no hidden fixture ambiguity.
- Make each test phase implementation-ready: what we need, what to do, how to do it, what to expect, and what input you should provide.
- Preserve strict scope: `1 phase = 1 test` and no production behavior changes.

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- This slice is fully unit-test only and should run offline (no Supabase init, no plugin calls, no widget harness).
- `T21-T22` are pure `DashboardPermissionService` enum logic tests and require no seams/fakes.
- `T23-T30` are parser/serializer/function tests and require fixture contracts, not dependency injection seams.
- `Task.fromJson` currently prefers joined relation fields (`profiles`, `categories.name`) over flat fallback fields (`user_name`, `user_avatar`, `category`).
- `BookingModel.fromJson` intentionally maps legacy/alternate DB status `in_progress` to `BookingStatus.active` and `paid_request_pending` to `BookingStatus.paidRequestPending`.
- In this slice, “receipts” for chat messages means `delivered_at` and `seen_at` timestamps parsed into `deliveredAt` / `seenAt`.

### Decision Needed (Blocking)

- Missing decision: **T23 joined-field precedence assertion scope**
  - Options:
  - Assert only that joined values parse when flat values are absent
  - Assert joined values parse and override conflicting flat fallback values in one test (recommended)
  - Keep test generic and avoid precedence assertions (not recommended; weak contract coverage)
  - Recommended: second option because precedence is the real regression risk in `Task.fromJson`.
  - Plan impact: affects fixture design and whether T23 truly protects join/fallback behavior.

- Missing decision: **T25 serializer assertion strictness (`Task.toJson(includeSystemFields: false)`)**
  - Options:
  - Key exclusion + selected key-presence assertions (recommended)
  - Full exact-map equality (strong but brittle)
  - Exclusion-only assertions (too weak)
  - Recommended: first option to lock the intent (`id`/`created_at` excluded) without over-coupling to unrelated serialization details.
  - Plan impact: determines maintenance cost and brittleness of T25.

- Missing decision: **T27 definition of “correctly”**
  - Options:
  - Map to `BookingStatus.paidRequestPending` only
  - Map to `BookingStatus.paidRequestPending` + parse success sanity (recommended)
  - Include downstream permission/action assertions (not recommended; wrong layer)
  - Recommended: second option to remove ambiguity while keeping the test model-focused.
  - Plan impact: prevents scope drift and reviewer disagreement.

- Missing decision: **T29 receipt timestamp assertion mode**
  - Options:
  - Exact `DateTime` equality using fixed ISO UTC strings (recommended)
  - Non-null only (too weak)
  - String passthrough assertions (wrong layer)
  - Recommended: exact `DateTime` equality because this is parser contract logic and easy to keep deterministic.
  - Plan impact: affects test strength and timezone-related flakiness risk.

### What Input You Should Provide Me (For This Slice)

- Approve `T23` precedence scope: joined values should override conflicting flat fallback values (recommended).
- Choose `T25` serializer assertion mode: key-exclusion + selected key-presence (recommended) vs full exact map.
- Confirm the definition of “correctly” for `T27` (recommended: enum mapping + parse success sanity).
- Choose `T29` timestamp assertion mode: exact parsed `DateTime` equality (recommended).
- Optional: confirm whether `T21/T22` should assert only target permission flags or also a few neighboring flags (recommended: include a few neighboring flags).
- Optional: confirm `T28` should also assert missing `payload` defaults to `{}` when omitted (recommended if kept concise).
- Optional: choose unknown string sample style for `T30` (completely unrelated token recommended).

## B) Gate Status (Pass/Fail)

### 1) Data/Contracts Gate

- Status: ❌ FAIL
- Reason: Parser/serializer tests (`T23-T30`) depend on fixture contract decisions that are still ambiguous (joined precedence, “correctly”, timestamp assertion mode, serializer strictness).
- Reason: Without explicit fixture standards, tests will either be weak or churn during review.
- What to add/fix to pass: lock the four blocking decisions in Section A and define reusable minimal fixtures per model file.

### 2) Security Gate

- Status: ⚠️ PARTIAL
- Reason: No RLS/auth/network behavior here, but `T21-T22` permission logic directly affects user action gating in dashboard flows.
- Reason: Model fallback tests (`T24`, `T28`, `T30`) also protect safe degradation on unknown/legacy values.
- What to add/fix to pass: keep permission tests explicit and ensure fallback assertions prove safe defaults rather than silent incorrect mappings.

### 3) Backend/API Gate

- Status: ✅ PASS
- Reason: This slice tests pure static logic and parsers/functions; no backend client construction or API seams are required.
- Reason: All dependencies are local enums, data classes, and JSON fixtures.
- What to add/fix to pass: maintain offline-only discipline and avoid introducing network-dependent fixtures.

### 4) UI/Integration Gate

- Status: ✅ PASS (N/A for slice)
- Reason: This slice is unit tests only (no widget or integration coverage).
- Reason: No UI harness or staging setup should be pulled into these phases.
- What to add/fix to pass: preserve strict unit-test scope.

### 5) Release/QA Gate

- Status: ❌ FAIL
- Reason: No slice-specific run command and review checklist is locked yet.
- Reason: Ambiguous assertion policies (`T25`, `T27`, `T29`) will cause inconsistent reviews.
- What to add/fix to pass: define run command + fixture standards + behavior-first review checklist before merge.

## C) Critical Gaps (Must-Fix)

- **Gap:** `T23` does not yet define joined-vs-flat precedence assertions
- **Why it will break:** The test may pass while the parser regresses to wrong precedence when both joined and flat values are present.
- **Fix (exact step(s) to add / reorder):** Lock a fixture with conflicting nested and flat values and assert nested values win.
- **Owner:** @APIContract / @Architect
- **Acceptance check:** `T23` explicitly proves `profiles` and `categories.name` are preferred over flat fallback values.

- **Gap:** `T25` serializer strictness is undefined
- **Why it will break:** Reviewers may disagree between weak exclusion-only assertions and brittle full-map snapshots.
- **Fix (exact step(s) to add / reorder):** Choose and document assertion mode (recommended: exclusion + selected key presence).
- **Owner:** @Architect / @Sentinel
- **Acceptance check:** `T25` uses one documented assertion style and reviewers enforce it consistently.

- **Gap:** `T27` title uses “correctly” without a precise contract
- **Why it will break:** The test can become vague, over-bundled, or under-specified.
- **Fix (exact step(s) to add / reorder):** Define “correctly” as enum mapping + parse success sanity in this slice.
- **Owner:** @APIContract / @Architect
- **Acceptance check:** `T27` assertions document and prove the intended mapping only.

- **Gap:** `T29` receipt timestamp assertion policy is not locked
- **Why it will break:** Timezone mismatches or weak non-null assertions can hide parser regressions.
- **Fix (exact step(s) to add / reorder):** Use fixed UTC strings and exact `DateTime` equality assertions.
- **Owner:** @APIContract / @Sentinel
- **Acceptance check:** `T29` asserts exact parsed `deliveredAt` and `seenAt` values from deterministic timestamps.

- **Gap:** No shared fixture strategy for task/booking/message parser tests
- **Why it will break:** Duplicated ad-hoc fixtures will drift and make failures harder to diagnose.
- **Fix (exact step(s) to add / reorder):** Create minimal fixture builders/helpers in each test file (or local helpers) with small overrides.
- **Owner:** @Architect
- **Acceptance check:** `task_model_test.dart`, `booking_model_test.dart`, and `message_model_test.dart` use reusable fixture helpers with explicit overrides.

- **Gap:** No slice-level review checklist for parser/permission tests
- **Why it will break:** Tests may over-assert unrelated fields or under-assert the actual contract.
- **Fix (exact step(s) to add / reorder):** Add and enforce a reviewer checklist covering fixture clarity, scope isolation, and exact fallback behavior.
- **Owner:** @Sentinel
- **Acceptance check:** All `T21-T30` tests pass checklist before merge.

## D) Invariants & Success Criteria (Non-Negotiable)

- **Invariant:** Freelancer booking permissions allow `canStart` for `BookingStatus.confirmed`
- **How to enforce:** Enforce with `T21` via `DashboardPermissionService.calculatePermissions(...)`.
- **How to verify:** `canStart == true` for freelancer + booking + confirmed.

- **Invariant:** Client task permissions allow `canApprove` for `TaskStatus.completed`
- **How to enforce:** Enforce with `T22` via `calculatePermissions(...)`.
- **How to verify:** `canApprove == true` for client + task + completed.

- **Invariant:** `Task.fromJson` maps `task_type: booking` and parses joined profile/category relation fields correctly
- **How to enforce:** Enforce with `T23` using nested `profiles` / `categories` fixture fields (and conflicting flat fallbacks if approved).
- **How to verify:** `taskType == TaskType.booking`, joined `userName`, `userAvatar`, and `categoryName` match expected values.

- **Invariant:** Unknown task status defaults safely to `TaskStatus.open`
- **How to enforce:** Enforce with `T24` using unknown `status` string.
- **How to verify:** Parser returns a `Task` and `status == TaskStatus.open`.

- **Invariant:** `Task.toJson(includeSystemFields: false)` excludes system-managed keys `id` and `created_at`
- **How to enforce:** Enforce with `T25` key-exclusion assertions.
- **How to verify:** Result map lacks `id` and `created_at` while preserving core payload fields.

- **Invariant:** `BookingModel.fromJson` maps legacy/alternate DB status `in_progress` to `BookingStatus.active`
- **How to enforce:** Enforce with `T26` using a minimal valid booking fixture.
- **How to verify:** Parsed `status == BookingStatus.active`.

- **Invariant:** `BookingModel.fromJson` maps `paid_request_pending` to `BookingStatus.paidRequestPending`
- **How to enforce:** Enforce with `T27` using a minimal valid booking fixture.
- **How to verify:** Parsed `status == BookingStatus.paidRequestPending`.

- **Invariant:** `Message.fromJson` defaults missing `message_type` to `MessageType.text`
- **How to enforce:** Enforce with `T28` fixture omitting `message_type`.
- **How to verify:** Parsed `messageType == MessageType.text` and parser succeeds.

- **Invariant:** `Message.fromJson` parses attachment metadata and read-receipt timestamps exactly
- **How to enforce:** Enforce with `T29` fixture containing attachment fields + `delivered_at` / `seen_at`.
- **How to verify:** Attachment fields and parsed timestamps match expected values.

- **Invariant:** `messageTypeFromString` returns `MessageType.text` for unknown values
- **How to enforce:** Enforce with `T30` pure function assertion using an unknown token.
- **How to verify:** Result enum equals `MessageType.text`.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| T23 fixture does not test joined-vs-flat precedence | T23 | Med | High | Feature | Test passes even after precedence regression | Use conflicting nested/flat values and assert nested wins | Strengthen T23 before merge |
| T25 becomes brittle due full-map equality | T25 | Med | Med | Local | Frequent failures after harmless serializer additions | Use exclusion + selected key assertions | Loosen assertions with documented rationale |
| T27 remains ambiguous (“correctly”) | T27 | High | Med | Feature | Reviewer disagreement / inconsistent assertions | Define contract in plan and test comments | Rework test before merge |
| Timezone-dependent receipt assertions | T29 | Med | Med | Feature | Fails on CI/local timezone mismatch | Use fixed UTC strings and exact parsed `DateTime` expectations | Normalize assertions to `.toUtc()` if needed |
| T28 duplicates T30 or vice versa | T28/T30 | Med | Low | Local | Redundant tests with overlapping assertions | Keep T28 = missing field fallback, T30 = unknown string fallback | Narrow one test scope during review |
| Permission tests assert too little | T21/T22 | Med | Med | Feature | Target flag passes while nearby permissions regress | Add small neighboring-flag assertions if approved | Add follow-up strengthening before merge |
| Parser fixtures drift from real model requirements | T23-T29 | Med | High | Feature | Tests fail due invalid fixtures, not code regressions | Shared fixture helpers + minimal valid base payloads | Rebuild fixture helpers and revalidate test intent |
| Over-bundling multiple parser branches in one phase | T23-T29 | Med | Med | Local | Large tests hard to debug and maintain | Enforce one-phase-one-contract rule | Split local subcases only when scoped and documented |
| Misunderstanding “receipts” as payload receipts rather than timestamps | T29 | Low | Med | Feature | Wrong fields asserted; real regression missed | Define receipts explicitly as delivered/seen timestamps | Update plan and test comment to clarify |

## F) Pre-Mortem (How this fails in real life)

- This fails when `T23` only tests happy-path joined fields and never proves nested values override flat fallbacks.
- This fails when `T25` uses full-map equality and starts failing every time unrelated serializer keys are added or reordered.
- This fails when `T27` says “correctly” but the test only checks `no throw`, so payment-related status regressions slip through.
- This fails when `T29` uses local-time timestamp strings and CI parses them differently than local development.
- This fails when `T28` and `T30` duplicate the same fallback assertion and leave attachment/receipt parsing under-tested.
- This fails when parser fixtures are copied repeatedly and one test silently becomes invalid due missing required fields.
- This fails when permission tests assert only positive flags and miss a branch regression that flips unrelated permissions to true.
- This fails when reviewers allow broad parser assertions that accidentally couple tests to unrelated fields and create noisy failures.

## G) Plan Fixes (Concrete Additions / Expansions)

- **Goal:** Lock parser contract decisions for `T23`, `T25`, `T27`, and `T29`
- **Why:** These are the main ambiguity points that would make the slice weak or brittle.
- **How:** Approve the blocking decisions in Section A before implementation and document them in test comments where useful.
- **Output artifact:** Updated plan approvals + consistent test assertion styles
- **Stop condition:** Each ambiguous phase has explicit assertion scope and fixture policy.

- **Goal:** Create reusable minimal fixture builders for task/booking/message model tests
- **Why:** Repeated ad-hoc fixtures will drift and slow debugging.
- **How:** Add local helper functions per test file (base fixture + override map) and keep them small and explicit.
- **Output artifact:** Fixture helper functions in `task_model_test.dart`, `booking_model_test.dart`, `message_model_test.dart`
- **Stop condition:** `T23-T29` reuse fixtures/helpers with clear overrides and deterministic values.

- **Goal:** Keep permission tests (`T21-T22`) small but meaningful
- **Why:** Pure enum tests can become too weak or too broad very easily.
- **How:** Assert target permission plus a small set of neighboring flags if approved, without mixing in primary-action assertions.
- **Output artifact:** `dashboard_permission_service_test.dart` cases for `T21-T22`
- **Stop condition:** Tests remain compact, deterministic, and clearly scoped to permission flags.

- **Goal:** Clarify fallback boundary between `T28` and `T30`
- **Why:** Both test text defaults in chat mapping and can accidentally overlap.
- **How:** Define `T28` as missing-field fallback and `T30` as unknown-string function fallback only.
- **Output artifact:** Distinct assertions/comments in `message_model_test.dart`
- **Stop condition:** Reviewers can explain the difference between T28 and T30 in one sentence.

- **Goal:** Add per-phase user input requirements and gate checks
- **Why:** This prevents hidden decisions from surfacing mid-implementation.
- **How:** Include explicit inputs + `GATE CHECK` in every phase below.
- **Output artifact:** Per-phase plan content
- **Stop condition:** Implementer can start any phase with no hidden assumption work.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Slice Dependency Order (T21-T30)

1. Data/Contracts: lock parser fixture/precedence/assertion policies for `T23-T30`.
2. Security-sensitive logic: permission gating checks in `T21-T22` and safe parser fallbacks in `T24`, `T28`, `T30`.
3. Backend/App logic unit tests: model parsing/serialization and pure mapping functions (`T23-T30`).
4. UI/Integration: not applicable for this slice (unit tests only).
5. QA/Release: grouped local run + review checklist signoff before moving to `T31-T40`.

### Shared Implementation Rules (Applies to T21-T30)

- [ ] (@Architect) No production behavior changes; implement tests only for this slice.
- [ ] (@Sentinel) All tests run offline and deterministically; no Supabase init, plugins, or widget harness setup.
- [ ] (@APIContract) Use minimal valid fixtures with explicit overrides; avoid copy-pasted ad-hoc payloads.
- [ ] (@Sentinel) Keep one-phase-one-contract scope; local subcases only when explicitly justified.
- [ ] (@ThreatModeler) Permission tests must remain explicit about role/type/status inputs to avoid hidden branch assumptions.

### Slice QA/Release Gate (Before Marking T21-T30 Complete)

- [ ] (@Sentinel) `flutter test /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models` passes for `T21-T30`.
- [ ] (@Sentinel) All blocking decisions in Section A are resolved and reflected in assertions/comments.
- [ ] (@Sentinel) Review checklist passes: no hidden network, no over-bundled scenarios, parser fixtures are minimal and explicit.
- **GATE CHECK:** `T21-T30` is stable and merge-ready before starting `T31-T40`.

## Phase 21: T21 - DashboardPermissionService booking confirmed (freelancer) allows canStart

> Primary: @Architect
> Supporting: @ThreatModeler, @Sentinel

### Goal

- Implement and stabilize `T21` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard/dashboard_permission_service_test.dart`.

### Why

- This locks a freelancer booking workflow permission rule. If `canStart` regresses for confirmed bookings, the dashboard action flow breaks even if data is correct.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard/dashboard_permission_service_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/services/dashboard_permission_service.dart`.
- Test case target: `DashboardPermissionService booking confirmed (freelancer) allows canStart`.
- Pure enum inputs for `UserRole.freelancer`, `WorkItemType.booking`, and `BookingStatus.confirmed`.
- Clear assertion scope choice: target flag only vs target flag + related flags (`canComplete`, `canCancel`, `canReschedule`) for sanity coverage.
- No seams, no fakes, and no backend setup (pure static logic).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Call `DashboardPermissionService.calculatePermissions(...)` with freelancer + booking + confirmed inputs.
- [ ] (@Architect) Assert `canStart == true` (primary contract for this phase).
- [ ] (@Architect) Optionally assert a small set of related flags to prevent accidental broad permission regressions without widening scope too much.
- [ ] (@Sentinel) Review the test for behavior-first assertions and one-scenario scope discipline.
- **Verify (@Sentinel):** `T21` remains one scenario and does not hide extra branch coverage requirements.

### How To Do It

- Use explicit enum literals in the test body (no fixture objects needed).
- Prefer direct field assertions on `WorkItemPermissions` over indirect UI action assertions for this phase title.
- If you assert additional flags, keep them tightly related to the same confirmed-freelancer booking state.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Fast protection for a core booking workflow permission contract with zero infrastructure cost.
- Immediate regression signal if permission logic changes for freelancer-confirmed bookings during dashboard refactors.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.


### What Input You Should Provide Me

- Confirm assertion scope: `canStart` only vs `canStart` + a few related flags (recommended: include `canStart` plus 1-2 related flags).
- Optional: confirm whether you want to assert `getPrimaryAction(...) == PrimaryActionType.startWork` in this phase (recommended: no, keep T21 permission-focused).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T21` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard/dashboard_permission_service_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Freelancer + booking + confirmed path returns `canStart == true` offline with deterministic enum-only inputs.
- This phase is not complete until the test passes locally and reviewer confirms one-scenario scope.

---

## Phase 22: T22 - DashboardPermissionService task completed (client) allows canApprove

> Primary: @Architect
> Supporting: @ThreatModeler, @Sentinel

### Goal

- Implement and stabilize `T22` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard/dashboard_permission_service_test.dart`.

### Why

- This protects the client approval permission on completed tasks. If it regresses, users can get stuck at the end of the task lifecycle.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard/dashboard_permission_service_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/services/dashboard_permission_service.dart`.
- Test case target: `DashboardPermissionService task completed (client) allows canApprove`.
- Pure enum inputs for `UserRole.client`, `WorkItemType.task`, and `TaskStatus.completed`.
- Decision on assertion scope: target flag only vs target flag + neighboring flags (`canCancel`, `canStart`) to prevent broad regressions.
- No seams, no fakes, and no backend setup (pure static logic).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Call `calculatePermissions(...)` with client + task + completed inputs.
- [ ] (@Architect) Assert `canApprove == true` (primary contract for this phase).
- [ ] (@Architect) Optionally assert selected neighboring flags remain false for completed client tasks.
- [ ] (@Sentinel) Review the test for behavior-first assertions and one-scenario scope discipline.
- **Verify (@Sentinel):** `T22` remains one scenario and does not hide extra branch coverage requirements.

### How To Do It

- Use direct enum literals and assert the returned `WorkItemPermissions` fields.
- Keep the test focused on task permissions, not unified or booking branches.
- Avoid duplicating T19/T20 primary-action coverage unless explicitly approved.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Stable coverage for a critical end-of-task permission rule on the client side.
- Fast detection if permission branching changes and blocks client approval actions.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.


### What Input You Should Provide Me

- Confirm assertion scope: `canApprove` only vs `canApprove` + a few related flags (recommended: include `canApprove` plus selected negatives).
- Optional: confirm whether to keep this phase strictly permission-only (recommended) and not assert primary action here.
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T22` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/dashboard/dashboard_permission_service_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Client + task + completed path returns `canApprove == true` with deterministic enum-only inputs.
- This phase is not complete until the test passes locally and reviewer confirms one-scenario scope.

---

## Phase 23: T23 - Task.fromJson parses booking type and joined profile/category fields

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T23` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_model_test.dart`.

### Why

- This parser path is contract-heavy and easy to break because it mixes task type mapping, joined `profiles` fields, and joined `categories(name)` fallback logic.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_model.dart`.
- Test case target: `Task.fromJson parses booking type and joined profile/category fields`.
- A fixture JSON payload that includes `task_type: booking`, nested `profiles(full_name, avatar_url)`, and nested `categories(name)` plus optional flat fallback fields to test precedence explicitly.
- Decision on precedence assertion scope: nested joined values only vs nested-overrides-flat in one test (recommended: nested-overrides-flat to lock the real contract).
- Awareness that `Task.fromJson` also parses `image_paths`, `assigned_freelancer_id`, `offers`, and category fallback; keep assertions scoped but strong.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Build one minimal-but-complete JSON fixture with booking task type and joined profile/category data.
- [ ] (@Architect) Call `Task.fromJson(fixture)` and assert `taskType == TaskType.booking`.
- [ ] (@Architect) Assert `userName`/`userAvatar` come from nested `profiles` values and `categoryName` comes from nested `categories.name`.
- [ ] (@Architect) Optionally include conflicting flat fields (`user_name`, `user_avatar`, `category`) to prove nested precedence if approved.
- [ ] (@Sentinel) Review the test for contract-focused assertions and one-scenario scope discipline.
- **Verify (@Sentinel):** `T23` remains one scenario and does not hide unrelated parser coverage.

### How To Do It

- Use a single fixture map with explicit strings that make precedence obvious (for example nested and flat values differ).
- Assert only fields named in the test title plus any minimal supporting fields needed to prove parser success.
- Do not bundle unknown-status fallback or `toJson` behavior into this phase (covered by T24/T25).
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Strong parser-contract coverage for joined Supabase payload shapes used by task list/detail queries.
- Early detection of regressions in nested relation parsing or task type mapping before they surface in UI screens.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.


### What Input You Should Provide Me

- Confirm whether to assert nested-joined values override conflicting flat fallback fields in this same test (recommended: yes).
- Optional: provide exact fixture strings for nested vs flat names/categories if you want product-specific wording in test data.
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T23` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Task fixture proves `task_type: booking` parsing and joined profile/category extraction deterministically offline.
- This phase is not complete until the test passes locally and reviewer confirms parser-contract scope is tight.

---

## Phase 24: T24 - Task.fromJson unknown status defaults to TaskStatus.open

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T24` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_model_test.dart`.

### Why

- Unknown status fallback is backward-compatibility protection. If it regresses, parser failures or bad enum mapping can break task surfaces on unexpected DB values.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_model.dart`.
- Test case target: `Task.fromJson unknown status defaults to TaskStatus.open`.
- A valid minimal `Task.fromJson` fixture with an intentionally unknown `status` string and otherwise parseable required fields.
- Decision on assertion scope: status fallback only vs status fallback + no-throw parser behavior (recommended: include both).
- Consistency with `TaskStatus.values.firstWhere(... orElse: TaskStatus.open)` current implementation contract.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Create a minimal valid task JSON fixture and set `status` to an unknown value (e.g., `legacy_unknown_status`).
- [ ] (@Architect) Call `Task.fromJson` and assert it returns a Task with `status == TaskStatus.open`.
- [ ] (@Architect) Assert parser succeeds (no throw) and required fields remain parsed correctly enough to prove this is a fallback path, not a broken fixture.
- [ ] (@Sentinel) Review the test for behavior-first fallback assertions and one-scenario scope discipline.
- **Verify (@Sentinel):** `T24` remains one scenario and does not hide unrelated parser coverage.

### How To Do It

- Start from the T23 fixture and simplify to a minimal parser-valid map, then replace only the `status` field.
- Assert the fallback enum explicitly and avoid over-asserting unrelated fields.
- Keep unknown `task_type` or missing fields out of scope for this phase.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Reliable coverage for parser resilience on unrecognized task statuses.
- Fast detection if enum mapping/fallback behavior changes and starts throwing or defaulting to a different status.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.


### What Input You Should Provide Me

- Confirm assertion scope: status fallback only vs status fallback + no-throw parse proof (recommended: include both).
- Optional: confirm the unknown status sample string you want used in tests (recommended: a clearly fake value like `legacy_unknown_status`).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T24` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Unknown task status maps to `TaskStatus.open` without breaking parser success for a valid fixture.
- This phase is not complete until the test passes locally and reviewer confirms fallback scope is isolated.

---

## Phase 25: T25 - Task.toJson(includeSystemFields: false) excludes id and created_at

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T25` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_model_test.dart`.

### Why

- This protects write-payload hygiene. Accidentally serializing system fields into insert/update payloads can cause DB errors or hidden data-contract issues.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_model.dart`.
- Test case target: `Task.toJson(includeSystemFields: false) excludes id and created_at`.
- A fully constructed `Task` instance with known `id` and `createdAt` values plus enough business fields to ensure serialization still produces a useful payload.
- Decision on assertion mode: key-exclusion focused vs full exact-map assertion (recommended: key-exclusion + selected critical keys to reduce brittleness).
- Awareness that `toJson` includes nullable keys like `category_id` and conditionally includes `category` / `assigned_freelancer_id`.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Construct a `Task` object with explicit system fields and non-system payload fields.
- [ ] (@Architect) Call `toJson(includeSystemFields: false)` and assert `id` and `created_at` keys are absent.
- [ ] (@Architect) Assert selected critical keys remain present (for example `title`, `user_id`, `status`, `task_type`) to prove serialization still works.
- [ ] (@Sentinel) Review the test for payload-contract assertions and one-scenario scope discipline.
- **Verify (@Sentinel):** `T25` remains one scenario and does not hide `includeSystemFields: true` coverage.

### How To Do It

- Prefer explicit `contains` / `isNot(contains())` key assertions instead of full-map equality unless you intentionally want a strict contract lock.
- Use a single task instance with non-null optional fields only if they help validate conditional key behavior without widening scope.
- Do not test `includeSystemFields: true` in this phase; keep it strictly the exclusion path.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Protection against accidental inclusion of system-managed fields in create/update payloads.
- Fast regression signal if serializer changes start leaking DB-managed keys into writes.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.


### What Input You Should Provide Me

- Choose assertion mode: key-exclusion + selected key-presence checks (recommended) vs full exact-map snapshot-style assertion.
- Optional: confirm whether you want to include non-null `category` / `assignedFreelancerId` in the fixture to also validate conditional key inclusion (recommended: only if kept concise).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T25` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- `toJson(includeSystemFields: false)` excludes `id` and `created_at` while preserving core payload keys.
- This phase is not complete until the test passes locally and reviewer confirms payload-scope assertions are not brittle.

---

## Phase 26: T26 - BookingModel.fromJson maps in_progress to BookingStatus.active

> Primary: @Architect
> Supporting: @APIContract, @Sentinel, @ThreatModeler

### Goal

- Implement and stabilize `T26` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/booking_model_test.dart`.

### Why

- This locks a legacy/alternate DB status mapping (`in_progress`) that directly affects booking workflow state and UI behavior.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/booking_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/models/booking_model.dart`.
- Test case target: `BookingModel.fromJson maps in_progress to BookingStatus.active`.
- A minimal valid booking fixture with `status: in_progress` and required fields (`id`, `provider_id`, `client_id`, `created_at`, etc.).
- Decision on assertion scope: enum mapping only vs enum mapping + parse sanity for timestamps/IDs (recommended: enum mapping + minimal parse sanity).
- Awareness that `slot_id` null fallback and payment status defaults exist, but they are not the main scope of this phase.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Build a minimal booking JSON fixture with `status: in_progress` and parseable required fields.
- [ ] (@Architect) Call `BookingModel.fromJson` and assert `status == BookingStatus.active`.
- [ ] (@Architect) Assert parse succeeded and basic identifiers/timestamps remain valid to show fixture is realistic.
- [ ] (@Sentinel) Review the test for mapping-focused assertions and one-scenario scope discipline.
- **Verify (@Sentinel):** `T26` remains one scenario and does not hide unrelated booking parser coverage.

### How To Do It

- Use a fixture with explicit UTC timestamps (`...Z`) to avoid timezone confusion in unrelated assertions.
- Keep assertions centered on status mapping; add only minimal sanity checks for parse success.
- Do not combine `paid_request_pending` mapping into this phase (covered by T27).
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Reliable coverage for a legacy status alias used in booking data migration/backward compatibility paths.
- Early detection if booking status mapping refactors drop or alter the `in_progress` alias.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.


### What Input You Should Provide Me

- Confirm assertion scope: status mapping only vs status mapping + minimal parse sanity (recommended: include minimal parse sanity).
- Optional: confirm whether to include `availability_slots.starts_at` in this fixture (recommended: no, keep T26 focused on status mapping).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T26` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/booking_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Booking fixture with `status: in_progress` deterministically maps to `BookingStatus.active` offline.
- This phase is not complete until the test passes locally and reviewer confirms mapping scope is isolated.

---

## Phase 27: T27 - BookingModel.fromJson maps paid_request_pending correctly

> Primary: @Architect
> Supporting: @APIContract, @Sentinel, @ThreatModeler

### Goal

- Implement and stabilize `T27` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/booking_model_test.dart`.

### Why

- This status mapping feeds payment/escrow workflows. Ambiguity in “correctly” must be resolved or the test will be weak and unstable.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/booking_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/models/booking_model.dart`.
- Test case target: `BookingModel.fromJson maps paid_request_pending correctly`.
- A minimal valid booking fixture with `status: paid_request_pending` and required parseable fields.
- Explicit definition of “correctly” for this phase (recommended: maps to `BookingStatus.paidRequestPending` and parses successfully).
- Awareness that downstream dashboard permission/action behavior is tested elsewhere; keep this phase model-mapping focused.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Build a minimal booking JSON fixture with `status: paid_request_pending`.
- [ ] (@Architect) Call `BookingModel.fromJson` and assert `status == BookingStatus.paidRequestPending`.
- [ ] (@Architect) Assert parse succeeds with realistic required fields and no unexpected fallback to another status.
- [ ] (@Sentinel) Review the test for precise definition of “correctly” and one-scenario scope discipline.
- **Verify (@Sentinel):** `T27` remains one scenario and does not hide downstream permission/action assertions.

### How To Do It

- Document “correctly” in a short test comment or plan note so reviewers enforce the same contract.
- Use direct enum assertion and avoid coupling this phase to permission-service expectations.
- Keep fixture minimal and deterministic, reusing the T26 helper with only the status changed if convenient.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Clear model-level protection for a payment-related booking status string that appears in DB payloads.
- Reduced ambiguity in future maintenance because the expected enum mapping is explicitly defined.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.


### What Input You Should Provide Me

- Confirm the definition of “correctly” for this phase (recommended: `BookingStatus.paidRequestPending` + parse success only).
- Optional: confirm whether to reuse the same fixture builder as T26 with status override (recommended: yes).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T27` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/booking_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- `paid_request_pending` maps to `BookingStatus.paidRequestPending` with an unambiguous model-level assertion.
- This phase is not complete until the test passes locally and reviewer confirms “correctly” is defined in assertions/comments.

---

## Phase 28: T28 - Message.fromJson defaults missing message_type to text

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T28` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/message_model_test.dart`.

### Why

- Chat payloads can arrive without `message_type` during migration or legacy writes. This default protects rendering and message handling from crashes.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/message_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/models/message_model.dart`.
- Test case target: `Message.fromJson defaults missing message_type to text`.
- A minimal valid message JSON fixture that intentionally omits `message_type` while keeping required fields parseable.
- Decision on assertion scope: messageType fallback only vs fallback + payload/content defaults (recommended: include payload default `{}` if missing too only when kept concise).
- Awareness that parser wraps errors with logging and rethrows; this phase should stay on the success-fallback path.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Build a valid message JSON fixture without `message_type`.
- [ ] (@Architect) Call `Message.fromJson` and assert `messageType == MessageType.text`.
- [ ] (@Architect) Optionally assert parser still succeeds with expected content/payload defaults if included in fixture scope.
- [ ] (@Sentinel) Review the test for fallback-focused assertions and one-scenario scope discipline.
- **Verify (@Sentinel):** `T28` remains one scenario and does not hide attachment/receipt parsing coverage.

### How To Do It

- Use a minimal fixture and omit only `message_type` to isolate the fallback condition.
- Prefer exact enum assertion; avoid broad map snapshots.
- Do not bundle unknown-string fallback here (covered by T30).
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Protection for chat parser compatibility when older or partial payloads omit `message_type`.
- Fast signal if parser changes start requiring `message_type` and breaking legacy messages.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.


### What Input You Should Provide Me

- Confirm assertion scope: `messageType == text` only vs include payload default `{}` / content fallback checks (recommended: include one small supporting assertion only).
- Optional: confirm whether the fixture should omit `payload` too to validate default `{}` in the same scenario (recommended: yes, if kept concise).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T28` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/message_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Message parser handles missing `message_type` by defaulting to `MessageType.text` without throwing.
- This phase is not complete until the test passes locally and reviewer confirms fallback scope is isolated.

---

## Phase 29: T29 - Message.fromJson parses attachments and receipts

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T29` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/message_model_test.dart`.

### Why

- Attachment and read-receipt parsing is directly user-visible in chat UI. If these fields parse incorrectly, rendering and delivery/read states break silently.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/message_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/models/message_model.dart`.
- Test case target: `Message.fromJson parses attachments and receipts`.
- A message JSON fixture including `attachment_url`, `attachment_type`, `attachment_name`, `attachment_size`, `delivered_at`, and `seen_at`.
- Clarified definition of “receipts” for this phase (recommended: delivered and seen timestamps only).
- Decision on timestamp assertion style: exact `DateTime.parse(...)` equality vs looser non-null checks (recommended: exact equality with fixed UTC strings).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Build one message fixture with attachment metadata and both receipt timestamps.
- [ ] (@Architect) Call `Message.fromJson` and assert all attachment fields parse exactly.
- [ ] (@Architect) Assert `deliveredAt` and `seenAt` parse to expected `DateTime` values (use fixed strings for determinism).
- [ ] (@Sentinel) Review the test for parser-contract assertions and one-scenario scope discipline.
- **Verify (@Sentinel):** `T29` remains one scenario and does not hide message-type fallback coverage.

### How To Do It

- Use UTC ISO strings (`...Z`) for `delivered_at` and `seen_at` to avoid timezone-dependent assertions.
- Assert the integer conversion for `attachment_size` if fixture uses numeric input, because parser casts via `(num).toInt()`.
- Keep message type/path simple (e.g., `text`) so the phase stays focused on attachments + receipts parsing.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Strong coverage for chat attachment metadata and read-receipt parsing used by message UI rendering.
- Early detection if parser field names or timestamp parsing logic drift from payload contracts.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.


### What Input You Should Provide Me

- Confirm “receipts” scope = `delivered_at` + `seen_at` only (recommended).
- Choose timestamp assertion mode: exact parsed `DateTime` equality (recommended) vs non-null only (not recommended).
- Optional: provide example attachment metadata values you prefer in fixtures (filename/type/size).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T29` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/message_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Attachment fields and receipt timestamps parse exactly from one deterministic message fixture offline.
- This phase is not complete until the test passes locally and reviewer confirms attachment/receipt scope is isolated.

---

## Phase 30: T30 - messageTypeFromString unknown value returns MessageType.text

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T30` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/message_model_test.dart`.

### Why

- This tiny function is a high-leverage fallback. If unknown types stop defaulting to `text`, chat rendering can break on new/unsupported message types.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/message_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/models/message_model.dart`.
- Test case target: `messageTypeFromString unknown value returns MessageType.text`.
- A clearly unknown input string (for example `futureExperimentalType`) that cannot match any current switch case.
- Decision on case-sensitivity expectation: treat `TEXT` as unknown (current code is case-sensitive) vs use a completely unrelated string (recommended).
- No fixtures, no seams, and no backend setup (pure function test).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Call `messageTypeFromString` with an unknown string value.
- [ ] (@Architect) Assert the result is `MessageType.text`.
- [ ] (@Architect) Document (briefly) that this test locks the default branch for forward compatibility with new message types.
- [ ] (@Sentinel) Review the test for one-function, one-scenario scope discipline.
- **Verify (@Sentinel):** `T30` remains one scenario and does not duplicate T28 missing-field fallback coverage.

### How To Do It

- Use one explicit unknown string and a direct enum assertion.
- Avoid mixing recognized-value assertions into this phase; recognized mappings can be covered separately if ever needed.
- If using an uppercase known token (e.g., `TEXT`), document that the function is case-sensitive; otherwise prefer a clearly unrelated token.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Cheap but valuable regression protection for unknown message-type forward compatibility.
- Fast signal if switch-case defaults change and unsupported types stop degrading safely to text.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.


### What Input You Should Provide Me

- Choose unknown-string sample: completely unrelated token (recommended) vs uppercase known token to also imply case-sensitivity behavior.
- Optional: confirm whether you want a short inline comment documenting forward-compat fallback intent (recommended: yes, concise).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T30` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/message_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Unknown message type string deterministically returns `MessageType.text` with a pure function assertion.
- This phase is not complete until the test passes locally and reviewer confirms no overlap with T28.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- The previous `T21-T30` segment was still generic and did not include `@PlanCritic` gating, risks, or slice-specific parser contract decisions.
- It lacked explicit fixture/precedence/assertion policies for model parser tests (`T23-T30`).
- Per-phase guidance did not state what inputs you should provide before implementation.
- It treated pure permission and parser tests as if they needed the same generic seam/fake workflow, which is misleading for this slice.

### 2) Added steps (bullet list)

- Added full `@PlanCritic` audit sections `A-I` for this slice.
- Added blocking decisions for `T23` precedence, `T25` serializer strictness, `T27` “correctly” definition, and `T29` timestamp assertion mode.
- Added slice-specific invariants and risks for permission flags, parser fallbacks, serializer exclusions, and timestamp parsing.
- Added per-phase `What Input You Should Provide Me` and `GATE CHECK` sections for all 10 tests.
- Added explicit fixture strategy guidance for `task_model_test.dart`, `booking_model_test.dart`, and `message_model_test.dart`.

### 3) Removed steps (if any)

- Removed generic placeholder seam/fake wording where this slice uses pure static/model parser logic and does not need DI seams.

### 4) Reordered steps (from → to)

- From: direct phase list only.
- To: audit + gate failures + corrected gate-based plan + 10 detailed one-test phases.

### 5) Expanded steps (what became more detailed)

- `T21-T22`: now specify permission-flag scope decisions and enum-only test inputs.
- `T23-T25`: now specify joined/flat precedence, unknown-status fallback, and serializer key-exclusion assertion strategy.
- `T26-T27`: now define booking status mapping contracts and remove ambiguity around “correctly”.
- `T28-T30`: now separate missing-field fallback, attachment/receipt parsing, and unknown-string mapping into distinct scopes.

### 6) Why (short, practical)

- The original slice could produce weak or brittle tests because the parser/serializer contracts were implied instead of locked. This version makes the exact assertions and inputs explicit before implementation starts.

### 7) Residual risks (what still remains risky even after fixes)

- If model field contracts change intentionally (new serializer keys, renamed payload fields, enum changes), this plan requires explicit test updates and decision re-validation.
- Parser tests can still become noisy if fixtures grow too large; keep them minimal and focused.
- Later slices may introduce new seam/dependency blockers; this document only hardens `T21-T30`.

