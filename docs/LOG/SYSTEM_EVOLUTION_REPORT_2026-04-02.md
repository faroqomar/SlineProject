# System Evolution Report

**Date:** 2026-04-02
**Sessions Analysed:** 1 (`SESSION_PhaseB_BugExposure_2026-04-01.md`)
**Supporting Evidence:** `MASTER_REPORT_2026-04-01_PhaseAB.md`, `AUDIT_Quality_Architecture_2026-04-01.md`, emulator test logs (2026-04-02)
**Most Common Failure Type:** Error/Exception taxonomy confusion (3 occurrences)
**Most Frequently Flagged Agent:** @Architect (3 of 5 gaps)
**Highest-Value Improvement:** Add Error vs Exception handling rule to Architect + Executor

---

## 1. Rule Gaps

### Gap 1.1: No Error vs Exception distinction rule

**Evidence:**
- Session log line 50: `PROBLEM ENCOUNTERED: AssertionError from Supabase.instance not caught by on Exception catch`
- Session log line 22: `AGENT MISTAKE: B2/B3 agent did not anticipate that Supabase.instance throws AssertionError (Error, not Exception)`
- Emulator log: `login_screen.dart` failed because `ProviderNotFoundException` extends `Error`
- Emulator log: `notification_view_model.dart retry()` failed for same reason

**Current state:** No agent has a rule distinguishing `Error` (programming bugs, env misconfiguration) from `Exception` (recoverable runtime errors).

**Impact:** Every time an agent changes `catch (e)` to `on Exception catch (e)`, it risks breaking code that relied on catching `Error` subclasses from:
- `Supabase.instance` (throws `AssertionError` when not initialized)
- `context.read<T>()` (throws `ProviderNotFoundException` which extends `Error`)
- JSON decoding of malformed external data (throws `TypeError`)

**Rule to add to `Architect.md`:**
```
### Error vs Exception Handling (Dart-Specific)

In Dart, `Error` and `Exception` are separate hierarchies under `Object`:
- `Exception` = recoverable runtime errors (network, auth, validation, Supabase queries)
- `Error` = programming bugs or environment failures (TypeError, AssertionError, StackOverflowError)

Rules:
1. ViewModel and service catch blocks should use `on Exception catch (e)` by default.
2. Code that accesses `Supabase.instance` in a "try or fallback to null" pattern MUST also catch `Error` (it throws `AssertionError` when not initialized).
3. Code that accesses `context.read<T>()` outside a guaranteed Provider scope MUST catch `Error` (throws `ProviderNotFoundException`).
4. JSON parsing of external data (realtime, webhooks) should catch both `FormatException` and `TypeError` explicitly — never `on Object catch`.
5. Global error boundaries (`runZonedGuarded`, `FlutterError.onError`) are the only places that should catch everything.
```

---

### Gap 1.2: No test mock audit rule when adding ViewModel methods

**Evidence:**
- Session log line 25: `AGENT MISTAKE: B7 agent did not add loadCategories mock stubs to the "submit can pop" test`
- create_task_screen_test.dart failed because `loadCategories()` was added to `TaskViewModel` but the test's `_MockTaskViewModel` had no stub for it

**Current state:** No agent requires checking all test mocks when a ViewModel's public API changes.

**Rule to add to `Executor.md` under Section 5 (Execution Strategy):**
```
### Test Mock Audit (Mandatory When ViewModel API Changes)

When any agent adds, removes, or changes a public method on a ViewModel:
1. Search for all test files that create a Mock of that ViewModel type.
2. Verify each mock has stubs for the new/changed methods.
3. Run the specific test file(s) BEFORE proceeding.
4. Log the mock audit in the session log.

Failure to do this has caused test failures in past sessions (SESSION_PhaseB_BugExposure, line 25).
```

---

### Gap 1.3: No rule about `notifyListeners()` timing during build phase

**Evidence:**
- Emulator log (2026-04-02): `setState() or markNeedsBuild() called during build` error from `TaskViewModel.loadCategories` (line 61)
- Root cause: `loadCategories()` called `notifyListeners()` synchronously before any `await`, triggered during `didChangeDependencies`

**Current state:** Architect.md says "Calls `notifyListeners()` only when state actually changes" but has no rule about WHEN during the Flutter lifecycle it's safe to call.

