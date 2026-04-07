import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/notifications/view/notifications_modal.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';

class NotificationBadgeButton extends StatelessWidget {
  const NotificationBadgeButton({super.key});

  static const Key buttonKey = ValueKey<String>('notification_badge_button');

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationViewModel>(
      builder: (context, vm, child) {
        final count = vm.unreadCount;
        final colorScheme = context.colorScheme;

        return GestureDetector(
          key: buttonKey,
          onTap: () async {
            AppLogger.d(
              'Notification badge tapped, opening modal',
              tag: 'Notifications',
            );
            final selected = await NotificationsModal.show(context);
            if (selected != null && context.mounted) {
              AppLogger.i(
                'notification_tap entityType=${selected.relatedEntityType} id=${selected.relatedEntityId}',
                tag: 'Notifications',
              );
              await context.read<DeepLinkService>().handleNotification(
                context,
                entityType: selected.relatedEntityType,
                entityId: selected.relatedEntityId,
                metadata: selected.metadata,
              );
            }
          },
          child: AppCardContainer(
            borderRadius: BorderRadius.circular(AppDimens.r16),
            padding: const EdgeInsets.all(AppDimens.p12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: colorScheme.text,
                  size: AppDimens.p24,
                ),
                if (count > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.lightRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
