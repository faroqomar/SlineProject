import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/storage_config.dart';

// #region agent log
void _agentDebugLog(
  String location,
  String message,
  Map<String, dynamic> data,
  String hypothesisId,
) {
  try {
    final line = jsonEncode({
      'sessionId': '9844e5',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'message': message,
      'data': data,
      'hypothesisId': hypothesisId,
    });
    File(
      '/Users/eros/Dev/Eros_Projects/Sline/sline_app/.cursor/debug-9844e5.log',
    ).writeAsStringSync('$line\n', mode: FileMode.append);
  } on Exception catch (_) {}
}
// #endregion

/// Handles uploads to the private bucket 'chat-attachments'.
///
/// Uses [SharedStorageConfig] for consistent TTL values.
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
            upsert: false,
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
    // #region agent log
    _agentDebugLog('attachment_service.dart:createSignedUrl', 'entry', {
      'path': path,
      'bucket': _bucket,
      'authUid': _client.auth.currentUser?.id,
      'hasSession': _client.auth.currentSession != null,
    }, 'H-A');
    // #endregion
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
          // #region agent log
          _agentDebugLog('attachment_service.dart:createSignedUrl', 'throw', {
            'path': path,
            'alternateTried': alt,
            'errorType': e.runtimeType.toString(),
            'errorToString': e.toString(),
            if (e is StorageException) 'statusCode': e.statusCode,
            if (e is StorageException) 'message': e.message,
          }, 'H-A');
          // #endregion
          rethrow;
        }
      }
      // #region agent log
      _agentDebugLog('attachment_service.dart:createSignedUrl', 'throw', {
        'path': path,
        'errorType': e.runtimeType.toString(),
        'errorToString': e.toString(),
        if (e is StorageException) 'statusCode': e.statusCode,
        if (e is StorageException) 'message': e.message,
      }, 'H-A');
      // #endregion
      rethrow;
    }
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
