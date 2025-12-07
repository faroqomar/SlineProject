import 'package:sline_app/features/notifications/models/notification_model.dart';

class NotificationService {
  Future<List<NotificationModel>> getNotifications() async {
    // Mock data for now
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      NotificationModel(
        id: '1',
        type: NotificationType.order,
        title: 'Order Update',
        message: 'Nexus Corp marked your order as Completed.',
        time: DateTime.now().subtract(const Duration(minutes: 2)),
        isRead: false,
        group: 'Today',
      ),
      NotificationModel(
        id: '2',
        type: NotificationType.proposal,
        title: 'New Proposal',
        message: 'David Chen applied to your Logo Design job.',
        time: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        group: 'Today',
      ),
      NotificationModel(
        id: '3',
        type: NotificationType.system,
        title: 'System Alert',
        message: 'Your password was changed successfully.',
        time: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
        group: 'Today',
      ),
      NotificationModel(
        id: '4',
        type: NotificationType.payment,
        title: 'Payment Received',
        message: 'You received \$250.00 from TravelLife.',
        time: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        group: 'Yesterday',
      ),
    ];
  }
}
