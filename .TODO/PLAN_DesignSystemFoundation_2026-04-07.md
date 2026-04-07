# Plan: Design System Foundation (Phase 0 of UI Redesign)

## 1) Goal
- **Goal:** Establish a complete, token-based design system foundation that all 134 UI files will inherit.
- **Why:** The current theme layer is structurally sound (1,348 lines across 6 files) but lacks motion tokens, interaction state definitions, a shadow elevation scale, proper typography line-heights, semantic status colors, and Material component themes. Without this foundation, every screen redesign will re-invent tokens ad hoc.
- **Result:** 2 new theme files (`app_motion.dart`, `app_states.dart`), 4 updated theme files, `.impeccable.md` design context, and a matching Figma token library. All downstream phases (1-16) can reference centralized tokens with zero hardcoded values.

## 2) Scope

### In-Scope
- Design context setup (`.impeccable.md` via `teach-impeccable` skill)
- Motion token file (`lib/core/theme/app_motion.dart`) — durations, curves, scale amounts, stagger delays, reduced-motion helper
- Interaction state definitions file (`lib/core/theme/app_states.dart`) — 8-state model constants, shake/focus/opacity values
- Shadow/elevation scale addition to `lib/core/theme/app_decorations.dart`
- Typography line-height and letter-spacing updates to `lib/core/theme/app_typography.dart`
- Semantic color expansion (success/warning/info/danger + interactive overlays) in `lib/core/theme/app_colors.dart`
- Material component theme additions (Card, Dialog, BottomSheet, Chip, Divider, SnackBar, TabBar) in `lib/core/theme/app_theme.dart`
- Theme dashboard reference doc update (`lib/core/theme/theme_dashboard.dart`)
- Figma token export strategy
- Reconciliation with existing `lib/core/utils/app_animations.dart` (330 lines, already has 4 durations, 4 curves, 3 scale values, 5 animation widgets)

### Out-of-Scope
- Migrating existing feature files to use new tokens (that is Phase 1+)
- Redesigning any widget or screen (Phase 1+)
- Any Supabase/backend changes
- Adding new dependencies to pubspec.yaml
- Changing app behavior or navigation

## 3) Evidence & Findings (From Scan)

### Existing
- **Theme files (6 files, 1,348 lines):**
  - `app_colors.dart` (411 lines): 12 base colors, 8 opacity variants, `AppColorScheme` with 32 properties, `lerp` support, light/dark factories. No semantic status colors (success/warning/info/danger).
  - `app_typography.dart` (110 lines): Plus Jakarta Sans, 14 styles (logo, h1-h6, subtitle, bodyLarge/Medium/Small, caption, captionBold, overline, micro). All use flat `height: 1.2`. Some letter-spacing exists on logo/h1-h4 but body/caption have none.
  - `app_dimens.dart` (54 lines): 25 spacing values (p0-p100), 12 border-radius values (r4-r50), 3 icon sizes.
  - `app_decorations.dart` (183 lines): 5 decoration methods (glass, bottomNav, inputField, hotBadge, authorInitials). No elevation scale.
  - `app_theme.dart` (195 lines): `AppThemeExtension` + light/dark factories. Only themes: ElevatedButton, InputDecoration, AppBar. Missing: Card, Dialog, BottomSheet, Chip, Divider, SnackBar, TabBar.
  - `theme_dashboard.dart` (395 lines): Documentation-only reference file. Last updated 2024 — stale.

- **Animation infrastructure (`app_animations.dart`, 330 lines):**
  - 4 duration constants: `fast` (200ms), `normal` (300ms), `slow` (400ms), `slower` (500ms)
  - 4 curves: `slideUpCurve`, `easeOut`, `springCurve` (0.175, 0.885, 0.32, 1.275), `fadeInCurve`
  - 3 scale values: `scalePressed` (0.95), `scaleHover` (1.02), `scaleActive` (1.1)
  - 5 animation widgets: `FadeInWidget`, `SlideUpWidget`, `SpringButton`, `HoverScaleWidget`, `AnimatedRotationButton`

- **Route transitions (`custom_route_transitions.dart`, 50 lines):**
  - `SlideUpRoute` (400ms, easeOutCubic)
  - `FadeRoute` (300ms)

- **ThemeModeProvider (35 lines):** Default `ThemeMode.dark`, cycles light/dark/system.

- **Provider registration in main.dart (598 lines):** Theme applied via `Consumer<ThemeModeProvider>` → `MaterialApp(theme: AppTheme.light(), darkTheme: AppTheme.dark())`.

