/// Provides the Amber Dusk shared-widget adapter for Phase 1.
///
/// The adapter translates Open Design evidence into typed widget recipes so
/// shared widgets can adopt Amber Dusk without scattering raw visual values or
/// flipping the global app theme.
library;

import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_colors.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_spacing.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_typography.dart';

/// Namespace for shared-widget Amber Dusk recipes.
///
/// This class is intentionally token-only: it performs no IO, logging, or
/// context reads, so widgets can safely use it from build methods.
abstract final class AmberDuskWidgetTheme {
  const AmberDuskWidgetTheme._();

  /// Token registry exposed through `AmberDuskTokens.widgetTheme`.
  static const AmberDuskWidgetThemeTokens tokens = AmberDuskWidgetThemeTokens();

  /// Shared button minimum height from Open Design evidence.
  static const double buttonMinHeight = 46;

  /// Visual icon-button size from `.icon-button` evidence.
  static const double iconButtonSize = 42;

  /// Icon size from `.icon-button svg` evidence.
  static const double iconButtonIconSize = 20;

  /// Default task-card elevation level for Flutter shadow recipes.
  static const int taskCardElevationLevel = 2;

  /// Default panel-card elevation level for Flutter shadow recipes.
  static const int panelCardElevationLevel = 1;

  /// Task card top fill retained for compatibility with older token readers.
  static const Color taskCardTopFill = AmberDuskColors.surfaceRaised;

  /// Task card bottom fill retained for compatibility with older token readers.
  static const Color taskCardBottomFill = AmberDuskColors.surfaceRaised;

  /// Subtle task price and tag surface from `.price-pill` evidence.
  static const Color taskPillSurface = Color.fromRGBO(255, 255, 255, 0.035);

  /// Circular booking action surface from `.round-action` evidence.
  static const Color bookingRoundActionSurface = Color.fromRGBO(
    255,
    255,
    255,
    0.055,
  );

  /// Low-opacity action surface from `.ghost-action` and `.danger-action`.
  static const Color quietActionSurface = Color.fromRGBO(255, 255, 255, 0.045);

  /// Field fill from the Open Design input evidence.
  static const Color fieldSurface = Color.fromRGBO(0, 0, 0, 0.13);

  /// Primary status wash from the Open Design pill evidence.
  static const Color primaryStatusOverlay = Color.fromRGBO(212, 144, 106, 0.10);

  /// Urgent status wash from the Open Design pill evidence.
  static const Color urgentStatusOverlay = Color.fromRGBO(201, 105, 92, 0.12);

  /// Active bottom-nav icon capsule fill from the Open Design evidence.
  static const Color navActiveOverlay = Color.fromRGBO(212, 144, 106, 0.105);

  /// Hover overlay for Amber Dusk button ink states.
  static const Color buttonHoverOverlay = Color.fromRGBO(212, 144, 106, 0.08);

  /// Focus overlay for Amber Dusk button ink states.
  static const Color buttonFocusOverlay = Color.fromRGBO(212, 144, 106, 0.16);

  /// Warm initials fallback for avatars without a resolved image.
  static const Color avatarFallbackWarm = Color(0xFFB88E6A);

  /// Cool profile-photo fallback for media without a resolved image.
  static const Color profilePhotoFallbackCool = Color(0xFF4A7A8C);

  /// Button recipes for primary, ghost, and danger actions.
  static const AmberDuskButtonThemeTokens buttons =
      AmberDuskButtonThemeTokens();

  /// Input field recipe for labels, text, fill, padding, and radius.
  static const AmberDuskFieldThemeTokens fields = AmberDuskFieldThemeTokens();

  /// Icon-button recipe for circular app-bar and tool actions.
  static const AmberDuskIconButtonThemeTokens iconButtons =
      AmberDuskIconButtonThemeTokens();

  /// Status pill recipes for primary and urgent states.
  static const AmberDuskStatusPillThemeTokens statusPills =
      AmberDuskStatusPillThemeTokens();

  /// Bottom navigation recipe for the four-destination phone shell.
  static const AmberDuskBottomNavThemeTokens bottomNav =
      AmberDuskBottomNavThemeTokens();

