# 📌 Plan Segment: 70-Test Baseline (T31-T40) — Re-improved with @PlanCritic

- Source master plan: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22.md`
- Segment file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/TestPlan/PLAN_Testing70Baseline_2026-02-22_T31-T40.md`
- Included phases/tests: `T31` to `T40` (TaskRequest model parsing/serialization + Unified/WorkItem models + ErrorMapper + SignedUrlCache)
- Audit method applied: `@PlanCritic` from `.agent/workflows/plan_critic.md`

## Purpose

- Turn the `T31-T40` slice into an execution-safe, gate-based mini-plan with explicit parser/utility contracts and no hidden fixture ambiguity.
- Make each test phase implementation-ready: what we need, what to do, how to do it, what to expect, and what input you should provide.
- Preserve strict scope: `1 phase = 1 test` and no production behavior changes.

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- This slice is fully unit-test only and should run offline (no Supabase init, no widgets, no plugins, no network).
- `T31-T35` are pure model parser/serializer tests driven by local fixtures and enums.
- `T36-T39` are pure utility tests for `ErrorMapper` and require package exception objects only (no live Supabase calls).
- `T40` is a pure in-memory cache test and must isolate static cache state via `SignedUrlCache.clear()`.
- `TaskRequest.fromMap` currently resolves `bidderId` from `freelancer_id` first, then `bidder_id`, then empty string if both are missing.
- `UnifiedWorkItemModel.fromJson` currently maps `paid_request_pending` to `UnifiedWorkStatus.requestPending` for compatibility.
- `ErrorMapper` currently returns user-facing strings and `isSessionExpired(...)` detects `jwt expired` by substring match on `AuthException.message`.

### Decision Needed (Blocking)

- Missing decision: **T32 definition of “falls back safely”**
  - Options:
  - `no throw` only
  - `no throw` + empty-string `bidderId` (recommended; matches current code contract)
  - Allow `null`/empty interchangeably (not recommended; ambiguous)
  - Recommended: second option to lock the actual fallback behavior and prevent silent contract drift.
  - Plan impact: determines whether T32 is strong or vague.

- Missing decision: **T33 insert serializer assertion scope**
  - Options:
  - Key absence/presence assertions (recommended)
  - Full exact-map equality (strong but brittle)
  - Exclusion-only checks (too weak)
  - Recommended: key absence + required key presence to protect contract without over-coupling.
  - Plan impact: affects test brittleness and review churn.

- Missing decision: **T35 roundtrip strictness**
  - Options:
  - Focus on `permissions` + sort fields + a few sanity fields (recommended)
  - Full field-by-field roundtrip across all `WorkItem` fields (heavier, higher maintenance)
  - Permissions-only (too weak for cache sort behavior)
  - Recommended: first option to match the test title and preserve signal quality.
  - Plan impact: defines assertion volume and maintenance cost.

- Missing decision: **ErrorMapper string assertion policy for T36-T38**
  - Options:
  - Exact strings (recommended if UX copy is stable)
  - Semantic contains/regex (recommended if copy changes often)
  - Non-null only (not recommended)
  - Recommended: one consistent policy across all ErrorMapper string tests in this slice.
  - Plan impact: affects brittleness and consistency across T36-T38.

- Missing decision: **Exception construction strategy for T36-T39**
  - Options:
  - Direct constructors inline in each test
  - Shared helper/factory in `error_mapper_test.dart` (recommended)
  - Runtime mocking of Supabase clients (not recommended; wrong layer)
  - Recommended: shared helper because constructor signatures can vary by package version and this reduces repeated brittle code.
  - Plan impact: affects implementation speed and compatibility with pinned Supabase package versions.

### What Input You Should Provide Me (For This Slice)

- Confirm T32 “safe fallback” = no throw + empty-string `bidderId` (recommended).
- Choose T33 serializer assertion mode: key absence/presence (recommended) vs full exact map.
- Choose T35 roundtrip strictness: permissions+sort focus (recommended) vs broad field-by-field roundtrip.
- Choose ErrorMapper string assertion policy for T36-T38: exact vs semantic contains.
- Approve shared exception helper strategy for `PostgrestException`, `AuthException`, and `StorageException` in `error_mapper_test.dart` (recommended).
- Optional: confirm whether T33 should include a blank-note omission subcase (recommended only if kept concise).
- Optional: confirm whether T40 should also assert `SignedUrlCache.size == 1` (recommended: yes).

## B) Gate Status (Pass/Fail)

### 1) Data/Contracts Gate

- Status: ❌ FAIL
- Reason: Parser/serializer tests (`T31-T35`) still have ambiguous contract boundaries (`T32` safe fallback, `T33` system-field scope, `T35` roundtrip strictness).
- Reason: ErrorMapper tests (`T36-T39`) need a version-compatible exception construction strategy before implementation can proceed cleanly.
- What to add/fix to pass: lock the blocking decisions in Section A and define minimal reusable fixtures/helpers per test file.

### 2) Security Gate

- Status: ⚠️ PARTIAL
- Reason: No RLS/network behavior in this slice, but `ErrorMapper` and `isSessionExpired(...)` are security-sensitive UX paths that must not leak technical details or miss re-auth triggers.
- Reason: `T31-T35` parser tests also protect compatibility paths that affect authorization-sensitive dashboard actions indirectly (status/action routing).
- What to add/fix to pass: make ErrorMapper assertions explicit about user-facing mapping and boolean detection, not raw technical messages.

### 3) Backend/API Gate

- Status: ✅ PASS
- Reason: All tests in this slice are pure models/utilities and can run without backend client initialization or DI seams.
- Reason: Supabase exception types are required only as local value objects for ErrorMapper tests.
- What to add/fix to pass: maintain offline-only scope and avoid introducing fake clients or network setup.

