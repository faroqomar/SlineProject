import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';

/// Service for handling task image operations with Supabase Storage.
///
/// Architecture: This service is used by TaskViewModel to upload task images
/// to the private 'task-images' bucket. UI widgets should never call this
/// service directly.
///
/// Storage Pattern: Store paths in DB, not signed URLs. Generate signed URLs
/// at render time using SignedImage widget.
class TaskImageService {
  final SupabaseClient _supabase;
  final String bucket = 'task-images';

  TaskImageService([SupabaseClient? client])
    : _supabase = client ?? Supabase.instance.client;

  /// Upload raw bytes for a task image.
  ///
  /// Returns the storage path (not a signed URL) on success.
  /// Throws a user-friendly exception on failure.
  ///
  /// Example:
  /// ```dart
  /// final path = await taskImageService.uploadBytes(
  ///   bytes: imageBytes,
  ///   fileExt: 'jpg',
  ///   userId: userId,
  ///   taskId: taskId,
  /// );
  /// ```
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String fileExt,
    required String userId,
    required String taskId,
  }) async {
    // Validate authentication
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      AppLogger.e('Upload failed: Not authenticated', tag: 'TaskImages');
      throw Exception('Please sign in to upload images.');
    }

    // Validate inputs
    if (bytes.isEmpty) {
      throw Exception('No image data provided.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/tasks/$taskId/$timestamp.$fileExt';

    AppLogger.d('Uploading task image: $path', tag: 'TaskImages');

    try {
      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      AppLogger.i('Task image uploaded: $path', tag: 'TaskImages');
      return path; // return storage path only
    } on StorageException catch (e, st) {
      AppLogger.e(
        'Storage error uploading image',
        tag: 'TaskImages',
        error: e,
        stackTrace: st,
      );

      // Map common storage errors to user-friendly messages
      final message = e.message.toLowerCase();
      if (message.contains('bucket not found')) {
        throw Exception(
          'Image storage is not configured. Please contact support.',
        );
      }
      if (message.contains('payload too large') || message.contains('size')) {
        throw Exception('Image is too large. Please use a smaller image.');
      }
      if (message.contains('permission') || message.contains('policy')) {
        throw Exception('You do not have permission to upload this image.');
      }

      throw Exception('Failed to upload image. Please try again.');
    } catch (e, st) {
      AppLogger.e(
        'Unexpected error uploading image',
        tag: 'TaskImages',
        error: e,
        stackTrace: st,
      );
      throw Exception('Failed to upload image. Please try again.');
    }
  }

  /// Create a signed URL to view the task image.
  ///
  /// Returns the signed URL string on success, null on failure.
  /// Does not throw - returns null for graceful degradation in UI.
  Future<String?> createSignedUrl(
    String path, {
    Duration expire = const Duration(hours: 2),
  }) async {
    if (path.isEmpty) {
      return null;
    }

    try {
      final res = await _supabase.storage
          .from(bucket)
          .createSignedUrl(path, expire.inSeconds);
      return res;
    } on StorageException catch (e) {
      AppLogger.w(
        'Failed to create signed URL for $path',
        tag: 'TaskImages',
        error: e,
      );
      return null;
    } catch (e) {
      AppLogger.w(
        'Unexpected error creating signed URL',
        tag: 'TaskImages',
        error: e,
      );
      return null;
    }
  }

  /// Delete a task image from storage.
  ///
  /// Returns true on success, false on failure.
  /// Does not throw - allows graceful handling of cleanup failures.
  Future<bool> deleteImage(String path) async {
    if (path.isEmpty) {
      return false;
    }

    try {
      await _supabase.storage.from(bucket).remove([path]);
      AppLogger.i('Task image deleted: $path', tag: 'TaskImages');
      return true;
    } catch (e) {
      AppLogger.w(
        'Failed to delete task image: $path',
        tag: 'TaskImages',
        error: e,
      );
      return false;
    }
  }
}
