# PHASE 0: DESIGN SYSTEM FOUNDATION
> Status: NOT STARTED
> Estimated scope: 2 new files + 4 updated files
> Prerequisite: None (this IS the prerequisite for everything else)

---

## PHASE OBJECTIVE

Build the design tokens layer that every screen and component will inherit. This phase produces:
1. **Code:** New theme files + updated existing theme files
2. **Figma Bridge:** Export token values to Figma as variables (colors, spacing, typography, motion)
3. **Skill Exploration:** Run `teach-impeccable` + `typeset` + `colorize` + `normalize`

---

## WORKFLOW PER TASK

Each task in this phase follows this cycle:

```
1. EXPLORE    — Run the relevant skill to analyze current state
2. DESIGN     — Decide the new token values (document in this file)
3. CODE       — Implement in Flutter theme files
4. VERIFY     — flutter analyze + visual check
5. FIGMA SYNC — Export tokens to Figma (screenshot code, use get_variable_defs, or manual sync)
```

---

## STEP 0: DESIGN CONTEXT SETUP (One-Time)

### What
Run `teach-impeccable` skill to generate `.impeccable.md` — the persistent design context that all other skills read from.

### How
```
@Pixel teach-impeccable
```

This will:
1. Scan the codebase (theme files, components, brand assets)
2. Ask questions about: target users, brand personality, aesthetic direction, accessibility requirements
3. Write `.impeccable.md` with design decisions that guide all future skill runs

### Key Decisions to Make During Setup
- **Aesthetic direction:** Premium minimalist? Bold marketplace? Warm and approachable?
- **Brand personality:** SLine's teal (#146068) + gold (#f3bb19) — what mood do these convey?
- **Target users:** Iraqi freelance marketplace — what cultural and UX expectations?
- **Accessibility bar:** WCAG AA (minimum) or AAA (aspirational)?

### Output
- `.impeccable.md` file created at project root
- All future skill invocations automatically use this context

### Figma Sync
- After `.impeccable.md` is created, use it as the brief/spec when setting up a new Figma file
- Create a Figma page called "Design Decisions" and document the aesthetic direction there

---

## TASK 0.1: MOTION TOKENS

### Explore
Run `animate` skill on the current codebase to audit existing animation patterns:
```
@Pixel animate — Audit all current animations across the app. List every AnimationController, duration, and curve. Identify inconsistencies.
```

**Known current state (from code audit):**
| Widget | Duration | Curve | Purpose |
|--------|----------|-------|---------|
| ScaleButton | 100ms | easeInOut | Press scale |
| BottomNavBar pill | 300ms | easeOutCubic | Active pill |
| BottomNavBar scale | 300ms | easeOutBack | Icon scale |
| SkeletonLoader | 1500ms | easeInOutSine | Shimmer |
| WalletHeroCard bar | 450ms | easeOutCubic | Balance bar |
| DashboardOfferCard pulse | 1000ms | linear (repeat) | Urgency pulse |
| Category chips | 200ms | default | Background change |
| ConversationTile | 200ms | default | Unread bg |
| _Everything else_ | **NONE** | — | — |

### Design — Token Values

```dart
// FILE: lib/core/theme/app_motion.dart

/// Centralized motion tokens for the SLine app.
/// Rule: NEVER use raw Duration() or Curves.* in feature code.
/// Rule: Respect MediaQuery.disableAnimations — skip all motion if true.

class AppMotion {
  AppMotion._();

  // ── Durations ──────────────────────────────────────────────
  // 100/300/500 rule from motion-design.md
  static const Duration micro     = Duration(milliseconds: 100);   // ripples, toggles, icon swaps
  static const Duration fast      = Duration(milliseconds: 200);   // chips, badges, small state changes
  static const Duration standard  = Duration(milliseconds: 300);   // cards, sheets, tab switches
  static const Duration emphasis  = Duration(milliseconds: 500);   // page transitions, hero animations
  static const Duration dramatic  = Duration(milliseconds: 800);   // count-up numbers, progress bars
  static const Duration shimmer   = Duration(milliseconds: 1500);  // skeleton loaders (keep existing)

  // ── Curves ─────────────────────────────────────────────────
  // Ease-out family for entering/appearing elements
  static const Curve curveStandard  = Curves.easeOutCubic;    // default for most interactions
  static const Curve curveDecel     = Curves.easeOutQuart;     // elements entering the screen
  static const Curve curveSharp     = Curves.easeOutExpo;      // snappy UI responses (FAB, badge)

  // Ease-in family for exiting/disappearing elements
  static const Curve curveAccel     = Curves.easeInCubic;      // elements leaving the screen

  // Symmetric curves for state changes
  static const Curve curveSymmetric = Curves.easeInOutCubic;   // expand/collapse, size changes

  // Spring curve (subtle overshoot for delight)
  static const Curve curveSpring    = Cubic(0.175, 0.885, 0.32, 1.075);

  // ── BANNED CURVES ──────────────────────────────────────────
  // NEVER use: Curves.bounceIn, Curves.bounceOut, Curves.elasticIn, Curves.elasticOut
  // NEVER use: Curves.linear for visible animations (only for repeating loops like shimmer)

  // ── Scale Amounts ──────────────────────────────────────────
  static const double pressScale   = 0.96;   // button/card press-down
  static const double hoverScale   = 1.02;   // hover state (desktop/web)
  static const double badgeEntrance = 1.15;  // notification badge pop-in
  static const double emphasize    = 1.05;   // draw attention briefly

  // ── Stagger Delays ────────────────────────────────────────
  static const Duration staggerSmall  = Duration(milliseconds: 30);  // list items
  static const Duration staggerMedium = Duration(milliseconds: 50);  // cards in grid
  static const Duration staggerLarge  = Duration(milliseconds: 100); // major sections

  // ── Helper ─────────────────────────────────────────────────
  /// Returns Duration.zero if reduced motion is preferred.
  static Duration respectMotion(BuildContext context, Duration duration) {
    return MediaQuery.of(context).disableAnimations ? Duration.zero : duration;
  }
}
```

