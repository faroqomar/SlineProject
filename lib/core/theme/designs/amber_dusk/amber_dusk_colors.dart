/// Provides the staged Amber Dusk color palette and semantic mappings.
///
/// The file keeps Open Design color evidence in one local token layer so later
/// screen phases can consume named values without changing the active app theme.
library;

import 'package:flutter/material.dart';

/// Namespace for Amber Dusk palette constants and mode-specific schemes.
///
/// The namespace exists so tests and future screen work can reference stable
/// token names while the current SLine theme remains unchanged.
abstract final class AmberDuskColors {
  const AmberDuskColors._();

  /// Token registry exposed by `AmberDuskTokens` for instance-style access.
  static const AmberDuskColorTokens tokens = AmberDuskColorTokens();

  /// Local transparent token used where Amber Dusk intentionally stays borderless.
  static const Color transparent = Color(0x00000000);

  /// Primary Amber Dusk action color from Open Design evidence.
  static const Color primary = Color(0xFFD4906A);

  /// Deeper primary color for pressed states and gradient depth.
  static const Color primaryDeep = Color(0xFFA36A48);

  /// Warm amber accent for supporting highlights.
  static const Color amber = Color(0xFFE6B87A);

  /// Rust accent used for danger states and warm contrast.
  static const Color rust = Color(0xFFC9695C);

  /// Forest accent used as the semantic success color.
  static const Color forest = Color(0xFF7FA872);

  /// Star accent used as the semantic warning color.
  static const Color star = Color(0xFFE8B856);

  /// Dark page background from the Amber Dusk phone artboard.
  static const Color page = Color(0xFF0E0B08);

  /// First elevated dark background step from the Open Design phone shell.
  static const Color background = Color(0xFF1A1612);

  /// Default dark card surface step.
  static const Color surface = Color(0xFF241F1A);

  /// Secondary dark surface step from the Open Design variable set.
  static const Color surface2 = Color(0xFF2F2822);

  /// Raised dark card surface step matching `rgba(36,31,26,.9)`.
  static const Color surfaceRaised = Color.fromRGBO(36, 31, 26, 0.90);

  /// Highest dark neutral surface available for strongest neutral contrast.
  static const Color surfaceHighest = Color(0xFF3A312A);

  /// Primary cream text color from Open Design evidence.
  static const Color text = Color(0xFFF2E8D5);

  /// Softer cream text color for secondary labels on dark surfaces.
  static const Color textSubtle = Color(0xFFE6D7BE);

  /// Dark text color used by derived light-mode tokens.
  static const Color textDark = Color(0xFF1F1813);

  /// Muted copy color from Open Design evidence.
  static const Color muted = Color(0xFF8F8478);

  /// Darker muted copy color used for lower-emphasis labels.
  static const Color mutedDark = Color(0xFF7A6F63);

  /// Top stop for the V2 booking hero gradient.
  static const Color heroTop = Color(0xFF4A2D1F);

  /// Middle stop for the V2 booking hero gradient.
  static const Color hero = Color(0xFF3E2418);

  /// Deep stop for the V2 booking hero gradient.
  static const Color heroDeep = Color(0xFF2E1810);

  /// Cream text color tuned for hero surfaces.
  static const Color heroText = Color(0xFFF5E8D0);

  /// Muted cream text for hero metadata, matching the authored 55% alpha.
  static const Color heroMuted = Color(0x8CF5E8D0);

  /// Subtle hero chip fill used inside booking cards.
  static const Color heroChip = Color(0x0DFFFFFF);

  /// Transparent hero chip border matching the borderless Open Design chip.
  static const Color heroChipBorder = transparent;

  /// Divider color used within hero booking surfaces.
  static const Color heroDivider = Color(0x1AF5E8D0);

  /// Hairline separator used inside raised surfaces instead of visible borders.
  static const Color rowSeparator = Color.fromRGBO(242, 232, 213, 0.058);

  /// First color stop for the quiet active or unread amber row wash.
  static const Color activeWashStart = Color.fromRGBO(212, 144, 106, 0.105);

  /// Middle color stop for the quiet active or unread amber row wash.
  static const Color activeWashMiddle = Color.fromRGBO(212, 144, 106, 0.018);

  /// Top stop for bottom navigation safe-area fade.
  static const Color bottomNavFadeTop = Color.fromRGBO(26, 22, 18, 0);

  /// Middle stop for bottom navigation safe-area fade.
  static const Color bottomNavFadeMiddle = Color.fromRGBO(26, 22, 18, 0.92);

