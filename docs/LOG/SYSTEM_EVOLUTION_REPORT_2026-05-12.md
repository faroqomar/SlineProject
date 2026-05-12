# System Evolution Report - 2026-05-12

Scope: Agent-system improvement pass after Open Design Amber Dusk Phases 2-4 Step 6 Orchestrator review.
Execution mode: one main agent only.
User instruction: merge findings into agent files and dedupe against existing rules.

## Sessions Analysed

Session logs scanned:

- `docs/LOG/SESSION_HomeDiscoveryNavConsolidation_2026-04-30.md`
- `docs/LOG/SESSION_PLAN_Agent_CI_RepoSafeguards_2026-04-06.md`
- `docs/LOG/SESSION_PLAN_CoreWidgetRedesign_2026-04-07.md`
- `docs/LOG/SESSION_PLAN_DesignSystemFoundation_2026-04-07.md`
- `docs/LOG/SESSION_PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md`
- `docs/LOG/SESSION_PLAN_LayoutTokens_Phase0.7_2026-04-08.md`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_2026-05-10.md`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md`
- `docs/LOG/SESSION_PLAN_Phase2_AppShellAuthCards_2026-04-08.md`
- `docs/LOG/SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md`
- `docs/LOG/SESSION_PLAN_Phase5_ChatDashboardNotifications_2026-04-09.md`
- `docs/LOG/SESSION_PLAN_Phase6_ChatAdvancedInteractions_2026-04-10.md`
- `docs/LOG/SESSION_PLAN_Phase7_DashboardCommandCenter_2026-04-10.md`

Prior SystemEvolution reports scanned:

- `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-07.md`
- `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-08.md`
- `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-08_v2.md`
- `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-09.md`
- `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-09_v2.md`
- `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-10.md`
- `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-30.md`
- `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-05-11.md`

Core docs scanned:

- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/SUPABASE_SETUP.md`
- `Sline_everything/STRUCTURE.md`
- `Sline_everything/CODE_REVIEW.md`
- `Sline_everything/MVP_ROADMAP.md`

Agent files scanned: all files in `.cursor/Agents/`.

## Summary

- Most common failure type: visual evidence / runtime QA closure risk. Existing 2026-05-11 rules already cover the baseline classification and hash-sanity gap, so no duplicate rule was added.
- Most frequently affected agents this run: `Orchestrator`, `Executor`, `Architect`, `Pixel`, `Observability`, and `Sentinel`.
- Highest-value improvement: add a formal scope-amendment path and behavior-test rule so post-plan review findings do not become either silent scope creep or untested fixes.
- MCP servers recommended: none. Current failures were process and rule gaps; Open Design MCP, local command execution, Computer Use/browser, and Flutter tests are already sufficient when required by the agents.
- New agents recommended: none.

## 1. Rule Gaps

### RG-1: Post-plan scope amendments need a formal ledger

Evidence:

- `SESSION_PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md:96-97` records missing Open Design evidence and token-normalization limits for several secondary screens.
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:52-55` records Profile and Messages changes exceeding the original phase scope, but being reclassified because the human supplied explicit follow-up review findings.

Merged rules:

- `Executor.md`: added `Step 3.1.4 — Scope Amendment Ledger`.
- `Orchestrator.md`: Master Report must include post-plan scope amendments; behavior rules now require explicit handling of human-supplied post-plan findings.

### RG-2: Views must not infer missing model contracts

Evidence:

- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:37-45` records unsafe Messages request/response inference and scattered `__details` metadata access.

Merged rule:

- `Architect.md`: added `View Contract Inference Rule` requiring explicit model/ViewModel contracts or documented visual-only behavior, plus centralized helper/constants for temporary metadata keys.

### RG-3: Custom interactive UI controls need explicit semantics and hit behavior

Evidence:

- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:63-71` records missing selected/button semantics and a no-op DashboardOfferCard semantic wrapper.

Merged rule:

- `Pixel.md`: added `Custom Gesture Semantics Pattern` for custom buttons, toggles, tabs, chips, cards, semantics exclusion, and `HitTestBehavior.opaque`.

### RG-4: View-layer logs must not include raw domain IDs by default

Evidence:

- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:78-81` records raw task/booking/offer IDs in new UI logs.

Merged rule:

- `Observability.md`: added view-layer logging restriction for raw domain IDs, with service/ViewModel logging allowed only under clear operation context.

### RG-5: Review-fix behavior changes need behavior-level tests

Evidence:

- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:30-33` records a full-suite failure from a stale booking badge text expectation.
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:47-50` records missing Inbox/Dashboard action-path tests.
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:83-85` records brittle CreateTaskScreen interaction tests.

Merged rule:

- `Sentinel.md`: added a review-fix behavior coverage rule under the UI QA evidence requirements, including stale visible-label and badge/status text assertion scans.

### RG-6: Runtime visual QA status must be explicit in Master Reports

Evidence:

- `SESSION_PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md:20-24` records the agent mistake of closing Phase 1 before proving screenshot evidence was route-specific runtime evidence.
- `SESSION_PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md:212-219` keeps Phase 1 screenshot evidence provisional.
- `SESSION_PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md:165-168` keeps Phase 2-4 emulator visual QA open.
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:17-19` and `:128-156` keep the manual visual parity gate open.

Merged rule:

- `Orchestrator.md`: Master Report test summary now requires visual evidence status for UI phases, and behavior rules forbid treating green tests as visual completion.

## 2. Rule Clarity Gaps

- The 2026-05-11 visual-evidence rules were already present in `Planner`, `PlanCritic`, `Executor`, `Pixel`, and `Sentinel`. This run did not duplicate them.
- `Orchestrator` had Stage 11.5 runtime smoke testing but its Master Report template did not force a visual evidence status line. This was a clarity gap, now patched.
- `SystemEvolution.md` already allows agent-file edits when the human explicitly asks for merge. No change needed there.

## 3. MCP Recommendations

None.

Reason: the repeated failures were not caused by unavailable live access. The logs show Open Design MCP evidence, local commands, Flutter tests, and simulator tooling were available; the missing pieces were rule enforcement, scope accounting, and manual visual-gate tracking.

## 4. Missing Skills

None.

The existing agent and skill set covers UI audit, MVVM audit, test QA, docs, and visual evidence handling. No new skill met the threshold.

## 5. Agent Coordination Gaps

- `Executor -> Orchestrator`: post-plan user findings need a shared scope amendment vocabulary. Patched in both agents.
- `Architect -> Pixel`: Pixel must request missing contracts rather than inferring them in widgets. Patched via Architect contract rule and Pixel remains bound to Architect contract confirmation.
- `Pixel -> Sentinel`: custom UI semantics and behavior must be verified as behavior, not theme constants. Patched in Pixel and Sentinel.

## 6. Orchestrator Pipeline Improvements

- Keep review-only parallel agents allowed when the user explicitly requests them.
- Keep fixes coordinated by one main owner.
- Add explicit scope amendments and visual evidence status to the Master Report.
- Do not close UI phases on analyzer/tests alone when runtime visual parity remains open.

## 7. New Agent Recommendations

None.

## 8. Things the Human Missed

- Visual QA is now a release gate, but it still depends on a seeded/emulator state that exposes authenticated Home, Dashboard, Create, Search, Saved, Favorites, Messages, Profile, and Wallet surfaces.
- If future user findings add files after execution starts, the session log should record that as scope amendment immediately, not only in the final report.

## 9. Priority Action List

1. Done: patch `Executor.md` scope amendment ledger.
2. Done: patch `Orchestrator.md` scope amendment and visual evidence status rules.
3. Done: patch `Architect.md` missing-contract inference rule.
4. Done: patch `Pixel.md` custom gesture semantics rule.
5. Done: patch `Observability.md` view-layer raw ID logging rule.
6. Done: patch `Sentinel.md` behavior-level review-fix testing rule.

## 10. Improvement Tracking

| Rule | Agent file | Status |
| --- | --- | --- |
| RG-1 | `Executor.md`, `Orchestrator.md` | Merged |
| RG-2 | `Architect.md` | Merged |
| RG-3 | `Pixel.md` | Merged |
| RG-4 | `Observability.md` | Merged |
| RG-5 | `Sentinel.md` | Merged |
| RG-6 | `Orchestrator.md` | Merged |

## 11. Full Evidence Index

- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md:20-24`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md:212-219`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md:96-97`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md:165-168`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:17-19`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:30-33`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:37-55`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:59-85`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md:128-156`