### Missing
- `.impeccable.md` — does NOT exist (required by all `.cursor/skills/`)
- `app_motion.dart` — does NOT exist (animation tokens scattered between `app_animations.dart` and individual widgets)
- `app_states.dart` — does NOT exist (no interaction state definitions anywhere)
- Elevation/shadow scale — does NOT exist (every widget has its own shadow)
- Semantic status colors — do NOT exist in `AppColorScheme` (status colors hardcoded in 11+ switch statements across card widgets)
- Component themes (Card, Dialog, BottomSheet, Chip, Divider, SnackBar, TabBar) — do NOT exist
- `HapticFeedback` usage — **0 instances** in entire codebase
- `Semantics` widget usage — **2 instances** in entire codebase (expiration_countdown, payment_status_badge)
- `MediaQuery.disableAnimations` — **0 instances** (no reduced-motion support)

### Must NOT Duplicate
- `AppAnimations` class in `app_animations.dart` already has duration/curve/scale constants. The new `app_motion.dart` must either **extend** or **replace** this file, not create a parallel set of tokens.
- `ScaleButton` in `core/widgets/` and `SpringButton` in `app_animations.dart` are **near-duplicates** (both provide tap-to-scale). Must decide which to keep.

### Conflicts / Risks
- **Naming conflict:** `AppAnimations.fast` (200ms) vs proposed `AppMotion.fast` (200ms). Both mean the same thing. Must unify or alias.
- **SpringButton vs ScaleButton:** Both exist, both do press-to-scale. `ScaleButton` is used in production by `GlassCard` and `GlassButton`. `SpringButton` may be unused — verify before removing.
- **Existing `app_animations.dart` widgets (`FadeInWidget`, `SlideUpWidget`):** These are useful utilities. Must be preserved or migrated.
- **Typography line-height change risk:** Changing `height: 1.2` to `1.5` for body text WILL affect layout of every screen. Text will take more vertical space. This is correct but may cause overflow in tightly-packed cards. Downstream phases must audit.
- **Dark mode shadows:** Current shadows use black alpha. Dark mode may need lighter shadows (white alpha) for visibility. Elevation helper must accept `isDark` parameter.
- **theme_dashboard.dart** says "Last Updated: 2024" — significantly stale. Update is mandatory.

## 4) System Impact Map
- **UI:** All 134 view/widget files inherit theme changes. No visual changes in this phase (tokens only), but typography line-height changes WILL cause subtle layout shifts.
- **MVVM / App Logic:** None. Theme files are read-only by views.
- **Database:** None.
- **RLS / Security:** None.
- **RPC / Edge Functions:** None.
- **Storage:** None.
- **Realtime / Notifications:** None.
- **Observability:** None.
- **Compatibility & Migration:** Typography line-height changes are additive and non-breaking at the code level but will shift UI layouts.
- **Contracts:** None.

## 5) Agent Map
- **Phase 1 (Design Context):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 2 (Motion Tokens):** `@Pixel` (primary), `@Architect` (review), `@Sentinel` (gate)
- **Phase 3 (Interaction States):** `@Pixel` (primary), `@Architect` (review), `@Sentinel` (gate)
- **Phase 4 (Elevation Scale):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 5 (Typography):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 6 (Semantic Colors):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 7 (Component Themes):** `@Pixel` (primary), `@Architect` (review), `@Sentinel` (gate)
- **Phase 8 (Theme Dashboard Doc):** `@SlineDocs` (primary), `@Sentinel` (gate)
- **Phase 9 (QA + Verification):** `@Sentinel` (primary), `@CodeGuard` (review)

---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** `@SlinePlanner`, `@Sentinel`

### 0.1 Spec Lock
- [ ] (`@Sentinel`) Acceptance criteria defined (see Section 7 below).
- [ ] (`@Architect`) Confirm touched files: 6 existing theme files + 2 new files + `app_animations.dart` + `theme_dashboard.dart`.
- [ ] (`@SlineDocs`) Confirm `.impeccable.md` does not exist yet.
- **GATE CHECK:** Scope is limited to `lib/core/theme/`, `lib/core/utils/app_animations.dart`, and `.impeccable.md`. No feature files touched.

### 0.2 Duplication Check
- [ ] (`@Architect`) Verify `SpringButton` usage across codebase. If unused, mark for deprecation. If used, document where.
- [ ] (`@Architect`) Verify `FadeInWidget`, `SlideUpWidget`, `HoverScaleWidget`, `AnimatedRotationButton` usage. Document which are used in production.
- [ ] (`@Architect`) Decide: does `app_motion.dart` replace `AppAnimations` class constants, or extend it? Document decision.
- **GATE CHECK:** No duplicate token sources will exist after this phase.

---

## Phase 1: Design Context Setup

**Primary Agent(s):** `@Pixel`
**Goal:** Generate `.impeccable.md` — the persistent design context that all skills read from.
**Why:** Every skill in `.cursor/skills/` checks for `.impeccable.md` before executing. Without it, skills run without aesthetic direction.
**How:** Run `teach-impeccable` skill interactively.
**Result:** `.impeccable.md` at project root with aesthetic direction, brand personality, target users, accessibility bar.

