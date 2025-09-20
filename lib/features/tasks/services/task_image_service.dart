import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskImageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String bucket = 'task-images';

  /// Upload raw bytes for a task image
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String fileExt,
    required String userId,
    required String taskId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/tasks/$taskId/$timestamp.$fileExt';

    await _supabase.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return path; // return storage path only
  }

  /// Create a signed URL to view the task image
  Future<String?> createSignedUrl(String path,
      {Duration expire = const Duration(days: 7)}) async {
    final res =
        await _supabase.storage.from(bucket).createSignedUrl(path, expire.inSeconds);
    return res;
  }
}
