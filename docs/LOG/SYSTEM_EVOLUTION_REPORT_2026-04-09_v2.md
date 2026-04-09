# System Evolution Report — 2026-04-09 v2

**Sessions Analyzed:** 8 (7 prior + Phase 5 ChatDashboardNotifications)
**Previous Evolution Reports:** 4 (2026-04-07, 2026-04-08, 2026-04-08_v2, 2026-04-09)
**Agent Files Scanned:** 16 (all agents in .cursor/Agents/)
**Core Docs Scanned:** DEVELOPER_GUIDE.md, SUPABASE_SETUP.md, STRUCTURE.md, .TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md
**Most Common Failure Type:** Visual verification gap — process completion without visual outcome verification (NEW, CRITICAL)
**Most Frequently Flagged Agent:** @Pixel (9 mistakes across 3 sessions) + @SlinePlanner (scope mislabeling, NEW)
**Highest-Value Improvement:** Visual Change Classification + Verification Gate (prevents entire phases of wasted work)

---

## Sessions Analyzed

| # | Session | Date | Status | Mistakes | Test Δ |
|---|---------|------|--------|----------|--------|
| 1 | GitHub_CI_RepoSafeguards | 2026-04-04 | NOT STARTED | 0 | N/A |
| 2 | Agent_CI_RepoSafeguards | 2026-04-06 | COMPLETED | 0 | 0 |
| 3 | DesignSystemFoundation | 2026-04-07 | COMPLETED | 6 | 0 |
| 4 | CoreWidgetRedesign | 2026-04-07 | COMPLETED* | 7 | +87 |
| 5 | LayoutTokens_Phase0.7 | 2026-04-08 | COMPLETED | 3 | +53 |
| 6 | Phase2_AppShellAuthCards | 2026-04-08 | COMPLETED | 1 | +15 |
| 7 | Phase4_HomeDiscovery | 2026-04-08 | COMPLETED | 2 | 0 (7 fixed) |
| 8 | Phase5_ChatDashboardNotifications | 2026-04-09 | COMPLETED | 2 | +17 |
| **Total** | | | | **21** | **+172** |

> \* CoreWidgetRedesign session log was not formally closed before the next session began (see Dead Code Detection guardrail).

---

## CRITICAL FINDING: The Phantom Redesign Problem

### What Happened

Phase 5 (ChatDashboardNotifications) was planned and executed as a "UI Redesign" of 17 files across Chat, Notifications, and Dashboard. The Orchestrator pipeline ran all 11 stages and produced a CONDITIONAL_PASS → PASS Master Report. All gates passed. All tests passed. Zero analyze issues.

**The user saw zero visual changes.** The entire phase was:
- Token swaps (`AppColors.teal` → `colorScheme.primary` — same rendered color)
- Micro-interactions (stagger animations, haptics, typing dots — invisible on inspection)
- Accessibility labels (invisible to sighted users)
- Skeleton loading states (only visible during load, not on inspection)

**Root cause:** The plan covered Master Plan Phase 6 (Chat) + Phase 7 (Dashboard) + Phase 14 (Notifications) but executed only the **polish/normalization** layer — not the actual visual redesign described in the Master Plan (new layouts, new input bar, swipe-to-reply, timeline redesign, pill-style tabs, animated counters, etc.).

### Why It Wasn't Caught

The agent system has **zero visual verification checkpoints**. Every gate checks process completion, code quality, and architecture compliance. No gate asks: "Did the screens actually change visually?"

| Agent | What It Checked | What It Missed |
|-------|-----------------|----------------|
| @SlinePlanner | Plan structure, phases, gates | Plan labeled "redesign" but scoped token-only work |
| @PlanCritic | Plan gaps, acceptance criteria | No criterion: "user must perceive visual change" |
| @Executor | Phase completion, lint, tests | No visual diff at phase end |
| @Pixel | Token compliance, Semantics, motion | No before/after screenshot comparison |
| @Sentinel | QA gates, test pass, architecture | No visual verification gate |
| @CodeGuard | Code quality, hardcoded values | No visual output validation |
| @Orchestrator | All agent reports merged | Accepted process proof, not visual proof |

---

## 1) Rule Gaps (NEW — not in any previous evolution report)