  /// Low-opacity amber top-shell atmospheric fade from `.phone:before`.
  static const Color atmosphericAmber = Color.fromRGBO(212, 144, 106, 0.13);

  /// Low-opacity forest top-shell atmospheric fade from `.phone:before`.
  static const Color atmosphericForest = Color.fromRGBO(127, 168, 114, 0.08);

  /// Top highlight that preserves the hero material sheen without blur.
  static const Color heroHighlight = Color(0x0AFFFFFF);

  /// Subtle hero rim used as bevel evidence, not as a generic card border.
  static const Color heroRim = Color(0x0FFFFFFF);

  /// Reserved for future overlay adapters that need the observed dark rim.
  static const Color rimDark = Color(0x1F000000);

  /// Low-alpha primary overlay expressed as a solid ARGB token.
  static const Color primaryOverlaySubtle = Color(0x1FD4906A);

  /// Medium-alpha primary overlay expressed as a solid ARGB token.
  static const Color primaryOverlay = Color(0x33D4906A);

  /// Active state glow tint from the Amber Dusk system rules.
  static const Color activeGlow = primaryOverlay;

  /// Reserved for future danger overlays while Phase 0 keeps status washes pinned.
  static const Color rustOverlaySubtle = Color(0x1FC9695C);

  /// Solid scrim token for modal and sheet dimming.
  static const Color scrim = Color(0x990E0B08);

  /// Open Design authored dark semantic palette.
  static const AmberDuskColorScheme darkScheme = AmberDuskColorScheme(
    isDark: true,
    primary: primary,
    primaryDeep: primaryDeep,
    amber: amber,
    rust: rust,
    forest: forest,
    star: star,
    page: page,
    background: background,
    surface: surface,
    surfaceRaised: surfaceRaised,
    surfaceHighest: surfaceHighest,
    text: text,
    textSubtle: textSubtle,
    textInverse: textDark,
    muted: muted,
    mutedStrong: mutedDark,
    heroTop: heroTop,
    hero: hero,
    heroDeep: heroDeep,
    heroText: heroText,
    heroMuted: heroMuted,
    heroChip: heroChip,
    heroChipBorder: heroChipBorder,
    heroDivider: heroDivider,
    heroHighlight: heroHighlight,
    heroRim: heroRim,
    border: transparent,
    divider: transparent,
    success: forest,
    successMuted: Color(0xFF25331F),
    warning: star,
    warningMuted: Color(0xFF3B2F14),
    info: primary,
    infoMuted: Color(0xFF3A281D),
    danger: rust,
    dangerMuted: Color(0xFF3B1F1A),
    activeGlow: activeGlow,
    overlay: primaryOverlaySubtle,
    scrim: scrim,
  );

  /// Derived light semantic palette for API parity, not an authored OD theme.
  static const AmberDuskColorScheme lightScheme = AmberDuskColorScheme(
    isDark: false,
    primary: primary,
    primaryDeep: primaryDeep,
    amber: Color(0xFFC9823C),
    rust: rust,
    forest: Color(0xFF4F7A44),
    star: Color(0xFFB87920),
    page: Color(0xFFFFF8EF),
    background: Color(0xFFF8ECDC),
    surface: Color(0xFFF2E8D5),
    surfaceRaised: Color(0xFFFFFCF7),
    surfaceHighest: Color(0xFFE2CFB3),
    text: textDark,
    textSubtle: Color(0xFF4A3A2E),
    textInverse: text,
    muted: mutedDark,
    mutedStrong: muted,
    heroTop: Color(0xFFE7B48F),
    hero: Color(0xFFD4906A),
    heroDeep: Color(0xFFA36A48),
    heroText: textDark,
    heroMuted: Color(0x8C1F1813),
    heroChip: Color(0x0D000000),
    heroChipBorder: transparent,
    heroDivider: Color(0x1A1F1813),
    heroHighlight: Color(0x14FFFFFF),
    heroRim: Color(0x1F1F1813),
    border: transparent,
    divider: transparent,
    success: Color(0xFF4F7A44),
    successMuted: Color(0xFFE4EEDC),
    warning: Color(0xFFB87920),
    warningMuted: Color(0xFFFFF2D4),
    info: Color(0xFFA36A48),
    infoMuted: Color(0xFFF5E1D1),
    danger: Color(0xFFA94F45),
    dangerMuted: Color(0xFFF7DDD8),
    activeGlow: Color(0x1FA36A48),
    overlay: Color(0x1FA36A48),
    scrim: Color(0x660E0B08),
  );
}

