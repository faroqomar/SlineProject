import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/skeleton_card.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/features/chat/view/widgets/conversation_list_tile.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
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
    final colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ChatViewModel>(
        builder: (context, controller, child) {
          // Calculate unread count
          final unreadCount = controller.conversations
              .where(_isUnread)
              .length;

          return RefreshIndicator(
            onRefresh: () async => controller.fetchConversations(),
            child: CustomScrollView(
              slivers: [
                // --- Header ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppDimens.p24,
                      topPadding + AppDimens.p24,
                      AppDimens.p24,
                      AppDimens.p16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Messages',
                              style: AppTypography.h2.copyWith(
                                color: colorScheme.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$unreadCount unread conversations',
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // --- List ---
                if (controller.isLoadingConversations)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p16,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const SkeletonConversationTile(),
                        childCount: 6,
                      ),
                    ),
                  )
                else if (controller.conversations.isEmpty)
                  SliverFillRemaining(
                    key: const ValueKey('message_list_empty_state'),
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: colorScheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: AppTypography.h5.copyWith(
                              color: colorScheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation by contacting a freelancer',
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.p16,
                      0,
                      AppDimens.p16,
                      AppDimens.p100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final convo =
                            controller.conversations[index];
                        return Dismissible(
                          key: ValueKey(convo.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(
                              bottom: AppDimens.p12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightRed,
                              borderRadius: BorderRadius.circular(
                                AppDimens.r18,
                              ),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(
                              right: AppDimens.p24,
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: colorScheme.cardBackground,
                                title: Text(
                                  'Delete Conversation?',
                                  style: AppTypography.h3,
                                ),
                                content: Text(
                                  'This will hide the conversation until a new message is sent.',
                                  style: AppTypography.bodyMedium,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: colorScheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: AppColors.lightRed,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) {
                            controller.deleteConversation(convo.id).catchError((
                              e,
                            ) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not archive this conversation. Please try again.',
                                    ),
                                  ),
                                );
                                controller.fetchConversations();
                              }
                            });
                          },
                          child: ConversationListTile(
                            conversation: convo,
                            onTap: () => _openChat(context, convo, controller),
                          ),
                        );
                      }, childCount: controller.conversations.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isUnread(Conversation convo) {
    final myId = context.read<ChatViewModel>().currentUserId;
    if (myId == null) return false;
    final isFromOther =
        convo.lastMessageSenderId != null && convo.lastMessageSenderId != myId;
    if (!isFromOther) return false;
    return convo.lastMessageSeenAt == null;
  }

  Future<void> _openChat(
    BuildContext context,
    Conversation convo,
    ChatViewModel controller,
  ) async {
    AppLogger.i('[CONVOS] open: ${convo.id}');
    controller.activeConversation = convo;
    await controller.fetchMessages(convo.id);
    if (context.mounted) {
      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(conversation: convo)),
        ),
      );
    }
  }
}
