import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/utils/signed_url_cache.dart';
import 'package:sline_app/features/profile/services/avatar_service.dart';

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

  const SignedAvatar({
    super.key,
    required this.storagePathOrUrl,
    this.radius = 20,
    this.size,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 2,
    this.placeholder,
    this.backgroundColor,
  });

  @override
  State<SignedAvatar> createState() => _SignedAvatarState();
}

class _SignedAvatarState extends State<SignedAvatar> {
  AvatarService? _avatarService;
  String? _resolvedUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  AvatarService _ensureAvatarService() {
    return _avatarService ??= AvatarService(Supabase.instance.client);
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
      final signed = await _ensureAvatarService().createSignedUrl(
        v,
        expire: const Duration(hours: 2),
      );
      SignedUrlCache.set(v, signed);
      if (!mounted) return;
      setState(() {
        _resolvedUrl = signed;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
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
    final bgColor = widget.backgroundColor ?? AppColors.teal;

    Widget avatar;

    if (_loading) {
      avatar = Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: widget.borderRadius,
        ),
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.offWhite,
            ),
          ),
        ),
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
              color: AppColors.offWhite,
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
          placeholder: (context, url) => Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: widget.borderRadius,
            ),
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.offWhite,
                ),
              ),
            ),
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
              color: AppColors.offWhite,
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
    final bgColor = widget.backgroundColor ?? AppColors.teal;

    if (_loading) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: bgColor,
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.offWhite,
          ),
        ),
      );
    }

    if (_resolvedUrl == null) {
      return widget.placeholder ??
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: bgColor,
            child: Icon(
              Icons.person,
              color: AppColors.offWhite,
              size: widget.radius,
            ),
          );
    }

    // Use CachedNetworkImageProvider for circular avatars
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: bgColor,
      backgroundImage: CachedNetworkImageProvider(_resolvedUrl!),
      onBackgroundImageError: (exception, stackTrace) {},
    );
  }
}