### 4) UI/Integration Gate

- Status: ✅ PASS (N/A for slice)
- Reason: This slice is unit tests only.
- Reason: No widget harness or staging integration setup belongs here.
- What to add/fix to pass: preserve strict unit-test scope.

### 5) Release/QA Gate

- Status: ❌ FAIL
- Reason: No slice-specific run command/review checklist is locked yet.
- Reason: Static cache global-state isolation (`T40`) and ErrorMapper assertion policy can cause flaky/inconsistent reviews if not standardized.
- What to add/fix to pass: define grouped run command, cache isolation rule, and ErrorMapper assertion policy before merge.

## C) Critical Gaps (Must-Fix)

- **Gap:** T32 does not define the exact fallback output when bidder IDs are missing
- **Why it will break:** The test can pass on a weaker contract (`no throw`) while parser output drifts from the current empty-string fallback.
- **Fix (exact step(s) to add / reorder):** Lock empty-string `bidderId` + no-throw semantics in this slice before implementation.
- **Owner:** @APIContract / @Architect
- **Acceptance check:** `T32` explicitly asserts parse success and empty-string fallback for `bidderId`.

- **Gap:** T33 “system fields” are not explicitly enumerated
- **Why it will break:** Reviewers may disagree whether `status` and `created_at` belong in the insert payload, leading to weak or inconsistent tests.
- **Fix (exact step(s) to add / reorder):** Enumerate excluded keys (`id`, `status`, `created_at`) and required insert keys in this slice.
- **Owner:** @Architect / @Sentinel
- **Acceptance check:** `T33` uses one documented key absence/presence policy.

- **Gap:** T35 roundtrip strictness is undefined
- **Why it will break:** The test can become either too weak (permissions only) or too brittle (full serializer snapshot) and lose trust quickly.
- **Fix (exact step(s) to add / reorder):** Lock roundtrip scope to permissions + sort fields + small sanity set unless you explicitly choose full roundtrip coverage.
- **Owner:** @APIContract / @Architect
- **Acceptance check:** `T35` assertions clearly match the chosen scope and reviewers enforce it consistently.

- **Gap:** ErrorMapper exception constructor shapes are version-sensitive and not standardized
- **Why it will break:** T36-T39 may fail due test setup incompatibility rather than real ErrorMapper regressions.
- **Fix (exact step(s) to add / reorder):** Create a shared local exception factory/helper in `error_mapper_test.dart` compatible with the pinned Supabase package versions.
- **Owner:** @Architect
- **Acceptance check:** T36-T39 instantiate exceptions through a shared helper and run offline without constructor churn.

- **Gap:** T40 uses global static cache state but lacks isolation rules
- **Why it will break:** Test-order leakage can cause false failures or false passes when cache entries persist across tests.
- **Fix (exact step(s) to add / reorder):** Require `SignedUrlCache.clear()` before and after T40 (and later T41) in this slice rules.
- **Owner:** @Sentinel / @Architect
- **Acceptance check:** T40 is deterministic regardless of test order and passes when run alone or in suite.

- **Gap:** No slice-level review checklist for parser/utility tests
- **Why it will break:** Tests may over-assert unrelated fields, under-assert real contracts, or mix multiple branches into one phase.
- **Fix (exact step(s) to add / reorder):** Add and enforce a review checklist covering fixture minimality, branch isolation, and global-state cleanup.
- **Owner:** @Sentinel
- **Acceptance check:** All `T31-T40` tests pass the checklist before merge.

## D) Invariants & Success Criteria (Non-Negotiable)

- **Invariant:** `TaskRequest.fromMap` prefers canonical `freelancer_id` over legacy `bidder_id`
- **How to enforce:** Enforce with `T31` using conflicting IDs in one fixture.
- **How to verify:** Parsed `bidderId` equals `freelancer_id` value.

- **Invariant:** Missing bidder IDs degrade safely instead of crashing parser
- **How to enforce:** Enforce with `T32` using fixture missing both bidder keys.
- **How to verify:** Parse succeeds and `bidderId` is the empty-string fallback (if approved contract).

- **Invariant:** `TaskRequest.toMap(forInsert: true)` excludes system-managed keys while keeping write-required keys
- **How to enforce:** Enforce with `T33` key absence/presence assertions.
- **How to verify:** `id/status/created_at` absent and insert keys present.

- **Invariant:** `UnifiedWorkItemModel.fromJson` maps `paid_request_pending` to `UnifiedWorkStatus.requestPending`
- **How to enforce:** Enforce with `T34` mapping fixture.
- **How to verify:** Parsed `unifiedStatus == UnifiedWorkStatus.requestPending`.

- **Invariant:** `WorkItem` cache roundtrip preserves nested `permissions` and sort metadata
- **How to enforce:** Enforce with `T35` roundtrip on a non-default `WorkItem` fixture.
- **How to verify:** Selected permission booleans and sort fields match before/after roundtrip.

- **Invariant:** `ErrorMapper.map` maps Postgrest code `42501` to session-expired guidance
- **How to enforce:** Enforce with `T36` using `PostgrestException` code `42501`.
- **How to verify:** Returned string matches chosen assertion policy for the session-expired message.

- **Invariant:** `ErrorMapper.map` maps auth invalid credentials to user-friendly login message
- **How to enforce:** Enforce with `T37` using `AuthException` message containing `invalid login credentials`.
- **How to verify:** Returned string matches chosen assertion policy for login-credentials message.

- **Invariant:** `ErrorMapper.map` maps payload-too-large storage errors to file-size guidance
- **How to enforce:** Enforce with `T38` using `StorageException` payload-too-large fixture.
- **How to verify:** Returned string matches chosen assertion policy for file-size message.

