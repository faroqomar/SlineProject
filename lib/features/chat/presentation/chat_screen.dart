import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../chat/controllers/chat_controller.dart';
import '../../chat/models/conversation_model.dart';
import '../../chat/models/message_model.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/services/logger_service.dart';

import 'widgets/message_bubble.dart';
import '../attachments/services/send_attachment_usecase.dart';
import '../attachments/widgets/attachment_message_tile.dart';

/// Chat screen
/// Why: shows messages, renders attachments, and triggers receipts.
class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  late final ChatController _chatCtrl;

  @override
  void initState() {
    super.initState();
    _chatCtrl = context.read<ChatController>();
    _chatCtrl.activeConversation = widget.conversation;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppLogger.i('[CHAT] opened: convo=${widget.conversation.id}');
      _chatCtrl.subscribeToActiveConversation();
      if (!mounted) return;
      await _chatCtrl.markReceiptsForActive(delivered: true, seen: true);
    });
  }

  @override
  void dispose() {
    AppLogger.d('[CHAT] closed: convo=${widget.conversation.id}');
    _chatCtrl.unsubscribeFromConversation();
    _messageController.dispose();
    super.dispose();
  }

  /// Trigger image sending via the isolated attachments use-case.
  Future<void> _onPickImage() async {
    try {
      final me = Supabase.instance.client.auth.currentUser?.id;
      if (me == null) return;
      final convo = widget.conversation;
      final receiverId = (convo.user1Id == me) ? convo.user2Id : convo.user1Id;

      await sendImageAttachment(
        conversationId: convo.id,
        senderId: me,
        receiverId: receiverId,
      );

      AppLogger.i('[CHAT] image sent via usecase for convo=${convo.id}');
    } catch (e) {
      AppLogger.e('❌ sendImageAttachment failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.otherUserName ?? 'Chat'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatController>(
              builder: (context, controller, child) {
                if (controller.isLoadingMessages) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.currentMessages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.currentMessages.length,
                  itemBuilder: (context, index) {
                    final Message msg = controller.currentMessages[index];
                    final userId = user?.id;
                    final isMine = (userId != null) && msg.senderId == userId;
                    final status = msg.seenAt != null
                        ? 'read'
                        : (msg.deliveredAt != null ? 'delivered' : 'sent');

                    final hasImage = (msg.attachmentType == 'image') &&
                        (msg.attachmentUrl != null && msg.attachmentUrl!.isNotEmpty);

                    if (hasImage) {
                      final caption = (msg.content.trim().toLowerCase() == '[photo]')
                          ? null
                          : msg.content;
                      return AttachmentMessageTile(
                        isMine: isMine,
                        storagePath: msg.attachmentUrl!,
                        time: formatFriendlyTime(msg.createdAt),
                        caption: caption,
                      );
                    }

                    return MessageBubble(
                      text: msg.content,
                      time: formatFriendlyTime(msg.createdAt),
                      isMine: isMine,
                      status: isMine ? status : null,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    tooltip: 'Send image',
                    onPressed: _onPickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      final text = _messageController.text.trim();
                      if (text.isNotEmpty) {
                        AppLogger.d('[CHAT] send tap: len=${text.length}');
                        context.read<ChatController>().sendMessage(text);
                        _messageController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}