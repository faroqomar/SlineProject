// Minimal MIME helpers without adding external dependencies.
// Why: avoid importing `package:mime` across the app and keep logic local.
String guessMimeFromExt(String ext) {
  final e = ext.toLowerCase();
  switch (e) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    default:
      return 'application/octet-stream';
  }
}