### RG-6: @SlinePlanner — Visual Change Classification [CRITICAL, NEW]

**Evidence:** Phase5_ChatDashboardNotifications — Plan was labeled "Phase 5 — Chat, Dashboard & Notifications UI Redesign" but contained only token normalization and micro-interactions. Zero structural layout changes. The user could not perceive any difference.

**Current state:** Sline_Planner.md §4.1 (UI Planning Protocol) has no classification of what constitutes a "redesign" vs a "polish pass" vs a "token normalization."

**Rule text to add to Sline_Planner.md §4.1:**

> ### Visual Change Classification (Required Before Phase Naming)
>
> Every UI phase MUST classify its scope before execution:
>
> - **Redesign**: Structural changes to layout, visual hierarchy, component arrangement, or visual direction that a user perceives as a noticeably different screen. Examples: new input bar layout, timeline design, card restructuring, tab style change.
> - **Polish Pass**: Refinements to existing layouts — micro-interactions, stagger animations, haptics, skeleton loading, empty states. Existing layout is preserved; behavior/feel is enhanced.
> - **Token Normalization**: Replacing hardcoded values (colors, spacing, durations) with design system tokens that resolve to the SAME rendered output. Zero visual change.
>
> **Naming rules:**
> - A phase labeled "Redesign" MUST include at least one structural layout change per screen
> - A phase labeled "Polish" MUST NOT be called "Redesign"
> - A phase labeled "Token Normalization" MUST NOT be bundled with redesign work
> - If the Master Plan phase describes a "Redesign" but the implementation plan only covers polish/normalization, the plan MUST be labeled accordingly and the gap documented
>
> **Why:** Phase 5 (2026-04-09) was labeled "Redesign" but executed token-only work. The user saw zero visual changes across 17 files. Entire session of polish work was mistaken for a redesign.

---

### RG-7: @Sentinel — Visual Verification Gate [CRITICAL, NEW]

**Evidence:** Phase5_ChatDashboardNotifications — Sentinel issued CONDITIONAL_PASS based on code quality, test results, and architecture compliance. No visual comparison was performed or required. The user discovered zero visual changes only after all gates passed.

**Current state:** Sentinel.md §10.2 (Manual QA Script) requires "screenshot or concise evidence note per major UI sub-phase" but does not require before/after comparison or visual diff verification.

**Rule text to add to Sentinel.md §4C:**

> ### Visual Verification Gate (Mandatory When Plan Includes UI Changes)
>
> If the plan includes Redesign or Polish Pass work:
>
> 1. **Before/After Evidence**: For every screen touched, the session log MUST contain a before/after visual description or screenshot reference documenting what changed
> 2. **Visual Change Checklist**: At least one of these must be true per screen:
>    - [ ] Layout or spacing visibly changed
>    - [ ] Colors or visual hierarchy noticeably different
>    - [ ] New components or visual elements added
>    - [ ] Existing components structurally rearranged
> 3. **Block Condition**: If the plan was labeled "Redesign" but zero visual differences exist → BLOCK. Relabel as "Token Normalization" or "Polish Pass" and require plan revision.
> 4. **Token Normalization Exception**: If the plan explicitly states "Token Normalization — zero visual changes expected" → PASS (zero change IS the success criterion).
>
> **Why:** Phase 5 (2026-04-09) passed all code quality gates but the user saw no visual difference. Process completion ≠ outcome delivery.

---

### RG-8: @Executor — Plan vs Master Plan Scope Validation [HIGH, NEW]

**Evidence:** Phase5_ChatDashboardNotifications — Plan covered Master Plan Phases 6+7+14 but only implemented the token/polish layer. The Master Plan specs for Phase 6 (Chat) include: "Redesigned input bar", "Swipe-to-reply", "Long-press context menu", "Pill-style date separators", "Emoji-only large display", "Link detection". None of these were implemented. The plan never cross-referenced against the Master Plan to verify scope coverage.

**Current state:** Executor.md §4.4 (Validation Checklist) has no requirement to compare plan scope against Master Plan phase definitions.

**Rule text to add to Executor.md §4.4:**

