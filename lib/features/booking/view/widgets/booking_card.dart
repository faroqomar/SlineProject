import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/utils/status_presenter.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/core/widgets/status_badge.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;
  final bool asProvider;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.asProvider = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final taskData = booking.taskData;
    final taskTitle =
        taskData?['title'] as String? ??
        'Task #${booking.taskId?.substring(0, 8) ?? "?"}';
    final taskImages =
        (taskData?['image_paths'] as List<dynamic>?)?.cast<String>() ?? [];
    final imagePath = taskImages.isNotEmpty ? taskImages.first : null;
    final rawBudget = taskData?['budget'];
    final budget = rawBudget is num ? rawBudget.toDouble() : 0.0;
    final timeline = booking.dueAtUtc ?? booking.scheduledAt;

    final statusColor = StatusPresenter.bookingStatusColor(booking.status);
    final statusLabel = StatusPresenter.bookingStatusLabel(booking.status);

    return Semantics(
      button: true,
      label: '$taskTitle booking, status ${statusLabel.toLowerCase()}',
      child: ScaleButton(
        onPressed: () {
          AppLogger.d('BookingCard tapped', tag: 'Cards');
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppDimens.p12),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(AppDimens.r16),
            border: Border.all(color: colorScheme.cardBorder, width: 1),
            boxShadow: AppDecorations.elevation(1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p12),
            child: Row(
              children: [
                // Thumb
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                  child: SizedBox(
                    width: AppDimens.p70,
                    height: AppDimens.p70,
                    child: imagePath != null
                        ? SignedImage(
                            storagePathOrUrl: imagePath,
                            width: AppDimens.p70,
                            height: AppDimens.p70,
                            fit: BoxFit.cover,
                          )
                        : ColoredBox(
                            color: colorScheme.cardBorder,
                            child: Icon(
                              Icons.work_outline,
                              color: colorScheme.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppDimens.p16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      StatusBadge(
                        text: statusLabel,
                        color: statusColor,
                        isSmall: true,
                      ),
                      const SizedBox(height: AppDimens.p4),

                      Text(
                        taskTitle,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.p4),
                      Text(
                        'Booked: ${formatUtcToLocal(booking.createdAtUtc)}',
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.p2),
                      Text(
                        timeline != null
                            ? 'Due: ${formatUtcToLocal(timeline)}'
                            : 'Due: No deadline',
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                      if (booking.deliveryDays != null) ...[
                        const SizedBox(height: AppDimens.p2),
                        Text(
                          'Delivery: ${booking.deliveryDays} days',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Price/Action
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (budget > 0)
                      Text(
                        PriceFormatter.formatPrice(budget),
                        style: AppTypography.h6.copyWith(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    const SizedBox(height: AppDimens.p8),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.textSecondary.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
