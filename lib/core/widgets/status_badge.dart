import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.text,
    this.color,
    this.isSmall = false,
  });

  factory StatusBadge.fromWorkItem(WorkItem item, {bool isSmall = false}) {
    final statusColor = _getColorForStatus(item.statusRaw, item.type);
    return StatusBadge(
      text: _formatStatus(item.statusRaw),
      color: statusColor,
      isSmall: isSmall,
    );
  }

  factory StatusBadge.fromStatus(
    dynamic status,
    WorkItemType type, {
    bool isSmall = false,
  }) {
    var statusStr = '';
    if (status is BookingStatus) {
      statusStr = status.name;
    } else if (status is TaskStatus) {
      statusStr = status.name;
    } else {
      statusStr = status.toString();
    }

    final statusColor = _getColorForStatus(statusStr, type);
    return StatusBadge(
      text: _formatStatus(statusStr),
      color: statusColor,
      isSmall: isSmall,
    );
  }

  static Color _getColorForStatus(String status, WorkItemType type) {
    final s = status.toLowerCase();

    // Universal Statuses
    if (s == 'completed' || s == 'delivered') {
      return Colors.green;
    }
    if (s == 'canceled' || s == 'declined' || s == 'rejected') {
      return AppColors.lightRed;
    }
    if (s == 'pending' || s == 'draft') {
      return AppColors.gold;
    }

    // Booking Specific
    if (type == WorkItemType.booking) {
      if (s == 'confirmed') {
        return AppColors.teal;
      }
      if (s == 'active' || s == 'inprogress') {
        return AppColors.teal;
      }
      if (s == 'paid_request_pending') {
        return AppColors.gold;
      }
    }

    // Task Specific
    if (type == WorkItemType.task) {
      if (s == 'open') {
        return AppColors.teal;
      }
      if (s == 'assigned' || s == 'inprogress') {
        return AppColors.teal;
      }
      if (s == 'offers_review') {
        return AppColors.gold;
      }
    }

    return AppColors.mediumGrey;
  }

  static String _formatStatus(String status) {
    if (status == 'paid_request_pending') {
      return 'Payment Pending';
    }
    if (status == 'inprogress') {
      return 'In Progress';
    }
    // Capitalize first letter
    if (status.isEmpty) {
      return '';
    }
    return status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final finalColor = color ?? context.colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppDimens.p8 : AppDimens.p12,
        vertical: isSmall ? 2 : AppDimens.p4,
      ),
      decoration: BoxDecoration(
        color: finalColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: finalColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style: isSmall
            ? AppTypography.micro.copyWith(
                color: finalColor,
                fontWeight: FontWeight.bold,
              )
            : AppTypography.captionBold.copyWith(color: finalColor),
      ),
    );
  }
}