/// Instance-facing color registry used by `AmberDuskTokens.colors`.
///
/// This class lets consumers use `AmberDuskTokens.colors.primary` for the
/// default dark mapping while still making the derived light scheme explicit.
@immutable
final class AmberDuskColorTokens {
  /// Creates a stateless color token registry for the staged design layer.
  const AmberDuskColorTokens();

  /// Dark Amber Dusk semantic scheme from Open Design evidence.
  AmberDuskColorScheme get dark => AmberDuskColors.darkScheme;

  /// Derived light semantic scheme kept for API parity only.
  AmberDuskColorScheme get light => AmberDuskColors.lightScheme;

  /// Primary action color from the default dark scheme.
  Color get primary => dark.primary;

  /// Deep primary action color from the default dark scheme.
  Color get primaryDeep => dark.primaryDeep;

  /// Page background color from the default dark scheme.
  Color get page => dark.page;

  /// Primary text color from the default dark scheme.
  Color get text => dark.text;

  /// Secondary cream text color from the default dark scheme.
  Color get textSubtle => dark.textSubtle;

  /// Inverse text color from the default dark scheme.
  Color get textInverse => dark.textInverse;

  /// First structural background color from the default dark scheme.
  Color get background => dark.background;

  /// Default card surface color from the default dark scheme.
  Color get surface => dark.surface;

  /// Secondary surface step from the Open Design variable set.
  Color get surface2 => AmberDuskColors.surface2;

  /// Raised surface color from the default dark scheme.
  Color get surfaceRaised => dark.surfaceRaised;

  /// Highest neutral surface color from the default dark scheme.
  Color get surfaceHighest => dark.surfaceHighest;

  /// Muted text color from the default dark scheme.
  Color get muted => dark.muted;

  /// Top hero gradient stop from the default dark scheme.
  Color get heroTop => dark.heroTop;

  /// Middle hero gradient stop from the default dark scheme.
  Color get hero => dark.hero;

  /// Deep hero gradient stop from the default dark scheme.
  Color get heroDeep => dark.heroDeep;

  /// Hero text color from the default dark scheme.
  Color get heroText => dark.heroText;

  /// Muted hero metadata color from the default dark scheme.
  Color get heroMuted => dark.heroMuted;

  /// Hero chip fill color from the default dark scheme.
  Color get heroChip => dark.heroChip;

  /// Hero chip border color from the default dark scheme.
  Color get heroChipBorder => dark.heroChipBorder;

  /// Hero divider color from the default dark scheme.
  Color get heroDivider => dark.heroDivider;

  /// Hairline separator used inside surfaces instead of card borders.
  Color get rowSeparator => AmberDuskColors.rowSeparator;

  /// First color stop for active and unread row washes.
  Color get activeWashStart => AmberDuskColors.activeWashStart;

  /// Middle color stop for active and unread row washes.
  Color get activeWashMiddle => AmberDuskColors.activeWashMiddle;

  /// Top transparent stop for bottom navigation safe-area fade.
  Color get bottomNavFadeTop => AmberDuskColors.bottomNavFadeTop;

  /// Middle stop for bottom navigation safe-area fade.
  Color get bottomNavFadeMiddle => AmberDuskColors.bottomNavFadeMiddle;

  /// Low-opacity amber top-shell atmospheric fade.
  Color get atmosphericAmber => AmberDuskColors.atmosphericAmber;

  /// Low-opacity forest top-shell atmospheric fade.
  Color get atmosphericForest => AmberDuskColors.atmosphericForest;

  /// Hero highlight color from the default dark scheme.
  Color get heroHighlight => dark.heroHighlight;

  /// Hero rim color from the default dark scheme.
  Color get heroRim => dark.heroRim;

  /// Dark scrim used for authored hero overlays.
  Color get scrim => dark.scrim;

  /// Forest accent alias used by status and badge recipes.
  Color get forest => dark.forest;

  /// Star accent alias used by warning and rating recipes.
  Color get star => dark.star;

  /// Rust accent alias used by danger recipes.
  Color get rust => dark.rust;

  /// Semantic success color from the default dark scheme.
  Color get success => dark.success;

  /// Muted success wash from the default dark scheme.
  Color get successMuted => dark.successMuted;

  /// Semantic warning color from the default dark scheme.
  Color get warning => dark.warning;

  /// Muted warning wash from the default dark scheme.
  Color get warningMuted => dark.warningMuted;

