// FavoritesViewModel: MVVM state holder for user's favorites.
// Single canonical read (listFavoritesWithProfile), typed mutation results, AppLogger.

import 'package:flutter/foundation.dart';

import '../../../core/services/logger_service.dart';
import '../data/favorites_service.dart';
import '../models/favorite_model.dart';
import '../models/favorite_with_profile_model.dart';
import '../models/favorites_mutation_result.dart';

class FavoritesViewModel extends ChangeNotifier {
  final FavoritesService service;

  FavoritesViewModel({required this.service});

  List<FavoriteModel> _items = [];
  List<FavoriteWithProfile> _itemsWithProfile = [];
  bool _loading = false;
  String? _error;
  bool _loadedOnce = false;
  final Set<String> _pendingIds = {};

  List<FavoriteModel> get items => _items;
  List<FavoriteWithProfile> get itemsWithProfile => _itemsWithProfile;
  bool get isLoading => _loading;
  String? get error => _error;
  bool isPending(String freelancerId) => _pendingIds.contains(freelancerId);

  /// Ensures favorites are loaded at least once (e.g. for public profile toggle).
  Future<void> ensureLoaded() async {
    if (_loadedOnce) {
      AppLogger.d(
        'ensureLoaded: skip (already loaded)',
        tag: 'FavoritesViewModel',
      );
      return;
    }
    if (_loading) {
      return;
    }
    AppLogger.d('ensureLoaded: loading', tag: 'FavoritesViewModel');
    await load();
  }

  Future<void> load() async {
    _setLoading(true);
    _setError(null);
    AppLogger.d('Load favorites start', tag: 'FavoritesViewModel');
    try {
      final list = await service.listFavoritesWithProfile();
      _itemsWithProfile = list;
      _items = list
          .map(
            (f) => FavoriteModel(
              id: f.id,
              freelancerId: f.freelancerId,
              createdAt: f.createdAt,
            ),
          )
          .toList();
      _loadedOnce = true;
      AppLogger.i(
        'Load favorites success: ${list.length} items',
        tag: 'FavoritesViewModel',
      );
    } catch (e, st) {
      AppLogger.e(
        'Failed to load favorites',
        tag: 'FavoritesViewModel',
        error: e,
        stackTrace: st,
      );
      _setError(_humanizeError(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() => load();

  Future<FavoritesMutationResult> add(String freelancerId) async {
    if (_pendingIds.contains(freelancerId)) {
      AppLogger.d(
        'Add skipped (pending): $freelancerId',
        tag: 'FavoritesViewModel',
      );
      return FavoritesMutationResult.skipped;
    }
    _setError(null);
    _pendingIds.add(freelancerId);
    notifyListeners();
    AppLogger.d('Add favorite: $freelancerId', tag: 'FavoritesViewModel');
    try {
      await service.addFavorite(freelancerId);
      await load();
      _pendingIds.remove(freelancerId);
      notifyListeners();
      AppLogger.i(
        'Add favorite success: $freelancerId',
        tag: 'FavoritesViewModel',
      );
      return FavoritesMutationResult.success;
    } catch (e, st) {
      _pendingIds.remove(freelancerId);
      notifyListeners();
      AppLogger.e(
        'Failed to add favorite',
        tag: 'FavoritesViewModel',
        error: e,
        stackTrace: st,
      );
      _setError(_humanizeError(e));
      return _mapErrorToResult(e);
    }
  }

  Future<FavoritesMutationResult> remove(String freelancerId) async {
    if (_pendingIds.contains(freelancerId)) {
      AppLogger.d(
        'Remove skipped (pending): $freelancerId',
        tag: 'FavoritesViewModel',
      );
      return FavoritesMutationResult.skipped;
    }
    _setError(null);
    _pendingIds.add(freelancerId);
    notifyListeners();
    AppLogger.d('Remove favorite: $freelancerId', tag: 'FavoritesViewModel');
    try {
      await service.removeFavorite(freelancerId);
      _items = _items.where((f) => f.freelancerId != freelancerId).toList();
      _itemsWithProfile = _itemsWithProfile
          .where((f) => f.freelancerId != freelancerId)
          .toList();
      _pendingIds.remove(freelancerId);
      notifyListeners();
      AppLogger.i(
        'Remove favorite success: $freelancerId',
        tag: 'FavoritesViewModel',
      );
      return FavoritesMutationResult.success;
    } catch (e, st) {
      _pendingIds.remove(freelancerId);
      notifyListeners();
      AppLogger.e(
        'Failed to remove favorite',
        tag: 'FavoritesViewModel',
        error: e,
        stackTrace: st,
      );
      _setError(_humanizeError(e));
      return _mapErrorToResult(e);
    }
  }

  FavoritesMutationResult _mapErrorToResult(Object e) {
    final s = e.toString();
    if (s.contains('23505')) return FavoritesMutationResult.duplicate;
    if (s.toLowerCase().contains('rls') ||
        s.toLowerCase().contains('forbidden')) {
      return FavoritesMutationResult.forbidden;
    }
    if (s.toLowerCase().contains('authenticated') ||
        s.toLowerCase().contains('sign in')) {
      return FavoritesMutationResult.unauthenticated;
    }
    return FavoritesMutationResult.failure;
  }

  void _setLoading(bool v) {
    if (_loading == v) return;
    _loading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    if (_error == msg) return;
    _error = msg;
    notifyListeners();
  }

  String _humanizeError(Object e) {
    final s = e.toString();
    if (s.contains('23505')) return 'Already in favorites.';
    if (s.toLowerCase().contains('rls')) return 'Not allowed for your role.';
    if (s.toLowerCase().contains('authenticated')) {
      return 'Please sign in to use favorites.';
    }
    return 'Something went wrong. Please try again.';
  }
}
