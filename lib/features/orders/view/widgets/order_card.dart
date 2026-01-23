import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

/// Card widget for the Orders Dashboard (Client View).
/// Displays a published task with status, metrics, and primary action.
class OrderCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onActionTap;
  final String actionLabel;
  final bool showChatButton;
  final VoidCallback? onChatTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const OrderCard({
    super.key,
    required this.task,
    this.onActionTap,
    this.actionLabel = 'View Details',
    this.showChatButton = false,
    this.onChatTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final bool isOpen = task.status == TaskStatus.open;
    final bool isAssigned =
        task.status == TaskStatus.assigned ||
        task.status == TaskStatus.inProgress;

    // Determine status badge color
    Color statusBg;
    Color statusText;
    Color statusBorder;

    switch (task.status) {
      case TaskStatus.open:
        statusBg = AppColors.teal.withValues(alpha: 0.1);
        statusText = AppColors.teal;
        statusBorder = AppColors.teal.withValues(alpha: 0.3);
        break;
      case TaskStatus.inProgress:
      case TaskStatus.assigned:
        statusBg = AppColors.gold.withValues(alpha: 0.1);
        statusText = AppColors.gold;
        statusBorder = AppColors.gold.withValues(alpha: 0.3);
        break;
      case TaskStatus.closed:
        statusBg = AppColors.lightTeal.withValues(alpha: 0.1);
        statusText = AppColors.lightTeal;
        statusBorder = AppColors.lightTeal.withValues(alpha: 0.3);
        break;
      case TaskStatus.completed:
        statusBg = AppColors.lightTeal.withValues(alpha: 0.1);
        statusText = AppColors.lightTeal;
        statusBorder = AppColors.lightTeal.withValues(alpha: 0.3);
        break;
      case TaskStatus.draft:
        statusBg = AppColors.mediumGrey.withValues(alpha: 0.1);
        statusText = AppColors.mediumGrey;
        statusBorder = AppColors.mediumGrey.withValues(alpha: 0.3);
        break;
      case TaskStatus.canceled:
        statusBg = AppColors.mediumGrey.withValues(alpha: 0.1);
        statusText = AppColors.mediumGrey;
        statusBorder = AppColors.mediumGrey.withValues(alpha: 0.3);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      padding: const EdgeInsets.all(AppDimens.p20),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r20),
        border: Border.all(color: colorScheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: colorScheme.isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info
              Expanded(
                child: Row(
                  children: [
                    // Icon/Avatar placeholder based on status
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isAssigned ? AppColors.gold : AppColors.teal,
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                      ),
                      child: Center(
                        child: Icon(
                          isAssigned ? Icons.person : Icons.assignment,
                          color: isAssigned
                              ? AppColors.almostBlack
                              : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.text,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            // Show freelancer name if assigned, otherwise offers count
                            isAssigned
                                ? 'Freelancer: ${task.assignedFreelancerId != null ? "Assigned" : "..."}'
                                : '${task.offers} Offers',
                            style: AppTypography.micro.copyWith(
                              color: colorScheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge + Menu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusBorder),
                    ),
                    child: Text(
                      _getStatusLabel(task.status),
                      style: AppTypography.micro.copyWith(
                        color: statusText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onEdit != null || onDelete != null) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: colorScheme.textSecondary,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') onEdit?.call();
                          if (value == 'delete') onDelete?.call();
                        },
                        itemBuilder: (context) => [
                          if (onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          if (onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Metrics (Active/Open only)
          if (isOpen || isAssigned) ...[
            const SizedBox(height: AppDimens.p16),
            Row(
              children: [
                // Time left
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.p12),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimens.r14),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.schedule, size: 16, color: AppColors.teal),
                        const SizedBox(height: 4),
                        Text(
                          task.deadline != null
                              ? formatTimeLeft(task.deadline!)
                              : 'No Deadline',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TIME LEFT',
                          style: AppTypography.micro.copyWith(
                            color: colorScheme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.p12),

                // Budget
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.p12),
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimens.r14),
                      border: Border.all(color: colorScheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: colorScheme.text,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          PriceFormatter.formatPrice(task.budget),
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'BUDGET',
                          style: AppTypography.micro.copyWith(
                            color: colorScheme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Actions
          const SizedBox(height: AppDimens.p16),
          Container(
            padding: const EdgeInsets.only(top: AppDimens.p12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colorScheme.divider)),
            ),
            child: Row(
              children: [
                // Primary action
                Expanded(
                  child: GestureDetector(
                    onTap: onActionTap,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          actionLabel,
                          style: AppTypography.captionBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (showChatButton) ...[
                  const SizedBox(width: AppDimens.p12),
                  // Chat button
                  GestureDetector(
                    onTap: onChatTap,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                        border: Border.all(color: colorScheme.cardBorder),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: colorScheme.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return 'OPEN';
      case TaskStatus.assigned:
        return 'ASSIGNED';
      case TaskStatus.inProgress:
        return 'IN PROGRESS';
      case TaskStatus.closed:
        return 'CLOSED';
      case TaskStatus.completed:
        return 'COMPLETED';
      case TaskStatus.draft:
        return 'DRAFT';
      case TaskStatus.canceled:
        return 'CANCELLED';
    }
  }
}
