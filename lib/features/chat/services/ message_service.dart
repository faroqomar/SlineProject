import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Service to handle messaging-related Supabase queries
class MessageService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Create or get an existing conversation between two users for a task
  Future<Conversation> createOrGetConversation({
    required String taskId,
    required String user1Id,
    required String user2Id,
  }) async {
    // Check if a conversation already exists
    final existing = await _client
        .from('conversations')
        .select()
        .eq('task_id', taskId)
        .or('user1_id.eq.$user1Id,user2_id.eq.$user2Id')
        .limit(1);

    // Debug: Checking existing conversations
    AppLogger.d('🔎 Existing conversations found: ${existing.length}');
    if (existing.isNotEmpty) {
      // Info: Using existing conversation
      AppLogger.i('📌 Using existing conversation: ${existing.first['id']}');
      return Conversation.fromJson(existing.first);
    }

    // Otherwise, create a new conversation
    final response = await _client.from('conversations').insert({
      'task_id': taskId,
      'user1_id': user1Id,
      'user2_id': user2Id,
    }).select().single();

    return Conversation.fromJson(response);
  }

  /// Get all conversations for a user with task title and participant names
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
            user1:profiles!conversations_user1_id_fkey(full_name),
            user2:profiles!conversations_user2_id_fkey(full_name),
            last_message:messages!conversation_id(content, created_at)
          ''')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('created_at', ascending: false);

      if (response is List) {
        // Debug: Conversations response received
        AppLogger.d('📦 Conversations response count: ${response.length}');
        return response.map((json) {
          return Conversation.fromJson({
            ...json,
            'task_title': json['tasks']?['title'] ?? 'Untitled Task',
            'user1_name': json['user1']?['full_name'] ?? 'User',
            'user2_name': json['user2']?['full_name'] ?? 'User',
          });
        }).toList();
      } else {
        // Warning: Unexpected response type
        AppLogger.w('⚠️ Unexpected response type: $response');
        return [];
      }
    } catch (e) {
      // Error: Failed to fetch conversations
      AppLogger.e('❌ Error fetching conversations: $e');
      return [];
    }
  }

  /// Get all messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => Message.fromJson(json))
        .toList();
  }

  /// Send a new message
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final response = await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
    }).select().single();

    return Message.fromJson(response);
  }

  /// Subscribe to realtime updates for a conversation
  Stream<Message?> subscribeToMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) {
          if (rows.isEmpty) return null;
          try {
            // Return the most recent message to trigger updates
            final messages = rows.map((row) => Message.fromJson(row)).toList();
            return messages.isNotEmpty ? messages.last : null;
          } catch (e) {
            AppLogger.e('Error parsing realtime message: $e');
            return null;
          }
        });
  }

  /// Subscribe to realtime updates for user conversations
  Stream<List<Map<String, dynamic>>> subscribeToConversations(String userId) {
    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .map((rows) {
          // Filter rows client-side since `.stream()` only allows one filter
          final filtered = rows.where((row) =>
            row['user1_id'] == userId || row['user2_id'] == userId
          ).toList();
          AppLogger.i('🔄 Conversations updated after filter: ${filtered.length}');
          return filtered;
        });
  }
}