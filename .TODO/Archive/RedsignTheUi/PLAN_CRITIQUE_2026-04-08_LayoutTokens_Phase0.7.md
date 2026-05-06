# @PlanCritic Audit: PLAN_LayoutTokens_Phase0.7_2026-04-08

**Auditor:** @PlanCritic
**Date:** 2026-04-08
**Plan Under Review:** `.TODO/PLAN_LayoutTokens_Phase0.7_2026-04-08.md`
**Verdict:** ❌ **FAIL — 7 Critical Gaps Found. Plan must be corrected before execution.**

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (Inferred)
1. Phase 0, 1, and 2 are fully complete and stable — confirmed by session logs.
2. Test baseline is 1297 passed / 30 skipped / 1 pre-existing failure — confirmed.
3. `app_layout.dart` does not exist — confirmed.
4. Widget file count is 15 (not 16 as the plan hedges) — scan confirms 15 files.
5. The plan targets zero visual change — all token values must match CURRENT hardcoded values.
6. `main_navigation_screen.dart` in `lib/app/` is out of scope (feature-level file).

### Decision Needed (Blocking)

**Decision 1: Icon size naming collision with AppDimens**
- **What:** The plan proposes `AppLayout.iconSmall = 16`, `AppLayout.iconMedium = 24`, `AppLayout.iconLarge = 32` which are IDENTICAL values to `AppDimens.iconSizeSmall = 16`, `AppDimens.iconSizeMedium = 24`, `AppDimens.iconSizeLarge = 32`. This creates TWO sources of truth for the same values with confusingly similar names.
- **Options:**
  - A) Keep both, document the overlap in comments (current plan approach)
  - B) `AppLayout` icon tokens reference `AppDimens.iconSize*` values instead of re-declaring (e.g., `static const double iconSmall = AppDimens.iconSizeSmall;`)
  - C) Remove overlapping icon sizes from `AppLayout`, keep only the NEW sizes (iconTiny=12, iconStandard=20, iconFeature=48)
- **Recommended:** Option C. Three overlapping tokens is confusing. `AppLayout` adds only what `AppDimens` doesn't have.
- **Impact:** Phase 1 sub-steps 1.7.2, 1.7.4, 1.7.5 change or are removed.

**Decision 2: Skeleton widgets — token coverage scope**
- **What:** `skeleton_card.dart` (515 lines) and `skeleton_card_extended.dart` (351 lines) are HEAVILY hardcoded with dozens of unique dimension values (34, 17, 90, 120, 6, 70, etc.) that do NOT map to any proposed `AppLayout` token. The plan says "replace hardcoded values with AppLayout.* tokens" but most values in these files have no matching token.
- **Options:**
  - A) Add dozens of skeleton-specific tokens to `AppLayout` (pollutes the token file with skeleton-only values)
  - B) Only replace values that match existing tokens (e.g., padding=16 → AppLayout.cardPadding), leave skeleton-specific dimensions hardcoded
  - C) Skip skeleton files entirely in this phase — they're rendering placeholders, not real content
- **Recommended:** Option B. Replace only values with semantic meaning (padding, spacing, border radius). Leave skeleton-specific widths/heights (34, 90, 120) as hardcoded — they mimic content, not layout.
- **Impact:** Phase 5 scope shrinks significantly. Expectations must be explicit about what gets replaced and what stays.

---

## B) Gate Status

### Gate 1: Data / Contracts Gate — ✅ PASS
- No data model or contract changes.
- Pure UI/theme token work.

### Gate 2: Security / RLS Gate — ✅ PASS
- No security implications.
- Layout tokens are compile-time constants with zero runtime behavior.

### Gate 3: Backend / Supabase Gate — ✅ PASS
- No backend changes.

