import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_motion.dart';

/// Legacy animation constants.
///
/// **DEPRECATED:** Use [AppMotion] for all new code.
/// This class is retained only for its utility widgets
/// ([SpringButton], [AnimatedRotationButton]) which are used in production.
///
/// Constants below are deprecated and will be removed in a future release.
class AppAnimations {
  AppAnimations._();

  // --- Durations (DEPRECATED — use AppMotion) ---

  @Deprecated('Use AppMotion.fast instead')
  static const Duration fast = Duration(milliseconds: 200);

  @Deprecated('Use AppMotion.standard instead')
  static const Duration normal = Duration(milliseconds: 300);

  @Deprecated('Use AppMotion.slow instead')
  static const Duration slow = Duration(milliseconds: 400);

  @Deprecated('Use AppMotion.emphasis instead')
  static const Duration slower = Duration(milliseconds: 500);

  // --- Custom Curves (DEPRECATED — use AppMotion) ---

  @Deprecated('Use AppMotion.curveSlideUp instead')
  static const Curve slideUpCurve = Cubic(0.2, 0.8, 0.2, 1);

  @Deprecated('Use AppMotion.curveStandard instead')
  static const Curve easeOut = Curves.easeOut;

  @Deprecated('Use AppMotion.curveSpring instead')
  static const Curve springCurve = Cubic(0.175, 0.885, 0.32, 1.275);

  @Deprecated('Use AppMotion.curveStandard instead')
  static const Curve fadeInCurve = Curves.easeOut;

  // --- Scale Values (DEPRECATED — use AppMotion) ---

  @Deprecated('Use AppMotion.pressScale instead')
  static const double scalePressed = 0.95;

  @Deprecated('Use AppMotion.hoverScale instead')
  static const double scaleHover = 1.02;

  @Deprecated('Use AppMotion.emphasize instead')
  static const double scaleActive = 1.1;
}

/// A widget that provides spring-like tap feedback.
///
/// Used in [MainNavigationScreen] for the FAB button.
/// Migrated to use [AppMotion] tokens.
class SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration duration;

  const SpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = AppMotion.pressScale,
    this.duration = AppMotion.fast,
  });

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.curveSpring),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    unawaited(_controller.forward());
  }

  void _onTapUp(TapUpDetails details) {
    unawaited(_controller.reverse());
    widget.onTap?.call();
  }

  void _onTapCancel() {
    unawaited(_controller.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// A widget that provides animated rotation (for FAB, etc.).
///
/// Used in [MainNavigationScreen] for the Create Task FAB.
/// Migrated to use [AppMotion] tokens.
class AnimatedRotationButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double rotationAngle; // In turns (0.25 = 90 degrees)
  final Duration duration;

  const AnimatedRotationButton({
    super.key,
    required this.child,
    this.onTap,
    this.rotationAngle = 0.25, // 90 degrees
    this.duration = AppMotion.slow,
  });

  @override
  State<AnimatedRotationButton> createState() => _AnimatedRotationButtonState();
}

class _AnimatedRotationButtonState extends State<AnimatedRotationButton> {
  double _rotation = 0.0;
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _rotation = widget.rotationAngle;
          _scale = AppMotion.emphasize;
        });
      },
      onTapUp: (_) {
        setState(() {
          _rotation = 0.0;
          _scale = 1.0;
        });
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() {
          _rotation = 0.0;
          _scale = 1.0;
        });
      },
      child: AnimatedRotation(
        turns: _rotation,
        duration: widget.duration,
        curve: AppMotion.curveSpring,
        child: AnimatedScale(
          scale: _scale,
          duration: widget.duration,
          curve: AppMotion.curveSpring,
          child: widget.child,
        ),
      ),
    );
  }
}
