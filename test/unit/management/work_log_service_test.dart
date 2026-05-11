import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sline_app/features/management/models/work_log_scope.dart';
import 'package:sline_app/features/management/services/work_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('WorkLogService', () {
    test('getLogs applies entity id and entity type filters', () async {
      late Uri requestedUri;
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode([
              {
                'id': 'log-1',
                'author_id': 'user-1',
                'related_entity_id': 'entity-1',
                'related_entity_type': 'task',
                'content': 'First note',
                'is_private': false,
                'metadata': <String, dynamic>{},
                'created_at': '2026-03-01T10:00:00Z',
                'profiles': {'full_name': 'User One', 'avatar_url': null},
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );

      final service = WorkLogService(client);
      final logs = await service.getLogs(
        const WorkLogScope(entityId: 'entity-1', entityType: 'task'),
      );

      expect(logs, hasLength(1));
      expect(logs.single.relatedEntityType, 'task');
      expect(requestedUri.path, endsWith('/rest/v1/work_logs'));
      expect(requestedUri.queryParameters['related_entity_id'], 'eq.entity-1');
      expect(requestedUri.queryParameters['related_entity_type'], 'eq.task');
      expect(requestedUri.queryParameters['order'], contains('created_at.asc'));
    });
  });
}
