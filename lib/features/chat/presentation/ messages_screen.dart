import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      context.read<ChatController>().fetchConversations();
    });
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
            debugPrint('⚠️ No conversations to display');
            return const Center(child: Text('No conversations yet.'));
          }

          debugPrint('📋 Conversations count in UI: ${controller.conversations.length}');

          return ListView.separated(
            itemCount: controller.conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final Conversation convo = controller.conversations[index];
              final user = Supabase.instance.client.auth.currentUser;
              final otherUserName = convo.user1Id == user!.id
                  ? (convo.user2Name ?? 'User')
                  : (convo.user1Name ?? 'User');

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
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
                        TimeOfDay.fromDateTime(convo.lastMessageTime!).format(context),
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
