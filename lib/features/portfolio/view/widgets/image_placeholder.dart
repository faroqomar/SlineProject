import 'package:flutter/material.dart';

/// Simple placeholder used when there is no image or image fails to load.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      color: color,
      child: Center(
        child: Text(
          title.isNotEmpty
              ? title.characters.take(2).toString().toUpperCase()
              : '—',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
