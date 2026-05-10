# Plan: Layout Tokens — Design/Theme Separation (Phase 0.7)
# CORRECTED BY @PlanCritic — 2026-04-08
# Critique: .TODO/PLAN_CRITIQUE_2026-04-08_LayoutTokens_Phase0.7.md

## 1) Goal
- **Goal:** Create `lib/core/theme/app_layout.dart` — a centralized layout token file that separates DESIGN (structure, proportions, spacing rhythm) from THEME (colors, fonts, motion), then migrate all 15 `lib/core/widgets/` files + `lib/app/main_navigation_screen.dart` to consume layout tokens instead of hardcoded values.
- **Why:** Layout constants (card padding, avatar sizes, header heights, section spacing, button heights, icon sizes, thumbnail dimensions) are hardcoded inside each widget file. Changing the "design" today requires modifying 134+ files. The theme layer (Layer 1: colors, fonts, motion) is fully centralized after Phase 0, but the layout layer (Layer 2) is scattered everywhere. This phase completes the three-layer architecture: Theme → Layout → Components.
- **Result:** `lib/core/theme/app_layout.dart` with all structural layout tokens. All 15 `lib/core/widgets/` files + `main_navigation_screen.dart` migrated or classified. `AppDimens` retained as the raw spacing/radius primitive layer. `theme_dashboard.dart` updated. Zero visual changes — token values extracted from ACTUAL codebase, not assumed from Master Plan.
- **Architecture:** Master Plan §0.7 "Layout Tokens — Design/Theme Separation" + Master Plan "ARCHITECTURE PRINCIPLE: DESIGN SEPARATED FROM THEME" three-layer model.
- **Session Log:** `docs/LOG/SESSION_PLAN_LayoutTokens_Phase0.7_2026-04-08.md`
- **Critique:** `.TODO/PLAN_CRITIQUE_2026-04-08_LayoutTokens_Phase0.7.md`

## 2) Scope

### In-Scope
- Create `lib/core/theme/app_layout.dart` with layout tokens extracted from ACTUAL codebase values (zero visual change)
- Migrate all 15 `lib/core/widgets/` files — replace SEMANTIC hardcoded layout values with `AppLayout.*` tokens (non-semantic values stay hardcoded)
- Migrate `lib/app/main_navigation_screen.dart` — FAB dimensions and positioning
- Update `lib/core/theme/theme_dashboard.dart` to document the new layout token layer
- Clarify the relationship between `AppDimens` (raw primitives) and `AppLayout` (semantic layout tokens)

### Out-of-Scope
- Migrating `lib/features/*/view/` files to use `AppLayout.*` tokens (Phase 1-16 scope)
- Changing any layout VALUE (all tokens must match current hardcoded values exactly)
- Any Supabase/backend changes
- Adding new dependencies to `pubspec.yaml`
- Changing app behavior, navigation, or business logic
- Redesigning any widget's visual appearance
- Replacing non-semantic hardcoded values (skeleton-specific placeholder dimensions, animation values, one-off alignment constants)

### Migration Rule (CRITICAL — From @PlanCritic)
> **Only replace hardcoded values that map to an existing `AppLayout` semantic token.**
> Skeleton-specific placeholder dimensions (34, 17, 90, 120, etc.), animation values (0.05, 0.7), font sizes inside nav bars (fontSize: 9), and one-off alignment constants (EdgeInsets.only(right: 3)) stay hardcoded.
> Each migrated file must document: (a) values replaced, (b) values intentionally left hardcoded, (c) rationale for each exception.

## 3) Evidence & Findings (From Scan)

### Existing
- **Phase 0 (Design System Foundation) — COMPLETED 2026-04-07:**
  - `app_motion.dart` (117 lines), `app_states.dart` (114 lines), `app_decorations.dart` (113 lines), `app_typography.dart` (143 lines), `app_colors.dart` (440 lines), `app_theme.dart` (305 lines), `theme_dashboard.dart`

- **Phase 1 (Core Widget Redesign) — COMPLETED 2026-04-07:**
  - Glass widgets migrated to solid surfaces per NO GLASS POLICY

- **Phase 2 (App Shell + Auth + Cards) — COMPLETED 2026-04-08:**
  - `flutter test`: 1297 passed, 30 skipped, 1 pre-existing failure

- **`.impeccable.md` (83 lines):** 4px base grid, 24px screen margins, 5 elevation levels, dark default

- **`AppDimens` (54 lines):** 24 spacing (p0-p100), 12 border-radius (r4-r50), 3 icon sizes (iconSizeSmall=16, iconSizeMedium=24, iconSizeLarge=32)

### Missing
- `lib/core/theme/app_layout.dart` — does NOT exist

### Must NOT Duplicate
- `AppLayout` MUST NOT re-declare values that already exist in `AppDimens` with similar names:
  - `AppDimens.iconSizeSmall = 16` exists → NO `AppLayout.iconSmall = 16`
  - `AppDimens.iconSizeMedium = 24` exists → NO `AppLayout.iconMedium = 24`
  - `AppDimens.iconSizeLarge = 32` exists → NO `AppLayout.iconLarge = 32`
  - `AppLayout` adds ONLY sizes `AppDimens` doesn't have: `iconTiny` (12), `iconStandard` (20), `iconFeature` (48)

### Conflicts / Risks
- **Value drift:** Master Plan token values are aspirational. @PlanCritic found 3+ wrong values:
  - Master Plan says `bottomNavHeight = 64` → ACTUAL: `70` (custom_bottom_nav_bar.dart:110)
  - Master Plan says `buttonHeight = 48` → ACTUAL default: `AppDimens.p54 = 54` (app_button.dart:248)
  - Master Plan says `circleIconButtonSize = 48` → ACTUAL: visual size=40 (line 33), touch target=48 (line 69)
- **Skeleton pollution risk:** skeleton_card.dart has 20+ unique hardcoded values. Only semantic ones (padding, border radius) should become tokens.
- **Test assertion regression:** 3 test files assert pixel values (circle_icon_button_test, sliver_tab_bar_delegate_test, scale_button_test).

