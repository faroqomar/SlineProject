import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:url_launcher/url_launcher.dart';

/// Chat message bubble with grouping support, link detection, emoji-only
/// rendering, reply quote, animated status icons, and full Semantics coverage.
///
/// Phase 5 redesign: added [isFirstInGroup] / [isLastInGroup] params for
/// message grouping. Replaced all hardcoded colors with semantic tokens.
///
/// Phase 6: Converted from StatelessWidget to StatefulWidget for
/// TapGestureRecognizer lifecycle management (link detection). Added URL
/// detection with tappable underlined links, emoji-only rendering (1-3 emoji
/// at 2x size without bubble), and optional reply quote display.
/// View-layer only — no ViewModel changes.
class MessageBubble extends StatefulWidget {
  final String text;
  final String time;
  final bool isMine;

  /// Optional status: 'sent' | 'delivered' | 'read'.
  final String? status;

  /// True if this is the first message in a consecutive same-sender group.
  final bool isFirstInGroup;

  /// True if this is the last message in a consecutive same-sender group.
  final bool isLastInGroup;

  /// Optional reply quote — sender name of the replied-to message.
  /// When set (along with [replyToText]), shows a quoted section above the text.
  // TODO: Wire replyToText/replyToSender when Message model has reply_to_message_id.
  // Until then, these params are available for the View-layer reply preview in ChatScreen.
  final String? replyToSender;

  /// Optional reply quote — text content of the replied-to message.
  final String? replyToText;

  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMine,
    this.status,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.replyToSender,
    this.replyToText,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  /// URL detection pattern — matches http:// and https:// URLs.
  static final _urlPattern = RegExp(r'https?://[^\s]+');

  /// Matches 1-3 visual emoji with optional variation selectors and ZWJ sequences.
  /// Uses Extended_Pictographic to exclude digits (#, *, 0-9) that \p{Emoji} includes.
  /// DECISION-1: \p{Extended_Pictographic} chosen over \p{Emoji} to avoid
  /// false positives on digits and symbol characters.
  // Analyzer reports valid_regexps false positive because it doesn't
  // understand \p{Extended_Pictographic} unicode property escapes.
  // Runtime test confirms pattern is valid with unicode: true.
  // ignore: valid_regexps
  static final _emojiOnlyPattern = RegExp(
    r'^\s*(\p{Extended_Pictographic}(\u{FE0F}|\u{200D}|\p{Extended_Pictographic})*\s*){1,3}\s*$',
    unicode: true,
  );

  /// Managed recognizers for link taps — disposed in dispose() and
  /// rebuilt in didUpdateWidget() when text changes to prevent memory leaks.
  List<TapGestureRecognizer> _recognizers = [];

