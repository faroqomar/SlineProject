import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../services/categories_service.dart';

/// Repository layer for Categories feature.
/// Wraps the underlying CategoriesService and exposes a stable API
/// for ViewModels and UI to consume.
class CategoriesRepository {
  CategoriesRepository(SupabaseClient client)
    : _client = client,
      _service = CategoriesService(client);

  final SupabaseClient _client;
  final CategoriesService _service;

  /// Currently authenticated user (if any)
  User? get currentUser => _client.auth.currentUser;

  /// Returns all categories ordered by name (ascending).
  Future<List<CategoryModel>> getAll({String? search, int limit = 200}) {
    return _service.getAll(search: search, limit: limit);
  }

  /// Returns one category by id or null.
  Future<CategoryModel?> getById(String id) {
    return _service.getById(id);
  }

  /// Returns cached categories if present, otherwise fetches from the server.
  Future<List<CategoryModel>> getCachedOrFetch() {
    return _service.getCachedOrFetch();
  }

  /// Clears in-memory cache.
  void clearCache() {
    _service.clearCache();
  }
}
