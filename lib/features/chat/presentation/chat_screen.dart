import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../chat/models/conversation_model.dart';
import '../../chat/models/message_model.dart';
import '../../chat/services/attachment_service.dart';
import '../../chat/services/message_service.dart';
import '../../../core/utils/format_date.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _attachmentService = AttachmentService();
  final _messageService = MessageService();

  @override
  void initState() {
    super.initState();
    final chatController = context.read<ChatController>();
    chatController.activeConversation = widget.conversation;
    chatController.subscribeToActiveConversation();
  }

  Future<void> _pickImageAndSend() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      await _sendAttachment(bytes: bytes, filename: xfile.name, type: 'image');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  Future<void> _pickFileAndSend() async {
    try {
      final res = await FilePicker.platform.pickFiles(withData: true);
      if (res == null || res.files.isEmpty) return;
      final file = res.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected file has no bytes.')));
        return;
      }
      await _sendAttachment(bytes: bytes, filename: file.name, type: 'file', size: file.size);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File pick failed: $e')));
    }
  }

  Future<void> _sendAttachment({
    required List<int> bytes,
    required String filename,
    required String type, // 'image' | 'file'
    int? size,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final convo = widget.conversation;
    final senderId = user.id;
    final receiverId = (convo.user1Id == senderId) ? convo.user2Id : convo.user1Id;

    // guard size
    if (size != null && size > 10 * 1024 * 1024) { // 10MB
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File too large (>10MB)')));
      return;
    }

    final path = await _attachmentService.uploadBytes(
      conversationId: convo.id,
      filename: filename,
      bytes: bytes,
    );

    await _messageService.sendMessage(
      conversationId: convo.id,
      senderId: senderId,
      receiverId: receiverId,
      content: '',
      attachmentUrl: path,
      attachmentType: type,
      attachmentName: filename,
      attachmentSize: size ?? bytes.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.otherUserName ?? 'Chat'),
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
                    final isMine = msg.senderId == user!.id;

                    // Attachment rendering
                    if (msg.attachmentUrl != null) {
                      return FutureBuilder<String>(
                        future: _attachmentService.createSignedUrl(msg.attachmentUrl!),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return Align(
                              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                            );
                          }
                          final signed = snap.data!;
                          if (msg.attachmentType == 'image') {
                            return Align(
                              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  signed,
                                  width: MediaQuery.of(context).size.width * 0.6,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          } else {
                            return Align(
                              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMine ? Theme.of(context).primaryColor.withOpacity(0.85) : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.insert_drive_file),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        msg.attachmentName ?? 'File',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: isMine ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      );
                    }

                    // Text bubble
                    return MessageBubble(
                      text: msg.content,
                      time: formatFriendlyTime(msg.createdAt),
                      isMine: isMine,
                      status: isMine ? 'sent' : null,
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
                    tooltip: 'Attach file',
                    icon: const Icon(Icons.attach_file),
                    onPressed: _pickFileAndSend,
                  ),
                  IconButton(
                    tooltip: 'Pick image',
                    icon: const Icon(Icons.image),
                    onPressed: _pickImageAndSend,
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      final text = _messageController.text.trim();
                      if (text.isNotEmpty) {
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