import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/logger_service.dart';
import '../../models/task_model.dart';
import '../../../chat/controllers/chat_controller.dart';
import '../../../chat/presentation/chat_screen.dart';
import '../../../chat/services/ message_service.dart';
import '../../../../core/utils/format_price.dart';

/// A card widget to display basic info about a task.
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: (task.userAvatar != null && task.userAvatar!.isNotEmpty)
                        ? NetworkImage(task.userAvatar!)
                        : null,
                    child: (task.userAvatar == null || task.userAvatar!.isEmpty)
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    task.userName ?? 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(task.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(task.description),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('💰 ${PriceFormatter.formatPrice(task.budget)}'),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user == null) {
                            // Error: No authenticated user found
                            AppLogger.e('❌ No authenticated user found');
                            return;
                          }

                          try {
                            final controller = context.read<ChatController>();
                            final messageService = MessageService();

                            // Info: Starting chat conversation from task card
                            AppLogger.i('🚀 TaskCard Chat pressed - creating or fetching conversation...');
                            final conversation = await messageService.createOrGetConversation(
                              taskId: task.id,
                              user1Id: user.id,
                              user2Id: task.userId,
                            );

                            // Info: Conversation ready for navigation
                            AppLogger.i('✅ Conversation ready: ${conversation.id}');
                            controller.activeConversation = conversation;
                            await controller.fetchMessages(conversation.id);

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(conversation: conversation),
                                ),
                              );
                            }
                          } catch (e) {
                            // Error: Failed to start conversation from task card
                            AppLogger.e('❌ Error starting conversation from TaskCard: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error starting chat: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Chat'),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.book_online_outlined),
                        label: const Text('Book'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}