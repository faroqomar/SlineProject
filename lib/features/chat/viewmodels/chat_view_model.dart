import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/chat_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../../../core/services/logger_service.dart';
import '../attachments/services/send_attachment_usecase.dart';

/// ChatViewModel — MVVM state holder for Chat feature.
///
/// Architecture:
/// - Uses ChatRepository for data access (never calls Supabase directly)
/// - Manages realtime subscriptions for live message updates
/// - Tracks subscription state via `_mounted` flag to prevent memory leaks
///
/// Memory Management:
/// - Subscriptions are stored in `_msgSub` and `_convoSub`
/// - dispose() cancels all subscriptions and sets `_mounted = false`
/// - `_notify()` checks `_mounted` before calling notifyListeners()
///
/// Why separate conversation/message subscriptions:
/// - Conversation list subscription runs while on messages list screen
/// - Active conversation subscription runs only when viewing a specific chat
/// - This prevents unnecessary updates and conserves resources
class ChatViewModel extends ChangeNotifier {
  ChatViewModel({SupabaseClient? client})
    : _repo = ChatRepository(client ?? Supabase.instance.client);

  final ChatRepository _repo;

  final List<Conversation> conversations = [];
  final List<Message> currentMessages = [];

  bool isLoadingConversations = false;
  bool isLoadingMessages = false;

  Conversation? activeConversation;

  StreamSubscription<Message?>? _msgSub;
  StreamSubscription<List<Map<String, dynamic>>>? _convoSub;

  bool _mounted = true;
  @override
  void dispose() {
    _mounted = false;
    _msgSub?.cancel();
    _convoSub?.cancel();
    super.dispose();
  }

  void _notify() {
    if (_mounted) notifyListeners();
  }

  /// Expose current authenticated user id for UI decisions when needed.
  String? get currentUserId => _repo.currentUser?.id;

  // --- Receipts ---
  Future<void> markReceiptsForActive({
    bool delivered = true,
    bool seen = false,
  }) async {
    if (activeConversation == null) return;
    try {
      if (delivered) await _repo.markDelivered(activeConversation!.id);
      if (seen) await _repo.markSeen(activeConversation!.id);
    } catch (e) {
      AppLogger.e('Error marking receipts: $e');
    }
  }

  // --- Conversations ---
  Future<void> fetchConversations() async {
    final user = _repo.currentUser;
    if (user == null) return;
    isLoadingConversations = true;
    _notify();
    try {
      final list = await _repo.getUserConversations(user.id);
      conversations
        ..clear()
        ..addAll(list);
      AppLogger.i('✅ Conversations fetched: ${conversations.length}');
    } catch (e) {
      AppLogger.e('Error fetching conversations: $e');
    } finally {
      isLoadingConversations = false;
      _notify();
    }
  }

  void subscribeToUserConversations() {
    final user = _repo.currentUser;
    if (user == null) return;
    _convoSub?.cancel();
    _convoSub = _repo
        .subscribeToConversations(user.id)
        .listen(
          (rows) {
            try {
              final updated = rows.map((json) {
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
              conversations
                ..clear()
                ..addAll(updated);
              AppLogger.i(
                '✅ Conversations updated in viewmodel: ${conversations.length}',
              );
              _notify();
            } catch (e) {
              AppLogger.e('Error parsing realtime conversations: $e');
            }
          },
          onError: (error) {
            AppLogger.e('Realtime conversation subscription error: $error');
          },
        );
  }

  void unsubscribeFromUserConversations() {
    _convoSub?.cancel();
    _convoSub = null;
  }

  // Utility to start or fetch a conversation (kept simple for UI usage)
  Future<Conversation> createOrGetConversation({
    String? taskId,
    required String user1Id,
    required String user2Id,
  }) {
    return _repo.createOrGetConversation(
      taskId: taskId,
      user1Id: user1Id,
      user2Id: user2Id,
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _repo.deleteConversation(conversationId);
      conversations.removeWhere((c) => c.id == conversationId);
      _notify(); // Update UI immediately
      AppLogger.i('Deleted conversation: $conversationId');
    } catch (e) {
      AppLogger.e('Error deleting conversation: $e');
      rethrow;
    }
  }

  // --- Messages ---
  Future<void> fetchMessages(String conversationId) async {
    isLoadingMessages = true;
    _notify();
    try {
      final msgs = await _repo.getMessages(conversationId);
      currentMessages
        ..clear()
        ..addAll(msgs);
      final idx = conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) activeConversation = conversations[idx];
    } catch (e) {
      AppLogger.e('Error fetching messages: $e');
    } finally {
      isLoadingMessages = false;
      _notify();
    }
  }

  Future<void> sendMessage(
    String content, {
    String? attachmentUrl,
    String? attachmentType,
    String? attachmentName,
    int? attachmentSize,
    String? messageType,
    Map<String, dynamic>? payload,
  }) async {
    final user = _repo.currentUser;
    if (user == null || activeConversation == null) return;

    final receiverId = activeConversation!.user1Id == user.id
        ? activeConversation!.user2Id
        : activeConversation!.user1Id;

    try {
      final message = await _repo.sendMessage(
        conversationId: activeConversation!.id,
        senderId: user.id,
        receiverId: receiverId,
        content: content,
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
        attachmentName: attachmentName,
        attachmentSize: attachmentSize,
        messageType: messageType,
        payload: payload,
      );
      currentMessages.add(message);
      _notify(); // Update UI
    } catch (e) {
      AppLogger.e('Error sending message: $e');
    }
  }

  Future<void> acceptOffer(Message offerMsg) async {
    // Send "Offer Accepted" message
    await sendMessage(
      'Offer Accepted',
      messageType: 'offerAccepted',
      payload: {'original_offer_id': offerMsg.id},
    );
    // TODO: The backend trigger 'trg_messages_after_insert_offer_accept' handles the rest
  }

  Future<void> rejectOffer(Message offerMsg) async {
    // Send "Offer Rejected" message
    await sendMessage(
      'Offer Rejected',
      messageType: 'offerRejected',
      payload: {'original_offer_id': offerMsg.id},
    );
  }

  void subscribeToActiveConversation() {
    if (activeConversation == null) return;
    _msgSub?.cancel();
    _msgSub = _repo
        .subscribeToMessages(activeConversation!.id)
        .listen(
          (message) async {
            if (message == null) return;
            if (activeConversation != null &&
                message.conversationId == activeConversation!.id) {
              final i = currentMessages.indexWhere((m) => m.id == message.id);
              if (i >= 0) {
                currentMessages[i] = message;
              } else {
                currentMessages.add(message);
                currentMessages.sort(
                  (a, b) => a.createdAt.compareTo(b.createdAt),
                );
              }
              await markReceiptsForActive(delivered: true, seen: false);
              _notify();
            }
          },
          onError: (error) {
            AppLogger.e('Realtime subscription error: $error');
          },
        );

    // On open: mark delivered immediately
    unawaited(markReceiptsForActive(delivered: true, seen: false));
  }

  void unsubscribeFromConversation() {
    _msgSub?.cancel();
    _msgSub = null;
  }

  /// High-level helper to send an image attachment for the active conversation.
  /// UI should not need to access Supabase directly.
  Future<void> sendImageForActive() async {
    final me = currentUserId;
    final convo = activeConversation;
    if (me == null || convo == null) return;
    final receiverId = convo.user1Id == me ? convo.user2Id : convo.user1Id;
    await sendImageAttachment(
      conversationId: convo.id,
      senderId: me,
      receiverId: receiverId,
    );
  }
}
