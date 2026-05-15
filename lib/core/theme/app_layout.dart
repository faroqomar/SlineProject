/// Centralized layout tokens for the SLine app.
///
/// WHAT: Every structural measurement in the app — padding, sizes, heights,
/// spacing rhythms, avatar dimensions, card proportions, button heights,
/// icon sizes, thumbnail dimensions, navigation constants, and border widths.
///
/// WHY: Separates DESIGN (structure/proportions) from THEME (colors/fonts/motion).
/// To redesign the app's layout, change THIS file. To retheme, change
/// `app_colors.dart`, `app_typography.dart`, or `app_motion.dart`.
/// Components consume both Layer 1 (Theme) and Layer 2 (Layout) but own neither.
///
/// THREE-LAYER ARCHITECTURE:
///   Layer 1 — THEME: AppColors, AppTypography, AppMotion, AppDecorations, AppStates
///   Layer 2 — LAYOUT: AppLayout (semantic structure) + AppDimens (raw primitives)
///   Layer 3 — COMPONENTS: Widgets consume Layer 1 + Layer 2, own neither
///
/// RELATIONSHIP TO AppDimens:
///   - `AppDimens` = raw spacing/radius primitives (p0–p140, r2–r50, iconSize*)
///   - `AppLayout` = semantic structural tokens with named intent
///   - Both are Layer 2. `AppLayout` provides meaning, `AppDimens` provides the scale.
///   - There is NO overlap: icon sizes 16/24/32 live in `AppDimens` only.
///   - `AppLayout` adds only icon sizes that `AppDimens` does not have (12, 20, 48).
///
/// MIGRATION STRATEGY:
///   1. Token values match the CURRENT codebase exactly (zero visual change).
///   2. Each screen redesign (Phases 1–16) replaces hardcoded values with tokens.
///   3. After all phases: changing layout = editing this file only.
class AppLayout {
  AppLayout._();

  // ── Card Dimensions ──────────────────────────────────────────────────

  /// Standard card content padding (all sides).
  /// Source: app_card.dart (uses AppDimens.p16 = 16.0).
  static const double cardPadding = 16.0;

  /// Compact card content padding for dense lists.
  /// Source: common pattern in booking/task cards.
  static const double cardPaddingCompact = 12.0;

  /// Card inner section spacing (between title row and meta row, etc).
  /// Source: common card internal gap pattern.
  static const double cardSectionSpacing = 8.0;

  /// Card gradient/image header height (when present).
  /// Source: task/booking card header areas.
  static const double cardHeaderHeight = 60.0;

  /// Standard card border width for solid surface cards.
  /// Source: app_card_container.dart:59 — `Border.all(..., width: 1)`.
  static const double cardBorderWidth = 1.0;

  // ── Avatar Sizes ─────────────────────────────────────────────────────

  /// Tiny avatar for inline mentions, comment threads (24px diameter, radius 12).
  static const double avatarTiny = 24.0;

  /// Small avatar for list tiles, cards (36px diameter, radius 18).
  static const double avatarSmall = 36.0;

  /// Default avatar size used when no size is specified (40px diameter, radius 20).
  /// Source: signed_avatar.dart:73 — default `radius = 20`.
  static const double avatarDefault = 40.0;

  /// Medium avatar for conversation tiles, card headers (44px diameter, radius 22).
  static const double avatarMedium = 44.0;

  /// Large avatar for profile headers, detail screens (64px diameter, radius 32).
  static const double avatarLarge = 64.0;

  /// Hero avatar for profile screen top section (80px diameter, radius 40).
  static const double avatarHero = 80.0;

  // ── Button Heights ───────────────────────────────────────────────────

  /// Standard button height (primary actions — AppButton default).
  /// Source: app_button.dart:248 — `widget.height ?? AppDimens.p54`.
  static const double buttonHeight = 54.0;

  /// Compact button height (styled/secondary buttons).
  /// Source: app_styled_button.dart:46 — `height = 48`.
  static const double buttonHeightCompact = 48.0;

  /// Small button height for inline or tertiary actions.
  static const double buttonHeightSmall = 36.0;

  /// Circle icon button visual diameter (the visible circle).
  /// Source: circle_icon_button.dart:33 — `size = 40`.
  static const double circleButtonVisualSize = 40.0;

