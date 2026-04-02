# System Evolution Report (v2)

**Date:** 2026-04-02
**Sessions Analysed:** 2
- `SESSION_PhaseB_BugExposure_2026-04-01.md`
- `SESSION_PLAN_CriticalTests_2026-04-02.md`
**Supporting Evidence:** `MASTER_REPORT_2026-04-02_PhaseC.md`, `SYSTEM_EVOLUTION_REPORT_2026-04-02.md` (v1)
**Most Common Failure Type:** Constructor DI injectability gap (new pattern, 2 occurrences in Phase C)
**Most Frequently Flagged Agent:** @SlinePlanner (2 of 3 new gaps)
**Highest-Value Improvement:** Add constructor DI verification to Planner's mandatory scan

---

## Prior Report Status

The v1 report (2026-04-02, Phase B only) identified 7 rule gaps. All 7 were applied:

| Gap | Rule Added To | Status |
|-----|--------------|--------|
| 1.1 Error vs Exception | Architect.md §3.2.1 | APPLIED |
| 1.2 Test mock audit | Executor.md Step 3.2 | APPLIED |
| 1.3 notifyListeners timing | Architect.md §3.4.1 | APPLIED |
| 1.4 Sub-phase test gate | Executor.md Step 3.1 | APPLIED |
| 1.5 Async callback guards | Architect.md §3.4.2 | APPLIED |
| 8.1 Query builder pattern | Architect.md §4.5 | APPLIED |
| P3 Runtime smoke test | Orchestrator.md Stage 11.5 | APPLIED |

**Effectiveness check:** Phase C had zero instances of the problems these rules address. The Error vs Exception rule was not triggered (no bare catch changes). The test mock audit rule was not triggered (no VM API changes in production code). The sub-phase test gate was followed (baseline verified after Phase 1 refactoring). Rules are working.

---

## 1. Rule Gaps (New — from Phase C)

### Gap 1.1: Planner does not verify constructor DI injectability

**Evidence:**
- Session log line 24: `@SlinePlanner (v1) | Did not identify WalletVM/ChatVM constructor DI gap`
- Plan Critique: "Gate 0: Test Infrastructure Gate — FAIL" — original plan had no phase for constructor refactoring
- Plan Critique: "Gap 1: WalletVM and ChatVM cannot be meaningfully unit-tested without injecting mock services"
- Both VMs created services internally from `SupabaseClient` — required additive constructor refactoring before tests could be written

**Current state:** `Sline_Planner.md` Section 2.2 (Code Scan) says "Scan relevant layers" but does not require verifying that target class constructors support DI.

**Impact:** Phase C required a @PlanCritic pass to catch this, adding an unplanned Phase 1 (4 sub-phases) to the execution. Without the critic, the executor would have hit a wall when trying to mock services.

**Rule to add to `Sline_Planner.md` under Section 2.2 (Code Scan):**
```
### 2.2.1 Constructor DI Verification (Required When Planning Tests)

When the plan includes unit tests for ViewModels, Services, or Repositories:
1. Read EVERY target class's constructor.
2. Verify that ALL dependencies (services, repositories, clients) can be injected via optional constructor parameters.
3. If a target class creates dependencies internally (e.g., `_repo = WalletRepository(client ?? Supabase.instance.client)` in the constructor body), the plan MUST include a constructor refactoring sub-phase BEFORE the test-writing phases.
4. Document the DI pattern used by each target class: "fully injectable" (like DashboardVM/BookingVM), "client-injectable" (like WalletVM pre-refactor), or "not injectable" (hard-coded dependencies).
5. Note whether `Supabase.instance` appears in any fallback — these classes need special test environment handling or refactoring.

Evidence: Phase C — WalletVM and ChatVM required constructor refactoring (Phase 1) that was not in the original plan. @PlanCritic caught this as a FAIL on the Test Infrastructure Gate.
```

---

### Gap 1.2: Planner does not check for singleton patterns in test targets

**Evidence:**
- Session log line 25: `@SlinePlanner (v1) | Did not include RoleSwitchCoordinator singleton cleanup`
- Plan Critique: "Gap 2: RoleSwitchCoordinator singleton pollution between tests"
- ChatVM and DashboardVM register with `RoleSwitchCoordinator()` (static singleton) in their constructors — tests that create multiple VM instances without cleanup would pollute state
- The singleton had a `clearForTesting()` method ready, but the plan didn't mention it

**Current state:** `Sline_Planner.md` has no rule about detecting singletons in test targets and planning cleanup strategies.

**Rule to add to `Sline_Planner.md` under Section 2.2 (Code Scan):**
```
### 2.2.2 Singleton & Static State Detection (Required When Planning Tests)

When the plan includes unit tests for classes that interact with singletons or static state:
1. Grep for singleton patterns in target classes: `static final`, `factory Constructor() => _instance`, `register(this)`, `Coordinator()`.
2. For EACH singleton found, verify whether a `clearForTesting()`, `reset()`, or equivalent method exists.
3. If it exists: the plan MUST include `tearDown` cleanup instructions.
4. If it doesn't exist: the plan MUST include a step to ADD a testing reset method to the singleton.
5. Document all singletons in the plan's Evidence section.

Evidence: Phase C — ChatVM and DashboardVM register with RoleSwitchCoordinator (singleton). Omitting `clearForTesting()` in tearDown would cause cross-test pollution and random CI failures.
```

