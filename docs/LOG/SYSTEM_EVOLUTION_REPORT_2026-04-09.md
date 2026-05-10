# System Evolution Report — 2026-04-09

**Sessions Analyzed:** 7
**Previous Evolution Reports:** 3 (2026-04-07, 2026-04-08, 2026-04-08_v2)
**Agent Files Scanned:** 6 (Pixel, Executor, Sentinel, Planner, Observability, Orchestrator)
**Most Common Failure Type:** Test regressions after animation/widget structural changes (3 sessions)
**Most Frequently Flagged Agent:** @Pixel (9 mistakes across 3 sessions)
**Highest-Value Improvement:** Sliver safety rule for @Pixel (brand new mistake category)

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
| 7 | Phase4_HomeDiscovery | 2026-04-08 | COMPLETED | 2 | 0 (7 regressions fixed) |
| **Total** | | | | **19** | **+155** |

*CoreWidgetRedesign session log never formally closed.

---

## 1) Rule Gaps (NEW — not in any previous evolution report)

### RG-1: @Pixel — Sliver Widget Safety Rule [HIGH, NEW]
**Evidence:** Phase4_HomeDiscovery session — wrapped `DiscoveryTaskSliver` (a sliver) in `Semantics` (a non-sliver) inside `CustomScrollView`, causing `RenderViewport` type mismatch.
**Current state:** Pixel.md mentions slivers once (line 299: "ListView.builder, slivers, or paged patterns for real lists") but has NO rule about sliver/non-sliver constraints.
**Rule text to add to Pixel.md:**

> **Sliver Safety Rule:** Never wrap a sliver widget (`SliverList`, `SliverGrid`, `SliverPadding`, `SliverToBoxAdapter`, or any custom sliver) with a non-sliver widget (`Semantics`, `Container`, `Padding`, `Center`) inside a `CustomScrollView`. The viewport expects `RenderSliver` children; wrapping with a non-sliver produces `RenderSemanticsAnnotations` which causes a `RenderViewport` type mismatch crash. Instead, add semantics INSIDE the sliver's children (e.g., wrap each list item in `Semantics`), or use `SliverToBoxAdapter` to bridge non-sliver widgets into the scroll view.

### RG-2: @Pixel — Widget Lifecycle Context Access Rule [HIGH, NEW]
**Evidence:** Phase4_HomeDiscovery session — called `AppMotion.respectMotion(context, ...)` in `initState()`, which accesses `MediaQuery` via `context.dependOnInheritedWidgetOfExactType`. This is forbidden before `initState()` completes.
**Current state:** NO rule in Pixel.md, Executor.md, or any agent file addresses initState vs didChangeDependencies.
**Rule text to add to Pixel.md:**

> **Widget Lifecycle Context Rule:** Never call methods that access inherited widgets (`MediaQuery.of(context)`, `Theme.of(context)`, `context.dependOnInheritedWidgetOfExactType<T>()`) inside `initState()`. The widget's `BuildContext` is not fully wired to the ancestor tree yet. Move such calls to `didChangeDependencies()`, which runs after `initState()` and whenever inherited dependencies change. Common patterns that violate this: `AppMotion.respectMotion(context, ...)`, `context.colorScheme`, `MediaQuery.disableAnimations`.

### RG-3: @Executor — Test Text Expectation Atomic Update Rule [MED, NEW]
**Evidence:** Phase4_HomeDiscovery session — empty state text changed from "No favorites yet." to "No favorites yet" (trailing period removed) but the test expectation was not updated until QA caught it.
**Current state:** NO rule in Executor.md or Sentinel.md addresses test string expectation updates.
**Rule text to add to Executor.md:**

> **Test Text Expectation Rule:** When changing user-facing text in a View (even punctuation changes), update the corresponding test expectations IN THE SAME PHASE — not deferred to QA. Grep for the old text string across `test/` immediately after the view change. If any test asserts the old text, update it before moving to the next phase.

### RG-4: @Sentinel — Infinite Animation Test Rule [MED, NEW]
**Evidence:** Phase4_HomeDiscovery session — `pumpAndSettle()` timed out because skeleton shimmer animations repeat forever (AnimationController with `..repeat()`). Existing rule says "always use pumpAndSettle when testing widgets with AnimationController" but this fails for infinite animations.
**Current state:** Sentinel.md line 323 says "Always use `pumpAndSettle()`" — this is WRONG for infinite animations.
**Rule text to AMEND in Sentinel.md:**

> **Amendment to Rule 4 (pumpAndSettle):** Use `pumpAndSettle()` for FINITE animations (AnimationController that calls `.forward()` or `.animateTo()`). For widgets containing INFINITE animations (shimmer with `..repeat()`, pulse with `..repeat(reverse: true)`, rotation loops), use `pump(Duration)` instead — `pumpAndSettle` will time out after 10 seconds. Common infinite-animation widgets: `SkeletonLoader`, `SkeletonTaskCard`, `ShimmerEffect`.

### RG-5: @Sentinel — DraggableScrollableSheet Test Rule [LOW, NEW]
**Evidence:** Phase4_HomeDiscovery session — `scrollUntilVisible` with `find.byType(Scrollable).last` failed because `DraggableScrollableSheet` introduces its own `Scrollable`, making `.last` ambiguous.
**Current state:** NO rule in Sentinel.md addresses DraggableScrollableSheet testing.
**Rule text to add to Sentinel.md:**

