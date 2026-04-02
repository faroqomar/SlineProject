import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../data/portfolio_repository.dart';
import '../models/portfolio_item.dart';

/// PortfolioViewModel — MVVM state holder for Portfolio feature.
///
/// Contract: `.TODO/portfolio_contract_2026-03-01.md`
/// Manages portfolio list state, pagination, and CRUD operations.
class PortfolioViewModel extends ChangeNotifier {
  /// Creates with explicit repository (preferred for testing/dependency injection).
  PortfolioViewModel({PortfolioRepository? repository, SupabaseClient? client})
    : _repo =
          repository ?? PortfolioRepository(client ?? Supabase.instance.client),
      _tag = 'PortfolioVM' {
    AppLogger.d('PortfolioViewModel created', tag: _tag);
  }

  final PortfolioRepository _repo;
  final String _tag;

  String? _ownerId;
  String? get ownerId => _ownerId;

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
    AppLogger.d('PortfolioViewModel disposed', tag: _tag);
    super.dispose();
  }

  void _notify() {
    if (_mounted) notifyListeners();
  }

  void _setError(Object? e) {
    _error = e?.toString();
    AppLogger.w('Error set: $_error', tag: _tag);
  }

  void _clearError() => _error = null;

  /// Loads the initial page of portfolio items.
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

    AppLogger.i(
      'Loading portfolio',
      tag: _tag,
      json: {'ownerId': uid, 'pageSize': pageSize},
    );

    try {
      final page = await _repo.listItems(ownerId: _ownerId!, limit: pageSize);
      _items.addAll(page);
      if (_items.isNotEmpty) {
        _cursorCreatedAtIso = _items.last.createdAt.toIso8601String();
      }
      _hasMore = page.length >= pageSize;
      AppLogger.i(
        'Loaded ${page.length} portfolio items',
        tag: _tag,
        json: {'totalItems': _items.length, 'hasMore': _hasMore},
      );
    } on Exception catch (e, st) {
      _setError(e);
      AppLogger.e(
        'Failed to load portfolio',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      _hasMore = false;
    } finally {
      _initialLoading = false;
      _notify();
    }
  }

  /// Loads the next page of portfolio items.
  Future<void> loadMore({int pageSize = 30}) async {
    if (_ownerId == null) {
      AppLogger.w('loadMore called without ownerId', tag: _tag);
      return;
    }
    if (!_hasMore) {
      AppLogger.d('loadMore: no more items', tag: _tag);
      return;
    }
    if (_loadingMore) {
      AppLogger.d('loadMore: already loading', tag: _tag);
      return;
    }

    _loadingMore = true;
    _clearError();
    _notify();

    AppLogger.i(
      'Loading more portfolio items',
      tag: _tag,
      json: {'cursor': _cursorCreatedAtIso, 'pageSize': pageSize},
    );

    try {
      final page = await _repo.listItems(
        ownerId: _ownerId!,
        limit: pageSize,
        cursorCreatedAtIso: _cursorCreatedAtIso,
      );
      _items.addAll(page);
      if (page.isNotEmpty) {
        _cursorCreatedAtIso = page.last.createdAt.toIso8601String();
      }
      _hasMore = page.length >= pageSize;
      AppLogger.i(
        'Loaded ${page.length} more items',
        tag: _tag,
        json: {'totalItems': _items.length, 'hasMore': _hasMore},
      );
    } on Exception catch (e, st) {
      _setError(e);
      AppLogger.e(
        'Failed to load more portfolio items',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      _hasMore = false;
    } finally {
      _loadingMore = false;
      _notify();
    }
  }

  /// Adds a new portfolio item.
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

    AppLogger.i(
      'Adding portfolio item',
      tag: _tag,
      json: {'title': title, 'hasImage': imageBytes != null},
    );

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
      AppLogger.i('Added portfolio item: ${created.id}', tag: _tag);
      _notify();
      return true;
    } on Exception catch (e, st) {
      _setError(e);
      AppLogger.e(
        'Failed to add portfolio item',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      _notify();
      return false;
    }
  }

  /// Deletes a portfolio item by id.
  Future<bool> deleteItem(String id) async {
    _clearError();
    _notify();

    AppLogger.i('Deleting portfolio item', tag: _tag, json: {'id': id});

    try {
      await _repo.deleteItem(id: id, alsoDeleteImage: true);
      final idx = _items.indexWhere((it) => it.id == id);
      if (idx != -1) {
        _items.removeAt(idx);
        AppLogger.i('Removed item from local list: $id', tag: _tag);
      }
      _notify();
      return true;
    } on Exception catch (e, st) {
      _setError(e);
      AppLogger.e(
        'Failed to delete item $id',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      _notify();
      return false;
    }
  }

  /// Updates a portfolio item's title and description.
  Future<bool> updateItem({
    required String id,
    required String title,
    String? description,
  }) async {
    AppLogger.i(
      'Updating portfolio item',
      tag: _tag,
      json: {'id': id, 'title': title},
    );

    try {
      await _repo.updateItem(id: id, title: title, description: description);
      final idx = _items.indexWhere((it) => it.id == id);
      if (idx != -1) {
        _items[idx] = _items[idx].copyWith(
          title: title,
          description: description,
        );
        AppLogger.i('Updated local item: $id', tag: _tag);
      }
      _notify();
      return true;
    } on Exception catch (e, st) {
      _setError(e);
      AppLogger.e(
        'Failed to update item $id',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      _notify();
      return false;
    }
  }

  /// Gets the public URL for a portfolio item's image.
  /// Returns null if the item has no image.
  String? getImageUrl(PortfolioItem item) {
    if (item.imagePath != null) {
      return _repo.getImageUrl(item.imagePath!);
    }
    // Legacy fallback
    return item.imageUrl;
  }

  /// Refreshes the list from the beginning.
  Future<void> refresh() async {
    AppLogger.i('Refreshing portfolio list', tag: _tag);
    return load(ownerId: _ownerId);
  }

  /// Clears all state (useful for logout/sign-out scenarios).
  void clear() {
    AppLogger.i('Clearing portfolio state', tag: _tag);
    _ownerId = null;
    _items.clear();
    _cursorCreatedAtIso = null;
    _hasMore = true;
    _clearError();
    _notify();
  }
}
