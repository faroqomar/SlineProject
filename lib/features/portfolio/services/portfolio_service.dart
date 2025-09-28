import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/portfolio_item.dart';

/// PortfolioService
///
/// Low-level service that talks to Supabase Storage and PostgREST.
/// - Uploads image bytes to `portfolio/<ownerId>/<filename>`
/// - Stores public URL (for public bucket) inside `public.portfolio_items`
/// All comments MUST be in English only.
class PortfolioService {
  PortfolioService(this._client);

  final SupabaseClient _client;

  static const String _table = 'portfolio_items';
  static const String _bucket = 'portfolio';

  /// Lists a user's portfolio items ordered by created_at desc.
  /// Client-side cursor filter for SDKs lacking `.lt()`.
  Future<List<PortfolioItem>> listItems({
    required String ownerId,
    int limit = 30,
    String? cursorCreatedAtIso,
  }) async {
    // Fetch a larger page to safely filter on client if cursor is provided.
    final int take = limit < 100 ? 100 : limit;

    final data = await _client
        .from(_table)
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false)
        .limit(take);

    final all = (data as List<dynamic>)
        .map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
        .toList();

    if (cursorCreatedAtIso == null || cursorCreatedAtIso.isEmpty) {
      return all.take(limit).toList();
    }

    final cursor = DateTime.parse(cursorCreatedAtIso).toUtc();
    final filtered = all.where((it) => it.createdAt.isBefore(cursor)).toList();
    return filtered.take(limit).toList();
  }

  /// Uploads image bytes to Storage and returns the public URL and the storage path.
  /// - [ownerId]: user id to scope files under `portfolio/<ownerId>/...`
  /// - [bytes]: raw image data
  /// - [filename]: original filename or a name with extension (e.g. "photo.jpg")
  Future<({String path, String publicUrl})> _uploadImageBytes({
    required String ownerId,
    required Uint8List bytes,
    required String filename,
  }) async {
    // Derive content-type from filename; fall back to 'application/octet-stream'
    final contentType = lookupMimeType(filename) ?? 'application/octet-stream';

    final safeName =
        '${DateTime.now().millisecondsSinceEpoch}_${filename.replaceAll(RegExp(r"[^A-Za-z0-9._-]"), "_")}';
    final path = '$ownerId/$safeName';

    // Upload (no upsert so we don't overwrite existing files)
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    // Public URL (bucket is public)
    final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);

    return (path: path, publicUrl: publicUrl);
  }

  /// Creates a portfolio item:
  /// 1) Uploads image (if provided) to Storage
  /// 2) Inserts a row into `public.portfolio_items`
  Future<PortfolioItem> addItem({
    required String ownerId,
    required String title,
    String? description,
    Uint8List? imageBytes,
    String? imageFilename, // e.g. "photo.jpg"
  }) async {
    String? imageUrl;

    if (imageBytes != null && imageFilename != null) {
      final res = await _uploadImageBytes(
        ownerId: ownerId,
        bytes: imageBytes,
        filename: imageFilename,
      );
      imageUrl = res.publicUrl;
    }

    final row = await _client.from(_table).insert({
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
    }).select().single();

    return PortfolioItem.fromJson(row as Map<String, dynamic>);
  }

  /// Deletes a portfolio item by id.
  /// If [alsoDeleteImage] is true and the item has an image_url (public),
  /// we attempt to delete the underlying storage object by reconstructing the path.
  Future<void> deleteItem({
    required String id,
    bool alsoDeleteImage = true,
  }) async {
    // Fetch item to find its image_url
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) {
      return;
    }
    final item = PortfolioItem.fromJson(row as Map<String, dynamic>);

    // Delete DB row first (RLS requires owner)
    await _client.from(_table).delete().eq('id', id);

    // Optionally delete storage object if we can infer path from the public URL
    if (alsoDeleteImage && item.imageUrl != null) {
      final url = item.imageUrl!;
      // Public URL pattern contains ".../object/public/portfolio/<owner>/<file>"
      final marker = '/object/public/$_bucket/';
      final idx = url.indexOf(marker);
      if (idx != -1) {
        final path = url.substring(idx + marker.length);
        try {
          await _client.storage.from(_bucket).remove([path]);
        } catch (_) {
          // Ignore storage deletion errors to avoid breaking UX
        }
      }
    }
  }
}
