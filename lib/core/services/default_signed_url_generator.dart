import 'package:sline_app/core/config/storage_config.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/services/signed_url_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Default [SignedUrlGenerator] that uses the Supabase client directly.
///
/// This lives in core so that core widgets can create a fallback URL generator
/// without importing feature-specific services. Feature services
/// ([AvatarService], [TaskImageService]) are preferred when available — they
/// know the correct bucket and TTL for their domain.
///
/// This generator requires an explicit [bucket] name and uses
/// [SharedStorageConfig] for TTL lookup.
class DefaultSignedUrlGenerator implements SignedUrlGenerator {
  final String _bucket;
  final SupabaseClient _client;

  /// Creates a generator for the given storage [bucket].
  ///
  /// [client] defaults to `Supabase.instance.client` for production use.
  DefaultSignedUrlGenerator({
    required String bucket,
    SupabaseClient? client,
  })  : _bucket = bucket,
        _client = client ?? Supabase.instance.client;

  @override
  Future<String?> createSignedUrl(
    String storagePath, {
    Duration? expire,
  }) async {
    if (storagePath.isEmpty) return null;

    try {
      final seconds =
          expire?.inSeconds ??
          SharedStorageConfig.ttlDurationForBucket(_bucket).inSeconds;
      final url = await _client.storage
          .from(_bucket)
          .createSignedUrl(storagePath, seconds);
      return url;
    } on Exception catch (e) {
      AppLogger.w(
        'DefaultSignedUrlGenerator: Failed to sign URL for $_bucket/$storagePath',
        error: e,
      );
      return null;
    }
  }
}