### 1.1 Run teach-impeccable
- [ ] (`@Pixel` | Skill: `teach-impeccable`) Execute the skill. It will:
  - Sub-step 1.1.1: Scan codebase for existing design patterns (theme files, components, brand assets).
  - Sub-step 1.1.2: Ask UX-focused questions about users, brand personality, aesthetic preferences, accessibility.
  - Sub-step 1.1.3: Write and persist design context to `.impeccable.md`.
- [ ] (`@Pixel`) Review generated `.impeccable.md`. Verify it captures:
  - SLine's teal (#146068) + gold (#f3bb19) brand colors
  - Iraqi freelance marketplace context
  - Plus Jakarta Sans typography choice
  - Glassmorphism aesthetic (used intentionally, not everywhere)
  - Dark mode as default (ThemeModeProvider defaults to `ThemeMode.dark`)
  - WCAG AA accessibility minimum
- [ ] (`@Sentinel`) Confirm `.impeccable.md` exists and is non-empty.
- **GATE CHECK:** `.impeccable.md` exists with design decisions documented.

---

## Phase 2: Motion Tokens

**Primary Agent(s):** `@Pixel`, `@Architect`
**Goal:** Create a single source of truth for all animation durations, curves, scale amounts, and stagger delays.
**Why:** Currently 30+ duration instances across 22 files, 9 curve usages across 5 files, with inconsistent values. `app_animations.dart` has 4 durations but the rest of the app ignores them.
**How:** Create `app_motion.dart` that supersedes `AppAnimations` constants while preserving `app_animations.dart` utility widgets.
**Result:** `lib/core/theme/app_motion.dart` with all motion tokens. `AppAnimations` class constants deprecated with `@Deprecated` annotations pointing to `AppMotion`.

### 2.1 Create app_motion.dart
- [ ] (`@Pixel` | Skill: `animate`) Create `lib/core/theme/app_motion.dart` with:
  - Sub-step 2.1.1: Duration constants — `micro` (100ms), `fast` (200ms), `standard` (300ms), `slow` (400ms), `emphasis` (500ms), `dramatic` (800ms), `shimmer` (1500ms).
  - Sub-step 2.1.2: Curve constants — `curveStandard` (easeOutCubic), `curveDecel` (easeOutQuart), `curveSharp` (easeOutExpo), `curveAccel` (easeInCubic), `curveSymmetric` (easeInOutCubic), `curveSpring` (Cubic(0.175, 0.885, 0.32, 1.075)).
  - Sub-step 2.1.3: Scale constants — `pressScale` (0.96), `hoverScale` (1.02), `badgeEntrance` (1.15), `emphasize` (1.05).
  - Sub-step 2.1.4: Stagger delays — `staggerSmall` (30ms), `staggerMedium` (50ms), `staggerLarge` (100ms).
  - Sub-step 2.1.5: `respectMotion(BuildContext, Duration)` helper that returns `Duration.zero` if `MediaQuery.of(context).disableAnimations` is true.
  - Sub-step 2.1.6: Banned curves doc comment listing `bounceIn`, `bounceOut`, `elasticIn`, `elasticOut` as NEVER-USE.
- [ ] (`@Architect`) Review: confirm `AppMotion` does not import feature code, only `flutter/material.dart`.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 2.2 Deprecate AppAnimations constants
- [ ] (`@Architect`) Add `@Deprecated('Use AppMotion.fast instead')` to `AppAnimations.fast`.
- [ ] (`@Architect`) Add `@Deprecated('Use AppMotion.standard instead')` to `AppAnimations.normal`.
- [ ] (`@Architect`) Add `@Deprecated('Use AppMotion.slow instead')` to `AppAnimations.slow`.
- [ ] (`@Architect`) Add `@Deprecated('Use AppMotion.emphasis instead')` to `AppAnimations.slower`.
- [ ] (`@Architect`) Add `@Deprecated('Use AppMotion.curveSpring instead')` to `AppAnimations.springCurve`.
- [ ] (`@Architect`) Add `@Deprecated('Use AppMotion.pressScale instead')` to `AppAnimations.scalePressed`.
- [ ] (`@Architect`) Add `@Deprecated('Use AppMotion.hoverScale instead')` to `AppAnimations.scaleHover`.
- [ ] (`@Architect`) Keep `FadeInWidget`, `SlideUpWidget`, `SpringButton`, `HoverScaleWidget`, `AnimatedRotationButton` — these are utility widgets, not tokens.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean (deprecation warnings are OK but no errors).