---

### Gap 1.3: Planner does not scan for auto-loading constructors

**Evidence:**
- Plan Critique: "Gap 4: DashboardVM auto-loads in constructor — requires pre-configured mocks"
- DashboardVM calls `_loadCachedRole()`, `_syncRoleFromBackend()`, and `_loadOverviewData()` in its constructor body
- All mocks needed to be pre-configured BEFORE construction — omitting any stub caused `MissingStubError`
- While the @PlanCritic caught this, the original plan (v1) did not

**Current state:** No rule exists to detect constructors that trigger async side effects on creation.

**Rule to add to `Sline_Planner.md` under Section 2.2 (Code Scan):**
```
### 2.2.3 Auto-Loading Constructor Detection (Required When Planning Tests)

When the plan includes unit tests for classes with DI constructors:
1. Check if the constructor body or initializer calls any methods (load, fetch, init, sync, subscribe).
2. If yes: the plan MUST specify that ALL mock stubs must be configured BEFORE VM construction in setUp.
3. Include an explicit "Default Mock Configuration" step listing every method that needs a stub.
4. Note the required await/microtask delay pattern for async constructor init.

Evidence: Phase C — DashboardVM calls 3 load methods in constructor. Missing any mock stub = MissingStubError.
```

---

## 2. Rule Clarity Gaps

### Gap 2.1: `late final` → `late` change was initially accepted, then reversed

**Evidence:**
- Phase 1.2 session log: "Changed `late final` to `late` for 3 fields"
- Master Report finding #3: "MED — `late` (non-final) allows post-construction reassignment"
- Master Report finding #9: "LOW — reduces compile-time safety"
- Subsequently fixed by restructuring constructor to initializer list, restoring `final`

**Current state:** The Architect rule about immutability exists but the specific `late final` → `late` footgun when moving assignment from constructor body to initializer list is not documented.

**Rule to add to `Architect.md`:**
```
### Constructor Refactoring: Preserve Field Immutability

When refactoring a constructor to add optional DI parameters:
- If fields were `late final` (assigned in constructor body), prefer restructuring to use an initializer list with `final` fields and ternary/`??` expressions.
- Do NOT downgrade `late final` to `late` just to make conditional assignment work — this removes a compile-time immutability guarantee.
- Pattern: `final X _field;` with `: _field = param ?? DefaultX()` in the initializer list.

Evidence: Phase C — ChatVM fields were changed from `late final` to `late` to support conditional assignment, then reverted to `final` via initializer list restructuring after the Orchestrator audit flagged the mutability risk.
```

---

## 3. MCP Recommendations

### 3.1: Supabase MCP Server — Still Not Evidenced

Phase C had zero schema/RLS/RPC changes. The only Supabase-related finding (migration file on branch) was detected by grepping the filesystem, not by querying a live DB. Threshold not met.

**Status:** Monitor. No change from v1.

---

## 4. Missing Skills

None identified. Phase C used standard test-writing patterns. No skill from `.cursor/skills/` was invoked (no UI or backend work).

---

## 5. Agent Coordination Gaps

### 5.1: Planner → Executor handoff for test infrastructure needs

**Gap:** @SlinePlanner produces a plan that assumes test infrastructure is ready. @PlanCritic catches gaps. But if @PlanCritic is not invoked, @Executor hits walls.

**Pattern:** Both Phase B and Phase C required @PlanCritic to catch infrastructure gaps that @SlinePlanner missed. This is now a 2-session pattern (systemic).

**Fix:** Add to `Sline_Planner.md` Section 0 (Output Rule):
```
Before finalizing any test-heavy plan, the Planner MUST self-verify:
1. Can every target class be constructed with mock dependencies? (Gap 2.2.1)
2. Are singleton cleanup methods documented? (Gap 2.2.2)
3. Are auto-loading constructors flagged? (Gap 2.2.3)

If ANY check fails, add an infrastructure phase BEFORE the first test phase.
```

### 5.2: Executor → Orchestrator file integrity handoff (NEW)

**Gap:** During Phase C execution, a background agent corrupted the wallet VM test file (overwrote it with unrelated text). The Executor did not detect this until the full QA phase.

**Evidence:** Phase C session — `wallet_view_model_test.dart` was overwritten with garbage text starting "Fix the following issues..." — required full regeneration.

**Root cause:** Multiple background agents writing to different files concurrently. One agent's output was misdirected to another file.

**Fix:** Add to `Executor.md`:
```
### File Integrity Check (After Parallel Agent Execution)

After background agents complete in parallel:
1. Verify EVERY file they were supposed to create/modify by reading the first line.
2. If any file starts with unexpected content (not valid Dart: `import`, `//`, `library`), flag it immediately as corrupted.
3. Regenerate the corrupted file before proceeding.
4. Log the corruption as `PROBLEM ENCOUNTERED` in the session log.