### Code
Create the file at `lib/core/theme/app_motion.dart` with the above content.

### Verify
- `flutter analyze` — must pass clean
- Grep for `Duration(milliseconds:` in feature files — these will be migrated later (Phase 1+)
- Grep for `Curves.bounce` and `Curves.elastic` — must be zero

### Figma Sync
- In Figma, create a page "Motion Tokens"
- Document: duration values, curve names, scale amounts
- Use Figma's prototype interactions to match these curves where possible
- Screenshot the motion token file and add to Figma as reference

---

## TASK 0.2: INTERACTION STATES

### Explore
Run `harden` skill to audit current widget states:
```
@Pixel harden — Audit all interactive widgets (buttons, fields, cards, toggles). For each, list which of the 8 states exist: default, hover, focus, active, disabled, loading, success, error.
```

**Known current state:**
| Widget | default | hover | focus | active | disabled | loading | success | error |
|--------|---------|-------|-------|--------|----------|---------|---------|-------|
| AppButton | YES | NO | NO | NO | Partial | YES (spinner) | NO | NO |
| AppTextField | YES | NO | NO | NO | NO | NO | NO | NO |
| GlassButton | YES | NO | NO | Partial (scale) | Opacity | YES (spinner) | NO | NO |
| ScaleButton | YES | NO | NO | YES (scale) | NO | NO | NO | NO |
| CircleIconButton | YES | NO | NO | NO | NO | NO | NO | NO |
| GlassCard | YES | NO | NO | Conditional scale | NO | NO | NO | NO |

### Design — State Definitions

```dart
// FILE: lib/core/theme/app_states.dart

/// Defines visual treatments for all 8 interactive states.
/// Widgets read from this to ensure consistent behavior across the app.

class AppInteractionStates {
  AppInteractionStates._();

  // ── Visual treatments per state ────────────────────────────
  //
  // DEFAULT:   Base appearance. No overlay. Scale 1.0.
  //
  // HOVER:     (desktop/web only)
  //            Overlay: primary color at 4% opacity
  //            Scale: 1.02 (AppMotion.hoverScale)
  //            Duration: AppMotion.fast
  //
  // FOCUS:     (keyboard/switch access)
  //            Outline: 2px solid, primary color, 2px offset outside
  //            No fill/scale change (focus != active)
  //            Must be visible on ALL backgrounds (light + dark)
  //
  // ACTIVE/PRESSED:
  //            Scale: 0.96 (AppMotion.pressScale)
  //            Overlay: primary color at 8% opacity
  //            Haptic: HapticFeedback.lightImpact()
  //            Duration: AppMotion.micro (100ms)
  //
  // DISABLED:
  //            Opacity: 0.38 (Material standard)
  //            No pointer events (AbsorbPointer or IgnorePointer)
  //            Cursor: not-allowed (web)
  //            Greyscale tint (not just opacity — maintain readability)
  //
  // LOADING:
  //            Replace primary content with SizedBox(18x18) CircularProgressIndicator
  //            Stroke width: 2.0, color: matches text color
  //            Button stays same size (no layout shift)
  //            Disable interactions while loading
  //            Haptic: none
  //
  // SUCCESS:
  //            Background flash: success color at 15% for 300ms, then revert
  //            Icon: animated checkmark (scale in 200ms, curveSpring)
  //            Haptic: HapticFeedback.mediumImpact()
  //            Auto-revert to default after 1500ms
  //
  // ERROR:
  //            Background flash: danger color at 15% for 300ms, then revert
  //            Shake: 3 cycles, 4px horizontal, 300ms total, curveSymmetric
  //            Haptic: HapticFeedback.heavyImpact()
  //            Auto-revert to default after 1500ms

  // ── Shake animation helper ─────────────────────────────────
  static const double shakeAmplitude = 4.0;
  static const int shakeCycles = 3;
  static const Duration shakeDuration = Duration(milliseconds: 300);

  // ── Opacity values ─────────────────────────────────────────
  static const double disabledOpacity = 0.38;
  static const double hoverOverlayOpacity = 0.04;
  static const double pressedOverlayOpacity = 0.08;
  static const double flashOverlayOpacity = 0.15;

  // ── Focus ring ─────────────────────────────────────────────
  static const double focusRingWidth = 2.0;
  static const double focusRingOffset = 2.0;

  // ── Loading indicator ──────────────────────────────────────
  static const double loadingSize = 18.0;
  static const double loadingStrokeWidth = 2.0;

  // ── Success/Error revert ───────────────────────────────────
  static const Duration flashDuration = Duration(milliseconds: 300);
  static const Duration revertDelay = Duration(milliseconds: 1500);
}
```

