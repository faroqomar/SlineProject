import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';

/// Individual notification tile with semantic colors, unread indicator,
/// haptic feedback, and full Semantics coverage.
///
/// Phase 5 redesign moved legacy colors to semantic tokens, enhanced the
/// unread dot, added haptic feedback, and kept the tile view-layer only.
class NotificationTile extends StatelessWidget {
  /// Notification data already loaded by [NotificationViewModel].
  final NotificationItem notification;

  /// Tap callback owned by the modal so deep-link routing stays above the tile.
  final VoidCallback onTap;

  /// Creates one notification row for the modal list.
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRead = notification.isRead;
    final typeStyle = _typeStyle(context);

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
        borderRadius: BorderRadius.circular(AppDimens.r20),
        onTap: () {
          AppInteractionStates.hapticTap();
          AppLogger.d(
            'NotificationTile: tapped ${notification.type.name} notification',
            tag: 'Notifications',
          );
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(AppDimens.p14),
          decoration: BoxDecoration(
            color: isRead ? amberColors.surface : amberColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDimens.r20),
            border: Border.all(
              color: isRead
                  ? amberColors.surfaceHighest.withValues(alpha: 0.28)
                  : amberColors.primary.withValues(alpha: 0.36),
            ),
            boxShadow: AppDecorations.elevation(
              isRead ? 1 : 2,
              isDark: isDark,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Read/unread accent rail gives each row a fast visual state
                // without relying only on the small trailing dot.
                Container(
                  width: AppDimens.p4,
                  decoration: BoxDecoration(
                    color: isRead
                        ? amberColors.surfaceHighest
                        : typeStyle.color,
                    borderRadius: BorderRadius.circular(AppDimens.r50),
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                _buildIcon(context),
                const SizedBox(width: AppDimens.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AmberDuskTokens
                                  .typography
                                  .notificationTitle
                                  .copyWith(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    color: isRead
                                        ? amberColors.textSubtle
                                        : amberColors.text,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppDimens.p8),
                          _TimePill(
                            label: formatFriendlyTime(notification.createdAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.p8),
                      Wrap(
                        spacing: AppDimens.p8,
                        runSpacing: AppDimens.p6,
                        children: [
                          _TypePill(style: typeStyle),
                          if (!isRead)
                            _StatusPill(
                              label: 'Unread',
                              foreground: amberColors.primary,
                              background: amberColors.infoMuted,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.p8),
                      Text(
                        notification.message,
                        style: AmberDuskTokens.typography.body.copyWith(
                          color: amberColors.textSubtle,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Unread indicator remains as a compact trailing state marker
                // for users scanning the right edge of the sheet.
                if (!isRead) ...[
                  const SizedBox(width: AppDimens.p8),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: AppDimens.p10,
                      height: AppDimens.p10,
                      decoration: BoxDecoration(
                        color: amberColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Type-colored icon with semantic token mapping.
  Widget _buildIcon(BuildContext context) {
    final style = _typeStyle(context);

    return Container(
      width: AppDimens.avatarMedium,
      height: AppDimens.avatarMedium,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppDimens.r16),
      ),
      child: Icon(
        style.icon,
        color: style.color,
        size: AppLayout.iconStandard,
      ),
    );
  }

  /// Maps notification type to an icon, label, and semantic color pair.
  _NotificationTypeStyle _typeStyle(BuildContext context) {
    final amberColors = context.amberColors;
    IconData icon;
    Color color;
    Color background;
    String label;

    // Map notification types to semantic colors.
    switch (notification.type) {
      case NotificationType.offer:
        icon = Icons.local_offer_outlined;
        color = amberColors.warning;
        background = amberColors.warningMuted;
        label = 'Offer';
      case NotificationType.message:
        icon = Icons.chat_bubble_outline;
        color = amberColors.primary;
        background = amberColors.infoMuted;
        label = 'Message';
      case NotificationType.booking:
        icon = Icons.calendar_today_outlined;
        color = amberColors.primary;
        background = amberColors.infoMuted;
        label = 'Booking';
      case NotificationType.payment:
        icon = Icons.payment_outlined;
        color = amberColors.warning;
        background = amberColors.warningMuted;
        label = 'Payment';
      case NotificationType.review:
        icon = Icons.star_outline;
        color = amberColors.warning;
        background = amberColors.warningMuted;
        label = 'Review';
      case NotificationType.task:
        icon = Icons.assignment_outlined;
        color = amberColors.primary;
        background = amberColors.infoMuted;
        label = 'Task';
      case NotificationType.system:
        icon = Icons.notifications_none;
        color = amberColors.textSubtle;
        background = amberColors.surfaceHighest;
        label = 'System';
    }

    return _NotificationTypeStyle(
      icon: icon,
      color: color,
      background: background,
      label: label,
    );
  }
}

/// Visual tokens for one notification type.
class _NotificationTypeStyle {
  const _NotificationTypeStyle({
    required this.icon,
    required this.color,
    required this.background,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String label;
}

/// Compact type label for notification rows.
class _TypePill extends StatelessWidget {
  const _TypePill({required this.style});

  final _NotificationTypeStyle style;

  @override
  Widget build(BuildContext context) {
    return _StatusPill(
      label: style.label,
      foreground: style.color,
      background: style.background,
    );
  }
}

/// Time metadata rendered as a low-emphasis pill.
class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;

    return _StatusPill(
      label: label,
      foreground: amberColors.textSubtle,
      background: amberColors.surfaceHighest.withValues(alpha: 0.58),
    );
  }
}

/// Shared pill used for notification type, unread, and time metadata.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p8,
        vertical: AppDimens.p4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AmberDuskTokens.radius.pill),
      ),
      child: Text(
        label,
        style: AmberDuskTokens.typography.chip.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
