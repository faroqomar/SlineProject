import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/widgets/scale_button.dart';

/// A customizable button with the full 8-state interaction model.
///
/// ## 8 Interaction States
/// 1. **Default** — Normal appearance, Level 1 elevation.
/// 2. **Hover** — (desktop/web) via InkWell hoverColor.
/// 3. **Focus** — (keyboard) via InkWell focusColor.
/// 4. **Active/Pressed** — ScaleButton press + InkWell ripple.
/// 5. **Disabled** — [isDisabled] = true. AbsorbPointer + reduced opacity.
/// 6. **Loading** — [isLoading] = true. Spinner replaces text.
/// 7. **Success** — [onSuccess] callback triggers flash + check icon.
/// 8. **Error** — [isError] = true triggers flash + haptic.
///
/// ## Widget Tree
/// `ScaleButton > Material > InkWell > content`
/// ScaleButton provides press scale + haptics.
/// Material + InkWell provide elevation, ripple, hover, and focus.
///
/// ## Phase 1 Changes
/// - Converted from StatelessWidget to StatefulWidget (for success animation)
/// - Added 8-state model with AppMotion/AppInteractionStates tokens
/// - Added Semantics, haptics, elevation from design tokens
/// - Removed hardcoded shadow (blurRadius: 15, alpha: 0.3)
/// - All existing constructor params preserved (backward compatible)
class AppButton extends StatefulWidget {
  final Key? tapTargetKey;
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

  /// When true, disables all interaction and reduces opacity.
  final bool isDisabled;

  /// When set to true, triggers success flash animation (green + check icon).
  /// The button auto-reverts to normal after [AppInteractionStates.revertDelay].
  /// Parent should set back to false after the revert period.
  final bool isSuccess;

  /// When set to true, triggers error flash animation (red + haptic).
  /// The button auto-reverts visually after flash duration.
  final bool isError;

  const AppButton({
    super.key,
    this.tapTargetKey,
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
    this.isDisabled = false,
    this.isSuccess = false,
    this.isError = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  bool _isInSuccessState = false;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    );
    _flashAnimation = Tween<double>(
      begin: 0,
      end: AppInteractionStates.flashOverlayOpacity,
    ).animate(
      CurvedAnimation(parent: _flashController, curve: AppMotion.curveStandard),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger success animation when isSuccess transitions false → true
    if (widget.isSuccess && !oldWidget.isSuccess) {
      _runSuccessAnimation();
    }
    // Trigger error flash when isError transitions false → true
    if (widget.isError && !oldWidget.isError) {
      _runErrorFlash();
    }
  }

  bool get _inputBlocked =>
      widget.isDisabled || widget.isLoading || _isInSuccessState;

  void _handleTap() {
    if (_inputBlocked) return;
    widget.onPressed?.call();
  }

  void _runSuccessAnimation() {
    if (_isInSuccessState || !mounted) return;
    setState(() => _isInSuccessState = true);
    AppInteractionStates.hapticSuccess();
    _flashController.forward().then((_) {
      // Show check icon for 200ms after flash
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _flashController.reverse().then((_) {
          // Auto-revert after revertDelay
          Future.delayed(AppInteractionStates.revertDelay, () {
            if (!mounted) return;
            setState(() => _isInSuccessState = false);
          });
        });
      });
    });
  }

  void _runErrorFlash() {
    AppInteractionStates.hapticHeavy();
    _flashController.forward().then((_) {
      Future.delayed(AppInteractionStates.flashDuration, () {
        if (mounted) _flashController.reverse();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.appTextTheme;

    final effectiveBg =
        widget.backgroundColor ??
        (widget.isPrimary ? colorScheme.primary : colorScheme.cardBackground);
    final effectiveFg =
        widget.foregroundColor ??
        (widget.isPrimary ? AppColors.offWhite : colorScheme.text);
    final effectiveRadius =
        widget.borderRadius ?? BorderRadius.circular(AppDimens.r14);

    // Elevation: Level 1 at rest, Level 0 when disabled/loading/success
    final effectiveShadow =
        widget.boxShadow ??
        (_inputBlocked
            ? AppDecorations.elevation(0)
            : AppDecorations.elevation(1, isDark: colorScheme.isDark));

    // Build the button content
    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: AppInteractionStates.loadingSize,
        height: AppInteractionStates.loadingSize,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
          strokeWidth: AppInteractionStates.loadingStrokeWidth,
        ),
      );
    } else if (_isInSuccessState) {
      content = Icon(Icons.check, color: effectiveFg, size: 24);
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              style:
                  widget.textStyle ??
                  textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: effectiveFg,
                  ),
            ),
            if (widget.icon != null) ...[
              const SizedBox(width: 8),
              Icon(widget.icon, color: effectiveFg, size: 20),
            ],
          ],
        ),
      );
    }

    // Flash overlay for success/error
    final buttonBody = AnimatedBuilder(
      animation: _flashAnimation,
      builder: (context, child) {
        final flashColor =
            _isInSuccessState
                ? colorScheme.success
                : colorScheme.danger;
        return Stack(
          alignment: Alignment.center,
          children: [
            child!,
            if (_flashAnimation.value > 0)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: flashColor.withValues(alpha: _flashAnimation.value),
                    borderRadius: effectiveRadius,
                  ),
                ),
              ),
          ],
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height ?? AppDimens.p54,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          boxShadow: effectiveShadow,
        ),
        child: Material(
          color: effectiveBg,
          borderRadius: effectiveRadius,
          child: InkWell(
            key: widget.tapTargetKey,
            onTap: _inputBlocked ? null : _handleTap,
            borderRadius: effectiveRadius,
            hoverColor: colorScheme.hoverOverlay,
            focusColor: colorScheme.focusRing.withValues(
              alpha: AppInteractionStates.hoverOverlayOpacity,
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );

    // Wrap with ScaleButton for press feedback
    final result = ScaleButton(
      onPressed: _inputBlocked ? null : _handleTap,
      disabled: _inputBlocked,
      child: buttonBody,
    );

    // Semantics
    return Semantics(
      button: true,
      label: widget.text,
      enabled: !_inputBlocked,
      child: result,
    );
  }
}