  @override
  void didUpdateWidget(covariant MessageBubble old) {
    super.didUpdateWidget(old);
    // Rebuild recognizers when text content changes to avoid stale callbacks
    if (old.text != widget.text) {
      _disposeRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  /// Disposes all TapGestureRecognizer instances and clears the list.
  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  /// Whether the message text contains any URLs.
  bool get _hasLinks => _urlPattern.hasMatch(widget.text);

  /// Whether the message is emoji-only (1-3 emoji, no other text).
  /// Link messages are never treated as emoji-only (link detection takes priority).
  bool get _isEmojiOnly =>
      !_hasLinks && _emojiOnlyPattern.hasMatch(widget.text);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Emoji-only messages: render at 2x size without bubble background
    if (_isEmojiOnly) {
      return _buildEmojiOnly(colorScheme);
    }

    final bg = widget.isMine ? colorScheme.primary : colorScheme.cardBackground;
    final fg = widget.isMine ? Colors.white : colorScheme.text;
    final metaColor = widget.isMine
        ? Colors.white.withValues(alpha: 0.7)
        : colorScheme.textSecondary;

    // Corner radius: inner corner towards adjacent grouped bubble is smaller.
    final radius = _buildBorderRadius();

    return Semantics(
      label:
          '${widget.isMine ? "You" : "Other"} said: ${widget.text}, '
          'sent at ${widget.time}'
          '${widget.status != null ? ", status: ${widget.status}" : ""}',
      child: Align(
        alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          // 75% max width — intentional ratio for readable chat bubbles
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Container(
            margin: EdgeInsets.only(
              top: widget.isFirstInGroup ? AppLayout.spacingTight : 2.0,
              bottom: widget.isLastInGroup ? AppLayout.spacingTight : 0.0,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p14,
              vertical: AppDimens.p10,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: widget.isMine
                  ? null
                  : Border.all(color: colorScheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: widget.isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply quote — shown when replyToText is set
                if (widget.replyToText != null) _buildReplyQuote(colorScheme),
                // Message text — RichText with links or plain Text
                if (_hasLinks)
                  _buildRichText(colorScheme, fg)
                else
                  Text(
                    widget.text,
                    style: AppTypography.bodyMedium.copyWith(color: fg),
                  ),
                // Timestamp — only shown on last message in group
                if (widget.isLastInGroup) ...[
                  const SizedBox(height: AppLayout.spacingTight),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: widget.isMine
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Text(
                        widget.time,
                        style: AppTypography.micro.copyWith(color: metaColor),
                      ),
                      if (widget.isMine && widget.status != null) ...[
                        const SizedBox(width: 6),
                        AnimatedSwitcher(
                          duration: AppMotion.fast,
                          child: _statusIcon(
                            widget.status!,
                            metaColor,
                            colorScheme,
                          ),
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

  /// Emoji-only rendering: 1-3 emoji at 2x font size without bubble background.
  /// Keeps alignment and timestamp consistent with regular messages.
  Widget _buildEmojiOnly(AppColorScheme colorScheme) {
    final metaColor = widget.isMine
        ? colorScheme.textSecondary
        : colorScheme.textSecondary;

    return Semantics(
      label:
          '${widget.isMine ? "You" : "Other"} sent emoji: ${widget.text}, '
          'sent at ${widget.time}',
      child: Align(
        alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(
            top: widget.isFirstInGroup ? AppLayout.spacingTight : 2.0,
            bottom: widget.isLastInGroup ? AppLayout.spacingTight : 0.0,
          ),
          child: Column(
            crossAxisAlignment: widget.isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji at approximately 2x body text size (32px)
              Text(
                widget.text.trim(),
                style: const TextStyle(fontSize: 32, height: 1.2),
              ),
              // Timestamp below the emoji
              if (widget.isLastInGroup) ...[
                const SizedBox(height: AppLayout.spacingTight),
                Text(
                  widget.time,
                  style: AppTypography.micro.copyWith(color: metaColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds RichText with tappable URL links interspersed with plain text.
  /// Link style: underlined, white for sent (teal bubble), teal for received.
  Widget _buildRichText(AppColorScheme colorScheme, Color textColor) {
    // Dispose any previous recognizers before rebuilding
    _disposeRecognizers();
    _recognizers = [];

    final spans = <InlineSpan>[];
    var lastEnd = 0;

    // Link color: white underline on teal bubble, teal underline on card background
    final linkColor = widget.isMine ? Colors.white : colorScheme.primary;

    for (final match in _urlPattern.allMatches(widget.text)) {
      // Plain text before the URL
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: widget.text.substring(lastEnd, match.start),
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
        );
      }

      // URL text — trim trailing punctuation that regex may capture
      final url = match.group(0)!;
      final trimmed = _trimTrailingPunctuation(url);

      // Create a recognizer for this link and track it for disposal
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          AppLogger.d('MessageBubble: tapped link $trimmed', tag: 'Chat');
          launchUrl(Uri.parse(trimmed), mode: LaunchMode.externalApplication);
        };
      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: trimmed,
          style: AppTypography.bodyMedium.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
            decorationColor: linkColor,
          ),
          recognizer: recognizer,
        ),
      );

      // If we trimmed punctuation, add it back as plain text
      if (trimmed.length < url.length) {
        spans.add(
          TextSpan(
            text: url.substring(trimmed.length),
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
        );
      }

      lastEnd = match.end;
    }

    // Plain text after the last URL
    if (lastEnd < widget.text.length) {
      spans.add(
        TextSpan(
          text: widget.text.substring(lastEnd),
          style: AppTypography.bodyMedium.copyWith(color: textColor),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  /// Trim trailing punctuation from URLs that regex may over-capture.
  /// Handles: `.`, `,`, `)`, `!`, `?`, `;`, `:`
  static String _trimTrailingPunctuation(String url) {
    const trailingChars = {'.', ',', ')', '!', '?', ';', ':'};
    var result = url;
    while (result.isNotEmpty &&
        trailingChars.contains(result[result.length - 1])) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// Reply quote visual — displayed above message text when replyToText is set.
  /// Thin left accent border + sender name + quoted text preview.
  Widget _buildReplyQuote(AppColorScheme colorScheme) {
    // Accent color: white on sent bubble, primary on received
    final accentColor = widget.isMine
        ? Colors.white.withValues(alpha: 0.5)
        : colorScheme.primary.withValues(alpha: 0.5);
    final bgColor = widget.isMine
        ? Colors.white.withValues(alpha: 0.1)
        : colorScheme.primary.withValues(alpha: 0.05);
    final senderColor = widget.isMine
        ? Colors.white.withValues(alpha: 0.9)
        : colorScheme.text;
    final quoteTextColor = widget.isMine
        ? Colors.white.withValues(alpha: 0.7)
        : colorScheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p8),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.p8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimens.r8),
          // 3px left accent border for reply quote
          border: Border(left: BorderSide(color: accentColor, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyToSender != null)
              Text(
                widget.replyToSender!,
                style: AppTypography.captionBold.copyWith(color: senderColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              widget.replyToText!,
              style: AppTypography.caption.copyWith(color: quoteTextColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Build border radius based on grouping position.
  BorderRadius _buildBorderRadius() {
    if (widget.isMine) {
      return BorderRadius.only(
        topLeft: const Radius.circular(AppDimens.r18),
        topRight: Radius.circular(
          widget.isFirstInGroup ? AppDimens.r4 : AppDimens.r12,
        ),
        bottomLeft: const Radius.circular(AppDimens.r18),
        bottomRight: Radius.circular(
          widget.isLastInGroup ? AppDimens.r18 : AppDimens.r4,
        ),
      );
    } else {
      return BorderRadius.only(
        topLeft: Radius.circular(
          widget.isFirstInGroup ? AppDimens.r4 : AppDimens.r12,
        ),
        topRight: const Radius.circular(AppDimens.r18),
        bottomLeft: Radius.circular(
          widget.isLastInGroup ? AppDimens.r18 : AppDimens.r4,
        ),
        bottomRight: const Radius.circular(AppDimens.r18),
      );
    }
  }

  /// Status icon with animated transitions between send states.
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
          color: colorScheme.info,
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
