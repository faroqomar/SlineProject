import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/features/profile/services/avatar_service.dart';

/// A helper widget that renders a user avatar from either
/// a public URL (legacy) or a private Supabase Storage **path**.
/// If a storage path is provided, a short-lived signed URL is generated.
/// 
/// Supports two modes:
/// - **Circular**: Uses `radius` parameter (default behavior for backward compatibility)
/// - **Rounded Rectangle**: Uses `size` and `borderRadius` parameters
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
  static final Map<String, _CacheEntry> _cache = {};
  late final AvatarService _avatarService;
  String? _resolvedUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _avatarService = AvatarService(Supabase.instance.client);
    _resolve();
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

  Future<void> _resolve() async {
    final v = widget.storagePathOrUrl;
    if (v == null || v.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    if (v.startsWith('http')) { // legacy public URL
      setState(() {
        _resolvedUrl = v;
        _loading = false;
      });
      return;
    }

    final now = DateTime.now();
    final hit = _cache[v];
    if (hit != null && hit.expiry.isAfter(now)) {
      setState(() {
        _resolvedUrl = hit.url;
        _loading = false;
      });
      return;
    }

    try {
      final signed = await _avatarService.createSignedUrl(v, expire: const Duration(hours: 2));
      _cache[v] = _CacheEntry(url: signed, expiry: now.add(const Duration(minutes: 90)));
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
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.offWhite),
          ),
        ),
      );
    } else if (_resolvedUrl == null) {
      avatar = widget.placeholder ?? Container(
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
        child: Image.network(
          _resolvedUrl!,
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
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
          },
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
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.offWhite),
        ),
      );
    }

    if (_resolvedUrl == null) {
      return widget.placeholder ??
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: bgColor,
            child: Icon(Icons.person, color: AppColors.offWhite, size: widget.radius),
          );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: NetworkImage(_resolvedUrl!),
      onBackgroundImageError: (exception, stackTrace) {},
    );
  }
}

class _CacheEntry {
  final String url;
  final DateTime expiry;
  _CacheEntry({required this.url, required this.expiry});
}
