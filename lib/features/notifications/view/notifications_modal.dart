import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';

class NotificationsModal extends StatelessWidget {
  const NotificationsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => NotificationViewModel()..loadNotifications(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.r30)),
          border: Border(top: BorderSide(color: colorScheme.cardBorder)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.p24, AppDimens.p24, AppDimens.p24, AppDimens.p12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: AppTypography.h4.copyWith(color: colorScheme.text),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      child: Icon(Icons.close, size: 18, color: colorScheme.text),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // List
            Expanded(
              child: Consumer<NotificationViewModel>(
                builder: (context, vm, child) {
                  if (vm.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  return RefreshIndicator(
                    onRefresh: vm.loadNotifications,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimens.p24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (vm.notifications.isEmpty)
                            Center(child: Text('No notifications', style: AppTypography.bodyMedium.copyWith(color: colorScheme.textSecondary))),
                          
                          ...vm.groups.map((group) {
                            final groupItems = vm.notifications.where((n) => n.group == group).toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildGroupLabel(group.toUpperCase(), colorScheme),
                                ...groupItems.map((n) => _buildNotificationItem(n, colorScheme)),
                                const SizedBox(height: AppDimens.p24),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupLabel(String label, AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p12, left: AppDimens.p4),
      child: Text(
        label,
        style: AppTypography.captionBold.copyWith(
          color: colorScheme.textSecondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel n, AppColorScheme colorScheme) {
    Color iconColor;
    IconData icon;
    
    switch (n.type) {
      case NotificationType.order:
        iconColor = AppColors.teal;
        icon = Icons.shopping_bag;
        break;
      case NotificationType.proposal:
        iconColor = AppColors.lightTeal;
        icon = Icons.description;
        break;
      case NotificationType.payment:
        iconColor = AppColors.gold;
        icon = Icons.attach_money;
        break;
      default:
        iconColor = Colors.grey;
        icon = Icons.info;
    }

    // Using time ago logic (simplified for now or use util)
    final timeString = '${n.time.hour}:${n.time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.inputBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      n.title,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.text,
                      ),
                    ),
                    Text(
                      timeString,
                      style: AppTypography.micro.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  n.message,
                  style: AppTypography.micro.copyWith(
                    color: colorScheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!n.isRead)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(radius: 4, backgroundColor: AppColors.lightRed),
            ),
        ],
      ),
    );
  }
}
