import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

/// Solid media placeholder used when a portfolio image is missing or fails.
///
/// The widget is visual-only; storage-path and public URL handling remain with
/// the portfolio ViewModel and repository.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, required this.title, this.height});

  final String title;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;
    final label = title.isNotEmpty
        ? title.characters.take(2).toString().toUpperCase()
        : '-';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: amberColors.surfaceRaised,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [amberColors.surfaceHighest, amberColors.surface],
        ),
      ),
      child: SizedBox(
        height: height,
        child: Center(
          child: Text(
            label,
            style: AppTypography.h5.copyWith(color: colorScheme.text),
          ),
        ),
      ),
    );
  }
}
