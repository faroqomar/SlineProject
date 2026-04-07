import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';

/// A wrapper widget that adds a scale-down press effect with haptic feedback.
///
/// Provides immediate tactile feedback for buttons and cards. Used internally
/// by [AppButton], [AppStyledButton], [AppCard], and [CircleIconButton].
///
/// ## Phase 1 Redesign Changes
/// - Migrated from hardcoded 100ms/easeInOut/0.95 to [AppMotion] tokens
/// - Added [HapticFeedback.selectionClick] on press
/// - Added [disabled] parameter with opacity + pointer blocking
/// - Added [Semantics] wrapper for accessibility
/// - Added [callbackDelay] parameter (default 50ms for backward compat)
/// - Respects reduced motion via [AppMotion.respectMotion]
class ScaleButton extends StatefulWidget {
  /// The child widget to wrap with scale effect.
  final Widget child;

  /// Callback fired on tap-up (after [callbackDelay]).
  /// When null, the button is visually inert (no scale, no haptic).
  final VoidCallback? onPressed;

  /// Scale amount on press-down. Defaults to [AppMotion.pressScale] (0.96).
  final double scaleAmount;

  /// Duration of the scale animation. Defaults to [AppMotion.micro] (100ms).
  final Duration duration;

  /// Delay before firing [onPressed] after tap-up.
  /// Defaults to 50ms for backward compatibility. Pass [Duration.zero]
  /// to fire immediately.
  final Duration callbackDelay;

  /// When true, disables interaction and applies reduced opacity.
  final bool disabled;

  const ScaleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scaleAmount = AppMotion.pressScale,
    this.duration = AppMotion.micro,
    this.callbackDelay = const Duration(milliseconds: 50),
    this.disabled = false,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleAmount,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.curveSpring),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isInteractive =>
      widget.onPressed != null && !widget.disabled;

  void _onTapDown(TapDownDetails details) {
    if (!_isInteractive) return;
    _controller.forward();
    AppInteractionStates.hapticTap();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isInteractive) return;
    _controller.reverse();
    if (widget.callbackDelay == Duration.zero) {
      widget.onPressed!();
    } else {
      Future.delayed(widget.callbackDelay, () {
        if (mounted) widget.onPressed!();
      });
    }
  }

  void _onTapCancel() {
    if (!_isInteractive) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Respect reduced motion preference
    final effectiveDuration = AppMotion.respectMotion(context, widget.duration);
    if (effectiveDuration != _controller.duration) {
      _controller.duration = effectiveDuration;
    }

    Widget result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );

    // Apply disabled state
    if (widget.disabled) {
      result = AbsorbPointer(
        child: Opacity(
          opacity: AppInteractionStates.disabledOpacity,
          child: result,
        ),
      );
    }

    return Semantics(button: true, child: result);
  }
}
