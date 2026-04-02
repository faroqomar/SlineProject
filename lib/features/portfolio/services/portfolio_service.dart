import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../models/portfolio_item.dart';

/// PortfolioService
///
/// Low-level service that talks to Supabase Storage and PostgREST.
/// - Uploads image bytes to `portfolio/<ownerId>/<filename>`
/// - Stores storage path in `image_path` (canonical field)
/// - Maintains backwards compatibility with legacy `image_url` for reads
///
/// Contract: `.TODO/portfolio_contract_2026-03-01.md`
/// All comments MUST be in English only.
class PortfolioService {
  PortfolioService(this._client);

  final SupabaseClient _client;

  static const String _table = 'portfolio_items';
  static const String _bucket = 'portfolio';
  static const String _tag = 'PortfolioService';

  /// Lists a user's portfolio items ordered by created_at desc.
  /// Uses server-side cursor-based pagination with created_at filter.
  Future<List<PortfolioItem>> listItems({
    required String ownerId,
    int limit = 30,
    String? cursorCreatedAtIso,
  }) async {
    AppLogger.d(
      'Listing portfolio items',
      tag: _tag,
      json: {
        'ownerId': ownerId,
        'limit': limit,
        'cursorCreatedAt': cursorCreatedAtIso,
      },
    );

    try {
      // Build the base query
      var query = _client.from(_table).select().eq('owner_id', ownerId);

      // Apply cursor filter for pagination (server-side)
      // Use filter() with 'lt' operator for created_at < cursor
      if (cursorCreatedAtIso != null && cursorCreatedAtIso.isNotEmpty) {
        query = query.filter('created_at', 'lt', cursorCreatedAtIso);
      }

      // Order and limit
      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final items = (data as List<dynamic>)
          .map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.i('Listed ${items.length} portfolio items', tag: _tag);
      return items;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to list portfolio items',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
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
    AppLogger.d(
      'Uploading image bytes',
      tag: _tag,
      json: {
        'ownerId': ownerId,
        'filename': filename,
        'bytesLength': bytes.length,
      },
    );

    // Derive content-type from filename; fall back to 'application/octet-stream'
    final contentType = lookupMimeType(filename) ?? 'application/octet-stream';

    final safeName =
        '${DateTime.now().millisecondsSinceEpoch}_${filename.replaceAll(RegExp(r"[^A-Za-z0-9._-]"), "_")}';
    final path = '$ownerId/$safeName';

    // Upload (no upsert so we don't overwrite existing files)
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    // Public URL (bucket is public)
    final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);

    AppLogger.i('Image uploaded successfully', tag: _tag, json: {'path': path});
    return (path: path, publicUrl: publicUrl);
  }

  /// Creates a portfolio item:
  /// 1) Uploads image (if provided) to Storage
  /// 2) Inserts a row into `public.portfolio_items` with `image_path` (canonical)
  Future<PortfolioItem> addItem({
    required String ownerId,
    required String title,
    String? description,
    Uint8List? imageBytes,
    String? imageFilename, // e.g. "photo.jpg"
  }) async {
    AppLogger.i(
      'Adding portfolio item',
      tag: _tag,
      json: {
        'ownerId': ownerId,
        'title': title,
        'hasImage': imageBytes != null,
      },
    );

    String? imagePath;

    if (imageBytes != null && imageFilename != null) {
      final res = await _uploadImageBytes(
        ownerId: ownerId,
        bytes: imageBytes,
        filename: imageFilename,
      );
      imagePath = res.path; // Store path (canonical), not URL
    }

    try {
      final row = await _client
          .from(_table)
          .insert({
            'owner_id': ownerId,
            'title': title,
            'description': description,
            'image_path': imagePath, // Canonical: store path only
          })
          .select()
          .single();

      final item = PortfolioItem.fromJson(row as Map<String, dynamic>);
      AppLogger.i('Portfolio item created', tag: _tag, json: {'id': item.id});
      return item;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to create portfolio item',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Deletes a portfolio item by id.
  /// Cleans up storage object for both canonical (image_path) and legacy (image_url) formats.
  Future<void> deleteItem({
    required String id,
    bool alsoDeleteImage = true,
  }) async {
    AppLogger.i('Deleting portfolio item', tag: _tag, json: {'id': id});

    // Fetch item to find its image reference
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) {
      AppLogger.w(
        'Portfolio item not found for deletion',
        tag: _tag,
        json: {'id': id},
      );
      return;
    }
    final item = PortfolioItem.fromJson(row as Map<String, dynamic>);

    // Delete DB row first (RLS requires owner)
    await _client.from(_table).delete().eq('id', id);
    AppLogger.i('Deleted portfolio DB row', tag: _tag, json: {'id': id});

    // Optionally delete storage object
    if (alsoDeleteImage) {
      String? storagePath;

      // Prefer canonical image_path
      if (item.imagePath != null) {
        storagePath = item.imagePath;
        AppLogger.d('Using canonical image_path for cleanup', tag: _tag);
      }
      // Fall back to parsing legacy image_url
      else if (item.imageUrl != null) {
        storagePath = _extractPathFromUrl(item.imageUrl!);
        if (storagePath != null) {
          AppLogger.d('Parsed storage path from legacy image_url', tag: _tag);
        }
      }

      if (storagePath != null) {
        try {
          await _client.storage.from(_bucket).remove([storagePath]);
          AppLogger.i(
            'Deleted storage object',
            tag: _tag,
            json: {'path': storagePath},
          );
        } on Exception catch (e) {
          // Log but don't fail UX if storage cleanup fails
          AppLogger.w(
            'Failed to delete storage object (non-critical)',
            tag: _tag,
            error: e,
          );
        }
      } else {
        AppLogger.d('No resolvable storage path for cleanup', tag: _tag);
      }
    }
  }

  /// Extracts storage path from a public URL.
  /// URL pattern: ".../object/public/portfolio/{ownerId}/{filename}"
  String? _extractPathFromUrl(String url) {
    final marker = '/object/public/$_bucket/';
    final idx = url.indexOf(marker);
    if (idx != -1) {
      return url.substring(idx + marker.length);
    }
    return null;
  }

  /// Generates a public URL from a storage path.
  /// For public buckets, this is a simple concatenation.
  String getPublicUrl(String path) {
    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
