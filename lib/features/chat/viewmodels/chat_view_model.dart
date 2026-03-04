import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/chat_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/account_guard_service.dart';
import '../attachments/services/send_attachment_usecase.dart';
import '../../tasks/models/task_model.dart';
import '../../direct_offers/services/direct_offers_service.dart';

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
    : _repo = ChatRepository(client ?? Supabase.instance.client),
      _accountGuardService = AccountGuardService(
        client: client ?? Supabase.instance.client,
      ),
      _directOffersService = DirectOffersService(
        client ?? Supabase.instance.client,
      );

  final ChatRepository _repo;
  final AccountGuardService _accountGuardService;
  final DirectOffersService _directOffersService;

  final List<Conversation> conversations = [];
  final List<Message> currentMessages = [];

  /// Cache of direct offer id -> status for current session (updated on accept/deliver/complete).
  final Map<String, String> _offerStatusCache = {};

  bool isLoadingConversations = false;
  bool isLoadingMessages = false;
  bool isSending = false;

  Conversation? activeConversation;

  StreamSubscription<List<Message>>? _msgSub;
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

  /// Resolved status for a direct offer (from cache or null to use payload).
  String? getOfferStatus(String? offerId) =>
      offerId != null ? _offerStatusCache[offerId] : null;

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

  /// High-level helper for UI to easily start/fetch a conversation linked to a Task.
  /// Relies on idempotency of createOrGetConversation.
  Future<Conversation> getTaskConversation(Task task) async {
    final freelancerId = task.assignedFreelancerId;
    if (freelancerId == null) {
      throw Exception(
        'Cannot start conversation: No freelancer assigned to this task.',
      );
    }

    try {
      return await createOrGetConversation(
        taskId: task.id,
        user1Id: task.userId,
        user2Id: freelancerId,
      );
    } catch (e) {
      AppLogger.e('Error getting task conversation for task ${task.id}: $e');
      rethrow;
    }
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
    await _ensureSensitiveActionAllowed();

    final receiverId = activeConversation!.user1Id == user.id
        ? activeConversation!.user2Id
        : activeConversation!.user1Id;

    isSending = true;
    _notify();
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
      _notify();
    } catch (e) {
      AppLogger.e('Error sending message', error: e);
      rethrow;
    } finally {
      isSending = false;
      _notify();
    }
  }

  /// Create a direct offer (DB row + offer message with offer_id). Realtime will add the message.
  Future<void> createDirectOffer({
    String? title,
    String? description,
    required int price,
    required int days,
  }) async {
    final user = _repo.currentUser;
    if (user == null || activeConversation == null) return;
    await _ensureSensitiveActionAllowed();
    final convo = activeConversation!;
    final clientId = convo.user1Id == user.id ? convo.user2Id : convo.user1Id;
    final freelancerId = user.id;
    final receiverId = clientId;

    isSending = true;
    _notify();
    try {
      await _directOffersService.createOffer(
        conversationId: convo.id,
        clientId: clientId,
        freelancerId: freelancerId,
        senderId: user.id,
        receiverId: receiverId,
        taskId: convo.taskId,
        title: title,
        description: description,
        price: price,
        days: days,
      );
    } catch (e) {
      AppLogger.e('Error creating direct offer', error: e);
      rethrow;
    } finally {
      isSending = false;
      _notify();
    }
  }

  Future<void> acceptOffer(Message offerMsg) async {
    final offerId = offerMsg.payload['offer_id'] as String?;
    if (offerId != null) {
      try {
        await _directOffersService.acceptOfferWithoutPayment(offerId);
        _offerStatusCache[offerId] = 'accepted';
        _notify();
        // Do not send 'offer_accepted' message for direct offers: conversation may be
        // task-linked and backend can treat that message as task acceptance. Acceptance
        // is recorded in work_log; payment happens from dashboard.
      } catch (e) {
        AppLogger.e('Error accepting offer', error: e);
        rethrow;
      }
    } else {
      await sendMessage(
        'Offer Accepted',
        messageType: 'offer_accepted',
        payload: {'original_offer_id': offerMsg.id},
      );
    }
  }

  Future<void> rejectOffer(Message offerMsg) async {
    final offerId = offerMsg.payload['offer_id'] as String?;
    if (offerId != null) {
      try {
        await _directOffersService.rejectOffer(offerId);
      } catch (e) {
        AppLogger.e('Error rejecting offer', error: e);
        rethrow;
      }
    }
    await sendMessage(
      'Offer Rejected',
      messageType: 'offer_rejected',
      payload: {
        'original_offer_id': offerMsg.id,
        if (offerId != null) 'offer_id': offerId,
      },
    );
  }

  /// Freelancer cancels a sent direct offer.
  Future<void> cancelOffer(String offerId) async {
    await _directOffersService.cancelOffer(offerId);
    _offerStatusCache[offerId] = 'canceled';
    _notify();
  }

  /// Freelancer marks direct offer work as delivered.
  Future<void> markOfferDelivered(String offerId) async {
    await _directOffersService.markDelivered(offerId);
    _offerStatusCache[offerId] = 'delivered';
    _notify();
  }

  /// Client completes (approve & release payment) for a delivered direct offer.
  Future<void> completeOffer(String offerId) async {
    await _directOffersService.completeOffer(offerId);
    _offerStatusCache[offerId] = 'completed';
    _notify();
  }

  void subscribeToActiveConversation() {
    if (activeConversation == null) return;
    _msgSub?.cancel();
    _msgSub = _repo
        .subscribeToMessages(activeConversation!.id)
        .listen(
          (messages) async {
            if (activeConversation == null) return;
            currentMessages
              ..clear()
              ..addAll(messages);
            await markReceiptsForActive(delivered: true, seen: false);
            _notify();
          },
          onError: (error) {
            AppLogger.e('Realtime subscription error', error: error);
          },
        );

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
    await _ensureSensitiveActionAllowed();
    final receiverId = convo.user1Id == me ? convo.user2Id : convo.user1Id;
    await sendImageAttachment(
      conversationId: convo.id,
      senderId: me,
      receiverId: receiverId,
    );
  }

  Future<void> _ensureSensitiveActionAllowed() async {
    final allowed = await _accountGuardService.canPerformSensitiveAction();
    if (!allowed) {
      throw Exception('Your account is restricted. Please contact support.');
    }
  }
}
