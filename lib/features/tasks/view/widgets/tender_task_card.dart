import 'package:flutter/material.dart';

import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/core/app_enums.dart'; // Added for TaskStatus
import 'package:sline_app/features/tasks/models/task_model.dart';

class TenderTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final bool isHot;

  const TenderTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.isHot = false,
  });

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(20), // Matches rounded-[20px]
        border: Border.all(color: colorScheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.isDark
                ? AppColors.almostBlack.withValues(alpha: 0.2)
                : AppColors.almostBlack.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Accent Bar
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: AppColors.lightRed.withValues(alpha: 0.8),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),

                    // Content Area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Tags + Time
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tags (first 2)
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: task.skills
                                        .take(2)
                                        .map(
                                          (tag) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.tagBackground,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: colorScheme.tagBorder,
                                              ),
                                            ),
                                            child: Text(
                                              tag.toUpperCase(),
                                              style: AppTypography.micro
                                                  .copyWith(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.5,
                                                    color: colorScheme
                                                        .textSecondary,
                                                  ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),

                                // Time
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 24,
                                  ), // Extra right padding for heart
                                  child: Text(
                                    formatFriendlyTime(task.createdAt),
                                    style: AppTypography.micro.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Title
                            Text(
                              task.title,
                              style: AppTypography.h6.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: colorScheme.text,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 8),

                            // Description
                            Text(
                              task.description,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 13,
                                color: colorScheme.textSecondary.withValues(
                                  alpha: 0.8,
                                ),
                                height: 1.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 16),

                            // Footer
                            Container(
                              padding: const EdgeInsets.only(top: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: colorScheme.divider),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left: Time Left + Bids
                                  Row(
                                    children: [
                                      // Time Left
                                      if (task.deadline != null) ...[
                                        Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: colorScheme.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDeadline(task.deadline!),
                                          style: AppTypography.captionBold
                                              .copyWith(
                                                fontSize: 11,
                                                color:
                                                    colorScheme.textSecondary,
                                              ),
                                        ),
                                        const SizedBox(width: 16),
                                      ],

                                      // Bids Count
                                      Icon(
                                        Icons.group_outlined,
                                        size: 14,
                                        color: colorScheme.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${task.offers} bids',
                                        style: AppTypography.captionBold
                                            .copyWith(
                                              fontSize: 11,
                                              color: colorScheme.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),

                                  // Right: Budget + Arrow
                                  Row(
                                    children: [
                                      Text(
                                        PriceFormatter.formatPrice(task.budget),
                                        style: AppTypography.h5.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.lightRed,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_outward,
                                        size: 16,
                                        color: AppColors.lightRed,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Bookmark Button - Top Right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<SavedTasksViewModel>(
                    builder: (context, savedVM, child) {
                      final isSaved = savedVM.isSaved(task.id);
                      return GestureDetector(
                        onTap: () {
                          // Prevent card tap propagation effectively?
                          // No, GestureDetector inside InkWell might need to handle opaque hit test.
                          savedVM.toggle(task.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSaved
                                ? AppColors.lightRed.withValues(alpha: 0.1)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isSaved
                                ? AppColors.lightRed
                                : colorScheme.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDeadline(DateTime date) {
    if (task.status == TaskStatus.completed) return 'Completed';
    if (task.status == TaskStatus.closed) return 'Closed';

    final diff = date.difference(DateTime.now().toUtc());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }
}
