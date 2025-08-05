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
      activeConversation = conversations
          .firstWhere((c) => c.id == conversationId, orElse: () => activeConversation!);
    } catch (e) {
      // Error: Failed to fetch messages
      AppLogger.e('Error fetching messages: $e');
    } finally {
      isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Send a new message in the active conversation
  Future<void> sendMessage(String content) async {
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
      );

      // Ensure message has a createdAt timestamp for display
      final messageWithTime = Message(
        id: message.id,
        conversationId: message.conversationId,
        senderId: message.senderId,
        receiverId: message.receiverId,
        content: message.content,
        createdAt: message.createdAt ?? DateTime.now(),
      );

      currentMessages.add(messageWithTime);
      if (hasListeners) notifyListeners();
    } catch (e) {
      // Error: Failed to send message
      AppLogger.e('Error sending message: $e');
    }
  }

  void subscribeToActiveConversation() {
    if (activeConversation == null) return;

    // Cancel any previous subscription
    _subscription?.cancel();

    _subscription = _messageService
        .subscribeToMessages(activeConversation!.id)
        .listen((message) async {
      if (message != null && activeConversation != null) {
        await fetchMessages(activeConversation!.id);
        if (hasListeners) {
          AppLogger.i('📩 New message received and messages refreshed');
          notifyListeners();
        }
      }
    }, onError: (error) {
      AppLogger.e('Realtime subscription error: $error');
    });
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
    _subscription?.cancel();
    _subscription = null;
  }
}
