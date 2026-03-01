import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../models/portfolio_item.dart';
import '../services/portfolio_service.dart';

/// Repository layer for Portfolio feature.
/// Encapsulates Supabase data/storage through PortfolioService.
///
/// Contract: `.TODO/portfolio_contract_2026-03-01.md`
/// All writes go to `image_path` (canonical), reads fallback to `image_url` (legacy).
class PortfolioRepository {
  PortfolioRepository(SupabaseClient client)
    : _service = PortfolioService(client),
      _client = client;

  final PortfolioService _service;
  final SupabaseClient _client;
  static const String _tag = 'PortfolioRepository';

  User? get currentUser => _client.auth.currentUser;

  /// Lists portfolio items for a user with pagination.
  Future<List<PortfolioItem>> listItems({
    required String ownerId,
    int limit = 30,
    String? cursorCreatedAtIso,
  }) async {
    AppLogger.d('Repository: listItems', tag: _tag, json: {
      'ownerId': ownerId,
      'limit': limit,
    });
    try {
      return await _service.listItems(
        ownerId: ownerId,
        limit: limit,
        cursorCreatedAtIso: cursorCreatedAtIso,
      );
    } catch (e, st) {
      AppLogger.e('Repository: listItems failed', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Adds a new portfolio item with optional image.
  Future<PortfolioItem> addItem({
    required String ownerId,
    required String title,
    String? description,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    AppLogger.i('Repository: addItem', tag: _tag, json: {
      'ownerId': ownerId,
      'title': title,
    });
    try {
      return await _service.addItem(
        ownerId: ownerId,
        title: title,
        description: description,
        imageBytes: imageBytes,
        imageFilename: imageFilename,
      );
    } catch (e, st) {
      AppLogger.e('Repository: addItem failed', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a portfolio item and optionally its image.
  Future<void> deleteItem({required String id, bool alsoDeleteImage = true}) async {
    AppLogger.i('Repository: deleteItem', tag: _tag, json: {'id': id});
    try {
      return await _service.deleteItem(id: id, alsoDeleteImage: alsoDeleteImage);
    } catch (e, st) {
      AppLogger.e('Repository: deleteItem failed', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates title and description of a portfolio item.
  Future<void> updateItem({
    required String id,
    required String title,
    String? description,
  }) async {
    AppLogger.i('Repository: updateItem', tag: _tag, json: {
      'id': id,
      'title': title,
    });
    try {
      await _client
          .from('portfolio_items')
          .update({
            'title': title,
            'description': (description?.trim().isEmpty ?? true)
                ? null
                : description?.trim(),
          })
          .eq('id', id);
      AppLogger.i('Repository: updateItem success', tag: _tag);
    } catch (e, st) {
      AppLogger.e('Repository: updateItem failed', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Generates a public URL for a portfolio image path.
  /// For public buckets, this returns the direct URL.
  String getImageUrl(String path) {
    return _service.getPublicUrl(path);
  }
}