**Rule to add to `Architect.md` under ViewModel section:**
```
### notifyListeners() Timing

- NEVER call `notifyListeners()` synchronously inside a method that may be invoked during `build()`, `initState()`, or `didChangeDependencies()`.
- If a ViewModel method is called during widget initialization and needs to set loading state, either:
  (a) Skip the initial `notifyListeners()` — the view manages its own loading state via `setState()`.
  (b) Defer via `Future.microtask(() => notifyListeners())`.
- The `finally` block after an `await` is always safe — the build frame has completed by then.

Evidence: SESSION_PhaseB emulator testing — TaskViewModel.loadCategories caused "setState during build" error.
```

---

### Gap 1.4: No sub-phase test gate in Executor

**Evidence:**
- Session log shows 20 test failures discovered only at full-suite run after ALL B1-B7 changes were applied. If tests had run after each sub-phase (B1, then B2, etc.), failures would have been caught earlier and traced to the specific change.

**Current state:** Executor.md says "Verify" but doesn't mandate `flutter test` between sub-phases.

**Rule to add to `Executor.md` under Section 5:**
```
### Fast Feedback Gate (Mandatory Between Sub-Phases)

After completing each sub-phase that modifies source code:
1. Run `flutter analyze` — must pass.
2. Run `flutter test` — must pass (same pass/skip/fail counts as baseline).
3. If either fails, do NOT proceed to next sub-phase. Fix immediately.
4. Log the gate result in the session log.

This catches regressions at the smallest possible scope. Evidence: SESSION_PhaseB had 20 test failures discovered late because tests ran only after all B1-B7 changes.
```

---

### Gap 1.5: No debounce/guard rule for async UI callbacks

**Evidence:**
- Emulator log (2026-04-02): `showSubmitRequestSheet` called 9+ times in <1 second, all hitting "Context not mounted" guard
- Root cause: FloatingActionButton and CTA had no guard against rapid taps during async operations

**Current state:** No agent has a rule about protecting async callbacks from rapid invocation.

**Rule to add to `Architect.md` or `Pixel.md`:**
```
### Async Callback Guards

Any `onPressed` callback that calls an async function (especially one that shows a modal/sheet/dialog) MUST have a guard flag:
- Add a `bool _isShowingX = false` state field.
- Check and set the flag at the start of the callback.
- Clear the flag in a `finally` block.
- This prevents double-tap, rapid-fire, and race condition issues.

Evidence: SESSION_PhaseB emulator — showSubmitRequestSheet called 9+ times in 1 second without debounce.
```

---

## 2. Rule Clarity Gaps

None found. All existing rules were followed correctly. The problems stemmed from missing rules, not unclear ones.

---

## 3. MCP Recommendations

### 3.1: Supabase MCP Server (Potential, Not Yet Evidenced)

**Pattern:** Agents manually inspect Supabase state from migration files and docs. No session log shows a failure from this — but `Supabase_Ops`, `ThreatModeler`, and `Sentinel` all require "confirm live DB objects exist." Currently they read migration SQL files as proxy.

**Recommendation:** Monitor. If future sessions show agents failing because migration files don't match deployed state, add Supabase MCP for live schema inspection.

**Threshold not met:** No session log failure attributable to missing live DB access.

---

## 4. Missing Skills

None identified. The existing 31 skills cover the work performed. The `supabase-migration` skill was not invoked because Phase B had no backend changes.

---

## 5. Agent Coordination Gaps

### 5.1: Architect ↔ Sentinel test handoff

**Gap:** When Architect adds methods to a ViewModel, Sentinel is not triggered to audit test mocks. The handoff is implicit — Sentinel only runs at phase end, not after each Architect change.

**Fix:** Add to Executor.md: "When @Architect changes a ViewModel public API, immediately invoke @Sentinel for test mock audit before proceeding."

### 5.2: Architect ↔ Pixel view-layer timing

**Gap:** Architect creates a ViewModel method that calls `notifyListeners()` synchronously. Pixel wires the view to call it during `didChangeDependencies`. Neither agent considers the timing interaction.

**Fix:** Architect should own the rule about `notifyListeners()` timing (Gap 1.3 above). Pixel should have a complementary rule: "When calling ViewModel methods during widget initialization, always use `addPostFrameCallback`."

---

## 6. Orchestrator Pipeline Improvements

### 6.1: Add "Runtime Smoke Test" as Stage 11.5

**Evidence:** Emulator testing found 2 bugs (setState during build, bid sheet spam) that all automated gates passed clean. The Orchestrator pipeline has no stage for runtime/emulator validation.

**Recommendation:** Add between Stage 11 (Sentinel) and Stage 12 (Orchestrator):

```
STAGE 11.5 ─── @Sentinel     Runtime smoke test (emulator or device)
```