### 2.3 Verify motion token coverage
- [ ] (`@Sentinel`) Grep for `Duration(milliseconds:` across `lib/` — count should match scan baseline (30 instances).
- [ ] (`@Sentinel`) Confirm no new direct `Duration` or `Curves.*` references added in this phase.
- **GATE CHECK:** `app_motion.dart` exists, `app_animations.dart` constants deprecated, `flutter analyze` clean.

---

## Phase 3: Interaction State Definitions

**Primary Agent(s):** `@Pixel`, `@Architect`
**Goal:** Define the 8-state interaction model constants for all interactive elements.
**Why:** Currently buttons have 2 states (default, loading), fields have 1 state (default). No focus rings, no error shake, no success flash, no disabled styling, no haptic definitions.
**How:** Create `app_states.dart` with constant values. Widgets are updated in UI Redesign Phase 1.
**Result:** `lib/core/theme/app_states.dart` with all interaction state constants.

### 3.1 Create app_states.dart
- [ ] (`@Pixel` | Skill: `harden`) Create `lib/core/theme/app_states.dart` with:
  - Sub-step 3.1.1: Document the 8-state model in class doc comment: default, hover, focus, active/pressed, disabled, loading, success, error.
  - Sub-step 3.1.2: Opacity values — `disabledOpacity` (0.38), `hoverOverlayOpacity` (0.04), `pressedOverlayOpacity` (0.08), `flashOverlayOpacity` (0.15).
  - Sub-step 3.1.3: Focus ring values — `focusRingWidth` (2.0), `focusRingOffset` (2.0).
  - Sub-step 3.1.4: Loading indicator values — `loadingSize` (18.0), `loadingStrokeWidth` (2.0).
  - Sub-step 3.1.5: Error shake values — `shakeAmplitude` (4.0), `shakeCycles` (3), `shakeDuration` (300ms).
  - Sub-step 3.1.6: Success/error flash values — `flashDuration` (300ms), `revertDelay` (1500ms).
  - Sub-step 3.1.7: Haptic mapping doc comment: lightImpact for taps, selectionClick for toggles, mediumImpact for success, heavyImpact for destructive.
- [ ] (`@Architect`) Review: confirm file has private constructor, only `static const` values, no mutable state.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** `app_states.dart` exists with all constants. No widget changes yet (Phase 1 of UI Redesign).

---

## Phase 4: Shadow & Elevation Scale

**Primary Agent(s):** `@Pixel`
**Goal:** Add a 5-level elevation system to `app_decorations.dart`.
**Why:** Currently every card widget has its own shadow with inconsistent blur (8-20) and offset (1-8) values. 233 `BoxShadow` instances across 73 files.
**How:** Add `elevation()` static method to `AppDecorations`.
**Result:** Updated `app_decorations.dart` with `elevation(int level, {bool isDark})` method.

### 4.1 Add elevation method
- [ ] (`@Pixel` | Skill: `normalize`) Add to `AppDecorations` in `lib/core/theme/app_decorations.dart`:
  - Sub-step 4.1.1: Add `static List<BoxShadow> elevation(int level, {bool isDark = false})` method.
  - Sub-step 4.1.2: Level 0 (flat): empty list — for items at rest in scrolling lists.
  - Sub-step 4.1.3: Level 1 (resting): blur=4, offset=(0,1), alpha=0.06 — default cards.
  - Sub-step 4.1.4: Level 2 (raised): blur=8, offset=(0,2), alpha=0.08 — hovered/focused cards.
  - Sub-step 4.1.5: Level 3 (floating): blur=16, offset=(0,4), alpha=0.12 — modals, FAB, dragged.
  - Sub-step 4.1.6: Level 4 (dramatic): blur=24, offset=(0,8), alpha=0.16 — popovers, dropdowns.
  - Sub-step 4.1.7: Dark mode multiplier: `isDark ? 0.3 : 1.0` applied to alpha values.
  - Sub-step 4.1.8: Default case returns level 1.
  - Sub-step 4.1.9: Add doc comment explaining each level with usage guidance.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- [ ] (`@Sentinel`) Verify existing 5 decoration methods are unchanged (no regressions).
- **GATE CHECK:** `elevation()` method exists. Existing decorations untouched. `flutter analyze` clean.

---

## Phase 5: Typography Line Heights & Letter Spacing

**Primary Agent(s):** `@Pixel`
**Goal:** Update line heights from flat 1.2 to context-appropriate values. Add letter-spacing where missing.
**Why:** Body text at 14px/1.2 = 16.8px line height is cramped and hard to read. Headings need tighter height for impact. Captions need moderate height for scannability.
**How:** Update `_baseTextStyle` and individual getters in `app_typography.dart`.
**Result:** Updated `app_typography.dart` with per-style line heights and letter spacing.

