# System Evolution Report v3 — 2026-04-04

**Sessions Analysed:** 3 execution sessions + 2 prior evolution reports
**Agent Files Scanned:** 16/16
**Core Docs Scanned:** DEVELOPER_GUIDE, SUPABASE_SETUP, STRUCTURE, CODE_REVIEW, MVP_ROADMAP

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Sessions analysed | 3 (Phase B, Phase C, Phase D) |
| Total issues across all sessions | 27 |
| Resolved | 25 |
| Unresolved / deferred | 2 |
| Most common failure type | **Constructor DI / initialization gaps** (4 occurrences across 3 sessions) |
| Most frequently flagged agent | **@Architect** (3 mistakes across 2 sessions) |
| Highest-value improvement | **Executor: run platform builds after adding native deps** |
| MCP servers recommended | 0 (insufficient evidence for tool-based automation) |
| New rules to add | 6 |
| Agents needing rewrites | 0 |
| New agents recommended | 0 |

---

## 1) Rule Gaps

### Gap 1.1: Executor lacks native dependency build gate

**Evidence:** Phase D session log — EXECUTOR MISTAKE: "APK build not tested after adding sentry_flutter in Phase 1. Rule: After adding any native dependency, run platform builds immediately."

**Pattern:** Single occurrence but HIGH impact (blocked APK deployment, discovered only at Phase 8 QA).

**Affected Agent:** `Executor.md`

**Rule to Add:**
```
### Rule 8: Native Dependency Build Gate
After adding ANY dependency that includes native code (sentry_flutter, firebase_*,
image_picker, webview_flutter, etc.), run `flutter build apk --debug` AND
`flutter build ios --no-codesign` immediately in the SAME phase. Do not defer
platform builds to QA phase. Native SDK version mismatches (Kotlin, Swift, Gradle)
are invisible to `flutter analyze` and `flutter test`.
```

---

### Gap 1.2: Architect lacks lazy DI initialization rule

**Evidence:** Phase D session log — ARCHITECT MISTAKE: "NotificationVM eager client initialization crashed tests. Rule: When adding DI parameter with Supabase.instance default, use lazy getter."

**Pattern:** This is the 3rd time Supabase.instance initialization caused test failures:
- Phase B: `AssertionError` from `Supabase.instance` not caught by `on Exception catch`
- Phase C: `ChatVM.teardownForRoleSwitch()` calls `Supabase.instance` directly
- Phase D: `NotificationVM` eager client initialization crashed tests

**3 sessions = systemic gap.**

**Affected Agent:** `Architect.md`

**Rule to Add:**
```
### Rule: Lazy Supabase Client Resolution
When adding a SupabaseClient DI parameter with a Supabase.instance.client fallback,
ALWAYS use a lazy getter pattern:

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

NEVER assign eagerly in the initializer list:

  // BAD — crashes in tests when Supabase not initialized
  : _client = client ?? Supabase.instance.client

This prevents AssertionError in test environments where Supabase is not initialized.
```

---

### Gap 1.3: Planner lacks line-count feasibility check for decomposition

**Evidence:** Phase D plan set targets of <400 lines (DashboardVM), <500 lines (submit_request_sheet, requests_list_screen). Actual results: 537, 737, 604. All targets missed. The PlanCritic didn't catch that orchestration code (~200 lines) must stay in the parent VM.

**Pattern:** Single occurrence but recurrent risk. Plans set aspirational line counts without analyzing how much code MUST stay.

**Affected Agent:** `Sline_Planner.md`

**Rule to Add:**
```
### Rule: Decomposition Line-Count Feasibility
When planning god-file decomposition, analyze the extraction map and estimate:
1. Lines that CAN be extracted (business logic, UI components, helpers)
2. Lines that MUST stay (orchestration, state coordination, lifecycle management)

Set the target as: current_lines - extractable_lines + 10% buffer.
Do not set arbitrary round-number targets (<400, <500) without evidence.
```

---

### Gap 1.4: Executor lacks per-sub-phase test gate for risky refactors

**Evidence:** Phase D plan (PlanCritic Fix G7) explicitly added "per-sub-phase test gate for DashboardVM decomposition" because Phase C post-mortem found file corruption during parallel agent execution. The Executor applied this in Phase D (ran tests after each delegate creation).

