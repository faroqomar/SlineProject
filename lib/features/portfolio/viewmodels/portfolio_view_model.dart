import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/portfolio_repository.dart';
import '../models/portfolio_item.dart';
import 'package:sline_app/core/services/logger_service.dart';

/// PortfolioViewModel — MVVM state holder for Portfolio feature.
class PortfolioViewModel extends ChangeNotifier {
  PortfolioViewModel({SupabaseClient? client})
    : _repo = PortfolioRepository(client ?? Supabase.instance.client);

  final PortfolioRepository _repo;

  String? _ownerId;

  final List<PortfolioItem> _items = [];
  List<PortfolioItem> get items => List.unmodifiable(_items);

  bool _initialLoading = false;
  bool get initialLoading => _initialLoading;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  String? _error;
  String? get error => _error;

  String? _cursorCreatedAtIso;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _mounted = true;
  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _notify() {
    if (_mounted) notifyListeners();
  }

  void _setError(Object? e) => _error = e?.toString();
  void _clearError() => _error = null;

  Future<void> load({String? ownerId, int pageSize = 30}) async {
    final uid = ownerId ?? _repo.currentUser?.id;
    if (uid == null) {
      _setError('Not authenticated');
      _notify();
      return;
    }
    _ownerId = uid;

    _initialLoading = true;
    _loadingMore = false;
    _cursorCreatedAtIso = null;
    _hasMore = true;
    _clearError();
    _items.clear();
    _notify();

    try {
      final page = await _repo.listItems(ownerId: _ownerId!, limit: pageSize);
      _items.addAll(page);
      if (_items.isNotEmpty) {
        _cursorCreatedAtIso = _items.last.createdAt.toIso8601String();
      }
      _hasMore = page.length >= pageSize;
      AppLogger.i('Loaded ${page.length} portfolio items', tag: 'Portfolio');
    } catch (e) {
      _setError(e);
      AppLogger.e('Failed to load portfolio', tag: 'Portfolio', error: e);
      _hasMore = false;
    } finally {
      _initialLoading = false;
      _notify();
    }
  }

  Future<void> loadMore({int pageSize = 30}) async {
    if (_ownerId == null) return;
    if (!_hasMore) return;
    if (_loadingMore) return;

    _loadingMore = true;
    _clearError();
    _notify();

    try {
      final page = await _repo.listItems(
        ownerId: _ownerId!,
        limit: pageSize,
        cursorCreatedAtIso: _cursorCreatedAtIso,
      );
      _items.addAll(page);
      if (_items.isNotEmpty) {
        _cursorCreatedAtIso = _items.last.createdAt.toIso8601String();
      }
      _hasMore = page.length >= pageSize;
    } catch (e) {
      _setError(e);
      AppLogger.e(
        'Failed to load more portfolio items',
        tag: 'Portfolio',
        error: e,
      );
      _hasMore = false;
    } finally {
      _loadingMore = false;
      _notify();
    }
  }

  Future<bool> addItem({
    required String title,
    String? description,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    final uid = _ownerId ?? _repo.currentUser?.id;
    if (uid == null) {
      _setError('Not authenticated');
      _notify();
      return false;
    }
    _clearError();
    _notify();
    try {
      final created = await _repo.addItem(
        ownerId: uid,
        title: title,
        description: description,
        imageBytes: imageBytes,
        imageFilename: imageFilename,
      );
      _items.insert(0, created);
      if (_cursorCreatedAtIso == null && _items.isNotEmpty) {
        _cursorCreatedAtIso = _items.last.createdAt.toIso8601String();
      }
      AppLogger.i('Added portfolio item: ${created.id}', tag: 'Portfolio');
      _notify();
      return true;
    } catch (e) {
      _setError(e);
      AppLogger.e('Failed to add portfolio item', tag: 'Portfolio', error: e);
      _notify();
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    _clearError();
    _notify();
    try {
      await _repo.deleteItem(id: id, alsoDeleteImage: true);
      final idx = _items.indexWhere((it) => it.id == id);
      if (idx != -1) _items.removeAt(idx);
      AppLogger.i('Deleted portfolio item: $id', tag: 'Portfolio');
      _notify();
      return true;
    } catch (e) {
      _setError(e);
      AppLogger.e('Failed to delete item $id', tag: 'Portfolio', error: e);
      _notify();
      return false;
    }
  }

  Future<bool> updateItem({
    required String id,
    required String title,
    String? description,
  }) async {
    try {
      await _repo.updateItem(id: id, title: title, description: description);
      final idx = _items.indexWhere((it) => it.id == id);
      if (idx != -1) {
        _items[idx] = _items[idx].copyWith(
          title: title,
          description: description,
        );
      }
      _notify();
      return true;
    } catch (e) {
      _setError(e);
      AppLogger.e('Failed to update item $id', tag: 'Portfolio', error: e);
      _notify();
      return false;
    }
  }
}