### 5.1 Update base text style
- [ ] (`@Pixel` | Skill: `typeset`) In `lib/core/theme/app_typography.dart`:
  - Sub-step 5.1.1: Remove `height: 1.2` from `_baseTextStyle` (each style will define its own).
  - Sub-step 5.1.2: Update `logo`: add `height: 1.0` (display text, tight).
  - Sub-step 5.1.3: Update `h1`: change `height` to `1.1`.
  - Sub-step 5.1.4: Update `h2`: change `height` to `1.15`.
  - Sub-step 5.1.5: Update `h3`: keep `height: 1.2`.
  - Sub-step 5.1.6: Update `h4`: keep `height: 1.2`.
  - Sub-step 5.1.7: Update `h5`: change `height` to `1.25`.
  - Sub-step 5.1.8: Update `subtitle`: change `height` to `1.3`.
  - Sub-step 5.1.9: Update `h6`: change `height` to `1.25`.
  - Sub-step 5.1.10: Update `bodyLarge`: change `height` to `1.5`.
  - Sub-step 5.1.11: Update `bodyMedium`: change `height` to `1.5`.
  - Sub-step 5.1.12: Update `bodySmall`: change `height` to `1.4`, add `letterSpacing: 0.1`.
  - Sub-step 5.1.13: Update `caption`: change `height` to `1.3`, add `letterSpacing: 0.2`.
  - Sub-step 5.1.14: Update `captionBold`: change `height` to `1.3`, add `letterSpacing: 0.2`.
  - Sub-step 5.1.15: Update `overline`: change `height` to `1.3`, add `letterSpacing: 1.5`.
  - Sub-step 5.1.16: Update `micro`: keep `height: 1.2`, add `letterSpacing: 0.3`.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- [ ] (`@Sentinel`) Run `flutter test` — confirm no test failures from height changes. If failures occur, document which tests and why.
- **GATE CHECK:** All 14 text styles have explicit `height` values. Body text uses 1.4-1.5. `flutter analyze` clean.

---

## Phase 6: Semantic Color Expansion

**Primary Agent(s):** `@Pixel`
**Goal:** Add semantic status colors and interactive state colors to `AppColorScheme`.
**Why:** Status colors are currently hardcoded in 11+ switch statements across card widgets (booking_card has 11 cases, status_badge has 6+). No success/warning/info/danger tokens exist.
**How:** Add new properties to `AppColorScheme` and both `light()` and `dark()` factories.
**Result:** Updated `app_colors.dart` with 12 new color properties.

### 6.1 Add semantic properties to AppColorScheme
- [ ] (`@Pixel` | Skill: `colorize`) In `lib/core/theme/app_colors.dart`:
  - Sub-step 6.1.1: Add `final Color success;` property.
  - Sub-step 6.1.2: Add `final Color successMuted;` property.
  - Sub-step 6.1.3: Add `final Color warning;` property.
  - Sub-step 6.1.4: Add `final Color warningMuted;` property.
  - Sub-step 6.1.5: Add `final Color info;` property.
  - Sub-step 6.1.6: Add `final Color infoMuted;` property.
  - Sub-step 6.1.7: Add `final Color danger;` property.
  - Sub-step 6.1.8: Add `final Color dangerMuted;` property.
  - Sub-step 6.1.9: Add `final Color hoverOverlay;` property.
  - Sub-step 6.1.10: Add `final Color pressedOverlay;` property.
  - Sub-step 6.1.11: Add `final Color focusRing;` property.
  - Sub-step 6.1.12: Add `final Color disabledFill;` property.

### 6.2 Update constructor and factories
- [ ] (`@Pixel` | Skill: `colorize`) In `lib/core/theme/app_colors.dart`:
  - Sub-step 6.2.1: Add all 12 new required parameters to `AppColorScheme` constructor.
  - Sub-step 6.2.2: Update `AppColorScheme.light()` factory with light-mode values:
    - success: `Color(0xFF2E7D32)` (green-700), successMuted: `Color(0xFFE8F5E9)` (green-50)
    - warning: `Color(0xFFF57F17)` (amber-900), warningMuted: `Color(0xFFFFF8E1)` (amber-50)
    - info: `Color(0xFF1565C0)` (blue-800), infoMuted: `Color(0xFFE3F2FD)` (blue-50)
    - danger: `Color(0xFFC62828)` (red-800), dangerMuted: `Color(0xFFFFEBEE)` (red-50)
    - hoverOverlay: `AppColors.teal.withValues(alpha: 0.04)`
    - pressedOverlay: `AppColors.teal.withValues(alpha: 0.08)`
    - focusRing: `AppColors.teal`
    - disabledFill: `Color(0x14000000)` (black at 8%)
  - Sub-step 6.2.3: Update `AppColorScheme.dark()` factory with dark-mode values:
    - success: `Color(0xFF66BB6A)` (green-400), successMuted: `Color(0xFF1B3D1F)`
    - warning: `Color(0xFFFFB300)` (amber-600), warningMuted: `Color(0xFF3D2E00)`
    - info: `Color(0xFF42A5F5)` (blue-400), infoMuted: `Color(0xFF0D2137)`
    - danger: `Color(0xFFEF5350)` (red-400), dangerMuted: `Color(0xFF3D1111)`
    - hoverOverlay: `AppColors.lightTeal.withValues(alpha: 0.06)`
    - pressedOverlay: `AppColors.lightTeal.withValues(alpha: 0.10)`
    - focusRing: `AppColors.lightTeal`
    - disabledFill: `Color(0x14FFFFFF)` (white at 8%)
  - Sub-step 6.2.4: Update `AppColorScheme.lerp()` to interpolate all 12 new properties.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- [ ] (`@Sentinel` | Skill: `audit`) Check contrast ratios: each semantic color on its muted background must be >= 4.5:1 for normal text.
