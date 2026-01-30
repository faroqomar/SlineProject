import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';

class ServiceCard extends StatelessWidget {
  final dynamic service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Dynamic fallback
    final title = service is Map
        ? service['title'] ?? 'Untitled Service'
        : 'Service';
    final description = service is Map
        ? service['description'] ?? 'No description'
        : '';

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(AppDimens.p16),
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.h5.copyWith(color: colorScheme.text),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: AppDimens.p8),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