- **Invariant:** `ErrorMapper.isSessionExpired` returns `true` for JWT-expired auth errors
- **How to enforce:** Enforce with `T39` using `AuthException` message containing `jwt expired`.
- **How to verify:** Boolean result is `true`.

- **Invariant:** `SignedUrlCache` returns the exact cached URL immediately after `set()`
- **How to enforce:** Enforce with `T40` using immediate set/get and cache cleanup.
- **How to verify:** `get(path)` returns the URL and optional `size` sanity matches expected value.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| T32 uses weak “no throw” assertion only | T32 | Med | Med | Feature | Parser output changes but test still passes | Lock empty-string fallback contract | Strengthen test before merge |
| T33 serializer scope disagreement | T33 | Med | Med | Local | Review churn on which keys are “system” | Enumerate excluded/present keys in plan | Align on key-policy and update assertions |
| T35 becomes brittle with full roundtrip snapshot | T35 | Med | Med | Local | Frequent failures on unrelated model field changes | Scope to permissions+sort+sanity fields | Relax assertions with documented rationale |
| ErrorMapper exception constructors differ by package version | T36-T39 | High | High | Feature | Tests fail to compile/run due constructor signature mismatch | Shared exception helper/factory | Update helper once for package version |
| ErrorMapper string assertions churn due copy edits | T36-T38 | Med | Med | Feature | Frequent non-behavioral test failures | Choose one assertion policy (exact or semantic) | Switch to semantic with explicit note |
| T38 accidentally triggers wrong StorageException branch | T38 | Med | High | Feature | Unexpected mapped message in test | Build fixture with clear payload-too-large signals | Document and switch to a single explicit trigger path |
| T40 leaks static cache state between tests | T40 | High | Med | Local | Passes alone, fails in suite or vice versa | Clear cache before/after each cache test | Add teardown cleanup and rerun suite |
| T31/T32 fixtures become invalid due missing required fields | T31-T32 | Low | Med | Local | Parser throws/logs during arrange | Shared minimal fixture builder with overrides | Rebuild fixture helper and revalidate scope |
| T34 mixes source status and unified status semantics | T34 | Med | Med | Feature | Test passes but asserts wrong field | Use distinct values and assert mapped field explicitly | Add raw `sourceStatus` preservation assertion |

## F) Pre-Mortem (How this fails in real life)

- This fails when `T32` only checks “no throw” and the fallback silently changes from empty string to null, breaking downstream code later.
- This fails when `T33` does not explicitly assert `status`/`created_at` exclusion and insert payload regressions slip through.
- This fails when `T35` becomes a full serializer snapshot and starts failing on unrelated `WorkItem` evolution, causing the team to distrust the suite.
- This fails when `T36-T39` spend time fighting Supabase exception constructors instead of testing ErrorMapper behavior, because helper strategy was not defined up front.
- This fails when `T38` accidentally triggers the wrong storage branch and the test asserts a generic upload message instead of the size message.
- This fails when `T40` forgets to clear the static cache and passes/fails depending on test order.
- This fails when `T34` asserts `source_status` mapping instead of `unified_status` mapping and misses the actual UI compatibility contract.
- This fails when ErrorMapper string assertion policy is inconsistent across T36/T37/T38 and review churn slows progress.

## G) Plan Fixes (Concrete Additions / Expansions)

- **Goal:** Lock exact parser/serializer contract scopes for `T31-T35`
- **Why:** Ambiguous “safe fallback”, “system fields”, and roundtrip scope would produce weak or brittle tests.
- **How:** Resolve the blocking decisions in Section A and encode the choices in test comments/assertions.
- **Output artifact:** Updated plan decisions + consistent test assertion scopes in model test files
- **Stop condition:** Each phase has a clear, reviewable assertion contract and minimal fixture strategy.

- **Goal:** Standardize exception construction for ErrorMapper tests (`T36-T39`)
- **Why:** Constructor churn can waste implementation time and produce false failures unrelated to `ErrorMapper` logic.
- **How:** Add a shared local helper/factory in `error_mapper_test.dart` for Postgrest/Auth/Storage exceptions compatible with pinned package versions.
- **Output artifact:** Exception helper utilities in `error_mapper_test.dart`
- **Stop condition:** All ErrorMapper tests create exceptions through one helper and run offline.

- **Goal:** Enforce static-cache isolation for `SignedUrlCache` tests
- **Why:** `SignedUrlCache` uses a global static map and is vulnerable to test-order leakage.
- **How:** Clear cache before and after each cache test and include this in the slice review checklist.
- **Output artifact:** Cache test setup/teardown + checklist note
- **Stop condition:** T40 (and later T41) pass alone and in suite order.

- **Goal:** Add per-phase input requirements and gate checks
- **Why:** Makes blockers explicit and reduces back-and-forth during implementation.
- **How:** Document required user inputs and `GATE CHECK` for every phase below.
- **Output artifact:** Per-phase plan content
- **Stop condition:** Implementer can start each test with no hidden assumption work.

- **Goal:** Add slice-level QA/review checklist for parser/utility tests
- **Why:** Parser and utility tests fail most often from poor fixture design and over-bundled assertions, not code defects.
- **How:** Require fixture minimality, branch isolation, and cleanup rules in the slice gate before merge.
- **Output artifact:** Slice QA gate + reviewer checklist expectations
- **Stop condition:** `T31-T40` tests are deterministic, scoped, and review-consistent.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Slice Dependency Order (T31-T40)