- **GATE CHECK:** 12 new color properties in `AppColorScheme`. Both light and dark factories populated. `lerp` handles all new properties. `flutter analyze` clean.

---

## Phase 7: Material Component Themes

**Primary Agent(s):** `@Pixel`, `@Architect`
**Goal:** Add themed component defaults to `ThemeData` so cards, dialogs, sheets, chips, dividers, snackbars, and tab bars have consistent styling without per-widget overrides.
**Why:** Currently only ElevatedButton, InputDecoration, and AppBar are themed. All other components use Material defaults, which don't match the SLine design language.
**How:** Add component themes to `_buildTheme()` in `app_theme.dart`.
**Result:** Updated `app_theme.dart` with 7 new component theme properties.

### 7.1 Add CardTheme
- [ ] (`@Pixel` | Skill: `normalize`) Add `cardTheme` to `ThemeData` in `_buildTheme()`:
  - `elevation: 0`
  - `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.r16))`
  - `color: appColorScheme.cardBackground`
  - `margin: EdgeInsets.zero`

### 7.2 Add DialogTheme
- [ ] (`@Pixel` | Skill: `normalize`) Add `dialogTheme` to `ThemeData`:
  - `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.r24))`
  - `backgroundColor: appColorScheme.cardBackground`
  - `elevation: 0`

### 7.3 Add BottomSheetThemeData
- [ ] (`@Pixel` | Skill: `normalize`) Add `bottomSheetTheme` to `ThemeData`:
  - `shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.r24)))`
  - `backgroundColor: appColorScheme.cardBackground`
  - `elevation: 0`
  - `showDragHandle: true`
  - `dragHandleColor: appColorScheme.outline`
  - `dragHandleSize: Size(32, 4)`

### 7.4 Add ChipThemeData
- [ ] (`@Pixel` | Skill: `normalize`) Add `chipTheme` to `ThemeData`:
  - `shape: StadiumBorder()`
  - `backgroundColor: Colors.transparent`
  - `side: BorderSide(color: appColorScheme.outline, width: 0.5)`
  - `labelStyle: AppTypography.captionBold.copyWith(color: appColorScheme.text)`
  - `padding: EdgeInsets.symmetric(horizontal: AppDimens.p12, vertical: AppDimens.p4)`

### 7.5 Add DividerThemeData
- [ ] (`@Pixel` | Skill: `normalize`) Add `dividerTheme` to `ThemeData`:
  - `color: appColorScheme.outline`
  - `thickness: 0.5`
  - `space: 0`

### 7.6 Add SnackBarThemeData
- [ ] (`@Pixel` | Skill: `normalize`) Add `snackBarTheme` to `ThemeData`:
  - `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.r12))`
  - `behavior: SnackBarBehavior.floating`
  - `backgroundColor: appColorScheme.text`
  - `contentTextStyle: AppTypography.bodySmall.copyWith(color: appColorScheme.phoneBackground)`

### 7.7 Add TabBarTheme
- [ ] (`@Pixel` | Skill: `normalize`) Add `tabBarTheme` to `ThemeData`:
  - `labelColor: AppColors.teal`
  - `unselectedLabelColor: appColorScheme.textSecondary`
  - `indicatorSize: TabBarIndicatorSize.label`
  - `indicator: UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.teal, width: 3), borderRadius: BorderRadius.circular(2))`
  - `labelStyle: AppTypography.captionBold`
  - `unselectedLabelStyle: AppTypography.caption`

### 7.8 Review & verify
- [ ] (`@Architect`) Review all component themes for consistency with existing ElevatedButton and InputDecoration themes.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- [ ] (`@Sentinel`) Verify `flutter test` — confirm no test failures from new component themes.
- **GATE CHECK:** 7 component themes added. `flutter analyze` clean. `flutter test` passes.

---

## Phase 8: Theme Dashboard Documentation Update

