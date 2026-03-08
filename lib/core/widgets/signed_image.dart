import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sline_app/core/config/storage_config.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/signed_url_cache.dart';
import 'package:sline_app/features/tasks/services/task_image_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Renders an image from either a public URL or a private Supabase Storage path.
///
/// Why this widget: Handles the complexity of displaying task images that may be
/// stored as either legacy public URLs or private storage paths requiring signed
/// URL generation. Uses shared caching to prevent redundant API calls.
///
/// Performance: Uses CachedNetworkImage for disk/memory caching of downloaded
/// images, reducing network calls on subsequent loads.
///
/// Example:
/// ```dart
/// SignedImage(
///   storagePathOrUrl: task.imagePaths.first,
///   width: 120,
///   height: 80,
///   borderRadius: 12,
/// )
/// ```
class SignedImage extends StatefulWidget {
  final String? storagePathOrUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final Widget? placeholder;

  final String? bucket;

  const SignedImage({
    super.key,
    required this.storagePathOrUrl,
    this.width = 100,
    this.height = 80,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.bucket,
  });

  @override
  State<SignedImage> createState() => _SignedImageState();
}

class _SignedImageState extends State<SignedImage> {
  String? _resolvedUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  /// Resolves the storage path to a displayable URL.
  ///
  /// Why this logic: Handles three cases:
  /// 1. Null/empty path -> show placeholder
  /// 2. Full URL (legacy) -> use directly
  /// 3. Storage path -> generate signed URL with caching
  Future<void> _resolve() async {
    final v = widget.storagePathOrUrl;
    if (v == null || v.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    // Legacy public URLs can be used directly
    if (v.startsWith('http')) {
      setState(() {
        _resolvedUrl = v;
        _loading = false;
      });
      return;
    }

    // Check shared cache first to avoid redundant API calls
    final cached = SignedUrlCache.get(v);
    if (cached != null) {
      setState(() {
        _resolvedUrl = cached;
        _loading = false;
      });
      return;
    }

    // Generate new signed URL and cache it
    try {
      String? resolved;
      if (widget.bucket != null) {
        // Try signed URL first (for private buckets)
        try {
          resolved = await Supabase.instance.client.storage
              .from(widget.bucket!)
              .createSignedUrl(
                v,
                SharedStorageConfig.ttlForBucket(widget.bucket!),
              );
        } catch (e) {
          // If signed URL fails (e.g., public bucket), fall back to public URL
          resolved = Supabase.instance.client.storage
              .from(widget.bucket!)
              .getPublicUrl(v);
        }
      } else {
        // Default to TaskImageService (legacy behavior for task-images)
        final signer = TaskImageService();
        resolved = await signer.createSignedUrl(
          v,
          expire: SharedStorageConfig.ttlDurationForBucket('task-images'),
        );
      }

      if (resolved != null && resolved.isNotEmpty) {
        SignedUrlCache.set(v, resolved);
      }
      if (!mounted) return;
      setState(() {
        _resolvedUrl = resolved;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      AppLogger.w(
        'Failed to resolve signed image URL',
        tag: 'SignedImage',
        json: {'path': widget.storagePathOrUrl, 'error': e.toString()},
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPlaceholder =
        widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(Icons.image_outlined, size: 22),
        );

    // Loading state while resolving signed URL
    if (_loading) {
      return Container(
        width: widget.width,
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // No URL resolved - show placeholder
    if (_resolvedUrl == null || _resolvedUrl!.isEmpty) {
      return defaultPlaceholder;
    }

    // Use CachedNetworkImage for disk/memory caching with memory optimization
    // We determine cache size based on render size to avoid OOM on large images
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int? cacheWidth = widget.width.isFinite
        ? (widget.width * pixelRatio).toInt()
        : null;
    final int? cacheHeight = widget.height.isFinite
        ? (widget.height * pixelRatio).toInt()
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: CachedNetworkImage(
        imageUrl: _resolvedUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        // CRITICAL: Optimize memory usage by decoding only to display size
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        placeholder: (context, url) => Container(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
          ),
          child: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => defaultPlaceholder,
      ),
    );
  }
}
