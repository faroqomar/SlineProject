import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/widgets/booking_task_card.dart';
import 'package:sline_app/features/tasks/view/widgets/tender_task_card.dart';

/// A card widget to display task info matching the new design system.
/// Delegates to [TenderTaskCard] or [BookingTaskCard] based on task type.
///
/// For backwards compatibility, you can set [useLegacyLayout] to true
/// to use the original compact card layout.
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final bool isHot;

  /// If true, uses the original card layout.
  /// If false (default), delegates to TenderTaskCard or BookingTaskCard.
  final bool useLegacyLayout;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.isHot = false,
    this.useLegacyLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    const colors = AmberDuskTokens.colors;
    const radii = AmberDuskTokens.radius;
    // Delegate to type-specific cards unless legacy layout is requested
    if (!useLegacyLayout) {
      if (task.isTender) {
        return TenderTaskCard(task: task, onTap: onTap, isHot: isHot);
      } else {
        return BookingTaskCard(task: task, onTap: onTap, isHot: isHot);
      }
    }

    // Compact card layout below
    final colorScheme = context.colorScheme;
    final isTender = task.isTender;
    final statusColor = isTender ? colors.rust : colors.forest;
    final borderColor = colorScheme.isDark
        ? colors.dark.border
        : colors.light.border;

    return Semantics(
      button: true,
      label: '${task.title} task card',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.p16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radii.taskCard),
          border: Border.all(color: borderColor),
          boxShadow: AppDecorations.elevation(2, isDark: colorScheme.isDark),
        ),
        child: ScaleButton(
          onPressed: () {
            AppLogger.d('TaskCard tapped: ${task.id}', tag: 'Cards');
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Badge + Hot Badge Row
                Row(
                  children: [
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p10,
                        vertical: AppDimens.p4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(radii.pill),
                      ),
                      child: Text(
                        isTender ? 'TENDER' : 'BOOKING',
                        style: AppTypography.micro.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isTender ? colors.rust : colors.forest,
                        ),
                      ),
                    ),

                    // HOT Badge
                    if (isHot) ...[
                      const SizedBox(width: AppDimens.p8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.p10,
                          vertical: AppDimens.p4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.star.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimens.r8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: AppLayout.iconTiny,
                              color: colors.star,
                            ),
                            const SizedBox(width: AppDimens.p4),
                            Text(
                              'HOT',
                              style: AppTypography.micro.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.star,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppDimens.p12),

                // Title
                Text(
                  task.title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppDimens.p8),

                // Description
                Text(
                  task.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.muted,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppDimens.p12),

                // Footer with divider
                Container(
                  padding: const EdgeInsets.only(top: AppDimens.p12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colors.surfaceHighest),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Time Left / Offers info
                      Row(
                        children: [
                          if (task.deadline != null) ...[
                            Icon(
                              Icons.schedule,
                              size: AppDimens.p14,
                              color: statusColor,
                            ),
                            const SizedBox(width: AppDimens.p4),
                            Text(
                              _formatDeadline(task.deadline!),
                              style: AppTypography.captionBold.copyWith(
                                color: statusColor,
                              ),
                            ),
                          ] else
                            Text(
                              isTender ? 'Open' : 'Available',
                              style: AppTypography.captionBold.copyWith(
                                color: statusColor,
                              ),
                            ),
                        ],
                      ),

                      // Budget
                      Text(
                        PriceFormatter.formatPrice(task.budget),
                        style: AppTypography.h5.copyWith(
                          color: colors.primary,
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

  String _formatDeadline(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    return '${diff.inHours}h left';
  }
}
