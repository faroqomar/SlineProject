import 'package:flutter/material.dart';

// Helper extension to parse hex colors with optional alpha from Tailwind-like syntax
extension HexColor on Color {
  static Color fromHex(String hexString, {double opacity = 1.0}) {
    // Remove # if present
    final String cleanHex = hexString.replaceFirst('#', '');

    // Handle transparent colors like `bg-[#f4f3f1]/10`
    // Opacity will be passed directly in Flutter Color constructor rather than calculating from hex.
    final buffer = StringBuffer();
    if (cleanHex.length == 6) {
      buffer.write('ff'); // Add full opacity if not specified
    }
    buffer.write(cleanHex);
    return Color(
      int.parse(buffer.toString(), radix: 16),
    ).withValues(alpha: opacity);
  }
}

/// Defines the core color palette of the application.
///
/// This class holds all the raw, base colors used throughout the SLine app,
/// extracted directly from the design system. These colors are then composed
/// into light and dark color schemes by [AppColorScheme].
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // --- Primary Hues ---
  static final Color teal = HexColor.fromHex('#146068');
  static final Color darkTeal = HexColor.fromHex(
    '#0c3b40',
  ); // Darker teal for gradients
  static final Color lightTeal = HexColor.fromHex('#93ccce');
  static final Color gold = HexColor.fromHex('#f3bb19');
  static final Color sand = HexColor.fromHex(
    '#F7D69C',
  ); // Sand/beige for UI elements
  static final Color lightRed = HexColor.fromHex(
    '#f49d9d',
  ); // Often used for "hot" badges or error states

  // --- Grayscale & Neutrals ---
  static final Color almostBlack = HexColor.fromHex('#0c0c0c');
  static final Color offWhite = HexColor.fromHex('#f4f3f1');
  static final Color white = HexColor.fromHex('#ffffff');
  static final Color mediumGreyBlue = HexColor.fromHex('#9dbabb');
  static final Color mediumGrey = HexColor.fromHex('#a9a8a7');
  static final Color darkerGrey = HexColor.fromHex('#6b6b6b');

  // --- Specific UI Element Colors (derived from base hues with opacities) ---
  // These are often intermediate colors that carry a specific opacity from the design.
  static final Color tealTransparent5 = HexColor.fromHex(
    '#146068',
    opacity: 0.05,
  ); // from-[#146068]/5
  static final Color lightTealTransparent15 = HexColor.fromHex(
    '#93ccce',
    opacity: 0.15,
  ); // from-[#93ccce]/15
  static final Color lightTealTransparent20 = HexColor.fromHex(
    '#93ccce',
    opacity: 0.20,
  ); // border-[#93ccce]/20

  static final Color offWhiteTransparent8 = HexColor.fromHex(
    '#f4f3f1',
    opacity: 0.08,
  ); // bg-[#f4f3f1]/8 (dark card bg)
  static final Color offWhiteTransparent10 = HexColor.fromHex(
    '#f4f3f1',
    opacity: 0.10,
  ); // bg-[#f4f3f1]/10 (dark input bg)
  static final Color offWhiteTransparent15 = HexColor.fromHex(
    '#f4f3f1',
    opacity: 0.15,
  ); // focus:bg-[#f4f3f1]/15

  static final Color tealTransparent15 = HexColor.fromHex(
    '#146068',
    opacity: 0.15,
  ); // border-[#146068]/15
  static final Color tealTransparent20 = HexColor.fromHex(
    '#146068',
    opacity: 0.20,
  ); // bg-[#146068]/20 (dark header bg)
  static final Color tealTransparent30 = HexColor.fromHex(
    '#146068',
    opacity: 0.30,
  ); // for buttons
  static final Color tealTransparent40 = HexColor.fromHex(
    '#146068',
    opacity: 0.40,
  ); // hover border

  static final Color goldTransparent20 = HexColor.fromHex(
    '#f3bb19',
    opacity: 0.20,
  ); // hotBadgeBg
  static final Color goldTransparent30 = HexColor.fromHex(
    '#f3bb19',
    opacity: 0.30,
  ); // hotBadgeBorder

  static final Color almostBlackTransparent70 = HexColor.fromHex(
    '#0c0c0c',
    opacity: 0.70,
  ); // contentGradient to
  static final Color almostBlackTransparent60 = HexColor.fromHex(
    '#0c0c0c',
    opacity: 0.60,
  ); // taskGradient from
  static final Color almostBlackTransparent40 = HexColor.fromHex(
    '#0c0c0c',
    opacity: 0.40,
  ); // New: taskGradient from in light mode

  // --- Glassmorphism Gradients ---
  static final List<Color> glassCardGradientLight = [
    AppColors.white.withValues(alpha: 0.7),
    AppColors.white.withValues(alpha: 0.4),
  ];
  static final List<Color> glassCardGradientDark = [
    AppColors.teal.withValues(alpha: 0.2), // rgba(20, 96, 104, 0.2)
    AppColors.almostBlack.withValues(alpha: 0.4), // rgba(0, 0, 0, 0.4)
  ];

  // --- Semantic Colors for Task Types (Tender vs Booking) ---
  // These methods maintain the signature expected by existing code.

  static Color tenderCardBg(BuildContext context) =>
      AppColors.lightRed.withValues(alpha: 0.05);
  static Color bookingCardBg(BuildContext context) =>
      AppColors.teal.withValues(alpha: 0.05);

  static Color tenderBorder(BuildContext context) =>
      AppColors.lightRed.withValues(alpha: 0.3);
  static Color bookingBorder(BuildContext context) =>
      AppColors.teal.withValues(alpha: 0.3);

  static Color tenderChipBg(BuildContext context) =>
      AppColors.lightRed.withValues(alpha: 0.15);
  static Color bookingChipBg(BuildContext context) =>
      AppColors.teal.withValues(alpha: 0.15);
}

