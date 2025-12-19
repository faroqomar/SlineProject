import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles uploads to the private bucket 'chat-attachments'.
class AttachmentService {
  final SupabaseClient _client = Supabase.instance.client;
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
    final path = '$conversationId/${randomId}_$safeName';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
    return path;
  }

  /// Create a short-lived signed URL to view/download a private object.
  Future<String> createSignedUrl(
    String path, {
    int expiresInSeconds = 3600,
  }) async {
    final res = await _client.storage
        .from(_bucket)
        .createSignedUrl(path, expiresInSeconds);
    return res;
  }

  // --- helpers ---
  String _sanitize(String name) {
    return name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
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
