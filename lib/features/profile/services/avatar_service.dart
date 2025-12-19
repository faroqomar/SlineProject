import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for uploading user avatar images to Supabase Storage
/// and generating short-lived signed URLs for private display.
///
/// NOTE:
/// - We store only the **storage path** in the DB (e.g. `avatars/<uid>/<ts>.jpg`).
/// - Display layers should call [createSignedUrl] to obtain a temporary link.
class AvatarService {
  /// Private bucket name used for storing avatars.
  /// We reuse the existing private bucket (e.g., `portfolio`).
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
  /// [expire] controls how long the URL is valid (default 2 hours).
  /// Returns a temporary public URL suitable for display in the UI.
  Future<String> createSignedUrl(
    String storagePath, {
    Duration expire = const Duration(hours: 2),
  }) async {
    final url = await _supabase.storage
        .from(bucket)
        .createSignedUrl(storagePath, expire.inSeconds);
    return url;
  }
}
