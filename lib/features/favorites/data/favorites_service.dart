// FavoritesService - CRUD for Supabase `favorites` table.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../models/favorite_model.dart';

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

  /// List current user's favorites.
  Future<List<FavoriteModel>> listFavorites() async {
    final uid = _requireUid();
    try {
      final res = await _client
          .from('favorites')
          .select()
          .eq('client_id', uid)
          .order('created_at', ascending: false);

      return (res as List)
          .cast<Map<String, dynamic>>()
          .map(FavoriteModel.fromMap)
          .toList();
    } catch (e, st) {
      AppLogger.e(
        'Failed to list favorites',
        tag: 'Favorites',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// List favorites with freelancer profile info.
  Future<List<Map<String, dynamic>>> listFavoritesWithProfile() async {
    final uid = _requireUid();
    try {
      final res = await _client
          .from('favorites')
          .select(
            'created_at, freelancer:freelancer_id (id, full_name, avatar_url)',
          )
          .eq('client_id', uid)
          .order('created_at', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      AppLogger.e(
        'Failed to list favorites with profile',
        tag: 'Favorites',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Add freelancer to favorites.
  Future<void> addFavorite(String freelancerId) async {
    final uid = _requireUid();
    try {
      await _client.from('favorites').insert({
        'client_id': uid,
        'freelancer_id': freelancerId,
      });
    } catch (e, st) {
      AppLogger.e(
        'Failed to add favorite',
        tag: 'Favorites',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Remove freelancer from favorites.
  Future<void> removeFavorite(String freelancerId) async {
    final uid = _requireUid();
    try {
      await _client
          .from('favorites')
          .delete()
          .eq('client_id', uid)
          .eq('freelancer_id', freelancerId);
    } catch (e, st) {
      AppLogger.e(
        'Failed to remove favorite',
        tag: 'Favorites',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
