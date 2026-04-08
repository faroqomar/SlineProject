# @PlanCritic Audit: PLAN_DesignSystemFoundation_2026-04-07

**Plan audited:** `.TODO/PLAN_DesignSystemFoundation_2026-04-07.md`
**Audit date:** 2026-04-07
**Verdict:** ❌ **FAIL — 6 critical gaps must be fixed before execution**

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (Inferred Safely)
1. No pubspec.yaml changes needed (all proposed code uses existing Flutter SDK APIs).
2. `flutter analyze` and `flutter test` are runnable from current branch without setup.
3. The plan targets the `main` branch (or a feature branch off `main`).
4. `.impeccable.md` is generated interactively — the user answers questions from the `teach-impeccable` skill.

### Decision Needed (Blocking)

**DECISION 1: AppColorScheme already HAS `success`, `warning`, `info` as optional parameters with defaults (`Colors.green`, `Colors.orange`, `Colors.blue`).**

The plan proposes adding 8 new status color properties + 4 interactive colors. But `success`, `warning`, and `info` ALREADY EXIST as optional params with `Colors.*` defaults (which are Material defaults, not SLine design tokens).

- **Option A (Recommended):** Convert existing optional `success`/`warning`/`info` from `Colors.*` defaults to proper SLine token values. Add `danger` (currently `error` exists with value `AppColors.lightRed`). Add muted variants and interactive colors. This is 9 truly new properties, not 12.
- **Option B:** Ignore existing optionals and add all 12 as new required params alongside the old optionals. Creates duplicates.

**Impact:** Option A reduces scope and avoids duplicate color tokens. The plan MUST acknowledge that `success`, `warning`, `info` already exist and update their defaults rather than creating parallel properties.

**DECISION 2: Should `app_animations.dart` widget classes that ARE used (`SpringButton`, `AnimatedRotationButton` in `main_navigation_screen.dart`) be migrated to use `AppMotion` tokens internally?**

- **Option A (Recommended):** Yes — update `SpringButton` and `AnimatedRotationButton` to reference `AppMotion.*` constants instead of `AppAnimations.*`. This keeps them working and eliminates the old token dependency.
- **Option B:** Leave them as-is since they reference their own file's constants.

**Impact:** Option A ensures `AppAnimations` constants can be fully deprecated. Option B leaves lingering dependencies.

---

## B) Gate Status

| # | Gate | Status | Reason |
|---|------|--------|--------|
| 1 | Data / Contracts Gate | ✅ PASS | No database, no contracts. Theme-only changes. |
| 2 | Security / RLS Gate | ✅ PASS | No security impact. |
| 3 | Backend / Supabase Gate | ✅ PASS | No backend work. |
| 4 | UI / Integration Gate | ❌ **FAIL** | 6 critical gaps below. |
| 5 | Release / QA Gate | ❌ **FAIL** | Missing pre/post test baseline comparison. Missing commit strategy. |

---

## C) Critical Gaps (Must-Fix)

### GAP 1: `success`/`warning`/`info` already exist — plan will create duplicates or break constructor

**Why it will break:** The plan adds `success`, `warning`, `info` as new `required` properties to `AppColorScheme`. But these already exist as **optional** parameters with defaults (`Colors.green`, `Colors.orange`, `Colors.blue`). Adding them again as `required` will either: (a) cause a compile error from duplicate named params, or (b) require removing the old optionals first, which changes the `lerp()` method that already interpolates them.

**Fix:**
- [ ] (`@Pixel`) In Phase 6, Sub-step 6.1: Do NOT add `success`, `warning`, `info` as new properties. Instead, CHANGE their existing default values from `Colors.green`/`Colors.orange`/`Colors.blue` to the proper SLine tokens. Convert them from optional to required.
- [ ] (`@Pixel`) Add only truly new properties: `successMuted`, `warningMuted`, `infoMuted`, `danger`, `dangerMuted`, `hoverOverlay`, `pressedOverlay`, `focusRing`, `disabledFill`. That is 9 new + 3 modified = 12 color changes total.
- [ ] (`@Pixel`) Update `lerp()` — it already handles `success`, `warning`, `info`. Only add `lerp` lines for the 9 truly new properties.

**Owner:** @Pixel
**Acceptance check:** `flutter analyze` clean. No duplicate named parameters in `AppColorScheme` constructor.

---

### GAP 2: `app_animations.dart` — most code is dead, plan doesn't clean up

