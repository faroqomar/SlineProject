import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/chat/attachments/widgets/attachment_message_tile.dart';
import 'package:sline_app/features/chat/models/chat_offer_payload.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/models/message_model.dart';
import 'package:sline_app/features/chat/view/widgets/chat_context_widget.dart';
import 'package:sline_app/features/chat/view/widgets/create_offer_sheet.dart';
import 'package:sline_app/features/chat/view/widgets/message_bubble.dart';
import 'package:sline_app/features/chat/view/widgets/offer_message_bubble.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';

/// Chat screen with message grouping, enhanced date separators, animated send
/// button, scroll-to-bottom FAB, rich empty state, and full Semantics coverage.
///
/// Phase 5 redesign: added message grouping (same sender within 2-minute window
/// renders tighter spacing + adjusted corner radii), enhanced date separators
/// (pill-style with horizontal rules), opacity-animated send button,
/// keyboard-aware scroll FAB, and accessibility labels throughout.
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

// ── Chat list item types for unified message + separator rendering ──
/// Sealed type representing items in the flat chat list.
/// Either a message (with grouping flags) or a date separator.
sealed class _ChatListItem {}

class _MessageItem extends _ChatListItem {
  final Message message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  _MessageItem(
    this.message, {
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });
}

class _DateSeparatorItem extends _ChatListItem {
  final DateTime date;
  _DateSeparatorItem(this.date);
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatViewModel _chatCtrl;

  /// Whether the user has scrolled far enough to show the scroll-to-bottom FAB.
  bool _showScrollFab = false;

