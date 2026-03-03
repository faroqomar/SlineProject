// FavoritesService - CRUD for Supabase `favorites` table.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../models/favorite_with_profile_model.dart';

class FavoritesService {
  final SupabaseClient _client;

  FavoritesService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      AppLogger.e('Not authenticated', tag: 'Favorites');
      throw StateError('Not authenticated');
    }
    return uid;
  }

  /// Single canonical read: favorites with optional joined freelancer profile.
  /// Root freelancer_id included for null-safe parsing when join is missing.
  Future<List<FavoriteWithProfile>> listFavoritesWithProfile() async {
    final uid = _requireUid();
    AppLogger.d('Loading favorites with profile', tag: 'FavoritesService');
    try {
      final res = await _client
          .from('favorites')
          .select(
            'id, client_id, freelancer_id, created_at, freelancer:freelancer_id(id, full_name, avatar_url)',
          )
          .eq('client_id', uid)
          .order('created_at', ascending: false);

      final list = (res as List)
          .cast<Map<String, dynamic>>()
          .map(FavoriteWithProfile.fromMap)
          .toList();
      AppLogger.i('Loaded ${list.length} favorites', tag: 'FavoritesService');
      return list;
    } catch (e, st) {
      AppLogger.e(
        'Failed to list favorites with profile',
        tag: 'FavoritesService',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Add freelancer to favorites.
  Future<void> addFavorite(String freelancerId) async {
    final uid = _requireUid();
    AppLogger.d('Adding favorite: $freelancerId', tag: 'FavoritesService');
    try {
      await _client.from('favorites').insert({
        'client_id': uid,
        'freelancer_id': freelancerId,
      });
      AppLogger.i('Added favorite: $freelancerId', tag: 'FavoritesService');
    } catch (e, st) {
      AppLogger.e(
        'Failed to add favorite',
        tag: 'FavoritesService',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Remove freelancer from favorites.
  Future<void> removeFavorite(String freelancerId) async {
    final uid = _requireUid();
    AppLogger.d('Removing favorite: $freelancerId', tag: 'FavoritesService');
    try {
      await _client
          .from('favorites')
          .delete()
          .eq('client_id', uid)
          .eq('freelancer_id', freelancerId);
      AppLogger.i('Removed favorite: $freelancerId', tag: 'FavoritesService');
    } catch (e, st) {
      AppLogger.e(
        'Failed to remove favorite',
        tag: 'FavoritesService',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
