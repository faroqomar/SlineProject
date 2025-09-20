import 'package:flutter/material.dart';
import 'package:sline_app/features/tasks/services/task_image_service.dart';

/// Renders an image from either a public URL (legacy) or a private
/// Supabase Storage **path** in the `task-images` bucket by generating
/// a short-lived signed URL.
class SignedImage extends StatefulWidget {
  final String? storagePathOrUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final Widget? placeholder;

  const SignedImage({
    super.key,
    required this.storagePathOrUrl,
    this.width = 100,
    this.height = 80,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  State<SignedImage> createState() => _SignedImageState();
}

class _SignedImageState extends State<SignedImage> {
  static final Map<String, _CacheEntry> _cache = {};
  String? _resolvedUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final v = widget.storagePathOrUrl;
    if (v == null || v.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    // Legacy: already a public URL
    if (v.startsWith('http')) {
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
      final signer = TaskImageService();
      final signed = await signer.createSignedUrl(v, expire: const Duration(hours: 2));
      _cache[v] = _CacheEntry(url: signed ?? '', expiry: now.add(const Duration(minutes: 90)));
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
    final placeholder = widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.image_outlined, size: 22),
        );

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
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_resolvedUrl == null || _resolvedUrl!.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Image.network(
        _resolvedUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      ),
    );
  }
}

class _CacheEntry {
  final String url;
  final DateTime expiry;
  _CacheEntry({required this.url, required this.expiry});
}