### Gate 4: UI / Integration Gate — ❌ FAIL
- **Reason 1:** Plan does NOT account for `main_navigation_screen.dart` which has `bottom: 100` (FAB offset) and `width: 56, height: 56` (FAB dimensions) hardcoded. The plan proposes `AppLayout.fabBottomOffset = 100` and `AppLayout.fabSize = 56` but never plans to wire these to the actual file that uses them. Either the file must be in scope or the tokens are orphans with no consumers in this phase.
- **Reason 2:** Plan proposes `AppLayout.bottomNavHeight = 64` but the ACTUAL bottom nav height is `70` (verified in `custom_bottom_nav_bar.dart` line 110: `height: 70`). **Wrong value in plan.**
- **Reason 3:** Plan proposes `AppLayout.circleIconButtonSize = 48` but the actual default is `size = 40` (line 33) with a WCAG touch target SizedBox of `48` (line 69). These are two different concepts — the button visual size vs the touch target. Plan conflates them.
- **Reason 4:** Plan proposes `AppLayout.buttonHeight = 48` but `app_button.dart` uses `AppDimens.p54` as its default height. The actual default button height is **54, not 48**.
- **Reason 5:** Missing risk assessment for tests that assert specific pixel values. 3 test files have hardcoded dimension assertions (`circle_icon_button_test.dart` asserts `maxWidth == 40`, `sliver_tab_bar_delegate_test.dart` asserts `preferredSize.height`, `scale_button_test.dart` asserts `opacity == 0.38`).
- **Fix:** Correct all token values to match ACTUAL codebase. Add test assertion audit sub-phase. Either include `main_navigation_screen.dart` or remove orphan tokens.

### Gate 5: Release / QA Gate — ❌ FAIL
- **Reason 1:** Plan's test regression strategy is "run flutter test and hope." No specific plan to audit the 3 test files with pixel-value assertions BEFORE modifying the widgets they test.
- **Reason 2:** No explicit "token value verification" step that greps the actual codebase value BEFORE writing the token. The plan assumes Master Plan values are correct — scan proves at least 3 are wrong (bottomNavHeight 64→70, buttonHeight 48→54, circleIconButtonSize conflated).
- **Fix:** Add explicit "read file, extract value, write token" workflow per sub-phase. Add test assertion audit in Phase 0.

---

## C) Critical Gaps (Must-Fix)

### Gap 1: Wrong token values — plan assumes Master Plan values, codebase has drifted
- **Why it will break:** `AppLayout.bottomNavHeight = 64` → actual is 70. `AppLayout.buttonHeight = 48` → actual default is 54. `AppLayout.circleIconButtonSize = 48` → actual visual size is 40, touch target is 48. If tokens are created with wrong values and widgets are migrated to use them, layout WILL break. This directly violates the plan's own "zero visual change" acceptance criterion.
- **Fix:** Add a mandatory "Value Extraction" sub-step to Phase 1 for EVERY token category. The executor MUST read the actual widget file, extract the actual value, and use THAT — not the Master Plan's suggested value. Add a verification table in the session log.
- **Owner:** @Pixel (extraction), @Sentinel (verification)
- **Acceptance check:** Every token value has a comment citing the source file and line number where the value was extracted from.

### Gap 2: Skeleton files are heavily hardcoded with non-semantic values
- **Why it will break:** The plan says "migrate skeleton_card.dart" but most values (34, 17, 90, 120, 6, 70) are skeleton-specific placeholder dimensions that have no semantic layout meaning. Forcing these into `AppLayout` pollutes the token file. Not replacing them leaves the migration "incomplete" by the plan's own audit criteria.
- **Fix:** Explicitly define the migration rule: "Only replace values that map to an existing `AppLayout` semantic token. Document remaining hardcoded values as intentional exceptions." Add this rule to Phase 0 Spec Lock.
- **Owner:** @Architect (rule), @Sentinel (audit)
- **Acceptance check:** Each skeleton file's migration notes list which values were replaced, which were kept, and why.