### Code
Create the file at `lib/core/theme/app_states.dart`.

### Verify
- `flutter analyze` clean
- The file is constants/documentation only at this stage — widgets are updated in Phase 1

### Figma Sync
- In Figma, create a component page "Interactive States"
- Design a button component with 8 state variants
- Design a text field with 5 state variants (default, focus, filled, error, disabled)
- Use Figma's interactive components feature to prototype state transitions
- Use `mcp__Figma__get_variable_defs` to check if variables already exist, then create/update

---

## TASK 0.3: SHADOW & ELEVATION SCALE

### Explore
```
@Pixel audit — Check all BoxDecoration shadows across the codebase. List every unique shadow value.
```

**Known inconsistencies:**
- TaskCard: blur=20, offset=(0,8), alpha=0.3/0.1
- TenderCard: blur=12, offset=(0,4), alpha=0.2/0.05
- BookingCard: blur=10, offset=(0,4), alpha=0.05
- BookingTaskCard: blur=12, offset=(0,4), alpha=0.2/0.05
- DashboardOfferCard: blur=8, offset=(0,2), alpha=0.05

### Design — Elevation System

Add to existing `lib/core/theme/app_decorations.dart`:

```dart
// ── Elevation Scale ──────────────────────────────────────────
// 5 levels. Light mode uses black alpha. Dark mode uses lighter alpha.
//
// Level 0 — FLAT:       No shadow. For items in a scrolling list at rest.
// Level 1 — RESTING:    blur=4,  offset=(0,1). Default for cards.
// Level 2 — RAISED:     blur=8,  offset=(0,2). Hovered/focused cards.
// Level 3 — FLOATING:   blur=16, offset=(0,4). Modals, FAB, dragging.
// Level 4 — DRAMATIC:   blur=24, offset=(0,8). Popovers, dropdowns.

static List<BoxShadow> elevation(int level, {bool isDark = false}) {
  final double alpha = isDark ? 0.3 : 1.0; // dark mode shadows are less visible
  switch (level) {
    case 0: return [];
    case 1: return [BoxShadow(color: Color.fromRGBO(0,0,0, 0.06 * alpha), blurRadius: 4, offset: Offset(0, 1))];
    case 2: return [BoxShadow(color: Color.fromRGBO(0,0,0, 0.08 * alpha), blurRadius: 8, offset: Offset(0, 2))];
    case 3: return [BoxShadow(color: Color.fromRGBO(0,0,0, 0.12 * alpha), blurRadius: 16, offset: Offset(0, 4))];
    case 4: return [BoxShadow(color: Color.fromRGBO(0,0,0, 0.16 * alpha), blurRadius: 24, offset: Offset(0, 8))];
    default: return elevation(1, isDark: isDark);
  }
}
```

### Verify
- `flutter analyze` clean
- Visual: create a test row of 5 cards at levels 0-4 to validate visual progression

### Figma Sync
- Create "Elevation" frame in Figma with 5 sample cards showing each shadow level
- Match shadow values exactly (blur, offset, opacity)
- Save as Figma styles for reuse

---

