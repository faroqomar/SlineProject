import 'package:flutter/material.dart';

/// WhatsApp-like message bubble.
/// Shows text, time, and optional tick status icon.
/// Keeps max width to ~70% of screen.
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
    // Use withValues to avoid precision loss warnings in newer Flutter versions.
    final bg = isMine
        ? Theme.of(context).primaryColor.withValues(alpha: 0.85)
        : Colors.grey.shade300;
    final fg = isMine ? Colors.white : Colors.black87;

    final radius = BorderRadius.only(
      topLeft: Radius.circular(isMine ? 16 : 4),
      topRight: Radius.circular(isMine ? 4 : 16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(color: fg, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  if (isMine && status != null) ...[
                    const SizedBox(width: 6),
                    _statusIcon(status!, isMine),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Map status strings to WhatsApp-like icons
  /// Why: UX parity — single check = sent, double grey = delivered, double blue = read.
  static Widget _statusIcon(String status, bool isMine) {
    final neutral = isMine ? Colors.white70 : Colors.black54;
    switch (status) {
      case 'read':
        return Icon(Icons.done_all, size: 16, color: Colors.blue);
      case 'delivered':
        return Icon(Icons.done_all, size: 16, color: neutral);
      case 'sent':
      default:
        return Icon(Icons.check, size: 16, color: neutral);
    }
  }
}
