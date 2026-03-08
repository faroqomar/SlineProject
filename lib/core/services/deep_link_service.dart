import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import '../../features/notifications/models/notification_model.dart';
import '../../features/dashboard/models/activity_log.dart';
import '../../core/services/logger_service.dart';
import '../../features/tasks/services/task_service.dart';
import '../../features/booking/services/booking_service.dart';
import '../../features/chat/services/message_service.dart';
import '../../features/tasks/view/task_details_screen.dart';
import '../../features/booking/view/booking_details_screen.dart';
import '../../features/chat/view/chat_screen.dart';
import '../../features/direct_offers/view/direct_offer_details_screen.dart';
import '../../features/work/view/work_item_details_screen.dart';
import '../../features/profile/view/public_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

/// Service to handle deep linking and routing from notifications/activity feed.
/// Supported entity types (task_request is handled in [handleNotification] via metadata).
class DeepLinkService {
  static const List<String> supportedEntityTypes = [
    'task',
    'offer',
    'booking',
    'conversation',
    'message',
    'direct_offer',
    'directoffer',
    'profile',
    'user',
  ];

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
  /// For task_request, routes using metadata: conversation_id first, else task_id.
  Future<void> handleNotification(
    BuildContext context,
    NotificationItem item,
  ) async {
    AppLogger.i(
      'handleNotification: entityType=${item.relatedEntityType} id=${item.relatedEntityId}',
      tag: 'DeepLink',
    );
    final type = item.relatedEntityType?.toLowerCase();
    if (type == 'task_request') {
      final convId = item.metadata['conversation_id']?.toString();
      final taskId = item.metadata['task_id']?.toString();
      if (convId != null && convId.isNotEmpty) {
        AppLogger.d(
          'task_request: routing to conversation $convId',
          tag: 'DeepLink',
        );
        await navigateToEntity(context, 'conversation', convId);
      } else if (taskId != null && taskId.isNotEmpty) {
        AppLogger.d('task_request: routing to task $taskId', tag: 'DeepLink');
        await navigateToEntity(context, 'task', taskId);
      } else {
        AppLogger.w(
          'task_request: no conversation_id or task_id in metadata',
          tag: 'DeepLink',
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open this notification.')),
        );
      }
      return;
    }
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
      tag: 'DeepLink',
    );
    await navigateToEntity(context, activity.entityType, activity.entityId);
  }

  /// Open the chat screen for a conversation (e.g. from direct offer details).
  Future<void> openConversation(
    BuildContext context,
    String conversationId,
  ) async {
    return _navigateToConversation(context, conversationId);
  }

  /// Handle tap on a dashboard work item.
  /// Uses [type] as string ("task", "booking", or "directOffer") and [id].
  /// For direct offers, opens [DirectOfferDetailsScreen]; [conversationId] is passed for "Open chat".
  Future<dynamic> handleWorkItem(
    BuildContext context,
    String type,
    String id, {
    String? conversationId,
  }) async {
    AppLogger.i('Handling work item tap: $type - $id', tag: 'DeepLink');
    if (!context.mounted) return;

    final typeLower = type.toLowerCase();
    if (typeLower == 'directoffer') {
      return Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DirectOfferDetailsScreen(
            offerId: id,
            conversationId: conversationId,
          ),
        ),
      );
    }

    final workItemType = typeLower == 'booking'
        ? WorkItemType.booking
        : WorkItemType.task;

    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkItemDetailsScreen(id: id, type: workItemType),
      ),
    );
  }

  /// Centralized navigation logic based on entity type and ID.
  Future<void> navigateToEntity(
    BuildContext context,
    String? type,
    String? id,
  ) async {
    if (id == null || type == null) {
      AppLogger.w('Cannot navigate: ID or Type is null', tag: 'DeepLink');
      return;
    }

    try {
      switch (type.toLowerCase()) {
        case 'task':
        case 'offer': // Offers usually link to the task details or inbox
          await _navigateToTask(context, id);
          AppLogger.i(
            'deep_link_routed entityType=$type id=$id',
            tag: 'DeepLink',
          );
          break;
        case 'booking':
          await _navigateToBooking(context, id);
          AppLogger.i(
            'deep_link_routed entityType=$type id=$id',
            tag: 'DeepLink',
          );
          break;
        case 'conversation':
        case 'message':
          await _navigateToConversation(context, id);
          AppLogger.i(
            'deep_link_routed entityType=$type id=$id',
            tag: 'DeepLink',
          );
          break;
        case 'direct_offer':
        case 'directoffer':
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  DirectOfferDetailsScreen(offerId: id, conversationId: null),
            ),
          );
          AppLogger.i(
            'deep_link_routed entityType=$type id=$id',
            tag: 'DeepLink',
          );
          break;
        case 'profile':
          _navigateToProfile(context);
          AppLogger.i(
            'deep_link_routed entityType=$type id=$id',
            tag: 'DeepLink',
          );
          break;
        case 'user':
          _navigateToUserProfile(context, id);
          AppLogger.i(
            'deep_link_routed entityType=$type id=$id',
            tag: 'DeepLink',
          );
          break;
        default:
          AppLogger.w(
            'Notification route not supported: entityType=$type',
            tag: 'DeepLink',
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open this item type: $type')),
          );
      }
    } catch (e) {
      AppLogger.e('Deep link navigation failed', error: e, tag: 'DeepLink');
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

  Future<void> _navigateToProfile(BuildContext context) async {
    // 1. Clear stack to main
    Navigator.popUntil(context, (route) => route.isFirst);

    // 2. Switch to Profile tab (Index 5)
    if (context.mounted) {
      final navProvider = Provider.of<NavigationProvider>(
        context,
        listen: false,
      );
      navProvider.setCurrentIndex(5);
    }
  }

  void _navigateToUserProfile(BuildContext context, String userId) {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: userId)),
    );
  }
}