### Gap 3: Test assertion regression risk not accounted for
- **Why it will break:** `circle_icon_button_test.dart` asserts `maxWidth == 40 && maxHeight == 40`. If the plan changes the default from 40 to `AppLayout.circleIconButtonSize` and the token is 48, the test breaks. The plan has NO step to audit test assertions before modifying widgets.
- **Fix:** Add Phase 0.3 "Test Assertion Audit" — for every core widget that has tests with pixel-value assertions, document the asserted values and verify they match the planned token values.
- **Owner:** @Sentinel
- **Acceptance check:** Test assertion inventory table with columns: Test File | Asserted Value | Matching Token | Status (match/conflict).

### Gap 4: Icon size naming creates confusion
- **Why it will break:** `AppLayout.iconSmall = 16` and `AppDimens.iconSizeSmall = 16` are the same value with almost the same name. Developers will randomly use one or the other. Code reviews will disagree on which is "correct." This is a maintenance hazard.
- **Fix:** Per Decision 1, remove overlapping icon sizes from `AppLayout`. Keep only `iconTiny` (12), `iconStandard` (20), `iconFeature` (48) — sizes that `AppDimens` doesn't have.
- **Owner:** @Architect
- **Acceptance check:** Zero overlapping icon size values between `AppLayout` and `AppDimens`.

### Gap 5: `main_navigation_screen.dart` orphan tokens
- **Why it will break:** Plan creates `AppLayout.fabBottomOffset = 100` and `AppLayout.fabSize = 56` but `main_navigation_screen.dart` is explicitly out of scope. These tokens have zero consumers in this phase. Orphan tokens are confusing — they suggest the migration is incomplete.
- **Fix:** Either (A) include `main_navigation_screen.dart` in scope since it's in `lib/app/` not `lib/features/`, or (B) add these tokens with a `// TODO: Wire to main_navigation_screen.dart in Phase N` comment explaining they're pre-defined for the app shell phase.
- **Owner:** @Architect (scope decision)
- **Acceptance check:** Every token in `app_layout.dart` either has a consumer in this phase OR has a doc comment citing the planned consumer.

### Gap 6: Missing "signed_image.dart" default value analysis
- **Why it will break:** `signed_image.dart` has `width = 100, height = 80, borderRadius = 12` as defaults. None of these map to proposed tokens. The plan says "replace with AppLayout.thumbnailSmall (60) or thumbnailMedium (80)" but the actual default width is 100 and height is 80. The width doesn't match ANY proposed token.
- **Fix:** Either add `AppLayout.signedImageWidth = 100` or document that `signed_image.dart` defaults are caller-overridden parameters (the widget accepts size from its parent, defaults are just fallbacks). If the latter, migration is: leave defaults as-is, callers use `AppLayout.*` when constructing the widget.
- **Owner:** @Pixel
- **Acceptance check:** `signed_image.dart` migration decision is documented with rationale.

### Gap 7: `app_card.dart` is already clean — wasted migration phase
- **Why it will break:** Won't break, but wastes execution time. `app_card.dart` already uses `AppDimens.p16` and `AppDimens.r20` — it has ZERO hardcoded layout values. The plan allocates migration steps for it anyway.
- **Fix:** Phase 0.2 Discovery Scan must classify each file as "needs migration" or "already clean" BEFORE Phase 2-6 execution. Files already using tokens are marked as no-op.
- **Owner:** @Sentinel
- **Acceptance check:** Discovery scan produces a classification table: File | Status (needs migration / clean / skip).

---

## D) Invariants & Success Criteria (Non-Negotiable)

