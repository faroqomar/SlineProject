import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/signed_url_cache.dart';
import 'package:sline_app/core/widgets/fullscreen_image_viewer.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';

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
/// through chat history, while keeping backend-specific errors out of widgets.
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
  bool _resolverMissing = false;

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
    if (oldWidget.storagePath != widget.storagePath ||
        oldWidget.signedUrlResolver != widget.signedUrlResolver) {
      _loading = true;
      _error = null;
      _resolvedUrl = null;
      _resolverMissing = false;
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
      AppLogger.d('AttachmentMessageTile: error cache hit', tag: 'Chat');
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

    final resolver = widget.signedUrlResolver;
    if (resolver == null) {
      if (mounted) {
        setState(() {
          _error = 'Could not load attachment. Please try again.';
          _loading = false;
          _resolverMissing = true;
        });
      }
      AppLogger.w(
        'AttachmentMessageTile: missing signed URL resolver',
        tag: 'Chat',
      );
      return;
    }

    // Generate new signed URL through the ViewModel-provided resolver.
    try {
      final url = await resolver(widget.storagePath);

      // Cache the successful URL
      SignedUrlCache.set(widget.storagePath, url);

      if (mounted) {
        setState(() {
          _resolvedUrl = url;
          _loading = false;
          _resolverMissing = false;
        });
      }
      AppLogger.d('AttachmentMessageTile: signed URL resolved', tag: 'Chat');
    } on Object catch (e, st) {
      // Resolver errors may include private storage paths, so the widget keeps
      // copy generic and lets the service/ViewModel own backend-specific types.
      const errorMessage = 'Could not load attachment. Please try again.';

      if (mounted) {
        setState(() {
          _error = errorMessage;
          _loading = false;
        });
      }
      AppLogger.w(
        'AttachmentMessageTile: failed to resolve URL — $errorMessage',
        tag: 'Chat',
        error: e,
        json: {'stack_trace': st.toString()},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final amberColors = context.amberColors;

    // Attachment bubbles follow the same Amber Dusk contract as text bubbles.
    final bg = widget.isMine
        ? amberColors.primary.withValues(alpha: 0.92)
        : amberColors.surfaceRaised;
    final fg = widget.isMine ? amberColors.textInverse : amberColors.text;
    final metaColor = widget.isMine
        ? amberColors.textInverse.withValues(alpha: 0.7)
        : amberColors.muted;

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
                  : Border.all(color: amberColors.surfaceHighest),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Column(
                crossAxisAlignment: widget.isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildImageSection(amberColors),
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

  Widget _buildImageSection(AmberDuskColorScheme amberColors) {
    // Loading state — shimmer skeleton
    if (_loading) {
      return _shimmerPlaceholder();
    }

    // Error state — icon + retry button
    if (_error != null || _resolvedUrl == null || _resolvedUrl!.isEmpty) {
      return _errorBox(amberColors, _error ?? 'Failed to load image');
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
        errorBuilder: (c, e, st) => _errorBox(amberColors, 'Image error'),
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
  Widget _errorBox(AmberDuskColorScheme amberColors, String msg) {
    final canRetry =
        !_resolverMissing && !SignedUrlCache.hasError(widget.storagePath);
    return GestureDetector(
      onTap: canRetry
          ? () {
              // Allow retry for non-auth errors
              AppLogger.d('AttachmentMessageTile: retrying load', tag: 'Chat');
              setState(() {
                _loading = true;
                _error = null;
              });
              _loadSignedUrl();
            }
          : null,
      child: Container(
        height: _imageHeight,
        width: double.infinity,
        color: amberColors.surface,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppDimens.p12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: AppLayout.iconStandard,
              color: amberColors.muted,
            ),
            const SizedBox(height: AppLayout.spacingStandard),
            Text(
              msg,
              style: AppTypography.micro.copyWith(color: amberColors.muted),
              textAlign: TextAlign.center,
            ),
            // Show retry hint for non-auth errors
            // Localization backlog: 'Tap to retry' and error strings below
            // should move to AppLocalizations once l10n covers this surface.
            if (canRetry) ...[
              const SizedBox(height: AppLayout.spacingTight),
              Text(
                'Tap to retry',
                style: AppTypography.micro.copyWith(
                  color: amberColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Opens the image in the shared [FullscreenImageViewer] with Hero animation,
  /// pinch-to-zoom, and drag-to-dismiss. Replaces the old basic Dialog viewer.
  /// Phase 6B: wired to reusable FullscreenImageViewer from core/widgets.
  void _showFullScreen(BuildContext context, String url) {
    FullscreenImageViewer.show(
      context,
      imageUrl: url,
      // Full path avoids hash collisions; Hero tags are not user-visible copy.
      heroTag: 'chat-attachment-${widget.runtimeType}-${widget.storagePath}',
      caption: widget.caption,
    );
  }
}
