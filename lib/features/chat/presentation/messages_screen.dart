import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/logger_service.dart';
// Utility functions for formatting date/time in chat UI
import '../../../core/utils/format_date.dart' as date_utils;
import '../../chat/controllers/chat_controller.dart';
import '../../chat/models/conversation_model.dart';
import '../../chat/presentation/chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ChatController>();
      controller.fetchConversations();
      controller.subscribeToUserConversations();
    });
  }

  @override
  void dispose() {
    final controller = context.read<ChatController>();
    controller.unsubscribeFromUserConversations();
    controller.unsubscribeFromConversation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Consumer<ChatController>(
        builder: (context, controller, child) {
          if (controller.isLoadingConversations) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.conversations.isEmpty) {
            // Warning: No conversations to display
            AppLogger.w('⚠️ No conversations to display');
            return const Center(child: Text('No conversations yet.'));
          }

          // Debug: Displaying conversations count in UI
          AppLogger.d('📋 Conversations count in UI: ${controller.conversations.length}');

          return ListView.separated(
            itemCount: controller.conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final Conversation convo = controller.conversations[index];
              final otherUserName = convo.otherUserName ?? 'User';

              return ListTile(
                leading: convo.otherUserAvatar != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(convo.otherUserAvatar!),
                      )
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  otherUserName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  convo.lastMessage ?? convo.taskTitle ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: convo.lastMessageTime != null
                    ? Text(
                        date_utils.formatFriendlyTime(convo.lastMessageTime!),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : null,
                onTap: () async {
                  controller.activeConversation = convo;
                  await controller.fetchMessages(convo.id);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(conversation: convo),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