> ### Master Plan Cross-Reference (Required Before Execution)
>
> Before executing any UI phase:
>
> 1. Open the Master Plan (`.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md`)
> 2. Find the matching Master Plan phase(s) for this plan's scope
> 3. Compare the plan's AFTER descriptions against the Master Plan's AFTER descriptions
> 4. Document any gaps: "Master Plan Phase 6 specifies swipe-to-reply — not in this plan"
> 5. If the plan covers < 50% of the Master Plan phase scope, flag as PARTIAL IMPLEMENTATION and require explicit acknowledgment from the human
>
> **Why:** Phase 5 (2026-04-09) covered Master Plan Phases 6+7+14 but implemented only token normalization. The Master Plan's visual redesign specs (new layouts, new interactions) were not referenced during planning.

---

### RG-9: @Pixel — Visual Attestation Requirement [HIGH, NEW]

**Evidence:** Phase5_ChatDashboardNotifications — @Pixel audit (during Orchestrator review) checked token compliance, Semantics presence, and state coverage. It confirmed "UI audit step ran" — but this meant "code was analyzed", not "visual change was verified." No screenshot, no before/after, no visual diff.

**Current state:** Pixel.md has no rule requiring visual attestation or before/after evidence.

**Rule text to add to Pixel.md §10:**

> ### Visual Attestation (Mandatory for UI Phases)
>
> After implementing any UI phase that is labeled Redesign or Polish:
>
> 1. List specific visual changes observed per screen:
>    - Layout changes: "Input bar redesigned from basic TextField to rounded container with floating send button"
>    - Color changes: "Message bubbles now use gradient teal instead of flat teal"
>    - Spacing changes: "Card padding increased from 12px to 16px, visible gap between sections"
> 2. If zero visual changes exist, report: "This phase was token normalization only — no visual changes"
> 3. Never report "UI audit completed" without specifying what visually changed
>
> **Why:** Phase 5 Orchestrator review — @Pixel reported all files passed audit, but no visual change attestation was provided.

---

### Previously Identified Rule Gaps (from 2026-04-09 v1 — still pending implementation)

| ID | Agent | Rule | Priority | Status |
|----|-------|------|----------|--------|
| RG-1 | @Pixel | Sliver Widget Safety Rule | HIGH | PENDING |
| RG-2 | @Pixel | Widget Lifecycle Context Access Rule | HIGH | PENDING |
| RG-3 | @Executor | Test Text Expectation Atomic Update Rule | MED | PENDING |
| RG-4 | @Sentinel | Infinite Animation Test Rule (amend pumpAndSettle) | MED | PENDING |
| RG-5 | @Sentinel | DraggableScrollableSheet Test Rule | LOW | PENDING |

---

## 2) Rule Clarity Gaps

### RC-2: "Redesign" is undefined across the entire agent system [CRITICAL]

Every agent uses the word "redesign" — the Master Plan title is "SLINE UI REDESIGN — MASTER PLAN", session plans are titled "Phase X ... Redesign", Pixel talks about "redesigned screens." But nowhere in any agent file is "redesign" defined. This allowed Phase 5 to execute a token swap and call it a redesign.

**Fix:** RG-6 (above) adds the classification. All agents that reference "redesign" should link to this classification.

---

## 3) MCP Recommendations

### MCP-1: Screenshot/Preview MCP for Visual Verification [HIGH]

**Evidence:** Phase 5 — no visual verification was possible because no agent could render the app and compare screenshots.

**Opportunity:** A preview/screenshot MCP (e.g., `mcp__Claude_Preview__preview_screenshot`) already exists in the tool list. It could:
- Render a screen before/after changes
- Produce visual diff evidence
- Enable Sentinel to perform visual verification gates

**Agents that benefit:** @Pixel (visual attestation), @Sentinel (visual verification gate), @Executor (phase completion evidence)

**Note:** The `Claude_Preview` and `computer-use` MCPs are already available. The gap is that no agent REQUIRES their use for visual verification. Adding the rules above (RG-7, RG-9) would make screenshot evidence mandatory, naturally driving MCP adoption.

---

## 4) Missing Skills

### MS-1: Visual Diff Skill

No agent has a workflow for "compare current screen to baseline and report differences." This should be a defined skill in @Pixel or @Sentinel:
1. Render/screenshot the current state
2. Compare to baseline (previous branch or saved screenshot)
3. Report pixel-level or structural differences
4. Attest that changes match plan intent

---