  /// Card recipes for task, panel, and message surfaces.
  static const AmberDuskCardThemeTokens cards = AmberDuskCardThemeTokens();

  /// Media placeholder colors for avatars and profile photos.
  static const AmberDuskMediaThemeTokens media = AmberDuskMediaThemeTokens();

  /// Skeleton colors derived only from existing Amber Dusk surface steps.
  static const AmberDuskSkeletonThemeTokens skeleton =
      AmberDuskSkeletonThemeTokens();

  /// Light-mode skeleton colors using the derived light surface steps.
  static const AmberDuskSkeletonThemeTokens skeletonLight =
      _AmberDuskSkeletonThemeTokensLight();

  /// TabBar recipe used to remove teal-era active tab colors.
  static const AmberDuskTabThemeTokens tabs = AmberDuskTabThemeTokens();

  /// Light-mode TabBar recipe using the derived light color scheme.
  static const AmberDuskTabThemeTokens tabsLight =
      _AmberDuskTabThemeTokensLight();
}

/// Root registry for all shared-widget Amber Dusk recipes.
///
/// Consumers should enter through this type from `AmberDuskTokens.widgetTheme`
/// so the Phase 1 activation point stays explicit and easy to audit.
@immutable
class AmberDuskWidgetThemeTokens {
  /// Creates a stateless shared-widget token registry.
  const AmberDuskWidgetThemeTokens();

  /// Button recipes for primary, ghost, and danger actions.
  AmberDuskButtonThemeTokens get buttons => AmberDuskWidgetTheme.buttons;

  /// Input field recipe for Amber Dusk forms.
  AmberDuskFieldThemeTokens get fields => AmberDuskWidgetTheme.fields;

  /// Icon-button recipe for circular app-bar and tool actions.
  AmberDuskIconButtonThemeTokens get iconButtons =>
      AmberDuskWidgetTheme.iconButtons;

  /// Status pill recipes for metadata and urgent states.
  AmberDuskStatusPillThemeTokens get statusPills =>
      AmberDuskWidgetTheme.statusPills;

  /// Bottom navigation recipe for the four-destination shell.
  AmberDuskBottomNavThemeTokens get bottomNav => AmberDuskWidgetTheme.bottomNav;

  /// Card recipes for task, panel, and message components.
  AmberDuskCardThemeTokens get cards => AmberDuskWidgetTheme.cards;

  /// Media placeholder colors for avatars and profile photos.
  AmberDuskMediaThemeTokens get media => AmberDuskWidgetTheme.media;

  /// Skeleton colors derived from existing Amber Dusk surface tokens.
  AmberDuskSkeletonThemeTokens get skeleton => AmberDuskWidgetTheme.skeleton;

  /// TabBar recipe used by `AppTheme.tabBarTheme`.
  AmberDuskTabThemeTokens get tabs => AmberDuskWidgetTheme.tabs;
}

/// Light-mode widget theme that overrides skeleton and tab colors to match
/// the derived light Amber Dusk color scheme.
@immutable
final class AmberDuskWidgetThemeTokensLight extends AmberDuskWidgetThemeTokens {
  const AmberDuskWidgetThemeTokensLight();

  @override
  AmberDuskSkeletonThemeTokens get skeleton =>
      AmberDuskWidgetTheme.skeletonLight;

  @override
  AmberDuskTabThemeTokens get tabs => AmberDuskWidgetTheme.tabsLight;
}

/// Button recipes for shared Amber Dusk actions.
///
/// The recipes preserve the Open Design button geometry while letting widgets
/// map primary, quiet, and destructive commands to named roles.
@immutable
final class AmberDuskButtonThemeTokens {
  /// Creates immutable button recipes for the shared-widget adapter.
  const AmberDuskButtonThemeTokens();

  /// High-emphasis primary action recipe.
  AmberDuskButtonRecipe get primary => const AmberDuskButtonRecipe(
    background: AmberDuskColors.primary,
    foreground: AmberDuskColors.text,
  );

  /// Quiet secondary action recipe.
  AmberDuskButtonRecipe get ghost => const AmberDuskButtonRecipe(
    background: AmberDuskWidgetTheme.quietActionSurface,
    foreground: AmberDuskColors.text,
  );

