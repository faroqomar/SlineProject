/// Provides Amber Dusk typography roles and fallback stacks.
///
/// The file records DM Sans and Fraunces as design-intent families without
/// bundling font assets, keeping Phase 0 free of licensing and asset changes.
library;

import 'package:flutter/material.dart';

/// Stable names for Amber Dusk typography roles.
///
/// Component recipes use these constants instead of raw strings so role names
/// stay aligned with the text styles exposed by this file.
abstract final class AmberDuskTypographyRoles {
  const AmberDuskTypographyRoles._();

  /// Screen title typography role name.
  static const String screenTitle = 'screenTitle';

  /// Section title typography role name.
  static const String sectionTitle = 'sectionTitle';

  /// Booking and freelancer name typography role name.
  static const String bookingName = 'bookingName';

  /// Large money value typography role name.
  static const String moneyLarge = 'moneyLarge';

  /// Medium money value typography role name.
  static const String moneyMedium = 'moneyMedium';

  /// Body copy typography role name.
  static const String body = 'body';

  /// Small body copy typography role name.
  static const String bodySmall = 'bodySmall';

  /// Control label typography role name.
  static const String control = 'control';

  /// Chip and badge typography role name.
  static const String chip = 'chip';

  /// Bottom navigation label typography role name.
  static const String navLabel = 'navLabel';
}

/// Namespace for Amber Dusk font families and role-based text styles.
///
/// The namespace keeps family names and role styles stable for future screen
/// phases while allowing the Flutter app to fall back gracefully today.
abstract final class AmberDuskTypography {
  const AmberDuskTypography._();

  /// Token registry exposed by `AmberDuskTokens` for instance-style access.
  static const AmberDuskTypographyTokens tokens = AmberDuskTypographyTokens();

  /// Interface family used for controls, labels, chips, and paragraphs.
  static const String interfaceFamily = 'DM Sans';

  /// Display family used for titles, names, and major money values.
  static const String displayFamily = 'Fraunces';

  /// Fallbacks for DM Sans that preserve Arabic readiness and platform safety.
  static const List<String> interfaceFallback = <String>[
    'Noto Sans',
    'Noto Sans Arabic',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  /// Fallbacks for Fraunces display roles before local font assets are bundled.
  static const List<String> displayFallback = <String>[
    'DM Serif Display',
    'Georgia',
    // Use the UI family before broad system fonts for safer i18n fallback.
    interfaceFamily,
    'Noto Sans',
    'Noto Sans Arabic',
    'serif',
  ];

  /// Large screen title style for 402px phone artboards.
  static const TextStyle screenTitle = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: displayFallback,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.08,
    letterSpacing: 0,
  );

  /// Section heading style for compact grouped content.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: interfaceFamily,
    fontFamilyFallback: interfaceFallback,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Booking and freelancer name style using the display family sparingly.
  static const TextStyle bookingName = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: displayFallback,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: 0,
  );

  /// Large wallet or money value style from Open Design evidence.
  static const TextStyle moneyLarge = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: displayFallback,
    fontSize: 44,
    fontWeight: FontWeight.w800,
    height: 1,
    letterSpacing: 0,
  );

  /// Medium money value style for cards and summaries.
  static const TextStyle moneyMedium = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: displayFallback,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.04,
    letterSpacing: 0,
  );

  /// Primary body copy style for dense marketplace content.
  static const TextStyle body = TextStyle(
    fontFamily: interfaceFamily,
    fontFamilyFallback: interfaceFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0,
  );

  /// Smaller body copy style for descriptions and secondary rows.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: interfaceFamily,
    fontFamilyFallback: interfaceFallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0,
  );

  /// Control label style for buttons and segmented actions.
  static const TextStyle control = TextStyle(
    fontFamily: interfaceFamily,
    fontFamilyFallback: interfaceFallback,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Compact label style for chips, tags, and status badges.
  static const TextStyle chip = TextStyle(
    fontFamily: interfaceFamily,
    fontFamilyFallback: interfaceFallback,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: 0,
  );

  /// Bottom navigation label style for the phone shell.
  static const TextStyle navLabel = TextStyle(
    fontFamily: interfaceFamily,
    fontFamilyFallback: interfaceFallback,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: 0,
  );
}

/// Instance-facing typography registry used by `AmberDuskTokens.typography`.
///
/// The registry keeps text roles reachable from the public token entry point
/// without requiring consumers to import implementation files directly.
@immutable
final class AmberDuskTypographyTokens {
  /// Creates a stateless typography token registry.
  const AmberDuskTypographyTokens();

  /// Interface family used for controls, labels, chips, and paragraphs.
  String get interfaceFamily => AmberDuskTypography.interfaceFamily;

  /// Display family used for titles, names, and money values.
  String get displayFamily => AmberDuskTypography.displayFamily;

  /// Control family alias for button and segmented-control labels.
  String get controlFamily => AmberDuskTypography.interfaceFamily;

  /// Label family alias for metadata and field labels.
  String get labelFamily => AmberDuskTypography.interfaceFamily;

  /// Chip family alias for compact tags and status pills.
  String get chipFamily => AmberDuskTypography.interfaceFamily;

  /// Paragraph family alias for readable body copy.
  String get paragraphFamily => AmberDuskTypography.interfaceFamily;

  /// Title family alias for page titles and section display copy.
  String get titleFamily => AmberDuskTypography.displayFamily;

  /// Name family alias for freelancer and booking names.
  String get nameFamily => AmberDuskTypography.displayFamily;

  /// Money family alias for high-emphasis amount text.
  String get moneyFamily => AmberDuskTypography.displayFamily;

  /// Fallbacks for interface text when DM Sans is unavailable.
  List<String> get interfaceFallback => AmberDuskTypography.interfaceFallback;

  /// Fallbacks for display text when Fraunces is unavailable.
  List<String> get displayFallback => AmberDuskTypography.displayFallback;

  /// Plural alias for interface fallback family names.
  List<String> get interfaceFallbacks => interfaceFallback;

  /// Plural alias for display fallback family names.
  List<String> get displayFallbacks => displayFallback;

  /// Large screen title style for phone pages.
  TextStyle get screenTitle => AmberDuskTypography.screenTitle;

  /// Section heading style for grouped content.
  TextStyle get sectionTitle => AmberDuskTypography.sectionTitle;

  /// Booking and freelancer name style.
  TextStyle get bookingName => AmberDuskTypography.bookingName;

  /// Large wallet or money value style.
  TextStyle get moneyLarge => AmberDuskTypography.moneyLarge;

  /// Medium money value style.
  TextStyle get moneyMedium => AmberDuskTypography.moneyMedium;

  /// Primary body copy style.
  TextStyle get body => AmberDuskTypography.body;

  /// Smaller secondary body copy style.
  TextStyle get bodySmall => AmberDuskTypography.bodySmall;

  /// Control label style.
  TextStyle get control => AmberDuskTypography.control;

  /// Compact chip and badge style.
  TextStyle get chip => AmberDuskTypography.chip;

  /// Bottom navigation label style.
  TextStyle get navLabel => AmberDuskTypography.navLabel;
}