  /// WCAG minimum touch target size (48x48dp).
  /// Source: circle_icon_button.dart:69 — `SizedBox(width: 48, height: 48)`.
  static const double minTouchTarget = 48.0;

  /// Floating action button size.
  /// Source: main_navigation_screen.dart:284-285 — `width: 56, height: 56`.
  static const double fabSize = 56.0;

  // ── Spacing Rhythm ───────────────────────────────────────────────────
  // Semantic spacing rhythm for layout flow.
  // For raw spacing primitives (p0–p140), see `AppDimens`.

  /// Tight spacing within a single component (icon-to-text, badge gap).
  static const double spacingTight = 4.0;

  /// Standard spacing between related elements.
  static const double spacingStandard = 8.0;

  /// Section spacing between distinct groups.
  static const double spacingSection = 16.0;

  /// Screen-level vertical spacing between major sections.
  static const double spacingScreen = 24.0;

  /// Large gap for visual breathing room.
  static const double spacingLarge = 32.0;

  /// Screen-level horizontal margin.
  /// Source: .impeccable.md — "Screen margins: 24px horizontal".
  static const double screenHorizontalMargin = 24.0;

  // ── Content Widths ───────────────────────────────────────────────────

  /// Max width for form content (login, signup, settings).
  static const double formMaxWidth = 400.0;

  /// Max width for a card in grid view.
  static const double cardMaxWidth = 600.0;

  // ── Icon Sizes ───────────────────────────────────────────────────────
  // Semantic icon sizes NOT covered by `AppDimens.iconSize*`.
  // For 16px use `AppDimens.iconSizeSmall`.
  // For 24px use `AppDimens.iconSizeMedium`.
  // For 32px use `AppDimens.iconSizeLarge`.

  /// Tiny icon for status indicators, badges, chips (12px).
  /// NOT in AppDimens.
  static const double iconTiny = 12.0;

  /// Standard icon for buttons, list tiles (20px).
  /// NOT in AppDimens. Source: circle_icon_button.dart:34 default iconSize.
  static const double iconStandard = 20.0;

  /// Feature icon for empty states, auth screens (48px).
  /// NOT in AppDimens.
  static const double iconFeature = 48.0;

  // ── Thumbnail Sizes ──────────────────────────────────────────────────

  /// Task card thumbnail (compact inline).
  static const double thumbnailSmall = 60.0;

  /// Booking card thumbnail.
  static const double thumbnailMedium = 80.0;

  // ── Navigation ───────────────────────────────────────────────────────

  /// Bottom navigation bar total height.
  /// Source: custom_bottom_nav_bar.dart:110 — `height: 70`.
  /// NOTE: Master Plan suggested 64, but actual is 70.
  static const double bottomNavHeight = 70.0;

  /// Stable bottom inset for tabbed screens that sit above the app nav bar.
  static const double tabViewBottomPadding = bottomNavHeight + spacingStandard;

  /// FAB bottom offset above the navigation bar.
  /// Source: main_navigation_screen.dart:265 — `bottom: 100`.
  static const double fabBottomOffset = 100.0;

  /// Status bar / indicator height.
  static const double statusIndicatorHeight = 40.0;

  // ── Stagger Intervals ────────────────────────────────────────────────

  /// Number of stagger elements for auth (login) screens.
  static const int authStaggerCount = 5;

  /// Number of stagger elements for signup (more fields).
  static const int signupStaggerCount = 6;

  // ── List / Tile ──────────────────────────────────────────────────────

  /// Minimum height for standard list tiles.
  static const double listItemMinHeight = 56.0;

  /// Horizontal padding for list items.
  static const double listItemPadding = 16.0;

  /// Standard divider indent in lists.
  static const double dividerIndent = 16.0;

  // ── Border Widths ────────────────────────────────────────────────────

  /// Standard border width for cards and containers (1px).
  /// Source: app_card_container.dart:59.
  static const double borderStandard = 1.0;

  /// Thick border for emphasis (1.5px).
  /// Source: custom_bottom_nav_bar.dart:282.
  static const double borderThick = 1.5;

  /// Avatar border width (2px).
  /// Source: signed_avatar.dart:77 — default `borderWidth = 2`.
  static const double borderAvatar = 2.0;
}
