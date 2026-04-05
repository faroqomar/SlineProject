import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart' as date_utils;
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';

/// Individual message tile widget matching the new design.
class ConversationListTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationListTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  bool _isUnread(String? myUserId) {
    if (myUserId == null) return false;
    final isFromOther =
        conversation.lastMessageSenderId != null &&
        conversation.lastMessageSenderId != myUserId;
    if (!isFromOther) return false;
    return conversation.lastMessageSeenAt == null;
  }

  static bool _isTypingWithin15s(
    DateTime? presenceUpdatedAt,
    bool otherUserTyping,
  ) {
    if (!otherUserTyping || presenceUpdatedAt == null) return false;
    return DateTime.now().difference(presenceUpdatedAt).inSeconds <= 15;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final vm = context.read<ChatViewModel>();
    final myId = vm.currentUserId;
    final isUnread = _isUnread(myId);

    final isActiveConvo = vm.activeConversation?.id == conversation.id;
    final isOnline = isActiveConvo
        ? vm.otherUserTyping
        : _isTypingWithin15s(
            conversation.presenceUpdatedAt,
            conversation.otherUserTyping,
          );

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
                  // Context Row (Task/Booking)
                  if (conversation.taskTitle != null) ...[
                    Row(
                      children: [
                        Icon(
                          conversation.taskType == 'booking'
                              ? Icons.calendar_today
                              : Icons.assignment_outlined,
                          size: 10,
                          color: conversation.taskType == 'booking'
                              ? AppColors.gold
                              : AppColors.teal,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            conversation.taskTitle!.toUpperCase(),
                            style: AppTypography.micro.copyWith(
                              color: conversation.taskType == 'booking'
                                  ? AppColors.gold
                                  : AppColors.teal,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

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
                          ],
                        ),
                      ),
                      if (conversation.lastMessageTime != null)
                        Text(
                          date_utils.formatFriendlyTime(
                            conversation.lastMessageTime!,
                          ),
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
                      color: isUnread
                          ? colorScheme.text
                          : colorScheme.textSecondary,
                      fontWeight: isUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread badge
            if (isUnread) ...[
              const SizedBox(width: AppDimens.p8),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
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
