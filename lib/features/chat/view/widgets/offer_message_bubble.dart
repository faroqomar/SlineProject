import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';

/// Offer status enum for display purposes.
enum OfferStatus { pending, accepted, declined }

/// A message bubble widget for displaying custom offers in chat.
/// Matches the new design system with glass effect and action buttons.
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
  });

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
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
    // Show status badge if not pending
    if (status != OfferStatus.pending) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p12,
          vertical: AppDimens.p8,
        ),
        decoration: BoxDecoration(
          color: status == OfferStatus.accepted
              ? AppColors.lightTeal.withValues(alpha: 0.2)
              : AppColors.lightRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppDimens.r8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == OfferStatus.accepted ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: status == OfferStatus.accepted
                  ? AppColors.lightTeal
                  : AppColors.lightRed,
            ),
            const SizedBox(width: 6),
            Text(
              status == OfferStatus.accepted ? 'Accepted' : 'Declined',
              style: AppTypography.captionBold.copyWith(
                color: status == OfferStatus.accepted
                    ? AppColors.lightTeal
                    : AppColors.lightRed,
              ),
            ),
          ],
        ),
      );
    }

    // Show action buttons for pending offers (only if not mine)
    if (!isMine) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Accept',
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

    // For sender's own pending offers
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p8,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimens.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: AppColors.gold,
          ),
          const SizedBox(width: 6),
          Text(
            'Pending Response',
            style: AppTypography.captionBold.copyWith(
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

