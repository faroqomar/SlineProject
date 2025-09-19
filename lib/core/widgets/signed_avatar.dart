import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/features/profile/services/avatar_service.dart';

/// A small helper widget that renders a user avatar from either
/// a public URL (legacy) or a private Supabase Storage **path**.
/// If a storage path is provided, a short-lived signed URL is generated.
class SignedAvatar extends StatefulWidget {
  final String? storagePathOrUrl;
  final double radius;
  final Widget? placeholder;

  const SignedAvatar({
    super.key,
    required this.storagePathOrUrl,
    this.radius = 20,
    this.placeholder,
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
    if (_loading) {
      return CircleAvatar(
        radius: widget.radius,
        child: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_resolvedUrl == null) {
      return widget.placeholder ??
          CircleAvatar(radius: widget.radius, child: const Icon(Icons.person));
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: NetworkImage(_resolvedUrl!),
    );
  }
}

class _CacheEntry {
  final String url;
  final DateTime expiry;
  _CacheEntry({required this.url, required this.expiry});
}