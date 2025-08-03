import 'package:flutter/material.dart';
import 'package:sline_app/features/chat/services/%20message_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  /// Fetch all conversations for the current user
  Future<void> fetchConversations() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isLoadingConversations = true;
    notifyListeners();

    try {
      conversations =
          await _messageService.getUserConversations(user.id);
      debugPrint('✅ Conversations fetched: ${conversations.length}');
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
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
      debugPrint('Error fetching messages: $e');
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
      currentMessages.add(message);
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  /// Subscribe to realtime updates for the active conversation
  void subscribeToActiveConversation() {
    if (activeConversation == null) return;

    _messageService
        .subscribeToMessages(activeConversation!.id)
        .listen((message) {
      if (message != null) { // Skip nulls
        currentMessages.add(message);
        notifyListeners();
      }
    });
  }
}