> **DraggableScrollableSheet Test Rule:** When testing widgets inside a `DraggableScrollableSheet`, do not use `scrollUntilVisible` with `find.byType(Scrollable).first` or `.last` — the sheet introduces nested `Scrollable` widgets that make the finder ambiguous. Instead, use `tester.drag(find.byType(DraggableScrollableSheet), Offset(0, -N))` to scroll the sheet content directly.

---

## 2) Rule Clarity Gaps

### RC-1: @Sentinel — pumpAndSettle Rule Needs Exception for Infinite Animations
**See RG-4 above.** The existing rule is too absolute. Needs amendment, not replacement.

---

## 3) MCP Recommendations

**None.** No session logs show manual work that a connected MCP tool could have automated. The Supabase MCP is available but unused because all Phase 4 work is pure View-layer with no backend interaction.

---

## 4) Missing Skills

**None.** All required skills (animate, normalize, harden, onboard, polish, delight, clarify, extract) are referenced in plans and executed successfully.

---

## 5) Agent Coordination Gaps

**None new.** All agent handoffs in Phase 4 worked correctly (@Planner → @Executor → @Sentinel/@Pixel/@Architect for review).

---

## 6) Orchestrator Pipeline Improvements

### OP-1: Stage 11.5 Runtime Smoke Test — STILL NEVER EXECUTED [LOW]
**Evidence:** Recommended in 3 previous evolution reports (v1, v1.5, v2). Never executed. Not a blocker for any session, but the pattern of recommending and ignoring suggests it should either be formalized as human-assisted or removed from recommendations.
**Action:** Mark as "Human Action Required — not automatable by agents."

---

## 7) New Agent Recommendations

**None.** Existing agent set covers all observed responsibilities.

---

## 8) Things the Human Missed

### TH-1: Pre-existing Flaky Test (6 sessions, NEVER fixed) [MED]
`wallet_shared_body_test.dart` has failed in every single execution session since Agent_CI. This erodes test suite trust and makes "zero new regressions" claims ambiguous.

### TH-2: 30 Skipped Integration Tests (6 sessions, NEVER run) [LOW]
Supabase integration tests are always skipped. Either they should be run periodically or removed.

---

## 9) Priority Action List

| Priority | Action | Agent | Evidence |
|----------|--------|-------|----------|
| P1 | Add Sliver Safety Rule (RG-1) | @Pixel | Phase4 — sliver in Semantics crash |
| P2 | Add Widget Lifecycle Context Rule (RG-2) | @Pixel | Phase4 — respectMotion in initState |
| P3 | Amend pumpAndSettle rule for infinite animations (RG-4) | @Sentinel | Phase4 — shimmer timeout |
| P4 | Add Test Text Expectation Atomic Update Rule (RG-3) | @Executor | Phase4 — "No favorites yet." mismatch |
| P5 | Add DraggableScrollableSheet Test Rule (RG-5) | @Sentinel | Phase4 — nested Scrollable |

---

## 10) Improvement Tracking

### Previously Applied (Confirmed Effective)
- Token Value Intentionality Check (Executor 3.8) — EFFECTIVE, no recurrence
- Plan Critique Review (Executor 3.9) — EFFECTIVE, used in LayoutTokens and Phase2
- Flutter API Verification (Pixel 3.3) — EFFECTIVE (now covers test code too)
- Widget Conversion Test Gate (Executor 3.9) — EFFECTIVE, test regressions caught earlier
- Token Value Extraction Workflow (Planner 2.2.6) — EFFECTIVE, no recurrence
- Logging Frequency Rule (Observability §10) — EFFECTIVE, no recurrence

### Previously Applied (Partially Effective)
- Per-Sub-Phase Test Gate (Executor 3.5) — Used but Phase4 still deferred some test fixes to QA

### Never Applied (Carry Forward)
- TH-1: Fix pre-existing flaky test — 6 sessions, never addressed
- TH-2: Run or remove skipped integration tests — 6 sessions, never addressed
- OP-1: Stage 11.5 Runtime Smoke Test — 3 reports, never formalized

---

## 11) Full Evidence Index

| Finding | Session Log | Line/Section |
|---------|-----------|-------------|
| RG-1 (Sliver safety) | SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md | "PROBLEM ENCOUNTERED" section, root cause #2 |
| RG-2 (initState context) | SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md | "PROBLEM ENCOUNTERED" section, root cause #5 |
| RG-3 (Test text atomic) | SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md | "PROBLEM ENCOUNTERED" section, root cause #4 |
| RG-4 (pumpAndSettle infinite) | SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md | "PROBLEM ENCOUNTERED" section, root cause #1 |
| RG-5 (DraggableScrollableSheet) | SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md | "PROBLEM ENCOUNTERED" section, root cause #3 |
| TH-1 (Flaky test) | All 6 execution session logs | "1 failed (pre-existing)" in every test count |
| TH-2 (Skipped tests) | All 6 execution session logs | "30 skipped" in every test count |

END.
