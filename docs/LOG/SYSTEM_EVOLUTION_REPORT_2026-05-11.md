# System Evolution Report - 2026-05-11

Scope: all `docs/LOG/SESSION_*.md` logs, all `.cursor/Agents/*.md` files, and core SLINE docs.

## Executive Summary

- Sessions analysed: 13.
- Most common failure type: verification and implementation-hygiene gaps around analyzer timing, import edits, widget-test harnesses, and token value provenance.
- Most frequently flagged agent: `@Pixel`, followed closely by `@Executor` and `@Planner`.
- Highest-value improvement: make token/design-system planning evidence-based and force public entry-point files to be created first for file-contract work.
- MCP servers recommended: none. The logs did not show a repeated failure that requires a new MCP server beyond existing repo search, Supabase, browser/emulator, and command-line verification patterns.
- Agents needing significant rewrites: none.
- New agents recommended: none.

## Sessions Analysed

- `docs/LOG/SESSION_HomeDiscoveryNavConsolidation_2026-04-30.md`
- `docs/LOG/SESSION_PLAN_Agent_CI_RepoSafeguards_2026-04-06.md`
- `docs/LOG/SESSION_PLAN_CoreWidgetRedesign_2026-04-07.md`
- `docs/LOG/SESSION_PLAN_DesignSystemFoundation_2026-04-07.md`
- `docs/LOG/SESSION_PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md`
- `docs/LOG/SESSION_PLAN_LayoutTokens_Phase0.7_2026-04-08.md`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_2026-05-10.md`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`
- `docs/LOG/SESSION_PLAN_Phase2_AppShellAuthCards_2026-04-08.md`
- `docs/LOG/SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md`
- `docs/LOG/SESSION_PLAN_Phase5_ChatDashboardNotifications_2026-04-09.md`
- `docs/LOG/SESSION_PLAN_Phase6_ChatAdvancedInteractions_2026-04-10.md`
- `docs/LOG/SESSION_PLAN_Phase7_DashboardCommandCenter_2026-04-10.md`

## Rule Gaps

### 1. Token values were planned from intent instead of extracted reality

Evidence:

- `SESSION_PLAN_LayoutTokens_Phase0.7_2026-04-08.md:27-29` records wrong token values, duplicate icon-size semantics, and over-scoped skeleton migration.
- `SESSION_PLAN_DesignSystemFoundation_2026-04-07.md:23-24` records motion token value drift without documented rationale.

Merged rules:

- `Planner.md`: added token/constants value extraction workflow.
- `PlanCritic.md`: added token/design-system plan checks.

### 2. UI implementation pitfalls were not centralized in Pixel

Evidence:

- `SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md:38-39` records a sliver wrapped in non-sliver `Semantics` and inherited-widget access from `initState()`.
- `SESSION_PLAN_Phase2_AppShellAuthCards_2026-04-08.md:38` records animation-related test failures after converting `MainNavigationScreen` to `StatefulWidget`.
- `SESSION_PLAN_Phase6_ChatAdvancedInteractions_2026-04-10.md:19-20` records regex behavior assumptions that needed edge-case tests.
- `SESSION_PLAN_DesignSystemFoundation_2026-04-07.md:19-22` records analyzer failures from unused imports, local type annotation lint, Flutter Material API mismatch, and const/non-const token misuse.

Merged rules:

- `Pixel.md`: added a prior-session UI pitfalls section and verification checks for analyzer/import/orphan hygiene.
- `CodeGuard.md`: added review checks for import removal, orphan locals, and regex edge-case coverage.

### 3. Executor lacked compact gates for file-contract sequencing and refactor hygiene

Evidence:

- `SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md:19` records a worker closing before creating the public token entry point and planned files.
- `SESSION_PLAN_Phase5_ChatDashboardNotifications_2026-04-09.md:19-20` records missing and unused imports.
- `SESSION_PLAN_Phase7_DashboardCommandCenter_2026-04-10.md:19-20` records import removal without checking type signatures and an orphan local variable.
- `SESSION_HomeDiscoveryNavConsolidation_2026-04-30.md:233-252` records route-push, timer-pump, provider placement, and Supabase test-helper misses.

Merged rules:

- `Executor.md`: added path/skill validation, baseline gate capture, public entry-point-first sequencing, import/const/orphan hygiene, and UI runtime test-pattern gates.

### 4. Planning and execution needed concrete path and skill validation

Evidence:

- `SESSION_HomeDiscoveryNavConsolidation_2026-04-30.md:198-202` records skill-label drift, command-path drift, and dirty analyzer baseline discovery.

Merged rules:

- `Planner.md`: added skill-tag validation and scan-evidence requirements for path validation.
- `Executor.md`: added pre-execution validation for planned paths and skill tags, plus baseline gate reporting.
- `PlanCritic.md`: added audit check for path and skill validation.

### 5. Manual UI/nav evidence needed a durable place

Evidence:

- `SESSION_HomeDiscoveryNavConsolidation_2026-04-30.md:203` says browser smoke evidence is useful for navigation work and should include local run URL and observed log events.

Merged rule:

- `Sentinel.md`: manual QA for navigation/app-shell changes must record local run target or emulator/device plus observed route/tab/log events.

## Rule Clarity Gaps

### Session log Agent Improvement Notes

