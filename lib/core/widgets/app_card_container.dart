import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

/// A reusable container with solid background, subtle border, and elevation shadow.
///
/// ## NO GLASS POLICY (see .impeccable.md)
///
/// This widget was previously a glassmorphism container with [BackdropFilter] blur.
/// As of Phase 1 (Core Widget Redesign), ALL glass effects have been removed.
/// The widget now renders as a solid-surface container using:
/// - `AmberDuskTokens.widgetTheme.cards.panel` for background and radius
/// - `AmberDuskTokens.widgetTheme.cards.borderWidth` for borderless cards
/// - [AppDecorations.elevation] for shadow depth
///
/// The widget name is kept as `AppCardContainer` for backward compatibility
/// with existing feature code (21+ files use it). The API is backward-compatible:
/// `child`, `padding`, `margin`, `borderRadius` parameters are unchanged.
///
/// The `blurRadius` parameter is deprecated and ignored.
///
/// The [elevation] default now comes from Amber Dusk while the public field
/// stays non-null for compatibility with existing call sites.
class AppCardContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  /// Elevation level for the shadow.
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
    this.elevation = AmberDuskWidgetTheme.panelCardElevationLevel,
    @Deprecated('Glass blur removed. Use elevation instead.') this.blurRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    final panelRecipe = cardTheme.panel;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(panelRecipe.radius);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: panelRecipe.background,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: cardTheme.border,
          width: cardTheme.borderWidth,
        ),
        boxShadow: AppDecorations.elevation(
          elevation,
          isDark: colorScheme.isDark,
        ),
      ),
      child: child,
    );
  }
}
