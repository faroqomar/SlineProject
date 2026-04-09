import 'package:flutter/material.dart';
import 'package:sline_app/core/config/storage_config.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/core/utils/signed_url_cache.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';
import 'package:sline_app/features/chat/attachments/services/upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef AttachmentSignedUrlResolver =
    Future<String> Function(String storagePath);

/// Renders an image attachment bubble and resolves a signed URL for private files.
///
/// Phase 5 redesign: replaced all hardcoded colors and dimensions with semantic
/// tokens, added shimmer skeleton loading (SkeletonLoader) instead of grey box,
/// fade-in transition on image load, retry on error, and full Semantics
/// coverage for accessibility. View-layer only.
///
/// Uses [SignedUrlCache] to prevent redundant API calls when scrolling
/// through chat history. Handles error states gracefully and caches
/// auth/permission errors to prevent retry storms.
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

  /// Single uploader instance — avoids creating a new object on every URL
  /// resolution call (which previously happened inside _loadSignedUrl).
  late final SupabaseAttachmentUploader _uploader =
      SupabaseAttachmentUploader();

  /// Image height — consistent across loading, error, and success states
  static const double _imageHeight = 180.0;

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

  /// Loads the signed URL with caching.
  ///
  /// Checks error cache first, then success cache, then calls API.
  Future<void> _loadSignedUrl() async {
    // Check error cache first to prevent retry storms
    if (SignedUrlCache.hasError(widget.storagePath)) {
      if (mounted) {
        setState(() {
          _error = 'Access denied';
          _loading = false;
        });
      }
      AppLogger.d(
        'AttachmentMessageTile: error cache hit for ${widget.storagePath.split('/').last}',
        tag: 'Chat',
      );
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
              _uploader.createSignedUrl(
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
      AppLogger.d(
        'AttachmentMessageTile: signed URL resolved for ${widget.storagePath.split('/').last}',
        tag: 'Chat',
      );
    } on Exception catch (e) {
      // Cache only auth/permission failures so transient errors can retry
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
      AppLogger.w(
        'AttachmentMessageTile: failed to resolve URL — $errorMessage',
        tag: 'Chat',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Semantic colors — replaces hardcoded primaryColor / grey.shade300
    final bg = widget.isMine
        ? colorScheme.primary.withValues(alpha: 0.85)
        : colorScheme.cardBackground;
    final fg = widget.isMine ? Colors.white : colorScheme.text;
    final metaColor = widget.isMine
        ? Colors.white.withValues(alpha: 0.7)
        : colorScheme.textSecondary;

    // Border radius consistent with MessageBubble
    final radius = BorderRadius.only(
      topLeft: Radius.circular(widget.isMine ? AppDimens.r18 : AppDimens.r4),
      topRight: Radius.circular(widget.isMine ? AppDimens.r4 : AppDimens.r18),
      bottomLeft: const Radius.circular(AppDimens.r18),
      bottomRight: const Radius.circular(AppDimens.r18),
    );

    return Semantics(
      label:
          'Image attachment'
          '${widget.caption != null ? ": ${widget.caption}" : ""}'
          ', sent at ${widget.time}',
      child: Align(
        alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // 75% width — consistent with MessageBubble ratio
            maxWidth: MediaQuery.of(context).size.width * 0.75,
            minWidth: 120,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(
              vertical: AppLayout.spacingTight,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: widget.isMine
                  ? null
                  : Border.all(color: colorScheme.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Column(
                crossAxisAlignment: widget.isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildImageSection(colorScheme),
                  if (widget.caption != null &&
                      widget.caption!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p12,
                        vertical: AppDimens.p8,
                      ),
                      child: Text(
                        widget.caption!,
                        style: AppTypography.bodySmall.copyWith(color: fg),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p12,
                      vertical: AppDimens.p8,
                    ),
                    child: Text(
                      widget.time,
                      style: AppTypography.micro.copyWith(color: metaColor),
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

  Widget _buildImageSection(AppColorScheme colorScheme) {
    // Loading state — shimmer skeleton
    if (_loading) {
      return _shimmerPlaceholder();
    }

    // Error state — icon + retry button
    if (_error != null || _resolvedUrl == null || _resolvedUrl!.isEmpty) {
      return _errorBox(colorScheme, _error ?? 'Failed to load image');
    }

    // Success state — image with fade-in transition
    return GestureDetector(
      onTap: () => _showFullScreen(context, _resolvedUrl!),
      child: Image.network(
        _resolvedUrl!,
        height: _imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        // Shimmer while image bytes load from network
        loadingBuilder: (c, child, progress) =>
            progress == null ? child : _shimmerPlaceholder(),
        errorBuilder: (c, e, st) =>
            _errorBox(context.colorScheme, 'Image error'),
      ),
    );
  }

  /// Shimmer skeleton placeholder — replaces plain grey box.
  Widget _shimmerPlaceholder() {
    return const SizedBox(
      height: _imageHeight,
      width: double.infinity,
      child: SkeletonLoader(
        height: _imageHeight,
        borderRadius: 0, // clipped by parent ClipRRect
      ),
    );
  }

  /// Error state with icon and retry action.
  Widget _errorBox(AppColorScheme colorScheme, String msg) {
    return GestureDetector(
      onTap: () {
        // Allow retry for non-auth errors
        if (!SignedUrlCache.hasError(widget.storagePath)) {
          AppLogger.d(
            'AttachmentMessageTile: retrying load for ${widget.storagePath.split('/').last}',
            tag: 'Chat',
          );
          setState(() {
            _loading = true;
            _error = null;
          });
          _loadSignedUrl();
        }
      },
      child: Container(
        height: _imageHeight,
        width: double.infinity,
        color: colorScheme.inputBackground,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppDimens.p12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: AppLayout.iconStandard,
              color: colorScheme.textTertiary,
            ),
            const SizedBox(height: AppLayout.spacingStandard),
            Text(
              msg,
              style: AppTypography.micro.copyWith(
                color: colorScheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            // Show retry hint for non-auth errors
            // TODO(l10n): 'Tap to retry' and error strings below should be
            // localized via AppLocalizations once l10n is set up for the app.
            if (!SignedUrlCache.hasError(widget.storagePath)) ...[
              const SizedBox(height: AppLayout.spacingTight),
              Text(
                'Tap to retry',
                style: AppTypography.micro.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullScreen(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(AppDimens.p8),
          backgroundColor: Colors.black,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                // Show a spinner while fullscreen image bytes are loading.
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                // Show an error state with a close button if the image fails
                // to load in the fullscreen viewer.
                errorBuilder: (ctx, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        // TODO(l10n): localize when l10n is added.
                        const Text(
                          'Failed to load',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