### Widget Hardcoded Value Inventory (From @PlanCritic Scan)
| File | Lines | Hardcoded Count | Key Values | Has AppDimens | Classification |
|------|-------|----------------|-----------|---------------|---------------|
| app_card.dart | 75 | 0 | (uses AppDimens tokens) | YES | CLEAN — skip |
| app_card_container.dart | 68 | 1 | border width: 1 | YES | LIGHT — 1 semantic value |
| app_button.dart | 285 | 3 | spacing: 8, icon: 20, 24 | YES | MEDIUM |
| app_styled_button.dart | 126 | 3 | height: 48, icon: 18, border: 1 | YES | MEDIUM |
| circle_icon_button.dart | 80 | 3 | size: 40, icon: 20, touch: 48 | NO | MEDIUM — test assertions exist |
| scale_button.dart | 129 | 1 | delay: 50ms (not layout) | NO | SKIP — no layout values |
| signed_avatar.dart | 346 | 6 | radius: 20, border: 2, spinner: 12 | NO | MEDIUM |
| signed_image.dart | 255 | 6 | width: 100, height: 80, radius: 12, icon: 22, spacing: 4, fontSize: 10 | NO | COMPLEX — defaults are caller-overridden |
| skeleton_card.dart | 515 | 20+ | 20, 4, 12, 16, 24, 90, 56, 34, 17... | YES | HEAVY — semantic only |
| skeleton_card_extended.dart | 351 | 15+ | 60, 80, 6, 70, 32, 16, 120, 10... | YES | HEAVY — semantic only |
| skeleton_loader.dart | 158 | 2 | anim: -2/2, avatar: 48 | YES | LIGHT |
| app_text_field.dart | 218 | 4 | icon: 20, spacing: 12, 4, 8 | NO | MEDIUM |
| custom_bottom_nav_bar.dart | 345 | 8+ | height: 70, width: 56, padding: 8, 4, fontSize: 9 | YES | HEAVY |
| status_badge.dart | 234 | 6+ | padding: 6/10/2/4, icon: 10/14, spacing: 4 | NO | MEDIUM |
| sliver_tab_bar_delegate.dart | 51 | 1 | border: 1 | NO | LIGHT — test assertions exist |
| main_navigation_screen.dart | 325 | 6 | bottom: 100, FAB: 56x56, blur: 20, icon: 30 | YES | MEDIUM |

## 4) System Impact Map
- **UI:** Zero visual changes. All tokens match current hardcoded values exactly.
- **MVVM / App Logic:** None. Layout tokens are compile-time constants.
- **Database:** None.
- **RLS / Security:** None.
- **RPC / Edge Functions:** None.
- **Storage:** None.
- **Realtime / Notifications:** None.
- **Observability:** None.
- **Compatibility & Migration:** Additive-only. New file + updated imports.
- **Contracts:** None.

## 5) Agent Map
- **Phase 0 (Preconditions + Audits):** `@Planner`, `@Sentinel`, `@Architect`
- **Phase 1 (Create app_layout.dart):** `@Pixel` (primary), `@Architect` (review), `@Sentinel` (gate)
- **Phase 2 (Migrate Card/Container group):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 3 (Migrate Button group):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 4 (Migrate Avatar/Image group):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 5 (Migrate Skeleton/Loader group):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 6 (Migrate Remaining + App Shell):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 7 (Documentation):** `@DocsKeeper` (primary), `@Sentinel` (gate)
- **Phase 8 (QA + Verification):** `@Sentinel` (primary), `@CodeGuard` (review)

---

## Phase 0: Preconditions, Discovery & Audits

**Primary Agent(s):** `@Planner`, `@Sentinel`, `@Architect`
**Goal:** Verify all preconditions, classify every widget, audit test assertions, and lock scope before any code changes.
**Why:** @PlanCritic found 3+ wrong token values, 1 already-clean widget, and 3 test files with pixel assertions. Without this phase, execution will produce wrong values and regressions.
**How:** Systematic scans, classification, and value verification.
**Result:** Widget Classification Table, Test Assertion Inventory, and confirmed scope — all documented in session log before Phase 1 begins.

### 0.1 Spec Lock
- [ ] (`@Sentinel`) Acceptance criteria defined (see Section 7 below).
- [ ] (`@Architect`) Confirm `app_layout.dart` does NOT already exist.
- [ ] (`@Architect`) Confirm Phase 0/1/2 are fully complete — verify test baseline (1297 passed, 30 skipped, 1 pre-existing).
- [ ] (`@Architect`) Confirm Migration Rule is understood: "Only replace SEMANTIC values. Non-semantic values stay hardcoded. Document exceptions."
- [ ] (`@Architect`) Confirm AppDimens/AppLayout overlap rule: "No overlapping icon sizes. AppLayout adds only iconTiny (12), iconStandard (20), iconFeature (48)."
- **GATE CHECK:** Scope, rules, and preconditions are explicit and locked.

### 0.2 Codebase Discovery Scan + Migration Classification
- [ ] (`@Sentinel`) List every file in `lib/core/widgets/` with line count. Confirm exact count (expected: 15).
- [ ] (`@Sentinel`) For each core widget file, read the file and classify:
  - **CLEAN** — already uses tokens, no hardcoded layout values → skip migration
  - **LIGHT** — 1-2 semantic hardcoded values → quick migration
  - **MEDIUM** — 3-6 semantic hardcoded values → standard migration
  - **HEAVY** — 7+ hardcoded values, mix of semantic and non-semantic → selective migration
  - **SKIP** — no layout values (animation-only, delegate-only) → document and skip
- [ ] (`@Sentinel`) Read `lib/app/main_navigation_screen.dart` and classify.
- [ ] (`@Sentinel`) Record the Migration Classification Table in the session log:
  ```
  | File | Classification | Semantic Values to Replace | Values to Keep Hardcoded | Rationale |
  ```
- [ ] (`@Sentinel`) Report to user: "Discovery scan complete. X files need migration, Y are clean/skip. Classification table attached."
- **GATE CHECK:** Every file classified. User has approved scope before code changes begin.

### 0.3 Test Assertion Audit
- [ ] (`@Sentinel`) Read `test/core/widgets/circle_icon_button_test.dart`. Document every assertion that checks a specific numeric value (size, width, height, constraints).
  - Known: asserts `maxWidth == 40`, `maxHeight == 40`, `icon.size == 30`
- [ ] (`@Sentinel`) Read `test/core/widgets/sliver_tab_bar_delegate_test.dart`. Document every assertion that checks a specific numeric value.
  - Known: asserts `maxExtent == preferredSize.height`, `minExtent == preferredSize.height`
- [ ] (`@Sentinel`) Read `test/core/widgets/scale_button_test.dart`. Document every assertion that checks opacity or scale values.
  - Known: asserts `opacity == 0.38`
- [ ] (`@Sentinel`) Grep all test files in `test/core/widgets/` for `expect(.*size`, `expect(.*width`, `expect(.*height`, `expect(.*opacity`, `constraints` to catch any assertions the scan may have missed.
- [ ] (`@Sentinel`) Record the Test Assertion Inventory in the session log:
  ```
  | Test File | Asserted Value | Source Widget Constant | Matching AppLayout Token | Risk |
  ```
