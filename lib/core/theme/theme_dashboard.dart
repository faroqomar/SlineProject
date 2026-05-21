/// Theme System Dashboard
///
/// This file serves as a comprehensive reference for all theme values in the SLine app.
/// It documents colors, typography, dimensions, and decorations in one place for easy
/// reference and maintenance.
///
/// **Usage:** This is a reference/documentation file. Use the actual theme classes
/// (`AppColors`, `AppTypography`, `AppDimens`, `AppDecorations`) in your code.
///
/// **Last Updated:** 2026-04-08 (Phase 0.7 — Layout Tokens)
library;

// These imports are intentionally kept because this file is a developer-facing
// theme reference, not executable theme logic.
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_typography.dart';

/// Theme Dashboard - Comprehensive Reference
///
/// This class provides static documentation and quick reference for all theme values.
/// It does NOT provide actual theme values - use the respective theme classes instead.
class ThemeDashboard {
  ThemeDashboard._(); // Private constructor

  // ============================================================================
  // COLOR SYSTEM
  // ============================================================================

  /// **Primary Colors** (from `AppColors`)
  ///
  /// - `AppColors.teal` - #146068 - Primary brand color
  /// - `AppColors.lightTeal` - #93ccce - Secondary teal
  /// - `AppColors.gold` - #f3bb19 - Accent color
  /// - `AppColors.lightRed` - #f49d9d - Hot badges, errors

  /// **Neutral Colors** (from `AppColors`)
  ///
  /// - `AppColors.almostBlack` - #0c0c0c - Dark text, dark backgrounds
  /// - `AppColors.offWhite` - #f4f3f1 - Light backgrounds
  /// - `AppColors.white` - #ffffff - Pure white
  /// - `AppColors.mediumGreyBlue` - #9dbabb - Secondary text (dark mode)
  /// - `AppColors.mediumGrey` - #a9a8a7 - Secondary text (light mode)
  /// - `AppColors.darkerGrey` - #6b6b6b - Tertiary text (light mode)

  /// **Color Usage Contexts**
  ///
  /// **Primary (Teal #146068):**
  /// - Primary buttons
  /// - Active states
  /// - Focus borders
  /// - Brand elements
  ///
  /// **Accent (Gold #f3bb19):**
  /// - Hot badges
  /// - Highlights
  /// - Special indicators
  ///
  /// **Error (Light Red #f49d9d):**
  /// - Error states
  /// - Hot badges
  /// - Warning indicators

  // ============================================================================
  // TYPOGRAPHY SYSTEM
  // ============================================================================

  /// **Font Family:** Plus Jakarta Sans (via Google Fonts)
  ///
  /// **Typography Scale** (from `AppTypography`):
  ///
  /// | Style | Size | Weight | Usage |
  /// |-------|------|--------|-------|
  /// | `logo` | 36px | w900 | Logo text |
  /// | `h1` | 32px | w900 | Main headings |
  /// | `h2` | 28px | w900 | Section headings |
  /// | `h3` | 22px | w800 | Subsection headings |
  /// | `h4` | 20px | w800 | Card titles |
  /// | `h5` | 18px | w700 | Modal titles |
  /// | `subtitle` | 17px | w700 | Modal subtitles |
  /// | `h6` | 16px | w800 | Small headings |
  /// | `bodyLarge` | 15px | w500 | Body text (large) |
  /// | `bodyMedium` | 14px | normal | Body text (standard) |
  /// | `bodySmall` | 13px | w500 | Body text (small) |
  /// | `caption` | 12px | normal | Captions |
  /// | `captionBold` | 12px | w700 | Bold captions |
  /// | `overline` | 11px | w600 | Overlines |
  /// | `micro` | 10px | w500 | Micro text |

