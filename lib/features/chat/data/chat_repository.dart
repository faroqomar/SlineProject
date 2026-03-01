import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

/// Repository layer for Chat feature.
/// Encapsulates data access via MessageService and exposes a stable API
/// to higher layers (ViewModels / Controllers).
class ChatRepository {
  ChatRepository(SupabaseClient client)
    : _service = MessageService(client),
      _client = client;

  final MessageService _service;
  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  // Conversations
  Future<List<Conversation>> getUserConversations(String userId) =>
      _service.getUserConversations(userId);

  Stream<List<Map<String, dynamic>>> subscribeToConversations(String userId) =>
      _service.subscribeToConversations(userId);

  Future<Conversation> createOrGetConversation({
    String? taskId,
    required String user1Id,
    required String user2Id,
  }) => _service.createOrGetConversation(
    taskId: taskId,
    user1Id: user1Id,
    user2Id: user2Id,
  );

  /// Direct DM (favorites-gated per RLS). Use for non–task-linked conversations.
  Future<Conversation> startDirectConversation({
    required String user1Id,
    required String user2Id,
  }) =>
      _service.createOrGetConversation(
        taskId: null,
        user1Id: user1Id,
        user2Id: user2Id,
      );

  /// Task-linked conversation. Non-owner starts via RPC start_task_conversation_v1.
  Future<Conversation> startTaskConversation(String taskId) =>
      _service.createOrGetConversation(
        taskId: taskId,
        user1Id: '',
        user2Id: '',
      );

  /// @deprecated Use [startDirectConversation] or [startTaskConversation]. Kept for compatibility.
  Future<Conversation> startConversationByClient({
    String? taskId,
    required String clientId,
    required String freelancerId,
  }) async {
    final convo = await _service.createOrGetConversation(
      taskId: taskId,
      user1Id: clientId,
      user2Id: freelancerId,
    );
    return convo;
  }

  // Messages
  Future<List<Message>> getMessages(String conversationId) =>
      _service.getMessages(conversationId);

  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    String? attachmentUrl,
    String? attachmentType,
    String? attachmentName,
    int? attachmentSize,
    String? messageType,
    Map<String, dynamic>? payload,
  }) => _service.sendMessage(
    conversationId: conversationId,
    senderId: senderId,
    receiverId: receiverId,
    content: content,
    attachmentUrl: attachmentUrl,
    attachmentType: attachmentType,
    attachmentName: attachmentName,
    attachmentSize: attachmentSize,
    messageType: messageType,
    payload: payload,
  );

  // Receipts
  Future<void> markDelivered(String conversationId) =>
      _service.markDelivered(conversationId);
  Future<void> markSeen(String conversationId) =>
      _service.markSeen(conversationId);

  // Realtime (emits full list per snapshot)
  Stream<List<Message>> subscribeToMessages(String conversationId) =>
      _service.subscribeToMessages(conversationId);

  Future<void> deleteConversation(String conversationId) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('User not logged in');
    return _service.deleteConversation(conversationId, uid);
  }
}
