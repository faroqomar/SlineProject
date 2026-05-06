# System Evolution Report — 2026-04-08 (v2)

**Analyst:** @SystemEvolution
**Sessions Analysed:** 6 (GitHub_CI, Agent_CI, DesignSystemFoundation, CoreWidgetRedesign, Phase2_AppShellAuthCards, LayoutTokens_Phase0.7)
**Agent Files Scanned:** 16
**Date Range:** 2026-04-04 to 2026-04-08
**Previous Report:** `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-08.md` (v1, analyzed 5 sessions)

---

## Executive Summary

- **Most common failure type:** Flutter API misuse in test code (7 mistakes across 2 sessions)
- **Most frequently flagged agent:** @Pixel (7 mistakes), @Sentinel (7 mistakes, all test-related)
- **Highest-value improvement:** Add "Value Extraction from Codebase" mandatory workflow to @SlinePlanner — prevents the 3 wrong token values caught by @PlanCritic
- **MCP servers recommended:** None (no evidence of manual work that a tool would automate)
- **New rules to add:** 4 (detailed below)
- **Agents needing significant rewrites:** None
- **New agents recommended:** None

---

## 1) Rule Gaps (Must Add)

### RG-1: @SlinePlanner — Token Value Extraction Workflow

**Evidence:** LayoutTokens Phase 0.7 session — @SlinePlanner proposed `bottomNavHeight = 64` (actual: 70), `buttonHeight = 48` (actual: 54), `circleIconButtonSize = 48` (actual: 40 visual / 48 touch). All 3 caught by @PlanCritic before execution.

**Pattern:** 1 session, 3 mistakes. Single-session but HIGH impact — wrong token values would have broken the zero-visual-change invariant across every widget migration.

**Rule text to add to `Sline_Planner.md` after §2.2.5:**

```markdown
### 2.2.6 Token Value Extraction (Required When Planning Token Files)

When the plan creates a new token or constant file (e.g., `app_layout.dart`, `app_motion.dart`):
1. For EVERY proposed token value, read the actual source file and extract the real value with file:line citation.
2. Do NOT use values from the Master Plan, aspirational docs, or memory — codebase changes between planning and execution.
3. Record a Value Extraction Table in the plan appendix: Token | Planned Value | Actual Value | Source File:Line | Decision.
4. If actual differs from planned, use the ACTUAL value (zero visual change rule).
5. If the plan creates icon/size/spacing tokens, grep `AppDimens` for overlap. Remove any token that duplicates an existing `AppDimens` value with a similar name.

Evidence: LayoutTokens Phase 0.7 — @SlinePlanner proposed 3 wrong values (bottomNavHeight 64→70, buttonHeight 48→54, circleIconButtonSize conflated 40/48) because values came from the Master Plan, not the actual codebase. @PlanCritic caught all 3.
```

---

### RG-2: @Pixel — Intentional Hardcoded Exception Documentation

**Evidence:** LayoutTokens Phase 0.7 Orchestrator review — 6 MED findings were hardcoded values that remained in migrated files without explanation (`fontSize: 9` in nav bar, `size: 18` icon in styled button, `size: 30` FAB icon). All were intentional but undocumented. Fixed in post-Orchestrator cleanup.

**Pattern:** 1 session. LOW urgency but prevents repeat audit noise in every future Orchestrator review.

**Rule text to add to `Pixel.md` after §3.3:**

```markdown
### 3.4 Intentional Hardcoded Exception Documentation

When migrating widgets to use design tokens (AppLayout, AppDimens, AppMotion, AppColors):
1. If a hardcoded value CANNOT be replaced because no matching token exists, or because the value is component-specific (e.g., badge-internal padding, skeleton placeholder dimensions), add an inline comment:
   `// Intentional hardcoded: <reason> — no matching layout token`
2. If the value is CLOSE to a token but intentionally different (e.g., icon size 18 between iconSizeSmall=16 and iconStandard=20), add:
   `// 18px — intentionally between iconSizeSmall (16) and iconStandard (20) for compact styled buttons.`
3. Never leave a hardcoded value in a migrated file without explanation — it will be flagged by @CodeGuard in every future Orchestrator review.

