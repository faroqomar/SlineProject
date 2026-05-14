import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sline_app/core/mixins/role_switch_aware.dart';
import 'package:sline_app/core/services/account_guard_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/role_switch_coordinator.dart';
import 'package:sline_app/features/chat/attachments/services/send_attachment_usecase.dart';
import 'package:sline_app/features/chat/attachments/services/upload_service.dart';
import 'package:sline_app/features/chat/data/chat_repository.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/models/message_model.dart';
import 'package:sline_app/features/chat/services/chat_realtime_merger.dart';
import 'package:sline_app/features/direct_offers/services/direct_offers_service.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ChatViewModel — MVVM state holder for Chat feature.
///
/// Architecture:
/// - Uses ChatRepository for data access (never calls Supabase directly)
/// - Manages realtime subscriptions for live message updates
/// - Tracks subscription state via `_mounted` flag to prevent memory leaks
///
/// Memory Management:
/// - Subscriptions are stored in `_msgSub` and `_inboxMsgSub`
/// - dispose() cancels all subscriptions and sets `_mounted = false`
/// - `_notify()` checks `_mounted` before calling notifyListeners()
///
/// Why separate conversation/message subscriptions:
/// - Conversation list subscription runs while on messages list screen
/// - Active conversation subscription runs only when viewing a specific chat
/// - This prevents unnecessary updates and conserves resources
class ChatViewModel extends ChangeNotifier with RoleSwitchAware {
  ChatViewModel({
    ChatRepository? repo,
    AccountGuardService? accountGuardService,
    DirectOffersService? directOffersService,
    SupabaseAttachmentUploader? attachmentUploader,
    SupabaseClient? client,
  }) : _repo = repo ?? ChatRepository(client ?? Supabase.instance.client),
       _accountGuardService =
           accountGuardService ??
           AccountGuardService(client: client ?? Supabase.instance.client),
       _directOffersService =
           directOffersService ??
           DirectOffersService(client ?? Supabase.instance.client),
       _attachmentUploader =
           attachmentUploader ??
           SupabaseAttachmentUploader(
             client: client ?? Supabase.instance.client,
           ) {
    // Register with coordinator for role switch teardown
    RoleSwitchCoordinator().register(this);
  }

  final ChatRepository _repo;
  final AccountGuardService _accountGuardService;
  final DirectOffersService _directOffersService;
  final SupabaseAttachmentUploader _attachmentUploader;

  final List<Conversation> conversations = [];
  final List<Message> currentMessages = [];

  /// Cache of direct offer id -> status for current session (updated on accept/deliver/complete).
  final Map<String, String> _offerStatusCache = {};

  bool isLoadingConversations = false;
  bool isLoadingMessages = false;
  bool isSending = false;
  bool isCreatingConversation = false;

  /// Error state for conversation creation (Chat Creation Matrix)
  String? conversationCreationError;

  Conversation? activeConversation;

  StreamSubscription<List<Message>>? _msgSub;
  StreamSubscription<List<Message>>? _inboxMsgSub;
  StreamSubscription<List<Map<String, dynamic>>>? _presenceSub;

  /// Debounce timer for refreshOfferStatusesForCurrentMessages (avoid calling on every emission).
  Timer? _offerRefreshDebounce;

  /// Guard: at most one in-flight getConversationById per conversation_id (prevents double fetch).
  final Set<String> _fetchingConversationIds = {};

  bool _mounted = true;

  /// Last message list for active conversation (for merge/dedupe on stream).
  List<Message> _lastMessages = [];

  /// Feature flag: presence and receipt ticks (null until first check).
  bool? _presenceReceiptsEnabled;

  /// Other participant typing state (15s TTL applied when reading).
  bool _otherUserTyping = false;
  DateTime? _presenceUpdatedAt;