- [ ] (`@Sentinel`) For each asserted value, verify the planned token value matches. If mismatch → flag as MUST-FIX before migration.
- **GATE CHECK:** All pixel-value test assertions documented. No known mismatches between planned tokens and tested values.

---

## Phase 1: Create app_layout.dart

**Primary Agent(s):** `@Pixel`, `@Architect`
**Goal:** Create `lib/core/theme/app_layout.dart` with all structural layout tokens, values extracted from ACTUAL codebase.
**Why:** Layer 2b of the three-layer architecture. Centralizes all layout decisions.
**How:** For EVERY token: read the source widget file → extract the actual value → verify → write the token with source citation in the doc comment.
**Result:** `lib/core/theme/app_layout.dart` exists with verified, accurate token values.

### 1.1 Create file with header documentation
- [ ] (`@Pixel` | Skill: `normalize`) Create `lib/core/theme/app_layout.dart`:
  - Sub-step 1.1.1: Add file-level `///` doc comment explaining:
    - WHAT: Every structural measurement in the app
    - WHY: Separates DESIGN from THEME
    - RELATIONSHIP TO AppDimens: `AppDimens` = raw spacing/radius primitives, `AppLayout` = semantic structural tokens, both are Layer 2, no overlapping values
  - Sub-step 1.1.2: Add `class AppLayout` with `AppLayout._();`
  - Sub-step 1.1.3: Import `package:flutter/material.dart` only.
- [ ] (`@Architect`) Review: private constructor, no mutable state, `static const` only.
- [ ] (`@Sentinel`) Verify: `flutter analyze` clean.

### 1.2 Add Card Dimension tokens (Value Extraction: app_card.dart, app_card_container.dart)
- [ ] (`@Pixel`) Read `lib/core/widgets/app_card.dart` — extract actual padding value (expected: `AppDimens.p16` = 16.0).
- [ ] (`@Pixel`) Read `lib/core/widgets/app_card_container.dart` — extract actual border width (expected: 1.0 from line 59).
- [ ] (`@Pixel` | Skill: `normalize`) Add Card Dimensions section with VERIFIED values:
  - `static const double cardPadding = 16.0;` — `/// Standard card content padding. Source: app_card.dart (AppDimens.p16).`
  - `static const double cardPaddingCompact = 12.0;` — `/// Compact card padding (dense lists). Source: app_card_container.dart pattern.`
  - `static const double cardSectionSpacing = 8.0;` — `/// Card inner section spacing.`
  - `static const double cardHeaderHeight = 60.0;` — `/// Card gradient/image header height.`
  - `static const double cardBorderWidth = 1.0;` — `/// Standard card border width. Source: app_card_container.dart:59.`
- [ ] (`@Sentinel`) Verify: grep `EdgeInsets.all(16)` and `width: 1` in card widgets to confirm values.

### 1.3 Add Avatar Size tokens (Value Extraction: signed_avatar.dart)
- [ ] (`@Pixel`) Read `lib/core/widgets/signed_avatar.dart` — extract actual default radius (expected: 20 from line 73, meaning diameter = 40).
- [ ] (`@Pixel` | Skill: `normalize`) Add Avatar Sizes section with VERIFIED values:
  - `static const double avatarTiny = 24.0;` — `/// Tiny avatar for inline mentions (24px diameter, radius 12).`
  - `static const double avatarSmall = 36.0;` — `/// Small avatar for list tiles (36px diameter, radius 18).`
  - `static const double avatarDefault = 40.0;` — `/// Default avatar (40px diameter, radius 20). Source: signed_avatar.dart:73 default radius=20.`
  - `static const double avatarMedium = 44.0;` — `/// Medium avatar for conversation tiles (44px diameter, radius 22).`
  - `static const double avatarLarge = 64.0;` — `/// Large avatar for detail screens (64px diameter, radius 32).`
  - `static const double avatarHero = 80.0;` — `/// Hero avatar for profile top section (80px diameter, radius 40).`
- [ ] (`@Sentinel`) Verify: grep for `radius:` values in `signed_avatar.dart` and consuming feature files.

### 1.4 Add Button Height tokens (Value Extraction: app_button.dart, app_styled_button.dart, circle_icon_button.dart)
- [ ] (`@Pixel`) Read `lib/core/widgets/app_button.dart` — extract actual default height (expected: `AppDimens.p54` = 54.0 from line 248).
- [ ] (`@Pixel`) Read `lib/core/widgets/app_styled_button.dart` — extract actual default height (expected: 48 from line 46).
- [ ] (`@Pixel`) Read `lib/core/widgets/circle_icon_button.dart` — extract actual visual size (expected: 40 from line 33) and touch target (expected: 48 from line 69).
- [ ] (`@Pixel` | Skill: `normalize`) Add Button Heights section with VERIFIED values:
  - `static const double buttonHeight = 54.0;` — `/// Standard button height (primary actions). Source: app_button.dart:248 (AppDimens.p54).`
  - `static const double buttonHeightCompact = 48.0;` — `/// Compact button height (styled/secondary). Source: app_styled_button.dart:46.`
  - `static const double buttonHeightSmall = 36.0;` — `/// Small button height (inline actions).`
  - `static const double circleButtonVisualSize = 40.0;` — `/// Circle icon button visual diameter. Source: circle_icon_button.dart:33.`
  - `static const double minTouchTarget = 48.0;` — `/// WCAG minimum touch target (48x48dp). Source: circle_icon_button.dart:69.`
  - `static const double fabSize = 56.0;` — `/// Floating action button size. Source: main_navigation_screen.dart:284-285.`
- [ ] (`@Sentinel`) Verify: cross-reference each value with the source file and line.
- [ ] (`@Sentinel`) Verify: `circle_icon_button_test.dart` asserts `maxWidth == 40` — this must NOT conflict with any token change.

### 1.5 Add Spacing Rhythm tokens
- [ ] (`@Pixel` | Skill: `normalize`) Add Spacing Rhythm section. Doc comment: "Semantic spacing rhythm. For raw primitives, see `AppDimens`."
  - `static const double spacingTight = 4.0;` — tight spacing within components.
  - `static const double spacingStandard = 8.0;` — standard spacing between related elements.
  - `static const double spacingSection = 16.0;` — section spacing between groups.
  - `static const double spacingScreen = 24.0;` — screen-level vertical spacing.
  - `static const double spacingLarge = 32.0;` — large gap for breathing room.
  - `static const double screenHorizontalMargin = 24.0;` — `/// Source: .impeccable.md screen margins.`
- [ ] (`@Sentinel`) Verify `screenHorizontalMargin` = 24 matches `.impeccable.md`.

