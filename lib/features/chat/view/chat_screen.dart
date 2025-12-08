import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';

import '../viewmodels/chat_view_model.dart';
import '../../chat/models/conversation_model.dart';
import '../../chat/models/message_model.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/services/logger_service.dart';

import 'widgets/message_bubble.dart';
import 'widgets/offer_message_bubble.dart';
import 'widgets/create_offer_sheet.dart';
import '../attachments/widgets/attachment_message_tile.dart';
import 'video_call_modal.dart';

/// Chat screen with Glassmorphism design matching the new design system.
class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  late final ChatViewModel _chatCtrl;

  @override
  void initState() {
    super.initState();
    _chatCtrl = context.read<ChatViewModel>();
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

  Future<void> _onPickImage() async {
    try {
      await _chatCtrl.sendImageForActive();
      AppLogger.i('[CHAT] image sent via usecase for convo=${widget.conversation.id}');
    } catch (e) {
      AppLogger.e('sendImageAttachment failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send image')),
      );
    }
  }

  void _showCreateOfferModal() {
    showCreateOfferSheet(
      context,
      onSubmit: (title, description, price, delivery) {
        final offerData = {
          'type': 'offer',
          'title': title,
          'description': description,
          'price': price,
          'delivery': delivery,
          'status': 'pending',
        };
        _chatCtrl.sendMessage(jsonEncode(offerData));
      },
    );
  }

  void _startVideoCall() {
    // Navigate to video call modal
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoCallModal(
          userName: widget.conversation.otherUserName ?? 'User',
          userAvatar: widget.conversation.otherUserAvatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<ChatViewModel>().currentUserId;
    final AppColorScheme colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: Stack(
        children: [
          // --- Messages List ---
          Positioned.fill(
            child: Consumer<ChatViewModel>(
              builder: (context, controller, child) {
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.p16,
                    AppDimens.p100,
                    AppDimens.p16,
                    AppDimens.p100,
                  ),
                  itemCount: controller.currentMessages.length,
                  itemBuilder: (context, index) {
                    final Message msg = controller.currentMessages[index];
                    final isMine = (me != null) && msg.senderId == me;
                    final status = msg.seenAt != null
                        ? 'read'
                        : (msg.deliveredAt != null ? 'delivered' : 'sent');

                    // Check for Custom Offer (JSON format)
                    if (msg.content.trim().startsWith('{"type":"offer"')) {
                      try {
                        final offerData = jsonDecode(msg.content);
                        return OfferMessageBubble(
                          title: offerData['title'] ?? '',
                          description: offerData['description'] ?? '',
                          price: offerData['price'] ?? '0',
                          deliveryDays: offerData['delivery'] ?? '3',
                          status: _parseOfferStatus(offerData['status']),
                          isMine: isMine,
                          time: formatFriendlyTime(msg.createdAt),
                          onAccept: () {
                            // TODO: Accept offer logic
                          },
                          onDecline: () {
                            // TODO: Decline offer logic
                          },
                        );
                      } catch (_) {
                        // Fallback if parsing fails
                      }
                    }

                    final hasImage = (msg.attachmentType == 'image') &&
                        (msg.attachmentUrl != null && msg.attachmentUrl!.isNotEmpty);

                    if (hasImage) {
                      return AttachmentMessageTile(
                        isMine: isMine,
                        storagePath: msg.attachmentUrl!,
                        time: formatFriendlyTime(msg.createdAt),
                        caption: msg.content != '[photo]' ? msg.content : null,
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

          // --- Header ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(context, colorScheme),
          ),

          // --- Input Area ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInputArea(context, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colorScheme) {
    return ClipRect(
      child: GlassContainer(
        borderRadius: BorderRadius.zero,
        padding: EdgeInsets.fromLTRB(
          AppDimens.p8,
          MediaQuery.of(context).padding.top + AppDimens.p8,
          AppDimens.p16,
          AppDimens.p12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button and name
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: colorScheme.text, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  widget.conversation.otherUserName ?? 'Chat',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.text,
                  ),
                ),
              ],
            ),

            // Action buttons
            Row(
              children: [
                // Video call button
                GestureDetector(
                  onTap: _startVideoCall,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videocam,
                      color: AppColors.teal,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.p8),

                // Offer button
                GestureDetector(
                  onTap: _showCreateOfferModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p12,
                      vertical: AppDimens.p6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Offer',
                          style: AppTypography.captionBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, AppColorScheme colorScheme) {
    return GlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.r24)),
      padding: EdgeInsets.fromLTRB(
        AppDimens.p16,
        AppDimens.p12,
        AppDimens.p16,
        MediaQuery.of(context).padding.bottom + AppDimens.p12,
      ),
      child: Row(
        children: [
          // Attachment button
          GestureDetector(
            onTap: _onPickImage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.attach_file,
                color: AppColors.teal,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.p8),

          // Text input
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: colorScheme.inputBackground,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: colorScheme.inputBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: colorScheme.text),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: colorScheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.p8),

          // Send button
          GestureDetector(
            onTap: () {
              final text = _messageController.text.trim();
              if (text.isNotEmpty) {
                _chatCtrl.sendMessage(text);
                _messageController.clear();
              }
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  OfferStatus _parseOfferStatus(String? status) {
    switch (status) {
      case 'accepted':
        return OfferStatus.accepted;
      case 'declined':
        return OfferStatus.declined;
      default:
        return OfferStatus.pending;
    }
  }
}