**Pattern:** The rule was added ad-hoc in the plan. It should be permanent in Executor.

**Affected Agent:** `Executor.md`

**Rule to Add:**
```
### Rule 9: Per-Sub-Phase Test Gate for Multi-File Refactors
When a phase involves creating 3+ new files that refactor an existing file
(e.g., delegate decomposition), run `flutter test <affected_test_dir>` after
EACH new file is created and wired — not just at the end of the phase.
This catches wiring errors immediately instead of accumulating them.
```

---

## 2) Rule Clarity Gaps

### Clarity 2.1: Architecture guard Check 3 exclusion was too broad

**Evidence:** Phase D discovered that CI guard Check 3 excluded `Supabase.instance.client.auth.` patterns, which allowed the exact A6 violations the guard was supposed to catch. The PlanCritic flagged this (Gap 6), and the Executor tightened it.

**Pattern:** The original Phase B implementation was correct at the time (auth access was legitimate in VMs). After Phase D fixed the VMs, the exclusion became a regression risk.

**Lesson:** Architecture guard exclusions should be reviewed after every architecture fix phase. Add a note to the Executor:

```
### Rule 10: Review CI Guard Exclusions After Architecture Fixes
After fixing architecture violations that were previously excluded from CI guards,
review ALL guard exclusion patterns and tighten them. Exclusions that were necessary
before the fix become regression risks after the fix.
```

---

## 3) MCP Recommendations

**No MCP servers recommended.**

Evidence review:
- No session log shows an agent failing because it lacked live database access (tests use mocks, Supabase reality is scanned from docs/migrations)
- No session log shows manual file search being a bottleneck (Glob/Grep tools are effective)
- No session log shows package advisory gaps causing failures
- The one file corruption incident (Phase C, wallet_vm_test.dart) was caused by parallel agent execution, not by lack of tooling

**Threshold not met:** The Prime Directive requires evidence of manual work or failure from lack of live access. None found.

---

## 4) Missing Skills

### Skill 4.1: No "native dependency integration" skill

**Evidence:** Phase D required: adding `sentry_flutter` to pubspec, configuring Android Kotlin version in `build.gradle.kts`, running `pod install` for iOS, setting `--dart-define` compile-time flags. These steps span 3 platforms and 4 config files. No agent or skill explicitly owns this workflow.

**Recommendation:** Create a skill `native-dependency-integration/SKILL.md` that covers:
1. Add to pubspec.yaml
2. Run `flutter pub get`
3. Android: check Kotlin/Gradle version compatibility
4. iOS: run `pod install`
5. Verify all 3 platform builds
6. Document `--dart-define` flags in CLAUDE.md

**Affected Agents:** `@Observability` (for crash reporting SDKs), `@Architect` (for any native dep), `@Executor` (for build verification)

---

## 5) Agent Coordination Gaps

### Coordination 5.1: Orchestrator pipeline vs actual execution mismatch

**Evidence:** The Orchestrator defines a 12-stage sequential pipeline. In practice, the Phase D review ran Stages 1-2 in parallel and Stages 3-5 in parallel for efficiency. The Orchestrator spec says "Sequential-only pipeline (one agent at a time, locked order)" but this is impractical for review-only audits where stages have no data dependencies.

**Recommendation:** Allow parallel execution for review-only stages (ThreatModeler + Supabase_Ops can run in parallel since they audit different domains). Keep sequential for implementation stages.

**Affected Agent:** `orchestrator.md`

**Suggested Change:**
```
### Pipeline Parallelism (Review-Only Mode)
When the Orchestrator runs in REVIEW mode (no implementations), the following
stages may run in parallel since they audit independent domains:
- Parallel Group 1: ThreatModeler + Supabase_Ops
- Parallel Group 2: Architect + Pixel + APIContract
- Sequential: DataMigration → TemplateOwner → Observability → SlineDocs
- Sequential: CodeGuard → Sentinel (these depend on prior findings)
```

---

### Coordination 5.2: PlanCritic → Executor handoff of blocking decisions

