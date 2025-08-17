import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Why this service exists: encapsulates Supabase queries/streams so UI/controllers remain clean
/// and to centralize schema changes (attachments, receipts, typing) in one place.
class MessageService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Create or get conversation (order-insensitive pair)
  Future<Conversation> createOrGetConversation({
    required String taskId,
    required String user1Id,
    required String user2Id,
  }) async {
    final existing = await _client
        .from('conversations')
        .select()
        .eq('task_id', taskId)
        .or('and(user1_id.eq.$user1Id,user2_id.eq.$user2Id),and(user1_id.eq.$user2Id,user2_id.eq.$user1Id)')
        .limit(1);

    AppLogger.d('🔎 Existing conversations found: ${existing.length}');
    if (existing is List && existing.isNotEmpty) {
      AppLogger.i('📌 Using existing conversation: ${existing.first['id']}');
      return Conversation.fromJson(Map<String, dynamic>.from(existing.first as Map));
    }

    final response = await _client
        .from('conversations')
        .insert({
          'task_id': taskId,
          'user1_id': user1Id,
          'user2_id': user2Id,
        })
        .select()
        .single();

    try {
      final id = (response as Map)['id'];
      AppLogger.i('🆕 Created conversation: $id');
    } catch (_) {}

    return Conversation.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Get conversations for user (kept as-is)
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
            tasks(title),
            user1:profiles!conversations_user1_id_fkey(full_name, avatar_url),
            user2:profiles!conversations_user2_id_fkey(full_name, avatar_url),
            last_message:messages!conversation_id(content, created_at)
          ''')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('created_at', foreignTable: 'messages', ascending: false)
          .limit(1, foreignTable: 'messages')
          .order('created_at', ascending: false);

      if (response is List) {
        AppLogger.d('📦 Conversations response count: ${response.length}');
        return response.map((raw) {
          final json = Map<String, dynamic>.from(raw as Map);
          final isUser1 = json['user1_id'] == userId;
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
        .select('id, conversation_id, sender_id, receiver_id, content, created_at, attachment_url, attachment_type, attachment_name, attachment_size, delivered_at, seen_at')
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
  }) async {
    final insertMap = <String, dynamic>{
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
    };
    if (attachmentUrl != null) insertMap['attachment_url'] = attachmentUrl;
    if (attachmentType != null) insertMap['attachment_type'] = attachmentType;
    if (attachmentName != null) insertMap['attachment_name'] = attachmentName;
    if (attachmentSize != null) insertMap['attachment_size'] = attachmentSize;

    final response = await _client
        .from('messages')
        .insert(insertMap)
        .select('id, conversation_id, sender_id, receiver_id, content, created_at, attachment_url, attachment_type, attachment_name, attachment_size, delivered_at, seen_at')
        .single();

    return Message.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Mark all messages in a conversation as delivered for the current receiver.
  /// Why: switch UI status from single tick (sent) to double-grey (delivered).
  Future<void> markDelivered(String conversationId) async {
    await _client.rpc('mark_conversation_delivered', params: {
      'p_conversation_id': conversationId,
    });
    AppLogger.d('[RECEIPTS] delivered marked for convo=$conversationId');
  }

  /// Mark all messages in a conversation as seen for the current receiver.
  /// Why: switch UI status from double-grey to double-blue (read).
  Future<void> markSeen(String conversationId) async {
    await _client.rpc('mark_conversation_seen', params: {
      'p_conversation_id': conversationId,
    });
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
          final convoIds = rows.map((row) => (row as Map)['id']).toList();
          final response = await _client
              .from('conversations')
              .select('''
                id,
                task_id,
                user1_id,
                user2_id,
                created_at,
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
              .toList();
        });
  }
}