1. Data/Contracts: lock parser/serializer scope decisions (`T32`, `T33`, `T35`) and ErrorMapper assertion policy/helper strategy.
2. Security-sensitive logic: ErrorMapper mapping/detection tests (`T36-T39`) and compatibility mappings that affect action routing (`T34`).
3. Backend/App logic unit tests: model parsing/serialization and cache hit behavior (`T31-T35`, `T40`).
4. UI/Integration: not applicable for this slice (unit tests only).
5. QA/Release: grouped local run + review checklist signoff before moving to `T41-T50`.

### Shared Implementation Rules (Applies to T31-T40)

- [ ] (@Architect) No production behavior changes; this slice should be test-only.
- [ ] (@Sentinel) All tests run offline and deterministically; no network, no Supabase initialization, no plugin channels.
- [ ] (@APIContract) Use minimal valid fixtures with small override helpers for parser tests; avoid copy-pasted large payloads.
- [ ] (@Sentinel) Keep one-phase-one-contract scope; local subcases only when explicitly justified.
- [ ] (@Sentinel) Clear `SignedUrlCache` before and after cache tests to prevent static-state leakage.
- [ ] (@ThreatModeler) ErrorMapper tests must assert user-facing outputs or boolean session detection, not raw technical exception text.

### Slice QA/Release Gate (Before Marking T31-T40 Complete)

- [ ] (@Sentinel) `flutter test /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models /Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core` passes for `T31-T40`.
- [ ] (@Sentinel) All blocking decisions in Section A are resolved and reflected in assertions/comments.
- [ ] (@Sentinel) Review checklist passes: parser fixtures minimal, ErrorMapper exceptions built via shared helper, cache tests isolate global state.
- **GATE CHECK:** `T31-T40` is stable and merge-ready before starting `T41-T50`.

## Phase 31: T31 - TaskRequest.fromMap chooses freelancer_id then bidder_id

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T31` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_request_model_test.dart`.

### Why

- This locks the canonical-vs-legacy ID precedence in `TaskRequest.fromMap`. If it regresses, offers can be associated with the wrong freelancer identity in UI and follow-up actions.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_request_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_request_model.dart`.
- Test case target: `TaskRequest.fromMap chooses freelancer_id then bidder_id`.
- A valid `TaskRequest.fromMap` fixture that includes both `freelancer_id` and `bidder_id` with conflicting values to prove precedence.
- Minimal required fields for parser success (`id`, `task_id`, `price`, `days`, `status`, `created_at`).
- Decision on scope: precedence assertion only vs precedence + parse sanity on one or two other fields (recommended: precedence + minimal parse sanity).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Build one deterministic fixture where `freelancer_id != bidder_id` and all required fields are valid.
- [ ] (@Architect) Call `TaskRequest.fromMap(...)` and assert `bidderId` equals the `freelancer_id` value (canonical precedence).
- [ ] (@Architect) Add minimal sanity assertions (for example `taskId` / `price`) to prove parser success and avoid a misleading fixture-only pass.
- [ ] (@Sentinel) Review the test for one-scenario scope and explicit precedence coverage.
- **Verify (@Sentinel):** `T31` remains one scenario and does not hide missing-field fallback coverage (T32).

### How To Do It

- Use one fixture map with clearly different canonical vs legacy IDs so the precedence result is unambiguous.
- Keep joined `profiles` / `tasks` payloads out of this phase unless required for parser validity (they are not required here).
- Avoid combining null handling with precedence; null fallback behavior belongs to `T32`.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Strong parser-contract coverage for canonical/legacy identifier migration compatibility in task requests.
- Fast signal if future refactors accidentally prioritize the legacy `bidder_id` over canonical `freelancer_id`.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm precedence scope: canonical `freelancer_id` must win when both keys exist (recommended: yes, explicit conflicting fixture).
- Optional: confirm whether to include one parse-sanity assertion (recommended: yes, e.g. `price` or `taskId`).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T31` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_request_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Conflicting `freelancer_id` / `bidder_id` fixture deterministically produces `bidderId == freelancer_id`.
- This phase is not complete until the test passes locally and reviewer confirms precedence is explicitly proven.

---

## Phase 32: T32 - TaskRequest.fromMap missing bidder fields falls back safely

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T32` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_request_model_test.dart`.

### Why

- This protects the null-safe fallback path in a mixed-schema environment. If it regresses, missing bidder IDs may crash parsing instead of degrading safely.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_request_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_request_model.dart`.
- Test case target: `TaskRequest.fromMap missing bidder fields falls back safely`.
- A valid fixture that omits both `freelancer_id` and `bidder_id` but still includes all other required parser fields.
- Explicit definition of “safely” (recommended: no throw + parsed empty-string `bidderId` based on current implementation).
- Awareness that `TaskRequest.fromMap` logs and rethrows on parse failure; this phase must stay on the successful fallback path.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Build a minimal valid task-request fixture with both bidder keys omitted.
- [ ] (@Architect) Call `TaskRequest.fromMap(...)` and assert parse succeeds with empty-string `bidderId` fallback.
- [ ] (@Architect) Add a minimal sanity assertion on another parsed field to prove the object is valid, not partially broken.
- [ ] (@Sentinel) Review the test to ensure it covers fallback semantics, not logger behavior or exception paths.
- **Verify (@Sentinel):** `T32` remains one scenario and does not duplicate precedence coverage from `T31`.

### How To Do It

- Start from the T31 base fixture and remove both bidder ID keys while keeping required values intact.
- Assert the exact fallback output (empty string) if you want to lock current behavior; do not weaken to non-null-only unless intentionally changing the contract.
- Do not combine unknown `status` fallback in this phase; it would dilute the bidder-ID fallback signal.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Coverage for safe parser behavior during schema transition or malformed payloads missing bidder ID columns.
- Early detection if null handling changes and starts throwing or returning an unintended fallback value.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm “falls back safely” means no throw + empty-string `bidderId` (recommended, matches current code).
- Optional: confirm whether to assert one extra parsed field for sanity (recommended: yes).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T32` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_request_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Missing bidder key fixture parses successfully and returns the documented empty-string fallback for `bidderId`.
- This phase is not complete until the test passes locally and reviewer confirms “safely” is explicitly defined.