| # | Invariant | How to Enforce | How to Verify |
|---|-----------|---------------|---------------|
| 1 | Zero visual change — every token value matches current codebase | Extract values from code, not from Master Plan | `flutter test` passes + visual spot check |
| 2 | No View imports or calls Supabase directly | `app_layout.dart` is a pure constant file | `flutter analyze` CI check |
| 3 | `AppLayout` has no runtime behavior | Private constructor, `static const` only, no methods | Code review |
| 4 | `AppDimens` is not modified or deprecated | Phase scope excludes `app_dimens.dart` changes | Git diff shows no changes to `app_dimens.dart` |
| 5 | No feature files (`lib/features/`) are touched | Scope is `lib/core/` only | `git diff --name-only` filtered to `lib/features/` shows empty |
| 6 | Token names are unambiguous | No naming overlap with `AppDimens` for same values | Review: no `AppLayout.X == AppDimens.Y` where X ≈ Y |
| 7 | Every token has a doc comment | Mandatory per CLAUDE.md code comment rules | Grep for `static const` without preceding `///` |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Token value mismatch causes layout shift | Any migrated widget | HIGH (proven: 3 values already wrong) | MEDIUM (visual regression) | Per-widget | Test failure or visual diff | Extract from code, not plan | Fix token value |
| Skeleton migration scope creep | skeleton_card.dart, skeleton_card_extended.dart | HIGH | LOW (wasted time) | 2 files | Executor starts adding skeleton-specific tokens | Define "only semantic tokens" rule | Skip skeletons |
| Test assertion regression | circle_icon_button_test.dart | MEDIUM | LOW (test failure, easy fix) | 1 test file | `flutter test` failure | Audit test assertions before modifying | Update test value |
| Icon naming confusion | app_layout.dart vs app_dimens.dart | HIGH | LOW (maintenance debt) | All future developers | PR review disagreements | Remove overlapping icon sizes | Add cross-reference comments |
| Orphan tokens never consumed | fabBottomOffset, fabSize | MEDIUM | LOW (dead code) | 1 file | Lint for unused references | Document planned consumers | Delete if unclaimed |
| `signed_image.dart` defaults don't map to tokens | signed_image.dart | HIGH | LOW (incomplete migration) | 1 file | Executor can't find matching token | Pre-classify defaults as "caller responsibility" | Leave defaults, migrate callers |

---

## F) Pre-Mortem (How This Fails In Real Life)

1. **This fails when** the executor creates `AppLayout.bottomNavHeight = 64` (from Master Plan) but the actual nav bar is 70px. A downstream phase uses the token for FAB positioning and the FAB overlaps the nav bar by 6px.

2. **This fails when** the executor migrates `skeleton_card.dart` and spends 2 hours creating tokens for `width: 34, height: 17, borderRadius: 90` — values that are skeleton-specific and will never be reused. The token file becomes a junk drawer.

3. **This fails when** the executor replaces `size = 40` in `circle_icon_button.dart` with `AppLayout.circleIconButtonSize` set to 48 (touch target, not visual size). The button renders 8px larger, breaking layout.

4. **This fails when** a developer months later wants to set an icon to 24px. They find `AppLayout.iconMedium = 24` AND `AppDimens.iconSizeMedium = 24`. They use one in file A and the other in file B. Neither is "wrong" but the codebase becomes inconsistent.

5. **This fails when** `app_button.dart` is migrated to use `AppLayout.buttonHeight = 48` but its actual default is `AppDimens.p54` (54px). Every screen using AppButton without an explicit height gets 6px shorter. All button-adjacent elements shift.

6. **This fails when** the executor changes `signed_avatar.dart` default `radius: 20` to `AppLayout.avatarMedium / 2` (44/2 = 22). The avatar renders 4px larger in diameter everywhere it uses the default.

7. **This fails when** `app_card.dart` is "migrated" but there's nothing to change (it already uses AppDimens tokens). The session log says "migrated" but git diff shows zero changes, confusing the reviewer.

8. **This fails when** Phase 8 QA runs `flutter test` and finds 0 new failures — because the wrong token values cancel out (token says 48 but widget was already using AppDimens.p48). The test passes but the semantic meaning is wrong — `buttonHeight` should be 54, not 48.

---

## G) Plan Fixes (Concrete Additions / Expansions)

