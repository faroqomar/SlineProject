import 'package:sline_app/features/chat/services/attachment_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper to keep the attachments module self-contained.
class SupabaseAttachmentUploader {
  /// Creates an uploader around [AttachmentService].
  ///
  /// The service is lazy by default so unit tests can construct ViewModels
  /// without initializing Supabase unless an upload or signed URL is requested.
  SupabaseAttachmentUploader({
    AttachmentService? service,
    SupabaseClient? client,
  }) : _service = service,
       _client = client;

  AttachmentService? _service;
  final SupabaseClient? _client;

  AttachmentService get _effectiveService =>
      _service ??= AttachmentService(client: _client);

  /// Uploads under `convos/<conversationId>/random_safeName`.
  Future<String> uploadImage({
    required String conversationId,
    required String filename,
    required List<int> bytes,
  }) {
    return _effectiveService.uploadBytes(
      conversationId: conversationId,
      filename: filename,
      bytes: bytes,
    );
  }

  /// Creates a signed URL through the service boundary for private chat media.
  Future<String> createSignedUrl(String path, {int expiresInSeconds = 3600}) {
    return _effectiveService.createSignedUrl(
      path,
      expiresInSeconds: expiresInSeconds,
    );
  }
}
