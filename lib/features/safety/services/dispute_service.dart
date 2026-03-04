import 'package:sline_app/core/services/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DisputeService {
  DisputeService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> submitDispute({
    required String taskId,
    required String reason,
    String? defendantId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('You must be signed in to submit a dispute.');
    }
    if (reason.trim().isEmpty) {
      throw Exception('Please provide a reason.');
    }

    await _client.from('disputes').insert({
      'task_id': taskId,
      'complainant_id': uid,
      if (defendantId != null && defendantId.isNotEmpty)
        'defendant_id': defendantId,
      'reason': reason.trim(),
      'status': 'open',
    });

    AppLogger.i(
      'Dispute submitted',
      tag: 'Safety',
      json: <String, dynamic>{'task_id': taskId},
    );
  }
}
