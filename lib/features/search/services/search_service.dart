import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/features/profile/models/profile_model.dart';
import 'package:sline_app/features/profile/services/profile_summary_service.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SearchService
///
/// Handles search operations for Tasks and Profiles using database RPC functions.
/// Implements manual batch fetching for related data (Profiles, Categories)
/// to avoid N+1 queries since RPCs return raw table rows without joins.
class SearchService {
  final SupabaseClient _client;
  late final ProfileSummaryService _profileSummaryService;

  SearchService([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client {
    _profileSummaryService = ProfileSummaryService(_client);
  }

  /// Search tasks using Full Text Search RPC
  ///
  /// Returns a list of [Task] populated with author profile and category name.
  Future<List<Task>> searchTasks({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client.rpc(
        'search_tasks',
        params: {'query': query, 'limit_val': limit, 'offset_val': offset},
      );

      final rows = response as List;
      if (rows.isEmpty) return [];

      // Collect IDs for batch fetching
      final userIds = <String>{};
      final categoryIds = <String>{};

      for (final row in rows) {
        if (row['user_id'] != null) userIds.add(row['user_id'] as String);
        if (row['category_id'] != null) {
          categoryIds.add(row['category_id'] as String);
        }
      }

      final results = await Future.wait([
        _fetchProfilesByIds(userIds),
        _fetchCategoriesByIds(categoryIds),
      ]);

      final profilesMap = results[0];
      final categoriesMap = results[1];

      return rows.map((json) {
        final taskJson = Map<String, dynamic>.from(json as Map);
        final userId = taskJson['user_id'] as String?;
        final categoryId = taskJson['category_id'] as String?;

        // Enrich with Profile data
        if (userId != null && profilesMap.containsKey(userId)) {
          taskJson['profiles'] = profilesMap[userId];
        }

        // Enrich with Category data
        // Task.fromJson looks for 'categories' map with 'name' inside
        if (categoryId != null && categoriesMap.containsKey(categoryId)) {
          taskJson['categories'] = categoriesMap[categoryId];
        }

        return Task.fromJson(taskJson);
      }).toList();
    } on Exception catch (e, st) {
      AppLogger.e('Search tasks failed', error: e, stackTrace: st);
      // Return empty list on search error? Or rethrow?
      // Rethrowing allows VM to show error state.
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Search profiles using Full Text Search RPC
  Future<List<ProfileModel>> searchProfiles({
    required String query,
    String? roleFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _profileSummaryService.searchProfiles(
        query: query,
        roleFilter: roleFilter,
        limit: limit,
        offset: offset,
      );
    } on Exception catch (e, st) {
      AppLogger.e('Search profiles failed', error: e, stackTrace: st);
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Batch fetch profiles
  Future<Map<String, Map<String, dynamic>>> _fetchProfilesByIds(
    Set<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    try {
      return await _profileSummaryService.fetchByIds(userIds);
    } on Exception catch (e) {
      AppLogger.w('Failed to enrich search results with profiles: $e');
      return {};
    }
  }

  /// Batch fetch categories
  Future<Map<String, Map<String, dynamic>>> _fetchCategoriesByIds(
    Set<String> categoryIds,
  ) async {
    if (categoryIds.isEmpty) return {};
    try {
      final response = await _client
          .from('categories')
          .select('id, name')
          .in_('id', categoryIds.toList());

      final map = <String, Map<String, dynamic>>{};
      for (final row in (response as List)) {
        map[row['id'] as String] = row as Map<String, dynamic>;
      }
      return map;
    } on Exception catch (e) {
      AppLogger.w('Failed to enrich search results with categories: $e');
      return {};
    }
  }
}
