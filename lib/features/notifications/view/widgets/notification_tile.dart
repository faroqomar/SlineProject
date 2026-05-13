import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';

/// Individual notification tile with semantic colors, unread indicator,
/// haptic feedback, and full Semantics coverage.
///
/// Phase 5 redesign: replaced all hardcoded `AppColors.teal/gold/mediumGrey/lightRed`
/// with semantic tokens (`colorScheme.primary/warning/textSecondary/danger`).
/// Enhanced unread dot from 8px to 10px, added haptic on tap, and full
/// accessibility label. View-layer only.
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
    final colorScheme = context.colorScheme;
    final isRead = notification.isRead;

    return Semantics(
      label:
          '${notification.type.name} notification: ${notification.title}, '
          '${formatFriendlyTime(notification.createdAt)}'
          '${!isRead ? ", unread" : ""}',
      button: true,
      // Prevent child widgets from emitting duplicate announcements —
      // the label above already describes the full tile content.
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          AppInteractionStates.hapticTap();
          AppLogger.d(
            'NotificationTile: tapped ${notification.type.name} notification',
            tag: 'Notifications',
          );
          onTap();
        },
        child: Container(
          // Subtle primary tint for unread — replaces hardcoded AppColors.teal
          color: isRead ? null : colorScheme.primary.withValues(alpha: 0.05),
          padding: const EdgeInsets.all(AppDimens.p16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(colorScheme),
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
                              color: colorScheme.text,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatFriendlyTime(notification.createdAt),
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.p4),
                    Text(
                      notification.message,
                      style: AppTypography.bodyMedium.copyWith(
                        // Semantic textSecondary replaces hardcoded mediumGrey
                        color: colorScheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Unread indicator — enhanced from 8px to 10px dot
              if (!isRead) ...[
                const SizedBox(width: AppDimens.p8),
                Container(
                  width: AppDimens.p10,
                  height: AppDimens.p10,
                  decoration: BoxDecoration(
                    // Semantic danger replaces hardcoded AppColors.lightRed
                    color: colorScheme.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Type-colored icon with semantic token mapping.
  Widget _buildIcon(AppColorScheme colorScheme) {
    IconData icon;
    Color color;

    // Map notification types to semantic colors
    switch (notification.type) {
      case NotificationType.offer:
        icon = Icons.local_offer_outlined;
        color = colorScheme.warning; // replaces AppColors.gold
      case NotificationType.message:
        icon = Icons.chat_bubble_outline;
        color = colorScheme.primary; // replaces AppColors.teal
      case NotificationType.booking:
        icon = Icons.calendar_today_outlined;
        color = colorScheme.primary; // replaces AppColors.teal
      case NotificationType.payment:
        icon = Icons.payment_outlined;
        color = colorScheme.warning; // replaces AppColors.gold
      case NotificationType.review:
        icon = Icons.star_outline;
        color = colorScheme.warning; // replaces AppColors.gold
      case NotificationType.task:
        icon = Icons.assignment_outlined;
        color = colorScheme.primary; // replaces AppColors.teal
      case NotificationType.system:
        icon = Icons.notifications_none;
        color = colorScheme.textSecondary; // replaces AppColors.mediumGrey
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.p8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: AppLayout.iconStandard),
    );
  }
}
