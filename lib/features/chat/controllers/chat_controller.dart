import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/message_service.dart';
import '../../../core/services/logger_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Controller for managing chat state and logic
class ChatController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MessageService _messageService = MessageService();

  List<Conversation> conversations = [];
  List<Message> currentMessages = [];

  bool isLoadingConversations = false;
  bool isLoadingMessages = false;

  Conversation? activeConversation;

  StreamSubscription<Message?>? _subscription;
  StreamSubscription<List<Map<String, dynamic>>>? _convoSubscription;

  /// Mark messages as delivered and seen for the active conversation (if any).
  /// Why: called when opening the chat or when user scrolls to bottom.
  Future<void> markReceiptsForActive({bool delivered = true, bool seen = false}) async {
    if (activeConversation == null) return;
    try {
      if (delivered) {
        await _messageService.markDelivered(activeConversation!.id);
      }
      if (seen) {
        await _messageService.markSeen(activeConversation!.id);
      }
    } catch (e) {
      AppLogger.e('Error marking receipts: $e');
    }
  }

  /// Fetch all conversations for the current user
  Future<void> fetchConversations() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isLoadingConversations = true;
    notifyListeners();

    try {
      conversations =
          await _messageService.getUserConversations(user.id);
      // Info: Conversations fetched successfully
      AppLogger.i('✅ Conversations fetched: ${conversations.length}');
    } catch (e) {
      // Error: Failed to fetch conversations
      AppLogger.e('Error fetching conversations: $e');
    } finally {
      isLoadingConversations = false;
      notifyListeners();
    }
  }

  /// Fetch messages for a given conversation
  Future<void> fetchMessages(String conversationId) async {
    isLoadingMessages = true;
    notifyListeners();

    try {
      currentMessages =
          await _messageService.getMessages(conversationId);
      final idx = conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        activeConversation = conversations[idx];
      }
    } catch (e) {
      // Error: Failed to fetch messages
      AppLogger.e('Error fetching messages: $e');
    } finally {
      isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Send a new message in the active conversation
  Future<void> sendMessage(
    String content, {
    String? attachmentUrl,
    String? attachmentType,
    String? attachmentName,
    int? attachmentSize,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null || activeConversation == null) return;

    // Determine receiver (the other participant)
    final receiverId = activeConversation!.user1Id == user.id
        ? activeConversation!.user2Id
        : activeConversation!.user1Id;

    try {
      final message = await _messageService.sendMessage(
        conversationId: activeConversation!.id,
        senderId: user.id,
        receiverId: receiverId,
        content: content,
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
        attachmentName: attachmentName,
        attachmentSize: attachmentSize,
      );

      // Append the exact server-returned message (keeps attachment & receipt fields)
      currentMessages.add(message);
      if (hasListeners) notifyListeners();
    } catch (e) {
      // Error: Failed to send message
      AppLogger.e('Error sending message: $e');
    }
  }

  void subscribeToActiveConversation() {
    if (activeConversation != null) {
      AppLogger.i('[CHAT] subscribe: convo=${activeConversation!.id}');
    }
    // Removed double-subscribe prevention block.

    if (activeConversation == null) return;

    // Cancel any previous subscriptions
    _subscription?.cancel();

    // Messages realtime
    _subscription = _messageService
        .subscribeToMessages(activeConversation!.id)
        .listen((message) async {
      if (message == null) return;

      // Only upsert if message belongs to the active conversation
      if (activeConversation != null &&
          message.conversationId == activeConversation!.id) {
        final i = currentMessages.indexWhere((m) => m.id == message.id);
        if (i >= 0) {
          currentMessages[i] = message;
        } else {
          currentMessages.add(message);
          currentMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }
        await markReceiptsForActive(delivered: true, seen: false);
        if (hasListeners) notifyListeners();
      }
    }, onError: (error, [stack]) {
      AppLogger.e('Realtime subscription error: $error');
    });

    // On open: mark delivered immediately
    unawaited(markReceiptsForActive(delivered: true, seen: false));
  }

  /// Subscribe to realtime updates for user conversations
  void subscribeToUserConversations() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Cancel old subscription
    _convoSubscription?.cancel();

    _convoSubscription = _messageService
        .subscribeToConversations(user.id)
        .listen((rows) {
      try {
        conversations = rows.map((json) {
          // Enrich raw json with additional fields for display
          final isUser1 = json['user1_id'] == user.id;
          final otherUser = isUser1 ? json['user2'] : json['user1'];

          return Conversation.fromJson({
            ...json,
            'task_title': json['tasks']?['title'] ?? 'Untitled Task',
            'user1_name': json['user1']?['full_name'] ?? 'User',
            'user2_name': json['user2']?['full_name'] ?? 'User',
            'other_user_name': otherUser?['full_name'],
            'other_user_avatar': otherUser?['avatar_url'],
          });
        }).toList();

        AppLogger.i('✅ Conversations updated in controller: ${conversations.length}');
        notifyListeners();
      } catch (e) {
        AppLogger.e('Error parsing realtime conversations: $e');
      }
    }, onError: (error) {
      AppLogger.e('Realtime conversation subscription error: $error');
    });
  }

  void unsubscribeFromUserConversations() {
    _convoSubscription?.cancel();
    _convoSubscription = null;
  }

  /// Call this when leaving the chat screen to avoid memory leaks
  void unsubscribeFromConversation() {
    AppLogger.d('[CHAT] unsubscribe from active conversation');
    _subscription?.cancel();
    _subscription = null;
  }
}
