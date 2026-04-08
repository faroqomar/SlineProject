# System Evolution Report — 2026-04-08

**Sessions Analysed:** 5 (GitHub_CI 04-04, Agent_CI 04-06, DesignSystemFoundation 04-07, CoreWidgetRedesign 04-07, Phase2_AppShellAuthCards 04-08)
**Previous Evolution Report:** 2026-04-07 (analysed 3 sessions)
**Agent Files Scanned:** 16 (all present in `.cursor/Agents/`)
**Most Common Failure Type:** Flutter API misuse / Dart lint violations (3 sessions)
**Most Frequently Flagged Agent:** @Pixel (7 of 10 total mistakes)
**Highest-Value Improvement:** Mandatory test run after StatefulWidget conversion
**MCP Servers Recommended:** 0 (no evidence threshold met)

---

## 1) Rule Gaps

### RG-1: No rule requiring immediate test run after StatefulWidget conversion
- **Evidence:** Phase2 session — @Executor converted MainNavigationScreen from StatelessWidget to StatefulWidget with AnimationControllers. 2 existing tests broke (T51 FAB, T52 tab switch) because they used `tester.pump()` instead of `pumpAndSettle()`. Found only in Phase 9 (6 phases later).
- **Also evidence:** CoreWidgetRedesign — ScaleTransition finder issues in tests after animation controllers added.
- **Sessions affected:** 2 (systemic)
- **Agent:** @Executor
- **Rule to add to `executor.md` section 3 (after 3.5):**

```
### 3.9 Widget Conversion Test Gate (Mandatory After StatefulWidget Conversion)

After converting ANY widget from StatelessWidget to StatefulWidget (or adding AnimationControllers to an existing StatefulWidget):

1. Run that widget's existing test file IMMEDIATELY — before proceeding to the next sub-phase.
2. If tests fail due to animation timing (common: `pump()` needs `pumpAndSettle()`), fix the tests in the same phase.
3. Log the test fix in the session log.

Do NOT defer test verification to the QA phase. Animation timing breaks are invisible to `flutter analyze` and only surface in tests.

Evidence: Phase 2 Session — MainNavigationScreen conversion broke T51/T52 tests. Caught only in Phase 9 (6 phases later). CoreWidgetRedesign — ScaleTransition finder issues after animation changes.
```

### RG-2: No rule for widget test finder best practices
- **Evidence:** CoreWidgetRedesign Phase 2 — `tester.widget<ColoredBox>(find.ancestor(...))` failed with multiple ancestors. Phase 4 — dual Opacity widgets confused test assertions.
- **Sessions affected:** 2 (systemic)
- **Agent:** @Sentinel (test author)
- **Rule to add to `Sentinel.md`:**

```
### Widget Test Finder Rules

When writing widget tests:
1. Prefer `find.bySemanticsLabel()` over deeply nested `find.ancestor()` chains.
2. For checking existence of a widget type in a subtree, use `widgetList.any()` instead of exact match.
3. Always verify constructor parameter names (positional vs named) by reading the source class before writing tests.
4. When testing widgets with animations, always use `pumpAndSettle()` — not raw `pump()` — unless testing mid-animation state.
5. If a finder returns multiple matches, narrow with `find.descendant()` + `find.byKey()` rather than making assumptions about widget tree depth.

Evidence: CoreWidgetRedesign — 7 test mistakes from finder fragility, constructor param errors, and animation timing.
```

### RG-3: No rule against logging high-frequency operations
- **Evidence:** DesignSystemFoundation — `respectMotion()` logged every animation call via `AppLogger.d()`, flooding console output.
- **Sessions affected:** 1 (incident, but important for observability discipline)
- **Agent:** @Observability
- **Rule to add to `Observability.md`:**

```
### Logging Frequency Rule

Never add AppLogger calls inside methods that execute per-frame or per-animation-tick (e.g., `respectMotion()`, `lerp()`, `build()` of frequently rebuilt widgets). Debug logging in these paths floods the console and degrades performance.

Log at the trigger point (e.g., "animation started") not the execution point (e.g., "frame computed").

Evidence: DesignSystemFoundation — respectMotion() logged every animation call, had to be removed.
```

---

## 2) Rule Clarity Gaps

