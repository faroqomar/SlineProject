import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';
import 'package:sline_app/features/notifications/view/widgets/notification_tile.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';

/// Stable keys for tests (see .TODO/TEST_notifications_2026-03-01.md).
class NotificationsModalKeys {
  NotificationsModalKeys._();
  static const Key modal = ValueKey<String>('notifications_modal');
  static const Key loading = ValueKey<String>('notifications_loading');
  static const Key empty = ValueKey<String>('notifications_empty');
  static const Key error = ValueKey<String>('notifications_error');
  static Key row(String id) => ValueKey<String>('notification_row_$id');
}

class NotificationsModal extends StatelessWidget {
  const NotificationsModal({super.key});

  /// Shows the modal and returns the selected [NotificationItem] when user taps a row, or null if dismissed.
  static Future<NotificationItem?> show(BuildContext context) {
    return showModalBottomSheet<NotificationItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      key: NotificationsModalKeys.modal,
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
                    if (vm.error != null && vm.notifications.isEmpty) {
                      return Center(
                        key: NotificationsModalKeys.error,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(vm.error!, textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => vm.retry(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (vm.isLoading && vm.notifications.isEmpty) {
                      return const Center(
                        key: NotificationsModalKeys.loading,
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (vm.notifications.isEmpty) {
                      return const Center(
                        key: NotificationsModalKeys.empty,
                        child: Text('No notifications yet'),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: vm.notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notification = vm.notifications[index];
                        return NotificationTile(
                          key: NotificationsModalKeys.row(notification.id),
                          notification: notification,
                          onTap: () {
                            vm.markAsRead(notification.id).then((_) {
                              if (context.mounted) {
                                Navigator.pop(context, notification);
                              }
                            });
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
