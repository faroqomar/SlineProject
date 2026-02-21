import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';
import 'package:sline_app/features/notifications/view/notifications_modal.dart';

class NotificationBadgeButton extends StatelessWidget {
  const NotificationBadgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationViewModel>(
      builder: (context, vm, child) {
        final count = vm.unreadCount;
        final colorScheme = context.colorScheme;

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const NotificationsModal(),
            );
          },
          child: GlassContainer(
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