### 1.6 Add Content Width tokens
- [ ] (`@Pixel` | Skill: `normalize`) Add Content Widths section:
  - `static const double formMaxWidth = 400.0;`
  - `static const double cardMaxWidth = 600.0;`
- [ ] (`@Sentinel`) Verify values are reasonable for mobile-first layout.

### 1.7 Add Icon Size tokens (NO OVERLAP with AppDimens)
- [ ] (`@Pixel` | Skill: `normalize`) Add Icon Sizes section. Doc comment: "Semantic icon sizes NOT covered by `AppDimens.iconSize*`. For 16/24/32, use `AppDimens.iconSizeSmall/Medium/Large`."
  - `static const double iconTiny = 12.0;` — `/// Status/inline icon (badges, chips). NOT in AppDimens.`
  - `static const double iconStandard = 20.0;` — `/// Standard icon (buttons, list tiles). NOT in AppDimens.`
  - `static const double iconFeature = 48.0;` — `/// Feature icon (empty states, auth screens). NOT in AppDimens.`
- [ ] (`@Sentinel`) Verify: NO `AppLayout` icon token has the same value as an `AppDimens.iconSize*` token (16, 24, 32 must NOT appear).

### 1.8 Add Thumbnail Size tokens
- [ ] (`@Pixel` | Skill: `normalize`) Add Thumbnail Sizes section:
  - `static const double thumbnailSmall = 60.0;` — task card thumbnail.
  - `static const double thumbnailMedium = 80.0;` — booking card thumbnail.
- [ ] (`@Sentinel`) Verify values match current codebase.

### 1.9 Add Navigation tokens (Value Extraction: custom_bottom_nav_bar.dart, main_navigation_screen.dart)
- [ ] (`@Pixel`) Read `lib/core/widgets/custom_bottom_nav_bar.dart` — extract actual height (expected: 70 from line 110).
- [ ] (`@Pixel`) Read `lib/app/main_navigation_screen.dart` — extract actual FAB bottom offset (expected: 100 from line 265).
- [ ] (`@Pixel` | Skill: `normalize`) Add Navigation section with VERIFIED values:
  - `static const double bottomNavHeight = 70.0;` — `/// Bottom navigation bar height. Source: custom_bottom_nav_bar.dart:110. NOT 64 (Master Plan was wrong).`
  - `static const double fabBottomOffset = 100.0;` — `/// FAB bottom offset above nav bar. Source: main_navigation_screen.dart:265.`
  - `static const double statusIndicatorHeight = 40.0;` — status bar/indicator height.
- [ ] (`@Sentinel`) Verify: `bottomNavHeight` = 70 matches ACTUAL code, not Master Plan's 64.

### 1.10 Add Stagger Count tokens
- [ ] (`@Pixel` | Skill: `normalize`) Add Stagger section:
  - `static const int authStaggerCount = 5;`
  - `static const int signupStaggerCount = 6;`
- [ ] (`@Sentinel`) Verify values match auth/signup implementations.

### 1.11 Add List/Tile tokens
- [ ] (`@Pixel` | Skill: `normalize`) Add List/Tile section:
  - `static const double listItemMinHeight = 56.0;`
  - `static const double listItemPadding = 16.0;`
  - `static const double dividerIndent = 16.0;`
- [ ] (`@Sentinel`) Verify values match current list implementations.

### 1.12 Add Border Width tokens
- [ ] (`@Pixel` | Skill: `normalize`) Add Border Widths section:
  - `static const double borderStandard = 1.0;` — `/// Standard border width for cards and containers.`
  - `static const double borderThick = 1.5;` — `/// Thick border for emphasis. Source: custom_bottom_nav_bar.dart:282.`
  - `static const double borderAvatar = 2.0;` — `/// Avatar border width. Source: signed_avatar.dart:77.`
- [ ] (`@Sentinel`) Verify values match codebase.

### 1.13 Final file review
- [ ] (`@Architect`) Review complete `app_layout.dart`:
  - Private constructor, `static const` only, no mutable state.
  - Doc comments on every section and every token.
  - Source citations in doc comments for extracted values.
  - No overlapping icon values with `AppDimens`.
  - Relationship to `AppDimens` documented in file-level comment.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- [ ] (`@Sentinel`) Run `dart format lib/core/theme/app_layout.dart` — no changes.
- [ ] (`@Sentinel`) Record Value Extraction Table in session log:
  ```
  | Token | Value | Source File:Line | Matches Master Plan? |
  ```
- **GATE CHECK:** `app_layout.dart` exists with all token categories, verified values, source citations. `flutter analyze` clean.

---

## Phase 2: Migrate Core Widgets — Card/Container Group

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Wire card and container widgets to `AppLayout.*` tokens.
**Why:** Card widgets are most-used structural components.
**How:** Read file → identify semantic values → replace with matching tokens → document exceptions.
**Result:** Card/container widgets use tokens. Zero visual change.

### 2.1 Migrate `app_card.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/app_card.dart`.
- [ ] (`@Pixel`) Classification from Phase 0.2: **CLEAN** — already uses `AppDimens.p16` and `AppDimens.r20`. No hardcoded layout values.
- [ ] (`@Pixel`) Decision: NO CHANGES NEEDED. Document as "already tokenized via AppDimens" in session log.
- [ ] (`@Sentinel`) Confirm: git diff shows zero changes to this file.

### 2.2 Migrate `app_card_container.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/app_card_container.dart`. Classification: **LIGHT** — 1 hardcoded value.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `width: 1` (line 59) with `AppLayout.borderStandard`.
- [ ] (`@Pixel`) Add `import 'package:sline_app/core/theme/app_layout.dart';`
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 2.3 Migrate `status_badge.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/status_badge.dart`. Classification: **MEDIUM** — 6+ hardcoded values.
- [ ] (`@Pixel` | Skill: `normalize`) Identify which values are semantic (padding, icon size, spacing) and which are component-specific (badge-specific small/large variants).
- [ ] (`@Pixel` | Skill: `normalize`) Replace semantic spacing (e.g., `SizedBox(width: 4)` → `AppLayout.spacingTight`).
- [ ] (`@Pixel`) Replace icon sizes: `10.0` → `AppLayout.iconTiny` if close, or leave as badge-specific. `14.0` → leave as badge-specific (no matching token).
- [ ] (`@Pixel`) Document exceptions: badge-specific padding (6/10/2/4 variants for isSmall toggle) are NOT semantic layout tokens — leave hardcoded.
- [ ] (`@Pixel`) Add `import 'package:sline_app/core/theme/app_layout.dart';`
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 2.4 Gate check
- [ ] (`@Sentinel`) Run `flutter test` — zero new failures.
- [ ] (`@Sentinel`) Record in session log: which values were replaced, which were kept, rationale.
- **GATE CHECK:** Card/container group processed. Zero visual changes. Tests pass.

