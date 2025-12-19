import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Defines the typography for the entire application, consistent with the design system.
///
/// This class provides static [TextStyle] getters for various text elements
/// (e.g., headings, body text, captions), using the 'Plus Jakarta Sans' font
/// and specific font sizes and weights inferred from the design.
class AppTypography {
  AppTypography._(); // Private constructor to prevent instantiation

  // Base text style, all other styles will derive from this
  static final TextStyle _baseTextStyle = GoogleFonts.plusJakartaSans(
    fontWeight: FontWeight.normal,
    height: 1.2, // Default line height
  );

  // --- Headings ---
  // Logo size (used in auth screen)
  static TextStyle get logo => _baseTextStyle.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w900, // Extrabold from design
    letterSpacing: -0.5,
  );

  static TextStyle get h1 => _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w900, // Extrabold from design
    letterSpacing: -0.5,
  );

  static TextStyle get h2 => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w900, // Extrabold from design
    letterSpacing: -0.4,
  );

  static TextStyle get h3 => _baseTextStyle.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w800, // Extrabold/Black from design
    letterSpacing: -0.3,
  );

  static TextStyle get h4 => _baseTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w800, // Extrabold from design
    letterSpacing: -0.2,
  );

  static TextStyle get h5 => _baseTextStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700, // Bold from design
  );

  // Subtitle (17px from design - used in modals)
  static TextStyle get subtitle => _baseTextStyle.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700, // Bold from design
  );

  static TextStyle get h6 => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w800, // Extrabold from design
  );

  // --- Body Text ---
  static TextStyle get bodyLarge => _baseTextStyle.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w500, // Medium from design
  );

  static TextStyle get bodyMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal, // Regular from design
  );

  static TextStyle get bodySmall => _baseTextStyle.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w500, // Medium from design
  );

  // --- Utility & Caption ---
  static TextStyle get caption => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal, // Regular from design
  );

  static TextStyle get captionBold => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700, // Bold from design
  );

  static TextStyle get overline => _baseTextStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600, // Semibold from design
  );

  static TextStyle get micro => _baseTextStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500, // Medium from design
  );
}