  /// **Typography Usage Examples:**
  ///
  /// ```dart
  /// // Headings
  /// Text('Title', style: AppTypography.h1)
  /// Text('Subtitle', style: AppTypography.h4)
  ///
  /// // Body text
  /// Text('Description', style: AppTypography.bodyMedium)
  ///
  /// // Captions
  /// Text('Time', style: AppTypography.caption)
  /// ```

  // ============================================================================
  // DIMENSION SYSTEM
  // ============================================================================

  /// **Spacing/Padding Scale** (from `AppDimens`)
  ///
  /// Common values:
  /// - `p0` = 0.0
  /// - `p2` = 2.0
  /// - `p4` = 4.0
  /// - `p6` = 6.0
  /// - `p8` = 8.0
  /// - `p10` = 10.0
  /// - `p12` = 12.0
  /// - `p14` = 14.0
  /// - `p16` = 16.0
  /// - `p18` = 18.0
  /// - `p20` = 20.0
  /// - `p22` = 22.0 (icon size)
  /// - `p24` = 24.0
  /// - `p28` = 28.0
  /// - `p32` = 32.0
  /// - `p40` = 40.0
  /// - `p48` = 48.0
  /// - `p50` = 50.0
  /// - `p52` = 52.0 (avatar size)
  /// - `p54` = 54.0
  /// - `p60` = 60.0
  /// - `p70` = 70.0
  /// - `p80` = 80.0
  /// - `p100` = 100.0

  /// **Border Radius Scale** (from `AppDimens`)
  ///
  /// Common values:
  /// - `r4` = 4.0
  /// - `r8` = 8.0
  /// - `r10` = 10.0 (small buttons)
  /// - `r12` = 12.0 (chips, small buttons)
  /// - `r14` = 14.0 (inputs, buttons)
  /// - `r16` = 16.0 (inputs, cards)
  /// - `r18` = 18.0 (avatars, buttons)
  /// - `r20` = 20.0 (cards)
  /// - `r24` = 24.0 (large cards)
  /// - `r30` = 30.0 (modals)
  /// - `r50` = 50.0 (phone mockup)

  /// **Icon Sizes** (from `AppDimens`)
  ///
  /// - `iconSizeSmall` = 16.0
  /// - `iconSizeMedium` = 24.0
  /// - `iconSizeLarge` = 32.0

  /// **Common Component Sizes** (from design):
  ///
  /// **Inputs:**
  /// - Standard input height: 46px (`h-[46px]`)
  /// - Auth input height: 52px (`h-[52px]`)
  /// - Search input height: 48px (`h-[48px]`)
  ///
  /// **Buttons:**
  /// - Standard button height: 50px (`h-[50px]`)
  /// - Auth button height: 54px (`h-[54px]`)
  /// - Small button height: 36px (`h-[36px]`)
  ///
  /// **Avatars:**
  /// - Standard avatar: 52x52px (`w-[52px] h-[52px]`)
  /// - Large avatar: 80x80px (`w-[80px] h-[80px]`)
  ///
  /// **Icon Buttons:**
  /// - Standard: 46x46px (`w-[46px] h-[46px]`)
  /// - Small: 38x38px (`w-[38px] h-[38px]`)
  /// - Large: 56x56px (`w-[56px] h-[56px]`)

  // ============================================================================
  // COLOR SCHEME (Light & Dark)
  // ============================================================================

  /// **Light Mode Colors** (from `AppColorScheme.light()`)
  ///
  /// - Background: `#f4f3f1` (offWhite)
  /// - Text: `#0c0c0c` (almostBlack)
  /// - Text Secondary: `#a9a8a7` (mediumGrey)
  /// - Text Tertiary: `#6b6b6b` (darkerGrey)
  /// - Card Background: `#ffffff` (white)
  /// - Input Background: `#ffffff` (white)
  /// - Primary: `#146068` (teal)
  /// - Accent: `#f3bb19` (gold)

