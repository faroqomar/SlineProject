import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // theme variable unused, removed
    final isRead = notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? null : AppColors.teal.withValues(alpha: 0.05),
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.h4.copyWith(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        formatFriendlyTime(notification.createdAt),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.p4),
                  Text(
                    notification.message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isRead) ...[
              const SizedBox(width: AppDimens.p8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.lightRed,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.offer:
        icon = Icons.local_offer_outlined;
        color = AppColors.gold;
      case NotificationType.message:
        icon = Icons.chat_bubble_outline;
        color = AppColors.teal;
      case NotificationType.booking:
        icon = Icons.calendar_today_outlined;
        color = AppColors.teal;
      case NotificationType.payment:
        icon = Icons.payment_outlined;
        color = AppColors.gold;
      case NotificationType.review:
        icon = Icons.star_outline;
        color = AppColors.gold;
      case NotificationType.task:
        icon = Icons.assignment_outlined;
        color = AppColors.teal;
      case NotificationType.system:
        icon = Icons.notifications_none;
        color = AppColors.mediumGrey;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.p8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