**Evidence:** Phase D PlanCritic identified 3 blocking decisions (DN-1: coverage threshold, DN-2: scoped provider pattern, DN-3: BookingService provider promotion). The Executor correctly applied all 3. But the handoff was informal — the decisions were embedded in the plan text, not in a structured format.

**Recommendation:** PlanCritic should output blocking decisions in a machine-parseable format at the top of the plan, so the Executor can verify each one is addressed.

**Affected Agents:** `Plan_Critic.md`, `Executor.md`

---

## 6) Orchestrator Pipeline Improvements

### Pipeline 6.1: Add "Build Verification" as a named stage

**Evidence:** APK build failure in Phase D wasn't caught until Phase 8 (QA). Build verification is currently embedded in Sentinel's QA checklist, but it should be a distinct early gate for phases that add native dependencies.

**Recommendation:** Add Stage 11.5 (or rename existing) as explicit "Platform Build Gate" that runs after CodeGuard and before Sentinel when native dependencies changed.

---

## 7) New Agent Recommendations

**No new agents recommended.**

All 16 existing agents cover the observed failure modes. The constructor DI gap, lazy initialization, and build verification issues are all solvable by adding rules to existing agents (Architect, Executor). No repeated work was observed that falls outside existing agent ownership.

---

## 8) Things the Human Missed

### 8.1: Coverage floor is very low (28%)

The 28% coverage floor was set correctly as a regression prevention measure (current coverage 30.6%). However, no plan exists to raise it. Phase E mentions "85% coverage target" but that's aspirational with no roadmap.

**Recommendation:** Add incremental coverage gates to the audit roadmap:
- After Phase D: 28% (current)
- After 2 more feature phases: raise to 35%
- After Phase E polish: raise to 50%
- Long-term: 70%

### 8.2: Session log format inconsistency

Phase B and Phase D session logs use different formats for "Agent Improvement Notes" — Phase B uses inline text, Phase D uses a table. The Executor should standardize.

**Recommendation:** Standardize on the table format used in Phase D:
```
| Agent | Mistake Made | Rule to Add/Change |
```

---

## 9) Priority Action List

| Priority | Action | Agent to Update | Effort |
|----------|--------|----------------|--------|
| **P0** | Add lazy DI initialization rule | `Architect.md` | 5 min (paste rule) |
| **P0** | Add native dependency build gate | `Executor.md` | 5 min (paste rule) |
| **P1** | Add per-sub-phase test gate rule | `Executor.md` | 5 min (paste rule) |
| **P1** | Add CI guard exclusion review rule | `Executor.md` | 5 min (paste rule) |
| **P1** | Add decomposition line-count feasibility rule | `Sline_Planner.md` | 5 min (paste rule) |
| **P2** | Allow parallel review stages in Orchestrator | `orchestrator.md` | 15 min (rewrite pipeline section) |
| **P2** | Create native-dependency-integration skill | `.cursor/skills/` | 30 min (new file) |
| **P2** | Standardize session log format | `Executor.md` | 5 min (add note) |
| **P3** | Add incremental coverage gate roadmap | Audit file | 10 min (add section) |
| **P3** | Structured blocking decision format for PlanCritic | `Plan_Critic.md` | 15 min |

---

## 10) Improvement Tracking

### Rules Applied in Previous Reports (v1 + v2)

| Rule | Source | Applied To | Status |
|------|--------|-----------|--------|
| Error vs Exception catch | v1 Gap 1.1 | Architect.md §3.2.1 | APPLIED, EFFECTIVE |
| Test mock audit on VM method add | v1 Gap 1.2 | Executor.md Step 3.2 | APPLIED, EFFECTIVE |
| notifyListeners timing rule | v1 Gap 1.3 | Architect.md §3.4.1 | APPLIED, EFFECTIVE |
| Sub-phase test gate | v1 Gap 1.4 | Executor.md Step 3.1 | APPLIED, EFFECTIVE |
| Async callback guards | v1 Gap 1.5 | Architect.md §3.4.2 | APPLIED, EFFECTIVE |
| Query builder pagination | v1 Gap 8.1 | Architect.md §4.5 | APPLIED, EFFECTIVE |
| Runtime smoke test | v1 | Orchestrator.md Stage 11.5 | APPLIED, EFFECTIVE |
| Constructor DI verification | v2 Gap 1.1 | Sline_Planner.md §2.2.1 | APPLIED, EFFECTIVE |
| Singleton detection | v2 Gap 1.2 | Sline_Planner.md §2.2.2 | APPLIED, EFFECTIVE |
| Auto-loading constructor detection | v2 Gap 1.3 | Sline_Planner.md §2.2.3 | APPLIED, EFFECTIVE |
| Field immutability preservation | v2 Gap 2.1 | Architect.md §4.5 | APPLIED, EFFECTIVE |
| File integrity check | v2 Gap 5.2 | Executor.md Step 3.3 | APPLIED, EFFECTIVE |

