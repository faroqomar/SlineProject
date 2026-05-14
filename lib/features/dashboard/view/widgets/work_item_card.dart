import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/app_card.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/profile/view/widgets/profile_preview_modal.dart';

/// Compact dashboard work card with navigation and lifecycle action callbacks.
///
/// The card keeps business actions delegated to callers while presenting the
/// work item with Amber Dusk dashboard status, money, and progress treatments.
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
    const amber = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    const typography = AmberDuskTokens.typography;
    final media = AmberDuskTokens.widgetTheme.media;
    final isBooking = item.type == WorkItemType.booking;
    final isDirectOffer = item.type == WorkItemType.directOffer;
    final deepLinkService = context.read<DeepLinkService>();

    Color statusColor;
    switch (item.statusRaw) {
      case 'open':
      case 'pending':
      case 'paid_request_pending':
      case 'accepted': // direct offer pending payment
        statusColor = amber.warning;
      case 'assigned':
      case 'confirmed':
      case 'inProgress':
      case 'in_progress':
      case 'active':
        statusColor = amber.primary;
      case 'delivered':
        statusColor = amber.warning;
      case 'completed':
      case 'closed':
      case 'refunded':
        statusColor = amber.text;
      case 'canceled':
      case 'declined':
        statusColor = amber.danger;
      default:
        statusColor = amber.muted;
    }

    final typeLabel = isDirectOffer
        ? 'Custom offer'
        : (isBooking ? 'Booking' : 'Task');
    final statusLabel = _getStatusDisplayLabel(item.statusRaw);
    final progressValue = _progressForStatus(item.statusRaw);

    return Semantics(
      label: '$typeLabel: ${item.title}, $statusLabel',
      child: AppCard(
        onTap: () async {
          AppLogger.d('WorkItemCard tapped', tag: 'Cards');
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
        margin: EdgeInsets.zero,
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (context.mounted) {
                      showProfilePreview(context, item.counterpartyId);
                    }
                  },
                  child: SignedAvatar(
                    storagePathOrUrl: item.counterpartyAvatar,
                    radius: AppDimens.p18,
                    placeholder: CircleAvatar(
                      radius: AppDimens.p18,
                      backgroundColor: media.avatarFallback,
                      child: Icon(
                        Icons.person,
                        size: AppDimens.iconSizeSmall,
                        color: media.foreground,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: typography.body.copyWith(
                          color: amber.text,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.p2),
                      Text(
                        '${item.counterpartyName} · ${item.statusRaw.replaceAll('_', ' ')}',
                        style: typography.bodySmall.copyWith(
                          color: amber.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.price == null
                          ? PriceFormatter.formatPrice(0)
                          : PriceFormatter.formatPrice(item.price!),
                      style: typography.sectionTitle.copyWith(
                        color: statusColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppDimens.p4),
                    _StatusPill(label: statusLabel, color: statusColor),
                  ],
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.r4),
                    child: LinearProgressIndicator(
                      minHeight: AppDimens.p4,
                      value: progressValue,
                      backgroundColor: amber.surfaceHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ),
                SizedBox(width: spacing.sm),
                Text(
                  '${(progressValue * 100).round()}%',
                  style: typography.chip.copyWith(color: amber.muted),
                ),
              ],
            ),
            if (item.needsReview) ...[
              SizedBox(height: spacing.sm),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.md,
                  vertical: spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: amber.dangerMuted,
                  borderRadius: BorderRadius.circular(spacing.moduleRadius),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.rate_review,
                      size: AppDimens.iconSizeSmall,
                      color: amber.danger,
                    ),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Text(
                        item.actionableNeedsReview
                            ? 'Delivery ready for your review'
                            : 'Waiting for client review',
                        style: typography.chip.copyWith(color: amber.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (item.primaryActionType != PrimaryActionType.startWork &&
                item.primaryActionType != PrimaryActionType.reviewDelivery &&
                (item.permissions.canComplete ||
                    item.permissions.canApprove ||
                    item.permissions.canReview ||
                    item.permissions.canPayEscrow)) ...[
              SizedBox(height: spacing.sm),
              SizedBox(
                height: AppDimens.p40,
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPrimaryAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: amber.primary,
                    foregroundColor: amber.text,
                  ),
                  child: Text(_getPrimaryButtonLabel(item.primaryActionType)),
                ),
              ),
            ],
            if (onSecondaryAction != null) ...[
              SizedBox(height: spacing.xs),
              SizedBox(
                height: AppDimens.p40,
                width: double.infinity,
                child: TextButton(
                  onPressed: onSecondaryAction,
                  style: TextButton.styleFrom(foregroundColor: amber.danger),
                  child: const Text('Cancel payment'),
                ),
              ),
            ],
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

  /// Maps lifecycle buckets to a stable visual progress marker.
  ///
  /// The dashboard evidence shows progress on every work card, but the current
  /// model does not expose a numeric completion ratio, so status provides the
  /// least surprising deterministic proxy.
  double _progressForStatus(String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'open':
      case 'draft':
        // Created but not yet committed to payment or delivery.
        return 0.12;
      case 'pending':
      case 'paid_request_pending':
      case 'accepted':
        // Awaiting payment or a required party action.
        return 0.28;
      case 'confirmed':
      case 'assigned':
        // Confirmed and queued for work to begin.
        return 0.42;
      case 'active':
      case 'inprogress':
      case 'in_progress':
        // Work has started but is not delivered yet.
        return 0.58;
      case 'delivered':
        // Delivered and waiting for client review.
        return 0.72;
      case 'completed':
      case 'closed':
      case 'refunded':
        // Lifecycle is finished for dashboard purposes.
        return 1;
      case 'canceled':
      case 'cancelled':
      case 'declined':
      case 'expired':
        // Short-lived or aborted work still shows slight progress.
        return 0.16;
      default:
        // Unknown statuses stay low-emphasis until mapped explicitly.
        return 0.24;
    }
  }
}

/// Compact status capsule used by [WorkItemCard].
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pills = AmberDuskTokens.widgetTheme.statusPills;

    return Container(
      padding: pills.smallPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(pills.radius),
      ),
      child: Text(
        label,
        style: pills.smallTextStyle.copyWith(color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