  /// Whether the text input has content (for send button opacity animation).
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _chatCtrl = context.read<ChatViewModel>();
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onTextChanged);

    if (widget.enableLifecycleEffects) {
      _chatCtrl.activeConversation = widget.conversation;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        AppLogger.i(
          '[ChatScreen] opened: convo=${widget.conversation.id}',
          tag: 'Chat',
        );
        unawaited(_chatCtrl.subscribeToActiveConversation());
        if (!mounted) return;
        await _chatCtrl.markReceiptsForActive(delivered: true, seen: true);
      });
    }
  }

  @override
  void dispose() {
    AppLogger.d(
      '[ChatScreen] closed: convo=${widget.conversation.id}',
      tag: 'Chat',
    );
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    if (widget.enableLifecycleEffects) {
      _chatCtrl.unsubscribeFromConversation();
    }
    super.dispose();
  }

  void _onScroll() {
    // Show FAB when scrolled more than 2 screen heights from bottom
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    final screenHeight = MediaQuery.of(context).size.height;
    final showFab = (maxExtent - current) > screenHeight * 2;
    if (showFab != _showScrollFab) {
      setState(() => _showScrollFab = showFab);
    }
  }

  void _onTextChanged() {
    final hasContent = _messageController.text.trim().isNotEmpty;
    if (hasContent != _hasText) {
      setState(() => _hasText = hasContent);
    }
  }

  /// Build the flat list of chat items: messages + date separators.
  /// Computes grouping flags (isFirstInGroup/isLastInGroup) based on
  /// sender continuity and 2-minute time window.
  List<_ChatListItem> _buildChatItems(List<Message> messages) {
    if (messages.isEmpty) return [];
    final items = <_ChatListItem>[];
    DateTime? lastDate;

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final msgDate = msg.createdAt.toLocal();
      final dayKey = DateTime(msgDate.year, msgDate.month, msgDate.day);

      // Insert date separator at day boundaries
      if (lastDate == null || dayKey != lastDate) {
        items.add(_DateSeparatorItem(dayKey));
        lastDate = dayKey;
      }

      // Compute grouping based on adjacent messages
      final prevMsg = i > 0 ? messages[i - 1] : null;
      final nextMsg = i < messages.length - 1 ? messages[i + 1] : null;

      final isFirstInGroup = _isGroupBreakBefore(msg, prevMsg);
      final isLastInGroup = _isGroupBreakAfter(msg, nextMsg);

      items.add(
        _MessageItem(
          msg,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
        ),
      );
    }

    return items;
  }

  /// Check if there's a group break before this message.
  /// A break occurs if: previous message is null, different sender, different
  /// day, or time gap > 2 minutes.
  ///
  /// The day-boundary check below is intentionally redundant with the date
  /// separators inserted by [_buildChatItems]. Those separators sit between
  /// messages from different days, so the first message after a separator
  /// would already be in a new group by the sender check — but the explicit
  /// day comparison guards against edge cases where two messages from the same
  /// sender straddle midnight within the 2-minute window, ensuring the group
  /// is still broken even if the sender ID and time gap checks would otherwise
  /// let them merge.
  bool _isGroupBreakBefore(Message current, Message? previous) {
    if (previous == null) return true;
    if (previous.senderId != current.senderId) return true;
    final gap = current.createdAt.difference(previous.createdAt);
    if (gap.inMinutes > 2) return true;
    // Break the group at a calendar-day boundary (midnight crossing).
    // This handles the rare case where two consecutive messages from the same
    // sender are less than 2 minutes apart but span two different days.
    final currDay = current.createdAt.toLocal();
    final prevDay = previous.createdAt.toLocal();
    if (currDay.day != prevDay.day ||
        currDay.month != prevDay.month ||
        currDay.year != prevDay.year) {
      return true;
    }
    return false;
  }

  /// Check if there's a group break after this message.
  bool _isGroupBreakAfter(Message current, Message? next) {
    if (next == null) return true;
    if (next.senderId != current.senderId) return true;
    final gap = next.createdAt.difference(current.createdAt);
    if (gap.inMinutes > 2) return true;
    final currDay = current.createdAt.toLocal();
    final nextDay = next.createdAt.toLocal();
    if (currDay.day != nextDay.day ||
        currDay.month != nextDay.month ||
        currDay.year != nextDay.year) {
      return true;
    }
    return false;
  }

  /// Format date for separator: "Today", "Yesterday", or locale-aware short
  /// date (e.g. "Mon, Apr 7"). "Today"/"Yesterday" are kept as plain English
  /// strings since the app does not yet have l10n entries for them. All other
  /// dates delegate to [DateFormat.MMMEd] so weekday and month names honour
  /// the device locale automatically.
  String _formatSeparatorDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';

    // MMMEd produces e.g. "Mon, Apr 7" in en, "الاثنين، ٧ أبريل" in ar, etc.
    return DateFormat.MMMEd().format(date);
  }

  Future<void> _onPickImage() async {
    try {
      await _chatCtrl.sendImageForActive();
      AppLogger.i(
        '[ChatScreen] image sent for convo=${widget.conversation.id}',
        tag: 'Chat',
      );
    } on Exception catch (e) {
      AppLogger.e('sendImageAttachment failed', error: e, tag: 'Chat');
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
        } on Exception catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to create offer: $e')));
        }
      },
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: AppMotion.emphasis,
      curve: AppMotion.curveDecel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<ChatViewModel>().currentUserId;
    final colorScheme = context.colorScheme;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: Stack(
        children: [
          // ── Messages List ──────────────────────────────────────
          Positioned.fill(
            child: Consumer<ChatViewModel>(
              builder: (context, controller, child) {
                final messages = controller.currentMessages;

                // Empty state
                if (messages.isEmpty && !controller.isLoadingMessages) {
                  return _buildEmptyState(colorScheme);
                }

                final chatItems = _buildChatItems(messages);

                return Semantics(
                  label: 'Chat messages',
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppLayout.spacingSection,
                      AppDimens.p100,
                      AppLayout.spacingSection,
                      AppDimens.p100,
                    ),
                    itemCount: chatItems.length,
                    itemBuilder: (context, index) {
                      final item = chatItems[index];

                      // Date separator
                      if (item is _DateSeparatorItem) {
                        return _buildDateSeparator(item.date, colorScheme);
                      }

                      // Message item
                      final msgItem = item as _MessageItem;
                      final msg = msgItem.message;
                      final isMine = (me != null) && msg.senderId == me;
                      final status =
                          controller.isPresenceReceiptsEnabled && isMine
                          ? (msg.seenAt != null
                                ? 'read'
                                : (msg.deliveredAt != null
                                      ? 'delivered'
                                      : 'sent'))
                          : (isMine ? 'sent' : null);

                      // Offer messages (structured or legacy JSON)
                      if (msg.messageType == MessageType.offer ||
                          msg.content.trim().startsWith('{"type":"offer"')) {
                        var offerData = <String, dynamic>{};
                        if (msg.messageType == MessageType.offer) {
                          offerData = msg.payload;
                        } else {
                          try {
                            offerData = jsonDecode(msg.content);
                          } on Exception catch (e) {
                            AppLogger.w(
                              'Failed to decode legacy offer JSON',
                              error: e,
                              tag: 'Chat',
                            );
                          }
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

                      // Image attachments
                      final hasImage =
                          (msg.attachmentType == 'image') &&
                          (msg.attachmentUrl != null &&
                              msg.attachmentUrl!.isNotEmpty);

                      if (hasImage) {
                        return AttachmentMessageTile(
                          isMine: isMine,
                          storagePath: msg.attachmentUrl!,
                          time: formatFriendlyTime(msg.createdAt),
                          caption: msg.content != '[photo]'
                              ? msg.content
                              : null,
                          signedUrlResolver: widget.attachmentSignedUrlResolver,
                        );
                      }

                      // Regular text messages with grouping
                      return MessageBubble(
                        text: msg.content,
                        time: formatFriendlyTime(msg.createdAt),
                        isMine: isMine,
                        status: isMine ? status : null,
                        isFirstInGroup: msgItem.isFirstInGroup,
                        isLastInGroup: msgItem.isLastInGroup,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // ── Header ─────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(context, colorScheme),
          ),

          // ── Input Area ─────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInputArea(context, colorScheme),
          ),

          // ── Scroll-to-bottom FAB ───────────────────────────────
          // Always kept in the widget tree so AnimatedSlide/AnimatedOpacity
          // exit animations can play. Visibility is driven purely by the
          // animation values: slide offscreen and fade to 0 when hidden.
          // IgnorePointer prevents taps when the FAB is not visible.
          Positioned(
            // Position above input area: compact button + section spacing + extra
            bottom: AppLayout.buttonHeightCompact + AppLayout.spacingSection + AppLayout.spacingSection,
            right: AppLayout.spacingSection,
            child: IgnorePointer(
              // Block taps when the FAB is not showing
              ignoring: !(_showScrollFab && !keyboardOpen),
              child: Semantics(
                button: true,
                label: 'Scroll to latest messages',
                child: AnimatedSlide(
                  duration: AppMotion.standard,
                  curve: AppMotion.curveDecel,
                  // Slide down out of view when hidden
                  offset: (_showScrollFab && !keyboardOpen)
                      ? Offset.zero
                      : const Offset(0, 1),
                  child: AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: (_showScrollFab && !keyboardOpen) ? 1.0 : 0.0,
                    child: GestureDetector(
                      onTap: _scrollToBottom,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorScheme.cardBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.cardBorder),
                          // Elevation level 2 — subtle lift for scroll-to-bottom FAB
                          boxShadow: AppDecorations.elevation(2),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: colorScheme.text,
                          size: AppLayout.iconStandard,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Enhanced date separator: pill-style with horizontal hairline rules.
  /// Replaces the previous plain centered text separators.
  Widget _buildDateSeparator(DateTime date, AppColorScheme colorScheme) {
    final text = _formatSeparatorDate(date);
    return Semantics(
      label: 'Messages from $text',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.spacingSection),
        child: Row(
          children: [
            Expanded(
              child: Divider(color: colorScheme.cardBorder, thickness: 0.5),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.spacingStandard,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.p12,
                  vertical: AppDimens.p4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.inputBackground,
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                ),
                child: Text(
                  text,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.textTertiary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Divider(color: colorScheme.cardBorder, thickness: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Rich empty state when no messages exist in the conversation.
  Widget _buildEmptyState(AppColorScheme colorScheme) {
    return Semantics(
      label: 'No messages yet. Start the conversation.',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_outlined,
              size: AppLayout.iconFeature,
              color: colorScheme.textSecondary,
            ),
            const SizedBox(height: AppLayout.spacingSection),
            Text(
              'Start the conversation',
              style: AppTypography.h5.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppLayout.spacingStandard),
            if (widget.conversation.taskTitle != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.spacingLarge,
                ),
                child: Text(
                  'Say hello about "${widget.conversation.taskTitle}"',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colorScheme) {
    return Column(
      children: [
        ClipRect(
          child: AppCardContainer(
            borderRadius: BorderRadius.zero,
            padding: EdgeInsets.fromLTRB(
              AppDimens.p8,
              MediaQuery.of(context).padding.top + AppDimens.p8,
              AppLayout.spacingSection,
              AppDimens.p12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button and name
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Go back',
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: colorScheme.text,
                          size: AppLayout.iconStandard,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
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

                // Offer button + more menu
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Create custom offer',
                      child: GestureDetector(
                        onTap: () {
                          AppInteractionStates.hapticTap();
                          _showCreateOfferModal();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.p12,
                            vertical: AppDimens.p6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(AppDimens.r20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_money,
                                color: Colors.white,
                                size: AppDimens.iconSizeSmall,
                              ),
                              const SizedBox(width: AppLayout.spacingTight),
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
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: colorScheme.text),
                      onSelected: (value) {
                        if (value == 'report_chat') {
                          _reportConversation(context);
                        } else if (value == 'report_user') {
                          _reportUser(context);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'report_chat',
                          child: Text('Report Conversation'),
                        ),
                        PopupMenuItem(
                          value: 'report_user',
                          child: Text('Report User'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Typing indicator
        Consumer<ChatViewModel>(
          builder: (context, vm, _) {
            if (!vm.otherUserTyping) return const SizedBox.shrink();
            return Semantics(
              label: '${widget.conversation.otherUserName ?? "User"} is typing',
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppLayout.spacingSection,
                  bottom: AppLayout.spacingTight,
                ),
                child: Text(
                  'Typing...',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            );
          },
        ),
        // Task/booking context banner
        ChatContextWidget(conversation: widget.conversation),
      ],
    );
  }

  Widget _buildInputArea(BuildContext context, AppColorScheme colorScheme) {
    return AppCardContainer(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.r24),
      ),
      padding: EdgeInsets.fromLTRB(
        AppLayout.spacingSection,
        AppDimens.p12,
        AppLayout.spacingSection,
        MediaQuery.of(context).padding.bottom + AppDimens.p12,
      ),
      child: Row(
        children: [
          // Attachment button
          Semantics(
            button: true,
            label: 'Attach image',
            child: GestureDetector(
              onTap: _onPickImage,
              child: SizedBox(
                width: AppLayout.circleButtonVisualSize,
                height: AppLayout.circleButtonVisualSize,
                child: Icon(
                  Icons.attach_file,
                  color: colorScheme.primary,
                  size: AppDimens.p22,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppLayout.spacingStandard),

          // Text input
          Expanded(
            child: Container(
              height:
                  AppLayout.buttonHeightCompact, // 48px standard input height
              decoration: BoxDecoration(
                color: colorScheme.inputBackground,
                borderRadius: BorderRadius.circular(AppDimens.r23),
                border: Border.all(color: colorScheme.inputBorder),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.spacingSection,
              ),
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
                onChanged: (value) {
                  _chatCtrl.setTyping(value.trim().isNotEmpty);
                },
              ),
            ),
          ),
          const SizedBox(width: AppLayout.spacingStandard),

          // Send button — opacity animation based on text presence
          Consumer<ChatViewModel>(
            builder: (context, vm, _) {
              final sending = vm.isSending;
              return Semantics(
                button: true,
                label: 'Send message',
                child: GestureDetector(
                  onTap: sending
                      ? null
                      : () async {
                          final text = _messageController.text.trim();
                          if (text.isEmpty) return;
                          AppInteractionStates.hapticTap();
                          try {
                            await _chatCtrl.sendMessage(text);
                            if (context.mounted) _messageController.clear();
                          } on Exception catch (_) {
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
                  child: AnimatedOpacity(
                    // Fade 0.5→1.0 when text is entered, disabled when sending
                    duration: AppMotion.fast,
                    opacity: sending ? 0.5 : (_hasText ? 1.0 : 0.5),
                    child: Container(
                      key: ChatScreen.sendButtonKey,
                      width: AppLayout.buttonHeightCompact,
                      height: AppLayout.buttonHeightCompact,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: sending
                          ? const Center(
                              child: SizedBox(
                                width: AppInteractionStates.loadingSize,
                                height: AppInteractionStates.loadingSize,
                                child: CircularProgressIndicator(
                                  strokeWidth:
                                      AppInteractionStates.loadingStrokeWidth,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: AppLayout.iconStandard,
                            ),
                    ),
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
    } on Exception catch (e) {
      AppLogger.e('Accept offer failed', error: e, tag: 'Chat');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not accept offer. Please try again.'),
        ),
      );
    }
  }

  OfferStatus _parseOfferStatus(String? status) {
    if (status == null) return OfferStatus.pending;
    switch (status) {
      case 'accepted':
      case 'accepted_unpaid':
      case 'active':
      case 'active_held':
      case 'delivered':
      case 'delivered_held':
      case 'completed':
      case 'completed_released':
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

  Future<void> _reportConversation(BuildContext context) async {
    final reason = await _showReasonDialog(
      context,
      title: 'Report Conversation',
    );
    if (!context.mounted || reason == null) return;
    final vm = context.read<SafetyViewModel>();
    final ok = await vm.submitReport(
      entityType: 'chat',
      entityId: widget.conversation.id,
      reason: reason,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Report submitted.' : (vm.error ?? 'Report failed.'),
        ),
      ),
    );
  }

  Future<void> _reportUser(BuildContext context) async {
    final me = context.read<ChatViewModel>().currentUserId;
    if (me == null) return;
    final targetUserId = widget.conversation.user1Id == me
        ? widget.conversation.user2Id
        : widget.conversation.user1Id;
    final reason = await _showReasonDialog(context, title: 'Report User');
    if (!context.mounted || reason == null) return;
    final vm = context.read<SafetyViewModel>();
    final ok = await vm.submitReport(
      entityType: 'user',
      entityId: targetUserId,
      reason: reason,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Report submitted.' : (vm.error ?? 'Report failed.'),
        ),
      ),
    );
  }

  Future<String?> _showReasonDialog(
    BuildContext context, {
    required String title,
  }) async {
    var draftReason = '';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          maxLines: 4,
          onChanged: (value) => draftReason = value,
          decoration: const InputDecoration(
            hintText: 'Describe the issue',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, draftReason.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return null;
    return result;
  }
}
