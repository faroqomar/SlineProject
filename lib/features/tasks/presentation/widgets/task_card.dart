import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/logger_service.dart';
import '../../models/task_model.dart';
import '../../../chat/controllers/chat_controller.dart';
import '../../../chat/presentation/chat_screen.dart';
import '../../../chat/services/message_service.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/saved/controller/saved_tasks_controller.dart';
import '../../../../features/favorites/data/favorites_service.dart';

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
    final bool isTender = task.isTender == true;
    final bool isBooking = task.isBooking == true;
    final Color cardBg = isTender
        ? AppColors.tenderCardBg(context)
        : isBooking
            ? AppColors.bookingCardBg(context)
            : Theme.of(context).colorScheme.surface;
    final Color borderColor = isTender
        ? AppColors.tenderBorder(context)
        : isBooking
            ? AppColors.bookingBorder(context)
            : Theme.of(context).dividerColor.withOpacity(0.2);

    return Card(
      elevation: 0,
      color: cardBg,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
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
                  Expanded(
                    child: Text(
                      task.userName ?? 'Unknown User',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isTender
                          ? AppColors.tenderChipBg(context)
                          : isBooking
                              ? AppColors.bookingChipBg(context)
                              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      isTender ? 'TENDER' : (isBooking ? 'BOOKING' : 'TASK'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              // Show resolved category name (from embedded join) with fallback
              Text(
                'Category: ${task.categoryName ?? 'Uncategorized'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 6),
              Text(task.description),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('💰 ${PriceFormatter.formatPrice(task.budget)}'),
                  Row(
                    children: [
                      // Bookmark toggle
                      Builder(
                        builder: (context) {
                          final savedCtrl = context.watch<SavedTasksController>();
                          final isSaved = savedCtrl.isSaved(task.id);
                          return IconButton(
                            tooltip: isSaved ? 'Remove bookmark' : 'Save task',
                            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                            onPressed: () async {
                              final nowSaved = await savedCtrl.toggle(task.id);
                              if (!context.mounted) return;
                              final snackBar = SnackBar(
                                content: Text(nowSaved ? 'Task saved' : 'Bookmark removed'),
                                action: nowSaved
                                    ? SnackBarAction(
                                        label: 'Add freelancer to favorites',
                                        onPressed: () async {
                                          try {
                                            await FavoritesService().addFavorite(task.userId);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Freelancer added to favorites')),
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            final msg = e.toString().contains('23505')
                                                ? 'Already in favorites'
                                                : e.toString().toLowerCase().contains('rls')
                                                    ? 'Not allowed for your role'
                                                    : 'Failed to add favorite';
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(msg)),
                                            );
                                          }
                                        },
                                      )
                                    : null,
                                duration: const Duration(seconds: 4),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(snackBar);
                            },
                          );
                        },
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user == null) {
                            AppLogger.e('❌ No authenticated user found');
                            return;
                          }

                          try {
                            final controller = context.read<ChatController>();
                            final messageService = MessageService();

                            AppLogger.i('🚀 TaskCard Chat pressed - creating or fetching conversation...');
                            final conversation = await messageService.createOrGetConversation(
                              taskId: task.id,
                              user1Id: user.id,
                              user2Id: task.userId,
                            );

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