**Why it will break:** Scan proves `FadeInWidget`, `SlideUpWidget`, `HoverScaleWidget` are **completely unused** (0 references outside definition file). All `AppAnimations.*` constants are also **unused** outside the definition file. Only `SpringButton` and `AnimatedRotationButton` are used (both in `main_navigation_screen.dart`). The plan says "keep all 5 utility widgets" — this preserves 200+ lines of dead code.

**Fix:**
- [ ] (`@Architect`) Phase 2, new Sub-phase 2.2: Remove dead code from `app_animations.dart`:
  - Remove `FadeInWidget` class (unused).
  - Remove `SlideUpWidget` class (unused).
  - Remove `HoverScaleWidget` class (unused).
  - Keep `SpringButton` (used in main_navigation_screen.dart).
  - Keep `AnimatedRotationButton` (used in main_navigation_screen.dart).
- [ ] (`@Architect`) Update `SpringButton` and `AnimatedRotationButton` to reference `AppMotion.*` instead of `AppAnimations.*` constants.
- [ ] (`@Architect`) After widget migration, deprecate ALL `AppAnimations` constants (they will have zero consumers).

**Owner:** @Architect
**Acceptance check:** `flutter analyze` clean. `grep -r "FadeInWidget\|SlideUpWidget\|HoverScaleWidget" lib/` returns only import/export references (if barrel file exists) or zero matches.

---

### GAP 3: No commit strategy — plan doesn't say when to commit

**Why it will break:** The plan has 9 phases producing changes to 8+ files. If the executor does all phases without committing, a single failure in Phase 7 could require reverting all of Phases 2-6. If the executor commits after every sub-step, the git history is noisy and hard to revert.

**Fix:** Add a commit strategy section:
- Commit after Phase 1 (design context — `.impeccable.md` is independent).
- Commit after Phases 2+3 combined (motion tokens + interaction states — both are new files with no dependencies between them).
- Commit after Phase 4 (elevation — standalone addition to existing file).
- Commit after Phase 5 (typography — highest risk, must be independently revertible).
- Commit after Phase 6 (colors — large change to existing file, must be independently revertible).
- Commit after Phase 7 (component themes — depends on colors from Phase 6).
- Commit after Phase 8 (docs — no-risk).
- **Total: 7 commits.**

**Owner:** @Sentinel
**Acceptance check:** Each commit passes `flutter analyze` independently.

---

### GAP 4: No test baseline captured before changes

**Why it will break:** The plan says "Run `flutter test` — must produce zero new failures." But without capturing the baseline BEFORE changes, there's no way to distinguish pre-existing failures from regressions. The project has 982 tests — some might already be failing or flaky.

**Fix:**
- [ ] (`@Sentinel`) Phase 0, new Sub-phase 0.3: Run `flutter test` and capture baseline: total tests, passed, failed, skipped. Record in session log.
- [ ] (`@Sentinel`) Phase 9: Compare post-change test results against baseline. Only failures that didn't exist in baseline count as regressions.

**Owner:** @Sentinel
**Acceptance check:** Session log has before/after test counts.

---

### GAP 5: Typography height change risk is acknowledged but not mitigated

**Why it will break:** The plan acknowledges that changing body text from `height: 1.2` → `1.5` (a 25% increase in line height) will shift layouts. But the ONLY mitigation is "document failures and fix in Phase 1." This is not enough — if 30+ widget tests fail, the executor will be stuck with a broken test suite until Phase 1 of UI Redesign (which could be weeks away).

**Fix:**
- [ ] (`@Pixel`) Phase 5, new Sub-phase 5.2: After updating typography, immediately run `flutter test`. If > 5 test failures:
  - Option A: Adjust body heights to a smaller increment (1.2 → 1.35 instead of 1.5) as a stepping-stone. Full 1.5 deferred to Phase 1 widget updates.
  - Option B: Keep 1.5 but add `TODO(phase-1)` comments on each failing test and mark them `skip: true` with reason "Phase 0 typography height change — layout will be fixed in Phase 1". Count skipped tests.
  - Document chosen option in session log.
- [ ] (`@Sentinel`) Record exact failure count and test names.

**Owner:** @Pixel + @Sentinel
**Acceptance check:** `flutter test` either passes clean OR has a documented, bounded list of skipped tests with a clear path to fix.

---

### GAP 6: Figma sync is vague — "document the approach" is not execution-ready

