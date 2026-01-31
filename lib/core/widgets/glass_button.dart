import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/scale_button.dart';

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isLoading;
  final double? width;
  final double height;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isLoading = false,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    // Opacity handling for disabled state
    final opacity = onPressed == null ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: ScaleButton(
        onPressed: isLoading ? null : onPressed,
        child: Container(
          width: width,
          height: height,
          decoration: _buildDecoration(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.r12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
                alignment: Alignment.center,
                color: Colors.transparent, // Needed for BackdropFilter to fill
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _getTextColor(context),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: _getTextColor(context)),
                            const SizedBox(width: AppDimens.p8),
                          ],
                          Text(
                            text,
                            style: AppTypography.bodySmall.copyWith(
                              color: _getTextColor(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(BuildContext context) {
    final colorScheme = context.colorScheme;

    if (isPrimary) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.r12),
        gradient: LinearGradient(
          colors: [
            AppColors.teal.withValues(alpha: 0.9),
            AppColors.teal.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AppColors.lightTeal.withValues(alpha: 0.3),
          width: 1,
        ),
      );
    } else {
      // Secondary / Minimal
      return BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.r12),
        color: colorScheme.isDark
            ? AppColors.white.withValues(alpha: 0.05)
            : AppColors.almostBlack.withValues(alpha: 0.05),
        border: Border.all(
          color: colorScheme.textSecondary.withValues(alpha: 0.3),
          width: 1,
        ),
      );
    }
  }

  Color _getTextColor(BuildContext context) {
    if (isPrimary) {
      return AppColors.white;
    }
    return context.colorScheme.text;
  }
}
