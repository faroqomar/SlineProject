// Attachment pipeline exceptions
// Why: explicit, typed errors make the flow easier to debug and test.

class AttachmentPickCancelled implements Exception {
  @override
  String toString() => 'AttachmentPickCancelled';
}

class AttachmentValidationError implements Exception {
  final String message;
  AttachmentValidationError(this.message);
  @override
  String toString() => 'AttachmentValidationError: $message';
}

class AttachmentUploadError implements Exception {
  final String message;
  AttachmentUploadError(this.message);
  @override
  String toString() => 'AttachmentUploadError: $message';
}