**Why it will break:** Phase 9.5 says "Document the Figma token export approach" with 3 options. This is a research task, not a deliverable. After Phase 0, there should be an actual Figma artifact, not just a documented intention.

**Fix:**
- [ ] (`@Pixel`) Phase 9.5: Replace "document approach" with:
  - Run `mcp__Figma__create_design_system_rules` to generate design system rules from codebase.
  - Create a Figma page (or frame in existing file) with token reference: colors (swatches), typography scale (samples), elevation (shadow demo), motion (duration/curve table).
  - Method: screenshot the `theme_dashboard.dart` output and import to Figma as reference frame. Low-effort, high-value.
- Record Figma file URL or node ID in session log.

**Owner:** @Pixel
**Acceptance check:** A Figma artifact exists (even if minimal) with token reference.

---

## D) Invariants & Success Criteria (Non-Negotiable)

| # | Invariant | How to Enforce | How to Verify |
|---|-----------|----------------|---------------|
| 1 | No feature files modified | Plan scope excludes `lib/features/` | `git diff --name-only` shows only `lib/core/` and root files |
| 2 | `AppColorScheme` constructor has no duplicate named params | Don't add `success`/`warning`/`info` as new params (they exist) | `flutter analyze` clean |
| 3 | All theme token files are in `lib/core/theme/` | New files placed there | File path check |
| 4 | `flutter analyze` passes after each phase | Run after every phase | CI or manual run |
| 5 | `flutter test` has no NEW failures | Baseline comparison | Before/after test counts |
| 6 | No dead code introduced | Unused widgets cleaned up | Grep for unused classes |
| 7 | `AppMotion` is the sole source of truth for motion tokens | `AppAnimations` constants deprecated | Grep for `AppAnimations.fast` etc. — only deprecated definition remains |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Typography height breaks tests | Phase 5 | HIGH (70%) | MEDIUM | 5-30 tests | First `flutter test` run | Smaller increment (1.35) | Skip + document |
| AppColorScheme constructor duplicate params | Phase 6 | HIGH (90% if plan unchanged) | HIGH | Compile failure | `flutter analyze` | Fix GAP 1 above | Revert Phase 6 |
| Component themes override existing widget styling | Phase 7 | MEDIUM (40%) | LOW | Visual changes | Visual spot check | Review each theme carefully | Remove offending theme |
| `teach-impeccable` doesn't capture all context | Phase 1 | LOW (20%) | LOW | Weaker skill output | Review `.impeccable.md` | Manual review + edits | Edit `.impeccable.md` manually |
| Dark mode elevation shadows invisible | Phase 4 | MEDIUM (30%) | LOW | Dark mode only | Visual check | isDark multiplier | Adjust alpha values |
| `lerp()` missing new color fields | Phase 6 | MEDIUM (50%) | HIGH | Theme transition crash | Animated theme switch | Careful implementation | Revert Phase 6 |

---

## F) Pre-Mortem

1. **This fails when** the executor adds `required this.success` to `AppColorScheme` without removing the existing optional `this.success = Colors.green`, causing a compile error that blocks all subsequent phases.
2. **This fails when** typography height changes cause 20+ test failures and the executor spends hours debugging tests instead of progressing through the plan.
3. **This fails when** the `lerp()` method is updated for 9 new properties but the executor misses one, causing a crash only when the user toggles light↔dark mode (an edge case not caught by `flutter analyze`).
4. **This fails when** `SpringButton` in `main_navigation_screen.dart` still references `AppAnimations.scalePressed` after deprecation, and `flutter analyze` shows deprecation warnings that the executor ignores, then a future cleanup accidentally breaks the nav bar.
5. **This fails when** the executor doesn't commit between phases, Phase 6 breaks, and reverting also undoes Phase 5 typography changes that were clean and valuable.
6. **This fails when** the `teach-impeccable` skill asks questions the user hasn't considered, the user gives superficial answers, and all subsequent skill runs produce generic output because `.impeccable.md` is shallow.
7. **This fails when** `ChipThemeData` in Phase 7 sets `backgroundColor: Colors.transparent` but existing Chip widgets throughout the app relied on the Material default background color, making all chips invisible.
8. **This fails when** `BottomSheetThemeData` sets `showDragHandle: true` but existing bottom sheets already have custom drag handles, resulting in double drag handles.

---

## G) Plan Fixes (Concrete Additions)

