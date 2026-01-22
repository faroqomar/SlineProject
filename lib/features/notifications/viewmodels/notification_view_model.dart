import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/loading_utils.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/services/message_service.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'package:sline_app/features/booking/view/booking_details_screen.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';
import 'package:provider/provider.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _service;
  late final MessageService _messageService;
  late final TaskService _taskService;

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;

  NotificationViewModel({
    NotificationService? service,
    MessageService? messageService,
    TaskService? taskService,
  }) : _service = service ?? NotificationService() {
    _messageService = messageService ?? MessageService();
    _taskService = taskService ?? TaskService();
    _init();
  }

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _init() {
    // Auto-load on init
    _listenToNotifications();
   }

  void _listenToNotifications() {
    _isLoading = true;
    notifyListeners();

    _service.streamNotifications().listen(
      (items) {
        _notifications = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        AppLogger.e('Error streaming notifications', error: e);
        _error = 'Failed to load notifications';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> handleNotificationTap(
    BuildContext context,
    NotificationItem item,
  ) async {
    // 1. Mark as read immediately
    markAsRead(item.id);

    // 2. Handle Deep Linking
    final entityId = item.relatedEntityId;
    if (entityId == null) return;

    try {
      LoadingUtils.show(context);

      switch (item.type) {
        case NotificationType.message:
        case NotificationType.offer:
          // For message/offer, entityId is usually Conversation ID
          // EXCEPT if legacy logic used TaskId.
          // MessageService sets relatedEntityId = conversationId for offers.
          // If type is offer, we might want to go to task details proposals.
          // BUT if relatedID is conversation, we need to fetch convo first.
          final conversation = await _messageService.getConversationById(
            entityId,
          );

          if (!context.mounted) return;
          LoadingUtils.hide(context);

          if (item.type == NotificationType.offer) {
            // "New Offer" -> Open Task Details -> Proposals
            if (conversation.taskId != null) {
              _navigateToTaskProposals(context, conversation.taskId!);
            } else {
              // Fallback: Just open chat if no task linked (shouldn't happen for offers)
              _navigateToChat(context, conversation);
            }
          } else {
            // "New Message" -> Open Chat
            _navigateToChat(context, conversation);
          }
          break;

        case NotificationType.task:
          // entityId is Task ID
          final task = await _taskService.getTaskById(entityId);
          if (!context.mounted) return;
          LoadingUtils.hide(context);

          if (task != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
            );
          }
          break;

        case NotificationType.booking:
          // entityId is Booking ID
          // We need to fetch booking -> get taskId -> fetch task
          // We need BookingService for this.
          // Since we can't easily inject it here without changing main.dart (and we want to avoid that risk),
          // we'll try to fetch the booking using a direct Supabase query or a new service instance if needed.
          // Ideally: inject BookingService.
          // Fallback: direct simple query since VM is transient? No, proper way is create internal service.
          // Assuming we add BookingService to imports.

          try {
            final bookingVm = context.read<BookingViewModel>();
            final booking = await bookingVm.getBookingById(entityId);

            if (!context.mounted) return;
            LoadingUtils.hide(context);

            if (booking != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingDetailsScreen(booking: booking),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              LoadingUtils.hide(context);
            }
            AppLogger.e('Failed to navigate to booking', error: e);
          }
          break;

        default:
          LoadingUtils.hide(context);
          break;
      }
    } catch (e) {
      if (context.mounted) {
        LoadingUtils.hide(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load content: $e')));
      }
    }
  }

  Future<void> _navigateToChat(
    BuildContext context,
    Conversation conversation,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: conversation)),
    );
  }

  Future<void> _navigateToTaskProposals(
    BuildContext context,
    String taskId,
  ) async {
    final task = await _taskService.getTaskById(taskId);
    if (!context.mounted) return;

    if (task != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailsScreen(
            task: task,
            showProposalsInitially: true, // Auto-open proposals
          ),
        ),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    // We can't modify the item directly since it's immutable
    // But we can depend on the stream to update us shortly.
    // However, for immediate UI feedback, we often want an optimistic update.
    // For now, let's just trigger the service call and let the stream handle the update.

    try {
      await _service.markAsRead(id);
    } catch (e) {
      _error = 'Failed to update notification';
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
    } catch (e) {
      _error = 'Failed to mark all as read';
      notifyListeners();
    }
  }
}
