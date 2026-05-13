import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/services/models/service_model.dart';
import 'package:sline_app/features/services/models/service_status.dart';

/// Typed card for a [ServiceModel], replacing the old dynamic-map card.
class ServiceCard extends StatelessWidget {
  /// Service data already loaded by the caller's ViewModel.
  final ServiceModel service;

  /// Optional edit/detail action owned by the caller.
  final VoidCallback? onTap;

  /// Creates a service summary card for profile service management.
  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Semantics(
      button: onTap != null,
      label: 'Service ${service.title}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AppCardContainer(
          padding: const EdgeInsets.all(AppDimens.p16),
          borderRadius: BorderRadius.circular(AppDimens.r16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Keep the status badge inline so service rows scan like package
              // proof rows without adding a second line of state chrome.
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

              // Cap service copy to preserve stable card heights in dense lists.
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

              // Format already-loaded service metadata without adding view logic.
              if (service.price != null || service.deliveryDays != null) ...[
                const SizedBox(height: AppDimens.p12),
                Row(
                  children: [
                    if (service.price != null) ...[
                      Icon(
                        Icons.attach_money,
                        size: AppDimens.iconSizeSmall,
                        color: colorScheme.textSecondary,
                      ),
                      Text(
                        PriceFormatter.formatPrice(service.price!),
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
                        size: AppDimens.iconSizeSmall,
                        color: colorScheme.textSecondary,
                      ),
                      const SizedBox(width: AppDimens.p4),
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
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ServiceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusPills = AmberDuskTokens.widgetTheme.statusPills;
    final (Color bg, Color fg) = switch (status) {
      ServiceStatus.active => (
        statusPills.active.background,
        statusPills.active.foreground,
      ),
      ServiceStatus.draft => (
        statusPills.primary.background,
        statusPills.primary.foreground,
      ),
      ServiceStatus.paused => (
        statusPills.muted.background,
        statusPills.muted.foreground,
      ),
    };

    return Container(
      padding: statusPills.smallPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(statusPills.radius),
      ),
      child: Text(
        status.label,
        style: statusPills.smallTextStyle.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
