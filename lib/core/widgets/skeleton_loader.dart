import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';

/// Animated shimmer skeleton for loading states.
///
/// Displays a subtle shimmer animation to indicate content is loading.
/// Uses theme-aware colors that adapt to light/dark mode.
///
/// Usage:
/// ```dart
/// SkeletonLoader(
///   width: 200,
///   height: 20,
///   borderRadius: AppDimens.r8,
/// )
/// ```
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppDimens.r8,
    this.isCircle = false,
  });

  /// Width of the skeleton. If null, expands to fill available space.
  final double? width;

  /// Height of the skeleton.
  final double? height;

  /// Border radius for rounded corners.
  final double borderRadius;

  /// If true, renders as a circle (ignores borderRadius).
  final bool isCircle;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.shimmer)
      ..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.curveSymmetric),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final baseColor = colorScheme.isDark
        ? AppColors.offWhiteTransparent10
        : AppColors.tealTransparent5;
    final highlightColor = colorScheme.isDark
        ? AppColors.offWhiteTransparent15
        : AppColors.tealTransparent15;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built skeleton for common text lines.
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.width,
    this.height = 14,
    this.lines = 1,
    this.lineSpacing = AppDimens.p8,
  });

  final double? width;
  final double height;
  final int lines;
  final double lineSpacing;

  @override
  Widget build(BuildContext context) {
    if (lines == 1) {
      return SkeletonLoader(
        width: width,
        height: height,
        borderRadius: AppDimens.r4,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(lines, (index) {
        // Make the last line shorter for natural appearance
        final isLast = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: index < lines - 1 ? lineSpacing : 0),
          child: SkeletonLoader(
            width: isLast && width == null
                ? null
                : (isLast ? (width ?? 200) * 0.6 : width),
            height: height,
            borderRadius: AppDimens.r4,
          ),
        );
      }),
    );
  }
}

/// Pre-built skeleton for circular avatars.
class SkeletonAvatar extends StatelessWidget {
  const SkeletonAvatar({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(width: size, height: size, isCircle: true);
  }
}
