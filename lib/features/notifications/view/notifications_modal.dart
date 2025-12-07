import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

class NotificationsModal extends StatelessWidget {
  const NotificationsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    // Mock Data
    final List<Map<String, dynamic>> notifications = [
      {
        'id': 1,
        'type': 'order',
        'title': 'Order Update',
        'message': 'Nexus Corp marked your order as Completed.',
        'time': '2m ago',
        'isRead': false,
        'group': 'Today'
      },
      {
        'id': 2,
        'type': 'proposal',
        'title': 'New Proposal',
        'message': 'David Chen applied to your Logo Design job.',
        'time': '1h ago',
        'isRead': false,
        'group': 'Today'
      },
      {
        'id': 3,
        'type': 'system',
        'title': 'System Alert',
        'message': 'Your password was changed successfully.',
        'time': '3h ago',
        'isRead': true,
        'group': 'Today'
      },
      {
        'id': 4,
        'type': 'payment',
        'title': 'Payment Received',
        'message': 'You received \$250.00 from TravelLife.',
        'time': 'Yesterday',
        'isRead': true,
        'group': 'Yesterday'
      },
    ];

    final today = notifications.where((n) => n['group'] == 'Today').toList();
    final yesterday = notifications.where((n) => n['group'] == 'Yesterday').toList();

    return Container(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (today.isNotEmpty) ...[
                    _buildGroupLabel('TODAY', colorScheme),
                    ...today.map((n) => _buildNotificationItem(n, colorScheme)),
                    const SizedBox(height: AppDimens.p24),
                  ],
                  if (yesterday.isNotEmpty) ...[
                    _buildGroupLabel('YESTERDAY', colorScheme),
                    ...yesterday.map((n) => _buildNotificationItem(n, colorScheme)),
                  ],
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildNotificationItem(Map<String, dynamic> n, AppColorScheme colorScheme) {
    final isRead = n['isRead'] as bool;
    final type = n['type'] as String;
    
    Color iconColor;
    IconData icon;
    
    switch (type) {
      case 'order':
        iconColor = AppColors.teal;
        icon = Icons.shopping_bag;
        break;
      case 'proposal':
        iconColor = AppColors.lightTeal;
        icon = Icons.description;
        break;
      case 'payment':
        iconColor = AppColors.gold;
        icon = Icons.attach_money;
        break;
      default:
        iconColor = Colors.grey;
        icon = Icons.info;
    }

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
                      n['title'],
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.text,
                      ),
                    ),
                    Text(
                      n['time'],
                      style: AppTypography.micro.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  n['message'],
                  style: AppTypography.micro.copyWith(
                    color: colorScheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!isRead)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(radius: 4, backgroundColor: AppColors.lightRed),
            ),
        ],
      ),
    );
  }
}