  /// **Dark Mode Colors** (from `AppColorScheme.dark()`)
  ///
  /// - Background: `#0c0c0c` (almostBlack)
  /// - Text: `#f4f3f1` (offWhite)
  /// - Text Secondary: `#9dbabb` (mediumGreyBlue)
  /// - Text Tertiary: `#a9a8a7` (mediumGrey)
  /// - Card Background: `rgba(244, 243, 241, 0.08)` (offWhiteTransparent8)
  /// - Input Background: `rgba(244, 243, 241, 0.10)` (offWhiteTransparent10)
  /// - Primary: `#146068` (teal)
  /// - Accent: `#f3bb19` (gold)

  // ============================================================================
  // DECORATIONS
  // ============================================================================

  /// **NO GLASS POLICY — Mandatory**
  ///
  /// Glass effects (BackdropFilter, frosted blur, semi-transparent gradients)
  /// are BANNED from the SLine design system. They are performance-heavy,
  /// dated in 2026, and harm readability. See `.impeccable.md` for full rationale.
  ///
  /// **Use instead:**
  /// - Solid `colorScheme.cardBackground` for surfaces
  /// - `colorScheme.cardBorder` for subtle borders
  /// - `AppDecorations.elevation(level)` for depth/shadow
  ///
  /// **Legacy glass widgets** have been migrated to solid-surface equivalents
  /// in Phase 1: `GlassContainer` → `AppCardContainer`, `GlassCard` → `AppCard`,
  /// `GlassButton` → `AppStyledButton`. All `BackdropFilter` usage removed.

  /// **Common Decorations:**
  ///
  /// - `AppDecorations.elevation(1)` - Resting card shadow (blur=4, offset=1)
  /// - `AppDecorations.elevation(2)` - Raised/hovered card shadow (blur=8, offset=2)
  /// - `AppDecorations.elevation(3)` - Floating modal/FAB shadow (blur=16, offset=4)
  /// - `AppDecorations.inputFieldDecoration()` - Input fields
  /// - `AppDecorations.hotBadgeDecoration()` - Hot badges
  /// - `AppDecorations.authorInitialsDecoration()` - Avatar circles

  // ============================================================================
  // USAGE PATTERNS
  // ============================================================================

  /// **Accessing Theme in Widgets:**
  ///
  /// ```dart
  /// // Get color scheme
  /// final colorScheme = context.colorScheme;
  /// final textColor = colorScheme.text;
  ///
  /// // Use typography
  /// Text('Hello', style: AppTypography.h1)
  ///
  /// // Use dimensions
  /// Padding(padding: EdgeInsets.all(AppDimens.p16))
  /// BorderRadius.circular(AppDimens.r16)
  ///
  /// // Use colors directly
  /// Container(color: AppColors.teal)
  /// ```

  /// **Common Patterns:**
  ///
  /// **Card (solid surface — NO GLASS per .impeccable.md):**
  /// ```dart
  /// AppCardContainer(
  ///   padding: EdgeInsets.all(AppLayout.cardPadding),
  ///   elevation: 1,
  ///   child: Text('Content', style: AppTypography.bodyMedium),
  /// )
  /// ```
  ///
  /// **Button:**
  /// ```dart
  /// Container(
  ///   height: 50,
  ///   padding: EdgeInsets.symmetric(
  ///     horizontal: AppDimens.p24,
  ///     vertical: AppDimens.p16,
  ///   ),
  ///   decoration: BoxDecoration(
  ///     color: AppColors.teal,
  ///     borderRadius: BorderRadius.circular(AppDimens.r14),
  ///   ),
  ///   child: Text('Button', style: AppTypography.bodyMedium),
  /// )
  /// ```
  ///
  /// **Input:**
  /// ```dart
  /// Container(
  ///   height: 46,
  ///   decoration: AppDecorations.inputFieldDecoration(
  ///     colorScheme: context.colorScheme,
  ///     borderRadius: BorderRadius.circular(AppDimens.r14),
  ///   ),
  ///   child: TextField(...),
  /// )
  /// ```