/// Defines a complete color scheme for the application, tailored for
/// either light or dark mode.
///
/// This class encapsulates all the specific [Color] values required for various
/// UI elements (e.g., text, backgrounds, borders, accents) and provides a clear
/// interface for accessing them.
@immutable
class AppColorScheme {
  const AppColorScheme({
    required this.primary,
    required this.accent,
    required this.background,
    required this.phoneBackground, // Specific for phone mockup background
    required this.statusBarText,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.authGradientStart,
    required this.authGradientEnd,
    required this.authInputBackground,
    required this.authInputBorder,
    required this.cardBackground,
    required this.cardBorder,
    required this.cardBorderHover,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputFocusBackground,
    required this.tagBackground,
    required this.tagBorder,
    required this.hotBadgeBackground,
    required this.hotBadgeBorder,
    required this.headerBackground,
    required this.headerBorder,
    required this.contentGradientEnd,
    required this.scrollbarColorThumb,
    required this.bottomNavBackground,
    required this.bottomNavBorder,
    required this.bottomNavInactive,
    required this.divider,
    required this.taskGradientFrom,
    required this.glassCardGradient, // ADD THIS LINE
    required this.error,
    required this.isDark,
    this.success = Colors.green, // Default for now
    this.warning = Colors.orange, // Default for now
    this.info = Colors.blue, // Default for now
  });

  final Color primary;
  final Color accent;
  final Color background;
  final Color phoneBackground;
  final Color statusBarText;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color authGradientStart;
  final Color authGradientEnd;
  final Color authInputBackground;
  final Color authInputBorder;
  final Color cardBackground;
  final Color cardBorder;
  final Color cardBorderHover;
  final Color inputBackground;
  final Color inputBorder;
  final Color inputFocusBackground;
  final Color tagBackground;
  final Color tagBorder;
  final Color hotBadgeBackground;
  final Color hotBadgeBorder;
  final Color headerBackground;
  final Color headerBorder;
  final Color contentGradientEnd;
  final Color scrollbarColorThumb;
  final Color bottomNavBackground;
  final Color bottomNavBorder;
  final Color bottomNavInactive;
  final Color divider;
  final Color taskGradientFrom;
  final List<Color> glassCardGradient; // ADD THIS LINE
  final Color error;
  final Color success;
  final Color warning;
  final Color info;
  final bool isDark;

