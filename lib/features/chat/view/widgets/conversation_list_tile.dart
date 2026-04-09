import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart' as date_utils;
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';

/// Conversation list tile with animated typing dots, spring unread badge,
/// and full Semantics coverage.
///
/// Phase 5 redesign: replaced all hardcoded colors with semantic tokens,
/// added animated typing indicator (3-dot pulse), enhanced unread badge
/// with spring entrance, and added accessibility labels. View-layer only.
class ConversationListTile extends StatefulWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationListTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  State<ConversationListTile> createState() => _ConversationListTileState();
}

class _ConversationListTileState extends State<ConversationListTile>
    with TickerProviderStateMixin {
  // ── Typing dots animation ──────────────────────────────────
  // Three dots pulse sequentially: opacity 0.3→1.0 each, staggered.
  late final AnimationController _typingController;

  // ── Unread badge entrance ──────────────────────────────────
  // Scale 0→1 with spring curve on first appearance.
  late final AnimationController _badgeController;
  late final Animation<double> _badgeScale;

  bool _wasPreviouslyUnread = false;

  // Tracks whether a postFrameCallback for animations is already queued,
  // to avoid scheduling redundant callbacks on the same frame.
  bool _animationCallbackPending = false;

  @override
  void initState() {
    super.initState();

    // Typing animation: repeating loop, 600ms per cycle
    // Repeating typing dot pulse animation
    _typingController = AnimationController(
      duration: AppMotion.typingCycle,
      vsync: this,
    );

    // Badge entrance: fast spring scale
    _badgeController = AnimationController(
      duration: AppMotion.fast,
      vsync: this,
    );
    _badgeScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _badgeController, curve: AppMotion.curveSpring),
    );
  }

  @override
  void dispose() {
    _typingController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  /// Updates animation controllers in response to prop changes.
  ///
  /// Called via addPostFrameCallback so controller mutations never happen
  /// inside build(), which would trigger illegal setState-during-build errors.
  void _updateAnimations({required bool isTyping, required bool isUnread}) {
    // Typing dots: repeat while typing, stop+reset when done
    if (isTyping && !_typingController.isAnimating) {
      _typingController.repeat();
    } else if (!isTyping && _typingController.isAnimating) {
      _typingController
        ..stop()
        ..reset();
    }

    // Badge entrance: forward on first appearance, reverse on dismissal
    if (isUnread && !_wasPreviouslyUnread) {
      _badgeController.forward(from: 0);
    } else if (!isUnread && _wasPreviouslyUnread) {
      _badgeController.reverse();
    }
    _wasPreviouslyUnread = isUnread;
    _animationCallbackPending = false;
  }

  bool _isUnread(String? myUserId) {
    if (myUserId == null) return false;
    final isFromOther =
        widget.conversation.lastMessageSenderId != null &&
        widget.conversation.lastMessageSenderId != myUserId;
    if (!isFromOther) return false;
    return widget.conversation.lastMessageSeenAt == null;
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

    final isActiveConvo = vm.activeConversation?.id == widget.conversation.id;
    final isTyping = isActiveConvo
        ? vm.otherUserTyping
        : _isTypingWithin15s(
            widget.conversation.presenceUpdatedAt,
            widget.conversation.otherUserTyping,
          );

    // Schedule animation updates after the frame completes to avoid
    // mutating controllers inside build() — same pattern as notification_badge_button.
    if (!_animationCallbackPending) {
      _animationCallbackPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateAnimations(isTyping: isTyping, isUnread: isUnread);
      });
    }

    final previewText = widget.conversation.lastMessage ?? 'No messages yet';
    final userName = widget.conversation.otherUserName ?? 'User';
    final timeText = widget.conversation.lastMessageTime != null
        ? date_utils.formatFriendlyTime(widget.conversation.lastMessageTime!)
        : '';

    return Semantics(
      label:
          '$userName, $previewText, $timeText'
          '${isUnread ? ", unread" : ""}'
          '${isTyping ? ", typing" : ""}',
      button: true,
      child: GestureDetector(
        onTap: () {
          AppInteractionStates.hapticTap();
          widget.onTap();
        },
        child: AnimatedContainer(
          // Use AppMotion.fast token — same 200ms value but from design system
          duration: AppMotion.fast,
          margin: const EdgeInsets.only(bottom: AppDimens.p12),
          padding: const EdgeInsets.all(AppLayout.cardPadding),
          decoration: BoxDecoration(
            color: isUnread
                ? colorScheme.primary.withValues(alpha: 0.05)
                : colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(AppDimens.r18),
            border: Border.all(
              color: isUnread
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : colorScheme.cardBorder,
              width: isUnread ? 1.5 : AppLayout.cardBorderWidth,
            ),
          ),
          child: Row(
            children: [
              // Avatar with online/typing indicator
              _buildAvatar(colorScheme, isTyping),
              const SizedBox(width: AppDimens.p12),

              // Content column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Context row (Task/Booking title banner)
                    if (widget.conversation.taskTitle != null) ...[
                      Row(
                        children: [
                          Icon(
                            widget.conversation.taskType == 'booking'
                                ? Icons.calendar_today
                                : Icons.assignment_outlined,
                            size: AppLayout.iconTiny,
                            color: widget.conversation.taskType == 'booking'
                                ? colorScheme.warning
                                : colorScheme.primary,
                          ),
                          const SizedBox(width: AppLayout.spacingTight),
                          Expanded(
                            child: Text(
                              widget.conversation.taskTitle!.toUpperCase(),
                              style: AppTypography.micro.copyWith(
                                color: widget.conversation.taskType == 'booking'
                                    ? colorScheme.warning
                                    : colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                // 9px — below AppTypography.micro (10px) for compact tag label
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppLayout.spacingTight),
                    ],

                    // Name + timestamp row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeText.isNotEmpty)
                          Text(
                            timeText,
                            style: AppTypography.micro.copyWith(
                              color: colorScheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppLayout.spacingTight),

                    // Last message preview OR typing indicator
                    if (isTyping)
                      _buildTypingDots(colorScheme)
                    else
                      Text(
                        previewText,
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

              // Unread indicator — always in tree so reverse animation plays.
              // ScaleTransition renders as invisible when scale is 0.
              const SizedBox(width: AppLayout.spacingStandard),
              ScaleTransition(
                scale: _badgeScale,
                child: Container(
                  // AppDimens.p10 = 10px — minimum visible dot for accessibility
                  width: AppDimens.p10,
                  height: AppDimens.p10,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Animated typing dots — three dots that pulse sequentially.
  /// Each dot fades between 0.3 and 1.0 opacity with 100ms stagger offset.
  Widget _buildTypingDots(AppColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot by 0.15 of the cycle
            final offset = i * 0.15;
            final progress = (_typingController.value + offset) % 1.0;
            // Sine wave for smooth pulse: range 0.3 → 1.0
            final opacity = 0.3 + 0.7 * ((1 + _sinFromProgress(progress)) / 2);
            return Padding(
              padding: EdgeInsets.only(
                right: i < 2 ? AppLayout.spacingTight : 0,
              ),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  // AppDimens.p6 = 6px — compact typing dot size
                  width: AppDimens.p6,
                  height: AppDimens.p6,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Convert a 0..1 progress value to a sine wave value (-1..1).
  /// Uses dart:math for accuracy — no Taylor-series approximation needed.
  static double _sinFromProgress(double progress) {
    return math.sin(2 * math.pi * progress);
  }

  /// Avatar with online/typing indicator dot.
  Widget _buildAvatar(AppColorScheme colorScheme, bool isOnline) {
    final initials = _getInitials(widget.conversation.otherUserName);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: AppLayout.minTouchTarget,
          height: AppLayout.minTouchTarget,
          decoration: BoxDecoration(
            color: colorScheme.warning,
            borderRadius: BorderRadius.circular(AppDimens.r14),
            border: Border.all(color: colorScheme.cardBorder, width: 2),
          ),
          child: widget.conversation.otherUserAvatar != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                  child: SignedAvatar(
                    storagePathOrUrl: widget.conversation.otherUserAvatar,
                    radius: 22,
                  ),
                )
              : Center(
                  child: Text(
                    initials,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.text,
                    ),
                  ),
                ),
        ),

        // Online/typing indicator dot
        if (isOnline)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: colorScheme.success,
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