  // ============================================================================
  // DESIGN TOKENS MAPPING
  // ============================================================================

  /// **Design Token → Flutter Theme Mapping:**
  ///
  /// From `.TODO/New_Design/Common/Theme.ts`:
  ///
  /// | Design Token | Flutter Theme |
  /// |--------------|---------------|
  /// | `phoneBg` | `colorScheme.phoneBackground` |
  /// | `text` | `colorScheme.text` |
  /// | `textSecondary` | `colorScheme.textSecondary` |
  /// | `textTertiary` | `colorScheme.textTertiary` |
  /// | `cardBg` | `colorScheme.cardBackground` |
  /// | `cardBorder` | `colorScheme.cardBorder` |
  /// | `inputBg` | `colorScheme.inputBackground` |
  /// | `inputBorder` | `colorScheme.inputBorder` |
  /// | `headerBg` | `colorScheme.headerBackground` |
  /// | `headerBorder` | `colorScheme.headerBorder` |
  /// | `bottomNavBg` | `colorScheme.bottomNavBackground` |
  /// | `bottomNavBorder` | `colorScheme.bottomNavBorder` |
  /// | `bottomNavInactive` | `colorScheme.bottomNavInactive` |
  /// | `hotBadgeBg` | `colorScheme.hotBadgeBackground` |
  /// | `hotBadgeBorder` | `colorScheme.hotBadgeBorder` |

  // ============================================================================
  // ANTI-PATTERNS
  // ============================================================================

  /// **❌ NEVER DO THIS:**
  ///
  /// ```dart
  /// // Hardcoded colors
  /// Container(color: Color(0xFF146068))
  /// Text('Hello', style: TextStyle(color: Colors.black))
  ///
  /// // Hardcoded sizes
  /// Padding(padding: EdgeInsets.all(16))
  /// BorderRadius.circular(20)
  ///
  /// // Hardcoded fonts
  /// TextStyle(fontSize: 14, fontFamily: 'Arial')
  /// ```
  ///
  /// **✅ ALWAYS DO THIS:**
  ///
  /// ```dart
  /// // Use theme colors
  /// Container(color: AppColors.teal)
  /// Text('Hello', style: AppTypography.bodyMedium.copyWith(
  ///   color: context.colorScheme.text,
  /// ))
  ///
  /// // Use theme dimensions
  /// Padding(padding: EdgeInsets.all(AppDimens.p16))
  /// BorderRadius.circular(AppDimens.r20)
  ///
  /// // Use theme typography
  /// Text('Hello', style: AppTypography.bodyMedium)
  /// ```

  // ============================================================================
  // FILE REFERENCES
  // ============================================================================

  /// **Theme Files:**
  ///
  /// - `lib/core/theme/app_colors.dart` - Color palette and color schemes
  /// - `lib/core/theme/app_typography.dart` - Typography styles
  /// - `lib/core/theme/app_dimens.dart` - Spacing and dimensions (raw primitives)
  /// - `lib/core/theme/app_layout.dart` - Layout tokens (semantic structure) [Phase 0.7]
  /// - `lib/core/theme/app_decorations.dart` - Box decorations and elevation scale
  /// - `lib/core/theme/app_motion.dart` - Animation durations, curves, scales [Phase 0]
  /// - `lib/core/theme/app_states.dart` - Interaction state constants [Phase 0]
  /// - `lib/core/theme/app_theme.dart` - Material 3 theme data + component themes
  /// - `lib/core/theme/theme_dashboard.dart` - This file (reference)

  /// **Design Reference:**
  ///
  /// - `.TODO/New_Design/Common/Theme.ts` - Design theme tokens
  /// - `.TODO/New_Design/Theme.ts` - Design theme function

  // ============================================================================
  // QUICK REFERENCE
  // ============================================================================

