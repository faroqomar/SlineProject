import 'package:flutter/material.dart';

/// Defines animation curves and durations consistent with the design system.
///
/// This class provides reusable animation configurations that match the
/// React design system (slideUp, fadeIn, spring animations).
class AppAnimations {
  AppAnimations._(); // Private constructor to prevent instantiation

  // --- Durations ---
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);

  // --- Custom Curves ---
  /// Curve for slide up animations (modals, sheets)
  /// Mimics: cubic-bezier(0.2, 0.8, 0.2, 1)
  static const Curve slideUpCurve = Cubic(0.2, 0.8, 0.2, 1);

  /// Standard ease out curve for most transitions
  static const Curve easeOut = Curves.easeOut;

  /// Curve for spring-like animations (button feedback)
  /// Mimics: cubic-bezier(0.175, 0.885, 0.32, 1.275)
  static const Curve springCurve = Cubic(0.175, 0.885, 0.32, 1.275);

  /// Standard fade in curve
  static const Curve fadeInCurve = Curves.easeOut;

  // --- Scale Values ---
  static const double scalePressed = 0.95;
  static const double scaleHover = 1.02;
  static const double scaleActive = 1.1;
}

/// A widget that animates its child with a fade-in effect on first build.
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.delay = Duration.zero,
    this.curve = AppAnimations.fadeInCurve,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

/// A widget that animates its child with a slide-up effect on first build.
class SlideUpWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double offsetY;

  const SlideUpWidget({
    super.key,
    required this.child,
    this.duration = AppAnimations.slow,
    this.delay = Duration.zero,
    this.curve = AppAnimations.slideUpCurve,
    this.offsetY = 1.0, // Full height offset by default
  });

  @override
  State<SlideUpWidget> createState() => _SlideUpWidgetState();
}

class _SlideUpWidgetState extends State<SlideUpWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.offsetY),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A widget that provides spring-like tap feedback.
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
    this.scaleDown = AppAnimations.scalePressed,
    this.duration = AppAnimations.fast,
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
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.springCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
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

/// A widget that provides hover scale effect (useful for cards).
class HoverScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hoverScale;
  final double pressedScale;
  final Duration duration;

  const HoverScaleWidget({
    super.key,
    required this.child,
    this.onTap,
    this.hoverScale = AppAnimations.scaleHover,
    this.pressedScale = AppAnimations.scalePressed,
    this.duration = AppAnimations.normal,
  });

  @override
  State<HoverScaleWidget> createState() => _HoverScaleWidgetState();
}

class _HoverScaleWidgetState extends State<HoverScaleWidget> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = widget.pressedScale),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: widget.duration,
        curve: AppAnimations.springCurve,
        child: widget.child,
      ),
    );
  }
}

/// A widget that provides animated rotation (for FAB, etc.).
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
    this.duration = AppAnimations.slow,
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
          _scale = AppAnimations.scaleActive;
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
        curve: AppAnimations.springCurve,
        child: AnimatedScale(
          scale: _scale,
          duration: widget.duration,
          curve: AppAnimations.springCurve,
          child: widget.child,
        ),
      ),
    );
  }
}

