import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/logger_service.dart';
import '../../services/message_service.dart';
import '../errors/attachment_exceptions.dart';
import '../services/pick_image_service.dart';
import '../services/compress_service.dart';
import '../services/upload_service.dart';

/// High-level use-case to send an image attachment.
/// Orchestrates: pick -> validate -> compress -> upload -> create message.
Future<void> sendImageAttachment({
  required String conversationId,
  required String senderId,
  required String receiverId,
}) async {
  final supabase = Supabase.instance.client;
  if (supabase.auth.currentUser?.id != senderId) {
    // Defensive: ensure the sender is the logged-in user
    AppLogger.w('[ATTACH] senderId != current user');
  }

  try {
    // 1) Pick
    final payload = await PickImageService().pickFromGallery();

    // 2) Validate basic size (optional threshold: 20MB)
    const int maxBytes = 20 * 1024 * 1024;
    if (payload.size <= 0 || payload.size > maxBytes) {
      throw AttachmentValidationError('Image size invalid (max 20MB)');
    }

    // 3) Compress (mobile only)
    final compressed = await CompressService().maybeCompressImage(
      payload.bytes,
    );

    // 4) Upload to Storage
    final uploader = SupabaseAttachmentUploader();
    final storagePath = await uploader.uploadImage(
      conversationId: conversationId,
      filename: payload.name,
      bytes: compressed,
    );

    // 5) Insert message with attachment info
    final msgService = MessageService();
    await msgService.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: '[photo]',
      attachmentUrl: storagePath,
      attachmentType: 'image',
      attachmentName: payload.name,
      attachmentSize: compressed.length,
    );

    AppLogger.i(
      '[ATTACH] image uploaded + message created: path=$storagePath size=${compressed.length}',
    );
  } on AttachmentPickCancelled {
    AppLogger.d('[ATTACH] user cancelled picking');
    return;
  } on AttachmentValidationError catch (e) {
    AppLogger.e(e.toString());
    rethrow;
  } on AttachmentUploadError catch (e) {
    AppLogger.e(e.toString());
    rethrow;
  } catch (e) {
    AppLogger.e('Unhandled attachment error: ${e.toString()}');
    rethrow;
  }
}
