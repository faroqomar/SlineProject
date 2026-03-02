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
import 'widgets/chat_context_widget.dart'; // Added
import '../../chat/models/message_model.dart';
import '../../chat/models/chat_offer_payload.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/services/logger_service.dart';

import 'widgets/message_bubble.dart';
import 'widgets/offer_message_bubble.dart';
import 'widgets/create_offer_sheet.dart';
import '../attachments/widgets/attachment_message_tile.dart';

/// Chat screen with Glassmorphism design matching the new design system.
class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final bool enableLifecycleEffects;
  final AttachmentSignedUrlResolver? attachmentSignedUrlResolver;
  static const Key messageInputKey = ValueKey<String>(
    'chat_message_input_field',
  );
  static const Key sendButtonKey = ValueKey<String>('chat_send_button');

  const ChatScreen({
    super.key,
    required this.conversation,
    this.enableLifecycleEffects = true,
    this.attachmentSignedUrlResolver,
  });

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
    if (widget.enableLifecycleEffects) {
      _chatCtrl.activeConversation = widget.conversation;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        AppLogger.i('[CHAT] opened: convo=${widget.conversation.id}');
        _chatCtrl.subscribeToActiveConversation();
        if (!mounted) return;
        await _chatCtrl.markReceiptsForActive(delivered: true, seen: true);
      });
    }
  }

  @override
  void dispose() {
    AppLogger.d('[CHAT] closed: convo=${widget.conversation.id}');
    if (widget.enableLifecycleEffects) {
      _chatCtrl.unsubscribeFromConversation();
    }
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _onPickImage() async {
    try {
      await _chatCtrl.sendImageForActive();
      AppLogger.i(
        '[CHAT] image sent via usecase for convo=${widget.conversation.id}',
      );
    } catch (e) {
      AppLogger.e('sendImageAttachment failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send image')));
    }
  }

  void _showCreateOfferModal() {
    showCreateOfferSheet(
      context,
      onSubmit: (title, description, priceStr, deliveryStr) async {
        final price = int.tryParse(priceStr) ?? 0;
        final days = int.tryParse(deliveryStr) ?? 3;
        if (price <= 0) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a valid price')),
            );
          }
          return;
        }
        try {
          await _chatCtrl.createDirectOffer(
            title: title.isNotEmpty ? title : null,
            description: description.isNotEmpty ? description : null,
            price: price,
            days: days,
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to create offer: $e')));
        }
      },
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

                    // Check for Offer (Structured or Legacy JSON)
                    if (msg.messageType == MessageType.offer ||
                        msg.content.trim().startsWith('{"type":"offer"')) {
                      Map<String, dynamic> offerData = {};
                      if (msg.messageType == MessageType.offer) {
                        offerData = msg.payload;
                      } else {
                        try {
                          offerData = jsonDecode(msg.content);
                        } catch (_) {}
                      }

                      if (offerData.isNotEmpty) {
                        final offerId = offerData['offer_id'] as String?;
                        final rawStatus =
                            controller.getOfferStatus(offerId) ??
                            offerData['status']?.toString() ??
                            'sent';
                        return OfferMessageBubble(
                          title: offerData['title'] ?? '',
                          description: offerData['description'] ?? '',
                          price: offerData['price']?.toString() ?? '0',
                          deliveryDays: ChatOfferPayload.daysFromPayload(
                            offerData,
                          ).toString(),
                          status: _parseOfferStatus(rawStatus),
                          isMine: isMine,
                          time: formatFriendlyTime(msg.createdAt),
                          onAccept: () =>
                              _onAcceptOffer(context, msg, offerData),
                          onDecline: () => _chatCtrl.rejectOffer(msg),
                          offerId: offerId,
                          rawStatus: rawStatus,
                          onCancel: offerId != null
                              ? () => _chatCtrl.cancelOffer(offerId)
                              : null,
                          onDeliver: offerId != null
                              ? () => _chatCtrl.markOfferDelivered(offerId)
                              : null,
                          onComplete: offerId != null
                              ? () => _chatCtrl.completeOffer(offerId)
                              : null,
                        );
                      }
                    }

                    final hasImage =
                        (msg.attachmentType == 'image') &&
                        (msg.attachmentUrl != null &&
                            msg.attachmentUrl!.isNotEmpty);

                    if (hasImage) {
                      return AttachmentMessageTile(
                        isMine: isMine,
                        storagePath: msg.attachmentUrl!,
                        time: formatFriendlyTime(msg.createdAt),
                        caption: msg.content != '[photo]' ? msg.content : null,
                        signedUrlResolver: widget.attachmentSignedUrlResolver,
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
    return Column(
      children: [
        ClipRect(
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
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: colorScheme.text,
                        size: 20,
                      ),
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

                // Offer button: show in all 1:1 chats (direct or task-linked)
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showCreateOfferModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.p12,
                          vertical: AppDimens.p6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(AppDimens.r20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: AppColors.white,
                              size: AppDimens.iconSizeSmall,
                            ),
                            const SizedBox(width: AppDimens.p4),
                            Text(
                              'Offer',
                              style: AppTypography.captionBold.copyWith(
                                color: AppColors.white,
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
        ),
        // Task context banner when conversation is task-linked
        ChatContextWidget(conversation: widget.conversation),
      ],
    );
  }

  Widget _buildInputArea(BuildContext context, AppColorScheme colorScheme) {
    return GlassContainer(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.r24),
      ),
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
              width: AppDimens.p40,
              height: AppDimens.p40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.attach_file,
                color: AppColors.teal,
                size: AppDimens.p22,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.p8),

          // Text input
          Expanded(
            child: Container(
              height: 46, // Standard input height from design
              decoration: BoxDecoration(
                color: colorScheme.inputBackground,
                borderRadius: BorderRadius.circular(AppDimens.r23),
                border: Border.all(color: colorScheme.inputBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
              child: TextField(
                key: ChatScreen.messageInputKey,
                controller: _messageController,
                style: TextStyle(color: colorScheme.text),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: colorScheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: AppDimens.p10),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.p8),

          // Send button (disabled while sending; clear input only on success)
          Consumer<ChatViewModel>(
            builder: (context, vm, _) {
              final sending = vm.isSending;
              return GestureDetector(
                onTap: sending
                    ? null
                    : () async {
                        final text = _messageController.text.trim();
                        if (text.isEmpty) return;
                        try {
                          await _chatCtrl.sendMessage(text);
                          if (context.mounted) _messageController.clear();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Message could not be sent. Please try again.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: Container(
                  key: ChatScreen.sendButtonKey,
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: sending
                        ? AppColors.teal.withValues(alpha: 0.5)
                        : AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: AppColors.white,
                    size: AppDimens.p20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onAcceptOffer(
    BuildContext context,
    Message msg,
    Map<String, dynamic> offerData,
  ) async {
    try {
      await _chatCtrl.acceptOffer(msg);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Offer accepted. Complete payment from your Dashboard.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is Exception ? e.toString() : 'Failed to accept offer',
          ),
        ),
      );
    }
  }

  OfferStatus _parseOfferStatus(String? status) {
    if (status == null) return OfferStatus.pending;
    switch (status) {
      case 'accepted':
      case 'completed':
        return OfferStatus.accepted;
      case 'declined':
      case 'rejected':
      case 'canceled':
      case 'refunded':
        return OfferStatus.declined;
      default:
        return OfferStatus.pending;
    }
  }
}
