import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';

/// A customizable application button with primary and secondary styles,
/// supporting a loading state.
///
/// This widget mimics the button styles from the React design, including
/// specific dimensions, rounded corners, text styling, and elevation/shadow.
class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isPrimary;
  final double? width;
  final double? height;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isPrimary = true,
    this.width,
    this.height,
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.boxShadow,
    this.borderRadius,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final TextTheme textTheme = context.appTextTheme;

    // Determine colors based on primary/secondary and theme
    final Color effectiveBackgroundColor =
        backgroundColor ??
        (isPrimary ? colorScheme.primary : colorScheme.cardBackground);
    final Color effectiveForegroundColor =
        foregroundColor ?? (isPrimary ? AppColors.offWhite : colorScheme.text);

    // Default boxShadow mimicking shadow-xl from Tailwind, but adapted
    final List<BoxShadow> effectiveBoxShadow =
        boxShadow ??
        (isPrimary
            ? [
                BoxShadow(
                  color: effectiveBackgroundColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : []);

    final BorderRadius effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(AppDimens.r14);

    return Container(
      width: width,
      height: height ?? AppDimens.p54, // Matches h-[54px]
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow: effectiveBoxShadow,
      ),
      child: Material(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: effectiveBorderRadius,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: AppDimens.p24,
                    height: AppDimens.p24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        effectiveForegroundColor,
                      ),
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        style:
                            textStyle ??
                            textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: effectiveForegroundColor,
                            ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(icon, color: effectiveForegroundColor, size: 20),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