This stage would:
- Run the app on emulator/device
- Exercise critical flows from the regression checklist
- Check console for Flutter framework errors
- Report any runtime issues not caught by static analysis or unit tests

**Priority:** MEDIUM — only needed for changes that touch UI flow or ViewModel state management.

---

## 7. New Agent Recommendations

None needed. The existing 15 agents cover all responsibilities. The gaps are in rules, not ownership.

---

## 8. Things the Human Missed

### 8.1: The `query.lt()` pagination bug

The B1 unawaited_futures fix wrapped `query.lt()` in `unawaited()`, which broke cursor-based pagination in 3 files (booking_service.dart x2, task_requests_service.dart x1). The human caught this during review — but neither the plan, the executor, nor any agent flagged that Supabase query builder methods return `PostgrestFilterBuilder` (which implements `Future`) and should NOT be wrapped in `unawaited()`.

**Rule to add to `Architect.md` or `Supabase_Ops.md`:**
```
### Supabase Query Builder Pattern

Supabase's Dart client uses a builder pattern where methods like `.eq()`, `.lt()`, `.gt()`, `.order()` return a `PostgrestFilterBuilder` that implements `Future`. These are NOT fire-and-forget futures — they are builder chain methods.

- NEVER wrap query builder methods in `unawaited()`.
- NEVER ignore their return value.
- Use `query = query.lt(...)` (reassign) or chain them fluently.
- The `unawaited_futures` lint is a FALSE POSITIVE for these methods. Use `// ignore: unawaited_futures` only if you cannot reassign (rare).

Evidence: Phase B wrapped query.lt() in unawaited(), breaking cursor pagination in 3 files.
```

---

## 9. Priority Action List

| Priority | Action | Agent(s) | Evidence |
|----------|--------|----------|----------|
| **P0** | Add Error vs Exception rule | Architect.md | Session log line 50, 22 |
| **P0** | Add Supabase query builder rule | Architect.md or Supabase_Ops.md | Emulator test: pagination broken |
| **P1** | Add test mock audit rule | Executor.md | Session log line 25 |
| **P1** | Add notifyListeners() timing rule | Architect.md | Emulator: setState during build |
| **P1** | Add sub-phase test gate | Executor.md | Session log: 20 late failures |
| **P2** | Add async callback guard rule | Architect.md or Pixel.md | Emulator: 9x bid sheet spam |
| **P2** | Add Architect↔Sentinel test handoff | Executor.md | Coordination gap |
| **P3** | Add runtime smoke test stage | Orchestrator.md | 2 bugs caught only on emulator |

---

## 10. Improvement Tracking

| Gap ID | Rule Text Written | Agent File | Status |
|--------|------------------|------------|--------|
| 1.1 | Error vs Exception (§3.2.1) | Architect.md | APPLIED (2026-04-02) |
| 1.2 | Test mock audit (Step 3.2) | Executor.md | APPLIED (2026-04-02) |
| 1.3 | notifyListeners timing (§3.4.1) | Architect.md | APPLIED (2026-04-02) |
| 1.4 | Sub-phase test gate (Step 3.1) | Executor.md | APPLIED (2026-04-02) |
| 1.5 | Async callback guards (§3.4.2) | Architect.md | APPLIED (2026-04-02) |
| 8.1 | Query builder pattern (§4.5) | Architect.md | APPLIED (2026-04-02) |
| P3 | Runtime smoke test (Stage 11.5) | Orchestrator.md | APPLIED (2026-04-02) |

---

## 11. Full Evidence Index

| Evidence | File | Lines |
|----------|------|-------|
| AssertionError not caught | `docs/LOG/SESSION_PhaseB_BugExposure_2026-04-01.md` | 50-53 |
| Missing mock stubs | `docs/LOG/SESSION_PhaseB_BugExposure_2026-04-01.md` | 70-71 |
| Agent mistake table | `docs/LOG/SESSION_PhaseB_BugExposure_2026-04-01.md` | 22-27 |
| Pre-existing H1/H2 | `.TODO/MASTER_REPORT_2026-04-01_PhaseAB.md` | 25-32 |
| setState during build | Emulator console log (2026-04-02) | TaskViewModel.loadCategories:61 |
| Bid sheet spam (9x) | Emulator console log (2026-04-02) | requests_list_screen FAB + CTA |
| query.lt() pagination | Human review + emulator test | booking_service.dart:38, task_requests_service.dart:295 |
| 20 test failures late | `docs/LOG/SESSION_PhaseB_BugExposure_2026-04-01.md` | Full timeline |