---

## Phase 33: T33 - TaskRequest.toMap(forInsert: true) excludes system fields

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T33` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_request_model_test.dart`.

### Why

- This protects insert payload hygiene for task requests. If system-managed fields leak into insert maps, writes can fail or create hidden compatibility issues.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_request_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_request_model.dart`.
- Test case target: `TaskRequest.toMap(forInsert: true) excludes system fields`.
- A `TaskRequest` instance with all normal fields populated (including `id`, `status`, `createdAt`) so exclusions are observable.
- Explicit definition of “system fields” for this phase (recommended: at least `id`, `status`, `created_at`; plus preserve write-required keys).
- Decision on whether to also assert note trimming/omission when `note` is blank (optional; can be a local subcase if approved).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Construct a `TaskRequest` object with non-default values and call `toMap(forInsert: true)`.
- [ ] (@Architect) Assert excluded keys (`id`, `status`, `created_at`) are absent in the insert payload.
- [ ] (@Architect) Assert required insert keys remain present (`task_id`, `freelancer_id`, `bidder_id`, `price`, `days`) and canonical+legacy ID writes both use `bidderId`.
- [ ] (@Sentinel) Review the test for key-contract focus and ensure it does not drift into full serializer snapshot testing.
- **Verify (@Sentinel):** `T33` remains one scenario and does not duplicate non-insert `toMap()` behavior.

### How To Do It

- Use key-presence and key-absence assertions rather than full-map equality unless you intentionally want strict serializer lock-in.
- If you include a blank-note local subcase, keep it explicitly scoped to `forInsert` behavior and do not add extra test IDs.
- Keep joined/display-only fields (`bidderName`, `taskTitle`) out of the payload assertions because they are not serialized by `toMap`.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Reliable protection against accidental insertion of system-managed task-request fields.
- Fast regression signal if insert payload keys drift during schema migration or serializer refactors.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm “system fields” for T33 should include `id`, `status`, and `created_at` (recommended: yes).
- Choose assertion style: key absence/presence (recommended) vs full exact map.
- Optional: confirm whether to include a blank-note subcase to assert note omission (recommended only if kept concise).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T33` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/task_request_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- `toMap(forInsert: true)` excludes system keys and retains required insert keys (including canonical + legacy bidder IDs).
- This phase is not complete until the test passes locally and reviewer confirms payload-scope assertions are not brittle.

---

## Phase 34: T34 - UnifiedWorkItemModel.fromJson maps paid_request_pending to requestPending

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T34` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/unified_work_item_model_test.dart`.

### Why

- This mapping feeds unified dashboard behavior. If `paid_request_pending` stops mapping to `requestPending`, UI action logic can show the wrong CTA for work items.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/unified_work_item_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/models/unified_work_item_model.dart`.
- Test case target: `UnifiedWorkItemModel.fromJson maps paid_request_pending to requestPending`.
- A minimal valid unified-work fixture with `unified_status: paid_request_pending` and required parser fields (`id`, `source_type`, `source_status`, `title`, `price`, `client_id`, `freelancer_id`).
- Decision on scope: assert mapped `unifiedStatus` only vs mapped `unifiedStatus` + raw `sourceStatus` preservation (recommended: include both).
- Awareness that `sort_rank`, `needs_review`, and other defaults exist but are not the primary contract for this phase.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Build a valid fixture with `unified_status: paid_request_pending` and a distinct `source_status` value.
- [ ] (@Architect) Call `UnifiedWorkItemModel.fromJson(...)` and assert `unifiedStatus == UnifiedWorkStatus.requestPending`.
- [ ] (@Architect) Optionally assert `sourceStatus` preserves the raw DB value to prove mapping is applied only to the unified field.
- [ ] (@Sentinel) Review the test for mapping-scope focus and one-scenario discipline.
- **Verify (@Sentinel):** `T34` remains one scenario and does not bundle unrelated default-field assertions.

### How To Do It

- Use one fixture map with explicit strings to avoid ambiguity between `source_status` and `unified_status`.
- Assert enum mapping directly and keep downstream permission/action logic out of this phase (covered elsewhere).
- Use minimal additional assertions only to prove parser success and raw-field preservation if approved.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Strong model-level protection for a status alias that drives unified workspace actions and sorting behavior indirectly.
- Early detection if view/RPC output names or parser mappings drift from current compatibility rules.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm assertion scope: mapped `unifiedStatus` only vs mapped `unifiedStatus` + raw `sourceStatus` preservation (recommended: include both).
- Optional: confirm whether to assert default `sortRank`/`needsReview` here (recommended: no, keep T34 focused on status mapping).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T34` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/unified_work_item_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Fixture with `unified_status: paid_request_pending` deterministically maps to `UnifiedWorkStatus.requestPending`.
- This phase is not complete until the test passes locally and reviewer confirms unified-status mapping scope is isolated.

---

## Phase 35: T35 - WorkItem toJson/fromJson roundtrip preserves permissions and sort fields

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T35` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/work_item_model_test.dart`.

### Why