### FIX 1: Add Phase 0.3 — Capture Test Baseline
- **Goal:** Record test pass/fail/skip counts before any code changes.
- **Why:** Can't detect regressions without a baseline.
- **How:** Run `flutter test`, capture output. Record in session log.
- **Output artifact:** Session log entry with baseline numbers.
- **Stop condition:** Baseline recorded.

### FIX 2: Restructure Phase 6 for Existing Optional Params
- **Goal:** Prevent duplicate constructor parameters.
- **Why:** `success`, `warning`, `info` already exist as optional params.
- **How:** Convert optionals to required with new default values. Add only 9 new properties.
- **Output artifact:** Updated `app_colors.dart` without duplicates.
- **Stop condition:** `flutter analyze` clean, no duplicate named params.

### FIX 3: Add Dead Code Removal to Phase 2
- **Goal:** Remove 200+ lines of unused animation widgets.
- **Why:** `FadeInWidget`, `SlideUpWidget`, `HoverScaleWidget` have zero usages.
- **How:** Delete unused classes. Migrate `SpringButton`/`AnimatedRotationButton` to `AppMotion` tokens.
- **Output artifact:** Leaner `app_animations.dart` (~130 lines instead of 330).
- **Stop condition:** `grep` confirms zero references to removed classes.

### FIX 4: Add Commit Strategy
- **Goal:** Each phase is independently revertible.
- **Why:** Prevents cascading rollbacks.
- **How:** 7 commits at specified phase boundaries.
- **Output artifact:** Git log with 7 clean commits.
- **Stop condition:** Each commit passes `flutter analyze`.

### FIX 5: Add Typography Risk Mitigation
- **Goal:** Bounded test failure from height changes.
- **Why:** 25% body text height increase will shift layouts.
- **How:** Run tests immediately, apply fallback if > 5 failures.
- **Output artifact:** Either clean tests or documented skip list.
- **Stop condition:** `flutter test` passes (with or without bounded skips).

### FIX 6: Make Figma Sync Concrete
- **Goal:** Actual Figma artifact, not just documented approach.
- **Why:** "Document the approach" is research, not delivery.
- **How:** Run `mcp__Figma__create_design_system_rules` + create token reference frame.
- **Output artifact:** Figma page with color/type/elevation/motion tokens.
- **Stop condition:** Figma artifact exists and is linked in session log.

### FIX 7: Add BottomSheet/Chip Theme Collision Check
- **Goal:** Prevent double drag handles and invisible chips.
- **Why:** Pre-mortem items 7 and 8.
- **How:** Before adding themes, grep for existing `showDragHandle`, `DragHandle`, and `Chip(backgroundColor:` overrides in feature code. If > 3 collisions, make the theme properties less aggressive (e.g., `showDragHandle: false` as default, let individual sheets opt in).
- **Output artifact:** Grep results in session log.
- **Stop condition:** Visual spot check shows no double handles or invisible chips.

---

## H) Corrected Plan (Execution-Ready)

> The corrected plan incorporates all 7 fixes above. Changes from original are marked with **[ADDED]**, **[CHANGED]**, or **[EXPANDED]**.

The corrected plan is **the same as the original** with these specific modifications inserted:

### Phase 0: Preconditions & Gates
**[ADDED] Sub-phase 0.3: Test Baseline**
- [ ] (`@Sentinel`) Run `flutter test --reporter=compact`. Record: total, passed, failed, skipped.
- [ ] (`@Sentinel`) Record baseline in session log under `### [BASELINE CAPTURED]`.
- **GATE CHECK:** Baseline recorded. Any pre-existing failures documented.

**[ADDED] Sub-phase 0.4: Theme Collision Scan**
- [ ] (`@Architect`) Grep for `showDragHandle` in `lib/features/` — count instances.
- [ ] (`@Architect`) Grep for `Chip(backgroundColor` or `ChipTheme` in `lib/features/` — count instances.
- [ ] (`@Architect`) Grep for `DialogTheme` or `AlertDialog(backgroundColor` in `lib/features/` — count instances.
- [ ] (`@Architect`) Record collision counts in session log. If any count > 3, flag for Phase 7 adjustment.
- **GATE CHECK:** Collision data recorded.

**[ADDED] Sub-phase 0.5: Commit Strategy Lock**
- [ ] (`@Sentinel`) Confirm 7-commit plan:
  1. After Phase 1 (`.impeccable.md`)
  2. After Phases 2+3 (motion + states)
  3. After Phase 4 (elevation)
  4. After Phase 5 (typography)
  5. After Phase 6 (colors)
  6. After Phase 7 (component themes)
  7. After Phase 8 (docs)