  /// Destructive action recipe using the authored danger-action text color.
  AmberDuskButtonRecipe get danger => const AmberDuskButtonRecipe(
    background: AmberDuskWidgetTheme.quietActionSurface,
    foreground: AmberDuskColors.text,
  );

  /// Shared button radius from `.primary-action` evidence.
  double get radius => AmberDuskSpacing.compactControlRadius;

  /// Shared button minimum height from Open Design evidence.
  double get minHeight => AmberDuskWidgetTheme.buttonMinHeight;

  /// Shared horizontal padding from Open Design evidence.
  double get horizontalPadding => 18;

  /// Shared button padding with vertical space handled by min-height.
  EdgeInsets get padding => const EdgeInsets.symmetric(horizontal: 18);

  /// Border width is zero because the authored actions are borderless.
  double get borderWidth => AmberDuskSpacing.borderWidth;

  /// Shared button label style from Open Design evidence.
  TextStyle get textStyle => AmberDuskTypography.control.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );

  /// Success flash role for transient completion feedback.
  Color get successFlash => AmberDuskColors.forest;

  /// Error flash role for transient failure feedback.
  Color get errorFlash => AmberDuskColors.rust;

  /// Hover overlay for Material ink states.
  Color get hoverOverlay => AmberDuskWidgetTheme.buttonHoverOverlay;

  /// Focus overlay for Material ink states.
  Color get focusOverlay => AmberDuskWidgetTheme.buttonFocusOverlay;

  /// Icon size for compact CTA icons.
  double get iconSize => 20;

  /// Elevation level for active button surfaces.
  int get activeElevationLevel => 1;

  /// Elevation level for disabled, loading, or inactive button surfaces.
  int get inactiveElevationLevel => 0;
}

/// Visual recipe for one Amber Dusk button variant.
///
/// Widgets combine this color pair with shared geometry from
/// [AmberDuskButtonThemeTokens] to keep variant styling compact.
@immutable
final class AmberDuskButtonRecipe {
  /// Creates one immutable Amber Dusk button variant.
  const AmberDuskButtonRecipe({
    required this.background,
    required this.foreground,
  });

  /// Button fill color.
  final Color background;

  /// Button label and icon color.
  final Color foreground;
}

/// Input field recipe for shared Amber Dusk forms.
///
/// The label role records uppercase intent so widgets can transform display
/// text without hardcoding typography in individual fields.
@immutable
final class AmberDuskFieldThemeTokens {
  /// Creates immutable input field tokens.
  const AmberDuskFieldThemeTokens();

  /// Field label style from Open Design evidence.
  TextStyle get labelStyle => AmberDuskTypography.bodySmall.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );

  /// Field text style from Open Design evidence.
  TextStyle get textStyle => AmberDuskTypography.body.copyWith(fontSize: 14);

  /// Labels should render uppercase to match the source design.
  bool get labelUppercase => true;

  /// Borderless field background from the source artifact.
  Color get background => AmberDuskWidgetTheme.fieldSurface;

  /// Field radius from Open Design evidence.
  double get radius => 16;

  /// Field content padding from Open Design evidence.
  EdgeInsets get padding =>
      const EdgeInsets.symmetric(horizontal: 13, vertical: 12);

  /// Fields are borderless in the Amber Dusk evidence.
  double get borderWidth => AmberDuskSpacing.borderWidth;
}

/// Icon-button recipe for circular Amber Dusk tool actions.
///
/// The source `.icon-button` is a 42px borderless bg2 circle with text-colored
/// icon content. The Flutter widget still wraps smaller visuals in a 48px
/// semantic tap target for accessibility.
@immutable
final class AmberDuskIconButtonThemeTokens {
  /// Creates immutable icon-button tokens.
  const AmberDuskIconButtonThemeTokens();

  /// Visual size from `.icon-button` evidence.
  double get size => AmberDuskWidgetTheme.iconButtonSize;

  /// Standard icon size from the source SVG dimensions.
  double get iconSize => AmberDuskWidgetTheme.iconButtonIconSize;

  /// Solid icon button fill.
  Color get background => AmberDuskColors.surface;

