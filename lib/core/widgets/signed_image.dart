import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:sline_app/core/config/storage_config.dart';
import 'package:sline_app/core/services/default_signed_url_generator.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/signed_url_generator.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/utils/signed_url_cache.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';
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

  /// Optional [SignedUrlGenerator] for resolving storage paths to signed URLs.
  /// If not provided, a default generator for 'task-images' bucket is used.
  final SignedUrlGenerator? urlGenerator;

  const SignedImage({
    super.key,
    required this.storagePathOrUrl,
    this.width = 100,
    this.height = 80,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.bucket,
    this.urlGenerator,
  });

  @override
  State<SignedImage> createState() => _SignedImageState();
}

class _SignedImageState extends State<SignedImage> {
  String? _resolvedUrl;
  bool _loading = true;
  bool _hasError = false;

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
        } on Exception catch (_) {
          // If signed URL fails (e.g., public bucket), fall back to public URL
          resolved = Supabase.instance.client.storage
              .from(widget.bucket!)
              .getPublicUrl(v);
        }
      } else {
        // Use injected generator or default to task-images bucket
        final signer =
            widget.urlGenerator ??
            DefaultSignedUrlGenerator(bucket: 'task-images');
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
    } on Exception catch (e) {
      if (!mounted) return;
      AppLogger.w(
        'Failed to resolve signed image URL',
        tag: 'SignedImage',
        json: {'path': widget.storagePathOrUrl, 'error': e.toString()},
      );
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shimmer loading state (replaces CircularProgressIndicator)
    if (_loading) {
      return SkeletonLoader(
        width: widget.width,
        height: widget.height,
        borderRadius: widget.borderRadius,
      );
    }

    // Error state with retry
    if (_hasError || _resolvedUrl == null || _resolvedUrl!.isEmpty) {
      return Semantics(
        image: true,
        label: 'Image failed to load',
        child: GestureDetector(
          onTap: () {
            setState(() {
              _loading = true;
              _hasError = false;
              _resolvedUrl = null;
            });
            _resolve();
          },
          child: widget.placeholder ??
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  color: Theme.of(context).colorScheme.surface.withValues(
                    alpha: 0.3,
                  ),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined, size: 22),
                    SizedBox(height: 4),
                    Text('Tap to retry', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
        ),
      );
    }

    // Loaded — use CachedNetworkImage with memory optimization
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth =
        widget.width.isFinite ? (widget.width * pixelRatio).toInt() : null;
    final cacheHeight =
        widget.height.isFinite ? (widget.height * pixelRatio).toInt() : null;

    return Semantics(
      image: true,
      label: 'Image',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: AppMotion.standard,
          curve: AppMotion.curveDecel,
          child: CachedNetworkImage(
            imageUrl: _resolvedUrl!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            memCacheWidth: cacheWidth,
            memCacheHeight: cacheHeight,
            placeholder: (context, url) => SkeletonLoader(
              width: widget.width,
              height: widget.height,
              borderRadius: widget.borderRadius,
            ),
            errorWidget: (context, url, error) => Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                color: Theme.of(context).colorScheme.surface.withValues(
                  alpha: 0.3,
                ),
              ),
              child: const Icon(Icons.image_not_supported_outlined, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
