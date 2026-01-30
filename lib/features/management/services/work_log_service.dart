import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/utils/error_mapper.dart';
import '../models/work_log_model.dart';

class WorkLogService {
  final SupabaseClient _client;

  WorkLogService([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  /// Fetch logs for a specific entity (Task or Booking).
  ///
  /// Includes author profile data via JOIN.
  Future<List<WorkLog>> getLogs(String entityId) async {
    try {
      // Using !inner implies author must exist (which is enforced by FK)
      // Using profiles!work_logs_author_id_fkey to disambiguate if multiple FKs exist,
      // though typically standard 'profiles' works if unique.
      // We'll use the specific hint to be safe.
      final response = await _client
          .from('work_logs')
          .select('*, profiles!work_logs_author_id_fkey(full_name, avatar_url)')
          .eq('related_entity_id', entityId)
          .order('created_at', ascending: true);

      return (response as List).map((e) => WorkLog.fromJson(e)).toList();
    } catch (e, st) {
      AppLogger.e(
        'Failed to fetch work logs',
        tag: 'Management',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Add a new log entry.
  Future<void> addLog({
    required String entityId,
    required String entityType,
    required String content,
    bool isPrivate = false,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw Exception('User not authenticated');

      await _client.from('work_logs').insert({
        'author_id': uid,
        'related_entity_id': entityId,
        'related_entity_type': entityType,
        'content': content,
        'is_private': isPrivate,
        'metadata': metadata,
      });

      AppLogger.i('Work log added: $content', tag: 'Management');
    } catch (e, st) {
      AppLogger.e(
        'Failed to add work log',
        tag: 'Management',
        error: e,
        stackTrace: st,
      );
      throw Exception(ErrorMapper.map(e));
    }
  }

  /// Helper to log a system event (e.g. "Extension Requested")
  Future<void> logEvent({
    required String entityId,
    required String entityType,
    required String eventType,
    required String description,
    Map<String, dynamic> additionalMetadata = const {},
  }) async {
    return addLog(
      entityId: entityId,
      entityType: entityType,
      content: description,
      isPrivate: false,
      metadata: {'type': eventType, ...additionalMetadata},
    );
  }
}