  /// Default icon color from Open Design.
  Color get foreground => AmberDuskColors.text;

  /// Border color remains transparent because the source is borderless.
  Color get border => AmberDuskColors.transparent;

  /// Border width remains zero because the source is borderless.
  double get borderWidth => AmberDuskSpacing.borderWidth;
}

/// Status pill recipes for shared Amber Dusk metadata.
///
/// The pill keeps label text uppercase and borderless so status badges can
/// match the Open Design capsule treatment.
@immutable
final class AmberDuskStatusPillThemeTokens {
  /// Creates immutable status pill tokens.
  const AmberDuskStatusPillThemeTokens();

  /// Primary status recipe for normal highlighted states.
  AmberDuskStatusPillRecipe get primary => const AmberDuskStatusPillRecipe(
    background: AmberDuskWidgetTheme.primaryStatusOverlay,
    foreground: AmberDuskColors.primary,
  );

  /// Muted status recipe for setup and timeout states.
  AmberDuskStatusPillRecipe get muted => AmberDuskStatusPillRecipe(
    background: AmberDuskColors.muted.withValues(alpha: 0.12),
    foreground: AmberDuskColors.muted,
  );

  /// Active status recipe for active, won, and in-progress states.
  AmberDuskStatusPillRecipe get active => AmberDuskStatusPillRecipe(
    background: AmberDuskColors.forest.withValues(alpha: 0.14),
    foreground: AmberDuskColors.forest,
  );

  /// Completed status recipe for closed, delivered, and refunded states.
  AmberDuskStatusPillRecipe get completed => AmberDuskStatusPillRecipe(
    background: AmberDuskColors.text.withValues(alpha: 0.10),
    foreground: AmberDuskColors.text,
  );

  /// Urgent status recipe for destructive or time-sensitive states.
  AmberDuskStatusPillRecipe get urgent => const AmberDuskStatusPillRecipe(
    background: AmberDuskWidgetTheme.urgentStatusOverlay,
    foreground: AmberDuskColors.rust,
  );

  /// Full pill radius used for status capsules.
  double get radius => AmberDuskSpacing.pillRadius;

  /// Compact status padding from Open Design evidence.
  EdgeInsets get padding =>
      const EdgeInsets.symmetric(horizontal: 10, vertical: 5);

  /// Dense status padding for existing compact badge call sites.
  ///
  /// Open Design does not define a separate small status pill, so this keeps
  /// the full pill role but compresses it for dense legacy rows.
  EdgeInsets get smallPadding =>
      const EdgeInsets.symmetric(horizontal: 6, vertical: 2);

  /// Status label style from Open Design evidence.
  TextStyle get textStyle => AmberDuskTypography.chip.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w800,
  );

  /// Dense status label style for `StatusBadge.isSmall`.
  TextStyle get smallTextStyle => AmberDuskTypography.chip.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w800,
  );

  /// Icon size for normal status badges.
  double get iconSize => 14;

  /// Icon size for compact status badges.
  double get smallIconSize => 10;

  /// Status labels should render uppercase to match the source design.
  bool get labelUppercase => true;
}

/// Visual recipe for one Amber Dusk status pill variant.
///
/// Status widgets use this color pair with shared pill geometry to avoid
/// duplicating semantic overlay colors.
@immutable
final class AmberDuskStatusPillRecipe {
  /// Creates one immutable status pill variant.
  const AmberDuskStatusPillRecipe({
    required this.background,
    required this.foreground,
  });

  /// Pill fill color.
  final Color background;

  /// Pill label color.
  final Color foreground;
}

/// Bottom navigation recipe for the Amber Dusk phone shell.
///
/// It captures the four-destination contract and capsule geometry used by the
/// shared `CustomBottomNavBar` in later Phase 1 work.
@immutable
final class AmberDuskBottomNavThemeTokens {
  /// Creates immutable bottom navigation tokens.
  const AmberDuskBottomNavThemeTokens();

  /// Bottom nav keeps the current SLine four-destination contract.
  int get destinationCount => 4;

  /// Solid high-opacity nav surface from the Open Design evidence.
  Color get surface => AmberDuskColors.surface;

