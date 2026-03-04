import 'package:sline_app/core/services/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  ReportService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> submitReport({
    required String entityType,
    required String entityId,
    required String reason,
    String? category,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('You must be signed in to submit a report.');
    }
    if (!{'task', 'user', 'chat'}.contains(entityType)) {
      throw Exception('Unsupported report target.');
    }
    if (reason.trim().isEmpty) {
      throw Exception('Please provide a reason.');
    }

    await _client.from('reports').insert({
      'reporter_user_id': uid,
      'entity_type': entityType,
      'entity_id': entityId,
      'reason': reason.trim(),
      if (category != null && category.isNotEmpty) 'category': category,
    });

    AppLogger.i(
      'User report submitted',
      tag: 'Safety',
      json: <String, dynamic>{'entity_type': entityType, 'entity_id': entityId},
    );
  }
}
