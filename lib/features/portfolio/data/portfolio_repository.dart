import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/portfolio_item.dart';
import '../services/portfolio_service.dart';

/// Repository layer for Portfolio feature.
/// Encapsulates Supabase data/storage through PortfolioService.
class PortfolioRepository {
  PortfolioRepository(SupabaseClient client)
    : _service = PortfolioService(client),
      _client = client;

  final PortfolioService _service;
  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<List<PortfolioItem>> listItems({
    required String ownerId,
    int limit = 30,
    String? cursorCreatedAtIso,
  }) {
    return _service.listItems(
      ownerId: ownerId,
      limit: limit,
      cursorCreatedAtIso: cursorCreatedAtIso,
    );
  }

  Future<PortfolioItem> addItem({
    required String ownerId,
    required String title,
    String? description,
    Uint8List? imageBytes,
    String? imageFilename,
  }) {
    return _service.addItem(
      ownerId: ownerId,
      title: title,
      description: description,
      imageBytes: imageBytes,
      imageFilename: imageFilename,
    );
  }

  Future<void> deleteItem({required String id, bool alsoDeleteImage = true}) {
    return _service.deleteItem(id: id, alsoDeleteImage: alsoDeleteImage);
  }

  /// Optional update for editing title/description only.
  Future<void> updateItem({
    required String id,
    required String title,
    String? description,
  }) async {
    await _client
        .from('portfolio_items')
        .update({
          'title': title,
          'description': (description?.trim().isEmpty ?? true)
              ? null
              : description?.trim(),
        })
        .eq('id', id)
        .select()
        .single();
  }
}
