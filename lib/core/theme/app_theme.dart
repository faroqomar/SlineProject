import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

/// A custom [ThemeExtension] to provide easy access to the [AppColorScheme]
/// within the widget tree using `Theme.of(context).extension<AppThemeExtension>()`.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({required this.colors});

  final AppColorScheme colors;

  @override
  AppThemeExtension copyWith({AppColorScheme? colors}) {
    return AppThemeExtension(colors: colors ?? this.colors);
  }

  @override
  AppThemeExtension lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      colors: AppColorScheme.lerp(colors, other.colors, t),
    );
  }
}

/// Theme extension for animated skeleton placeholder colors.
///
/// Skeleton primitives read this extension so loading colors follow the active
/// app theme instead of importing a named design system directly.
@immutable
class SkeletonColors extends ThemeExtension<SkeletonColors> {
  const SkeletonColors({required this.base, required this.highlight});

  /// Base fill color for skeleton placeholders.
  final Color base;

  /// Moving shimmer highlight color.
  final Color highlight;

  @override
  SkeletonColors copyWith({Color? base, Color? highlight}) {
    return SkeletonColors(
      base: base ?? this.base,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  SkeletonColors lerp(
    covariant ThemeExtension<SkeletonColors>? other,
    double t,
  ) {
    if (other is! SkeletonColors) {
      return this;
    }
    return SkeletonColors(
      base: Color.lerp(base, other.base, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
    );
  }
}

/// Defines the main [ThemeData] for the application, providing both
/// light and dark themes.
///
/// This class integrates [AppColors], [AppTypography], and [AppDimens]
/// to create a consistent and customizable visual style for the entire app.
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  /// Returns the light [ThemeData] for the application.
  static ThemeData light() {
    final lightColorScheme = AppColorScheme.light();
    return _buildTheme(lightColorScheme, AmberDuskTokens.widgetTheme);
  }

  /// Returns the dark [ThemeData] for the application.
  static ThemeData dark() {
    final darkColorScheme = AppColorScheme.dark();
    return _buildTheme(darkColorScheme, AmberDuskTokens.widgetTheme);
  }

  /// Builds a [ThemeData] instance based on the provided [AppColorScheme].
  static ThemeData _buildTheme(
    AppColorScheme appColorScheme,
    AmberDuskWidgetThemeTokens widgetTheme,
  ) {
    final isDark = appColorScheme.isDark;
    final tabTheme = widgetTheme.tabs;
    final skeletonTheme = widgetTheme.skeleton;

    return ThemeData(
      // Core Material 3 ColorScheme, derived from a seed color for harmony
      colorScheme: ColorScheme.fromSeed(
        seedColor: appColorScheme.primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: appColorScheme.primary,
        secondary: appColorScheme.accent,
        surface: appColorScheme.background, // Changed from background
        error: appColorScheme.error,
        onPrimary: isDark ? AppColors.almostBlack : AppColors.white,
        onSurface: appColorScheme.text, // Changed from onBackground
        onError: AppColors.white,
      ),
      useMaterial3: true,
      fontFamilyFallback: AppTypography.fontFamilyFallback,

      // Custom TextTheme
      textTheme: TextTheme(
        displayLarge: AppTypography.h1.copyWith(color: appColorScheme.text),
        displayMedium: AppTypography.h2.copyWith(color: appColorScheme.text),
        displaySmall: AppTypography.h3.copyWith(color: appColorScheme.text),
        headlineLarge: AppTypography.h4.copyWith(color: appColorScheme.text),
        headlineMedium: AppTypography.h5.copyWith(color: appColorScheme.text),
        headlineSmall: AppTypography.h6.copyWith(color: appColorScheme.text),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: appColorScheme.text),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: appColorScheme.text,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: appColorScheme.textSecondary,
        ),
        labelLarge: AppTypography.captionBold.copyWith(
          color: appColorScheme.primary,
        ),
        labelMedium: AppTypography.caption.copyWith(
          color: appColorScheme.textSecondary,
        ),
        labelSmall: AppTypography.overline.copyWith(
          color: appColorScheme.textTertiary,
        ),
        titleLarge: AppTypography.bodyLarge.copyWith(
          color: appColorScheme.text,
        ),
        titleMedium: AppTypography.bodyMedium.copyWith(
          color: appColorScheme.text,
        ),
        titleSmall: AppTypography.bodySmall.copyWith(
          color: appColorScheme.text,
        ),
      ),

      // Scaffold background (main screen background)
      scaffoldBackgroundColor: appColorScheme.background,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: appColorScheme.headerBackground,
        foregroundColor: appColorScheme.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h5.copyWith(color: appColorScheme.text),
        iconTheme: IconThemeData(color: appColorScheme.text),
      ),

      // ElevatedButton Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: appColorScheme.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.r14),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p24,
            vertical: AppDimens.p16,
          ),
          textStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          elevation: 5, // Matching some design elements
          shadowColor: appColorScheme.primary.withValues(alpha: 0.3),
        ),
      ),

      // Input Decoration Theme (for TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: appColorScheme.inputBackground,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: appColorScheme.textSecondary,
        ),
        labelStyle: AppTypography.bodySmall.copyWith(
          color: appColorScheme.text,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p16,
          vertical: AppDimens.p14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r14),
          borderSide: BorderSide(color: appColorScheme.inputBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r14),
          borderSide: BorderSide(color: appColorScheme.inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r14),
          borderSide: BorderSide(
            color: appColorScheme.primary,
            width: 1.5,
          ), // Focus color from React
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r14),
          borderSide: BorderSide(color: appColorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r14),
          borderSide: BorderSide(color: appColorScheme.error, width: 2.0),
        ),
      ),

      // ── Component Themes (Phase 0 — Design System Foundation) ──

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.r16),
        ),
        color: appColorScheme.cardBackground,
        margin: EdgeInsets.zero,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.r24),
        ),
        backgroundColor: appColorScheme.cardBackground,
        elevation: 0,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: appColorScheme.cardBackground,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: appColorScheme.divider,
        dragHandleSize: const Size(32, 4),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        backgroundColor: Colors.transparent,
        side: BorderSide(color: appColorScheme.divider, width: 0.5),
        labelStyle: AppTypography.captionBold.copyWith(
          color: appColorScheme.text,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p12,
          vertical: AppDimens.p4,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: appColorScheme.divider,
        thickness: 0.5,
        space: 0,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: appColorScheme.text,
        contentTextStyle: AppTypography.bodySmall.copyWith(
          color: appColorScheme.phoneBackground,
        ),
      ),

      // TabBar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: tabTheme.activeLabelColor,
        unselectedLabelColor: tabTheme.inactiveLabelColor,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: tabTheme.indicatorColor,
            width: tabTheme.indicatorThickness,
          ),
          borderRadius: BorderRadius.circular(tabTheme.indicatorRadius),
        ),
        labelStyle: tabTheme.labelStyle.copyWith(
          color: tabTheme.activeLabelColor,
        ),
        unselectedLabelStyle: tabTheme.inactiveLabelStyle.copyWith(
          color: tabTheme.inactiveLabelColor,
        ),
      ),

      // TextButton Theme (Phase 1 — deferred from Phase 0 LOW-2)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: appColorScheme.primary,
          textStyle: AppTypography.bodyMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.r14),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p16,
            vertical: AppDimens.p12,
          ),
        ),
      ),

      // OutlinedButton Theme (Phase 1 — deferred from Phase 0 LOW-2)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: appColorScheme.primary,
          side: BorderSide(color: appColorScheme.primary, width: 1),
          textStyle: AppTypography.bodyMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.r14),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p16,
            vertical: AppDimens.p12,
          ),
        ),
      ),

      // Extensions
      extensions: <ThemeExtension<dynamic>>[
        AppThemeExtension(colors: appColorScheme),
        SkeletonColors(
          base: skeletonTheme.base,
          highlight: skeletonTheme.highlight,
        ),
      ],
    );
  }
}

// Helper to access custom theme extension
extension BuildContextExtension on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>()!;
  AppColorScheme get colorScheme => appTheme.colors;
  TextTheme get appTextTheme => Theme.of(this).textTheme;
}