## TASK 0.4: TYPOGRAPHY LINE HEIGHTS & LETTER SPACING

### Explore
```
@Pixel typeset — Audit current typography. Check line heights, letter spacing, and readability across all screen contexts.
```

### Design — Updated Values

Update `lib/core/theme/app_typography.dart`:

```
// CHANGES ONLY (existing size/weight stays):
//
// logo:       height: 1.0,  letterSpacing: -1.0   (tight display)
// h1:         height: 1.1,  letterSpacing: -0.5
// h2:         height: 1.15, letterSpacing: -0.5
// h3:         height: 1.2,  letterSpacing: -0.3
// h4:         height: 1.2,  letterSpacing: -0.2
// h5:         height: 1.25, letterSpacing: 0
// subtitle:   height: 1.3,  letterSpacing: 0
// h6:         height: 1.25, letterSpacing: 0
// bodyLarge:  height: 1.5,  letterSpacing: 0
// bodyMedium: height: 1.5,  letterSpacing: 0
// bodySmall:  height: 1.4,  letterSpacing: 0.1
// caption:    height: 1.3,  letterSpacing: 0.2
// captionBold:height: 1.3,  letterSpacing: 0.2
// overline:   height: 1.3,  letterSpacing: 1.5    (ALL CAPS readability)
// micro:      height: 1.2,  letterSpacing: 0.3
```

### Verify
- `flutter analyze` clean
- Visual: check login screen, chat screen, task details — body text should feel more breathable
- Check no text gets clipped by new line heights

### Figma Sync
- Create "Typography Scale" frame in Figma
- Show each style name, size, weight, line height, letter spacing as a sample text block
- Save as Figma text styles

---

## TASK 0.5: SEMANTIC COLOR EXPANSION

### Explore
```
@Pixel colorize — Audit the current color palette. Check contrast ratios for all text/background combos. Identify missing semantic colors.
```

### Design — New Tokens

Add to `AppColorScheme` in `lib/core/theme/app_colors.dart`:

```
// ── Semantic Status Colors ────────────────────
//                        LIGHT MODE          DARK MODE
// success:              #2E7D32 (green-700)  #66BB6A (green-400)
// successMuted:         #E8F5E9 (green-50)   #1B3D1F (custom dark)
// warning:              #F57F17 (amber-900)   #FFB300 (amber-600)
// warningMuted:         #FFF8E1 (amber-50)    #3D2E00 (custom dark)
// info:                 #1565C0 (blue-800)    #42A5F5 (blue-400)
// infoMuted:            #E3F2FD (blue-50)     #0D2137 (custom dark)
// danger:               #C62828 (red-800)     #EF5350 (red-400)
// dangerMuted:          #FFEBEE (red-50)      #3D1111 (custom dark)
//
// ── Interactive State Colors ─────────────────
// hoverOverlay:         primary at 4%
// pressedOverlay:       primary at 8%
// focusRing:            primary (full)
// disabledBg:           grey at 8%
// disabledText:         grey at 38%
```

### Verify
- `flutter analyze` clean
- Contrast check: every text color on every background color >= 4.5:1 ratio
- Dark mode: all semantic colors visible and distinguishable

### Figma Sync
- Expand Figma color library with semantic tokens
- Create color swatches showing light + dark variants
- Use `mcp__Figma__get_variable_defs` to sync color variables
- Show contrast ratios next to each combo

---

## TASK 0.6: COMPONENT THEMES

### Explore
```
@Pixel normalize — Audit ThemeData in app_theme.dart. List which Material components have custom themes vs using defaults.
```

### Design — Added Component Themes

Update `lib/core/theme/app_theme.dart`:

```
// ADD to ThemeData:
//
// cardTheme: CardTheme(
//   elevation: 0,
//   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.r16)),
//   color: colorScheme.cardBackground,
//   margin: EdgeInsets.zero,
// ),
//
// dialogTheme: DialogTheme(
//   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.r24)),
//   backgroundColor: colorScheme.cardBackground,
//   elevation: 0,
// ),
//
// bottomSheetTheme: BottomSheetThemeData(
//   shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.r24))),
//   backgroundColor: colorScheme.cardBackground,
//   elevation: 0,
//   showDragHandle: true,
//   dragHandleColor: colorScheme.outline,
//   dragHandleSize: Size(32, 4),
// ),
//
// chipTheme: ChipThemeData(
//   shape: StadiumBorder(),
//   backgroundColor: Colors.transparent,
//   side: BorderSide(color: colorScheme.outline, width: 0.5),
//   labelStyle: AppTypography.captionBold,
//   padding: EdgeInsets.symmetric(horizontal: AppDimens.p12, vertical: AppDimens.p4),
// ),
//
// dividerTheme: DividerThemeData(
//   color: colorScheme.outline,
//   thickness: 0.5,
//   space: 0,
// ),
//
// snackBarTheme: SnackBarThemeData(
//   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.r12)),
//   behavior: SnackBarBehavior.floating,
//   backgroundColor: colorScheme.text,
//   contentTextStyle: AppTypography.bodySmall.copyWith(color: colorScheme.phoneBackground),
// ),
//
// tabBarTheme: TabBarTheme(
//   labelColor: AppColors.teal,
//   unselectedLabelColor: colorScheme.textSecondary,
//   indicatorSize: TabBarIndicatorSize.label,
//   indicator: UnderlineTabIndicator(
//     borderSide: BorderSide(color: AppColors.teal, width: 3),
//     borderRadius: BorderRadius.circular(2),
//   ),
//   labelStyle: AppTypography.captionBold,
//   unselectedLabelStyle: AppTypography.caption,
// ),
```