### Fix 1: Add Phase 0.3 — Test Assertion Audit
- **Goal:** Identify all test files that assert specific pixel values on core widgets.
- **Why:** 3 test files have dimension assertions that will break if token values differ from current values.
- **How:** Grep test files for `expect(.*size`, `expect(.*width`, `expect(.*height`, `expect(.*opacity`, `constraints`.
- **Output artifact:** Test Assertion Inventory table in session log.
- **Stop condition:** Every pixel assertion is documented with its current value.

### Fix 2: Add "Value Extraction" workflow to Phase 1
- **Goal:** Ensure every token value is extracted from the ACTUAL codebase, not assumed from the Master Plan.
- **Why:** At least 3 values are wrong (bottomNavHeight 64→70, buttonHeight 48→54, circleIconButtonSize conflated 40/48).
- **How:** For each token category, the executor reads the source widget file, extracts the actual value, and records it with file:line citation.
- **Output artifact:** Value Extraction Table in session log with columns: Token | Planned Value | Actual Value | Source File:Line | Decision.
- **Stop condition:** Every token has a verified value with source citation.

### Fix 3: Add "Migration Classification" to Phase 0.2 Discovery Scan
- **Goal:** Classify each core widget as "needs migration" / "already clean" / "skip (no semantic values)" BEFORE migration phases.
- **Why:** `app_card.dart` is already clean. Skeleton files are mostly non-semantic. Classifying upfront prevents wasted work.
- **How:** Read each file, list hardcoded values, classify as semantic (maps to AppLayout token) or non-semantic (one-off, skeleton-specific, animation-related).
- **Output artifact:** Migration Classification Table in session log.
- **Stop condition:** Every file has a classification.

### Fix 4: Remove overlapping icon sizes from AppLayout
- **Goal:** Eliminate `AppLayout.iconSmall/iconMedium/iconLarge` which duplicate `AppDimens.iconSizeSmall/Medium/Large`.
- **Why:** Two sources of truth for the same values with similar names.
- **How:** Keep only `AppLayout.iconTiny` (12), `AppLayout.iconStandard` (20), `AppLayout.iconFeature` (48). For 16/24/32, use `AppDimens.iconSize*`.
- **Output artifact:** Updated Phase 1.7 with 3 tokens instead of 6.
- **Stop condition:** Zero overlapping icon values between AppLayout and AppDimens.

### Fix 5: Define skeleton migration rule explicitly
- **Goal:** Prevent skeleton files from polluting AppLayout with non-semantic tokens.
- **Why:** skeleton_card.dart has values like 34, 17, 90, 120 that are placeholder dimensions.
- **How:** Add rule to Phase 0.1: "Only replace hardcoded values that map to an existing AppLayout semantic token. Skeleton-specific dimensions (placeholder widths, heights, border radii) stay hardcoded. Document exceptions."
- **Output artifact:** Rule documented in plan and session log.
- **Stop condition:** Rule is explicit and accepted.

### Fix 6: Correct all wrong token values
- **Goal:** Fix the 3+ known wrong values before execution begins.
- **Why:** Master Plan was written before Phase 0/1/2 execution. Code has changed.
- **How:** Update Phase 1 sub-steps with corrected values based on actual codebase scan.
- **Output artifact:** Corrected sub-steps in plan.
- **Stop condition:** Every value matches `grep` output from actual files.

### Fix 7: Resolve main_navigation_screen.dart scope
- **Goal:** Decide whether `lib/app/main_navigation_screen.dart` is in scope.
- **Why:** It's in `lib/app/`, not `lib/features/`. It uses 6 hardcoded layout values. The plan creates tokens for 2 of them (fabBottomOffset, fabSize) but doesn't migrate the file.
- **How:** Include the file in Phase 6 as "Migrate Remaining — App Shell", or mark tokens as pre-defined with TODO comments.
- **Output artifact:** Scope decision documented.
- **Stop condition:** Tokens have consumers or documented planned consumers.

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