## 5) Agent Coordination Gaps

### AC-2: @SlinePlanner → @Executor handoff lacks Master Plan cross-reference [NEW]

**Evidence:** Phase 5 — @SlinePlanner produced a plan that covered token normalization. @Executor executed it faithfully. Neither checked whether the plan covered the Master Plan's actual redesign scope.

**Fix:** RG-8 (above) adds the cross-reference requirement to @Executor. Additionally, @SlinePlanner should include a "Master Plan Coverage" section in every plan showing which Master Plan items are IN scope and which are DEFERRED.

### AC-3: @Orchestrator → User handoff lacks visual evidence [NEW]

**Evidence:** Phase 5 — Orchestrator Master Report declared PASS. User opened the app and saw no changes. The Master Report contained zero visual evidence.

**Fix:** RG-7 (Sentinel visual gate) + adding a "Visual Changes Summary" section to the Master Report template (Section B.5).

---

## 6) Orchestrator Pipeline Improvements

### OP-1: Add Visual Verification as Stage 11.5 requirement [HIGH]

Stage 11.5 (@Sentinel Runtime Smoke Test) already exists but is marked "human-assisted" and was skipped in Phase 5. For UI phases, this stage MUST run and MUST include visual comparison.

### OP-2: Master Report should include "Visual Changes Summary" section [MED]

Add between Section B (Findings) and Section C (Fix Plan):

> ### B.5) Visual Changes Summary
>
> For each screen modified in this phase:
> | Screen | Visual Change | Evidence |
> |--------|--------------|----------|
> | MessagesScreen | Stagger animation on entrance | Animation only — no layout change |
> | ChatScreen | Date separator pills added | Minor visual addition |
> | ... | ... | ... |
>
> **Overall visual impact:** [Significant / Minor / Token-only / None]
>
> If "Token-only" or "None" and the phase was labeled "Redesign" → BLOCK.

---

## 7) New Agent Recommendations

**None.** The existing agent set covers all responsibilities. The gap is in RULES within existing agents, not in missing agents.

---

## 8) Things the Human Missed

### The Phase Numbering Confusion

The executed plans use their own phase numbering (Phase 0, 1, 2, 3, 4, 5) that does NOT map 1:1 to the Master Plan phases. This causes confusion:

| Executed Plan "Phase" | Master Plan Phase | Master Plan Name |
|----------------------|-------------------|------------------|
| Phase 0 (Design System) | Phase 0 | Design System Overhaul |
| Phase 1 (Core Widgets) | Phase 1 | Core Widget Redesign |
| Phase 0.7 (Layout Tokens) | Phase 0 (sub-phase) | Layout Tokens |
| Phase 2 (App Shell + Auth + Cards) | Phase 2 + 3 + 5 | Navigation + Auth + Cards |
| Phase 4 (Home & Discovery) | Phase 4 | Home & Discovery |
| Phase 5 (Chat/Dashboard/Notifications) | Phase 6 + 7 + 14 | Chat + Dashboard + Notifications |

**The next execution should be:** Master Plan Phase 6 (Chat — actual visual redesign), Phase 7 (Dashboard — actual visual redesign), then Phase 8 onwards.

**Recommendation:** Future plans should include a "Master Plan Mapping" header showing exactly which Master Plan phases they cover.

---

## 9) Priority Action List

| Priority | Action | Owner | Effort |
|----------|--------|-------|--------|
| **P0** | Add RG-6 (Visual Change Classification) to Sline_Planner.md | Human | 5 min |
| **P0** | Add RG-7 (Visual Verification Gate) to Sentinel.md | Human | 5 min |
| **P0** | Add RG-8 (Master Plan Cross-Reference) to Executor.md | Human | 5 min |
| **P0** | Add RG-9 (Visual Attestation) to Pixel.md | Human | 5 min |
| **P1** | Add RG-1 through RG-5 from v1 report (still pending) | Human | 15 min |
| **P1** | Add OP-2 (Visual Changes Summary) to Orchestrator.md Master Report template | Human | 5 min |
| **P2** | Fix pre-existing flaky test (6 sessions carrying) | Executor | 30 min |
| **P2** | Formally close CoreWidgetRedesign session log | Executor | 10 min |
| **P3** | Add Master Plan Coverage section to plan template | Sline_Planner | 10 min |

