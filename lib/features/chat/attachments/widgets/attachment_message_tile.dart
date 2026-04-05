import 'package:flutter/material.dart';
import 'package:sline_app/core/config/storage_config.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/core/utils/signed_url_cache.dart';
import 'package:sline_app/features/chat/attachments/services/upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef AttachmentSignedUrlResolver =
    Future<String> Function(String storagePath);

/// Renders an image attachment bubble and resolves a signed URL for private files.
///
/// This widget now uses [SignedUrlCache] to prevent redundant API calls
/// when scrolling through chat history. It also handles error states
/// gracefully and caches errors to prevent retry storms.
class AttachmentMessageTile extends StatefulWidget {
  final bool isMine;
  final String storagePath; // e.g. chat-attachments/convos/<id>/file.jpg
  final String time; // already formatted
  final String? caption; // optional caption; null to hide
  final AttachmentSignedUrlResolver? signedUrlResolver;

  const AttachmentMessageTile({
    super.key,
    required this.isMine,
    required this.storagePath,
    required this.time,
    this.caption,
    this.signedUrlResolver,
  });

  @override
  State<AttachmentMessageTile> createState() => _AttachmentMessageTileState();
}

class _AttachmentMessageTileState extends State<AttachmentMessageTile> {
  String? _resolvedUrl;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  @override
  void didUpdateWidget(covariant AttachmentMessageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-load if storage path changed
    if (oldWidget.storagePath != widget.storagePath) {
      _loading = true;
      _error = null;
      _resolvedUrl = null;
      _loadSignedUrl();
    }
  }

  /// Loads the signed URL with caching
  ///
  /// Checks error cache first, then success cache, then calls API
  Future<void> _loadSignedUrl() async {
    // Check error cache first to prevent retry storms
    if (SignedUrlCache.hasError(widget.storagePath)) {
      if (mounted) {
        setState(() {
          _error = 'Access denied';
          _loading = false;
        });
      }
      return;
    }

    // Check success cache
    final cached = SignedUrlCache.get(widget.storagePath);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _resolvedUrl = cached;
          _loading = false;
        });
      }
      return;
    }

    // Generate new signed URL
    try {
      final url =
          await (widget.signedUrlResolver?.call(widget.storagePath) ??
              SupabaseAttachmentUploader().createSignedUrl(
                widget.storagePath,
                expiresInSeconds: SharedStorageConfig.chatAttachmentTtlSeconds,
              ));

      // Cache the successful URL
      SignedUrlCache.set(widget.storagePath, url);

      if (mounted) {
        setState(() {
          _resolvedUrl = url;
          _loading = false;
        });
      }
    } on Exception catch (e) {
      // Cache only auth/permission failures so transient errors (network, timeout) can retry
      final isAuthFailure =
          e is StorageException &&
          (e.statusCode == '403' ||
              e.statusCode == '401' ||
              e.message.toLowerCase().contains('permission') ||
              e.message.toLowerCase().contains('policy'));
      if (isAuthFailure) {
        SignedUrlCache.setError(widget.storagePath);
      }

      // Map error to user-friendly message
      final errorMessage = ErrorMapper.map(e);

      if (mounted) {
        setState(() {
          _error = errorMessage;
          _loading = false;
        });
      }
    }
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
              crossAxisAlignment: widget.isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImageSection(),
                if (widget.caption != null && widget.caption!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(widget.caption!, style: TextStyle(color: fg)),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: widget.isMine
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Text(
                        widget.time,
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.isMine
                              ? Colors.white70
                              : Colors.black54,
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

  Widget _buildImageSection() {
    // Loading state
    if (_loading) {
      return _placeholder(height: 180);
    }

    // Error state
    if (_error != null || _resolvedUrl == null || _resolvedUrl!.isEmpty) {
      return _errorBox(_error ?? 'Failed to load image');
    }

    // Success state - display image
    return GestureDetector(
      onTap: () => _showFullScreen(context, _resolvedUrl!),
      child: Image.network(
        _resolvedUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (c, child, progress) =>
            progress == null ? child : _placeholder(height: 180),
        errorBuilder: (c, e, st) => _errorBox('Image error'),
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
