import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/features/services/models/service_model.dart';
import 'package:sline_app/features/services/models/service_status.dart';

/// Typed card for a [ServiceModel], replacing the old dynamic-map card.
class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(AppDimens.p16),
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.title,
                    style: AppTypography.h5.copyWith(color: colorScheme.text),
                  ),
                ),
                _StatusBadge(status: service.status),
              ],
            ),

            // Description
            if (service.description != null &&
                service.description!.isNotEmpty) ...[
              const SizedBox(height: AppDimens.p8),
              Text(
                service.description!,
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Price & delivery
            if (service.price != null || service.deliveryDays != null) ...[
              const SizedBox(height: AppDimens.p12),
              Row(
                children: [
                  if (service.price != null) ...[
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: colorScheme.textSecondary,
                    ),
                    Text(
                      service.price!.toStringAsFixed(2),
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppDimens.p16),
                  ],
                  if (service.deliveryDays != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: colorScheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${service.deliveryDays} day${service.deliveryDays == 1 ? '' : 's'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ServiceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final (Color bg, Color fg) = switch (status) {
      ServiceStatus.active => (
        colorScheme.primary.withValues(alpha: 0.15),
        colorScheme.primary,
      ),
      ServiceStatus.draft => (
        colorScheme.warning.withValues(alpha: 0.15),
        colorScheme.warning,
      ),
      ServiceStatus.paused => (
        colorScheme.textSecondary.withValues(alpha: 0.15),
        colorScheme.textSecondary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.r8),
      ),
      child: Text(
        status.label,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