**Primary Agent(s):** `@SlineDocs`
**Goal:** Update `theme_dashboard.dart` to reflect all Phase 0 additions.
**Why:** Currently says "Last Updated: 2024" and is missing motion tokens, interaction states, elevation scale, semantic colors, and component themes.
**How:** Update the documentation-only reference class.
**Result:** Updated `theme_dashboard.dart` with all new tokens documented.

### 8.1 Update theme_dashboard.dart
- [ ] (`@SlineDocs`) Update the "Last Updated" timestamp to 2026-04-07.
- [ ] (`@SlineDocs`) Add "Motion Tokens" section documenting all `AppMotion` values.
- [ ] (`@SlineDocs`) Add "Interaction States" section documenting `AppInteractionStates` values.
- [ ] (`@SlineDocs`) Add "Elevation Scale" section documenting the 5 levels.
- [ ] (`@SlineDocs`) Add "Semantic Colors" section documenting success/warning/info/danger (light + dark).
- [ ] (`@SlineDocs`) Add "Component Themes" section listing all 7 themed components with their properties.
- [ ] (`@SlineDocs`) Update existing Typography section with new line-height and letter-spacing values.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** `theme_dashboard.dart` is current and comprehensive.

---

## Phase 9: QA + Verification (MANDATORY)

**Primary Agent(s):** `@Sentinel`, `@CodeGuard`

### 9.1 Static Analysis
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass with zero errors, zero warnings (deprecation infos OK).
- [ ] (`@Sentinel`) Run `dart format .` — must produce no changes.

### 9.2 Test Suite
- [ ] (`@Sentinel`) Run `flutter test` — must produce zero new failures.
- [ ] (`@Sentinel`) If test failures occur from typography height changes, document each failure with file name, test name, and root cause. These become Phase 1 tasks.

### 9.3 Token Completeness Audit
- [ ] (`@Sentinel`) Confirm `app_motion.dart` exists with >= 7 duration constants, >= 6 curve constants, >= 4 scale constants, >= 3 stagger delays, 1 respectMotion helper.
- [ ] (`@Sentinel`) Confirm `app_states.dart` exists with >= 6 opacity/size/duration constants.
- [ ] (`@Sentinel`) Confirm `AppDecorations.elevation()` exists and returns correct shadow lists for levels 0-4.
- [ ] (`@Sentinel`) Confirm `AppColorScheme` has 12 new color properties (success, successMuted, warning, warningMuted, info, infoMuted, danger, dangerMuted, hoverOverlay, pressedOverlay, focusRing, disabledFill).
- [ ] (`@Sentinel`) Confirm all 14 typography styles have explicit `height` values (not inherited from base).
- [ ] (`@Sentinel`) Confirm 7 component themes exist in `_buildTheme()`.
- [ ] (`@Sentinel`) Confirm `AppAnimations` constants have `@Deprecated` annotations.

### 9.4 Visual Spot Check
- [ ] (`@Pixel` | Skill: `audit`) Run the app on a device/emulator. Navigate to: Login, Home, Dashboard, Chat, Profile. Verify no visual regressions from typography height changes. Screenshot any issues.

### 9.5 Figma Export Strategy
- [ ] (`@Pixel`) Document the Figma token export approach:
  - Option A: Manual sync (create Figma variables matching code tokens)
  - Option B: Use `mcp__Figma__create_design_system_rules` to auto-generate
  - Option C: Screenshot code token files and add to Figma as reference
  - Record chosen approach.
- **GATE CHECK:** All tests pass. All tokens verified. Visual spot check clean. Figma approach documented.

---

## 7) Acceptance Criteria (MANDATORY)

1. `.impeccable.md` exists at project root with aesthetic direction, brand personality, and accessibility bar.
2. `lib/core/theme/app_motion.dart` exists with all motion tokens (durations, curves, scales, staggers, respectMotion helper).
3. `lib/core/theme/app_states.dart` exists with all interaction state constants.
4. `lib/core/theme/app_decorations.dart` has `elevation(int level, {bool isDark})` returning correct shadow lists for 5 levels.
5. `lib/core/theme/app_typography.dart` has per-style `height` values (1.0-1.5 range) and `letterSpacing` where specified.
6. `lib/core/theme/app_colors.dart` has 12 new semantic+interactive color properties in `AppColorScheme` with both light and dark values.
7. `lib/core/theme/app_theme.dart` has 7 component themes (Card, Dialog, BottomSheet, Chip, Divider, SnackBar, TabBar).
8. `lib/core/theme/theme_dashboard.dart` updated to reflect all changes.
9. `AppAnimations` duration/curve/scale constants have `@Deprecated` annotations.
10. `flutter analyze` passes with zero errors.
11. `flutter test` passes with zero new failures.
12. No feature files (`lib/features/`) were modified.

## 8) Rollback Plan

