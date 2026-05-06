import 'dart:typed_data';

import 'package:sline_app/core/config/storage_config.dart';
import 'package:sline_app/core/services/signed_url_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for uploading user avatar images to Supabase Storage
/// and generating short-lived signed URLs for private display.
///
/// Implements [SignedUrlGenerator] so that core widgets ([SignedAvatar]) can
/// depend on the abstract interface instead of this feature-specific class.
///
/// NOTE:
/// - We store only the **storage path** in the DB (e.g. `avatars/<uid>/<ts>.jpg`).
/// - Display layers should call [createSignedUrl] to obtain a temporary link.
/// - Uses [SharedStorageConfig] for consistent TTL values.
class AvatarService implements SignedUrlGenerator {
  /// Private bucket name used for storing avatars.
  static const String bucket = 'avatars';

  final SupabaseClient _supabase;

  /// Create a new [AvatarService] instance.
  /// [supabase] is the shared Supabase client from your app config.
  AvatarService(this._supabase);

  /// Upload a new avatar image for the given [userId].
  ///
  /// Parameters:
  /// - [userId]: The authenticated user's id.
  /// - [bytes]: Raw bytes of the image file.
  /// - [contentType]: MIME type (e.g., 'image/jpeg', 'image/png').
  /// - [fileExt]: File extension without dot (e.g., 'jpg', 'png').
  ///
  /// Returns the **storage path** string (e.g.,
  /// `avatars/<userId>/<timestamp>.<ext>`).
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String contentType,
    required String fileExt,
  }) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _supabase.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return path;
  }

  /// Create a short-lived signed URL for a given [storagePath].
  ///
  /// Uses [SharedStorageConfig.avatarTtlSeconds] for consistent TTL.
  /// Returns a temporary public URL suitable for display in the UI.
  @override
  Future<String?> createSignedUrl(
    String storagePath, {
    Duration? expire,
  }) async {
    final seconds = expire?.inSeconds ?? SharedStorageConfig.avatarTtlSeconds;
    final url = await _supabase.storage
        .from(bucket)
        .createSignedUrl(storagePath, seconds);
    return url;
  }
}
