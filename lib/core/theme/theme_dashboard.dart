// ignore: dangling_library_doc_comments
/// Theme System Dashboard
///
/// This file serves as a comprehensive reference for all theme values in the SLine app.
/// It documents colors, typography, dimensions, and decorations in one place for easy
/// reference and maintenance.
///
/// **Usage:** This is a reference/documentation file. Use the actual theme classes
/// (`AppColors`, `AppTypography`, `AppDimens`, `AppDecorations`) in your code.
///
/// **Last Updated:** 2024

// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
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

  /// **Glassmorphism Effects** (from `AppDecorations`)
  ///
  /// Use `AppDecorations.glassBoxDecoration()` for glassmorphism cards:
  /// - Gradient background with transparency
  /// - Subtle border
  /// - Multi-layered shadow
  /// - Backdrop blur effect

  /// **Common Decorations:**
  ///
  /// - `AppDecorations.glassBoxDecoration()` - General glassmorphism
  /// - `AppDecorations.bottomNavBarDecoration()` - Bottom navigation
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
  /// **Card:**
  /// ```dart
  /// Container(
  ///   padding: EdgeInsets.all(AppDimens.p16),
  ///   decoration: AppDecorations.glassBoxDecoration(
  ///     colorScheme: context.colorScheme,
  ///     borderRadius: BorderRadius.circular(AppDimens.r20),
  ///   ),
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
  /// - `lib/core/theme/app_dimens.dart` - Spacing and dimensions
  /// - `lib/core/theme/app_decorations.dart` - Box decorations
  /// - `lib/core/theme/app_theme.dart` - Material 3 theme data
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
}
