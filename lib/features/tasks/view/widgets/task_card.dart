import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

/// A card widget to display basic info about a task with Glassmorphism design.
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final bool isTender = task.isTender;
    // final bool isBooking = task.isBooking; // Unused

    // Semantic Colors based on Task Type
    final Color badgeBg = isTender
        ? AppColors.tenderChipBg(context)
        : AppColors.bookingChipBg(context);
    final Color badgeText = isTender ? AppColors.lightRed : AppColors.teal;
    final IconData badgeIcon = isTender ? Icons.assignment : Icons.calendar_today;
    final String badgeLabel = isTender ? 'TENDER' : 'BOOKING';

    // Dynamic Avatar Color (simple hash based on name)
    final List<Color> avatarColors = [
      AppColors.teal,
      AppColors.gold,
      AppColors.lightRed,
      AppColors.lightTeal,
    ];
    final int colorIndex = (task.userName ?? 'User').hashCode.abs() % avatarColors.length;
    final Color avatarBg = avatarColors[colorIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: AppDecorations.glassBoxDecoration(
        colorScheme: colorScheme,
        borderRadius: BorderRadius.circular(AppDimens.r18),
      ).copyWith(
        // Add subtle type-based tint override if needed, or stick to glass
        // color: isTender ? AppColors.tenderCardBg(context) : AppColors.bookingCardBg(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.r18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.r18),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 36, // w-9
                      height: 36, // h-9
                      decoration: BoxDecoration(
                        color: avatarBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(task.userName),
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white, // Assuming dark text on bright colors or white on dark
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.p8),
                    
                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  task.userName ?? 'Unknown User',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.text,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Verification check could go here
                            ],
                          ),
                          Text(
                            _formatTimeAgo(task.createdAt),
                            style: AppTypography.micro.copyWith(
                              color: colorScheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p10,
                        vertical: AppDimens.p4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            badgeIcon,
                            size: 12,
                            color: badgeText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeLabel,
                            style: AppTypography.micro.copyWith(
                              fontWeight: FontWeight.bold,
                              color: badgeText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.p12),

                // --- Content ---
                Text(
                  task.title,
                  style: AppTypography.h6.copyWith(
                    color: colorScheme.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimens.p4),
                Text(
                  task.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimens.p12),

                // --- Footer ---
                Container(
                  padding: const EdgeInsets.only(top: AppDimens.p12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colorScheme.cardBorder),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Time Left / Offers
                      Row(
                        children: [
                          Text(
                            task.deadline != null
                                ? _formatDeadline(task.deadline!)
                                : 'No deadline',
                            style: AppTypography.captionBold.copyWith(
                              color: isTender ? AppColors.lightRed : AppColors.teal,
                            ),
                          ),
                          if (task.taskType == TaskType.tender) ...[
                            const SizedBox(width: AppDimens.p8),
                            Text(
                              '•  0 offers', // Placeholder for offers count
                              style: AppTypography.captionBold.copyWith(
                                color: colorScheme.text,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Budget
                      Text(
                        PriceFormatter.formatPrice(task.budget),
                        style: AppTypography.h5.copyWith(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _formatDeadline(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    return '${diff.inHours}h left';
  }
}