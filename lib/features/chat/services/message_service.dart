import 'dart:async';

import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Why this service exists: encapsulates Supabase queries/streams so UI/controllers remain clean
/// and to centralize schema changes (attachments, receipts, typing) in one place.
class MessageService {
  /// Encapsulated Supabase client; allows injection for testing.
  final SupabaseClient _client;

  MessageService([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  /// Feature flag cache to avoid repeated lookups
  bool? _featureFlagCache;
  DateTime? _featureFlagCacheTime;
  static const _featureFlagCacheDuration = Duration(minutes: 1);

  /// Check if atomic RPC for direct conversations is enabled via feature flag.
  /// Caches result for 1 minute to reduce database queries.
  Future<bool> _isDirectConversationRpcEnabled() async {
    // Return cached value if still valid
    if (_featureFlagCache != null && _featureFlagCacheTime != null) {
      if (DateTime.now().difference(_featureFlagCacheTime!) <
          _featureFlagCacheDuration) {
        return _featureFlagCache!;
      }
    }

    try {
      final response = await _client
          .from('app_config')
          .select('value')
          .eq('key', 'enable_direct_conversation_rpc')
          .maybeSingle();

      // Default to false if flag not found
      final enabled = response?['value'] == 'true';

      // Update cache
      _featureFlagCache = enabled;
      _featureFlagCacheTime = DateTime.now();

      AppLogger.d('Feature flag enable_direct_conversation_rpc = $enabled');
      return enabled;
    } on Exception catch (e) {
      AppLogger.w('Failed to check feature flag, defaulting to false: $e');
      return false;
    }
  }

  /// Feature flag: presence and receipt ticks (typing indicator, delivered/read).
  bool? _presenceReceiptsFlagCache;
  DateTime? _presenceReceiptsFlagTime;

  /// Check if presence and receipt UI is enabled. Caches 1 minute.
  Future<bool> isPresenceReceiptsEnabled() async {
    if (_presenceReceiptsFlagCache != null &&
        _presenceReceiptsFlagTime != null &&
        DateTime.now().difference(_presenceReceiptsFlagTime!) <
            _featureFlagCacheDuration) {
      return _presenceReceiptsFlagCache!;
    }
    try {
      final response = await _client
          .from('app_config')
          .select('value')
          .eq('key', 'chat_presence_receipts_enabled')
          .maybeSingle();
      final enabled = response?['value'] == 'true';
      _presenceReceiptsFlagCache = enabled;
      _presenceReceiptsFlagTime = DateTime.now();
      AppLogger.d(
        '[CHAT] feature flag chat_presence_receipts_enabled = $enabled',
        tag: 'Chat',
      );
      return enabled;
    } on Exception catch (e) {
      AppLogger.w(
        '[CHAT] Failed to check chat_presence_receipts_enabled, default false: $e',
        tag: 'Chat',
      );
      return false;
    }
  }

  /// Throttle: min 5s between presence upserts per conversation.
  final Map<String, DateTime> _lastPresenceUpsertByConvo = {};

  /// Upsert typing presence. Throttled to at most once per 5s per conversation.
  Future<void> upsertPresence(
    String conversationId,
    String userId,
    bool isTyping,
  ) async {
    final now = DateTime.now().toUtc();
    final last = _lastPresenceUpsertByConvo[conversationId];
    if (last != null && now.difference(last).inSeconds < 5) {
      AppLogger.d(
        '[CHAT] presence upsert throttled conversationId=$conversationId',
        tag: 'Chat',
      );
      return;
    }
    try {
      await _client.from('conversation_presence').upsert({
        'conversation_id': conversationId,
        'user_id': userId,
        'is_typing': isTyping,
        'updated_at': now.toIso8601String(),
      }, onConflict: 'conversation_id,user_id');
      _lastPresenceUpsertByConvo[conversationId] = now;
      AppLogger.d(
        '[CHAT] presence_upsert conversationId=$conversationId isTyping=$isTyping',
        tag: 'Chat',
      );
    } on Exception catch (e, st) {
      AppLogger.e(
        '[CHAT] presence upsert failed',
        tag: 'Chat',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Stream presence for a conversation (for typing indicator). Emits list of rows.
  Stream<List<Map<String, dynamic>>> subscribeToPresence(
    String conversationId,
  ) {
    AppLogger.d(
      '[CHAT] presence subscription start conversationId=$conversationId',
      tag: 'Chat',
    );
    return _client
        .from('conversation_presence')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('conversation_id', conversationId)
        .handleError((e, st) {
          AppLogger.e(
            '[CHAT] presence stream error',
            tag: 'Chat',
            error: e,
            stackTrace: st,
          );
        })
        .map(
          (rows) =>
              rows.map((r) => Map<String, dynamic>.from(r as Map)).toList(),
        );
  }

  /// Create or get conversation (order-insensitive pair). taskId can be null.
  Future<Conversation> createOrGetConversation({
    String? taskId,
    required String user1Id,
    required String user2Id,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? const Duration(seconds: 10);

    // If this is a task-linked conversation, delegate to the RPC which
    // (a) blocks task owner from starting a convo with themselves,
    // (b) returns existing convo if already present, otherwise creates one,
    // (c) normalizes participant order (user1_id/user2_id) on the server.
    if (taskId != null) {
      AppLogger.d('Chat: using task-linked path (taskId provided)');
      try {
        final response = await _client
            .rpc('start_task_conversation_v1', params: {'p_task_id': taskId})
            .select(
              '*, tasks(title, task_type), user1:profiles!conversations_user1_id_fkey(full_name, avatar_url), user2:profiles!conversations_user2_id_fkey(full_name, avatar_url)',
            )
            .single()
            .timeout(effectiveTimeout);
        AppLogger.i('🧭 RPC start_task_conversation_v1 returned conversation');
        return Conversation.fromJson(
          Map<String, dynamic>.from(response as Map),
        );
      } on TimeoutException catch (e) {
        AppLogger.e('❌ RPC start_task_conversation timed out: $e');
        throw TimeoutException(
          'Connection timeout. Please check your internet and try again.',
        );
      } on Exception catch (e) {
        AppLogger.e('❌ RPC start_task_conversation failed: $e');
        rethrow;
      }
    }

    // ----- Plain DM (no task_id) path: used for booking work or direct DMs -----
    AppLogger.d('Chat: using DM path (no taskId)');

    // Check if atomic RPC is enabled via feature flag
    final useRpc = await _isDirectConversationRpcEnabled();

    if (useRpc) {
      // Use new atomic RPC path (Chat Creation Matrix)
      AppLogger.d('Chat: using atomic RPC path (feature flag enabled)');
      return _createDirectConversationViaRpc(
        targetId: user2Id,
        timeout: effectiveTimeout,
      );
    } else {
      // Use legacy direct INSERT path
      AppLogger.d(
        'Chat: using legacy direct INSERT path (feature flag disabled)',
      );
      return _createDirectConversationViaInsert(
        user1Id: user1Id,
        user2Id: user2Id,
        timeout: effectiveTimeout,
      );
    }
  }

  /// Create direct conversation using the new atomic RPC.
  /// This is the preferred path when feature flag is enabled.
  Future<Conversation> _createDirectConversationViaRpc({
    required String targetId,
    required Duration timeout,
  }) async {
    try {
      final response = await _client
          .rpc(
            'start_direct_conversation_v1',
            params: {'p_target_id': targetId},
          )
          .select('''
            *,
            user1:profiles!conversations_user1_id_fkey(full_name, avatar_url),
            user2:profiles!conversations_user2_id_fkey(full_name, avatar_url)
          ''')
          .single()
          .timeout(timeout);

      AppLogger.i('🆕 RPC start_direct_conversation_v1 succeeded');
      return Conversation.fromJson(Map<String, dynamic>.from(response as Map));
    } on TimeoutException catch (e) {
      AppLogger.e('❌ RPC start_direct_conversation_v1 timed out: $e');
      throw TimeoutException(
        'Connection timeout. Please check your internet and try again.',
      );
    } on PostgrestException catch (e) {
      AppLogger.e('❌ RPC start_direct_conversation_v1 failed: ${e.message}');
      // Let the error propagate for ErrorMapper to handle
      rethrow;
    } on Exception catch (e) {
      AppLogger.e('❌ RPC start_direct_conversation_v1 failed: $e');
      rethrow;
    }
  }

  /// Create direct conversation using direct INSERT (legacy path).
  /// Used when feature flag is disabled for backward compatibility.
  Future<Conversation> _createDirectConversationViaInsert({
    required String user1Id,
    required String user2Id,
    required Duration timeout,
  }) async {
    final base = _client.from('conversations').select();

    // Filter by pair regardless of order
    final pairFilter =
        'and(user1_id.eq.$user1Id,user2_id.eq.$user2Id),and(user1_id.eq.$user2Id,user2_id.eq.$user1Id)';

    // Only look for DMs (task_id IS NULL)
    final query = base.isFilter('task_id', null).or(pairFilter).limit(1);

    final existing = await query.timeout(timeout);

    AppLogger.d('🔎 Existing DM conversations found: ${existing.length}');
    if (existing.isNotEmpty) {
      AppLogger.i('📌 Using existing DM conversation: ${existing.first['id']}');
      return Conversation.fromJson(
        Map<String, dynamic>.from(existing.first as Map),
      );
    }

    // Create new DM conversation; initiator is user1Id (caller)
    final insertMap = <String, dynamic>{
      'user1_id': user1Id,
      'user2_id': user2Id,
      'initiated_by': user1Id,
    };

    final response = await _client
        .from('conversations')
        .insert(insertMap)
        .select()
        .single()
        .timeout(timeout);

    try {
      final id = (response as Map)['id'];
      AppLogger.i('🆕 Created DM conversation: $id');
    } on Exception catch (_) {}

    return Conversation.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Archive conversation for the current user (server time). Uses archive_conversation_v1 RPC.
  Future<void> deleteConversation(String conversationId, String userId) async {
    AppLogger.i('[ARCHIVE] start conversationId=$conversationId');
    try {
      await _client.rpc(
        'archive_conversation_v1',
        params: {'p_conversation_id': conversationId},
      );
      AppLogger.i('[ARCHIVE] success conversationId=$conversationId');
    } on Exception catch (e) {
      AppLogger.e('[ARCHIVE] failed conversationId=$conversationId', error: e);
      rethrow;
    }
  }

  /// Fetch a single conversation by ID (used for Deep Linking).
  Future<Conversation> getConversationById(String conversationId) async {
    final response = await _client
        .from('conversations')
        .select('''
          *,
          tasks(title, task_type),
          user1:profiles!conversations_user1_id_fkey(full_name, avatar_url),
          user2:profiles!conversations_user2_id_fkey(full_name, avatar_url)
        ''')
        .eq('id', conversationId)
        .single();

    final json = Map<String, dynamic>.from(response as Map);
    final currentUserId = _client.auth.currentUser?.id;

    if (currentUserId != null) {
      final isUser1 = json['user1_id'] == currentUserId;
      final otherUser = isUser1 ? json['user2'] : json['user1'];
      json['other_user_name'] = otherUser?['full_name'];
      json['other_user_avatar'] = otherUser?['avatar_url'];
    }

    return Conversation.fromJson(json);
  }

  /// Get conversations for user, filtering out deleted ones unless new messages arrived.
  Future<List<Conversation>> getUserConversations(String userId) async {
    AppLogger.d('[CONVOS] fetch start');
    try {
      final response = await _client
          .from('conversations')
          .select('''
            id,
            task_id,
            user1_id,
            user2_id,
            created_at,
            deleted_at_user1,
            deleted_at_user2,
            tasks(title, task_type),
            user1:profiles!conversations_user1_id_fkey(full_name, avatar_url),
            user2:profiles!conversations_user2_id_fkey(full_name, avatar_url),
            last_message:messages!conversation_id(content, created_at, seen_at, sender_id)
          ''')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('created_at', referencedTable: 'messages', ascending: false)
          .limit(1, referencedTable: 'messages')
          .order('created_at', ascending: false);

      AppLogger.d('📦 Conversations response count: ${response.length}');
      final validConversations = <Conversation>[];

      for (final raw in response) {
        final json = Map<String, dynamic>.from(raw);

        // Check deletion status
        final isUser1 = json['user1_id'] == userId;
        final deletedAtStr = isUser1
            ? json['deleted_at_user1']
            : json['deleted_at_user2'];

        if (deletedAtStr != null) {
          final deletedAt = DateTime.parse(deletedAtStr);
          final lastMsg = json['last_message'];
          // If no messages, or last message was before deletion, skip it
          if (lastMsg == null || lastMsg is! List || lastMsg.isEmpty) {
            continue;
          }
          final msgData = Map<String, dynamic>.from(lastMsg.first as Map);
          final msgTime = DateTime.parse(msgData['created_at']);

          if (msgTime.isBefore(deletedAt)) {
            continue; // Still deleted
          }
        }

        final otherUser = isUser1 ? json['user2'] : json['user1'];
        validConversations.add(
          Conversation.fromJson({
            ...json,
            'task_title': json['tasks']?['title'] ?? 'Untitled Task',
            'task_type': json['tasks']?['task_type'],
            'user1_name': json['user1']?['full_name'] ?? 'User',
            'user2_name': json['user2']?['full_name'] ?? 'User',
            'other_user_name': otherUser?['full_name'],
            'other_user_avatar': otherUser?['avatar_url'],
          }),
        );
      }

      // Sort by last message time descending
      validConversations.sort((a, b) {
        final aTime = a.lastMessageTime ?? a.createdAt;
        final bTime = b.lastMessageTime ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      return validConversations;
    } on Exception catch (e) {
      AppLogger.e('❌ Error fetching conversations: $e');
      return [];
    }
  }

  /// Get messages (now returns attachment fields too)
  Future<List<Message>> getMessages(String conversationId) async {
    AppLogger.d('[MESSAGES] fetch start conversationId=$conversationId');
    final response = await _client
        .from('messages')
        .select(
          'id, conversation_id, sender_id, receiver_id, content, created_at, attachment_url, attachment_type, attachment_name, attachment_size, delivered_at, seen_at, message_type, payload',
        )
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((raw) => Message.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  /// Send text and/or attachment
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    String? attachmentUrl,
    String? attachmentType,
    String? attachmentName,
    int? attachmentSize,
    String? messageType, // e.g. 'text', 'offer', etc.
    Map<String, dynamic>? payload,
  }) async {
    try {
      AppLogger.d(
        'Sending message to conversation=$conversationId type=${messageType ?? 'text'}',
      );
      final insertMap = <String, dynamic>{
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'message_type': messageType ?? 'text',
        'payload': payload ?? {},
      };
      if (attachmentUrl != null) insertMap['attachment_url'] = attachmentUrl;
      if (attachmentType != null) insertMap['attachment_type'] = attachmentType;
      if (attachmentName != null) insertMap['attachment_name'] = attachmentName;
      if (attachmentSize != null) insertMap['attachment_size'] = attachmentSize;

      final response = await _client
          .from('messages')
          .insert(insertMap)
          .select(
            'id, conversation_id, sender_id, receiver_id, content, created_at, attachment_url, attachment_type, attachment_name, attachment_size, delivered_at, seen_at, message_type, payload',
          )
          .single();

      final message = Message.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
      AppLogger.i('Sent message=${message.id} conversation=$conversationId');
      return message;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to send message to conversation=$conversationId',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Mark all messages in a conversation as delivered for the current receiver.
  /// Why: switch UI status from single tick (sent) to double-grey (delivered).
  Future<void> markDelivered(String conversationId) async {
    await _client.rpc(
      'mark_conversation_delivered',
      params: {'p_conversation_id': conversationId},
    );
    AppLogger.d('[RECEIPTS] delivered marked for convo=$conversationId');
  }

  /// Mark all messages in a conversation as seen for the current receiver.
  /// Why: switch UI status from double-grey to double-blue (read).
  Future<void> markSeen(String conversationId) async {
    await _client.rpc(
      'mark_conversation_seen',
      params: {'p_conversation_id': conversationId},
    );
    AppLogger.d('[RECEIPTS] seen marked for convo=$conversationId');
  }

  /// Realtime for a conversation. Emits full list per snapshot (no collapse to rows.last).
  Stream<List<Message>> subscribeToMessages(String conversationId) {
    AppLogger.d(
      '[REALTIME] messages subscription start conversationId=$conversationId',
    );
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .handleError((e, st) {
          AppLogger.e(
            'Realtime messages stream error (payload/transform)',
            error: e,
            stackTrace: st,
          );
        })
        .map((rows) {
          if (rows.isEmpty) return <Message>[];
          try {
            final list =
                rows
                    .map(
                      (r) =>
                          Message.fromJson(Map<String, dynamic>.from(r as Map)),
                    )
                    .toList()
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            return list;
          } on Exception catch (e) {
            AppLogger.e('Realtime message parse error', error: e);
            return <Message>[];
          }
        });
  }

  /// Realtime for Inbox: messages where current user is receiver.
  /// Drives conversation list updates without subscribing to conversations table
  /// (conversations is not in supabase_realtime publication; no N+1).
  Stream<List<Message>> subscribeToInboxMessages(String userId) {
    AppLogger.d(
      '[REALTIME] inbox messages subscription start receiver_id=$userId',
    );
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .order('created_at', ascending: true)
        .handleError((e, st) {
          AppLogger.w(
            '[REALTIME] Inbox messages stream error (timeout/protocol/connection)',
            error: e,
          );
          AppLogger.d(
            '[REALTIME] Inbox stream error stackTrace',
            json: st?.toString(),
          );
        })
        .map((rows) {
          if (rows.isEmpty) return <Message>[];
          try {
            final list =
                rows
                    .map(
                      (r) =>
                          Message.fromJson(Map<String, dynamic>.from(r as Map)),
                    )
                    .toList()
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            AppLogger.d('[REALTIME] inbox messages event count=${list.length}');
            return list;
          } on Exception catch (e) {
            AppLogger.e('Realtime inbox message parse error', error: e);
            return <Message>[];
          }
        });
  }

  /// Starts (or fetches) a conversation initiated by the CLIENT.
  /// - If [taskId] is provided, the caller must be the task owner (enforced by RLS).
  /// - If [taskId] is null, the freelancer must be in client's favorites (enforced by RLS).
  /// Returns the conversation id.
  Future<String> startConversationByClient({
    String? taskId,
    required String clientId,
    required String freelancerId,
  }) async {
    final convo = await createOrGetConversation(
      taskId: taskId,
      user1Id: clientId,
      user2Id: freelancerId,
    );
    return convo.id;
  }
}