  /// **Most Common Values:**
  ///
  /// **Colors:**
  /// - Primary: `AppColors.teal` or `context.colorScheme.primary`
  /// - Text: `context.colorScheme.text`
  /// - Background: `context.colorScheme.background`
  ///
  /// **Typography:**
  /// - Heading: `AppTypography.h1`, `h2`, `h3`, `h4`
  /// - Body: `AppTypography.bodyMedium`, `bodyLarge`, `bodySmall`
  /// - Caption: `AppTypography.caption`, `captionBold`
  ///
  /// **Spacing:**
  /// - Small: `AppDimens.p8`, `p12`
  /// - Medium: `AppDimens.p16`, `p20`, `p24`
  /// - Large: `AppDimens.p32`, `p40`
  ///
  /// **Border Radius:**
  /// - Small: `AppDimens.r8`, `r10`, `r12`
  /// - Medium: `AppDimens.r14`, `r16`, `r18`
  /// - Large: `AppDimens.r20`, `r24`, `r30`

  // ============================================================================
  // MOTION TOKENS (Phase 0 — AppMotion)
  // ============================================================================

  /// **Durations:**
  /// - micro: 100ms (ripples, toggles, icon swaps)
  /// - fast: 200ms (chips, badges, small state changes)
  /// - standard: 300ms (cards, sheets, tab switches)
  /// - slow: 400ms (entrance animations, expanding containers)
  /// - emphasis: 500ms (page transitions, hero animations)
  /// - dramatic: 800ms (count-up numbers, progress bars)
  /// - shimmer: 1500ms (skeleton loaders)
  ///
  /// **Curves:**
  /// - curveStandard: easeOutCubic (default for most interactions)
  /// - curveDecel: easeOutQuart (elements entering)
  /// - curveSharp: easeOutExpo (snappy — FAB, badge)
  /// - curveAccel: easeInCubic (elements leaving)
  /// - curveSymmetric: easeInOutCubic (expand/collapse)
  /// - curveSpring: Cubic(0.175, 0.885, 0.32, 1.075) (subtle overshoot)
  /// - curveSlideUp: Cubic(0.2, 0.8, 0.2, 1) (modals/sheets)
  ///
  /// **Scale Amounts:**
  /// - pressScale: 0.96 (button/card press-down)
  /// - hoverScale: 1.02 (desktop hover)
  /// - badgeEntrance: 1.15 (badge pop-in)
  /// - emphasize: 1.05 (attention draw)
  ///
  /// **Stagger Delays:**
  /// - staggerSmall: 30ms (list items)
  /// - staggerMedium: 50ms (grid cards)
  /// - staggerLarge: 100ms (major sections)
  ///
  /// **BANNED:** bounceIn, bounceOut, elasticIn, elasticOut, linear for visible animations.
  /// **HELPER:** `AppMotion.respectMotion(context, duration)` returns Duration.zero if reduced motion is preferred.

  // ============================================================================
  // INTERACTION STATES (Phase 0 — AppInteractionStates)
  // ============================================================================

  /// **8-State Model:** default, hover, focus, active/pressed, disabled, loading, success, error
  ///
  /// **Opacity Values:**
  /// - disabledOpacity: 0.38 (Material standard)
  /// - hoverOverlayOpacity: 0.04
  /// - pressedOverlayOpacity: 0.08
  /// - flashOverlayOpacity: 0.15
  ///
  /// **Focus Ring:** width=2.0, offset=2.0
  /// **Loading:** size=18.0, strokeWidth=2.0
  /// **Error Shake:** amplitude=4.0, cycles=3, duration=300ms
  /// **Flash:** flashDuration=300ms, revertDelay=1500ms
  ///
  /// **Haptic Methods:**
  /// - `hapticTap()` → lightImpact (button taps)
  /// - `hapticSelection()` → selectionClick (toggles, tabs)
  /// - `hapticSuccess()` → mediumImpact (successful actions)
  /// - `hapticHeavy()` → heavyImpact (destructive/error)

