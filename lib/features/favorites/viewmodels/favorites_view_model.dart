// FavoritesViewModel: MVVM state holder for user's favorites
// Moves business logic out of UI and into a ChangeNotifier ViewModel.

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../data/favorites_service.dart';
import '../models/favorite_model.dart';

final _favVmLogger = Logger();

class FavoritesViewModel extends ChangeNotifier {
  final FavoritesService service;

  FavoritesViewModel({required this.service});

  List<FavoriteModel> _items = [];
  List<FavoriteWithProfile> _itemsWithProfile = [];
  bool _loading = false;
  String? _error;

  List<FavoriteModel> get items => _items;
  List<FavoriteWithProfile> get itemsWithProfile => _itemsWithProfile;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _setLoading(true);
    _setError(null);
    try {
      _items = await service.listFavorites();
      final enriched = await service.listFavoritesWithProfile();
      _itemsWithProfile = enriched.map((row) => FavoriteWithProfile.fromMap(row)).toList();
    } catch (e, st) {
      _favVmLogger.e('FavoritesViewModel.load failed', error: e, stackTrace: st);
      _setError(_humanizeError(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() => load();

  Future<void> add(String freelancerId) async {
    _setError(null);
    try {
      await service.addFavorite(freelancerId);
      await load();
    } catch (e, st) {
      _favVmLogger.e('FavoritesViewModel.add failed', error: e, stackTrace: st);
      _setError(_humanizeError(e));
    }
  }

  Future<void> remove(String freelancerId) async {
    _setError(null);
    try {
      await service.removeFavorite(freelancerId);
      _items = _items.where((f) => f.freelancerId != freelancerId).toList();
      _itemsWithProfile = _itemsWithProfile.where((f) => f.freelancerId != freelancerId).toList();
      notifyListeners();
    } catch (e, st) {
      _favVmLogger.e('FavoritesViewModel.remove failed', error: e, stackTrace: st);
      _setError(_humanizeError(e));
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  String _humanizeError(Object e) {
    final s = e.toString();
    if (s.contains('23505')) {
      return 'Already in favorites.';
    }
    if (s.toLowerCase().contains('rls')) {
      return 'Not allowed for your role.';
    }
    if (s.toLowerCase().contains('authenticated')) {
      return 'Please sign in to use favorites.';
    }
    return 'Something went wrong. Please try again.';
  }
}