### RC-1: @Pixel Flutter API verification rule exists but recurred in test code
- **Evidence:** Rule added to Pixel.md after DesignSystemFoundation (section 3.3). But CoreWidgetRedesign saw similar API issues in test files — SemanticsFlag API moved, Semantics getter assumptions wrong, const-with-non-const-child.
- **Cause:** The rule says "verify API before implementation" but doesn't explicitly cover test code. @Pixel may treat "implementation" as production code only.
- **Fix:** Amend Pixel.md section 3.3 to say:

```
This applies to BOTH production code AND test code. Widget test assertions that reference Flutter widget APIs (Semantics, finder APIs, Material components) must be verified against the current SDK version.
```

---

## 3) MCP Recommendations

**None this cycle.** No session log shows evidence that manual work or lack of live access caused failure beyond what file-system tools can handle. The previous evolution report's MCP recommendations (Supabase MCP for live DB verification) remain valid but no new evidence strengthens the case.

---

## 4) Missing Skills

### MS-1: No formal test migration skill when adding animations to existing widgets
- **Evidence:** 2 sessions had test failures after adding animations. The fix pattern is always the same: `pump()` → `pumpAndSettle()`, add `await tester.pumpAndSettle()` before assertions.
- **Recommendation:** Not a new skill, but a checklist step in @Executor (covered by RG-1 above).

---

## 5) Agent Coordination Gaps

### AC-1: Orchestrator Parallel Group B latent dependency
- **Finding:** Orchestrator §2.1 allows @Architect + @Pixel + @APIContract to run in parallel. However, @Pixel may need to know about ViewModel API changes found by @Architect (e.g., new methods that views should wire).
- **Sessions affected:** 0 (not yet triggered — parallel review has only run on Phase 0/DesignSystemFoundation which had no VM changes)
- **Risk:** LOW — only manifests when a session includes both VM and View changes.
- **Recommendation:** Add a note to Orchestrator §2.1: "If the scope includes ViewModel changes, run @Architect before @Pixel (sequentially), not in parallel."

### AC-2: @SlineDocs always last, always catching stale docs reactively
- **Evidence:** DesignSystemFoundation and Agent_CI sessions both had stale docs caught by @SlineDocs in the Orchestrator pipeline.
- **Pattern:** Docs drift is caught reactively (in review) rather than proactively (during execution).
- **Recommendation:** No agent change — the Executor already has a Phase 11 (Documentation Sync) in plans. The pattern is acceptable as long as the Orchestrator pipeline catches it.

### AC-3: Five agents have zero evidence-based rules
- **Agents:** @ThreatModeler, @Supabase_Ops, @APIContract, @DataMigration, @Sentinel
- **Cause:** These agents have not been the primary execution agent in any completed session on the current branch (all sessions have been UI-focused).
- **Risk:** When a backend-heavy session runs (RLS, schema, payment), these agents lack the learned-from-failure rules that @Pixel and @Executor have.
- **Recommendation:** Not actionable now — wait for backend sessions to generate evidence.

---

## 6) Orchestrator Pipeline Improvements

### OP-1: Add explicit Stage 11.5 skip criteria
- **Current:** Stage 11.5 (Runtime Smoke Test) says "Skip for docs-only or backend-only changes."
- **Evidence:** All 5 sessions have been code-change sessions, but Stage 11.5 has never actually been executed (no emulator testing in any session log).
- **Recommendation:** Either make Stage 11.5 mandatory for UI changes (with the human running the device test), or formalize it as "human-only step" that the Orchestrator requests but does not perform.

### OP-2: Session log closure enforcement
- **Evidence:** CoreWidgetRedesign session was never formally closed (Quick Summary and Agent Improvement Notes left as placeholders).
- **Recommendation:** Add to Executor.md:

```
### Session Log Closure Enforcement

If the session reaches the final phase or the user indicates work is complete, you MUST write the SESSION CLOSED entry, Quick Summary, and Agent Improvement Notes BEFORE presenting the final status to the user. Never leave these as template placeholders.

Evidence: CoreWidgetRedesign session — 9 phases completed but session log never formally closed, breaking SystemEvolution's ability to analyze it.
```

---

## 7) New Agent Recommendations

**None this cycle.** The current 16-agent system covers all domains that have appeared in session logs. No repeated work falls outside existing ownership.

---