**All 12 previously recommended rules were applied and remained effective through Phase D.**

### New Rules Recommended in This Report (v3)

| Rule | Target Agent | Priority |
|------|-------------|----------|
| Lazy Supabase Client Resolution | Architect.md | P0 |
| Native Dependency Build Gate | Executor.md | P0 |
| Per-Sub-Phase Test Gate for Multi-File Refactors | Executor.md | P1 |
| CI Guard Exclusion Review After Architecture Fixes | Executor.md | P1 |
| Decomposition Line-Count Feasibility | Sline_Planner.md | P1 |
| Parallel Review Stages in Orchestrator | orchestrator.md | P2 |

---

## 11) Full Evidence Index

| Session | File | Issue | Resolution |
|---------|------|-------|-----------|
| Phase B | SESSION_PhaseB_BugExposure_2026-04-01.md | AssertionError from Supabase.instance | Rule added to Architect (v1) |
| Phase B | SESSION_PhaseB_BugExposure_2026-04-01.md | Missing loadCategories mock stubs | Rule added to Executor (v1) |
| Phase C | SESSION_PLAN_CriticalTests_2026-04-02.md | WalletVM/ChatVM constructor DI gap | Rule added to Planner (v2) |
| Phase C | SESSION_PLAN_CriticalTests_2026-04-02.md | RoleSwitchCoordinator singleton pollution | Rule added to Planner (v2) |
| Phase C | SYSTEM_EVOLUTION_REPORT_2026-04-02_v2.md | File corruption during parallel agents | Rule added to Executor (v2) |
| Phase C | SYSTEM_EVOLUTION_REPORT_2026-04-02_v2.md | late final → late change risk | Rule added to Architect (v2) |
| Phase D | SESSION_PLAN_PhaseD_Harden_2026-04-03.md | NotificationVM eager client crash | NEW: Lazy DI rule for Architect |
| Phase D | SESSION_PLAN_PhaseD_Harden_2026-04-03.md | APK build not tested after sentry_flutter | NEW: Native dep build gate for Executor |
| Phase D | PLAN_PhaseD_Harden_2026-04-03.md (PlanCritic) | Coverage threshold delusion (70% vs 30.6%) | Resolved in plan v2, no rule needed |
| Phase D | PLAN_PhaseD_Harden_2026-04-03.md (PlanCritic) | SubmitRequestVM provider pattern undefined | Resolved in plan v2, no rule needed |
| Phase D | PLAN_PhaseD_Harden_2026-04-03.md (PlanCritic) | BookingService not in Provider tree | Resolved in plan v2, no rule needed |
| Phase D | PLAN_PhaseD_Harden_2026-04-03.md (PlanCritic) | 12 Edge Functions affected by CORS | Resolved in plan v2, no rule needed |
| Phase D | PLAN_PhaseD_Harden_2026-04-03.md (PlanCritic) | Architecture guard Check 3 exclusion | NEW: CI guard review rule for Executor |

---

## Conclusion

The SLINE agent system is **maturing well**. 12 rules from v1+v2 reports all proved effective in Phase D. The system caught and prevented previously recurring issues (constructor DI gaps, singleton pollution, file integrity).

Phase D introduced 2 new failure patterns:
1. **Lazy vs eager Supabase client initialization** (3rd occurrence of Supabase.instance test issues — now systemic, needs permanent rule)
2. **Native dependency build verification** (new category, needs build gate rule)

Both are addressable with small rule additions to existing agents. No structural changes to the agent system are needed.

**End of Report.**
