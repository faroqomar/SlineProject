

// FavoritesService: handles CRUD against Supabase `favorites` table.
// Uses auth.uid() from Supabase to infer the current client.
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/favorite_model.dart';

final _favLogger = Logger();

class FavoritesService {
  final SupabaseClient _client;

  FavoritesService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Returns the current authenticated user id or throws if not signed in.
  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      _favLogger.e('FavoritesService: No authenticated user.');
      throw StateError('Not authenticated');
    }
    return uid;
  }

  /// List current user's favorites ordered by created_at desc.
  Future<List<FavoriteModel>> listFavorites() async {
    final uid = _requireUid();
    try {
      final res = await _client
          .from('favorites')
          .select()
          .eq('client_id', uid)
          .order('created_at', ascending: false);

      final list = (res as List)
          .cast<Map<String, dynamic>>()
          .map(FavoriteModel.fromMap)
          .toList();
      return list;
    } on PostgrestException catch (e, st) {
      _favLogger.e('listFavorites PostgrestException', error: e, stackTrace: st);
      rethrow;
    } catch (e, st) {
      _favLogger.e('listFavorites unknown error', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// List current user's favorites joined with freelancer profile info.
  Future<List<Map<String, dynamic>>> listFavoritesWithProfile() async {
    final uid = _requireUid();
    try {
      final res = await _client
          .from('favorites')
          .select('created_at, freelancer:freelancer_id (id, full_name, avatar_url)')
          .eq('client_id', uid)
          .order('created_at', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e, st) {
      _favLogger.e('listFavoritesWithProfile PostgrestException', error: e, stackTrace: st);
      rethrow;
    } catch (e, st) {
      _favLogger.e('listFavoritesWithProfile unknown error', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Add freelancer to current user's favorites.
  /// RLS requires client_id == auth.uid(); we send both explicitly.
  Future<void> addFavorite(String freelancerId) async {
    final uid = _requireUid();
    try {
      await _client.from('favorites').insert({
        'client_id': uid,
        'freelancer_id': freelancerId,
      });
    } on PostgrestException catch (e, st) {
      _favLogger.e('addFavorite PostgrestException', error: e, stackTrace: st);
      rethrow;
    } catch (e, st) {
      _favLogger.e('addFavorite unknown error', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Remove freelancer from current user's favorites.
  Future<void> removeFavorite(String freelancerId) async {
    final uid = _requireUid();
    try {
      await _client
          .from('favorites')
          .delete()
          .eq('client_id', uid)
          .eq('freelancer_id', freelancerId);
    } on PostgrestException catch (e, st) {
      _favLogger.e('removeFavorite PostgrestException', error: e, stackTrace: st);
      rethrow;
    } catch (e, st) {
      _favLogger.e('removeFavorite unknown error', error: e, stackTrace: st);
      rethrow;
    }
  }
}