  /// Active icon capsule fill from the source artifact.
  Color get activeIconBackground => AmberDuskWidgetTheme.navActiveOverlay;

  /// Active icon and label color.
  Color get activeForeground => AmberDuskColors.primary;

  /// Inactive icon and label color.
  Color get inactiveForeground => AmberDuskColors.muted;

  /// Floating nav radius from Open Design evidence.
  double get radius => AmberDuskSpacing.navRadius;

  /// Active icon capsule size from Open Design evidence.
  Size get activeIconSize => const Size(38, 30);

  /// Active icon capsule radius from Open Design evidence.
  double get activeIconRadius => 11;

  /// Bottom navigation label style from Open Design evidence.
  TextStyle get labelStyle => AmberDuskTypography.navLabel.copyWith(
    fontSize: 9.5,
    fontWeight: FontWeight.w500,
  );
}

/// Card recipes for shared Amber Dusk surfaces.
///
/// The recipes stay borderless and expose elevation levels rather than concrete
/// shadows, letting widgets apply the existing `AppDecorations.elevation` API.
@immutable
final class AmberDuskCardThemeTokens {
  /// Creates immutable card recipe tokens.
  const AmberDuskCardThemeTokens();

  /// Task card recipe with the larger Open Design task radius.
  AmberDuskCardRecipe get task => const AmberDuskCardRecipe(
    background: AmberDuskColors.surfaceRaised,
    radius: AmberDuskSpacing.taskCardRadius,
    elevationLevel: AmberDuskWidgetTheme.taskCardElevationLevel,
  );

  /// Panel recipe for grouped modules.
  AmberDuskCardRecipe get panel => const AmberDuskCardRecipe(
    background: AmberDuskColors.surfaceRaised,
    radius: AmberDuskSpacing.moduleRadius,
    elevationLevel: AmberDuskWidgetTheme.panelCardElevationLevel,
  );

  /// Message bubble recipe for chat-style surfaces.
  AmberDuskCardRecipe get message => const AmberDuskCardRecipe(
    background: AmberDuskColors.surfaceRaised,
    radius: AmberDuskSpacing.moduleRadius,
    elevationLevel: AmberDuskWidgetTheme.panelCardElevationLevel,
  );

  /// Shared border color remains transparent because OD cards are borderless.
  Color get border => AmberDuskColors.transparent;

  /// Shared border width remains zero because OD cards are borderless.
  double get borderWidth => AmberDuskSpacing.borderWidth;

  /// Task-card gradient from `.task-card` Open Design evidence.
  List<Color> get taskGradientStops => const <Color>[
    AmberDuskWidgetTheme.taskCardTopFill,
    AmberDuskWidgetTheme.taskCardBottomFill,
  ];

  /// Task-card padding from Open Design evidence.
  EdgeInsets get taskPadding => const EdgeInsets.fromLTRB(15, 13, 15, 14);

  /// Booking-card padding from Open Design evidence.
  EdgeInsets get bookingPadding => const EdgeInsets.fromLTRB(19, 17, 19, 18);

  /// Task-card avatar size from Open Design evidence.
  double get taskAvatarSize => 46;

  /// Booking-card photo size from Open Design evidence.
  double get bookingPhotoSize => 54;

  /// Circular action size used on booking cards.
  double get bookingRoundActionSize => 40;

  /// Circular booking action icon size from `.round-action svg`.
  double get bookingRoundActionIconSize => 14;

  /// Booking metadata chip icon size from `.booking-chip svg`.
  double get bookingChipIconSize => 11;

  /// Booking metadata chip inner gap from `.booking-chip`.
  double get bookingChipGap => 5;

  /// Gap between circular booking actions from `.booking-actions`.
  double get bookingActionGap => 6;

  /// Booking CTA icon size from `.booking-cta svg`.
  double get bookingCtaIconSize => 13;

  /// Shared card CTA height from `.outline-action` and `.booking-cta`.
  double get cardActionHeight => 42;

  /// Task vertical rhythm between title/content groups from `.task-title`.
  double get taskSectionSpacing => 13;

  /// Gap below the provider photo row in the booking hero card.
  double get bookingTopSpacing => 14;

  /// Gap between provider name and role in the booking hero card.
  double get bookingNameGap => 5;