Evidence: Phase C — background agent corrupted wallet_view_model_test.dart (overwrote with non-Dart text).
```

---

## 6. Orchestrator Pipeline Improvements

### 6.1: Stage 11.5 (Runtime Smoke Test) — Already Applied

Applied from v1 report. Not triggered in Phase C (no UI changes). Verified present in orchestrator.md line 58.

### 6.2: Parallel Stage Execution for Test-Only Scopes (NEW)

**Evidence:** Phase C Orchestrator ran Stages 1, 2, 3, 5, 8, 10, 11. Stages 4, 6, 7, 9, 11.5 were N/A. For test-only scopes, Stages 1-2 (Security + Backend) and 8 (Observability) could run in parallel since they have no dependencies.

**Recommendation:** LOW priority. The sequential pipeline is correct for safety. Parallelization is an optimization, not a gap. No action needed.

---

## 7. New Agent Recommendations

None needed. The existing 16 agents cover all responsibilities. Phase C gaps are in planning rules, not agent ownership.

---

## 8. Things the Human Missed

### 8.1: The wallet test file corruption went undetected until QA

The Executor launched 8 background agents in parallel. One agent's output corrupted `wallet_view_model_test.dart`. This was not detected until the Phase 8 full-suite run returned 1903 analysis errors.

The human did not catch this either — it was detected by the automated `flutter analyze` gate. This validates the importance of the Fast Feedback Gate rule (applied from v1) but reveals that parallel agent execution needs file integrity verification.

---

## 9. Priority Action List

| Priority | Action | Agent File | Evidence |
|----------|--------|------------|----------|
| **P0** | Add constructor DI verification rule | Sline_Planner.md | Session log line 24, PlanCritic Gate 0 FAIL |
| **P0** | Add singleton detection rule | Sline_Planner.md | Session log line 25, PlanCritic Gap 2 |
| **P1** | Add auto-loading constructor detection rule | Sline_Planner.md | PlanCritic Gap 4 |
| **P1** | Add field immutability preservation rule | Architect.md | Master Report findings #3, #9 |
| **P1** | Add file integrity check after parallel agents | Executor.md | Wallet test corruption during Phase C |
| **P2** | Add Planner self-verification gate for test plans | Sline_Planner.md | 2-session pattern of PlanCritic catching Planner gaps |

---

## 10. Improvement Tracking

| Gap ID | Rule Text | Agent File | Status |
|--------|----------|------------|--------|
| v1-1.1 | Error vs Exception | Architect.md | APPLIED |
| v1-1.2 | Test mock audit | Executor.md | APPLIED |
| v1-1.3 | notifyListeners timing | Architect.md | APPLIED |
| v1-1.4 | Sub-phase test gate | Executor.md | APPLIED |
| v1-1.5 | Async callback guards | Architect.md | APPLIED |
| v1-8.1 | Query builder pattern | Architect.md | APPLIED |
| v1-P3 | Runtime smoke test | Orchestrator.md | APPLIED |
| v2-1.1 | Constructor DI verification (§2.2.1) | Sline_Planner.md | APPLIED (2026-04-02) |
| v2-1.2 | Singleton detection (§2.2.2) | Sline_Planner.md | APPLIED (2026-04-02) |
| v2-1.3 | Auto-loading constructor detection (§2.2.3) | Sline_Planner.md | APPLIED (2026-04-02) |
| v2-2.1 | Field immutability preservation (§4.5) | Architect.md | APPLIED (2026-04-02) |
| v2-5.2 | File integrity check (Step 3.3) | Executor.md | APPLIED (2026-04-02) |
| v2-5.1 | Planner self-verification gate (§0.1) | Sline_Planner.md | APPLIED (2026-04-02) |

---

## 11. Full Evidence Index

| Evidence | File | Lines/Context |
|----------|------|---------------|
| DI gap not caught by Planner | `SESSION_PLAN_CriticalTests_2026-04-02.md` | Line 24 (Agent Improvement Notes) |
| Singleton cleanup not in plan | `SESSION_PLAN_CriticalTests_2026-04-02.md` | Line 25 (Agent Improvement Notes) |
| PlanCritic Gate 0 FAIL | `PLAN_CriticalTests_2026-04-02.md` | PlanCritic Section B |
| PlanCritic Gap 1-5 | `PLAN_CriticalTests_2026-04-02.md` | PlanCritic Section C |
| `late final` → `late` introduced then reverted | `SESSION_PLAN_CriticalTests_2026-04-02.md` | Line 109 + Master Report findings #3, #9 |
| DashboardVM auto-loading constructor | `PLAN_CriticalTests_2026-04-02.md` | PlanCritic Decision 2 |
| Wallet test corruption | Phase C execution (observed during QA) | flutter analyze returned 1903 errors |
| File started with "Fix the following issues" | `wallet_view_model_test.dart` (corrupted state, since regenerated) | Line 1 |
| All Phase B rules confirmed applied | `.cursor/Agents/Architect.md`, `Executor.md`, `orchestrator.md` | Grep results |
