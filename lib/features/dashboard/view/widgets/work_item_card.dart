import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:provider/provider.dart';
import '../../models/work_item.dart';

class WorkItemCard extends StatelessWidget {
  final WorkItem item;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  const WorkItemCard({
    super.key,
    required this.item,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isBooking = item.type == WorkItemType.booking;
    final deepLinkService = context.read<DeepLinkService>();

    Color statusColor;
    switch (item.statusRaw) {
      case 'open':
      case 'pending':
        statusColor = AppColors.gold;
        break;
      case 'assigned':
      case 'confirmed':
      case 'inProgress':
        statusColor = AppColors.teal;
        break;
      case 'completed':
      case 'closed':
        statusColor = AppColors.lightTeal;
        break;
      case 'canceled':
      case 'declined':
        statusColor = AppColors.lightRed;
        break;
      default:
        statusColor = AppColors.mediumGrey;
    }

    return InkWell(
      onTap: () =>
          deepLinkService.handleWorkItem(context, item.type.name, item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.p16),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r16),
          border: Border.all(color: colorScheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p16,
                vertical: AppDimens.p12,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimens.r16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isBooking ? Icons.calendar_today : Icons.assignment,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.type == WorkItemType.booking
                              ? 'BOOKING'
                              : 'TASK',
                          style: AppTypography.captionBold.copyWith(
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item.scheduledAt != null
                                ? '• ${DateFormat('MMM d, h:mm a').format(item.scheduledAt!.toLocal())}'
                                : '• Posted ${formatFriendlyTime(item.createdAt)}',
                            style: AppTypography.caption.copyWith(
                              color: statusColor.withValues(alpha: 0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.statusRaw.toUpperCase(),
                    style: AppTypography.captionBold.copyWith(
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.h5.copyWith(color: colorScheme.text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Avatar
                      SignedAvatar(
                        storagePathOrUrl: item.counterpartyAvatar,
                        radius: 12,
                        placeholder: CircleAvatar(
                          radius: 12,
                          backgroundColor: colorScheme.textSecondary,
                          child: Icon(
                            Icons.person,
                            size: 14,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "${item.counterpartyRole}: ${item.counterpartyName}",
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimens.p16),

                  // Actions
                  if (item.permissions.canStart ||
                      item.permissions.canComplete ||
                      item.permissions.canApprove)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onPrimaryAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                        ),
                        child: Text(
                          _getPrimaryButtonLabel(item.primaryActionType),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPrimaryButtonLabel(PrimaryActionType type) {
    switch (type) {
      case PrimaryActionType.startWork:
        return 'Start Work';
      case PrimaryActionType.markCompleted:
        return 'Mark Completed';
      case PrimaryActionType.approveClose:
        return 'Complete & Close';
    }
  }
}
