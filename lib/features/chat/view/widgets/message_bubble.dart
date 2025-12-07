import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

/// WhatsApp-like message bubble updated for Glassmorphism design.
class MessageBubble extends StatelessWidget {
  final String text;
  final String time; // already formatted
  final bool isMine;
  /// Optional status: 'sent' | 'delivered' | 'read'
  final String? status;

  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMine,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    final bg = isMine
        ? AppColors.teal
        : colorScheme.cardBackground; // or inputBackground
    
    final fg = isMine ? AppColors.offWhite : colorScheme.text;
    final metaColor = isMine ? AppColors.offWhite.withValues(alpha: 0.7) : colorScheme.textSecondary;

    final radius = BorderRadius.only(
      topLeft: Radius.circular(isMine ? AppDimens.r18 : AppDimens.r4),
      topRight: Radius.circular(isMine ? AppDimens.r4 : AppDimens.r18),
      bottomLeft: const Radius.circular(AppDimens.r18),
      bottomRight: const Radius.circular(AppDimens.r18),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            // Add subtle border for 'other' messages to stand out against glass bg if needed
            border: isMine ? null : Border.all(color: colorScheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: AppTypography.bodyMedium.copyWith(color: fg),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: AppTypography.micro.copyWith(color: metaColor),
                  ),
                  if (isMine && status != null) ...[
                    const SizedBox(width: 6),
                    _statusIcon(status!, isMine, metaColor),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _statusIcon(String status, bool isMine, Color color) {
    switch (status) {
      case 'read':
        return const Icon(Icons.done_all, size: 16, color: Colors.blue); // Keep blue for read
      case 'delivered':
        return Icon(Icons.done_all, size: 16, color: color);
      case 'sent':
      default:
        return Icon(Icons.check, size: 16, color: color);
    }
  }
}
