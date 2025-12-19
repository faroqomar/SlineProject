import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';

/// Why this service exists: encapsulates Supabase queries/streams so UI/controllers remain clean
/// and to centralize schema changes (attachments, receipts, typing) in one place.
class MessageService {
  /// Encapsulated Supabase client; allows injection for testing.
  final SupabaseClient _client;
  final NotificationService _notificationService = NotificationService();

  MessageService([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  /// Create or get conversation (order-insensitive pair). taskId can be null.
  Future<Conversation> createOrGetConversation({
    String? taskId,
    required String user1Id,
    required String user2Id,
  }) async {
    // If this is a task-linked conversation, delegate to the RPC which
    // (a) blocks task owner from starting a convo with themselves,
    // (b) returns existing convo if already present, otherwise creates one,
    // (c) normalizes participant order (user1_id/user2_id) on the server.
    if (taskId != null) {
      try {
        final response = await _client
            .rpc('start_task_conversation_v1', params: {'p_task_id': taskId})
            .select()
            .single();
        AppLogger.i('🧭 RPC start_task_conversation_v1 returned conversation');
        return Conversation.fromJson(
          Map<String, dynamic>.from(response as Map),
        );
      } catch (e) {
        AppLogger.e('❌ RPC start_task_conversation failed: $e');
        rethrow;
      }
    }

    // ----- Plain DM (no task_id) path: keep existing behavior -----
    final base = _client.from('conversations').select();

    // Filter by pair regardless of order
    final pairFilter =
        "and(user1_id.eq.$user1Id,user2_id.eq.$user2Id),and(user1_id.eq.$user2Id,user2_id.eq.$user1Id)";

    // Only look for DMs (task_id IS NULL)
    final query = base.is_('task_id', null).or(pairFilter).limit(1);

    final existing = await query;

    AppLogger.d(
      '🔎 Existing DM conversations found: ${existing is List ? existing.length : 'n/a'}',
    );
    if (existing is List && existing.isNotEmpty) {
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
        .single();

    try {
      final id = (response as Map)['id'];
      AppLogger.i('🆕 Created DM conversation: $id');
    } catch (_) {}

    return Conversation.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Delete (archive) conversation for a user.
  /// It will reappear if a new message is received (checked via timestamp).
  Future<void> deleteConversation(String conversationId, String userId) async {
    // First, find out if user is user1 or user2
    final convo = await _client
        .from('conversations')
        .select('user1_id, user2_id')
        .eq('id', conversationId)
        .single();

    final user1 = convo['user1_id'];
    final user2 = convo['user2_id'];

    if (userId == user1) {
      await _client
          .from('conversations')
          .update({
            'deleted_at_user1': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', conversationId);
    } else if (userId == user2) {
      await _client
          .from('conversations')
          .update({
            'deleted_at_user2': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', conversationId);
    } else {
      throw Exception('User is not a participant in this conversation');
    }
  }

  /// Get conversations for user, filtering out deleted ones unless new messages arrived.
  Future<List<Conversation>> getUserConversations(String userId) async {
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
            tasks(title),
            user1:profiles!conversations_user1_id_fkey(full_name, avatar_url),
            user2:profiles!conversations_user2_id_fkey(full_name, avatar_url),
            last_message:messages!conversation_id(content, created_at, seen_at, sender_id)
          ''')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('created_at', foreignTable: 'messages', ascending: false)
          .limit(1, foreignTable: 'messages')
          .order('created_at', ascending: false);

      if (response is List) {
        AppLogger.d('📦 Conversations response count: ${response.length}');
        final List<Conversation> validConversations = [];

        for (final raw in response) {
          final json = Map<String, dynamic>.from(raw as Map);

          // Check deletion status
          final isUser1 = json['user1_id'] == userId;
          final deletedAtStr = isUser1
              ? json['deleted_at_user1']
              : json['deleted_at_user2'];

          if (deletedAtStr != null) {
            final deletedAt = DateTime.parse(deletedAtStr);
            final lastMsg = json['last_message'];
            // If no messages, or last message was before deletion, skip it
            if (lastMsg == null || (lastMsg is List && lastMsg.isEmpty)) {
              continue;
            }
            final msgData = lastMsg is List ? lastMsg.first : lastMsg;
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
      } else {
        AppLogger.w('⚠️ Unexpected response type: $response');
        return [];
      }
    } catch (e) {
      AppLogger.e('❌ Error fetching conversations: $e');
      return [];
    }
  }

  /// Get messages (now returns attachment fields too)
  Future<List<Message>> getMessages(String conversationId) async {
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

    final msg = Message.fromJson(Map<String, dynamic>.from(response as Map));

    // Create notification for receiver
    String notifTitle = 'New Message';
    String notifBody = content;
    NotificationType notifType = NotificationType.message;

    if (messageType == 'offer') {
      notifTitle = 'New Offer Received';
      notifBody = 'You received an offer of ${payload?['price'] ?? '?'}';
      notifType = NotificationType.offer;
    } else if (messageType == 'offer_accepted') {
      notifTitle = 'Offer Accepted';
      notifBody = 'Your offer has been accepted!';
      notifType = NotificationType.offer;
    } else if (messageType == 'offer_rejected') {
      notifTitle = 'Offer Rejected';
      notifBody = 'Your offer has been rejected.';
      notifType = NotificationType.offer;
    }

    // Fire and forget notification creation (don't await to block UI)
    _notificationService.createNotification(
      userId: receiverId,
      title: notifTitle,
      message: notifBody,
      type: notifType,
      relatedEntityId: conversationId,
      relatedEntityType: 'conversation',
    );

    return msg;
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

  /// Realtime for a conversation
  Stream<Message?> subscribeToMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) {
          if (rows.isEmpty) return null;
          try {
            final last = Map<String, dynamic>.from(rows.last as Map);
            return Message.fromJson(last);
          } catch (e) {
            AppLogger.e('Error parsing realtime message: $e');
            return null;
          }
        });
  }

  /// Realtime for conversations (as-is)
  Stream<List<Map<String, dynamic>>> subscribeToConversations(String userId) {
    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .asyncMap((rows) async {
          if (rows.isEmpty) return <Map<String, dynamic>>[];
          // We need to re-fetch with relationships to get full details
          // And ideally apply deletion logic (though realtime often used for just updates,
          // a full refresh via fetchConversations is often triggered on open).
          // For now, we return raw stream, but ViewModel should probably re-fetch to respect deletion status.
          // Or we implement the fetch logic here.

          final convoIds = rows.map((row) => (row as Map)['id']).toList();
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
                tasks(title),
                user1:profiles!conversations_user1_id_fkey(full_name, avatar_url),
                user2:profiles!conversations_user2_id_fkey(full_name, avatar_url),
                last_message:messages!conversation_id(content, created_at)
              ''')
              .in_('id', convoIds)
              .order('created_at', foreignTable: 'messages', ascending: false)
              .limit(1, foreignTable: 'messages')
              .order('created_at', ascending: false);

          return (response as List)
              .map((raw) => Map<String, dynamic>.from(raw as Map))
              .where((json) {
                // Apply deletion filter
                final isUser1 = json['user1_id'] == userId;
                final deletedAtStr = isUser1
                    ? json['deleted_at_user1']
                    : json['deleted_at_user2'];
                if (deletedAtStr != null) {
                  final deletedAt = DateTime.parse(deletedAtStr);
                  final lastMsg = json['last_message'];
                  if (lastMsg == null || (lastMsg is List && lastMsg.isEmpty)) {
                    return false;
                  }
                  final msgData = lastMsg is List ? lastMsg.first : lastMsg;
                  final msgTime = DateTime.parse(msgData['created_at']);
                  return msgTime.isAfter(deletedAt);
                }
                return true;
              })
              .toList()
            ..sort((a, b) {
              // Parse timestamps for sorting
              DateTime getTime(Map<String, dynamic> json) {
                final lastMsg = json['last_message'];
                if (lastMsg != null && lastMsg is List && lastMsg.isNotEmpty) {
                  return DateTime.parse(lastMsg.first['created_at']);
                } else if (lastMsg != null && lastMsg is Map) {
                  // handle single object if changed
                  return DateTime.parse(lastMsg['created_at']);
                }
                return DateTime.parse(json['created_at']);
              }

              final aTime = getTime(a);
              final bTime = getTime(b);
              return bTime.compareTo(aTime);
            });
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