- This protects dashboard cache serialization. If `permissions`, `sortRank`, or `lastActivityAt` do not roundtrip correctly, cached dashboard state can rehydrate into wrong actions or order.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/work_item_model_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/models/work_item.dart`.
- Test case target: `WorkItem toJson/fromJson roundtrip preserves permissions and sort fields`.
- A fully constructed `WorkItem` instance with non-default `WorkItemPermissions`, non-default `sortRank`, and non-null `lastActivityAt` to make roundtrip preservation observable.
- Decision on strictness: assert only permissions/sort fields (recommended) vs broad field-by-field full roundtrip equality (stronger but more brittle).
- Fixed timestamp values (prefer UTC ISO strings) so roundtrip assertions remain deterministic.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Construct a `WorkItem` with mixed permission booleans and explicit non-default `sortRank` / `lastActivityAt` values.
- [ ] (@Architect) Roundtrip via `toJson()` then `WorkItem.fromJson(...)` and assert permissions booleans plus sort-related fields are preserved.
- [ ] (@Architect) Add a few sanity assertions on core identity/type fields to prove the roundtrip fixture is valid, without over-bundling the entire model contract.
- [ ] (@Sentinel) Review the test for cache-roundtrip focus and avoid brittle full-object snapshot assertions unless explicitly chosen.
- **Verify (@Sentinel):** `T35` remains one scenario and keeps focus on permissions and sort fields.

### How To Do It

- Prefer field-level assertions for `permissions`, `sortRank`, and `lastActivityAt` rather than comparing object identity (no custom equality on `WorkItem`).
- Use explicit `PrimaryActionType`, `WorkItemType`, and `DateTime` values so parser/serializer behavior is easy to reason about.
- Keep fallback parsing branches (for missing `primaryActionType` or default `sortRank`) out of this phase.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- High-value coverage for dashboard cache serialization integrity with minimal runtime overhead.
- Fast detection if nested permission JSON or sort metadata changes break cached dashboard ordering/actions.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Choose T35 strictness: focus on permissions + sort fields with a few sanity fields (recommended) vs broad field-by-field roundtrip assertions.
- Optional: confirm which sort fields to lock explicitly (recommended: `sortRank` and `lastActivityAt`; `needsReview` optional).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T35` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/work_item_model_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- WorkItem cache roundtrip preserves nested permissions and sort metadata deterministically from a non-default fixture.
- This phase is not complete until the test passes locally and reviewer confirms roundtrip scope is not over-bundled.

---

## Phase 36: T36 - ErrorMapper.map Postgrest 42501 returns session-expired message

> Primary: @Architect
> Supporting: @APIContract, @Sentinel, @ThreatModeler

### Goal

- Implement and stabilize `T36` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/error_mapper_test.dart`.

### Why

- This is a security-sensitive UX path. RLS denial (`42501`) is intentionally mapped to a session-expired message to drive re-auth flows; regressions here leak confusing DB errors to users.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/error_mapper_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/error_mapper.dart`.
- Test case target: `ErrorMapper.map Postgrest 42501 returns session-expired message`.
- A valid `PostgrestException` construction strategy for the current `supabase_flutter` dependency version (direct ctor or local helper factory).
- Decision on assertion mode: exact user-facing message string vs semantic contains (recommended: exact if you treat copy as contract; otherwise semantic).
- Clear separation from `ErrorMapper.isSessionExpired(...)` boolean checks (covered by `T39`).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Confirm/create a helper to instantiate `PostgrestException` with code `42501` for the pinned package version.
- [ ] (@Architect) Call `ErrorMapper.map(error)` and assert the mapped user-facing session-expired message.
- [ ] (@Architect) Ensure assertions verify mapped output, not raw exception code/message passthrough.
- [ ] (@Sentinel) Review the test for exception-shape correctness and behavior-first assertion scope.
- **Verify (@Sentinel):** `T36` remains one scenario and does not duplicate `isSessionExpired` boolean coverage from `T39`.

### How To Do It

- Use a local test helper for exception creation if constructor signatures differ by Supabase package versions to avoid repeated boilerplate in T36-T39.
- Prefer exact string assertion if product copy is stable; otherwise use semantic contains with a documented reason.
- Keep Postgrest code coverage strictly to `42501` in this phase; other codes are out of scope.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Strong coverage for session-expired messaging on backend authorization failures (RLS denied path).
- Early detection if ErrorMapper refactors start exposing technical DB messages or wrong auth guidance.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Choose string assertion mode for `T36`: exact mapped message vs semantic contains (recommended: exact if copy is stable).
- Optional: approve using a shared exception-construction helper in `error_mapper_test.dart` for Postgrest/Auth/Storage exceptions (recommended: yes).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T36` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/error_mapper_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- A version-compatible `PostgrestException` with code `42501` maps to the intended session-expired message through `ErrorMapper.map(...)`.
- This phase is not complete until the test passes locally and reviewer confirms no raw DB error leakage is asserted.

---

## Phase 37: T37 - ErrorMapper.map auth invalid credentials returns user-friendly auth message

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T37` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/error_mapper_test.dart`.

### Why

- Invalid-login messaging is one of the most user-visible auth error paths. Regressions here increase login friction and support noise immediately.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/error_mapper_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/error_mapper.dart`.
- Test case target: `ErrorMapper.map auth invalid credentials returns user-friendly auth message`.
- A valid `AuthException` construction strategy for the current Supabase auth package version.
- Decision on exact vs semantic string assertion mode (recommended: same policy as T36 for consistency across ErrorMapper string tests).
- A fixture/auth error message containing `invalid login credentials` to trigger the intended branch in `_mapAuthError`.
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Construct an `AuthException` (or version-compatible equivalent) whose message contains `invalid login credentials`.
- [ ] (@Architect) Call `ErrorMapper.map(error)` and assert the mapped user-friendly auth message.
- [ ] (@Architect) Keep the test focused on the invalid-credentials branch and avoid mixing duplicate-email or session-expired auth messages.
- [ ] (@Sentinel) Review the test for branch-specific message coverage and consistent assertion policy with T36/T38.
- **Verify (@Sentinel):** `T37` remains one scenario and does not bundle other auth-message mappings.

