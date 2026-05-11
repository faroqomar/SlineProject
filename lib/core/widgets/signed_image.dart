import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:sline_app/core/config/storage_config.dart';
import 'package:sline_app/core/services/default_signed_url_generator.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/signed_url_generator.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/signed_url_cache.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';
import 'package:sline_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Visual tokens for [SignedImage] fallback and retry surfaces.
///
/// This generic adapter keeps the shared widget API independent from any one
/// named design system while still allowing callers to override media styling.
@immutable
class SignedImageMediaTokens {
  const SignedImageMediaTokens({
    required this.profilePhotoFallback,
    required this.foreground,
    required this.fallbackLabelStyle,
  });

  /// Background color for the retry/fallback image placeholder.
  final Color profilePhotoFallback;

  /// Foreground color for fallback icons and labels.
  final Color foreground;

  /// Text style for the localized retry label.
  final TextStyle fallbackLabelStyle;
}

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

  /// Optional media placeholder tokens for alternate visual themes.
  ///
  /// Existing callers keep the Amber Dusk fallback by leaving this unset.
  final SignedImageMediaTokens? mediaTokens;

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
    this.mediaTokens,
  });

  @override
  State<SignedImage> createState() => _SignedImageState();
}

String? _redactedStorageFileName(String? storagePathOrUrl) {
  final trimmed = storagePathOrUrl?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final normalized = trimmed.replaceAll(RegExp(r'/+$'), '');
  if (normalized.isEmpty) return null;

  if (!normalized.contains('/')) {
    return _maskedStorageToken(normalized);
  }

  final filename = normalized.split('/').last.trim();
  if (filename.isEmpty) return null;

  final safeFilename = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$');
  if (safeFilename.hasMatch(filename)) return filename;

  return _maskedStorageToken(filename);
}

String _maskedStorageToken(String value) {
  final safe = value.replaceAll(RegExp('[^A-Za-z0-9._-]'), '');
  if (safe.length <= 4) return '****';
  return '****${safe.substring(safe.length - 4)}';
}

String _safeSignedImageError(Object error) => error.runtimeType.toString();

SignedImageMediaTokens _defaultSignedImageMediaTokens() {
  final mediaTheme = AmberDuskTokens.widgetTheme.media;
  return SignedImageMediaTokens(
    profilePhotoFallback: mediaTheme.profilePhotoFallback,
    foreground: mediaTheme.foreground,
    fallbackLabelStyle: mediaTheme.fallbackLabelStyle,
  );
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
        error: _safeSignedImageError(e),
        json: {'file': _redactedStorageFileName(widget.storagePathOrUrl)},
      );
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaTheme = widget.mediaTokens ?? _defaultSignedImageMediaTokens();
    final l10n = AppLocalizations.of(context);

    // Shimmer loading state keeps signed media aligned with skeleton cards.
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
          child:
              widget.placeholder ??
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  color: mediaTheme.profilePhotoFallback,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: AppDimens.p22,
                      color: mediaTheme.foreground,
                    ),
                    const SizedBox(height: AppDimens.p4),
                    Text(
                      l10n?.tapToRetry ?? 'Tap to retry',
                      style: mediaTheme.fallbackLabelStyle,
                    ),
                  ],
                ),
              ),
        ),
      );
    }

    // Loaded — use CachedNetworkImage with memory optimization
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = widget.width.isFinite
        ? (widget.width * pixelRatio).toInt()
        : null;
    final cacheHeight = widget.height.isFinite
        ? (widget.height * pixelRatio).toInt()
        : null;

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
                color: mediaTheme.profilePhotoFallback,
              ),
              child: Icon(
                Icons.image_not_supported_outlined,
                size: AppDimens.p22,
                color: mediaTheme.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