- **GATE CHECK:** Strategy documented.

### Phase 2: Motion Tokens — [CHANGED]
**Sub-phase 2.2: Clean Dead Code + Migrate Used Widgets**
- [ ] (`@Architect`) Delete `FadeInWidget` class from `app_animations.dart` (0 usages confirmed).
- [ ] (`@Architect`) Delete `SlideUpWidget` class from `app_animations.dart` (0 usages confirmed).
- [ ] (`@Architect`) Delete `HoverScaleWidget` class from `app_animations.dart` (0 usages confirmed).
- [ ] (`@Architect`) In `SpringButton`: replace `AppAnimations.scalePressed` → `AppMotion.pressScale`, `AppAnimations.fast` → `AppMotion.fast`, `AppAnimations.springCurve` → `AppMotion.curveSpring`.
- [ ] (`@Architect`) In `AnimatedRotationButton`: replace `AppAnimations.slow` → `AppMotion.slow`, `AppAnimations.scaleActive` → `AppMotion.emphasize`, `AppAnimations.springCurve` → `AppMotion.curveSpring`.
- [ ] (`@Architect`) Add import for `app_motion.dart` in `app_animations.dart`.
- [ ] (`@Sentinel`) Verify `flutter analyze` clean.
- [ ] (`@Sentinel`) Verify `main_navigation_screen.dart` still compiles (uses `SpringButton` and `AnimatedRotationButton`).

**Sub-phase 2.3: Deprecate AppAnimations Constants** — unchanged from original.

### Phase 5: Typography — [EXPANDED]
**[ADDED] Sub-phase 5.2: Immediate Regression Check**
- [ ] (`@Sentinel`) Run `flutter test`. Compare against Phase 0.3 baseline.
- [ ] (`@Sentinel`) If 0 new failures: proceed. Record "Typography: 0 regressions" in session log.
- [ ] (`@Sentinel`) If 1-5 new failures: document each (file, test name, cause). Mark as Phase 1 fixes. Proceed.
- [ ] (`@Pixel`) If > 5 new failures: STOP. Apply fallback — change body heights to intermediate values:
  - `bodyLarge`: 1.5 → 1.35
  - `bodyMedium`: 1.5 → 1.35
  - `bodySmall`: 1.4 → 1.3
  - Re-run tests. If still > 5 failures, revert to original `height: 1.2` and defer ALL height changes to Phase 1 of UI Redesign.
- [ ] (`@Sentinel`) Record final typography decision and test counts in session log.
- **GATE CHECK:** Test suite healthy (zero new failures, or bounded documented skips <= 5).

### Phase 6: Semantic Colors — [CHANGED]
**Sub-phase 6.1: Modify Existing Optional Params + Add New Properties**
- [ ] (`@Pixel` | Skill: `colorize`) In `AppColorScheme`:
  - Sub-step 6.1.1: Convert `this.success = Colors.green` from optional to required. Remove default.
  - Sub-step 6.1.2: Convert `this.warning = Colors.orange` from optional to required. Remove default.
  - Sub-step 6.1.3: Convert `this.info = Colors.blue` from optional to required. Remove default.
  - Sub-step 6.1.4: Add `required this.successMuted` (NEW).
  - Sub-step 6.1.5: Add `required this.warningMuted` (NEW).
  - Sub-step 6.1.6: Add `required this.infoMuted` (NEW).
  - Sub-step 6.1.7: Add `required this.danger` (NEW).
  - Sub-step 6.1.8: Add `required this.dangerMuted` (NEW).
  - Sub-step 6.1.9: Add `required this.hoverOverlay` (NEW).
  - Sub-step 6.1.10: Add `required this.pressedOverlay` (NEW).
  - Sub-step 6.1.11: Add `required this.focusRing` (NEW).
  - Sub-step 6.1.12: Add `required this.disabledFill` (NEW).
  - **Total: 3 converted (optional→required with new values) + 9 new = 12 color properties.**

**Sub-phase 6.2: Update Factories** — [CHANGED]
- [ ] (`@Pixel` | Skill: `colorize`) In `light()` factory:
  - Sub-step 6.2.1: Change `success` from default `Colors.green` → `Color(0xFF2E7D32)`.
  - Sub-step 6.2.2: Change `warning` from default `Colors.orange` → `Color(0xFFF57F17)`.
  - Sub-step 6.2.3: Change `info` from default `Colors.blue` → `Color(0xFF1565C0)`.
  - Sub-steps 6.2.4-6.2.12: Add all 9 new property values (same as original plan).