### How To Do It

- Use a minimal auth exception payload/message and assert the exact mapped output (or semantic policy chosen in Section A).
- Prefer lowercase/uppercase-insensitive fixture text only if needed; `ErrorMapper` lowercases the message internally.
- Keep `ErrorMapper.isSessionExpired` checks out of this phase (T39 covers boolean detection).
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Reliable coverage for a top-volume auth error mapping branch with direct UX impact.
- Fast regression signal if auth error strings stop mapping to the intended friendly copy.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Choose string assertion mode for `T37`: exact mapped message vs semantic contains (recommended: same choice as T36/T38 for consistency).
- Optional: approve using one shared helper for constructing version-compatible `AuthException` objects (recommended: yes).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T37` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/error_mapper_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- An auth exception with `invalid login credentials` maps to the intended user-friendly login error message.
- This phase is not complete until the test passes locally and reviewer confirms branch-specific scope.

---

## Phase 38: T38 - ErrorMapper.map storage payload-too-large returns size message

> Primary: @Architect
> Supporting: @APIContract, @Sentinel

### Goal

- Implement and stabilize `T38` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/error_mapper_test.dart`.

### Why

- File-upload failures are common and user-facing. This test locks the “too large” mapping so users get actionable guidance instead of generic upload errors.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/error_mapper_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/error_mapper.dart`.
- Test case target: `ErrorMapper.map storage payload-too-large returns size message`.
- A valid `StorageException` construction strategy for the current storage client package version.
- Decision on branch trigger style: status code `413`, message contains `payload too large`, or both in one fixture (recommended: both if constructor supports it).
- Decision on exact vs semantic string assertion mode (recommended: same policy as T36/T37 for consistency).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Construct a version-compatible `StorageException` that represents a payload-too-large condition (prefer `statusCode: 413` + matching message).
- [ ] (@Architect) Call `ErrorMapper.map(error)` and assert the user-facing file-size message.
- [ ] (@Architect) Keep assertions on the mapped output only; do not test unrelated storage branches (`404`, invalid type, policy) in this phase.
- [ ] (@Sentinel) Review the test for stable branch triggering and consistent assertion policy with T36/T37.
- **Verify (@Sentinel):** `T38` remains one scenario and does not bundle multiple storage error branches.

### How To Do It

- Use a helper to construct `StorageException` safely if constructor signatures differ across versions.
- Prefer a fixture that satisfies both branch signals (status `413` and message phrase) to make the test resilient to minor internal branch ordering changes.
- If constructor does not expose `statusCode`, document and use the message-based trigger path explicitly.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Strong protection for the file-too-large error UX path in upload workflows.
- Quick regression signal if storage error mapping stops returning actionable size guidance.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Choose branch trigger preference for `T38`: `413` status, message substring, or both (recommended: both if constructor supports it).
- Choose string assertion mode for `T38`: exact mapped message vs semantic contains (recommended: same as T36/T37).
- Optional: approve shared helper for version-compatible `StorageException` construction (recommended: yes).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T38` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/error_mapper_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- A payload-too-large storage exception deterministically maps to the file-size message via `ErrorMapper.map(...)`.
- This phase is not complete until the test passes locally and reviewer confirms only the size branch is being exercised.

---

## Phase 39: T39 - ErrorMapper.isSessionExpired returns true for JWT-expired auth errors

> Primary: @Architect
> Supporting: @APIContract, @Sentinel, @ThreatModeler

### Goal

- Implement and stabilize `T39` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/error_mapper_test.dart`.

### Why

- Session-expiry detection drives forced re-auth flows. If JWT-expired auth errors are not detected, the app can leave users stuck in broken states after auth expiry.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/error_mapper_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/error_mapper.dart`.
- Test case target: `ErrorMapper.isSessionExpired returns true for JWT-expired auth errors`.
- A valid `AuthException` (or equivalent) with a message containing `jwt expired` to trigger the boolean detection path.
- Clear separation from string-mapping tests (`T36-T38`); this phase tests boolean detection only.
- Decision on whether to add one negative control assertion in the same phase (optional, recommended: no to keep scope tight).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Construct a version-compatible auth exception with a `jwt expired` message.
- [ ] (@Architect) Call `ErrorMapper.isSessionExpired(error)` and assert the result is `true`.
- [ ] (@Architect) Keep this phase boolean-only; do not assert `ErrorMapper.map(...)` output here.
- [ ] (@Sentinel) Review the test for clean separation from message-mapping tests and one-scenario scope discipline.
- **Verify (@Sentinel):** `T39` remains one scenario and specifically covers the `jwt expired` auth message path.

### How To Do It

- Reuse the shared auth-exception helper from T37 if available to keep constructor compatibility in one place.
- Use a message string containing `jwt expired` exactly (case-insensitive behavior is handled internally by `toLowerCase()`).
- Avoid adding Postgrest `42501` session-expiry checks here; they are already covered by T36/T39 separation rules.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Targeted coverage for auth-expiry detection logic used by redirect/logout flows.
- Fast detection if JWT-expired wording stops being recognized by `isSessionExpired(...)`.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Optional: confirm whether you want a negative control assertion in this phase (recommended: no, keep T39 focused on the positive JWT-expired path).
- Optional: approve reuse of the same auth-exception helper as T37 (recommended: yes).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T39` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/error_mapper_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- A JWT-expired auth exception deterministically returns `true` from `ErrorMapper.isSessionExpired(...)`.
- This phase is not complete until the test passes locally and reviewer confirms boolean-only scope.

---

## Phase 40: T40 - SignedUrlCache set/get hit path

> Primary: @Architect
> Supporting: @Sentinel

### Goal

- Implement and stabilize `T40` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/signed_url_cache_test.dart`.