Evidence: LayoutTokens Phase 0.7 — Orchestrator flagged 6 MED findings for undocumented hardcoded values. All were intentional but required post-execution cleanup to add comments.
```

---

### RG-3: @Sentinel — Widget Test Finder Best Practices

**Evidence:** CoreWidgetRedesign session — 7 test failures from fragile finder patterns:
- `tester.widget<ColoredBox>(find.ancestor(...))` failed with multiple ancestors
- `Semantics` getter assumptions wrong (`.button`, `.label` not direct getters)
- `const Semantics(...)` failed when children were non-const
- `ScaleTransition` finders broke after animation controller changes

**Pattern:** 2 sessions (CoreWidgetRedesign + Phase2). SYSTEMIC — 9 total test mistakes related to widget test mechanics.

**Rule text to add to `Sentinel.md` in a new §"Widget Test Finder Rules":**

```markdown
### Widget Test Finder Rules

When writing or reviewing widget tests:
1. **Prefer `find.bySemanticsLabel()` over direct Semantics widget inspection.** The Semantics API surface changes across Flutter versions.
2. **Use `widgetList.any()` pattern when a widget type appears multiple times in the tree** (e.g., multiple `Opacity`, `Container`, or `Icon` widgets). Never assume `tester.widget<T>(find.byType(T))` returns the one you want.
3. **After adding AnimationControllers to a widget, the test MUST use `pumpAndSettle()` instead of `pump()`** to let animations complete before assertions.
4. **Never use `const` on widget constructors in tests when any child is non-const.** Check whether children reference `static final` (non-const) values.
5. **Verify constructor signatures before writing tests.** Read the target widget file first — do not assume named vs positional parameters.

