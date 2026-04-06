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
    double borderWidth =
        1.0, // This border is likely to be a BoxShadow or part of the gradient
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(AppDimens.r20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colorScheme.glassCardGradient,
      ),
      border: Border.all(color: colorScheme.cardBorder, width: borderWidth),
      boxShadow: [
        // 1px border-like shadow
        BoxShadow(
          color: colorScheme.isDark
              ? AppColors.white.withValues(alpha: 0.1) // rgba(255,255,255,0.1)
              : AppColors.almostBlack.withValues(
                  alpha: 0.05,
                ), // rgba(0,0,0,0.05)
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
  /// This implements the liquid glass effect from the new design with:
  /// - Gradient backgrounds (top to bottom)
  /// - Inset-like shadows for depth
  /// - Enhanced border styling
  /// - Outer shadow for elevation
  static BoxDecoration bottomNavBarDecoration({
    required AppColorScheme colorScheme,
  }) {
    // Liquid glass gradient colors from new design
    final gradientColors = colorScheme.isDark
        ? [
            // Dark mode: rgba(20, 96, 104, 0.2) to rgba(0, 0, 0, 0.4)
            AppColors.teal.withValues(alpha: 0.2),
            AppColors.almostBlack.withValues(alpha: 0.4),
          ]
        : [
            // Light mode: rgba(255, 255, 255, 0.7) to rgba(255, 255, 255, 0.4)
            AppColors.white.withValues(alpha: 0.7),
            AppColors.white.withValues(alpha: 0.4),
          ];

    // Border color from new design
    final borderColor = colorScheme.isDark
        ? AppColors.white.withValues(alpha: 0.08) // rgba(255,255,255,0.08)
        : AppColors.white.withValues(alpha: 0.6); // rgba(255,255,255,0.6)

    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppDimens.r30),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ),
      border: Border.all(color: borderColor, width: 1.0),
      boxShadow: [
        // Outer shadow for elevation
        BoxShadow(
          color: colorScheme.isDark
              ? AppColors.almostBlack.withValues(
                  alpha: 0.5,
                ) // 0 20px 40px -10px rgba(0,0,0,0.5)
              : AppColors.lightTeal.withValues(
                  alpha: 0.4,
                ), // 0 20px 40px -10px rgba(147, 204, 206, 0.4)
          blurRadius: 40.0,
          spreadRadius: -10.0,
          offset: const Offset(0, 20),
        ),
        // Top inset-like shadow (simulated with inner glow)
        // Note: Flutter doesn't support inset shadows, so we use a subtle inner border effect
        BoxShadow(
          color: colorScheme.isDark
              ? AppColors.white.withValues(
                  alpha: 0.1,
                ) // inset 0 1px 0 rgba(255,255,255,0.1)
              : AppColors.white.withValues(
                  alpha: 0.8,
                ), // inset 0 1px 0 rgba(255,255,255,0.8)
          blurRadius: 0,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
        // Bottom inset-like shadow
        BoxShadow(
          color: colorScheme.isDark
              ? AppColors.almostBlack.withValues(
                  alpha: 0.2,
                ) // inset 0 -1px 0 rgba(0,0,0,0.2)
              : Colors.transparent, // No bottom inset in light mode
          blurRadius: 0,
          spreadRadius: 0,
          offset: const Offset(0, -1),
        ),
      ],
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
}
