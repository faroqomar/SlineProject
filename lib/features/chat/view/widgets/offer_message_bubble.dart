import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';

/// Offer status enum for display purposes.
enum OfferStatus { pending, accepted, declined }

/// A message bubble widget for displaying custom offers in chat.
/// Supports both legacy (message-only) and direct offers (offer_id + lifecycle).
class OfferMessageBubble extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final String deliveryDays;
  final OfferStatus status;
  final bool isMine;
  final String time;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  /// Direct offer id (from payload). When set, lifecycle actions are shown.
  final String? offerId;

  /// Raw status from payload: sent, active, delivered, completed, rejected, canceled, refunded.
  final String? rawStatus;
  final VoidCallback? onCancel;
  final VoidCallback? onDeliver;
  final VoidCallback? onComplete;

  const OfferMessageBubble({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.deliveryDays,
    this.status = OfferStatus.pending,
    required this.isMine,
    required this.time,
    this.onAccept,
    this.onDecline,
    this.offerId,
    this.rawStatus,
    this.onCancel,
    this.onDeliver,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final maxWidth = MediaQuery.of(context).size.width * 0.85;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: maxWidth,
        margin: const EdgeInsets.symmetric(vertical: AppDimens.p8),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimens.r20),
          border: Border.all(
            color: AppColors.teal.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.r20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with badge and price
              Padding(
                padding: const EdgeInsets.all(AppDimens.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Badge and Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Offer badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.p8,
                            vertical: AppDimens.p4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(AppDimens.r8),
                          ),
                          child: Text(
                            'CUSTOM OFFER',
                            style: AppTypography.micro.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Price
                        Text(
                          '\$$price',
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.p12),

                    // Title
                    Text(
                      title,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.text,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p4),

                    // Description
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimens.p12),

                    // Delivery time
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: colorScheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$deliveryDays Days Delivery',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.p16),

                    // Action buttons or status
                    _buildActions(colorScheme),
                  ],
                ),
              ),

              // Time stamp
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.p16,
                  0,
                  AppDimens.p16,
                  AppDimens.p8,
                ),
                child: Text(
                  time,
                  style: AppTypography.micro.copyWith(
                    color: colorScheme.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(AppColorScheme colorScheme) {
    final isSent = rawStatus == 'sent' || rawStatus == 'sent_unpaid';
    final isActive = rawStatus == 'active' || rawStatus == 'active_held';
    final isDelivered =
        rawStatus == 'delivered' || rawStatus == 'delivered_held';
    final isAcceptedPendingPayment =
        rawStatus == 'accepted' || rawStatus == 'accepted_unpaid';

    // Direct offer: accepted but not yet paid (client must pay from dashboard)
    if (isAcceptedPendingPayment && offerId != null) {
      return _buildStatusChip('Pending Payment', Icons.payment, AppColors.gold);
    }

    // Payment done, work in progress (escrow held)
    if (isActive && offerId != null) {
      return _buildStatusChip('Paid', Icons.check_circle, AppColors.lightTeal);
    }

    // Full lifecycle done (completed and payment released)
    final isCompletedPaid =
        rawStatus == 'completed' || rawStatus == 'completed_released';
    if (isCompletedPaid) {
      return _buildStatusChip(
        'Completed • Paid',
        Icons.check_circle,
        AppColors.lightTeal,
      );
    }

    final isEndState =
        status != OfferStatus.pending ||
        rawStatus == 'completed' ||
        rawStatus == 'rejected' ||
        rawStatus == 'canceled' ||
        rawStatus == 'refunded';

    if (isEndState) {
      final accepted =
          status == OfferStatus.accepted || rawStatus == 'completed';
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p12,
          vertical: AppDimens.p8,
        ),
        decoration: BoxDecoration(
          color: accepted
              ? AppColors.lightTeal.withValues(alpha: 0.2)
              : AppColors.lightRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppDimens.r8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              accepted ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: accepted ? AppColors.lightTeal : AppColors.lightRed,
            ),
            const SizedBox(width: 6),
            Text(
              accepted
                  ? 'Accepted'
                  : (rawStatus == 'canceled' ? 'Canceled' : 'Declined'),
              style: AppTypography.captionBold.copyWith(
                color: accepted ? AppColors.lightTeal : AppColors.lightRed,
              ),
            ),
          ],
        ),
      );
    }

    // Client actions (not mine)
    if (!isMine) {
      if (isSent && (onAccept != null || onDecline != null)) {
        return Row(
          children: [
            Expanded(
              child: AppButton(
                text: offerId != null ? 'Accept' : 'Accept',
                height: 40,
                onPressed: onAccept ?? () {},
              ),
            ),
            const SizedBox(width: AppDimens.p8),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimens.r14),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.3),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDecline,
                    borderRadius: BorderRadius.circular(AppDimens.r14),
                    child: Center(
                      child: Text(
                        'Decline',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
      if (isDelivered && onComplete != null) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Approve & Complete',
            height: 40,
            onPressed: onComplete,
          ),
        );
      }
    }

    // Freelancer actions (mine)
    if (isMine) {
      if (isSent && onCancel != null) {
        return SizedBox(
          width: double.infinity,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.r14),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCancel,
                borderRadius: BorderRadius.circular(AppDimens.r14),
                child: Center(
                  child: Text(
                    'Cancel Offer',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      if (isActive && onDeliver != null) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Mark Delivered',
            height: 40,
            onPressed: onDeliver,
          ),
        );
      }
    }

    // Pending response (no action for this viewer)
    return _buildStatusChip('Pending Response', Icons.schedule, AppColors.gold);
  }

  Widget _buildStatusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimens.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.captionBold.copyWith(color: color)),
        ],
      ),
    );
  }
}
