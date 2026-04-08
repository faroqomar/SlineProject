import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
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
    final colorScheme = context.colorScheme;

    return Semantics(
      button: true,
      label: '${task.title} tender task card',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.p12),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r20),
          border: Border.all(color: colorScheme.cardBorder, width: 1),
          boxShadow: AppDecorations.elevation(1, isDark: colorScheme.isDark),
        ),
        child: ScaleButton(
          onPressed: () {
            AppLogger.d('TenderTaskCard tapped: ${task.id}', tag: 'Cards');
            onTap();
          },
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
                        color: colorScheme.danger.withValues(alpha: 0.8),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppDimens.r20),
                          bottomLeft: Radius.circular(AppDimens.r20),
                        ),
                      ),
                    ),

                    // Content Area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.p20,
                          AppDimens.p16,
                          AppDimens.p16,
                          AppDimens.p16,
                        ),
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
                                    spacing: AppDimens.p8,
                                    runSpacing: AppDimens.p4,
                                    children: task.skills
                                        .take(2)
                                        .map(
                                          (tag) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppDimens.p8,
                                              vertical: AppDimens.p2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.tagBackground,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppDimens.r8,
                                                  ),
                                              border: Border.all(
                                                color: colorScheme.tagBorder,
                                              ),
                                            ),
                                            child: Text(
                                              tag.toUpperCase(),
                                              style: AppTypography.micro
                                                  .copyWith(
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
                                    left: AppDimens.p8,
                                    right: AppDimens.p24,
                                  ),
                                  child: Text(
                                    formatFriendlyTime(task.createdAt),
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppDimens.p12),

                            // Title
                            Text(
                              task.title,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: colorScheme.text,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: AppDimens.p8),

                            // Description
                            Text(
                              task.description,
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.textSecondary.withValues(
                                  alpha: 0.8,
                                ),
                                height: 1.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: AppDimens.p16),

                            // Footer
                            Container(
                              padding: const EdgeInsets.only(
                                top: AppDimens.p12,
                              ),
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
                                          style: AppTypography.caption.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: AppDimens.p16),
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
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.w700,
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
                                        style: AppTypography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: colorScheme.danger,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_outward,
                                        size: 16,
                                        color: colorScheme.danger,
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
                  top: AppDimens.p8,
                  right: AppDimens.p8,
                  child: Consumer<SavedTasksViewModel>(
                    builder: (context, savedVM, child) {
                      final isSaved = savedVM.isSaved(task.id);
                      return GestureDetector(
                        onTap: () {
                          savedVM.toggle(task.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppDimens.p8),
                          decoration: BoxDecoration(
                            color: isSaved
                                ? colorScheme.danger.withValues(alpha: 0.1)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isSaved
                                ? colorScheme.danger
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
