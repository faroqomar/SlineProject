import 'dart:ui'; // For ImageFilter

import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';

/// A reusable widget that applies a Glassmorphism effect to its child.
///
/// This container combines a translucent background, a subtle border, a shadow,
/// and a blur effect to create the "glass" look, adapting to the current theme.
class GlassContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blurRadius;

  const GlassContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurRadius = AppDimens.p20, // Default blur radius matching design
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: AppDecorations.glassBoxDecoration(
        colorScheme: context.colorScheme,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(AppDimens.r20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
          child: Container(
            padding: padding,
            alignment: Alignment.topLeft, // Default alignment for content
            child: child,
          ),
        ),
      ),
    );
  }
}