  /// Gap below the booking divider before the price/action row.
  double get bookingDividerBottomSpacing => 13;

  /// Task price pill radius from `.price-pill`.
  double get taskPriceRadius => 13;

  /// Inline icon/text gap used by task tags and price suffixes.
  double get taskInlineGap => 5;

  /// Task tag and price pill fill from Open Design evidence.
  Color get taskPillFill => AmberDuskWidgetTheme.taskPillSurface;

  /// Booking circular action fill from Open Design evidence.
  Color get bookingRoundActionFill =>
      AmberDuskWidgetTheme.bookingRoundActionSurface;

  /// Task price pill padding from Open Design evidence.
  EdgeInsets get taskPricePadding =>
      const EdgeInsets.symmetric(horizontal: 10, vertical: 7);

  /// Task metadata tag padding from Open Design evidence.
  EdgeInsets get taskTagPadding =>
      const EdgeInsets.symmetric(horizontal: 9, vertical: 5);

  /// Booking metadata chip padding from Open Design evidence.
  EdgeInsets get bookingChipPadding =>
      const EdgeInsets.symmetric(horizontal: 10, vertical: 5);

  /// Booking CTA horizontal padding from Open Design evidence.
  EdgeInsets get bookingActionPadding =>
      const EdgeInsets.symmetric(horizontal: 15);

  /// Task title typography from `.task-title`.
  TextStyle get taskTitleStyle => AmberDuskTypography.sectionTitle.copyWith(
    fontSize: 16.5,
    fontWeight: FontWeight.w800,
    height: 1.23,
  );

  /// Task copy typography from `.task-copy`.
  TextStyle get taskCopyStyle =>
      AmberDuskTypography.bodySmall.copyWith(fontSize: 12.5, height: 1.4);

  /// Task author typography from `.person strong`.
  TextStyle get taskAuthorStyle =>
      AmberDuskTypography.chip.copyWith(fontSize: 13.5);

  /// Task chip typography from `.tag`.
  TextStyle get taskChipStyle => AmberDuskTypography.chip.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
  );

  /// Task price typography from `.price-pill`.
  TextStyle get taskPriceStyle => AmberDuskTypography.control.copyWith(
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
  );

  /// Task CTA typography from `.outline-action`.
  TextStyle get taskActionStyle => AmberDuskTypography.control.copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w800,
  );

  /// Booking provider name typography from `.booking-name`.
  TextStyle get bookingNameStyle =>
      AmberDuskTypography.bookingName.copyWith(letterSpacing: 0);

  /// Booking role typography from `.booking-role`.
  TextStyle get bookingRoleStyle => AmberDuskTypography.chip.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  /// Booking chip typography from `.booking-chip`.
  TextStyle get bookingChipStyle => AmberDuskTypography.chip.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
  );

  /// Booking price typography from `.booking-price span`.
  TextStyle get bookingPriceStyle => AmberDuskTypography.bookingName.copyWith(
    fontSize: 25,
    fontWeight: FontWeight.w700,
    height: 1,
  );

  /// Booking period typography from `.booking-period`.
  TextStyle get bookingPeriodStyle => AmberDuskTypography.chip.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  /// Card CTA typography shared by booking and task actions.
  TextStyle get cardActionStyle => AmberDuskTypography.control.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
}

/// Visual recipe for one Amber Dusk card surface.
///
/// Shared widgets use this small contract to map task, panel, and message
/// surfaces without copying background, radius, or depth values.
@immutable
final class AmberDuskCardRecipe {
  /// Creates one immutable card recipe.
  const AmberDuskCardRecipe({
    required this.background,
    required this.radius,
    required this.elevationLevel,
  });

  /// Card fill color.
  final Color background;

  /// Card radius in logical pixels.
  final double radius;

  /// Existing `AppDecorations.elevation` level to apply when rendered.
  final int elevationLevel;
}

/// Media placeholder tokens for avatars and fallback image surfaces.
///
/// These values are visual-only and do not alter signed URL, cache, storage, or
/// Supabase behavior in signed media widgets.
@immutable
final class AmberDuskMediaThemeTokens {
  /// Creates immutable media placeholder tokens.
  const AmberDuskMediaThemeTokens();