Evidence:

- `SESSION_PLAN_CoreWidgetRedesign_2026-04-07.md:15-20` and `SESSION_PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md:15-20` contain template-placeholder improvement tables.

Deduped result:

- No new edit. `Executor.md` already has a hard requirement to fill `Agent Improvement Notes` and cites prior evidence. Adding another rule would duplicate existing coverage.

### Coverage arithmetic and coverage floors

Evidence:

- Later session work surfaced coverage arithmetic drift, but coverage verification is already covered in `Planner.md` and `PlanCritic.md`.

Deduped result:

- No new edit. Existing Planner/PlanCritic rules already require parsing `coverage/lcov.info` and verifying coverage arithmetic.

## MCP Recommendations

None.

Rationale: logs show manual scanning and verification work, but no repeated failure caused by missing MCP capability. Existing commands, repo search, Supabase reality checks, and browser/emulator smoke steps cover the observed gaps. The threshold for adding new MCP recommendations was not met.

## Missing Skills

None.

The failures were rule and verification gaps in existing agents, not a missing agent or skill domain.

## Agent Coordination Gaps

### File-contract dependencies between parallel workers

Evidence:

- `SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md:19` shows a dependent token namespace was incomplete when a worker closed.

Merged result:

- `Executor.md` now requires public entry-point/barrel/contract files first for file-contract tasks.
- `PlanCritic.md` now flags missing public entry-point-first sequencing in token/design-system plans.

## Orchestrator Pipeline Improvements

No direct Orchestrator edit was needed. The Orchestrator already has runtime smoke and Master Report stages. The required changes belonged to Sentinel's manual QA evidence and Executor's pre/post implementation gates.

## New Agent Recommendations

None.

The current agent set covers planning, critique, execution, UI, architecture, QA, docs, and review. The observed issues fit existing agent ownership after rule additions.

## Things The Human Missed

- Two session logs still have placeholder Agent Improvement Notes; future SystemEvolution accuracy depends on filled tables.
- Some LOW review findings from Amber Dusk Step 6 remain deliberately deferred, especially local `.codex/config.toml` staging risk and future SafeArea/MediaQuery adapter work.
- The current SystemEvolution file originally forbade edits even when the human explicitly requests merging. That was clarified to allow explicit merge runs after the report.

## Priority Action List

1. Done: add token value extraction and token-plan audit rules to Planner/PlanCritic.
2. Done: add Pixel UI pitfall checks from prior sessions.
3. Done: add Executor file-contract-first and implementation hygiene gates.
4. Done: add Sentinel navigation smoke evidence requirement.
5. Done: add CodeGuard import/orphan/regex review checks.
6. Done: clarify SystemEvolution behavior for explicit human-requested merge runs.

## Improvement Tracking

Merged agent files:

- `.cursor/Agents/Planner.md`
- `.cursor/Agents/PlanCritic.md`
- `.cursor/Agents/Pixel.md`
- `.cursor/Agents/Executor.md`
- `.cursor/Agents/Sentinel.md`
- `.cursor/Agents/CodeGuard.md`
- `.cursor/Agents/SystemEvolution.md`

Deduped, no edit:

- `Orchestrator.md` already owns Master Report and runtime-smoke stage.
- `DocsKeeper.md` already owns docs sync and reference validation; no recurring docs-specific rule gap met the threshold.
- Coverage arithmetic was already covered in Planner and PlanCritic.
- Session-log improvement-table completion was already covered in Executor.

## Full Evidence Index

- `docs/LOG/SESSION_PLAN_LayoutTokens_Phase0.7_2026-04-08.md:27-29` - Planner token value, duplicate token, and migration-scope mistakes.
- `docs/LOG/SESSION_PLAN_DesignSystemFoundation_2026-04-07.md:19-24` - Pixel analyzer/API/const issues and Executor token drift rationale misses.
- `docs/LOG/SESSION_PLAN_Phase2_AppShellAuthCards_2026-04-08.md:38` - Stateful animation test failures requiring immediate widget tests/settling.
- `docs/LOG/SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md:38-39` - sliver wrapper and inherited-widget lifecycle errors.
- `docs/LOG/SESSION_PLAN_Phase5_ChatDashboardNotifications_2026-04-09.md:19-20` - missing and unused imports.
- `docs/LOG/SESSION_PLAN_Phase6_ChatAdvancedInteractions_2026-04-10.md:19-20` - regex assumptions requiring edge-case tests.
- `docs/LOG/SESSION_PLAN_Phase7_DashboardCommandCenter_2026-04-10.md:19-20` - import removal and orphan variable checks.
- `docs/LOG/SESSION_HomeDiscoveryNavConsolidation_2026-04-30.md:198-203` - skill/path/analyzer baseline/browser-smoke process lessons.
- `docs/LOG/SESSION_HomeDiscoveryNavConsolidation_2026-04-30.md:233-252` - route-push harness, timer pump, provider placement, and Supabase test-helper issues.
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md:19` - public token entry point missing from interrupted worker output.
- `docs/LOG/SESSION_PLAN_CoreWidgetRedesign_2026-04-07.md:15-20` - placeholder improvement table, deduped against existing Executor rule.
- `docs/LOG/SESSION_PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md:15-20` - placeholder improvement table, deduped against existing Executor rule.