  // ============================================================================
  // ELEVATION SCALE (Phase 0 — AppDecorations.elevation)
  // ============================================================================

  /// **5-Level Shadow System:**
  ///
  /// | Level | Name     | Blur | Offset  | Alpha (light) | Use Case              |
  /// |-------|----------|------|---------|---------------|-----------------------|
  /// | 0     | Flat     | 0    | (0,0)   | 0             | Items at rest in list |
  /// | 1     | Resting  | 4    | (0,1)   | 0.06          | Default cards, tiles  |
  /// | 2     | Raised   | 8    | (0,2)   | 0.08          | Hovered/focused cards |
  /// | 3     | Floating | 16   | (0,4)   | 0.12          | Modals, FAB, dragged  |
  /// | 4     | Dramatic | 24   | (0,8)   | 0.16          | Popovers, dropdowns   |
  ///
  /// Dark mode multiplier: 0.3x alpha.
  /// Usage: `AppDecorations.elevation(1, isDark: colorScheme.isDark)`

  // ============================================================================
  // SEMANTIC COLORS (Phase 0 — AppColorScheme)
  // ============================================================================

  /// **Status Colors (light / dark):**
  ///
  /// | Token         | Light Mode | Dark Mode  | Use Case                     |
  /// |---------------|------------|------------|------------------------------|
  /// | success       | #2E7D32    | #66BB6A    | Completed, approved, online  |
  /// | successMuted  | #E8F5E9    | #1B3D1F    | Success backgrounds          |
  /// | warning       | #F57F17    | #FFB300    | Pending, expiring, attention |
  /// | warningMuted  | #FFF8E1    | #3D2E00    | Warning backgrounds          |
  /// | info          | #1565C0    | #42A5F5    | Informational, neutral       |
  /// | infoMuted     | #E3F2FD    | #0D2137    | Info backgrounds             |
  /// | danger        | #C62828    | #EF5350    | Errors, declined, urgent     |
  /// | dangerMuted   | #FFEBEE    | #3D1111    | Danger backgrounds           |
  ///
  /// **Interactive Colors:**
  /// - hoverOverlay: primary at 4% (light) / lightTeal at 6% (dark)
  /// - pressedOverlay: primary at 8% (light) / lightTeal at 10% (dark)
  /// - focusRing: teal (light) / lightTeal (dark)
  /// - disabledFill: black at 8% (light) / white at 8% (dark)

  // ============================================================================
  // COMPONENT THEMES (Phase 0 — AppTheme)
  // ============================================================================

  /// **Themed Components:**
  ///
  /// | Component    | Shape           | Background       | Elevation |
  /// |-------------|-----------------|------------------|-----------|
  /// | Card        | r16 rounded     | cardBackground   | 0         |
  /// | Dialog      | r24 rounded     | cardBackground   | 0         |
  /// | BottomSheet | r24 top rounded | cardBackground   | 0         |
  /// | Chip        | Stadium (pill)  | transparent      | 0         |
  /// | Divider     | —               | divider color    | 0         |
  /// | SnackBar    | r12 rounded     | text color       | floating  |
  /// | TabBar      | label underline | teal indicator   | 0         |
  ///
  /// BottomSheet has `showDragHandle: true` with 32x4 handle.
  /// Chip has 0.5px divider-color border.
  /// SnackBar has inverted colors (text bg, phoneBackground text).
  /// TabBar: label=captionBold, unselected=caption, teal indicator (width 3).

  // ============================================================================
  // TYPOGRAPHY LINE HEIGHTS (Phase 0 — AppTypography)
  // ============================================================================