- [ ] (`@Pixel` | Skill: `colorize`) In `dark()` factory: same pattern (update 3, add 9).
- [ ] (`@Pixel`) In `lerp()`: `success`, `warning`, `info` are ALREADY handled. Add `Color.lerp` for only the 9 new properties: `successMuted`, `warningMuted`, `infoMuted`, `danger`, `dangerMuted`, `hoverOverlay`, `pressedOverlay`, `focusRing`, `disabledFill`.

### Phase 7: Component Themes — [EXPANDED]
**[ADDED] Sub-phase 7.0: Collision-Aware Adjustments**
- [ ] (`@Pixel`) Review Phase 0.4 collision scan results.
- [ ] (`@Pixel`) If `showDragHandle` has > 3 existing usages: set `BottomSheetThemeData.showDragHandle: false` (let individual sheets opt in).
- [ ] (`@Pixel`) If `Chip(backgroundColor:` has > 3 existing overrides: use `backgroundColor: null` in ChipThemeData (defer to per-widget).
- [ ] (`@Pixel`) If `AlertDialog(backgroundColor:` has > 3 existing overrides: use a less aggressive `DialogTheme` (match existing pattern).

### Phase 9: QA — [EXPANDED]
**Sub-phase 9.5: Figma Sync** — [CHANGED from "document approach"]
- [ ] (`@Pixel`) Run `mcp__Figma__create_design_system_rules` on the codebase.
- [ ] (`@Pixel`) Create Figma token reference: screenshot `theme_dashboard.dart` or create manual frames for colors, typography, elevation, motion.
- [ ] (`@Pixel`) Record Figma file/page reference in session log.
- **GATE CHECK:** Figma artifact exists (minimal acceptable: screenshot of theme dashboard imported as frame).

---

## I) Change Report (Diff-Style)

### 1. Original Issues Summary
- Plan was well-structured with 9 phases, 60+ steps, proper agent/skill assignment.
- 6 critical gaps found: constructor duplication, dead code retention, no commit strategy, no test baseline, unbounded typography risk, vague Figma deliverable.

### 2. Added Steps
- Phase 0.3: Test baseline capture (2 steps)
- Phase 0.4: Theme collision scan (4 steps)
- Phase 0.5: Commit strategy lock (1 step)
- Phase 2.2: Dead code removal + widget migration (8 steps) — replaces "keep all 5 widgets"
- Phase 5.2: Immediate regression check with fallback (5 steps)
- Phase 7.0: Collision-aware adjustments (4 steps)
- Phase 9.5: Concrete Figma sync (3 steps) — replaces "document approach"
- **Total: 27 new steps added.**

### 3. Removed Steps
- Phase 6.1 sub-steps 6.1.1-6.1.3 (adding `success`/`warning`/`info` as new properties) — replaced with conversion of existing optionals.

### 4. Reordered Steps
- None. Phase ordering is correct.

### 5. Expanded Steps
- Phase 2.2: "Keep all 5 utility widgets" → "Delete 3 unused, migrate 2 used, update imports"
- Phase 6.1: "Add 12 properties" → "Convert 3 optionals + add 9 new = 12 total"
- Phase 6.2: "Update lerp for 12" → "lerp already handles 3; update for 9 new only"
- Phase 9.5: "Document approach (3 options)" → "Execute Figma sync with concrete deliverable"

### 6. Why
- GAP 1: Prevents compile error from duplicate named params.
- GAP 2: Removes 200+ lines of dead code. Clean codebase principle.
- GAP 3: Enables independent rollback per phase.
- GAP 4: Makes regression detection scientific, not subjective.
- GAP 5: Prevents a broken test suite blocking development for weeks.
- GAP 6: Converts research into delivery.
- GAP 7: Prevents double drag handles and invisible chips.

### 7. Residual Risks
- Typography height changes at 1.35 (fallback) may still be too aggressive for some card layouts. Final value (1.5) deferred to Phase 1.
- Component themes may still cause subtle visual shifts in existing screens — visual spot check is the only mitigation (no automated visual regression testing in place).
- `teach-impeccable` output quality depends on user engagement with questions — shallow answers produce shallow design context.

---

**Plan is now PASS-ready once all 7 fixes are applied.**
**The @Executor should read this critique alongside the plan.**

END.
