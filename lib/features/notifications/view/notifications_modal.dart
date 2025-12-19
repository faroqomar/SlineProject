import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';
import 'package:sline_app/features/notifications/view/widgets/notification_tile.dart';

class NotificationsModal extends StatelessWidget {
  const NotificationsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimens.r20),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Consumer<NotificationViewModel>(
                  builder: (context, vm, child) {
                    if (vm.isLoading && vm.notifications.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (vm.notifications.isEmpty) {
                      return const Center(child: Text('No notifications yet'));
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: vm.notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notification = vm.notifications[index];
                        return NotificationTile(
                          notification: notification,
                          onTap: () {
                            vm.markAsRead(notification.id);
                            // TODO: Navigate to related entity
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Notifications', style: AppTypography.h3),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  context.read<NotificationViewModel>().markAllAsRead();
                },
                child: const Text('Mark all as read'),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