**See separate file: The corrected plan replaces the original `.TODO/PLAN_LayoutTokens_Phase0.7_2026-04-08.md`.**

Key structural changes to the corrected plan:
1. Phase 0 expanded: add 0.3 Test Assertion Audit, expand 0.2 with Migration Classification
2. Phase 1 restructured: every token sub-step includes "Value Extraction" workflow (read file → extract value → verify → write token)
3. Phase 1.7 (Icon Sizes) reduced from 6 tokens to 3 (remove AppDimens overlaps)
4. Phase 1.4 (Button Heights) corrected: buttonHeight = 54.0 (not 48), add buttonHeightSmall = 48.0, add WCAG touch target separate from visual size
5. Phase 1.9 (Navigation) corrected: bottomNavHeight = 70.0 (not 64)
6. Phases 2-6 each include explicit "read file first, classify values, only replace semantic matches" workflow
7. Phase 5 (Skeleton) scoped down: only replace values matching semantic tokens, document exceptions
8. Phase 6 expanded: include `main_navigation_screen.dart` migration (it's `lib/app/`, not `lib/features/`)
9. Phase 8 QA expanded: add test assertion verification step

---

## I) Change Report (Diff-Style)

### 1. Original Issues Summary
- 7 Critical Gaps found (wrong values, naming collisions, skeleton scope, test regression, orphan tokens, signed_image defaults, wasted no-op migration)
- 2 Gates failed (UI/Integration, Release/QA)
- 2 Blocking Decisions needed (icon naming, skeleton scope)
- At least 3 token values are factually wrong (bottomNavHeight, buttonHeight, circleIconButtonSize)

### 2. Added Steps
- Phase 0.3: Test Assertion Audit (NEW)
- Phase 0.2: Migration Classification table (EXPANDED)
- Phase 1.*: Value Extraction workflow on every token sub-step (EXPANDED)
- Phase 6: `main_navigation_screen.dart` migration (ADDED)
- Phase 8: Test assertion verification (ADDED)

### 3. Removed Steps
- Phase 1.7 sub-steps 1.7.2, 1.7.4, 1.7.5 (overlapping icon sizes) — REMOVED

### 4. Reordered Steps
- None. Phase order is correct.

### 5. Expanded Steps
- Phase 0.2: Discovery Scan → Discovery Scan + Migration Classification
- Phase 1 all sub-steps: "Add token" → "Read source file → Extract actual value → Verify → Add token with source citation"
- Phase 2-6 all sub-steps: "Replace hardcoded values" → "Read file → Classify each value (semantic/non-semantic) → Replace only semantic matches → Document exceptions"
- Phase 5 (Skeleton): "Migrate skeleton files" → "Migrate only semantic values in skeleton files, document non-semantic exceptions"
- Phase 8.4 (Migration Audit): "Verify migration" → "Verify migration + verify test assertions match token values"

### 6. Why
- Token values from the Master Plan are aspirational, not factual. The codebase changed during Phase 0/1/2 execution. The only safe approach is to extract values from the actual code at execution time.
- Skeleton files are heavily hardcoded with placeholder dimensions that have no reusable semantic meaning. Forcing them into AppLayout creates junk tokens.
- Test assertions on pixel values are a hidden regression vector. The plan had no strategy to handle them.
- Icon size overlap between AppLayout and AppDimens is a long-term maintenance hazard.

### 7. Residual Risks
- `signed_image.dart` defaults (100x80) don't map to any token. Executor must decide at migration time.
- `scale_button.dart` has only a 50ms delay constant — may be classified as "no layout migration needed" and skipped entirely.
- `custom_bottom_nav_bar.dart` has 8+ hardcoded values including `fontSize: 9` — some may not map to AppLayout tokens and need classification.
- Future phases (1-16) will need the same "Value Extraction" discipline when migrating feature files.

END.
