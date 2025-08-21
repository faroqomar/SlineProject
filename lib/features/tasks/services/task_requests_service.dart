library task_requests_service;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logger_service.dart';
import '../models/task_request_model.dart';

class TaskRequestsService {
  final SupabaseClient _client;

  TaskRequestsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<TaskRequest>> listByTask({
    required String taskId,
    int limit = 20,
    DateTime? before,
  }) async {
    AppLogger.d('[TaskRequestsService] listByTask start taskId=$taskId before=$before limit=$limit');

    try {
      final query = _client
          .from('task_requests')
          .select()
          .eq('task_id', taskId);

      if (before != null) {
        query.lt('created_at', before.toUtc().toIso8601String());
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final result = (data as List<dynamic>)
          .map((e) => TaskRequest.fromMap(e as Map<String, dynamic>))
          .toList();

      AppLogger.i('[TaskRequestsService] listByTask ok count=${result.length}');
      return result;
    } on PostgrestException catch (e, st) {
      AppLogger.e('[TaskRequestsService] listByTask PostgrestException', e, st);
      rethrow;
    } catch (e, st) {
      AppLogger.e('[TaskRequestsService] listByTask Unknown error', e, st);
      rethrow;
    }
  }

  Future<TaskRequest> submitOffer({
    required String taskId,
    required double price,
    required int days,
    String? note,
  }) async {
    AppLogger.d('[TaskRequestsService] submitOffer start taskId=$taskId price=$price days=$days');

    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      final err = Exception('Not authenticated');
      AppLogger.e('[TaskRequestsService] submitOffer no auth user', err);
      throw err;
    }

    try {
      final insertData = <String, dynamic>{
        'task_id': taskId,
        'bidder_id': uid,
        'price': price,
        'days': days,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final inserted = await _client
          .from('task_requests')
          .insert(insertData)
          .select()
          .single();

      final model = TaskRequest.fromMap(inserted as Map<String, dynamic>);
      AppLogger.i('[TaskRequestsService] submitOffer ok id=${model.id}');
      return model;
    } on PostgrestException catch (e, st) {
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('ux_task_requests_pending_per_user') ||
          (msg.contains('duplicate key') && msg.contains('task_id') && msg.contains('bidder_id'))) {
        final friendly = Exception('You already have a pending offer on this task.');
        AppLogger.w('[TaskRequestsService] submitOffer duplicate pending');
        throw friendly;
      }
      AppLogger.e('[TaskRequestsService] submitOffer PostgrestException', e, st);
      rethrow;
    } catch (e, st) {
      AppLogger.e('[TaskRequestsService] submitOffer Unknown error', e, st);
      rethrow;
    }
  }

  Future<TaskRequest> accept(String requestId) async {
    AppLogger.d('[TaskRequestsService] accept start requestId=$requestId');
    try {
      final res = await _client.rpc('accept_task_request', params: {
        'p_request_id': requestId,
      });

      final map = (res as Map<String, dynamic>);
      final model = TaskRequest.fromMap(map);
      AppLogger.i('[TaskRequestsService] accept ok id=${model.id}');
      return model;
    } on PostgrestException catch (e, st) {
      AppLogger.e('[TaskRequestsService] accept PostgrestException', e, st);
      rethrow;
    } catch (e, st) {
      AppLogger.e('[TaskRequestsService] accept Unknown error', e, st);
      rethrow;
    }
  }

  Future<TaskRequest> reject(String requestId) async {
    AppLogger.d('[TaskRequestsService] reject start requestId=$requestId');
    try {
      final res = await _client.rpc('reject_task_request', params: {
        'p_request_id': requestId,
      });

      final map = (res as Map<String, dynamic>);
      final model = TaskRequest.fromMap(map);
      AppLogger.i('[TaskRequestsService] reject ok id=${model.id}');
      return model;
    } on PostgrestException catch (e, st) {
      AppLogger.e('[TaskRequestsService] reject PostgrestException', e, st);
      rethrow;
    } catch (e, st) {
      AppLogger.e('[TaskRequestsService] reject Unknown error', e, st);
      rethrow;
    }
  }
}