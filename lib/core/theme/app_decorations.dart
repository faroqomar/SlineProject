import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';

/// Defines reusable [BoxDecoration] styles and other visual embellishments
/// for consistent application across the app, especially for Glassmorphism effects.
///
/// This class provides static methods that return [BoxDecoration] instances,
/// parameterizing them with the current [AppColorScheme] to adapt to
/// light and dark themes.
class AppDecorations {
  AppDecorations._(); // Private constructor to prevent instantiation

  /// Returns a [BoxDecoration] for a general glassmorphism container.
  ///
  /// This decoration includes a subtle gradient background, a border, and
  /// a multi-layered shadow, all adapting to the provided [colorScheme].
  static BoxDecoration glassBoxDecoration({
    required AppColorScheme colorScheme,
    BorderRadius? borderRadius,
    double borderWidth = 1.0, // This border is likely to be a BoxShadow or part of the gradient
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(AppDimens.r20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colorScheme.glassCardGradient,
      ),
      border: Border.all(
        color: colorScheme.cardBorder,
        width: borderWidth,
      ),
      boxShadow: [
        // 1px border-like shadow
        BoxShadow(
          color: colorScheme.isDark
              ? AppColors.white.withValues(alpha: 0.1) // rgba(255,255,255,0.1)
              : AppColors.almostBlack.withValues(alpha: 0.05), // rgba(0,0,0,0.05)
          spreadRadius: 0,
          blurRadius: 0,
          offset: Offset.zero,
        ),
        // Main shadow
        BoxShadow(
          color: colorScheme.isDark
              ? AppColors.almostBlack.withValues(alpha: 0.5) // rgba(0,0,0,0.5)
              : AppColors.almostBlack.withValues(alpha: 0.2), // rgba(0,0,0,0.2)
          blurRadius: 60.0,
          spreadRadius: -10.0,
          offset: const Offset(0, 30),
        ),
      ],
    );
  }

  /// Returns a [BoxDecoration] specifically for the floating bottom navigation bar.
  ///
  /// This mimics the `bottomNavBg` style from the React design, including
  /// a gradient and a subtle border.
  static BoxDecoration bottomNavBarDecoration({
    required AppColorScheme colorScheme,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppDimens.r30),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colorScheme.bottomNavBackground,
          colorScheme.bottomNavBackground.withValues(alpha: 0.6),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.isDark
              ? AppColors.almostBlack.withValues(alpha: 0.5)
              : AppColors.lightTeal.withValues(alpha: 0.4), // from React design
          blurRadius: 40.0,
          spreadRadius: -10.0,
          offset: const Offset(0, 20),
        ),
      ],
      border: Border.all(
        color: colorScheme.bottomNavBorder,
        width: 1.0,
      ),
    );
  }

  /// Returns a [BoxDecoration] for input fields.
  ///
  /// This decoration provides the translucent background and border defined
  /// in the design system.
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
      border: Border.all(
        color: colorScheme.hotBadgeBorder,
        width: 1.0,
      ),
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
}
