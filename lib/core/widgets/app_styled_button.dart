import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/scale_button.dart';

/// A styled button with primary/secondary variants, solid surface.
///
/// ## NO GLASS POLICY (see .impeccable.md)
///
/// All [BackdropFilter] blur has been removed. The button now uses
/// solid colors from [AppColorScheme] for both primary and secondary styles.
///
/// ## Phase 1 Changes
/// - Removed ALL BackdropFilter / glass effects
/// - Primary: solid primary color background + white text
/// - Secondary: solid cardBackground + primary text + border
/// - Disabled opacity from [AppInteractionStates.disabledOpacity]
/// - Added [disabled] parameter forwarded to [ScaleButton]
/// - Added [Semantics] wrapper
/// - All existing constructor params preserved (backward compatible)
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
    this.height = 48,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isInactive = onPressed == null || disabled || isLoading;
    final opacity = isInactive ? AppInteractionStates.disabledOpacity : 1.0;

    final effectiveBg = isPrimary
        ? colorScheme.primary
        : colorScheme.cardBackground;
    final effectiveFg = isPrimary ? AppColors.white : colorScheme.text;
    final effectiveBorder = isPrimary
        ? colorScheme.primary
        : colorScheme.cardBorder;

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
            Icon(icon, size: 18, color: effectiveFg),
            const SizedBox(width: AppDimens.p8),
          ],
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: effectiveFg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    Widget button = Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(AppDimens.r12),
          border: Border.all(color: effectiveBorder, width: 1),
          boxShadow: isInactive
              ? AppDecorations.elevation(0)
              : AppDecorations.elevation(1, isDark: colorScheme.isDark),
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