### Verify
- `flutter analyze` clean
- Visual check: open a dialog, bottom sheet, tab bar, chip — all should use themed values without per-widget overrides

### Figma Sync
- Create component frames: Button, TextField, Card, Dialog, BottomSheet, Chip, Badge, TabBar
- Each shows default + dark mode variant
- Map to code via `mcp__Figma__add_code_connect_map` once components exist in Figma

---

## FIGMA WORKFLOW FOR PHASE 0

### Strategy: Code-First, Figma-Second for Tokens

Since the app already exists in code, the most efficient workflow is:

1. **Define tokens in code** (this phase) — code is the source of truth
2. **Export to Figma as variables** — colors, spacing, typography become Figma variables
3. **Build Figma components** that reference those variables
4. **Use Code Connect** to map Figma nodes → Flutter widget paths

### Figma File Structure

```
SLine Design System (Figma file)
├── Page: Design Decisions         ← from .impeccable.md
├── Page: Color Tokens             ← from Task 0.5
├── Page: Typography Scale         ← from Task 0.4
├── Page: Spacing & Elevation      ← from Tasks 0.3
├── Page: Motion Tokens            ← from Task 0.1
├── Page: Interactive States       ← from Task 0.2
├── Page: Component Library        ← from Task 0.6 (base components)
└── Page: Screen Library           ← filled in Phases 1-15
```

### MCP Tools Usage

```
mcp__Figma__create_design_system_rules   → Generate rules from codebase
mcp__Figma__get_variable_defs            → Read existing Figma variables (if any)
mcp__Figma__get_screenshot               → Capture current Figma state for comparison
mcp__Figma__add_code_connect_map         → Link Figma component → Flutter widget
mcp__Figma__get_code_connect_map         → Verify existing connections
mcp__Figma__get_design_context           → Pull design specs from Figma into code
```

---

## PHASE 0 COMPLETION CHECKLIST

- [ ] `.impeccable.md` exists with design context
- [ ] `lib/core/theme/app_motion.dart` created with all tokens
- [ ] `lib/core/theme/app_states.dart` created with all state definitions
- [ ] `lib/core/theme/app_decorations.dart` updated with elevation scale
- [ ] `lib/core/theme/app_typography.dart` updated with line heights + letter spacing
- [ ] `lib/core/theme/app_colors.dart` updated with semantic colors
- [ ] `lib/core/theme/app_theme.dart` updated with component themes
- [ ] `flutter analyze` passes clean
- [ ] Figma file created with token pages
- [ ] All token values match between code and Figma

---

## SKILLS EXPLORED IN THIS PHASE

| Skill | Used For | When |
|-------|----------|------|
| `teach-impeccable` | Design context setup | Step 0 (first thing) |
| `animate` | Audit existing animations | Task 0.1 |
| `harden` | Audit interactive states | Task 0.2 |
| `normalize` | Consolidate shadows, themes | Tasks 0.3, 0.6 |
| `typeset` | Audit + fix typography | Task 0.4 |
| `colorize` | Expand color system | Task 0.5 |
| `audit` | Verify contrast ratios | Task 0.5 |

---

## TRANSITION TO PHASE 1

After Phase 0 is complete:
- All theme tokens exist in code
- Figma has a matching token library
- The design language is defined
- Phase 1 takes these tokens and applies them to the 14 core widgets
- Every Phase 1 widget change will reference `AppMotion.*`, `AppInteractionStates.*`, `AppDecorations.elevation()`, and the new semantic colors

**Next file:** `.TODO/PHASE_1_EXECUTION.md` (created when Phase 0 is complete or when you're ready to plan Phase 1)