---

## Phase 3: Migrate Core Widgets — Button Group

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Wire button widgets to `AppLayout.*` tokens.
**Why:** Buttons define interactive element sizes — must be consistent.
**How:** Read → classify values → replace semantic matches → document exceptions.
**Result:** Button widgets use tokens. Zero visual change.

### 3.1 Migrate `app_button.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/app_button.dart`. Classification: **MEDIUM** — 3 hardcoded values.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `SizedBox(width: 8)` (line 215) → `AppLayout.spacingStandard`.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `Icon(..., size: 20)` (line 216) → `AppLayout.iconStandard`.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `Icon(..., size: 24)` (line 198) → `AppDimens.iconSizeMedium` (24 is in AppDimens, NOT AppLayout).
- [ ] (`@Pixel`) Note: default height is already `AppDimens.p54` — no change needed. `buttonHeight = 54` token exists for future consumers.
- [ ] (`@Pixel`) Add `import 'package:sline_app/core/theme/app_layout.dart';`
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 3.2 Migrate `app_styled_button.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/app_styled_button.dart`. Classification: **MEDIUM** — 3 hardcoded values.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `height = 48` (line 46) default → `AppLayout.buttonHeightCompact`.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `Icon(icon, size: 18)` (line 80) → leave as component-specific (no 18px token). Document exception.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `Border.all(..., width: 1)` (line 103) → `AppLayout.borderStandard`.
- [ ] (`@Pixel`) Add `import 'package:sline_app/core/theme/app_layout.dart';`
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 3.3 Migrate `circle_icon_button.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/circle_icon_button.dart`. Classification: **MEDIUM** — 3 hardcoded values, TEST ASSERTIONS EXIST.
- [ ] (`@Pixel`) CRITICAL: Confirm from Phase 0.3 Test Assertion Audit that:
  - Test asserts `maxWidth == 40` → token `circleButtonVisualSize = 40.0` → MATCH ✅
  - Test asserts `icon.size == 30` → this is a test with custom size, not default → SAFE ✅
- [ ] (`@Pixel` | Skill: `normalize`) Replace `size = 40` default (line 33) → `AppLayout.circleButtonVisualSize`.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `iconSize = 20` default (line 34) → `AppLayout.iconStandard`.
- [ ] (`@Pixel` | Skill: `normalize`) SizedBox(width: 48, height: 48) touch target (line 69) → `AppLayout.minTouchTarget`.
- [ ] (`@Pixel`) Add `import 'package:sline_app/core/theme/app_layout.dart';`
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- [ ] (`@Sentinel`) Run `flutter test test/core/widgets/circle_icon_button_test.dart` — must pass.

### 3.4 Assess `scale_button.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/scale_button.dart`. Classification: **SKIP** — only hardcoded value is `50ms` delay (not layout, it's animation timing).
- [ ] (`@Pixel`) Decision: NO LAYOUT MIGRATION NEEDED. Document as "animation-only, no layout values" in session log.
- [ ] (`@Sentinel`) Confirm: git diff shows zero changes to this file (or animation-only if delay is changed to AppMotion token — executor decides).

### 3.5 Gate check
- [ ] (`@Sentinel`) Run `flutter test` — zero new failures.
- [ ] (`@Sentinel`) Verify `circle_icon_button_test.dart` specifically passes (highest regression risk in this phase).
- **GATE CHECK:** Button group processed. Zero visual changes. Tests pass.

---

## Phase 4: Migrate Core Widgets — Avatar/Image Group

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Wire avatar and image widgets to `AppLayout.*` tokens.
**Why:** Avatar sizes are hardcoded across 10+ feature files — establishing the pattern here.
**How:** Read → classify → replace semantic → document exceptions.
**Result:** Avatar/image widgets use tokens. Zero visual change.

