import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/core/widgets/scale_button.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap != null) {
      return ScaleButton(onPressed: onTap, child: _buildContainer());
    }
    return _buildContainer();
  }

  Widget _buildContainer() {
    return SizedBox(
      width: width,
      height: height,
      child: GlassContainer(
        padding: padding ?? const EdgeInsets.all(AppDimens.p16),
        margin: margin,
        borderRadius: borderRadius ?? BorderRadius.circular(AppDimens.r20),
        child: child,
      ),
    );
  }
}
