import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:sline_app/core/config/storage_config.dart';
import 'package:sline_app/core/services/default_signed_url_generator.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/signed_url_generator.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/signed_url_cache.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';

/// Renders a user avatar from either a public URL or a private Supabase Storage path.
///
/// Why this widget: Abstracts the complexity of handling both legacy public URLs
/// and private storage paths that require signed URL generation. Includes caching
/// to prevent redundant API calls on widget rebuilds.
///
/// Performance: Uses CachedNetworkImage for disk/memory caching of downloaded
/// images, reducing network calls on subsequent loads.
///
/// Supports two modes:
/// - **Circular**: Uses `radius` parameter (default, backward compatible)
/// - **Rounded Rectangle**: Uses `size` and `borderRadius` parameters
///
/// Example:
/// ```dart
/// SignedAvatar(
///   storagePathOrUrl: profile.avatarUrl, // Can be path or full URL
///   size: 48,
///   borderRadius: BorderRadius.circular(12),
/// )
/// ```
class SignedAvatar extends StatefulWidget {
  final String? storagePathOrUrl;

  /// Radius for circular avatars (used when borderRadius is null)
  final double radius;

  /// Size for rectangular avatars (width and height)
  /// When provided with borderRadius, creates a rounded rectangle avatar
  final double? size;

  /// Border radius for rounded rectangle avatars
  /// When null, uses CircleAvatar (circular)
  final BorderRadius? borderRadius;

  /// Border color around the avatar
  final Color? borderColor;

  /// Border width around the avatar
  final double borderWidth;

  /// Custom placeholder widget when no avatar is available
  final Widget? placeholder;

  /// Background color for the placeholder
  final Color? backgroundColor;

  /// Optional [SignedUrlGenerator] for resolving storage paths to signed URLs.
  final SignedUrlGenerator? urlGenerator;

  /// Initials to display when the image fails to load (e.g., "JD" for John Doe).
  /// When provided, shows initials in a colored circle instead of the generic person icon.
  final String? initials;

  /// When true, shows a 12px green circle at the bottom-right corner
  /// indicating the user is online.
  final bool showOnlineIndicator;

  const SignedAvatar({
    super.key,
    required this.storagePathOrUrl,
    this.radius = AppLayout.avatarDefault / 2,
    this.size,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = AppLayout.borderAvatar,
    this.placeholder,
    this.backgroundColor,
    this.urlGenerator,
    this.initials,
    this.showOnlineIndicator = false,
  });

  @override
  State<SignedAvatar> createState() => _SignedAvatarState();
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

String _safeSignedAvatarError(Object error) => error.runtimeType.toString();

class _SignedAvatarState extends State<SignedAvatar> {
  SignedUrlGenerator? _urlGenerator;
  String? _resolvedUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  SignedUrlGenerator _ensureUrlGenerator() {
    return _urlGenerator ??=
        widget.urlGenerator ?? DefaultSignedUrlGenerator(bucket: 'avatars');
  }

