import 'package:sline_app/features/categories/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CategoriesService
///
/// Read-only service for fetching categories from `public.categories`.
/// RLS policy allows SELECT for authenticated users only; writes are admin-only.
/// All comments MUST be in English only.
class CategoriesService {
  CategoriesService(this._client);

  final SupabaseClient _client;

  static const String _table = 'categories';

  /// Simple in-memory cache to avoid refetching on every screen open.
  /// You can invalidate this manually with [clearCache].
  List<CategoryModel>? _cache;

  /// Returns all categories ordered by `name ASC`.
  /// - Optional [search] will filter by name on the client (case-insensitive).
  /// - Limits to [limit] rows (defaults to 200).
  Future<List<CategoryModel>> getAll({String? search, int limit = 200}) async {
    final query = _client
        .from(_table)
        .select()
        .order('name', ascending: true)
        .limit(limit);

    // Fetch from server without server-side filtering to keep SDK compatibility
    final data = await query;

    final list = (data as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Update local cache only for unfiltered queries
    if (search == null || search.trim().isEmpty) {
      _cache = list;
      return list;
    }

    // Client-side case-insensitive filter for SDKs lacking `.filter/.ilike`
    final q = search.trim().toLowerCase();
    return list.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  /// Returns a category by id or null if not found.
  Future<CategoryModel?> getById(String id) async {
    // Try cache first
    final local = _cache?.firstWhere(
      (c) => c.id == id,
      orElse: () => CategoryModel(
        id: '',
        name: '',
        iconUrl: null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
    );
    if (local != null && local.id.isNotEmpty) return local;

    final row = await _client.from(_table).select().eq('id', id).maybeSingle();

    if (row == null) return null;
    return CategoryModel.fromJson(row as Map<String, dynamic>);
  }

  /// Returns cached categories if present, otherwise fetches from the server.
  Future<List<CategoryModel>> getCachedOrFetch() async {
    if (_cache != null) return _cache!;
    return getAll();
  }

  /// Clears the in-memory cache (next call will fetch fresh data).
  void clearCache() {
    _cache = null;
  }
}
