/// What: Theme-aware color helpers for consistent surfaces, borders, and chips.
/// Why: Centralizes color logic so widgets adapt correctly to light/dark modes.
library;
import 'package:flutter/material.dart';

/// Centralized app colors used across widgets.
/// We keep light/dark aware helpers so cards look good on both themes.
class AppColors {
  // Base hues (do not use directly in widgets; prefer helpers below)
  static const _tenderBase = Color(0xFFEEF7FF); // soft blue tint
  static const _bookingBase = Color(0xFFFFF5EA); // soft orange/peach tint

  static const _tenderBaseDark = Color(0xFF0F2636); // deep desaturated blue
  static const _bookingBaseDark = Color(0xFF2E1F12); // deep warm brown

  /// Surface background for Tender task cards
  static Color tenderCardBg(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? _tenderBaseDark : _tenderBase;
    }

  /// Surface background for Booking task cards
  static Color bookingCardBg(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? _bookingBaseDark : _bookingBase;
  }

  /// Subtle border color depending on theme; optional accent per type
  static Color tenderBorder(BuildContext context) {
    final theme = Theme.of(context);
    return theme.dividerColor.withValues(alpha: 0.25);
  }

  static Color bookingBorder(BuildContext context) {
    final theme = Theme.of(context);
    return theme.dividerColor.withValues(alpha: 0.25);
  }

  /// Text chip background accents (very subtle)
  static Color tenderChipBg(BuildContext context) {
    return tenderCardBg(context).withValues(alpha: 0.6);
  }

  static Color bookingChipBg(BuildContext context) {
    return bookingCardBg(context).withValues(alpha: 0.6);
  }
}
