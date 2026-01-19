import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_theme.dart';

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final double iconSize;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
