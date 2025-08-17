

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Optionally compress images to keep uploads snappy.
class CompressService {
  /// Returns compressed bytes (or original if compression not beneficial/supported).
  Future<Uint8List> maybeCompressImage(Uint8List input, {int quality = 85}) async {
    if (kIsWeb) return input; // plugin not supported on web
    try {
      final out = await FlutterImageCompress.compressWithList(
        input,
        quality: quality.clamp(1, 100),
        keepExif: true,
      );
      if (out.isEmpty) return input;
      // If compression saved less than ~5%, keep original to avoid quality loss
      if (out.length > input.length * 0.95) return input;
      return Uint8List.fromList(out);
    } catch (_) {
      return input;
    }
  }
}