### Why

- This is the base cache correctness path. If set/get hit behavior regresses, the app may generate redundant signed URLs and increase storage/network load.

### What We Need

- Planned test file: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/signed_url_cache_test.dart`.
- Primary implementation target: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/utils/signed_url_cache.dart`.
- Test case target: `SignedUrlCache set/get hit path`.
- A deterministic storage path + signed URL pair and a cache isolation strategy (clear cache before/after test because `SignedUrlCache` is global static state).
- Decision on assertion scope: returned URL only vs returned URL + cache size sanity (`size == 1`) (recommended: include size sanity if it stays simple).
- No time control needed for this phase because it tests a cache hit immediately after `set()` (expiry is covered by `T41`).
- **Verify (@Sentinel):** prerequisites are available and scoped to this one test only.

### What To Do

- [ ] (@Architect) Clear `SignedUrlCache` at test start to isolate global state.
- [ ] (@Architect) Call `SignedUrlCache.set(path, url)` and immediately assert `SignedUrlCache.get(path) == url`.
- [ ] (@Architect) Optionally assert `SignedUrlCache.size == 1` and clear the cache again in teardown/cleanup.
- [ ] (@Sentinel) Review the test for global-state isolation and no hidden dependency on wall-clock timing.
- **Verify (@Sentinel):** `T40` remains one scenario and does not include expiry/eviction behavior (T41).

### How To Do It

- Use a unique fake storage path string and a deterministic fake signed URL string; no real network calls are involved.
- Always clear the cache before (and preferably after) the test to prevent test-order leakage due the static map.
- Keep duration overrides and time assertions out of this phase; expiry behavior is separate.
- **Verify (@Sentinel):** implementation steps are reproducible and do not require new decisions beyond the listed inputs.

### What To Expect From This Test

- Fast and stable coverage for the most basic signed URL cache hit behavior.
- Early detection if cache writes, lookups, or static-state handling regress in utility refactors.
- **Verify (@Sentinel):** regression value is clear and proportional to maintenance cost.

### What Input You Should Provide Me

- Confirm cache isolation policy: clear before and after the test (recommended: yes).
- Optional: confirm whether to assert `SignedUrlCache.size == 1` in T40 (recommended: yes, simple sanity check).
- If you provide nothing, I will use the defaults/recommendations documented in Section A.

### Result (Expected Output Artifact)

- One passing test case (or one clearly-scoped test block with local subcases where explicitly allowed) implementing `T40` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/core/signed_url_cache_test.dart`.
- Any helper/fixture added for this phase remains reusable and does not change production behavior.

### GATE CHECK

- Immediate `set()` followed by `get()` returns the cached URL with isolated static cache state.
- This phase is not complete until the test passes locally and reviewer confirms no expiry behavior is mixed in.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- The previous `T31-T40` segment was still generic and did not include `@PlanCritic` gate checks, risks, or slice-specific parser/utility contract decisions.
- It treated model parser tests and utility tests with the same placeholder seam/fake wording, which is incorrect for this slice.
- It did not define exact meanings for ambiguous phrases like “falls back safely”, “system fields”, and “roundtrip preserves”.
- It did not make ErrorMapper exception-construction compatibility or SignedUrlCache static-state isolation explicit.
- It lacked per-phase `What Input You Should Provide Me` sections.

### 2) Added steps (bullet list)

- Added full `@PlanCritic` audit sections `A-I` for this slice.
- Added blocking decisions for `T32`, `T33`, `T35`, and ErrorMapper assertion/helper strategy (`T36-T39`).
- Added slice-specific invariants for TaskRequest precedence/fallback, unified status mapping, WorkItem cache roundtrip, ErrorMapper mappings, and SignedUrlCache hit behavior.
- Added risk register + pre-mortem tailored to parser ambiguity, exception constructor drift, and static cache leakage.
- Added per-phase `What Input You Should Provide Me` and `GATE CHECK` sections for all 10 tests.
- Added explicit cache isolation rule and grouped QA gate command for `test/unit/models` + `test/unit/core`.

### 3) Removed steps (if any)

- Removed generic “add seam/fake if needed” placeholders for pure model/utility tests where no DI seams are required.

### 4) Reordered steps (from → to)

- From: direct generic phase list only.
- To: audit + gate failures + corrected gate-based plan + 10 detailed one-test phases.

### 5) Expanded steps (what became more detailed)

- `T31-T33`: now define canonical/legacy bidder ID precedence, missing-ID fallback semantics, and insert payload key contracts.
- `T34-T35`: now define unified status mapping scope and cache roundtrip assertion strictness for permissions/sort fields.
- `T36-T39`: now define ErrorMapper branch triggers, exception helper strategy, and consistent string assertion policy.
- `T40`: now defines static-cache isolation rules and keeps expiry behavior explicitly out of scope (reserved for `T41`).

### 6) Why (short, practical)

- The original slice could produce weak or flaky tests because the real parser/error/cache contracts were implied instead of locked. This version makes the exact behavior and setup requirements explicit before implementation starts.

### 7) Residual risks (what still remains risky even after fixes)

- Supabase exception constructor APIs can still change with package upgrades; the helper strategy reduces but does not eliminate maintenance work.
- If user-facing ErrorMapper copy changes intentionally, T36-T38 will require policy-consistent assertion updates.
- Later cache tests (T41+) will need time-control discipline; this document only hardens the `set/get` hit path for `T40`.

