import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/tasks/view/widgets/requests/requests_list_screen.dart';
import '../../../../core/services/logger_service.dart';
import '../../models/task_model.dart';
import '../../../chat/viewmodels/chat_view_model.dart';
import '../../../chat/view/chat_screen.dart';
import '../../../../core/utils/format_price.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import '../../../../features/favorites/data/favorites_service.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';

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
            : Theme.of(context).dividerColor.withValues(alpha: 0.2);
    final String? currentUserId = context.select<TaskViewModel, String?>((vm) => vm.currentUserId);

    final bool isOwner = currentUserId == task.userId;
    final bool isAssigned = task.assignedFreelancerId != null;
    final String primaryCtaLabel = isBooking ? 'Book' : 'Offer';

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
                  SignedAvatar(
                    storagePathOrUrl: task.userAvatar,
                    radius: 20,
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
                              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
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
                  if (task.assignedFreelancerId != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'ASSIGNED',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
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
              if (task.imagePaths.isNotEmpty) ...[
                SignedImage(
                  storagePathOrUrl: task.imagePaths.first,
                  width: double.infinity,
                  height: 160,
                  borderRadius: 12,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 8),
              ],
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
                          final savedVm = context.watch<SavedTasksViewModel>();
                          final isSaved = savedVm.isSaved(task.id);
                          return IconButton(
                            tooltip: isSaved ? 'Remove bookmark' : 'Save task',
                            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                            onPressed: () async {
                              final nowSaved = await savedVm.toggle(task.id);
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
                          final me = context.read<TaskViewModel>().currentUserId;
                          if (me == null) {
                            AppLogger.e('❌ No authenticated user found');
                            return;
                          }
                          if (isOwner) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("You can't start a chat on your own task. Open offers or share your task to get bids."),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                            return; // do not proceed to create a conversation
                          }

                          try {
                            final chatVM = context.read<ChatViewModel>();

                            AppLogger.i('🚀 TaskCard Chat pressed - creating or fetching conversation...');
                            final conversation = await chatVM.createOrGetConversation(
                              taskId: task.id,
                              user1Id: me,
                              user2Id: task.userId,
                            );

                            AppLogger.i('✅ Conversation ready: ${conversation.id}');
                            chatVM.activeConversation = conversation;
                            await chatVM.fetchMessages(conversation.id);

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
                        onPressed: () async {
                          if (isOwner) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("You can't book or offer on your own task.")),
                              );
                            }
                            return;
                          }
                          if (isAssigned && isTender) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('This task is already assigned.')),
                              );
                            }
                            return;
                          }
                          try {
                            if (isBooking) {
                              // Navigate to booking availability for the task owner (freelancer)
                              if (context.mounted) {
                                Navigator.of(context).pushNamed(
                                  '/availability',
                                  arguments: {'freelancerId': task.userId, 'taskId': task.id},
                                );
                              }
                            } else {
                              // Tender → navigate to Requests screen and auto-open submit sheet
                              if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RequestsListScreen(
                                      taskId: task.id,
                                      autoOpenSubmitSheet: true,
                                      isTender: true,
                                      isOwner: isOwner,
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            AppLogger.e('❌ Primary CTA error: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Something went wrong: $e')),
                              );
                            }
                          }
                        },
                        icon: Icon(isBooking ? Icons.book_online_outlined : Icons.local_offer_outlined),
                        label: Text(primaryCtaLabel),
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