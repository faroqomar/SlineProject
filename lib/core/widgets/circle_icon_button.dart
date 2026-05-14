import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/scale_button.dart';

/// A circular icon button with haptic feedback and accessibility support.
///
/// ## Phase 1 Changes
/// - Wrapped in [ScaleButton] for press feedback + haptics
/// - Added [tooltip] optional parameter
/// - Added [Semantics] with button role and label
/// - Enforces minimum 48px touch target (WCAG guideline)
/// - Amber Dusk icon-button tokens now provide the 42px visual size, text
///   icon color, solid surface, and borderless treatment.
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final double iconSize;
  final double borderWidth;

  /// Optional tooltip text. Also used as the Semantics label.
  final String? tooltip;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.size = AmberDuskWidgetTheme.iconButtonSize,
    this.iconSize = AmberDuskWidgetTheme.iconButtonIconSize,
    this.borderWidth = AmberDuskSpacing.borderWidth,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final iconButtonTheme = AmberDuskTokens.widgetTheme.iconButtons;

    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? iconButtonTheme.background,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? iconButtonTheme.border,
          width: borderWidth,
        ),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor ?? iconButtonTheme.foreground,
      ),
    );

    // Wrap in ScaleButton for press feedback + haptics
    button = ScaleButton(
      onPressed: () {
        AppInteractionStates.hapticTap();
        onTap();
      },
      callbackDelay: Duration.zero, // Immediate for icon buttons
      child: button,
    );

    // Enforce minimum touch target per WCAG (48dp)
    if (size < AppLayout.minTouchTarget) {
      button = SizedBox(
        width: AppLayout.minTouchTarget,
        height: AppLayout.minTouchTarget,
        child: Center(child: button),
      );
    }

    // Tooltip
    if (tooltip case final tip?) {
      button = Tooltip(message: tip, child: button);
    }

    // Semantics
    return Semantics(button: true, label: tooltip ?? '', child: button);
  }
}