- **All changes are additive and non-breaking:**
  - New files (`app_motion.dart`, `app_states.dart`) can be deleted.
  - New properties added to `AppColorScheme` can be removed (but require removing from constructor + factories + lerp).
  - Typography height changes are the highest-risk item — if they cause widespread layout issues, revert `app_typography.dart` to flat `height: 1.2` and address per-screen in Phase 1.
  - Component themes are defaults that existing widgets can override — safe to add/remove.
  - `@Deprecated` annotations on `AppAnimations` are informational only — zero runtime impact.
- **Rollback strategy:** `git revert` the Phase 0 commit(s). No database, RLS, or backend changes to revert.
- **Forward-fix preference:** Typography height changes should be forward-fixed per-screen in Phase 1 rather than reverted, since the new values are correct for readability.

## 9) References (From Scan)

### Docs Scanned
- `Sline_everything/DEVELOPER_GUIDE.md` — v2.21.0, Phase F, 982 tests passing
- `Sline_everything/ARCHITECTURE_ANALYSIS.md` — v2.20, hardened payment gateway
- `Sline_everything/CODE_REVIEW.md` — 9.7/10 score, Phase F guardrails
- `Sline_everything/STRUCTURE.md` — Phase F, 40.8% coverage

### Code Paths Scanned
- `lib/core/theme/` — all 6 files (1,348 lines total)
- `lib/core/utils/app_animations.dart` — 330 lines
- `lib/core/utils/transitions/custom_route_transitions.dart` — 50 lines
- `lib/core/providers/theme_mode_provider.dart` — 35 lines
- `lib/main.dart` — 598 lines (theme application, provider registration, routes)
- `lib/core/widgets/` — all 14 widget files
- Animation patterns grep across entire `lib/` (30 duration instances, 9 curve usages)
- Anti-pattern grep across entire `lib/` (817 Colors.*, 408 BorderRadius.circular, 233 BoxShadow, 79 TextStyle, 33 fontSize)

### Existing .TODO/ Artifacts
- `.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md` — parent plan
- `.TODO/PHASE_INDEX.md` — phase dependency map
- `.TODO/PHASE_0_EXECUTION.md` — previous draft (superseded by this plan)

### Session Log
- **Path:** `docs/LOG/SESSION_PLAN_DesignSystemFoundation_2026-04-07.md`

## 10) Scan Evidence (Mandatory Appendix)

### File Line Counts
| File | Lines |
|------|-------|
| `lib/core/theme/app_colors.dart` | 411 |
| `lib/core/theme/app_typography.dart` | 110 |
| `lib/core/theme/app_dimens.dart` | 54 |
| `lib/core/theme/app_decorations.dart` | 183 |
| `lib/core/theme/app_theme.dart` | 195 |
| `lib/core/theme/theme_dashboard.dart` | 395 |
| `lib/core/utils/app_animations.dart` | 330 |
| `lib/core/utils/transitions/custom_route_transitions.dart` | 50 |
| `lib/core/providers/theme_mode_provider.dart` | 35 |
| `lib/main.dart` | 598 |

### Constructor Signatures
- `AppColorScheme({required Color phoneBackground, required Color cardBackground, ...})` — 32 required Color parameters. Adding 12 more.
- `AppColorScheme.light()` — factory, returns hardcoded light values.
- `AppColorScheme.dark()` — factory, returns hardcoded dark values.
- `AppColorScheme.lerp(AppColorScheme? a, AppColorScheme? b, double t)` — interpolation factory. Must add 12 new `Color.lerp` calls.
- `AppThemeExtension({required AppColorScheme colors})` — no change needed.

### Animation Baseline
- AnimationController instances: 14 across 5 files
- Duration(milliseconds:) instances: 30 across 22 files
- Curves.* instances: 9 across 5 files
- Tween instances: 9 across 5 files
- AnimatedContainer/Opacity/Positioned: 10 across 8 files
- HapticFeedback: 0 instances
- Semantics: 2 instances
- MediaQuery.disableAnimations: 0 instances

### Anti-Pattern Baseline (Migration Scope for Future Phases)
- `Colors.*` raw Material colors: 817 instances across 94 files
- `BorderRadius.circular` hardcoded: 408 instances across 105 files
- `BoxShadow` inline: 233 instances across 73 files
- `SizedBox` hardcoded: 189 instances
- `EdgeInsets` hardcoded: 169 instances
- `TextStyle` inline: 79 instances across 24 files
- `fontSize` hardcoded: 33 instances across 20 files

### Singleton/Static State
- None relevant to this phase. No singletons touched.

### Provider Dependencies
- `ThemeModeProvider` consumed by `MaterialApp` in `main.dart` via `Consumer<ThemeModeProvider>`.
- `AppTheme.light()` / `.dark()` called inside `MaterialApp` builder.
- No provider changes in this phase.

END.