  /// **Updated Line Heights:**
  ///
  /// | Style       | Size | Weight | Height | Letter Spacing | Category     |
  /// |-------------|------|--------|--------|----------------|-------------|
  /// | logo        | 36px | w900   | 1.0    | -0.5           | Display      |
  /// | h1          | 32px | w900   | 1.1    | -0.5           | Heading      |
  /// | h2          | 28px | w900   | 1.15   | -0.4           | Heading      |
  /// | h3          | 22px | w800   | 1.2    | -0.3           | Heading      |
  /// | h4          | 20px | w800   | 1.2    | -0.2           | Heading      |
  /// | h5          | 18px | w700   | 1.25   | —              | Heading      |
  /// | subtitle    | 17px | w700   | 1.3    | —              | Heading      |
  /// | h6          | 16px | w800   | 1.25   | —              | Heading      |
  /// | bodyLarge   | 15px | w500   | 1.5    | —              | Body         |
  /// | bodyMedium  | 14px | normal | 1.5    | —              | Body         |
  /// | bodySmall   | 13px | w500   | 1.4    | 0.1            | Body         |
  /// | caption     | 12px | normal | 1.3    | 0.2            | Utility      |
  /// | captionBold | 12px | w700   | 1.3    | 0.2            | Utility      |
  /// | overline    | 11px | w600   | 1.3    | 1.5            | Utility      |
  /// | micro       | 10px | w500   | 1.2    | 0.3            | Utility      |

  // ============================================================================
  // LAYOUT TOKENS (Phase 0.7 — AppLayout)
  // ============================================================================

  /// ## Three-Layer Architecture
  ///
  /// ```
  /// Layer 1 — THEME: AppColors, AppTypography, AppMotion, AppDecorations, AppStates
  /// Layer 2 — LAYOUT: AppLayout (semantic structure) + AppDimens (raw primitives)
  /// Layer 3 — COMPONENTS: Widgets consume Layer 1 + Layer 2, own neither
  /// ```
  ///
  /// ## AppDimens vs AppLayout
  ///
  /// - `AppDimens` = raw spacing/radius primitives (p0–p100, r4–r50, iconSize*)
  /// - `AppLayout` = semantic structural tokens with named intent
  /// - Both are Layer 2. No value overlap for icon sizes.
  ///
  /// ## Token Categories
  ///
  /// **Card Dimensions:**
  /// - cardPadding: 16.0 — standard card content padding
  /// - cardPaddingCompact: 12.0 — dense list padding
  /// - cardSectionSpacing: 8.0 — inner card section gap
  /// - cardHeaderHeight: 60.0 — card gradient/image header
  /// - cardBorderWidth: 1.0 — solid surface border width
  ///
  /// **Avatar Sizes (diameter):**
  /// - avatarTiny: 24.0, avatarSmall: 36.0, avatarDefault: 40.0
  /// - avatarMedium: 44.0, avatarLarge: 64.0, avatarHero: 80.0
  ///
  /// **Button Heights:**
  /// - buttonHeight: 54.0 (AppButton default)
  /// - buttonHeightCompact: 48.0 (AppStyledButton default)
  /// - buttonHeightSmall: 36.0, fabSize: 56.0
  /// - circleButtonVisualSize: 40.0, minTouchTarget: 48.0 (WCAG)
  ///
  /// **Spacing Rhythm (semantic, for raw use AppDimens):**
  /// - spacingTight: 4.0, spacingStandard: 8.0, spacingSection: 16.0
  /// - spacingScreen: 24.0, spacingLarge: 32.0, screenHorizontalMargin: 24.0
  ///
  /// **Icon Sizes (NO overlap with AppDimens.iconSize*):**
  /// - iconTiny: 12.0, iconStandard: 20.0, iconFeature: 48.0
  /// - For 16/24/32 use AppDimens.iconSizeSmall/Medium/Large
  ///
  /// **Navigation:**
  /// - bottomNavHeight: 70.0, fabBottomOffset: 100.0, statusIndicatorHeight: 40.0
  ///
  /// **Border Widths:**
  /// - borderStandard: 1.0, borderThick: 1.5, borderAvatar: 2.0
}
