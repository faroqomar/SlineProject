import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart'; // Added
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
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
                              style: AppTypography.h3.copyWith(
                                color: colorScheme.text,
                              ),
                            ),
                            Text(
                              '0 unread conversations', // Mock count
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        GlassContainer(
                          borderRadius: BorderRadius.circular(AppDimens.r14),
                          padding: const EdgeInsets.all(AppDimens.p10),
                          child: Icon(
                            Icons.filter_list,
                            color: colorScheme.text,
                            size: AppDimens.p24,
                          ),
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
                          Icon(Icons.chat_bubble_outline, size: 64, color: colorScheme.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text('No messages yet', style: AppTypography.bodyMedium.copyWith(color: colorScheme.textSecondary)),
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
                          return _buildMessageTile(context, convo, controller);
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

  Widget _buildMessageTile(BuildContext context, Conversation convo, ChatViewModel controller) {
    final AppColorScheme colorScheme = context.colorScheme;
    // Mock unread status based on arbitrary condition to avoid dead code warnings
    final bool isUnread = (convo.lastMessage?.length ?? 0) % 5 == 0;

    return GestureDetector(
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
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.p12),
        decoration: AppDecorations.glassBoxDecoration(
          colorScheme: colorScheme,
          borderRadius: BorderRadius.circular(AppDimens.r18),
        ).copyWith(
          // Highlight unread
          border: isUnread ? Border.all(color: AppColors.teal.withValues(alpha: 0.4)) : null,
          color: isUnread ? AppColors.teal.withValues(alpha: 0.05) : null,
        ),
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.gold, // Placeholder bg color
                    borderRadius: BorderRadius.circular(AppDimens.r14),
                    border: Border.all(color: AppColors.offWhite.withValues(alpha: 0.2), width: 2),
                  ),
                  child: SignedAvatar(
                    storagePathOrUrl: convo.otherUserAvatar,
                    radius: 22,
                  ),
                ),
                // Online Status (Mock)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.lightTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.phoneBackground, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppDimens.p12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          convo.otherUserName ?? 'User',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (convo.lastMessageTime != null)
                        Text(
                          date_utils.formatFriendlyTime(convo.lastMessageTime!),
                          style: AppTypography.micro.copyWith(
                            color: colorScheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    convo.lastMessage ?? 'No messages yet',
                    style: AppTypography.bodySmall.copyWith(
                      color: isUnread ? colorScheme.text : colorScheme.textSecondary,
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread Badge
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(left: AppDimens.p8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '1',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.offWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}