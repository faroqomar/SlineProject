

import 'dart:typed_data';

/// Data Transfer Object representing a picked attachment before upload.
class AttachmentPayload {
  /// Original filename provided by the picker.
  final String name;
  /// File extension in lowercase, without dot (e.g. `jpg`).
  final String ext;
  /// Raw bytes of the attachment.
  final Uint8List bytes;
  /// Total size in bytes.
  final int size;

  const AttachmentPayload({
    required this.name,
    required this.ext,
    required this.bytes,
    required this.size,
  });
}

/// Result after uploading an attachment to Storage.
class AttachmentResult {
  /// Storage path inside the private bucket (NOT public URL).
  final String storagePath;
  /// MIME type used when uploading (e.g. `image/jpeg`).
  final String mime;
  /// Size in bytes (may differ from original if compressed).
  final int size;
  /// Original filename kept for display.
  final String name;

  const AttachmentResult({
    required this.storagePath,
    required this.mime,
    required this.size,
    required this.name,
  });
}