---

## 10) Improvement Tracking

### From Previous Reports — Applied & Verified:
- ✅ Flutter API Verification rule (Pixel.md) — from 2026-04-07
- ✅ Token Value Intentionality Check (Executor.md) — from 2026-04-07
- ✅ Plan Critique Review rule (Executor.md §4.6) — from 2026-04-07
- ✅ Widget Conversion Test Gate (Executor.md §3.9) — from 2026-04-08
- ✅ Widget Test Finder Rules (Sentinel.md) — from 2026-04-08
- ✅ Session Log Closure Enforcement (Executor.md §3.10) — from 2026-04-08
- ✅ Token Value Extraction Workflow (Sline_Planner.md §2.2.6) — from 2026-04-08_v2
- ✅ Orchestrator Parallel Review Mode — from 2026-04-08

### From Previous Reports — Still Pending:
- ⚠️ RG-1: Sliver Safety Rule (Pixel.md) — from 2026-04-09
- ⚠️ RG-2: Widget Lifecycle Context Rule (Pixel.md) — from 2026-04-09
- ⚠️ RG-3: Test Text Expectation Rule (Executor.md) — from 2026-04-09
- ⚠️ RG-4: Infinite Animation Test Rule (Sentinel.md) — from 2026-04-09
- ⚠️ RG-5: DraggableScrollableSheet Test Rule (Sentinel.md) — from 2026-04-09

### New This Report:
- 🆕 RG-6: Visual Change Classification (Sline_Planner.md) — CRITICAL
- 🆕 RG-7: Visual Verification Gate (Sentinel.md) — CRITICAL
- 🆕 RG-8: Master Plan Cross-Reference (Executor.md) — HIGH
- 🆕 RG-9: Visual Attestation (Pixel.md) — HIGH
- 🆕 RC-2: "Redesign" undefined system-wide — CRITICAL
- 🆕 AC-2: Planner→Executor Master Plan cross-reference gap — HIGH
- 🆕 AC-3: Orchestrator→User visual evidence gap — HIGH
- 🆕 OP-1: Visual Verification in Stage 11.5 — HIGH
- 🆕 OP-2: Visual Changes Summary in Master Report — MED

---

## 11) Full Evidence Index

| Finding | Session Evidence |
|---------|-----------------|
| RG-6 | Phase5_ChatDashboardNotifications — labeled "Redesign", user saw zero changes |
| RG-7 | Phase5_ChatDashboardNotifications — Sentinel CONDITIONAL_PASS without visual check |
| RG-8 | Phase5_ChatDashboardNotifications — Master Plan Phase 6 specs not referenced |
| RG-9 | Phase5_ChatDashboardNotifications — Pixel audit said "PASS" without visual attestation |
| RC-2 | All 8 sessions — "redesign" used inconsistently, never defined |
| AC-2 | Phase5_ChatDashboardNotifications — plan covered Phase 6+7+14 at token level only |
| AC-3 | Phase5_ChatDashboardNotifications — Master Report declared PASS, user saw no change |
| OP-1 | Phase5_ChatDashboardNotifications — Stage 11.5 skipped (UI phase, should have run) |
| RG-1 | Phase4_HomeDiscovery — sliver wrapped in Semantics crash |
| RG-2 | Phase4_HomeDiscovery — respectMotion in initState |
| RG-3 | Phase4_HomeDiscovery — test text not updated with view text |
| RG-4 | Phase4_HomeDiscovery — pumpAndSettle timeout on shimmer |
| RG-5 | Phase4_HomeDiscovery — DraggableScrollableSheet scrollable ambiguity |
| Flaky test | 6 consecutive sessions — wallet_shared_body_test or favorites_screen_test |

---

## Conclusion

The Phase 5 incident reveals the most significant systemic gap found to date: **the agent system optimizes for process compliance over outcome delivery**. Every code quality gate passed. Every architecture guard passed. Every test passed. But the user opened the app and saw the same screens they had before.

The fix is straightforward: 4 new rules (RG-6 through RG-9) that require visual change classification at planning time and visual verification at QA time. These rules would have caught the Phase 5 mislabeling before execution began.

**The next phase execution (Master Plan Phase 6: Chat — actual visual redesign) should be the first test of these new rules.**
