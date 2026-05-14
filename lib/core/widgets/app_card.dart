import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/scale_button.dart';

/// A tappable card with solid background, border, and elevation shadow.
///
/// ## NO GLASS POLICY (see .impeccable.md)
///
/// This widget wraps [AppCardContainer] (now a solid-surface container) with
/// optional [ScaleButton] for press feedback. All glass/blur effects have
/// been removed.
///
/// ## Phase 1 Redesign Changes
/// - Inherits solid surface from [AppCardContainer] (no glass)
/// - Inherits haptics + AppMotion tokens from [ScaleButton]
/// - Added [elevation] parameter for shadow depth
/// - Added [disabled] parameter forwarded to [ScaleButton]
/// - Added [Semantics] container wrapper
/// - Amber Dusk tokens now provide the default task-card radius and depth.
///
/// The [elevation] default now comes from Amber Dusk while the public field
/// stays non-null for compatibility with existing call sites.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  /// Elevation level for the shadow.
  final int elevation;

  /// When true, disables tap interaction and applies reduced opacity.
  /// Forwarded to [ScaleButton.disabled].
  final bool disabled;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.elevation = AmberDuskWidgetTheme.taskCardElevationLevel,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    var result = _buildContainer();

    if (onTap != null) {
      result = ScaleButton(onPressed: onTap, disabled: disabled, child: result);
    }

    return Semantics(container: true, child: result);
  }

  Widget _buildContainer() {
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    final taskRecipe = cardTheme.task;

    return SizedBox(
      width: width,
      height: height,
      child: AppCardContainer(
        padding: padding ?? EdgeInsets.all(AmberDuskTokens.spacing.lg),
        margin: margin,
        borderRadius: borderRadius ?? BorderRadius.circular(taskRecipe.radius),
        elevation: elevation,
        child: child,
      ),
    );
  }
}
