import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/core/utils/format_date.dart';

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

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Fixed shadow color
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.r16),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p12),
            child: Row(
              children: [
                // Thumb
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: imagePath != null
                        ? SignedImage(
                            storagePathOrUrl: imagePath,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: colorScheme
                                .cardBorder, // Fixed surface -> cardBorder
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
                      _buildStatusBadge(booking.status),
                      const SizedBox(height: 4),

                      Text(
                        taskTitle,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booked: ${formatUtcToLocal(booking.createdAtUtc)}',
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price/Action
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (budget > 0)
                      Text(
                        '\$$budget', // Use formatter if available
                        style: AppTypography.h6.copyWith(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    const SizedBox(height: 8),
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

  Widget _buildStatusBadge(BookingStatus status) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pending:
        color = AppColors.gold;
        text = 'PENDING';
        break;
      case BookingStatus.confirmed:
        color = AppColors.teal;
        text = 'CONFIRMED';
        break;
      case BookingStatus.completed:
        color = AppColors.mediumGrey;
        text = 'COMPLETED';
        break;
      case BookingStatus.canceled:
        color = AppColors.lightRed;
        text = 'CANCELED';
        break;
      case BookingStatus.noShow:
        color = AppColors.lightRed;
        text = 'NO SHOW';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTypography.micro.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
