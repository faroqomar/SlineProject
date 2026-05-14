import 'dart:math';
import 'dart:typed_data';

import 'package:sline_app/core/config/storage_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles uploads to the private bucket 'chat-attachments'.
///
/// Uses [SharedStorageConfig] for consistent TTL values.
class AttachmentService {
  /// Creates the attachment service with an injectable Supabase client.
  ///
  /// Tests and ViewModels pass a client explicitly so private storage access
  /// stays behind the service boundary instead of leaking into widgets.
  AttachmentService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _bucket = 'chat-attachments';

  /// Upload raw bytes under: conversationId/random_filename
  /// Returns the storage path (NOT a public URL).
  Future<String> uploadBytes({
    required String conversationId,
    required String filename,
    required List<int> bytes,
  }) async {
    final safeName = _sanitize(filename);
    final randomId = _randomId(10);
    final path = conversationId.startsWith('convos/')
        ? '$conversationId/${randomId}_$safeName'
        : 'convos/$conversationId/${randomId}_$safeName';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            cacheControl: SharedStorageConfig.chatAttachmentTtlSeconds
                .toString(),
          ),
        );
    return path;
  }

  /// Create a short-lived signed URL to view/download a private object.
  ///
  /// Uses [SharedStorageConfig.chatAttachmentTtlSeconds] for consistent TTL.
  /// On 404, retries once with the alternate path shape (convos/convos/... <-> convos/...)
  /// so both legacy and current upload paths can resolve.
  Future<String> createSignedUrl(String path, {int? expiresInSeconds}) async {
    final seconds =
        expiresInSeconds ?? SharedStorageConfig.chatAttachmentTtlSeconds;
    const prefixLegacy = 'convos/convos/';
    const prefixNormal = 'convos/';

    String? alternatePath(String p) {
      if (p.startsWith(prefixLegacy) && p.length > prefixLegacy.length) {
        return prefixNormal + p.substring(prefixLegacy.length);
      }
      if (p.startsWith(prefixNormal) &&
          !p.startsWith(prefixLegacy) &&
          p.length > prefixNormal.length) {
        return prefixLegacy + p.substring(prefixNormal.length);
      }
      return null;
    }

    try {
      final res = await _client.storage
          .from(_bucket)
          .createSignedUrl(path, seconds);
      return res;
    } on Exception catch (e) {
      final is404 =
          e is StorageException &&
          (e.statusCode == '404' ||
              e.message.toLowerCase().contains('not found'));
      final alt = is404 ? alternatePath(path) : null;
      if (alt != null) {
        try {
          final res = await _client.storage
              .from(_bucket)
              .createSignedUrl(alt, seconds);
          return res;
        } on Exception catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
  }

  // --- helpers ---
  String _sanitize(String name) {
    return name.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');
  }

  String _randomId(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }
}
