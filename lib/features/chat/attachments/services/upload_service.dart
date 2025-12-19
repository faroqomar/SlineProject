import '../../services/attachment_service.dart';

/// Thin wrapper to keep the attachments module self-contained.
class SupabaseAttachmentUploader {
  final AttachmentService _svc = AttachmentService();

  /// Uploads under `convos/<conversationId>/random_safeName`.
  Future<String> uploadImage({
    required String conversationId,
    required String filename,
    required List<int> bytes,
  }) {
    return _svc.uploadBytes(
      conversationId: 'convos/$conversationId',
      filename: filename,
      bytes: bytes,
    );
  }

  Future<String> createSignedUrl(String path, {int expiresInSeconds = 3600}) {
    return _svc.createSignedUrl(path, expiresInSeconds: expiresInSeconds);
  }
}