  @override
  void didUpdateWidget(covariant SignedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-resolve if the storage path changed
    if (oldWidget.storagePathOrUrl != widget.storagePathOrUrl) {
      _loading = true;
      _resolvedUrl = null;
      _resolve();
    }
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
      final signed = await _ensureUrlGenerator().createSignedUrl(
        v,
        expire: SharedStorageConfig.ttlDurationForBucket('avatars'),
      );
      if (signed != null && signed.isNotEmpty) {
        SignedUrlCache.set(v, signed);
      }
      if (!mounted) return;
      setState(() {
        _resolvedUrl = signed;
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      AppLogger.w(
        'Failed to resolve signed avatar URL',
        tag: 'SignedAvatar',
        error: _safeSignedAvatarError(e),
        json: {'file': _redactedStorageFileName(widget.storagePathOrUrl)},
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use rounded rectangle mode if borderRadius is provided
    if (widget.borderRadius != null) {
      return _buildRoundedRectAvatar();
    }

    // Default: circular avatar (backward compatible)
    return _buildCircularAvatar();
  }

  /// Builds a rounded rectangle avatar with optional border
  Widget _buildRoundedRectAvatar() {
    final avatarSize = widget.size ?? (widget.radius * 2);
    final mediaTheme = AmberDuskTokens.widgetTheme.media;
    final bgColor = widget.backgroundColor ?? mediaTheme.avatarFallback;

    Widget avatar;

    if (_loading) {
      // Shimmer placeholder for rounded rect mode
      avatar = SkeletonLoader(
        width: avatarSize,
        height: avatarSize,
        borderRadius:
            widget.borderRadius?.resolve(TextDirection.ltr).topLeft.x ?? 12,
      );
    } else if (_resolvedUrl == null) {
      avatar =
          widget.placeholder ??
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: widget.borderRadius,
            ),
            child: Icon(
              Icons.person,
              color: mediaTheme.foreground,
              size: avatarSize * 0.5,
            ),
          );
    } else {
      avatar = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: CachedNetworkImage(
          imageUrl: _resolvedUrl!,
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => SkeletonLoader(
            width: avatarSize,
            height: avatarSize,
            borderRadius:
                widget.borderRadius?.resolve(TextDirection.ltr).topLeft.x ??
                AmberDuskTokens.spacing.md,
          ),
          errorWidget: (context, url, error) => Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: widget.borderRadius,
            ),
            child: Icon(
              Icons.person,
              color: mediaTheme.foreground,
              size: avatarSize * 0.5,
            ),
          ),
        ),
      );
    }

    // Wrap with border if borderColor is provided
    if (widget.borderColor != null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.borderColor!,
            width: widget.borderWidth,
          ),
          borderRadius: widget.borderRadius,
        ),
        child: avatar,
      );
    }

    return avatar;
  }

  /// Builds a circular avatar (original behavior)
  Widget _buildCircularAvatar() {
    final mediaTheme = AmberDuskTokens.widgetTheme.media;
    final bgColor = widget.backgroundColor ?? mediaTheme.avatarFallback;
    final avatarSize = widget.radius * 2;

    Widget avatar;

    if (_loading) {
      // Shimmer placeholder keeps avatar loading consistent with skeleton cards.
      avatar = SkeletonAvatar(size: avatarSize);
    } else if (_resolvedUrl == null) {
      // Initials fallback or placeholder
      avatar =
          widget.placeholder ?? _buildInitialsFallback(bgColor, avatarSize);
    } else {
      // Loaded — fade in
      avatar = AnimatedOpacity(
        opacity: 1.0,
        duration: AppMotion.standard,
        curve: AppMotion.curveDecel,
        child: CircleAvatar(
          radius: widget.radius,
          backgroundColor: bgColor,
          backgroundImage: CachedNetworkImageProvider(_resolvedUrl!),
          onBackgroundImageError: (exception, stackTrace) {},
        ),
      );
    }

    // Online indicator overlay uses the Amber forest semantic so presence is
    // visually distinct from the old teal-era avatar fallback.
    if (widget.showOnlineIndicator) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: AppLayout.iconTiny,
              height: AppLayout.iconTiny,
              decoration: BoxDecoration(
                color: mediaTheme.onlineDot,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AmberDuskTokens.colors.page,
                  width: AppLayout.borderAvatar,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(image: true, label: 'User avatar', child: avatar);
  }

  /// Builds initials fallback when image fails to load.
  Widget _buildInitialsFallback(Color bgColor, double size) {
    final mediaTheme = AmberDuskTokens.widgetTheme.media;
    if (widget.initials != null && widget.initials!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: bgColor,
        child: Text(
          widget.initials!.substring(0, widget.initials!.length.clamp(0, 2)),
          style: mediaTheme.initialsTextStyle(size),
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor,
      child: Icon(Icons.person, color: mediaTheme.foreground, size: size * 0.5),
    );
  }
}
