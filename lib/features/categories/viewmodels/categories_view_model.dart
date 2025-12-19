import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../data/categories_repository.dart';
import '../models/category_model.dart';

/// CategoriesViewModel
/// MVVM state holder for listing and searching categories.
class CategoriesViewModel extends ChangeNotifier {
  CategoriesViewModel({CategoriesRepository? repository})
    : _repository =
          repository ?? CategoriesRepository(Supabase.instance.client);

  final CategoriesRepository _repository;

  final List<CategoryModel> _items = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Read-only getters for UI
  List<CategoryModel> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  /// Load categories from repository. Optionally apply a search query.
  Future<void> load({String? search}) async {
    _setLoading(true);
    try {
      final data = await _repository.getAll(search: search);
      _items
        ..clear()
        ..addAll(data);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load categories';
      AppLogger.e('CategoriesViewModel.load error: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Refreshes using the current search query.
  Future<void> refresh() =>
      load(search: _searchQuery.isEmpty ? null : _searchQuery);

  /// Updates the current search query and reloads the list.
  Future<void> setSearchQuery(String q) async {
    _searchQuery = q;
    await load(search: q.trim().isEmpty ? null : q);
  }

  /// Clears cached data in the repository service (if any)
  void clearCache() => _repository.clearCache();
}
