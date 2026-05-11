import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/scale_button.dart';

/// A styled button with primary/ghost variants, solid surface.
///
/// ## NO GLASS POLICY (see .impeccable.md)
///
/// All [BackdropFilter] blur has been removed. The button now uses
/// solid Amber Dusk adapter colors for primary and ghost styles.
///
/// ## Phase 1 Changes
/// - Removed ALL BackdropFilter / glass effects
/// - Primary: solid Amber primary background + cream text
/// - Ghost: low-opacity quiet action surface + cream text
/// - Disabled opacity from [AppInteractionStates.disabledOpacity]
/// - Added [disabled] parameter forwarded to [ScaleButton]
/// - Added [Semantics] wrapper
/// - Amber Dusk tokens now provide default geometry and variant colors.
///
/// The [height] default now comes from Amber Dusk while the public field stays
/// non-null for compatibility with existing call sites.
class AppStyledButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isLoading;
  final double? width;
  final double height;

  /// When true, disables interaction and applies reduced opacity.
  final bool disabled;

  const AppStyledButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isLoading = false,
    this.width,
    this.height = AmberDuskWidgetTheme.buttonMinHeight,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final buttonTheme = AmberDuskTokens.widgetTheme.buttons;
    final buttonRecipe = isPrimary ? buttonTheme.primary : buttonTheme.ghost;
    final isInactive = onPressed == null || disabled || isLoading;
    final opacity = isInactive ? AppInteractionStates.disabledOpacity : 1.0;

    final effectiveBg = buttonRecipe.background;
    final effectiveFg = buttonRecipe.foreground;
    final tokenTextStyle = buttonTheme.textStyle;
    final finalTextStyle = tokenTextStyle.color == null
        ? tokenTextStyle.copyWith(color: effectiveFg)
        : tokenTextStyle;

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: AppInteractionStates.loadingSize,
        height: AppInteractionStates.loadingSize,
        child: CircularProgressIndicator(
          strokeWidth: AppInteractionStates.loadingStrokeWidth,
          color: effectiveFg,
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            // The button recipe owns icon sizing so compact CTAs stay aligned
            // with the Amber Dusk control system.
            Icon(icon, size: buttonTheme.iconSize, color: effectiveFg),
            SizedBox(width: AmberDuskTokens.spacing.sm),
          ],
          Text(text, style: finalTextStyle),
        ],
      );
    }

    Widget button = Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        padding: buttonTheme.padding,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(buttonTheme.radius),
          boxShadow: AppDecorations.elevation(
            isInactive
                ? buttonTheme.inactiveElevationLevel
                : buttonTheme.activeElevationLevel,
            isDark: colorScheme.isDark,
          ),
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );

    button = ScaleButton(
      onPressed: isInactive ? null : onPressed,
      disabled: disabled,
      child: button,
    );

    return Semantics(
      button: true,
      label: text,
      enabled: !isInactive,
      child: button,
    );
  }
}