### 4.1 Migrate `signed_avatar.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/signed_avatar.dart`. Classification: **MEDIUM** — 6 hardcoded values.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `radius = 20` default (line 73) → `AppLayout.avatarDefault / 2` (= 20.0). Doc comment: "Default avatar radius, half of avatarDefault."
- [ ] (`@Pixel` | Skill: `normalize`) Replace `borderWidth = 2` default (line 77) → `AppLayout.borderAvatar`.
- [ ] (`@Pixel` | Skill: `normalize`) Assess spinner dimensions (`width: 12, height: 12, strokeWidth: 2`): these are loading indicator sizes, NOT avatar layout. Leave hardcoded. Document exception: "Loading spinner dimensions are indicator-specific, not layout tokens."
- [ ] (`@Pixel` | Skill: `normalize`) Assess online indicator (`width: 12, height: 12, border: 2`): also indicator-specific. Leave hardcoded with same rationale.
- [ ] (`@Pixel`) Add `import 'package:sline_app/core/theme/app_layout.dart';`
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 4.2 Migrate `signed_image.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/signed_image.dart`. Classification: **COMPLEX** — defaults (width=100, height=80) are caller-overridden parameters.
- [ ] (`@Pixel` | Skill: `normalize`) Assess defaults: `width = 100, height = 80, borderRadius = 12`. These are widget parameter defaults, not layout constants. Callers override them per context. The widget itself doesn't have one "correct" size.
- [ ] (`@Pixel`) Decision: Leave parameter defaults as-is (they're fallbacks). Add `import 'package:sline_app/core/theme/app_layout.dart';` only if there are OTHER values to replace.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `Icon(..., size: 22)` → leave as component-specific (22 is between iconStandard=20 and iconMedium=24, no exact match).
- [ ] (`@Pixel` | Skill: `normalize`) Replace `SizedBox(height: 4)` → `AppLayout.spacingTight`.
- [ ] (`@Pixel`) Document exception: "Parameter defaults (100, 80, 12) are caller-overridden. Callers should use AppLayout tokens when constructing the widget."
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 4.3 Gate check
- [ ] (`@Sentinel`) Run `flutter test` — zero new failures.
- **GATE CHECK:** Avatar/image group processed. Zero visual changes. Tests pass.

---

## Phase 5: Migrate Core Widgets — Skeleton/Loader Group (SELECTIVE)

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Replace ONLY SEMANTIC hardcoded values in skeleton/loader widgets. Non-semantic placeholder dimensions stay hardcoded.
**Why:** Skeleton widgets have 20+ unique values (34, 17, 90, 120) that are placeholder dimensions — not reusable layout tokens.
**How:** Read → classify each value as semantic or placeholder → replace only semantic → document ALL exceptions.
**Result:** Skeleton widgets use tokens where meaningful. Placeholder dimensions documented as intentional exceptions.

### 5.1 Migrate `skeleton_card.dart` (SELECTIVE)
- [ ] (`@Pixel`) Read `lib/core/widgets/skeleton_card.dart` (515 lines). Classification: **HEAVY** — 20+ hardcoded values.
- [ ] (`@Pixel` | Skill: `normalize`) Classify each hardcoded value:
  - **SEMANTIC (replace):** padding values matching cardPadding (16), spacingStandard (8), border radius matching AppDimens (20, 24)
  - **NON-SEMANTIC (keep):** skeleton-specific dimensions (34, 17, 90, 56 for placeholder blocks, accent bar width: 4, blur: 12)
- [ ] (`@Pixel` | Skill: `normalize`) Replace ONLY semantic values with `AppLayout.*` or `AppDimens.*` tokens.
- [ ] (`@Pixel`) Add `import 'package:sline_app/core/theme/app_layout.dart';` if any replacements were made.
- [ ] (`@Pixel`) Document all kept values with inline comments: `// Skeleton placeholder dimension — not a layout token`
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 5.2 Migrate `skeleton_card_extended.dart` (SELECTIVE)
- [ ] (`@Pixel`) Read `lib/core/widgets/skeleton_card_extended.dart` (351 lines). Classification: **HEAVY** — 15+ hardcoded values.
- [ ] (`@Pixel` | Skill: `normalize`) Same classification approach as 5.1: semantic (replace) vs placeholder (keep).
- [ ] (`@Pixel` | Skill: `normalize`) Replace ONLY semantic values.
- [ ] (`@Pixel`) Document all kept values.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 5.3 Migrate `skeleton_loader.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/skeleton_loader.dart` (158 lines). Classification: **LIGHT**.
- [ ] (`@Pixel` | Skill: `normalize`) Assess: animation range (-2, 2) is NOT layout. Default avatar size 48 → `AppLayout.minTouchTarget` or `AppLayout.buttonHeightCompact` depending on context.
- [ ] (`@Pixel` | Skill: `normalize`) Replace applicable semantic values only.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 5.4 Gate check
- [ ] (`@Sentinel`) Run `flutter test` — zero new failures.
- [ ] (`@Sentinel`) Record in session log: "Skeleton migration — X values replaced (semantic), Y values kept (placeholder). Full classification attached."
- **GATE CHECK:** Skeleton group selectively migrated. Exceptions documented. Tests pass.

---

## Phase 6: Migrate Core Widgets — Remaining + App Shell

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Migrate remaining core widgets and the main navigation screen.
**Why:** Complete the core widget migration.
**How:** Read → classify → replace semantic → document exceptions.
**Result:** All core widgets and app shell processed.

### 6.1 Migrate `app_text_field.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/app_text_field.dart` (218 lines). Classification: **MEDIUM** — 4 hardcoded values.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `Icon(..., size: 20)` → `AppLayout.iconStandard`.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `EdgeInsets.only(right: 12)` → `AppDimens.p12` (raw spacing, not semantic layout).
- [ ] (`@Pixel` | Skill: `normalize`) Replace `SizedBox(width: 4)` → `AppLayout.spacingTight`.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `EdgeInsets.only(right: 8)` → `AppDimens.p8` (raw spacing).
- [ ] (`@Pixel`) Add appropriate imports.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 6.2 Migrate `custom_bottom_nav_bar.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/custom_bottom_nav_bar.dart` (345 lines). Classification: **HEAVY** — 8+ hardcoded values.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `height: 70` (line 110) → `AppLayout.bottomNavHeight`.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `width: 56` (line 225) → `AppLayout.fabSize`.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `padding: EdgeInsets.all(8)` → `EdgeInsets.all(AppLayout.spacingStandard)`.
- [ ] (`@Pixel` | Skill: `normalize`) Classify remaining values:
  - `padding: 4, 1` → `AppLayout.spacingTight` or component-specific (1px is visual tweak, keep hardcoded)
  - `minWidth: 16` → `AppDimens.iconSizeSmall` or badge-specific
  - `borderRadius: 8` → `AppDimens.r8`
  - `border width: 1.5` → `AppLayout.borderThick`
  - `fontSize: 9` → component-specific nav label size, NOT a layout token. Keep hardcoded.
- [ ] (`@Pixel`) Add `import 'package:sline_app/core/theme/app_layout.dart';`
- [ ] (`@Pixel`) Document exceptions: `fontSize: 9` (nav label), `vertical: 1` (visual tweak).
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 6.3 Migrate `sliver_tab_bar_delegate.dart`
- [ ] (`@Pixel`) Read `lib/core/widgets/sliver_tab_bar_delegate.dart` (51 lines). Classification: **LIGHT** — 1 hardcoded value, TEST ASSERTIONS EXIST.
- [ ] (`@Pixel`) CRITICAL: Confirm Phase 0.3 test assertion: `preferredSize.height` assertion is dynamic (depends on TabBar), not a fixed pixel value → SAFE.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `BorderSide(..., width: 1)` → `AppLayout.borderStandard`.
- [ ] (`@Pixel`) Add `import 'package:sline_app/core/theme/app_layout.dart';`
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- [ ] (`@Sentinel`) Run `flutter test test/core/widgets/sliver_tab_bar_delegate_test.dart` — must pass.

### 6.4 Migrate `main_navigation_screen.dart` (App Shell)
- [ ] (`@Pixel`) Read `lib/app/main_navigation_screen.dart` (325 lines). Classification: **MEDIUM** — 6 hardcoded layout values.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `bottom: 100` (line 265) → `AppLayout.fabBottomOffset`.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `width: 56, height: 56` (lines 284-285) → `AppLayout.fabSize`.
- [ ] (`@Pixel` | Skill: `normalize`) Classify remaining:
  - `blurRadius: 20, offset: Offset(0, 10)` → elevation/shadow values, use `AppDecorations.elevation()` or leave as FAB-specific shadow.
  - `size: 30` → FAB icon size, keep as component-specific (30 is between iconMedium=24 and iconLarge=32).
  - `Offset(0.05, 0)` → animation value, not layout. Keep hardcoded.
- [ ] (`@Pixel`) Add `import 'package:sline_app/core/theme/app_layout.dart';`
- [ ] (`@Pixel`) Document exceptions in session log.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 6.5 Final widget audit
- [ ] (`@Sentinel`) Verify ALL 15 core widget files + `main_navigation_screen.dart` have been reviewed.
- [ ] (`@Sentinel`) List files skipped and WHY:
  - `app_card.dart` — CLEAN (already tokenized)
  - `scale_button.dart` — SKIP (animation only, no layout)
- [ ] (`@Sentinel`) Run `flutter test` — zero new failures.
- **GATE CHECK:** All widgets processed or documented. Tests pass.

---

## Phase 7: Documentation Sync (MANDATORY)

**Primary Agent(s):** `@DocsKeeper`, `@Sentinel`
**Goal:** Update documentation to reflect the new Layout token layer.
**Why:** `theme_dashboard.dart` must document the three-layer architecture.
**How:** Update docs, finalize session log.
**Result:** Documentation current and comprehensive.

### 7.1 Update theme_dashboard.dart
- [ ] (`@DocsKeeper`) Update `lib/core/theme/theme_dashboard.dart`:
  - Sub-step 7.1.1: Add "Layout Tokens (AppLayout)" section documenting ALL token categories with values.
  - Sub-step 7.1.2: Add "Three-Layer Architecture" diagram:
    ```
    Layer 1 — THEME: AppColors, AppTypography, AppMotion, AppDecorations, AppStates
    Layer 2 — LAYOUT: AppLayout (semantic structure) + AppDimens (raw primitives)
    Layer 3 — COMPONENTS: Widgets consume Layer 1 + Layer 2, own neither
    ```
  - Sub-step 7.1.3: Add "AppDimens vs AppLayout" explanation with examples.
  - Sub-step 7.1.4: Update "Last Updated" timestamp to 2026-04-08.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 7.2 Session log finalization
- [ ] (`@DocsKeeper`) Ensure session log contains:
  - Migration Classification Table (from Phase 0.2)
  - Test Assertion Inventory (from Phase 0.3)
  - Value Extraction Table (from Phase 1)
  - Per-phase migration notes (values replaced, values kept, rationale)
- **GATE CHECK:** Documentation current. Session log complete.

---

## Phase 8: QA + Verification (MANDATORY)

**Primary Agent(s):** `@Sentinel`, `@CodeGuard`
**Goal:** Verify everything is correct, nothing broke, and zero visual changes occurred.
**Why:** Token values extracted from code should produce zero diff — but must verify.
**How:** Static analysis, tests, token audit, migration audit, visual check.
**Result:** All gates pass. Plan is complete.

### 8.1 Static Analysis
- [ ] (`@Sentinel`) Run `flutter analyze` — zero errors, zero warnings.
- [ ] (`@Sentinel`) Run `dart format .` — no changes in modified files.

### 8.2 Test Suite
- [ ] (`@Sentinel`) Run `flutter test` — zero new failures vs baseline (1297 passed, 30 skipped, 1 pre-existing).
- [ ] (`@Sentinel`) Specifically verify HIGH-RISK tests:
  - `test/core/widgets/circle_icon_button_test.dart` — passes
  - `test/core/widgets/sliver_tab_bar_delegate_test.dart` — passes
  - `test/core/widgets/scale_button_test.dart` — passes
- [ ] (`@Sentinel`) If ANY test failure: document file, test name, root cause. Fix before closing Phase 0.7.

### 8.3 Token Completeness Audit
- [ ] (`@Sentinel`) Confirm `app_layout.dart` exists with:
  - >= 5 card dimension tokens (cardPadding, cardPaddingCompact, cardSectionSpacing, cardHeaderHeight, cardBorderWidth)
  - >= 6 avatar size tokens (avatarTiny, avatarSmall, avatarDefault, avatarMedium, avatarLarge, avatarHero)
  - >= 6 button/touch tokens (buttonHeight, buttonHeightCompact, buttonHeightSmall, circleButtonVisualSize, minTouchTarget, fabSize)
  - >= 6 spacing tokens (spacingTight, spacingStandard, spacingSection, spacingScreen, spacingLarge, screenHorizontalMargin)
  - >= 2 content width tokens
  - >= 3 icon size tokens (iconTiny, iconStandard, iconFeature — NO overlap with AppDimens)
  - >= 2 thumbnail tokens
  - >= 3 navigation tokens (bottomNavHeight, fabBottomOffset, statusIndicatorHeight)
  - >= 2 stagger tokens
  - >= 3 list/tile tokens
  - >= 3 border width tokens (borderStandard, borderThick, borderAvatar)
- [ ] (`@Sentinel`) Confirm ALL tokens have `///` doc comments with source citations.
- [ ] (`@Sentinel`) Confirm `AppLayout` class has private constructor and only `static const` members.

### 8.4 Migration Audit
- [ ] (`@Sentinel`) For each core widget file, verify:
  - Migrated (imports `app_layout.dart` and uses tokens) OR
  - Clean (already tokenized, documented as skip) OR
  - Skipped (no layout values, documented with rationale)
- [ ] (`@Sentinel`) Verify exception documentation: each file with kept hardcoded values has inline comments or session log entry explaining why.
- [ ] (`@Sentinel`) Confirm zero `AppLayout` imports in `lib/features/` (out of scope).

### 8.5 Test Assertion Verification
- [ ] (`@Sentinel`) Cross-reference Phase 0.3 Test Assertion Inventory against final token values:
  - `circle_icon_button_test` asserts `maxWidth == 40` → `circleButtonVisualSize == 40.0` ✅
  - `circle_icon_button_test` asserts `icon.size == 30` → custom test value, not default ✅
  - `sliver_tab_bar_delegate_test` asserts dynamic height → not affected ✅
  - `scale_button_test` asserts `opacity == 0.38` → `AppStates.disabledOpacity == 0.38`, no change ✅
- [ ] (`@Sentinel`) Confirm no NEW test assertions were introduced that hardcode values.

### 8.6 Visual Zero-Diff Check
- [ ] (`@Pixel` | Skill: `audit`) Run app on device/emulator. Navigate to: Login, Home/Dashboard, Chat list, Profile, any screen with cards/buttons/avatars. Confirm NO visual changes.
- [ ] (`@Pixel` | Skill: `audit`) Check bottom navigation bar specifically (height changed from plan's 64 to actual 70 — must still look identical).
- [ ] (`@Pixel` | Skill: `audit`) Check AppButton height (54, not 48 — must still look identical).
- **GATE CHECK:** All tests pass. All tokens verified. All widgets audited. Visual zero-diff confirmed. Phase 0.7 COMPLETE.

---

## 7) Acceptance Criteria (MANDATORY)

1. `lib/core/theme/app_layout.dart` exists with all layout token categories.
2. All token values extracted from ACTUAL codebase (not Master Plan assumptions). Source citations in doc comments.
3. All tokens have `///` doc comments explaining usage context.
4. `AppLayout` class has private constructor (`AppLayout._()`) and only `static const` members.
5. File-level doc comment explains three-layer architecture and `AppDimens` vs `AppLayout` distinction.
6. NO overlapping icon size values between `AppLayout` and `AppDimens`.
7. All 15 `lib/core/widgets/` files + `main_navigation_screen.dart` are migrated, classified as clean, or documented as skip with rationale.
8. Skeleton files are selectively migrated (semantic values only). Non-semantic placeholder dimensions stay hardcoded with inline comments.
9. `lib/core/theme/theme_dashboard.dart` updated with Layout Tokens section and three-layer architecture.
10. `flutter analyze` passes with zero errors, zero warnings.
11. `flutter test` passes with zero new failures (baseline: 1297 passed, 30 skipped, 1 pre-existing).
12. No `lib/features/` files are modified.
13. No visual changes visible on device/emulator.
14. Session log complete with: Migration Classification Table, Test Assertion Inventory, Value Extraction Table, per-phase migration notes.

## 8) Rollback Plan

- **All changes are additive and non-breaking:**
  - `app_layout.dart` is a new file — can be deleted.
  - Widget changes replace hardcoded values with token references resolving to the SAME values — reverting is safe but unnecessary.
  - `theme_dashboard.dart` changes are documentation-only.
- **Rollback strategy:** `git revert` the Phase 0.7 commit(s). No database, RLS, or backend changes.
- **Forward-fix preference:** If a token value is wrong, fix the token value in `app_layout.dart` rather than reverting widget migration.

## 9) References (From Scan)

### Docs Scanned
- `.impeccable.md` — design rules, 4px grid, 24px margins, NO GLASS
- `.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md` — parent plan, Phase 0.7 spec
- `.TODO/PLAN_DesignSystemFoundation_2026-04-07.md` — Phase 0 plan (completed)
- `.TODO/PLAN_CRITIQUE_2026-04-08_LayoutTokens_Phase0.7.md` — this plan's critique
- `docs/LOG/SESSION_PLAN_DesignSystemFoundation_2026-04-07.md`
- `docs/LOG/SESSION_PLAN_CoreWidgetRedesign_2026-04-07.md`
- `docs/LOG/SESSION_PLAN_Phase2_AppShellAuthCards_2026-04-08.md`

### Code Paths Scanned
- `lib/core/theme/` — all 8 files
- `lib/core/widgets/` — all 15 files (line counts, hardcoded values, imports)
- `lib/app/main_navigation_screen.dart` — 325 lines
- `test/core/widgets/` — 13 test files, 85 test cases, 3 with pixel assertions
- Hardcoded layout grep across `lib/` (416 total instances)

### Session Log
- **Path:** `docs/LOG/SESSION_PLAN_LayoutTokens_Phase0.7_2026-04-08.md`

## 10) Scan Evidence (Mandatory Appendix)

### Corrected Token Values (From @PlanCritic Audit)
| Token | Master Plan Value | ACTUAL Value | Source | Decision |
|-------|------------------|-------------|--------|----------|
| bottomNavHeight | 64 | **70** | custom_bottom_nav_bar.dart:110 | Use 70 |
| buttonHeight | 48 | **54** | app_button.dart:248 (AppDimens.p54) | Use 54, rename to buttonHeight |
| buttonHeightCompact | 36 | **48** | app_styled_button.dart:46 | Use 48 |
| circleIconButtonSize | 48 | **40 (visual) / 48 (touch)** | circle_icon_button.dart:33/69 | Split into circleButtonVisualSize + minTouchTarget |
| avatarMedium | 44 | 44 | confirmed | Keep 44 |
| avatarDefault | (not proposed) | **40** | signed_avatar.dart:73 (radius=20) | ADD new token |
| iconSmall | 16 | 16 | CONFLICTS with AppDimens.iconSizeSmall | REMOVE from AppLayout |
| iconMedium | 24 | 24 | CONFLICTS with AppDimens.iconSizeMedium | REMOVE from AppLayout |
| iconLarge | 32 | 32 | CONFLICTS with AppDimens.iconSizeLarge | REMOVE from AppLayout |

### Widget Migration Classification
| File | Lines | Classification | Semantic to Replace | Non-Semantic to Keep |
|------|-------|---------------|--------------------|--------------------|
| app_card.dart | 75 | CLEAN | 0 | 0 |
| app_card_container.dart | 68 | LIGHT | 1 (border width) | 0 |
| app_button.dart | 285 | MEDIUM | 3 (spacing, icon sizes) | 0 |
| app_styled_button.dart | 126 | MEDIUM | 2 (height, border) | 1 (icon: 18) |
| circle_icon_button.dart | 80 | MEDIUM | 3 (size, icon, touch) | 0 |
| scale_button.dart | 129 | SKIP | 0 | 1 (50ms delay) |
| signed_avatar.dart | 346 | MEDIUM | 2 (radius, border) | 4 (spinner, indicator) |
| signed_image.dart | 255 | COMPLEX | 1 (spacing) | 5 (defaults, icon, fontSize) |
| skeleton_card.dart | 515 | HEAVY-SELECTIVE | ~5 (padding, radius) | 15+ (placeholder dims) |
| skeleton_card_extended.dart | 351 | HEAVY-SELECTIVE | ~3 (padding, radius) | 12+ (placeholder dims) |
| skeleton_loader.dart | 158 | LIGHT | 0-1 (avatar size) | 1 (animation range) |
| app_text_field.dart | 218 | MEDIUM | 3 (icon, spacing) | 1 (spacing: 12 → AppDimens) |
| custom_bottom_nav_bar.dart | 345 | HEAVY | 4 (height, width, padding, border) | 4 (fontSize: 9, padding: 1, etc.) |
| status_badge.dart | 234 | MEDIUM | 1 (spacing) | 5+ (badge-specific sizes) |
| sliver_tab_bar_delegate.dart | 51 | LIGHT | 1 (border width) | 0 |
| main_navigation_screen.dart | 325 | MEDIUM | 3 (bottom, width, height) | 3 (blur, icon: 30, animation) |

### Test Assertion Inventory
| Test File | Asserted Value | Widget Constant | AppLayout Token | Risk |
|-----------|---------------|----------------|----------------|------|
| circle_icon_button_test.dart | maxWidth == 40, maxHeight == 40 | size=40 | circleButtonVisualSize=40 | SAFE ✅ |
| circle_icon_button_test.dart | icon.size == 30 | custom (not default) | N/A | SAFE ✅ |
| sliver_tab_bar_delegate_test.dart | preferredSize.height | dynamic (TabBar) | N/A | SAFE ✅ |
| scale_button_test.dart | opacity == 0.38 | AppStates.disabledOpacity | N/A (not changed) | SAFE ✅ |

### Singleton/Static State
- None. `AppLayout` is pure static constants.

### Provider Dependencies
- None. `AppLayout` is not a provider.

END.
