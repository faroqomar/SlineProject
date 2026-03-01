import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/logger_service.dart';
import '../models/profile_model.dart';

/// Reads safe cross-user profile summary data through a server-side RPC.
class ProfileSummaryService {
  ProfileSummaryService([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, Map<String, dynamic>>> fetchByIds(
    Iterable<String> userIds, {
    String source = 'unknown',
    String? requestId,
  }) async {
    final ids = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return {};

    try {
      final response = await _client.rpc(
        'rpc_get_profile_summaries',
        params: {'p_ids': ids},
      );

      final summaries = <String, Map<String, dynamic>>{};
      for (final row in (response as List<dynamic>)) {
        final summary = Map<String, dynamic>.from(row as Map);
        final id = summary['id'] as String;
        summaries[id] = summary;
      }
      return summaries;
    } catch (error, stackTrace) {
      AppLogger.e(
        'profile_summary_rpc_failed',
        tag: 'ProfileSummary',
        error: error,
        stackTrace: stackTrace,
      );
      AppLogger.w(
        'profile_summary_rpc_failed',
        tag: 'ProfileSummary',
        json: {
          'source': source,
          'feed_request_id': requestId,
          'requested_profile_count': ids.length,
          'error_type': error.runtimeType.toString(),
        },
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchById(String userId) async {
    final summaries = await fetchByIds([userId]);
    return summaries[userId];
  }

  Future<List<ProfileModel>> searchProfiles({
    required String query,
    String? roleFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    AppLogger.d(
      'profile_search_started',
      tag: 'ProfileSummary',
      json: {
        'query_present': query.trim().isNotEmpty,
        'role_filter_present': roleFilter != null && roleFilter.isNotEmpty,
        'limit': limit,
        'offset': offset,
      },
    );

    try {
      final response = await _client.rpc(
        'search_profiles',
        params: {
          'query': query,
          'role_filter': roleFilter,
          'limit_val': limit,
          'offset_val': offset,
        },
      );

      final results = (response as List<dynamic>)
          .map(
            (row) =>
                ProfileModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();

      AppLogger.i(
        'profile_search_succeeded',
        tag: 'ProfileSummary',
        json: {
          'query_present': query.trim().isNotEmpty,
          'role_filter_present': roleFilter != null && roleFilter.isNotEmpty,
          'limit': limit,
          'offset': offset,
          'result_count': results.length,
        },
      );

      return results;
    } catch (error, stackTrace) {
      AppLogger.e(
        'profile_search_failed',
        tag: 'ProfileSummary',
        error: error,
        stackTrace: stackTrace,
      );
      AppLogger.w(
        'profile_search_failed',
        tag: 'ProfileSummary',
        json: {
          'query_present': query.trim().isNotEmpty,
          'role_filter_present': roleFilter != null && roleFilter.isNotEmpty,
          'limit': limit,
          'offset': offset,
          'error_type': error.runtimeType.toString(),
        },
      );
      rethrow;
    }
  }
}
