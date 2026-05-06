import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';

/// Defines reusable [BoxDecoration] styles and elevation shadows.
///
/// Provides static methods for consistent visual styling across the app.
/// All glass/blur effects have been removed per NO GLASS POLICY.
class AppDecorations {
  AppDecorations._();

  /// Returns a [BoxDecoration] for input fields.
  static BoxDecoration inputFieldDecoration({
    required AppColorScheme colorScheme,
    BorderRadius? borderRadius,
    Color? overrideBorderColor,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(AppDimens.r14),
      color: colorScheme.inputBackground,
      border: Border.all(
        color: overrideBorderColor ?? colorScheme.inputBorder,
        width: 1.5,
      ),
    );
  }

  /// Returns a [BoxDecoration] for a hot badge.
  static BoxDecoration hotBadgeDecoration({
    required AppColorScheme colorScheme,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(AppDimens.r8),
      color: colorScheme.hotBadgeBackground,
      border: Border.all(color: colorScheme.hotBadgeBorder, width: 1.0),
    );
  }

  /// Returns a [BoxDecoration] for an author initial circle.
  static BoxDecoration authorInitialsDecoration({
    required Color bgColor,
    double size = AppDimens.p40,
    double borderWidth = 2.0,
    required AppColorScheme colorScheme,
  }) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: bgColor,
      border: Border.all(
        color: colorScheme.phoneBackground.withValues(alpha: 0.2),
        width: borderWidth,
      ),
    );
  }

  // ── Elevation Scale ──────────────────────────────────────────

  /// Returns a list of [BoxShadow]s for the given elevation [level].
  ///
  /// | Level | Name     | Use Case                                |
  /// |-------|----------|-----------------------------------------|
  /// | 0     | Flat     | Items at rest in a scrolling list        |
  /// | 1     | Resting  | Default cards, tiles                     |
  /// | 2     | Raised   | Hovered/focused cards, active states     |
  /// | 3     | Floating | Modals, FAB, dragged items               |
  /// | 4     | Dramatic | Popovers, dropdowns, elevated dialogs    |
  ///
  /// Set [isDark] to `true` for dark mode — shadows use reduced alpha.
  static List<BoxShadow> elevation(int level, {bool isDark = false}) {
    final multiplier = isDark ? 0.3 : 1.0;

    switch (level) {
      case 0:
        return const [];
      case 1:
        return [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06 * multiplier),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];
      case 2:
        return [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08 * multiplier),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      case 3:
        return [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12 * multiplier),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
      case 4:
        return [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.16 * multiplier),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];
      default:
        return elevation(1, isDark: isDark);
    }
  }
}
