import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';

/// Conversation list tile with elevated card design, animated unread badge,
/// online status dot, relative time formatting, and full Semantics coverage.
///
/// Phase 6 redesign: Elevated card with resting shadow, prominent primary
/// accent bar on left edge for unread state, circular avatar with gradient
/// fallback, "You:" prefix on sent messages, and inline unread dot next to
/// the time. The tile animates between read/unread states smoothly using
/// AnimatedContainer with AppMotion tokens.
///
/// TODO(typing-indicator): Typing dots animation was disabled because the
/// backend/ViewModel integration for `otherUserTyping` is unreliable — it
/// fires false positives and the sine-wave dot pulse glitches visually.
/// Re-enable once the Realtime presence channel is stabilized. The previous
/// implementation used a repeating AnimationController with staggered sine
/// opacity on 3 dots. See git history for the removed `_buildTypingDots`.
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
    with SingleTickerProviderStateMixin {
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

    // Badge entrance: fast spring scale for a lively pop-in
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
    _badgeController.dispose();
    super.dispose();
  }

  /// Updates animation controllers in response to prop changes.
  ///
  /// Called via addPostFrameCallback so controller mutations never happen
  /// inside build(), which would trigger illegal setState-during-build errors.
  void _updateAnimations({required bool isUnread}) {
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

  /// Whether the other user is "online" — heuristic based on presenceUpdatedAt
  /// being within 60 seconds. Only meaningful when presence feature flag is on.
  // Online dot gated behind chat_presence_receipts_enabled feature flag.
  // presenceUpdatedAt within 60s = heuristic for "online".
  // TODO: Wire to explicit isOnline field when backend provides it.
  static bool _isOnlineWithin60s(DateTime? presenceUpdatedAt) {
    if (presenceUpdatedAt == null) return false;
    return DateTime.now().difference(presenceUpdatedAt).inSeconds <= 60;
  }

  /// Compact relative time formatter for conversation list tiles.
  ///
  /// Returns: "Just now" (<60s), "2m" (minutes), "1h" (hours),
  /// "Yesterday", weekday name (within 7 days), or "MMM d" (older).
  /// Future timestamps (clock skew) are treated as "Just now".
  static String _formatRelativeTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    // Future timestamps (clock skew edge case) — treat as "Just now"
    if (diff.isNegative) return 'Just now';

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';

    // Calendar-day checks for Yesterday and weekday names
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);
    final dayDiff = today.difference(messageDay).inDays;

    if (dayDiff == 1) return 'Yesterday';
    // Within 7 days — show abbreviated weekday name (Mon, Tue, etc.)
    if (dayDiff < 7) return DateFormat.E().format(time);
    // Older — show abbreviated month + day (Mar 15)
    return DateFormat.MMMd().format(time);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final vm = context.read<ChatViewModel>();
    final myId = vm.currentUserId;
    final isUnread = _isUnread(myId);

    // Schedule animation updates after the frame completes to avoid
    // mutating controllers inside build() — same pattern as notification_badge_button.
    if (!_animationCallbackPending) {
      _animationCallbackPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateAnimations(isUnread: isUnread);
      });
    }

    // Gate online dot behind presence feature flag.
    // Both conditions must be true: flag enabled AND presence within 60s.
    final isPresenceEnabled = context
        .watch<ChatViewModel>()
        .isPresenceReceiptsEnabled;
    final isOnline =
        isPresenceEnabled &&
        _isOnlineWithin60s(widget.conversation.presenceUpdatedAt);

    final previewText = widget.conversation.lastMessage ?? 'No messages yet';
    final userName = widget.conversation.otherUserName ?? 'User';
    final timeText = _formatRelativeTime(widget.conversation.lastMessageTime);

    // Whether the current user sent the last message — used to prefix preview.
    final isMySend = widget.conversation.lastMessageSenderId == myId;

    return Semantics(
      label:
          '$userName, $previewText, $timeText'
          '${isUnread ? ", unread" : ""}'
          '${isOnline ? ", online" : ""}',
      button: true,
      child: GestureDetector(
        onTap: () {
          AppInteractionStates.hapticTap();
          widget.onTap();
        },
        child: AnimatedContainer(
          // AppMotion.fast (200ms) for smooth theme/unread state transitions
          duration: AppMotion.fast,
          margin: const EdgeInsets.only(bottom: AppDimens.p10),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(AppDimens.r16),
            border: Border.all(
              color: isUnread
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.cardBorder,
              width: isUnread ? 1.5 : AppLayout.cardBorderWidth,
            ),
            // Level 1 resting shadow for depth — cards float above background
            boxShadow: AppDecorations.elevation(1, isDark: colorScheme.isDark),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.r16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // ── Left accent bar — visible only when unread ──
                  // A 3px primary-color bar on the leading edge draws the eye
                  // to unread conversations instantly.
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    width: isUnread ? 3.5 : 0,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDimens.r16),
                        bottomLeft: Radius.circular(AppDimens.r16),
                      ),
                    ),
                  ),

                  // ── Tile content ──
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.p12,
                        AppDimens.p12,
                        AppDimens.p14,
                        AppDimens.p12,
                      ),
                      child: Row(
                        children: [
                          // ── Avatar with online status dot ──
                          _buildAvatar(colorScheme, isOnline),
                          const SizedBox(width: AppDimens.p12),

                          // ── Content column ──
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Name + time + unread dot row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        userName,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              fontWeight: isUnread
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: colorScheme.text,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: AppDimens.p6),
                                    // Unread dot before time — small but high contrast
                                    if (isUnread)
                                      ScaleTransition(
                                        scale: _badgeScale,
                                        child: Container(
                                          width: 7,
                                          height: 7,
                                          margin: const EdgeInsets.only(
                                            right: AppDimens.p4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    if (timeText.isNotEmpty)
                                      Text(
                                        timeText,
                                        style: AppTypography.micro.copyWith(
                                          color: isUnread
                                              ? colorScheme.primary
                                              : colorScheme.textTertiary,
                                          fontWeight: isUnread
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),

                                // Task/Booking context tag
                                if (widget.conversation.taskTitle != null) ...[
                                  const SizedBox(height: AppDimens.p2),
                                  _buildContextTag(colorScheme),
                                ],

                                const SizedBox(height: AppDimens.p4),

                                // Last message preview
                                Text(
                                  isMySend ? 'You: $previewText' : previewText,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isUnread
                                        ? colorScheme.text
                                        : colorScheme.textSecondary,
                                    fontWeight: isUnread
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
      ),
    );
  }

  /// Compact context tag showing the task or booking title inline.
  ///
  /// Uses a tiny icon + uppercase text for quick visual scanning. The color
  /// differentiates booking (warning/amber) from task (primary/blue).
  Widget _buildContextTag(AppColorScheme colorScheme) {
    final isBooking = widget.conversation.taskType == 'booking';
    final tagColor = isBooking ? colorScheme.warning : colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isBooking ? Icons.calendar_today : Icons.assignment_outlined,
          size: 10,
          color: tagColor,
        ),
        const SizedBox(width: AppDimens.p4),
        Flexible(
          child: Text(
            widget.conversation.taskTitle!.toUpperCase(),
            style: AppTypography.micro.copyWith(
              color: tagColor,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Circular avatar with online indicator dot.
  ///
  /// Uses a circle shape with primary tint fallback for users without a
  /// profile photo. The green online dot appears bottom-right with a
  /// spring-scale entrance for a natural, lively feel.
  Widget _buildAvatar(AppColorScheme colorScheme, bool showDot) {
    final initials = _getInitials(widget.conversation.otherUserName);
    // 50px diameter — slightly larger than minTouchTarget for visual presence
    const double avatarSize = 50;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Circular avatar container
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: widget.conversation.otherUserAvatar != null
              ? ClipOval(
                  child: SignedAvatar(
                    storagePathOrUrl: widget.conversation.otherUserAvatar,
                    radius: avatarSize / 2,
                  ),
                )
              : Center(
                  child: Text(
                    initials,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      fontSize: 18,
                    ),
                  ),
                ),
        ),

        // Online indicator dot — animated entrance with spring scale.
        // 2.5px phoneBackground border creates a "cut-out" ring effect.
        if (showDot)
          Positioned(
            bottom: 0,
            right: 0,
            child: AnimatedScale(
              scale: 1.0,
              duration: AppMotion.fast,
              curve: AppMotion.curveSpring,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: colorScheme.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.cardBackground,
                    width: 2.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Extract initials from a full name for the fallback avatar.
  /// Returns first letter of first + last name, or just the first letter.
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
