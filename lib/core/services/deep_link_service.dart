import 'package:flutter/material.dart';
import '../../features/notifications/models/notification_model.dart';
import '../../features/dashboard/models/activity_log.dart';
import '../../core/services/logger_service.dart';
import '../../features/tasks/services/task_service.dart';
import '../../features/booking/services/booking_service.dart';
import '../../features/chat/services/message_service.dart';
import '../../features/tasks/view/task_details_screen.dart';
import '../../features/booking/view/booking_details_screen.dart';
import '../../features/chat/view/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle deep linking and routing from notifications/activity feed.
class DeepLinkService {
  final TaskService _taskService;
  final BookingService _bookingService;
  final MessageService _messageService;

  DeepLinkService({
    TaskService? taskService,
    BookingService? bookingService,
    MessageService? messageService,
  }) : _taskService = taskService ?? TaskService(),
       _bookingService =
           bookingService ?? BookingService(Supabase.instance.client),
       _messageService = messageService ?? MessageService();

  /// Handle tap on a notification item.
  Future<void> handleNotification(
    BuildContext context,
    NotificationItem item,
  ) async {
    AppLogger.i(
      'Handling notification tap: ${item.type} - ${item.relatedEntityId}',
    );
    await navigateToEntity(
      context,
      item.relatedEntityType,
      item.relatedEntityId,
    );
  }

  /// Handle tap on an activity log item.
  Future<void> handleActivity(
    BuildContext context,
    ActivityLog activity,
  ) async {
    AppLogger.i(
      'Handling activity tap: ${activity.entityType} - ${activity.entityId}',
    );
    await navigateToEntity(context, activity.entityType, activity.entityId);
  }

  /// Handle tap on a dashboard work item.
  /// Uses [type] as string ("task" or "booking") and [id].
  Future<void> handleWorkItem(
    BuildContext context,
    String type,
    String id,
  ) async {
    AppLogger.i('Handling work item tap: $type - $id');
    await navigateToEntity(context, type, id);
  }

  /// Centralized navigation logic based on entity type and ID.
  Future<void> navigateToEntity(
    BuildContext context,
    String? type,
    String? id,
  ) async {
    if (id == null || type == null) {
      AppLogger.w('Cannot navigate: ID or Type is null');
      return;
    }

    try {
      switch (type.toLowerCase()) {
        case 'task':
        case 'offer': // Offers usually link to the task details or inbox
          await _navigateToTask(context, id);
          break;
        case 'booking':
          await _navigateToBooking(context, id);
          break;
        case 'conversation':
        case 'message':
          await _navigateToConversation(context, id);
          break;
        default:
          AppLogger.w('Unknown entity type for deep link: $type');
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open this item type: $type')),
          );
      }
    } catch (e) {
      AppLogger.e('Deep link navigation failed', error: e);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open item. Please try again.')),
      );
    }
  }

  Future<void> _navigateToTask(BuildContext context, String taskId) async {
    // Show loading indicator
    if (!context.mounted) return;
    _showLoading(context);

    try {
      final task = await _taskService.getTaskById(taskId);
      if (!context.mounted) return;
      _hideLoading(context);

      if (task != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
        );
      } else if (context.mounted) {
        _showError(context, 'Task not found');
      }
    } catch (e) {
      if (!context.mounted) return;
      _hideLoading(context);
      rethrow;
    }
  }

  Future<void> _navigateToBooking(
    BuildContext context,
    String bookingId,
  ) async {
    if (!context.mounted) return;
    _showLoading(context);

    try {
      final booking = await _bookingService.getBookingById(bookingId);
      if (!context.mounted) return;
      _hideLoading(context);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailsScreen(booking: booking),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      _hideLoading(context);
      rethrow;
    }
  }

  Future<void> _navigateToConversation(
    BuildContext context,
    String conversationId,
  ) async {
    if (!context.mounted) return;
    _showLoading(context);

    try {
      // MessageService has getConversationById
      final conversation = await _messageService.getConversationById(
        conversationId,
      );
      if (!context.mounted) return;
      _hideLoading(context);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: conversation),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      _hideLoading(context);
      rethrow;
    }
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoading(BuildContext context) {
    if (context.mounted) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(); // Perform pop on root navigator to close dialog
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
