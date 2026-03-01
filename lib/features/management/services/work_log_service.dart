import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/utils/error_mapper.dart';
import '../models/work_log_model.dart';
import '../models/work_log_scope.dart';

class WorkLogService {
  final SupabaseClient _client;

  WorkLogService([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  /// Fetch logs for a specific entity (Task or Booking).
  ///
  /// Includes author profile data via JOIN.
  Future<List<WorkLog>> getLogs(WorkLogScope scope) async {
    try {
      final response = await _client
          .from('work_logs')
          .select('*, profiles!work_logs_author_id_fkey(full_name, avatar_url)')
          .eq('related_entity_id', scope.entityId)
          .eq('related_entity_type', scope.entityType)
          .order('created_at', ascending: true);

      return (response as List).map((e) => WorkLog.fromJson(e)).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to fetch work logs',
        tag: 'Management',
        error: e,
        stackTrace: st,
      );
      throw Exception(_mapReadError(e));
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
    required WorkLogScope scope,
    required String content,
    bool isPrivate = false,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw Exception('User not authenticated');
      final normalizedContent = content.trim();
      if (normalizedContent.isEmpty) {
        throw Exception('Note cannot be empty.');
      }

      await _client.from('work_logs').insert({
        'author_id': uid,
        'related_entity_id': scope.entityId,
        'related_entity_type': scope.entityType,
        'content': normalizedContent,
        'is_private': isPrivate,
        'metadata': metadata,
      });

      AppLogger.i(
        'Work log added',
        tag: 'Management',
        json: {
          'entityType': scope.entityType,
          'isPrivate': isPrivate,
          'hasMetadata': metadata.isNotEmpty,
        },
      );
    } on PostgrestException catch (e, st) {
      AppLogger.e(
        'Failed to add work log',
        tag: 'Management',
        error: e,
        stackTrace: st,
      );
      throw Exception(_mapWriteError(e));
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
    required WorkLogScope scope,
    required String eventType,
    required String description,
    Map<String, dynamic> additionalMetadata = const {},
  }) async {
    return addLog(
      scope: scope,
      content: description,
      isPrivate: false,
      metadata: {'type': eventType, ...additionalMetadata},
    );
  }

  String _mapReadError(PostgrestException error) {
    if (error.code == '42501') {
      return 'You do not have permission to view this order timeline.';
    }
    return ErrorMapper.map(error);
  }

  String _mapWriteError(PostgrestException error) {
    if (error.code == '42501') {
      return 'You cannot post notes to this order.';
    }
    return ErrorMapper.map(error);
  }
}