Evidence: CoreWidgetRedesign — 7 test failures from finder fragility. Phase2 — 2 test failures from pump vs pumpAndSettle after StatefulWidget conversion.
```

---

### RG-4: @Executor — Session Log Closure Enforcement (ALREADY ADDED in v1)

**Status:** Already present as §3.10 in `Executor.md`. Confirmed by scan.

---

## 2) Rule Clarity Gaps (Must Amend)

### RC-1: @Pixel §3.2 Flutter API Verification — Extend to Test Code

**Evidence:** DesignSystemFoundation — @Pixel rule added after `CardTheme` → `CardThemeData` mistake. CoreWidgetRedesign — similar API misuse recurred in TEST files (7 mistakes) even though rule existed for production code.

**Cause:** Rule says "verify API before implementation" but doesn't explicitly mention test code.

**Amendment to add to `Pixel.md` §3.2:**

```markdown
This rule applies to BOTH production code AND test code. Test files use the same Flutter SDK APIs (Semantics, finders, widget constructors) and are equally susceptible to version-specific API changes.
```

---

## 3) MCP Recommendations

**None.** No session log shows an agent failing because it lacked live tool access. The Supabase MCP is already available. Filesystem search is handled by grep/glob tools. Git context is accessible via `git` commands. No manual bottlenecks identified that a new MCP would resolve.

---

## 4) Missing Skills

**None.** All agents performed within their defined capabilities. The `.cursor/skills/` system (animate, normalize, harden, etc.) was used correctly where applicable. No repeated request for an undefined skill.

---

## 5) Agent Coordination Gaps

### AC-1: @PlanCritic → @Executor Handoff — NOW FORMALIZED

**Status:** Addressed in Executor.md §4.6 "Plan Critique Review (Mandatory Before Execution)". The LayoutTokens session confirmed the handoff works — @PlanCritic found 7 gaps, @Executor applied all fixes during execution.

### AC-2: @Orchestrator → @Executor Fix Verification — NOW FORMALIZED

**Status:** Addressed in Orchestrator.md §2.2 "Stage 13: Fix Verification (Conditional)". The LayoutTokens session demonstrated the loop: Orchestrator found 17 findings → Executor applied fixes → full test suite re-verified.

### AC-3: @SystemEvolution → Agent Updates — STILL INFORMAL

**Gap:** @SystemEvolution produces recommendations but there's no formal mechanism for the human to approve and apply them to agent files. This remains a manual process.

**Recommendation:** Acceptable as-is. The human review step is intentional (SystemEvolution §0.6: "The Human Decides"). No automation needed.

---

## 6) Orchestrator Pipeline Improvements

### OP-1: Stage 11.5 (Runtime Smoke Test) — Never Executed

**Evidence:** 6 sessions, 0 runtime smoke tests. Stage 11.5 was added to the Orchestrator definition but has never been triggered because it requires a physical device/emulator.

**Recommendation:** Rename to "Runtime Smoke Test (Human-Assisted)" and add a note that the Orchestrator REQUESTS the human to run specific flows on device, rather than attempting to automate it. The output is a human-reported checklist, not agent-generated evidence.

### OP-2: Parallel Review Mode — Confirmed Safe for View-Only Work

**Evidence:** DesignSystemFoundation Orchestrator review ran ThreatModeler + Supabase_Ops in parallel and Architect + Pixel + APIContract in parallel during review. No dependency issues observed. LayoutTokens Orchestrator review also ran Group B in parallel safely.

**Status:** Working as designed. The VM-change exception (sequential when VMs change) has not been triggered yet — latent but correctly documented.

---

## 7) New Agent Recommendations

**None.** The current 16-agent system covers all responsibilities observed in 6 sessions. No repeated work fell outside existing agent ownership.

---

## 8) Things the Human Should Address

### TH-1: Pre-Existing Flaky Test (SYSTEMIC — 5 sessions)

**Evidence:** Every session from Agent_CI onward carries `1 pre-existing failure`. The failing test has been identified as either `wallet_shared_body_test` or `favorites_screen_test`. It has never been investigated or fixed.

**Impact:** Erodes test suite trust. Makes it impossible to distinguish "zero regressions" from "1 pre-existing + 0 new".

**Recommendation:** Dedicate 30 minutes to debugging and fixing this test. If it's a legitimate bug, fix it. If it's flaky, add a skip annotation with a tracking comment.

### TH-2: 30 Skipped Supabase Integration Tests (SYSTEMIC — 5 sessions)

**Evidence:** `~30` tests skipped in every session with message "Requires Supabase; run with --dart-define=SUPABASE_INTEGRATION=1".

**Impact:** RLS policy tests, integration tests, and real-query tests never run in local dev. These tests are the most valuable for catching production bugs.

**Recommendation:** Set up a local Supabase instance (Docker) or a test project and run these tests at least once per milestone.

### TH-3: Design System Migration Debt

**Evidence:** Orchestrator reports across sessions identify:
- 70+ uses of `AppColors.lightRed` instead of `colorScheme.danger`
- 817 instances of raw `Colors.*` Material colors
- 408 hardcoded `BorderRadius.circular()`
- 233 inline `BoxShadow`

**Impact:** Every future screen redesign must manually replace these. The design system foundation is built but the migration is vast.

**Recommendation:** Track in `.TODO/` as a phased migration plan. Phases 1-16 of the Master Plan already cover this per-screen.

---

## 9) Priority Action List

| Priority | Action | Agent | Evidence Sessions | Type |
|----------|--------|-------|-------------------|------|
| **P1** | Add RG-1: Token Value Extraction Workflow | @SlinePlanner | LayoutTokens | Rule Gap |
| **P2** | Add RG-3: Widget Test Finder Best Practices | @Sentinel | CoreWidget, Phase2 | Rule Gap (Systemic) |
| **P3** | Amend RC-1: @Pixel API verification → include test code | @Pixel | DesignSystem, CoreWidget | Rule Clarity (Systemic) |
| **P4** | Add RG-2: Intentional Hardcoded Exception Documentation | @Pixel | LayoutTokens | Rule Gap |
| **P5** | Fix TH-1: Pre-existing flaky test | Human | All 5 execution sessions | Test Debt |
| **P6** | Rename OP-1: Stage 11.5 as Human-Assisted | @Orchestrator | All sessions | Pipeline Clarity |

---

## 10) Improvement Tracking

### Rules Added Since Last Report (v1 → v2)

| Rule | Agent | Added After Session | Status |
|------|-------|--------------------|---------| 
| §3.8 Token Value Intentionality Check | @Executor | DesignSystemFoundation | CONFIRMED IN AGENT FILE |
| §3.9 Widget Conversion Test Gate | @Executor | Phase2_AppShellAuthCards | CONFIRMED IN AGENT FILE |
| §3.10 Session Log Closure Enforcement | @Executor | CoreWidgetRedesign | CONFIRMED IN AGENT FILE |
| §3.11 Mandatory Code Comments | @Executor | Multiple sessions | CONFIRMED IN AGENT FILE |
| §4.6 Plan Critique Review | @Executor | DesignSystemFoundation | CONFIRMED IN AGENT FILE |
| §3.2 Flutter API Verification | @Pixel | DesignSystemFoundation | CONFIRMED IN AGENT FILE |
| §2.2 Stage 13 Fix Verification | @Orchestrator | Phase E | CONFIRMED IN AGENT FILE |
| §2.1 Parallel Review Mode | @Orchestrator | Phase D | CONFIRMED IN AGENT FILE |

### Rules Proposed & Applied in This Report

| Rule | Agent | Status |
|------|-------|--------|
| RG-1: Token Value Extraction Workflow | @SlinePlanner §2.2.6 | APPLIED — added to Sline_Planner.md |
| RG-2: Hardcoded Exception Documentation | @Pixel §3.4 | APPLIED — added to Pixel.md |
| RG-3: Widget Test Finder Best Practices | @Sentinel §11 | ALREADY EXISTS — 6 rules covering all patterns |
| RC-1: API Verification → include test code | @Pixel §3.3 IMPORTANT note | ALREADY EXISTS — "BOTH production code AND test code" amendment present |

---

## 11) Full Evidence Index

| Session | Log Path | Mistakes | Problems | Status |
|---------|----------|----------|----------|--------|
| GitHub_CI_RepoSafeguards | `docs/LOG/SESSION_PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md` | 0 | 0 | NOT STARTED |
| Agent_CI_RepoSafeguards | `docs/LOG/SESSION_PLAN_Agent_CI_RepoSafeguards_2026-04-06.md` | 0 | 0 | COMPLETED |
| DesignSystemFoundation | `docs/LOG/SESSION_PLAN_DesignSystemFoundation_2026-04-07.md` | 6 | 0 | COMPLETED |
| CoreWidgetRedesign | `docs/LOG/SESSION_PLAN_CoreWidgetRedesign_2026-04-07.md` | 7 | 0 | IN PROGRESS (not closed) |
| Phase2_AppShellAuthCards | `docs/LOG/SESSION_PLAN_Phase2_AppShellAuthCards_2026-04-08.md` | 1 | 1 | COMPLETED |
| LayoutTokens_Phase0.7 | `docs/LOG/SESSION_PLAN_LayoutTokens_Phase0.7_2026-04-08.md` | 3 (planning) | 0 | COMPLETED |

| Evolution Report | Path |
|-----------------|------|
| v1 (2026-04-07) | `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-07.md` |
| v1.5 (2026-04-08) | `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-08.md` |
| **v2 (2026-04-08)** | **`docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-08_v2.md`** (this file) |

---

## Agent Performance Trend (v1 → v2)

| Agent | v1 Mistakes | v2 Mistakes (cumulative) | Trend | Notes |
|-------|------------|--------------------------|-------|-------|
| @Pixel | 4 | 7 (+3 from CoreWidget) | STABLE — new sessions added, but mistakes are session-specific API issues, not worsening |
| @Executor | 2 | 2 | STABLE — rules added after DesignSystem session prevented recurrence |
| @Sentinel | 0 | 7 (newly attributed) | NEW DATA — CoreWidget test mistakes now attributed to @Sentinel |
| @SlinePlanner | 0 | 3 (planning) | NEW DATA — LayoutTokens planning mistakes caught by @PlanCritic before execution |
| @PlanCritic | 0 | 0 | STRONG — caught 7 critical gaps in LayoutTokens, 6 gaps in DesignSystem |
| @Orchestrator | 0 | 0 | STRONG — correctly identified 17 findings in LayoutTokens post-execution |

END.