  static AppColorScheme lerp(AppColorScheme? a, AppColorScheme? b, double t) {
    if (a == null && b == null) {
      return AppColorScheme.light(); // Default to light if both are null
    }
    if (a == null) return b!;
    if (b == null) return a;
    return AppColorScheme(
      primary: Color.lerp(a.primary, b.primary, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      background: Color.lerp(a.background, b.background, t)!,
      phoneBackground: Color.lerp(a.phoneBackground, b.phoneBackground, t)!,
      statusBarText: Color.lerp(a.statusBarText, b.statusBarText, t)!,
      text: Color.lerp(a.text, b.text, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
      textTertiary: Color.lerp(a.textTertiary, b.textTertiary, t)!,
      authGradientStart: Color.lerp(
        a.authGradientStart,
        b.authGradientStart,
        t,
      )!,
      authGradientEnd: Color.lerp(a.authGradientEnd, b.authGradientEnd, t)!,
      authInputBackground: Color.lerp(
        a.authInputBackground,
        b.authInputBackground,
        t,
      )!,
      authInputBorder: Color.lerp(a.authInputBorder, b.authInputBorder, t)!,
      cardBackground: Color.lerp(a.cardBackground, b.cardBackground, t)!,
      cardBorder: Color.lerp(a.cardBorder, b.cardBorder, t)!,
      cardBorderHover: Color.lerp(a.cardBorderHover, b.cardBorderHover, t)!,
      inputBackground: Color.lerp(a.inputBackground, b.inputBackground, t)!,
      inputBorder: Color.lerp(a.inputBorder, b.inputBorder, t)!,
      inputFocusBackground: Color.lerp(
        a.inputFocusBackground,
        b.inputFocusBackground,
        t,
      )!,
      tagBackground: Color.lerp(a.tagBackground, b.tagBackground, t)!,
      tagBorder: Color.lerp(a.tagBorder, b.tagBorder, t)!,
      hotBadgeBackground: Color.lerp(
        a.hotBadgeBackground,
        b.hotBadgeBackground,
        t,
      )!,
      hotBadgeBorder: Color.lerp(a.hotBadgeBorder, b.hotBadgeBorder, t)!,
      headerBackground: Color.lerp(a.headerBackground, b.headerBackground, t)!,
      headerBorder: Color.lerp(a.headerBorder, b.headerBorder, t)!,
      contentGradientEnd: Color.lerp(
        a.contentGradientEnd,
        b.contentGradientEnd,
        t,
      )!,
      scrollbarColorThumb: Color.lerp(
        a.scrollbarColorThumb,
        b.scrollbarColorThumb,
        t,
      )!,
      bottomNavBackground: Color.lerp(
        a.bottomNavBackground,
        b.bottomNavBackground,
        t,
      )!,
      bottomNavBorder: Color.lerp(a.bottomNavBorder, b.bottomNavBorder, t)!,
      bottomNavInactive: Color.lerp(
        a.bottomNavInactive,
        b.bottomNavInactive,
        t,
      )!,
      divider: Color.lerp(a.divider, b.divider, t)!,
      taskGradientFrom: Color.lerp(a.taskGradientFrom, b.taskGradientFrom, t)!,
      glassCardGradient: List.generate(
        a.glassCardGradient.length,
        (index) => Color.lerp(
          a.glassCardGradient[index],
          b.glassCardGradient[index],
          t,
        )!,
      ),
      error: Color.lerp(a.error, b.error, t)!,
      success: Color.lerp(a.success, b.success, t)!,
      warning: Color.lerp(a.warning, b.warning, t)!,
      info: Color.lerp(a.info, b.info, t)!,
      isDark: t < 0.5
          ? (a.isDark)
          : (b.isDark), // Boolean lerp is not meaningful, pick based on interpolation factor
    );
  }

  /// Returns the light [AppColorScheme].
  factory AppColorScheme.light() {
    return AppColorScheme(
      primary: AppColors.teal,
      accent: AppColors.gold,
      background: AppColors.offWhite,
      phoneBackground: AppColors.offWhite,
      statusBarText: AppColors.almostBlack,
      text: AppColors.almostBlack,
      textSecondary: AppColors.mediumGrey,
      textTertiary: AppColors.darkerGrey,
      authGradientStart: AppColors.lightTealTransparent15,
      authGradientEnd: AppColors.offWhite,
      authInputBackground: AppColors.white,
      authInputBorder: AppColors.tealTransparent20,
      cardBackground: AppColors.white,
      cardBorder: AppColors.tealTransparent15,
      cardBorderHover: HexColor.fromHex(
        '#146068',
        opacity: 0.50,
      ), // border-[#146068]/50
      inputBackground: AppColors.white,
      inputBorder: AppColors.tealTransparent20,
      inputFocusBackground: AppColors.white,
      tagBackground: AppColors.white,
      tagBorder: AppColors.tealTransparent15,
      hotBadgeBackground: AppColors.goldTransparent20,
      hotBadgeBorder: AppColors.goldTransparent30,
      headerBackground: AppColors.lightTealTransparent15,
      headerBorder: AppColors.tealTransparent20,
      contentGradientEnd: AppColors.offWhite,
      scrollbarColorThumb: AppColors.lightTeal,
      bottomNavBackground: AppColors.lightTealTransparent15,
      bottomNavBorder: AppColors.tealTransparent20,
      bottomNavInactive: AppColors.mediumGrey,
      divider: AppColors.tealTransparent15,
      taskGradientFrom: AppColors.almostBlackTransparent40,
      glassCardGradient: AppColors.glassCardGradientLight,
      error: AppColors.lightRed,
      isDark: false,
    );
  }

  /// Returns the dark [AppColorScheme].
  factory AppColorScheme.dark() {
    return AppColorScheme(
      primary: AppColors.teal,
      accent: AppColors.gold,
      background: AppColors.almostBlack,
      phoneBackground: AppColors.almostBlack,
      statusBarText: AppColors.offWhite,
      text: AppColors.offWhite,
      textSecondary: AppColors.mediumGreyBlue,
      textTertiary: AppColors.mediumGrey,
      authGradientStart: AppColors.tealTransparent5,
      authGradientEnd: AppColors.almostBlack,
      authInputBackground: AppColors.offWhiteTransparent10,
      authInputBorder: AppColors.lightTealTransparent20,
      cardBackground: AppColors.offWhiteTransparent8,
      cardBorder: HexColor.fromHex(
        '#93ccce',
        opacity: 0.10,
      ), // border-[#93ccce]/10
      cardBorderHover: AppColors.tealTransparent40, // border-[#146068]/40
      inputBackground: AppColors.offWhiteTransparent10,
      inputBorder: AppColors.lightTealTransparent20,
      inputFocusBackground: AppColors.offWhiteTransparent15,
      tagBackground: AppColors.offWhiteTransparent10,
      tagBorder: HexColor.fromHex(
        '#93ccce',
        opacity: 0.10,
      ), // border-[#93ccce]/10
      hotBadgeBackground: AppColors.goldTransparent20,
      hotBadgeBorder: AppColors.goldTransparent30,
      headerBackground: AppColors.tealTransparent20,
      headerBorder: AppColors.lightTealTransparent20,
      contentGradientEnd: AppColors.almostBlackTransparent70,
      scrollbarColorThumb: AppColors.teal,
      bottomNavBackground: AppColors.tealTransparent20,
      bottomNavBorder: AppColors.lightTealTransparent20,
      bottomNavInactive: AppColors.mediumGreyBlue,
      divider: AppColors.lightTealTransparent20,
      taskGradientFrom: AppColors.almostBlackTransparent60,
      glassCardGradient: AppColors.glassCardGradientDark,
      error: AppColors.lightRed,
      isDark: true,
    );
  }
}
