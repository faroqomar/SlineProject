

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../models/attachment_payload.dart';
import '../errors/attachment_exceptions.dart';

/// Picks an image from the user's gallery and returns an AttachmentPayload.
class PickImageService {
  final ImagePicker _picker = ImagePicker();

  /// Returns a payload or throws [AttachmentPickCancelled] if user cancels.
  Future<AttachmentPayload> pickFromGallery() async {
    final XFile? x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // no compression here; handled by CompressService
      maxWidth: 4096,
    );
    if (x == null) {
      throw AttachmentPickCancelled();
    }
    final bytes = await x.readAsBytes();
    if (bytes.isEmpty) {
      throw AttachmentValidationError('Empty image');
    }
    final name = x.name;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
    return AttachmentPayload(
      name: name,
      ext: ext,
      bytes: Uint8List.fromList(bytes),
      size: bytes.length,
    );
  }
}