  @override
  void dispose() {
    _mounted = false;
    _offerRefreshDebounce?.cancel();
    _offerRefreshDebounce = null;
    RoleSwitchCoordinator().unregister(this);
    unawaited(_msgSub?.cancel());
    unawaited(_inboxMsgSub?.cancel());
    unawaited(_presenceSub?.cancel());
    super.dispose();
  }

  /// RoleSwitchAware implementation: Teardown during role switch.
  ///
  /// This clears all cached data and disconnects from realtime channels
  /// to prevent data leakage between client and freelancer personas.
  @override
  Future<void> teardownForRoleSwitch() async {
    AppLogger.i('chat_teardown_role_switch', tag: 'ChatVM');

    // Cancel realtime subscriptions first
    unawaited(_msgSub?.cancel());
    _msgSub = null;
    unawaited(_inboxMsgSub?.cancel());
    _inboxMsgSub = null;
    unawaited(_presenceSub?.cancel());
    _presenceSub = null;

    // Also remove Supabase realtime channels (not just Dart streams)
    try {
      await _repo.removeAllChannels();
      AppLogger.d('chat_removed_all_supabase_channels', tag: 'ChatVM');
    } on Exception catch (e) {
      AppLogger.w('chat_remove_channels_warning: $e', tag: 'ChatVM');
    }

    // Clear all cached data
    conversations.clear();
    currentMessages.clear();
    _lastMessages = [];
    _offerStatusCache.clear();
    activeConversation = null;
    _otherUserTyping = false;
    _presenceUpdatedAt = null;

    // Reset loading states
    isLoadingConversations = false;
    isLoadingMessages = false;
    isSending = false;
    isCreatingConversation = false;
    conversationCreationError = null;

    AppLogger.i('chat_teardown_complete', tag: 'ChatVM');
    _notify();
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
    } on Exception catch (e) {
      final op = [if (delivered) 'delivered', if (seen) 'seen'].join('+');
      AppLogger.e(
        'Error marking receipts conversation_id=${activeConversation!.id} operation=$op',
        tag: 'ChatVM',
        error: e,
      );
    }
  }

  /// Optimistically marks a conversation as read in the local list.
  ///
  /// Called after returning from a chat screen so the unread badge clears
  /// instantly without waiting for a full `fetchConversations()` round-trip.
  /// Sets `lastMessageSeenAt` to `DateTime.now()` on the matching
  /// conversation. No backend call — `markSeen()` already handled that.
  void markConversationReadLocally(String conversationId) {
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx < 0) return;
    final c = conversations[idx];
    // Only update if currently "unread" (seenAt is null and sender is other)
    if (c.lastMessageSeenAt != null) return;
    conversations[idx] = c.copyWith(lastMessageSeenAt: DateTime.now());
    AppLogger.d(
      '[ChatVM] Optimistic local mark-read: $conversationId',
      tag: 'ChatVM',
    );
    _notify();
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
    } on Exception catch (e) {
      AppLogger.e('Error fetching conversations: $e');
    } finally {
      isLoadingConversations = false;
      _notify();
    }
  }

  void subscribeToUserConversations() {
    final user = _repo.currentUser;
    if (user == null) {
      AppLogger.d('[REALTIME] subscribeToUserConversations: no user, skip');
      return;
    }
    unawaited(_inboxMsgSub?.cancel());
    AppLogger.d(
      '[REALTIME] subscribeToUserConversations: starting inbox messages stream',
    );
    _inboxMsgSub = _repo
        .subscribeToInboxMessages(user.id)
        .listen(
          (messages) {
            if (!_mounted) return;
            if (messages.isEmpty) return;
            try {
              _mergeInboxMessages(messages);
              conversations.sort((a, b) {
                final aTime = a.lastMessageTime ?? a.createdAt;
                final bTime = b.lastMessageTime ?? b.createdAt;
                return bTime.compareTo(aTime);
              });
              AppLogger.d(
                '[REALTIME] Inbox merged: ${conversations.length} conversations',
              );
              _notify();
            } on Exception catch (e) {
              AppLogger.e('Error merging inbox messages', error: e);
            }
          },
          onError: (Object error) {
            AppLogger.e(
              'Realtime inbox messages subscription error',
              error: error,
            );
          },
        );
  }

  /// Merges incoming messages into conversation list (new Conversation instances; no mutation).
  void _mergeInboxMessages(List<Message> messages) {
    for (final message in messages) {
      final idx = conversations.indexWhere(
        (c) => c.id == message.conversationId,
      );
      if (idx >= 0) {
        final c = conversations[idx];
        conversations[idx] = c.copyWith(
          lastMessage: message.content,
          lastMessageTime: message.createdAt,
          lastMessageSenderId: message.senderId,
        );
      } else {
        if (_fetchingConversationIds.contains(message.conversationId)) continue;
        _fetchingConversationIds.add(message.conversationId);
        unawaited(
          _repo
              .getConversationById(message.conversationId)
              .then((convo) {
                if (!_mounted) return;
                _fetchingConversationIds.remove(message.conversationId);
                final merged = convo.copyWith(
                  lastMessage: message.content,
                  lastMessageTime: message.createdAt,
                  lastMessageSenderId: message.senderId,
                );
                if (!conversations.any((c) => c.id == merged.id)) {
                  conversations
                    ..add(merged)
                    ..sort((a, b) {
                      final aTime = a.lastMessageTime ?? a.createdAt;
                      final bTime = b.lastMessageTime ?? b.createdAt;
                      return bTime.compareTo(aTime);
                    });
                  AppLogger.d(
                    '[REALTIME] New conversation added from inbox message: ${merged.id}',
                  );
                  _notify();
                }
              })
              .onError<Exception>((e, st) {
                _fetchingConversationIds.remove(message.conversationId);
                AppLogger.w(
                  'getConversationById failed for ${message.conversationId}',
                  error: e,
                );
              }),
        );
      }
    }
  }

  void unsubscribeFromUserConversations() {
    unawaited(_inboxMsgSub?.cancel());
    _inboxMsgSub = null;
    AppLogger.d(
      '[REALTIME] unsubscribeFromUserConversations: inbox stream cancelled',
    );
  }

  // Utility to start or fetch a conversation with loading state and error handling
  Future<Conversation?> createOrGetConversation({
    String? taskId,
    required String user1Id,
    required String user2Id,
  }) async {
    // Prevent double-tap: if already creating, return null
    if (isCreatingConversation) {
      AppLogger.d(
        'createOrGetConversation: already in progress, ignoring double-tap',
      );
      return null;
    }

    isCreatingConversation = true;
    conversationCreationError = null;
    _notify();

    try {
      final conversation = await _repo.createOrGetConversation(
        taskId: taskId,
        user1Id: user1Id,
        user2Id: user2Id,
      );
      AppLogger.i('✅ Conversation created/fetched: ${conversation.id}');
      return conversation;
    } on Exception catch (e) {
      final errorMessage = _mapConversationError(e);
      conversationCreationError = errorMessage;
      AppLogger.e('❌ Error creating conversation: $errorMessage');
      _notify();
      rethrow;
    } finally {
      isCreatingConversation = false;
      _notify();
    }
  }

  /// Clear conversation creation error (call when user dismisses error UI)
  void clearConversationError() {
    conversationCreationError = null;
    _notify();
  }

  /// Map technical errors to user-friendly messages for conversation creation
  String _mapConversationError(dynamic error) {
    final message = error.toString().toLowerCase();

    if (message.contains('freelancers cannot start')) {
      return 'Only clients can start conversations with freelancers.';
    }
    if (message.contains('favorites list')) {
      return 'Add this freelancer to your favorites first to start a conversation.';
    }
    if (message.contains('rate limit exceeded')) {
      return "You've reached the conversation limit. Try again in an hour.";
    }
    if (message.contains('target user not found')) {
      return 'User not found. They may have deleted their account.';
    }
    if (message.contains('cannot create conversation with yourself')) {
      return "You can't start a conversation with yourself.";
    }
    if (message.contains('timeout') || message.contains('timed out')) {
      return 'Connection timeout. Check your internet and try again.';
    }
    if (message.contains('unauthenticated') || message.contains('session')) {
      return 'Session expired. Please log in again.';
    }

    return 'Failed to start conversation. Please try again.';
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
      final conversation = await createOrGetConversation(
        taskId: task.id,
        user1Id: task.userId,
        user2Id: freelancerId,
      );
      if (conversation == null) {
        throw Exception('Could not create conversation. Please try again.');
      }
      return conversation;
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
      _lastMessages = List.from(msgs);
      currentMessages
        ..clear()
        ..addAll(msgs);
      final idx = conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) activeConversation = conversations[idx];
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
        _offerStatusCache[offerId] = 'accepted_unpaid';
        _notify();
        // Do not send 'offer_accepted' message for direct offers: conversation may be
        // task-linked and backend can treat that message as task acceptance. Acceptance
        // is recorded in work_log; payment happens from dashboard.
      } on Exception catch (e) {
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
      } on Exception catch (e) {
        AppLogger.e('Error rejecting offer', error: e);
        rethrow;
      }
    }
    await sendMessage(
      'Offer Rejected',
      messageType: 'offer_rejected',
      payload: {
        'original_offer_id': offerMsg.id,
        'offer_id': ?offerId,
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
    _offerStatusCache[offerId] = 'delivered_held';
    _notify();
  }

  /// Client completes (approve & release payment) for a delivered direct offer.
  Future<void> completeOffer(String offerId) async {
    await _directOffersService.completeOffer(offerId);
    _offerStatusCache[offerId] = 'completed_released';
    _notify();
  }

  /// Refreshes offer statuses from DB for all offer messages in currentMessages.
  /// Called when messages are received so chat reflects payment/delivery done from dashboard.
  Future<void> refreshOfferStatusesForCurrentMessages() async {
    final offerIds = <String>{};
    for (final msg in currentMessages) {
      if (msg.messageType == MessageType.offer) {
        final id = msg.payload['offer_id'] as String?;
        if (id != null && id.isNotEmpty) offerIds.add(id);
      }
    }
    if (offerIds.isEmpty) return;
    try {
      final offers = await _directOffersService.getOffersByIds(
        offerIds.toList(),
      );
      for (final entry in offers.entries) {
        final offer = entry.value;
        final key = '${offer.status}_${offer.paymentStatus}';
        _offerStatusCache[entry.key] = key;
      }
      _notify();
    } on Exception catch (e) {
      AppLogger.w('Failed to refresh offer statuses: $e', tag: 'ChatVM');
    }
  }

  Future<void> subscribeToActiveConversation() async {
    if (activeConversation == null) return;
    unawaited(_msgSub?.cancel());
    unawaited(_presenceSub?.cancel());
    _offerRefreshDebounce?.cancel();
    _offerRefreshDebounce = null;
    final cid = activeConversation!.id;
    // Defensive: ensure merge state is for this conversation only (e.g. if entry point did not call fetchMessages first).
    if (_lastMessages.isNotEmpty) {
      final lastCid = _lastMessages.first.conversationId;
      if (lastCid != cid) _lastMessages = [];
    }
    _presenceReceiptsEnabled = await _repo.isPresenceReceiptsEnabled();

    _msgSub = _repo
        .subscribeToMessages(cid)
        .listen(
          (messages) async {
            if (activeConversation == null) return;
            final newRows = messages.map((m) => m.toJson()).toList();
            final merged = ChatRealtimeMerger.merge(
              _lastMessages,
              newRows,
              Message.fromJson,
            );
            final uid = currentUserId;
            final hasNewFromOther =
                uid != null &&
                merged.any(
                  (m) =>
                      m.receiverId == uid &&
                      !_lastMessages.any((l) => l.id == m.id),
                );
            _lastMessages = merged;
            currentMessages
              ..clear()
              ..addAll(merged);
            if ((_presenceReceiptsEnabled ?? false) && hasNewFromOther) {
              unawaited(markReceiptsForActive());
            }
            _offerRefreshDebounce?.cancel();
            _offerRefreshDebounce = Timer(
              const Duration(milliseconds: 500),
              () {
                if (_mounted && activeConversation != null) {
                  unawaited(refreshOfferStatusesForCurrentMessages());
                }
              },
            );
            AppLogger.d(
              '[CHAT] messages merged count=${merged.length}',
              tag: 'ChatVM',
            );
            _notify();
          },
          onError: (Object error) {
            AppLogger.e(
              '[CHAT] stream_error messages subscription',
              tag: 'ChatVM',
              error: error,
            );
            currentMessages
              ..clear()
              ..addAll(_lastMessages);
            _notify();
          },
        );

    if (_presenceReceiptsEnabled ?? false) {
      unawaited(markReceiptsForActive());
      final otherId = activeConversation!.user1Id == currentUserId
          ? activeConversation!.user2Id
          : activeConversation!.user1Id;
      _presenceSub = _repo
          .subscribeToPresence(cid)
          .listen(
            (rows) {
              if (activeConversation == null || !_mounted) return;
              final list = rows.where((r) => r['user_id'] == otherId).toList();
              final otherRow = list.isNotEmpty ? list.first : null;
              if (otherRow != null) {
                _otherUserTyping = otherRow['is_typing'] as bool? ?? false;
                final u = otherRow['updated_at'] as String?;
                _presenceUpdatedAt = u != null ? DateTime.tryParse(u) : null;
                AppLogger.d(
                  '[CHAT] presence_updated otherTyping=$_otherUserTyping',
                  tag: 'ChatVM',
                );
              } else {
                _otherUserTyping = false;
                _presenceUpdatedAt = null;
              }
              final idx = conversations.indexWhere(
                (c) => c.id == activeConversation!.id,
              );
              if (idx >= 0) {
                conversations[idx] = conversations[idx].copyWith(
                  otherUserTyping: _otherUserTyping,
                  presenceUpdatedAt: _presenceUpdatedAt,
                );
              }
              _notify();
            },
            onError: (Object e) {
              AppLogger.e(
                '[CHAT] presence stream error',
                tag: 'ChatVM',
                error: e,
              );
            },
          );
    }
  }

  void unsubscribeFromConversation() {
    _offerRefreshDebounce?.cancel();
    _offerRefreshDebounce = null;
    unawaited(_msgSub?.cancel());
    _msgSub = null;
    unawaited(_presenceSub?.cancel());
    _presenceSub = null;
  }

  /// Whether presence and receipt UI is enabled (from feature flag).
  bool get isPresenceReceiptsEnabled => _presenceReceiptsEnabled ?? false;

  /// Whether the other participant is typing (false if presence older than 15s).
  bool get otherUserTyping {
    if (!_otherUserTyping) return false;
    if (_presenceUpdatedAt == null) return false;
    if (DateTime.now().difference(_presenceUpdatedAt!).inSeconds > 15) {
      return false;
    }
    return true;
  }

  /// Resolves a private chat attachment path into a short-lived signed URL.
  ///
  /// Widgets receive this resolver so Storage access stays in the ViewModel and
  /// service layer rather than being created directly from the view tree.
  Future<String> resolveAttachmentSignedUrl(String storagePath) {
    return _attachmentUploader.createSignedUrl(
      storagePath,
    );
  }

  /// Call when user starts or stops typing. Throttled in service; no-op if feature flag off.
  Future<void> setTyping({required bool isTyping}) async {
    if (_presenceReceiptsEnabled != true || activeConversation == null) return;
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await _repo.upsertPresence(
        activeConversation!.id,
        uid,
        isTyping: isTyping,
      );
    } on Exception catch (e) {
      AppLogger.w('[CHAT] setTyping failed: $e', tag: 'ChatVM');
    }
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
