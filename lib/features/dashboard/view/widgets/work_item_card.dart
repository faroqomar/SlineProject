import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/profile/view/widgets/profile_preview_modal.dart';

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

  /// Convert raw snake_case status to human-readable label
  static String _getStatusDisplayLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'pending_payment':
      case 'accepted': // direct offer accepted, waiting for payment
        return 'PENDING PAYMENT';
      case 'request_pending':
      case 'paid_request_pending':
        return 'REQUEST PENDING';
      case 'in_progress':
        return 'IN PROGRESS';
      default:
        return raw.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isBooking = item.type == WorkItemType.booking;
    final isDirectOffer = item.type == WorkItemType.directOffer;
    final deepLinkService = context.read<DeepLinkService>();

    Color statusColor;
    switch (item.statusRaw) {
      case 'open':
      case 'pending':
      case 'paid_request_pending':
      case 'accepted': // direct offer pending payment
        statusColor = AppColors.gold;
      case 'assigned':
      case 'confirmed':
      case 'inProgress':
      case 'in_progress':
      case 'active':
        statusColor = AppColors.teal;
      case 'delivered':
        statusColor = AppColors.lightRed;
      case 'completed':
      case 'closed':
        statusColor = AppColors.lightTeal;
      case 'canceled':
      case 'declined':
      case 'refunded':
        statusColor = AppColors.lightRed;
      default:
        statusColor = AppColors.mediumGrey;
    }

    return AppCard(
      onTap: () async {
        final result = await deepLinkService.handleWorkItem(
          context,
          item.type.name,
          item.id,
          conversationId: item.conversationId,
        );
        if (result == true && context.mounted) {
          unawaited(context.read<DashboardViewModel>().refresh());
        }
      },
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Removed extra closing stuff
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
                        isDirectOffer
                            ? Icons.chat_bubble_outline
                            : (isBooking
                                  ? Icons.calendar_today
                                  : Icons.assignment),
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDirectOffer
                            ? 'CUSTOM OFFER'
                            : (isBooking ? 'BOOKING' : 'TASK'),
                        style: AppTypography.captionBold.copyWith(
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item.scheduledAt != null
                              ? '• Due ${DateFormat('MMM d, h:mm a').format(item.scheduledAt!.toLocal())}'
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
                  _getStatusDisplayLabel(item.statusRaw),
                  style: AppTypography.captionBold.copyWith(color: statusColor),
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
                // Avatar + Name (Clickable)
                GestureDetector(
                  onTap: () {
                    if (context.mounted) {
                      showProfilePreview(context, item.counterpartyId);
                    }
                  },
                  child: Row(
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
                      // Name
                      Flexible(
                        child: Text(
                          item.counterpartyName,
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.text,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimens.p16),

                if (item.needsReview)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppDimens.p8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimens.r16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.rate_review,
                          size: 14,
                          color: AppColors.lightRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.actionableNeedsReview
                              ? 'Needs Review'
                              : 'Awaiting Client Review',
                          style: AppTypography.captionBold.copyWith(
                            color: AppColors.lightRed,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Actions
                if (item.primaryActionType != PrimaryActionType.startWork &&
                    item.primaryActionType !=
                        PrimaryActionType.reviewDelivery &&
                    (item.permissions.canComplete ||
                        item.permissions.canApprove ||
                        item.permissions.canReview ||
                        item.permissions.canPayEscrow))
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
                if (onSecondaryAction != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppDimens.p8),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onSecondaryAction,
                        child: const Text('Cancel payment'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
      case PrimaryActionType.reviewDelivery:
        return 'Review Delivery';
      case PrimaryActionType.payEscrow:
        return 'Pay & Confirm';
      case PrimaryActionType.submitEvidence:
        return 'Submit Evidence';
      case PrimaryActionType.viewDetails:
        return 'View Details';
    }
  }
}
