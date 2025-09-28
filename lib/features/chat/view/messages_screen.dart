import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/utils/format_date.dart' as date_utils;
import '../viewmodels/chat_view_model.dart';
import '../../chat/models/conversation_model.dart';
import '../view/chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // Cache controller to avoid unsafe ancestor lookups in dispose.
  late final ChatViewModel _chatCtrl;

  @override
  void initState() {
    super.initState();
    _chatCtrl = context.read<ChatViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatCtrl.fetchConversations();
      _chatCtrl.subscribeToUserConversations();
    });
  }

  @override
  void dispose() {
    _chatCtrl.unsubscribeFromUserConversations();
    _chatCtrl.unsubscribeFromConversation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Consumer<ChatViewModel>(
        builder: (context, controller, child) {
          if (controller.isLoadingConversations) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.conversations.isEmpty) {
            AppLogger.w('⚠️ No conversations to display');
            return const Center(child: Text('No conversations yet.'));
          }

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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (convo.taskTitle != null)
                      Text(
                        convo.taskTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    Text(
                      convo.lastMessage ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: convo.lastMessageTime != null
                    ? Text(
                        date_utils.formatFriendlyTime(convo.lastMessageTime!),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : null,
                onTap: () async {
                  AppLogger.i('[CONVOS] open: ${convo.id}');
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