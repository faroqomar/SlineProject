/// Unit tests for [DisputeService] — submitDispute behavior.
///
/// Run: `flutter test test/unit/safety/dispute_service_test.dart`
/// Plan: PLAN_DisputeLifecycle_2026-03-08 (Phase 0 — Gate 0).
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/safety/services/dispute_service.dart';
import '../../helpers/mock_supabase.dart';

const String _logTag = 'dispute_service_test';

/// Holds the last RPC name and params captured in tests.
class _RpcCapture {
  String? lastRpcName;
  Map<String, dynamic>? lastRpcParams;
}

/// Awaitable stub for rpc() so that await client.rpc(...) completes.
class _StubRpcBuilder extends Fake implements PostgrestFilterBuilder<dynamic> {
  @override
  Future<R> then<R>(FutureOr<R> Function(dynamic) onValue, {Function? onError}) =>
      Future<dynamic>.value(null).then(onValue, onError: onError);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late _RpcCapture rpcCapture;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    rpcCapture = _RpcCapture();

    when(() => mockClient.auth).thenAnswer((_) => mockAuth);
    when(() => mockAuth.currentUser).thenAnswer((_) => mockUser);
    when(() => mockUser.id).thenAnswer((_) => 'user-123');
    when(() => mockClient.rpc(any(), params: any(named: 'params')))
        .thenAnswer((invocation) {
      rpcCapture.lastRpcName = invocation.positionalArguments[0] as String;
      rpcCapture.lastRpcParams = invocation.namedArguments[#params] as Map<String, dynamic>?;
      return _StubRpcBuilder();
    });

    AppLogger.d('DisputeService test setUp', tag: _logTag);
  });

  group('submitDispute', () {
    test('calls rpc_submit_dispute with task_id and reason', () async {
      final service = DisputeService(client: mockClient);
      await service.submitDispute(
        taskId: 'task-1',
        reason: 'Work not as described',
        defendantId: 'defendant-1',
      );

      expect(rpcCapture.lastRpcName, 'rpc_submit_dispute');
      expect(rpcCapture.lastRpcParams, isNotNull);
      final params = rpcCapture.lastRpcParams!;
      expect(params['p_task_id'], 'task-1');
      expect(params['p_direct_offer_id'], isNull);
      expect(params['p_reason'], 'Work not as described');
      expect(params['p_defendant_id'], 'defendant-1');
      AppLogger.d('submitDispute RPC params verified', tag: _logTag);
    });

    test('calls rpc_submit_dispute without defendant_id when not provided', () async {
      final service = DisputeService(client: mockClient);
      await service.submitDispute(
        taskId: 'task-2',
        reason: 'Late delivery',
      );

      expect(rpcCapture.lastRpcName, 'rpc_submit_dispute');
      expect(rpcCapture.lastRpcParams, isNotNull);
      final params = rpcCapture.lastRpcParams!;
      expect(params['p_task_id'], 'task-2');
      expect(params['p_reason'], 'Late delivery');
      expect(params.containsKey('p_defendant_id'), isTrue);
      expect(params['p_defendant_id'], isNull);
      AppLogger.d('submitDispute without defendant_id verified', tag: _logTag);
    });

    test('throws when reason is empty', () async {
      when(() => mockUser.id).thenReturn('user-123');
      final service = DisputeService(client: mockClient);

      expect(
        () => service.submitDispute(
          taskId: 'task-1',
          reason: '   ',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('reason'),
          ),
        ),
      );
      expect(rpcCapture.lastRpcParams, isNull);
      AppLogger.d('submitDispute empty reason threw as expected', tag: _logTag);
    });

    test('throws when not signed in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      final service = DisputeService(client: mockClient);

      expect(
        () => service.submitDispute(
          taskId: 'task-1',
          reason: 'Valid reason',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('signed in'),
          ),
        ),
      );
      expect(rpcCapture.lastRpcParams, isNull);
      AppLogger.d('submitDispute no user threw as expected', tag: _logTag);
    });
  });
}
