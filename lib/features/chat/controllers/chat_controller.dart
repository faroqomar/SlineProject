import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';

/// Controller for managing chat functionality
class ChatController extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  /// List of chat messages
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Send a new message
  Future<void> sendMessage(String content, String senderId) async {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      senderId: senderId,
      timestamp: DateTime.now(),
    );

    _messages.add(message);
    notifyListeners();

    // TODO: Implement actual message sending to Supabase
    // await _chatService.sendMessage(message);
  }

  /// Load chat messages
  Future<void> loadMessages() async {
    _setLoading(true);
    try {
      // TODO: Implement loading messages from Supabase
      // final messages = await _chatService.getMessages();
      // _messages.clear();
      // _messages.addAll(messages);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
