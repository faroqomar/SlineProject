import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/core/widgets/glass_container.dart';

import '../viewmodels/chat_view_model.dart';
import '../../chat/models/conversation_model.dart';
import '../../chat/models/message_model.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/services/logger_service.dart';

import 'widgets/message_bubble.dart';
import '../attachments/widgets/attachment_message_tile.dart';

/// Chat screen with Glassmorphism design.
class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  late final ChatViewModel _chatCtrl;

  // Offer Form Controllers
  final _offerTitleCtrl = TextEditingController();
  final _offerDescCtrl = TextEditingController();
  final _offerPriceCtrl = TextEditingController();
  final _offerTimeCtrl = TextEditingController(text: '3');

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
    _offerTitleCtrl.dispose();
    _offerDescCtrl.dispose();
    _offerPriceCtrl.dispose();
    _offerTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onPickImage() async {
    try {
      await _chatCtrl.sendImageForActive();
      AppLogger.i('[CHAT] image sent via usecase for convo=${widget.conversation.id}');
    } catch (e) {
      AppLogger.e('❌ sendImageAttachment failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send image')),
      );
    }
  }

  void _showCreateOfferModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.r30)),
          padding: const EdgeInsets.all(AppDimens.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.p24),
              Text('Create Custom Offer', style: AppTypography.h4),
              const SizedBox(height: AppDimens.p16),
              AppTextField(controller: _offerTitleCtrl, hintText: 'Title'),
              const SizedBox(height: AppDimens.p12),
              AppTextField(controller: _offerDescCtrl, hintText: 'Description', maxLines: 3), // Assumes AppTextField supports maxLines, if not need update
              const SizedBox(height: AppDimens.p12),
              Row(
                children: [
                  Expanded(child: AppTextField(controller: _offerPriceCtrl, hintText: 'Price (\$)', keyboardType: TextInputType.number)),
                  const SizedBox(width: AppDimens.p12),
                  Expanded(child: AppTextField(controller: _offerTimeCtrl, hintText: 'Days', keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: AppDimens.p24),
              AppButton(
                text: 'Send Offer',
                width: double.infinity,
                onPressed: () {
                  // Mock sending offer as JSON string
                  final offerData = {
                    'type': 'offer',
                    'title': _offerTitleCtrl.text,
                    'description': _offerDescCtrl.text,
                    'price': _offerPriceCtrl.text,
                    'delivery': _offerTimeCtrl.text,
                  };
                  _chatCtrl.sendMessage(jsonEncode(offerData));
                  Navigator.pop(context);
                  _offerTitleCtrl.clear();
                  _offerDescCtrl.clear();
                  _offerPriceCtrl.clear();
                  _offerTimeCtrl.text = '3';
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<ChatViewModel>().currentUserId;
    final AppColorScheme colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // --- Messages List ---
          Positioned.fill(
            child: Consumer<ChatViewModel>(
              builder: (context, controller, child) {
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.p16,
                    AppDimens.p100, // Top padding for header
                    AppDimens.p16,
                    AppDimens.p100, // Bottom padding for input
                  ),
                  itemCount: controller.currentMessages.length,
                  itemBuilder: (context, index) {
                    final Message msg = controller.currentMessages[index];
                    final isMine = (me != null) && msg.senderId == me;
                    final status = msg.seenAt != null
                        ? 'read'
                        : (msg.deliveredAt != null ? 'delivered' : 'sent');

                    // Check for Custom Offer (Mock JSON)
                    if (msg.content.trim().startsWith('{"type":"offer"')) {
                      try {
                        final offerData = jsonDecode(msg.content);
                        return _buildOfferBubble(context, offerData, isMine, msg.createdAt);
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
            child: ClipRect(
              child: GlassContainer(
                borderRadius: BorderRadius.zero,
                padding: EdgeInsets.fromLTRB(
                  AppDimens.p16,
                  MediaQuery.of(context).padding.top + AppDimens.p8,
                  AppDimens.p16,
                  AppDimens.p12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: colorScheme.text, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          widget.conversation.otherUserName ?? 'Chat',
                          style: AppTypography.h5.copyWith(color: colorScheme.text),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _showCreateOfferModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_money, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Offer',
                              style: AppTypography.captionBold.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Input Area ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GlassContainer(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.r24)),
              padding: EdgeInsets.fromLTRB(
                AppDimens.p16,
                AppDimens.p12,
                AppDimens.p16,
                MediaQuery.of(context).padding.bottom + AppDimens.p12,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image, color: AppColors.teal),
                    onPressed: _onPickImage,
                  ),
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
                          contentPadding: const EdgeInsets.only(bottom: 10), // Center align vertically roughly
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final text = _messageController.text.trim();
                      if (text.isNotEmpty) {
                        _chatCtrl.sendMessage(text);
                        _messageController.clear();
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: AppColors.teal,
                      radius: 23,
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferBubble(BuildContext context, Map<String, dynamic> offer, bool isMine, DateTime time) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'CUSTOM OFFER',
                      style: AppTypography.micro.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '\$${offer['price']}',
                    style: AppTypography.h5.copyWith(color: AppColors.teal, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(offer['title'] ?? '', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(offer['description'] ?? '', style: AppTypography.micro),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${offer['delivery']} Days Delivery', style: AppTypography.micro),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Accept',
                      height: 36,
                      onPressed: () {
                        // TODO: Accept Offer Logic
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      text: 'Decline',
                      height: 36,
                      isPrimary: false,
                      onPressed: () {
                        // TODO: Decline Offer Logic
                      },
                    ),
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