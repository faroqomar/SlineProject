import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';

/// A reusable container with solid background, subtle border, and elevation shadow.
///
/// ## NO GLASS POLICY (see .impeccable.md)
///
/// This widget was previously a glassmorphism container with [BackdropFilter] blur.
/// As of Phase 1 (Core Widget Redesign), ALL glass effects have been removed.
/// The widget now renders as a solid-surface container using:
/// - `colorScheme.cardBackground` for background
/// - `colorScheme.cardBorder` for border
/// - [AppDecorations.elevation] for shadow depth
///
/// The widget name is kept as `AppCardContainer` for backward compatibility
/// with existing feature code (21+ files use it). The API is backward-compatible:
/// `child`, `padding`, `margin`, `borderRadius` parameters are unchanged.
///
/// The `blurRadius` parameter is deprecated and ignored.
class AppCardContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  /// Elevation level for the shadow. Defaults to 1 (resting).
  /// See [AppDecorations.elevation] for levels 0-4.
  final int elevation;

  /// Deprecated — ignored. Glass blur has been removed per NO GLASS POLICY.
  @Deprecated('Glass blur removed in Phase 1. Use elevation parameter instead.')
  final double? blurRadius;

  const AppCardContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation = 1,
    @Deprecated('Glass blur removed. Use elevation instead.')
    this.blurRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppDimens.r20);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: effectiveRadius,
        border: Border.all(color: colorScheme.cardBorder, width: 1),
        boxShadow: AppDecorations.elevation(
          elevation,
          isDark: colorScheme.isDark,
        ),
      ),
      child: child,
    );
  }
}
