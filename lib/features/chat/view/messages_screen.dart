import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
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
    final AppColorScheme colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ChatViewModel>(
        builder: (context, controller, child) {
          // Calculate unread count
          final unreadCount = controller.conversations
              .where((c) => _isUnread(c))
              .length;

          return RefreshIndicator(
            onRefresh: () async => await controller.fetchConversations(),
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
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.conversations.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: colorScheme.textSecondary.withValues(alpha: 0.5),
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
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final Conversation convo = controller.conversations[index];
                          return _MessageTile(
                            conversation: convo,
                            onTap: () => _openChat(context, convo, controller),
                          );
                        },
                        childCount: controller.conversations.length,
                      ),
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
    // Mock unread logic - in real app, check against last read timestamp
    return (convo.lastMessage?.length ?? 0) % 5 == 0;
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: convo),
        ),
      );
    }
  }
}

/// Individual message tile widget matching the new design.
class _MessageTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _MessageTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    // Mock values for demo - in real app, these would come from the model
    final bool isUnread = (conversation.lastMessage?.length ?? 0) % 5 == 0;
    final bool isOnline = (conversation.otherUserName?.length ?? 0) % 2 == 0;
    final bool isVerified = (conversation.otherUserName?.length ?? 0) > 5;
    final int unreadCount = isUnread ? 1 + (conversation.lastMessage?.length ?? 0) % 3 : 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppDimens.p12),
        padding: const EdgeInsets.all(AppDimens.p16),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.teal.withValues(alpha: 0.05)
              : colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r18),
          border: Border.all(
            color: isUnread
                ? AppColors.teal.withValues(alpha: 0.4)
                : colorScheme.cardBorder,
            width: isUnread ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            _buildAvatar(colorScheme, isOnline),
            const SizedBox(width: AppDimens.p12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row with time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                conversation.otherUserName ?? 'User',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.text,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: AppColors.lightTeal,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (conversation.lastMessageTime != null)
                        Text(
                          date_utils.formatFriendlyTime(conversation.lastMessageTime!),
                          style: AppTypography.micro.copyWith(
                            color: colorScheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Last message
                  Text(
                    conversation.lastMessage ?? 'No messages yet',
                    style: AppTypography.bodySmall.copyWith(
                      color: isUnread ? colorScheme.text : colorScheme.textSecondary,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread badge
            if (unreadCount > 0) ...[
              const SizedBox(width: AppDimens.p8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: AppTypography.micro.copyWith(
                      color: AppColors.offWhite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(AppColorScheme colorScheme, bool isOnline) {
    final initials = _getInitials(conversation.otherUserName);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Avatar container with gold background and initials
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(AppDimens.r14),
            border: Border.all(
              color: AppColors.offWhite.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: conversation.otherUserAvatar != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                  child: SignedAvatar(
                    storagePathOrUrl: conversation.otherUserAvatar,
                    radius: 22,
                  ),
                )
              : Center(
                  child: Text(
                    initials,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.almostBlack,
                    ),
                  ),
                ),
        ),

        // Online indicator
        if (isOnline)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.lightTeal,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.phoneBackground,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
