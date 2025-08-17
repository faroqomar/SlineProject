import 'package:flutter/material.dart';
import '../services/upload_service.dart';

/// Renders an image attachment bubble and resolves a signed URL for private files.
class AttachmentMessageTile extends StatefulWidget {
  final bool isMine;
  final String storagePath; // e.g. chat-attachments/convos/<id>/file.jpg
  final String time; // already formatted
  final String? caption; // optional caption; null to hide

  const AttachmentMessageTile({
    super.key,
    required this.isMine,
    required this.storagePath,
    required this.time,
    this.caption,
  });

  @override
  State<AttachmentMessageTile> createState() => _AttachmentMessageTileState();
}

class _AttachmentMessageTileState extends State<AttachmentMessageTile> {
  late final Future<String> _signedUrlFuture;

  @override
  void initState() {
    super.initState();
    _signedUrlFuture = SupabaseAttachmentUploader()
        .createSignedUrl(widget.storagePath, expiresInSeconds: 3600);
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isMine
        ? Theme.of(context).primaryColor.withValues(alpha: 0.85)
        : Colors.grey.shade300;
    final fg = widget.isMine ? Colors.white : Colors.black87;

    final radius = BorderRadius.only(
      topLeft: Radius.circular(widget.isMine ? 16 : 4),
      topRight: Radius.circular(widget.isMine ? 4 : 16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );

    return Align(
      alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          minWidth: 120,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: ClipRRect(
            borderRadius: radius,
            child: Column(
              crossAxisAlignment:
                  widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<String>(
                  future: _signedUrlFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return _placeholder(height: 180);
                    }
                    if (!snap.hasData || snap.data!.isEmpty) {
                      return _errorBox('Failed to load image');
                    }
                    return GestureDetector(
                      onTap: () => _showFullScreen(context, snap.data!),
                      child: Image.network(
                        snap.data!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (c, child, progress) =>
                            progress == null ? child : _placeholder(height: 180),
                        errorBuilder: (c, e, st) => _errorBox('Image error'),
                      ),
                    );
                  },
                ),
                if (widget.caption != null && widget.caption!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(widget.caption!, style: TextStyle(color: fg)),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment:
                        widget.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Text(
                        widget.time,
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.isMine ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder({required double height}) => Container(
        height: height,
        width: double.infinity,
        color: Colors.black12,
        alignment: Alignment.center,
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _errorBox(String msg) => Container(
        height: 180,
        color: Colors.black12,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Text(
          msg,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      );

  void _showFullScreen(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(8),
          backgroundColor: Colors.black,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }
}