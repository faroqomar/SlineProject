import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/widgets/scale_button.dart';

/// A circular icon button with haptic feedback and accessibility support.
///
/// ## Phase 1 Changes
/// - Wrapped in [ScaleButton] for press feedback + haptics
/// - Added [tooltip] optional parameter
/// - Added [Semantics] with button role and label
/// - Enforces minimum 48px touch target (WCAG guideline)
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final double iconSize;

  /// Optional tooltip text. Also used as the Semantics label.
  final String? tooltip;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.size = 40,
    this.iconSize = 20,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor ?? colorScheme.cardBorder),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor ?? colorScheme.textSecondary,
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

    // Enforce minimum 48px touch target per WCAG
    if (size < 48) {
      button = SizedBox(width: 48, height: 48, child: Center(child: button));
    }

    // Tooltip
    if (tooltip case final tip?) {
      button = Tooltip(message: tip, child: button);
    }

    // Semantics
    return Semantics(button: true, label: tooltip ?? '', child: button);
  }
}