## 8) Things the Human Missed

### TH-1: Pre-existing flaky test never investigated
- **Evidence:** 1 test failure persists across ALL 4 executed sessions (1195→1195→1282→1297 all with exactly 1 failure). Described variously as `wallet_shared_body_test` (Session 2) and `favorites_screen_test` (Sessions 3-5). This has been carried forward as "pre-existing" without investigation for at least 4 sessions.
- **Recommendation:** Investigate and fix in a dedicated mini-session. A permanently failing test erodes trust in the test suite.

### TH-2: 30 skipped tests never investigated
- **Evidence:** 30 tests skipped in every session. All appear to require Supabase integration (`--dart-define=SUPABASE_INTEGRATION=1`). Never run or discussed.
- **Recommendation:** Either set up a Supabase integration test environment or document these as "integration-only" and exclude from CI counts.

### TH-3: `AppColors.lightRed` used 70+ times across codebase
- **Evidence:** Phase 2 Orchestrator review found 70+ direct uses of `AppColors.lightRed` instead of `colorScheme.danger`. This is the largest design-system migration debt.
- **Recommendation:** Schedule a dedicated color migration session after Phase 2 stabilizes.

---

## 9) Priority Action List

| Priority | Action | Agent(s) | Evidence |
|----------|--------|----------|----------|
| **P1** | Add Widget Conversion Test Gate rule (RG-1) | @Executor | 2 sessions with animation test breaks |
| **P2** | Add Widget Test Finder Rules (RG-2) | @Sentinel | 2 sessions with finder fragility |
| **P3** | Clarify @Pixel API verification covers test code (RC-1) | @Pixel | Rule existed but recurred in tests |
| **P4** | Add Session Log Closure Enforcement (OP-2) | @Executor | CoreWidgetRedesign log never closed |
| **P5** | Add Logging Frequency Rule (RG-3) | @Observability | 1 session with console flooding |
| **P6** | Investigate pre-existing flaky test (TH-1) | Human | 4 sessions carrying failure |
| **P7** | Add Orchestrator parallel review guard for VM changes (AC-1) | @Orchestrator | Latent risk, 0 incidents |

---

## 10) Improvement Tracking

| Rule/Change | Added After Session | Verified In Session | Status |
|-------------|--------------------|--------------------|--------|
| Token Value Intentionality Check (Executor 3.8) | DesignSystemFoundation | Phase2 (no recurrence) | EFFECTIVE |
| Plan Critique Review (Executor 3.9) | DesignSystemFoundation | Phase2 (critique read and applied) | EFFECTIVE |
| Flutter API Verification (Pixel 3.3) | DesignSystemFoundation | CoreWidgetRedesign (recurred in test code) | PARTIALLY EFFECTIVE — needs RC-1 clarification |
| Per-Sub-Phase Test Gate (Executor 3.5) | Referenced from PhaseC/D | Phase2 (tests run between phases) | EFFECTIVE |
| Raw String Sweep (Executor 3.6) | Referenced from PhaseE | Phase2 (sweep run, 0 bugs found) | EFFECTIVE |
| CI Guard Exclusion Review (Executor 3.7) | Referenced from PhaseD | Not yet triggered | UNTESTED |

---

## 11) Full Evidence Index

| Session | Date | File | Mistakes | Problems | Deviations |
|---------|------|------|----------|----------|------------|
| GitHub_CI | 04-04 | `docs/LOG/SESSION_PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md` | 0 | 0 | 0 |
| Agent_CI | 04-06 | `docs/LOG/SESSION_PLAN_Agent_CI_RepoSafeguards_2026-04-06.md` | 0 | 0 | 0 |
| DesignSystem | 04-07 | `docs/LOG/SESSION_PLAN_DesignSystemFoundation_2026-04-07.md` | 6 | 0 | 0 |
| CoreWidget | 04-07 | `docs/LOG/SESSION_PLAN_CoreWidgetRedesign_2026-04-07.md` | 7 | 0 | 0 |
| Phase2 | 04-08 | `docs/LOG/SESSION_PLAN_Phase2_AppShellAuthCards_2026-04-08.md` | 1 | 1 | 0 |
| **Totals** | | | **14** | **1** | **0** |

Previous Evolution Report: `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-07.md`

---

**END OF REPORT**