  /// Warm avatar fallback from the Open Design evidence.
  Color get avatarFallback => AmberDuskWidgetTheme.avatarFallbackWarm;

  /// Cool profile photo fallback from the Open Design evidence.
  Color get profilePhotoFallback =>
      AmberDuskWidgetTheme.profilePhotoFallbackCool;

  /// Online dot color from the Open Design evidence.
  Color get onlineDot => AmberDuskColors.forest;

  /// Foreground color for media placeholder icons and labels.
  Color get foreground => AmberDuskColors.text;

  /// Initials text style scaled to the rendered avatar size.
  ///
  /// Avatar initials need proportional sizing because this widget supports
  /// both circular and rounded-rectangle modes.
  TextStyle initialsTextStyle(double avatarSize) =>
      AmberDuskTypography.chip.copyWith(
        color: foreground,
        fontSize: avatarSize * 0.35,
        fontWeight: FontWeight.w800,
      );

  /// Retry label style for signed image fallback surfaces.
  TextStyle get fallbackLabelStyle => AmberDuskTypography.chip.copyWith(
    color: foreground,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
}

/// Skeleton placeholder tokens derived from Amber Dusk surfaces.
///
/// Open Design did not provide skeleton-specific evidence, so these values are
/// limited to existing bg2, bg3, and highlight surface steps.
@immutable
class AmberDuskSkeletonThemeTokens {
  /// Creates immutable skeleton tokens for dark mode (default).
  const AmberDuskSkeletonThemeTokens();

  /// Base skeleton fill derived from bg2.
  Color get base => AmberDuskColors.surface;

  /// Raised skeleton fill derived from bg3.
  Color get raised => AmberDuskColors.surfaceRaised;

  /// Highlight fill derived from the highest authored surface step.
  Color get highlight => AmberDuskColors.surfaceHighest;
}

/// Light-mode skeleton tokens using the derived light color scheme.
@immutable
final class _AmberDuskSkeletonThemeTokensLight
    extends AmberDuskSkeletonThemeTokens {
  const _AmberDuskSkeletonThemeTokensLight();

  @override
  Color get base => AmberDuskColors.lightScheme.surface;

  @override
  Color get raised => AmberDuskColors.lightScheme.surfaceRaised;

  @override
  Color get highlight => AmberDuskColors.lightScheme.surfaceHighest;
}

/// TabBar recipe used by the global SLine ThemeData.
///
/// Only the TabBar active color is activated in `AppTheme`; this does not remap
/// `AppTheme.light()` or `AppTheme.dark()` to the full Amber Dusk palette.
@immutable
class AmberDuskTabThemeTokens {
  /// Creates immutable TabBar tokens for dark mode (default).
  const AmberDuskTabThemeTokens();

  /// Active label and indicator color, replacing the previous teal-era value.
  Color get activeLabelColor => AmberDuskColors.primary;

  /// Inactive label color for subdued tab labels.
  Color get inactiveLabelColor => AmberDuskColors.muted;

  /// Indicator color aligned with the active label.
  Color get indicatorColor => AmberDuskColors.primary;

  /// Indicator thickness keeps the existing SLine TabBar geometry stable.
  double get indicatorThickness => 3;

  /// Indicator radius keeps the existing SLine underline shape stable.
  double get indicatorRadius => 2;

  /// Active tab label style from the Amber Dusk shared label system.
  TextStyle get labelStyle => AmberDuskTypography.chip.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );

  /// Inactive tab label style from the Amber Dusk shared label system.
  TextStyle get inactiveLabelStyle =>
      AmberDuskTypography.chip.copyWith(fontSize: 12);
}

/// Light-mode TabBar tokens using the derived light color scheme.
@immutable
final class _AmberDuskTabThemeTokensLight extends AmberDuskTabThemeTokens {
  const _AmberDuskTabThemeTokensLight();

  @override
  Color get activeLabelColor => AmberDuskColors.lightScheme.primary;

  @override
  Color get inactiveLabelColor => AmberDuskColors.lightScheme.muted;

  @override
  Color get indicatorColor => AmberDuskColors.lightScheme.primary;
}
