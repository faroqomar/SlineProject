# System Evolution Report - 2026-04-30

## Summary

- Sessions analysed: all `docs/LOG/SESSION_*.md` files with indexed problem, mistake, quick-summary, and improvement-note entries.
- Primary evidence session: `docs/LOG/SESSION_HomeDiscoveryNavConsolidation_2026-04-30.md`.
- Most common failure type in this run: test/planning specificity gaps.
- Most frequently affected agents: `@Planner`, `@PlanCritic`, `@Executor`, `@Sentinel`, `@CodeGuard`.
- Highest-value improvement: force concrete validation of plan skill labels, command paths, and route-push widget-test harnesses before execution.
- MCP servers recommended: none. The observed failures were rule/process gaps, not missing live-tool access.
- New agents recommended: none.

## Rule Gaps Merged

### 1. Concrete skill label validation

- Evidence: `SESSION_HomeDiscoveryNavConsolidation_2026-04-30.md` logged a pre-execution problem where the corrected plan used generic UI skill labels instead of concrete `.cursor/skills/` names.
- Change merged:
  - `Planner.md`: plans must validate every `Skill:` value against `.cursor/skills/<name>/SKILL.md`.
  - `PlanCritic.md`: UI / Integration Gate must fail unresolved skill labels.
  - `Executor.md`: pre-execution validation must stop when a `Skill:` label does not resolve.

### 2. Planned command path validation

- Evidence: the session log recorded that the plan listed `integration_test/create_tender_task_flow_test.dart`, while the repo path was `test/integration_test/create_tender_task_flow_test.dart`.
- Change merged:
  - `Planner.md`: test-heavy plans must validate planned command paths or create them first.
  - `PlanCritic.md`: Gate 0 blocks missing command paths.
  - `Executor.md`: pre-execution validation checks file paths used by planned commands.

### 3. Analyzer baseline recording

- Evidence: full `flutter analyze` failed on unrelated pre-existing chat issues, discovered during execution instead of as a baseline.
- Change merged:
  - `Executor.md`: if full analyzer is a gate, record baseline before edits; if dirty, log exact pre-existing findings and require scoped analyzer on changed files.

### 4. Route-push widget-test isolation

- Evidence: gap-completion and Orchestrator passes found the Home route-push test was initially over-coupled to real `TaskDetailsScreen` backend-dependent loading.
- Change merged:
  - `Planner.md`: route-push tests must define Provider scope above `MaterialApp` or a test-only route-builder seam.
  - `PlanCritic.md`: Gate 0 blocks route-push tests without Provider/screen isolation strategy.
  - `QA.md`: route-push widget tests should avoid unrelated backend-dependent destinations.
  - `CodeReviewer.md`: review must flag route-push tests over-coupled to destination internals.

### 5. Delayed tap wrappers and observer assumptions

- Evidence: gap-completion tests failed because `ScaleButton` left a delayed timer pending and the NavigatorObserver expectation assumed the initial route counted as a push.
- Change merged:
  - `Planner.md`: test plans must account for delayed callback wrappers.
  - `PlanCritic.md`: Gate 0 blocks missing delayed-callback test timing.
  - `QA.md`: widget finder/test rules now require pumping past `ScaleButton.callbackDelay` and avoiding observer initial-route assumptions.
  - `CodeReviewer.md`: test quality review now checks delayed tap wrappers and NavigatorObserver assumptions.

### 6. Navigation index contract robustness

- Evidence: the Orchestrator Master Report found fallback normalization did not reset provider state for visible indexes invalid for a short override screen list.
- Change merged:
  - `CodeReviewer.md`: compatibility review now checks named destination constants and provider-state normalization for screen-list/route overrides.

### 7. Orchestrator fix authorization ambiguity

- Evidence: user requested Orchestrator review and immediate BLOCKER/HIGH/MED fixes, while `Orchestrator.md` previously required a separate human approval after Stage 12.
- Change merged:
  - `Orchestrator.md`: explicit same-request fix authorization allows Stage 13 after the Master Report is produced.

### 8. SystemEvolution edit authorization ambiguity

- Evidence: user explicitly asked to run SystemEvolution and merge findings into agent files, while `SystemEvolution.md` previously forbade direct edits.
- Change merged:
  - `SystemEvolution.md`: report-only remains default; explicit human merge authorization permits deduped edits to agent files.

## Dedupe Notes

- No new Supabase, storage, MVVM, or AppLogger rules were added because equivalent rules already existed in `Architect.md`, `BackendOps.md`, `Executor.md`, `QA.md`, and `CodeReviewer.md`.
- No new generic UI skill-tag rule was added because `Planner.md`, `Executor.md`, `UIDesigner.md`, and `QA.md` already required skill-tagged UI work. Only concrete label resolution was added.
- No new broad widget finder rule was added because `QA.md` already covered semantics finders, nested scrollables, and infinite animations. Only the newly evidenced route-push, delayed callback, and observer-count hazards were added.

## Files Updated

- `.cursor/Agents/Planner.md`
- `.cursor/Agents/PlanCritic.md`
- `.cursor/Agents/Executor.md`
- `.cursor/Agents/Sentinel.md`
- `.cursor/Agents/CodeGuard.md`
- `.cursor/Agents/Orchestrator.md`
- `.cursor/Agents/SystemEvolution.md`

## Priority Action List

1. Use the new concrete skill-label validation in the next UI-heavy plan.
2. Use the new planned command path validation before every test-heavy execution.
3. Keep route-push widget tests scoped to the route behavior unless the destination is explicitly under test.
4. Continue recording dirty analyzer baselines separately from changed-file analyzer results.

## Full Evidence Index

- `docs/LOG/SESSION_HomeDiscoveryNavConsolidation_2026-04-30.md`
  - Pre-execution skill-label problem.
  - Missing integration-test command path problem.
  - Dirty full-analyzer baseline problem.
  - Gap-scan findings for metadata, bottom-nav index contract, stale integration wording, missing tests.
  - Route-push observer-count, delayed timer, provider-scope test problems.
  - Orchestrator Master Report findings MED-1 and MED-2.
- `.TODO/Archive/HomeDiscoveryNavConsolidation_2026-04-30/MASTER_REPORT_2026-04-30_HomeDiscoveryNavConsolidation.md`
  - Fixed MED-1 route-push test coupling.
  - Fixed MED-2 fallback normalization.