  /// Semantic info color from the default dark scheme.
  Color get info => dark.info;

  /// Muted info wash from the default dark scheme.
  Color get infoMuted => dark.infoMuted;

  /// Semantic danger color from the default dark scheme.
  Color get danger => dark.danger;

  /// Muted danger wash from the default dark scheme.
  Color get dangerMuted => dark.dangerMuted;

  /// Active state glow tint from the default dark scheme.
  Color get activeGlow => dark.activeGlow;

  /// Transparent token used by borderless Amber Dusk controls.
  Color get transparent => AmberDuskColors.transparent;

  /// Dark text token used on light hero/action fills.
  Color get textDark => AmberDuskColors.textDark;
}

/// A semantic Amber Dusk color mapping for one brightness mode.
///
/// The class separates authored dark tokens from derived light parity so future
/// theme activation can be tested without guessing which values are canonical.
@immutable
final class AmberDuskColorScheme {
  /// Creates a semantic color scheme for a single Amber Dusk brightness mode.
  const AmberDuskColorScheme({
    required this.isDark,
    required this.primary,
    required this.primaryDeep,
    required this.amber,
    required this.rust,
    required this.forest,
    required this.star,
    required this.page,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceHighest,
    required this.text,
    required this.textSubtle,
    required this.textInverse,
    required this.muted,
    required this.mutedStrong,
    required this.heroTop,
    required this.hero,
    required this.heroDeep,
    required this.heroText,
    required this.heroMuted,
    required this.heroChip,
    required this.heroChipBorder,
    required this.heroDivider,
    required this.heroHighlight,
    required this.heroRim,
    required this.border,
    required this.divider,
    required this.success,
    required this.successMuted,
    required this.warning,
    required this.warningMuted,
    required this.info,
    required this.infoMuted,
    required this.danger,
    required this.dangerMuted,
    required this.activeGlow,
    required this.overlay,
    required this.scrim,
  });

  /// Whether the scheme targets a dark brightness context.
  final bool isDark;

  /// Main action and active-state color.
  final Color primary;

  /// Deeper action color for pressed states and gradient depth.
  final Color primaryDeep;

  /// Warm secondary accent used for highlights that are not warnings.
  final Color amber;

  /// Rust palette color used by danger and destructive recipes.
  final Color rust;

  /// Forest palette color used by success recipes.
  final Color forest;

  /// Star palette color used by warning and rating recipes.
  final Color star;

  /// Screen background color.
  final Color page;

  /// First structural background color above the page.
  final Color background;

  /// Default card and control surface color.
  final Color surface;

  /// Raised surface color for stacked or active cards.
  final Color surfaceRaised;

  /// Highest neutral surface color for borders and strong dividers.
  final Color surfaceHighest;

  /// Primary readable text color.
  final Color text;

  /// Secondary readable text color.
  final Color textSubtle;

  /// Text color intended for inverse surfaces.
  final Color textInverse;

  /// Muted copy color for low-emphasis metadata.
  final Color muted;

  /// Stronger muted color for disabled or deeply secondary labels.
  final Color mutedStrong;

  /// Top stop for hero gradients.
  final Color heroTop;

  /// Middle stop for hero gradients.
  final Color hero;

  /// Deep stop for hero gradients.
  final Color heroDeep;

  /// Text color intended for hero surfaces.
  final Color heroText;

  /// Muted hero metadata color.
  final Color heroMuted;

  /// Hero chip fill color.
  final Color heroChip;

  /// Hero chip border color.
  final Color heroChipBorder;

  /// Hero divider color.
  final Color heroDivider;

  /// Hero top highlight color.
  final Color heroHighlight;

  /// Hero rim color used for material bevel evidence.
  final Color heroRim;

  /// Generic border color; transparent preserves the OD borderless rim.
  final Color border;

  /// Generic divider color; hero-specific dividers use [heroDivider].
  final Color divider;

  /// Semantic success color.
  final Color success;

  /// Muted success fill color.
  final Color successMuted;

  /// Semantic warning color.
  final Color warning;

  /// Muted warning fill color.
  final Color warningMuted;

  /// Semantic info color using the warm Amber Dusk range.
  final Color info;

  /// Muted info fill color.
  final Color infoMuted;

  /// Semantic danger color.
  final Color danger;

  /// Muted danger fill color.
  final Color dangerMuted;

  /// Active state glow tint.
  final Color activeGlow;

  /// Solid overlay tint for active states.
  final Color overlay;

  /// Solid scrim color for modal dimming.
  final Color scrim;
}
