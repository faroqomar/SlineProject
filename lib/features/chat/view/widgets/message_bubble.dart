import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

/// Chat message bubble with grouping support, animated status icons, and
/// full Semantics coverage.
///
/// Phase 5 redesign: added [isFirstInGroup] / [isLastInGroup] params for
/// message grouping (reduces spacing and adjusts corner radius for consecutive
/// messages from the same sender within a 2-minute window). Replaced all
/// hardcoded colors with semantic tokens. Added animated status icon
/// transitions and accessibility labels. View-layer only.
///
/// Grouping affects:
/// - **Spacing:** Tight 2px gap between grouped messages vs standard margin.
/// - **Corner radius:** Inner corner (facing adjacent same-sender bubble) is
///   reduced to r4 for visual continuity.
/// - **Timestamp:** Only shown on the last message in a group.
class MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMine;

  /// Optional status: 'sent' | 'delivered' | 'read'.
  final String? status;

  /// True if this is the first message in a consecutive same-sender group.
  /// Defaults to true (standalone message = first AND last in group).
  final bool isFirstInGroup;

  /// True if this is the last message in a consecutive same-sender group.
  /// When false, the timestamp is hidden to reduce visual noise.
  final bool isLastInGroup;

  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMine,
    this.status,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    final bg = isMine ? colorScheme.primary : colorScheme.cardBackground;
    final fg = isMine ? Colors.white : colorScheme.text;
    final metaColor = isMine
        ? Colors.white.withValues(alpha: 0.7)
        : colorScheme.textSecondary;

    // Corner radius: inner corner towards adjacent grouped bubble is smaller.
    // Outer corners stay large for visual distinction.
    final radius = _buildBorderRadius();

    // Asymmetric vertical margins: larger gap at the start/end of a group to
    // visually cluster consecutive same-sender messages together.

    return Semantics(
      // TODO(l10n): "You" and "Other" should be localized when flutter_gen_l10n
      // is added to the project. For now, English strings are acceptable.
      label:
          '${isMine ? "You" : "Other"} said: $text, '
          'sent at $time'
          '${status != null ? ", status: $status" : ""}',
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          // 75% max width — intentional ratio for readable chat bubbles
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Container(
            margin: EdgeInsets.only(
              top: isFirstInGroup ? AppLayout.spacingTight : 2.0,
              bottom: isLastInGroup ? AppLayout.spacingTight : 0.0,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p14,
              vertical: AppDimens.p10,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: isMine ? null : Border.all(color: colorScheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text, style: AppTypography.bodyMedium.copyWith(color: fg)),
                // Only show timestamp on last message in group
                if (isLastInGroup) ...[
                  const SizedBox(height: AppLayout.spacingTight),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: isMine
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: AppTypography.micro.copyWith(color: metaColor),
                      ),
                      if (isMine && status != null) ...[
                        const SizedBox(width: 6),
                        // Animated status icon: cross-fades between states
                        AnimatedSwitcher(
                          duration: AppMotion.fast,
                          child: _statusIcon(status!, metaColor, colorScheme),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build border radius based on grouping position.
  /// Inner corner (side facing same-sender adjacent bubble) uses r4,
  /// outer corners use r18. Solo messages use r18 everywhere except the
  /// traditional "tail" corner (r4).
  BorderRadius _buildBorderRadius() {
    if (isMine) {
      return BorderRadius.only(
        topLeft: const Radius.circular(AppDimens.r18),
        // Top-right: r4 if first in group (tail), r12 if middle/last
        topRight: Radius.circular(
          isFirstInGroup ? AppDimens.r4 : AppDimens.r12,
        ),
        bottomLeft: const Radius.circular(AppDimens.r18),
        // Bottom-right: r4 if not last (connects to next), r18 if last
        bottomRight: Radius.circular(
          isLastInGroup ? AppDimens.r18 : AppDimens.r4,
        ),
      );
    } else {
      return BorderRadius.only(
        // Top-left: r4 if first (tail), r12 if middle/last
        topLeft: Radius.circular(isFirstInGroup ? AppDimens.r4 : AppDimens.r12),
        topRight: const Radius.circular(AppDimens.r18),
        // Bottom-left: r4 if not last (connects to next), r18 if last
        bottomLeft: Radius.circular(
          isLastInGroup ? AppDimens.r18 : AppDimens.r4,
        ),
        bottomRight: const Radius.circular(AppDimens.r18),
      );
    }
  }

  /// Status icon with animated transitions between send states.
  /// Uses [ValueKey] so [AnimatedSwitcher] detects the change.
  static Widget _statusIcon(
    String status,
    Color defaultColor,
    AppColorScheme colorScheme,
  ) {
    switch (status) {
      case 'read':
        return Icon(
          Icons.done_all,
          key: const ValueKey('status_read'),
          size: AppDimens.iconSizeSmall,
          color: colorScheme.info, // semantic token instead of hardcoded blue
        );
      case 'delivered':
        return Icon(
          Icons.done_all,
          key: const ValueKey('status_delivered'),
          size: AppDimens.iconSizeSmall,
          color: defaultColor,
        );
      case 'sent':
      default:
        return Icon(
          Icons.check,
          key: const ValueKey('status_sent'),
          size: AppDimens.iconSizeSmall,
          color: defaultColor,
        );
    }
  }
}
