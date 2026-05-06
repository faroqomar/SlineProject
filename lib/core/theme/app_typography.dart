import 'package:flutter/material.dart';

/// Defines the typography for the entire application, consistent with the design system.
///
/// This class provides static [TextStyle] getters for various text elements
/// (e.g., headings, body text, captions), using the 'Plus Jakarta Sans' font
/// and specific font sizes and weights inferred from the design.
///
/// ## Line Height Strategy
/// - **Headings (logo–h6):** Tight (1.0–1.25) for visual impact.
/// - **Body (bodyLarge–bodySmall):** Comfortable (1.4–1.5) for readability.
/// - **Captions/Utility:** Moderate (1.2–1.3) for scannability.
///
/// ## Letter Spacing Strategy
/// - **Large headings (h1–h3):** Negative (-0.5 to -0.3) to tighten display text.
/// - **Body text:** Zero — default tracking is optimal.
/// - **Small text (caption, overline, micro):** Positive (0.1–1.5) to improve readability at small sizes.
class AppTypography {
  AppTypography._(); // Private constructor to prevent instantiation

  static const List<String> fontFamilyFallback = <String>[
    'Noto Sans',
    'Noto Sans Arabic',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  // Base text style — height is intentionally omitted so each style
  // defines its own context-appropriate line height.
  static const TextStyle _baseTextStyle = TextStyle(
    fontWeight: FontWeight.normal,
    fontFamilyFallback: fontFamilyFallback,
  );

  // --- Headings ---

  /// Logo size (used in auth screen). Tight line height for display.
  static TextStyle get logo => _baseTextStyle.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: -0.5,
  );

  static TextStyle get h1 => _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static TextStyle get h2 => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    height: 1.15,
    letterSpacing: -0.4,
  );

  static TextStyle get h3 => _baseTextStyle.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static TextStyle get h4 => _baseTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.2,
  );

  static TextStyle get h5 => _baseTextStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  /// Subtitle (17px — used in modals).
  static TextStyle get subtitle => _baseTextStyle.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle get h6 => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  // --- Body Text ---

  static TextStyle get bodyLarge => _baseTextStyle.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static TextStyle get bodyMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle get bodySmall => _baseTextStyle.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // --- Utility & Caption ---

  static TextStyle get caption => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
    letterSpacing: 0.2,
  );

  static TextStyle get captionBold => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.2,
  );

  static TextStyle get overline => _baseTextStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 1.5,
  );

  static TextStyle get micro => _baseTextStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.3,
  );
}
