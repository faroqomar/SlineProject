import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/chat/services/message_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../fixtures/chat_fixtures.dart';

// --- Mocks & Fakes ---

// We extend Mock but explicitly override rpc so that mocktail's `when()` stubs
// can intercept it AND it always returns a valid non-null value.
class _MC extends Mock implements SupabaseClient {
  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    dynamic get = false,
  }) {
    return (super.noSuchMethod(
          Invocation.method(#rpc, [fn], {#params: params, #get: get}),
        ))
        as PostgrestFilterBuilder<T>;
  }
}

class _MA extends Mock implements GoTrueClient {}

/// A simple stub filterbuilder that holds onto a value and resolves it.
class _StubFB<T> extends Fake
    implements PostgrestFilterBuilder<T>, PostgrestTransformBuilder<T> {
  final Object? _data;
  _StubFB(this._data);

  Map<String, dynamic> _dataAsMap(String methodName) {
    if (_data is Map) {
      return Map<String, dynamic>.from(_data);
    }
    throw StateError(
      '$methodName expected stub data shaped as Map, got ${_data.runtimeType}',
    );
  }

  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) =>
      _StubFB<PostgrestList>(_data);
  @override
  PostgrestFilterBuilder<T> eq(String column, dynamic value) => this;
  @override
  PostgrestFilterBuilder<T> or(String filters, {String? referencedTable}) =>
      this;
  @override
  PostgrestFilterBuilder<T> isFilter(String column, bool? value) => this;
  @override
  PostgrestFilterBuilder<T> lt(String column, dynamic value) => this;
  @override
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) => this;
  @override
  PostgrestTransformBuilder<T> limit(int count, {String? referencedTable}) =>
      this;
  @override
  PostgrestTransformBuilder<PostgrestMap> single() =>
      _StubFB<PostgrestMap>(_dataAsMap('single'));
  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      _StubFB<PostgrestMap?>(_data == null ? null : _dataAsMap('maybeSingle'));
  @override
  Future<T> timeout(
    Duration timeLimit, {
    FutureOr<T> Function()? onTimeout,
  }) async => _data as T;
  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) =>
      Future.value(_data as T).then(onValue, onError: onError);
}

// The generic typed version, used for from() stubs
class _FB<T> extends _StubFB<T> {
  _FB(super.data);
}

class _QB extends Fake implements SupabaseQueryBuilder {
  final dynamic next;
  _QB(this.next);

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      _StubFB<PostgrestList>(next is _StubFB ? next._data : next);
  @override
  PostgrestFilterBuilder<Map<String, dynamic>> insert(
    dynamic values, {
    bool defaultToNull = true,
  }) => _StubFB<Map<String, dynamic>>(next is _StubFB ? next._data : next);
  @override
  PostgrestFilterBuilder update(Map values) =>
      _StubFB<dynamic>(next is _StubFB ? next._data : next);
}

// --- Test Main ---

void main() {
  group('MessageService - Production Suite', () {
    late MessageService messageService;
    late _MC mockClient;
    late _MA mockAuth;

    setUpAll(() {
      registerFallbackValue(Uri.parse('https://test.com'));
      registerFallbackValue('');
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      mockClient = _MC();
      mockAuth = _MA();
      messageService = MessageService(mockClient);
    });

    void setupBasics() {
      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(null);
    }

    group('Feature Flag: start_direct_conversation_v1', () {
      test('Uses RPC start_direct_conversation_v1 when flag is true', () async {
        setupBasics();

        when(
          () => mockClient.from('app_config'),
        ).thenAnswer((_) => _QB(_FB<Map<String, dynamic>>({'value': 'true'})));
        when(
          () => mockClient.rpc(
            'start_direct_conversation_v1',
            params: any(named: 'params'),
          ),
        ).thenAnswer(
          (_) => _StubFB<Map<String, dynamic>>(newDirectConversationResponse),
        );

        final result = await messageService.createOrGetConversation(
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        expect(result.id, equals('550e8400-e29b-41d4-a716-446655440032'));
        verify(
          () => mockClient.rpc(
            'start_direct_conversation_v1',
            params: any(named: 'params'),
          ),
        ).called(1);
      });

      test('FALLBACK: Uses legacy query when flag is false', () async {
        setupBasics();

        when(
          () => mockClient.from('app_config'),
        ).thenAnswer((_) => _QB(_FB<Map<String, dynamic>>({'value': 'false'})));

        // The legacy path calls from('conversations') twice:
        // 1st call: check for existing DM -> return empty list.
        // 2nd call: insert new DM -> return the created conversation.
        var conversationsCallCount = 0;
        when(() => mockClient.from('conversations')).thenAnswer((_) {
          conversationsCallCount++;
          if (conversationsCallCount == 1) {
            // First call: no existing DM
            return _QB(
              _FB<List<Map<String, dynamic>>>(<Map<String, dynamic>>[]),
            );
          } else {
            // Second call: return the newly inserted conversation
            return _QB(_FB<Map<String, dynamic>>(existingDirectConversation));
          }
        });

        final result = await messageService.createOrGetConversation(
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        expect(result.id, equals(existingDirectConversation['id']));
        verifyNever(
          () => mockClient.rpc(
            'start_direct_conversation_v1',
            params: any(named: 'params'),
          ),
        );
      });
    });

    group('Message Pagination (Cursor-based)', () {
      test('loads initial page correctly', () async {
        setupBasics();

        final testMessages = <Map<String, dynamic>>[
          {
            'id': 'm1',
            'conversation_id': 'conv-id',
            'sender_id': 'user-1',
            'receiver_id': 'user-2',
            'content': 'msg 1',
            'message_type': 'text',
            'payload': <String, dynamic>{},
            'created_at': '2024-01-01T12:00:00Z',
          },
          {
            'id': 'm2',
            'conversation_id': 'conv-id',
            'sender_id': 'user-1',
            'receiver_id': 'user-2',
            'content': 'msg 2',
            'message_type': 'text',
            'payload': <String, dynamic>{},
            'created_at': '2024-01-01T11:59:00Z',
          },
        ];

        when(
          () => mockClient.from('messages'),
        ).thenAnswer((_) => _QB(_FB<List<Map<String, dynamic>>>(testMessages)));

        final messages = await messageService.getMessages('conv-id');

        expect(messages.length, 2);
        expect(messages.first.content, 'msg 1');
      });
    });

    group('Status Reporting', () {
      test('markSeen calls mark_conversation_seen RPC', () async {
        setupBasics();

        when(
          () => mockClient.rpc(
            'mark_conversation_seen',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => _StubFB<void>(null));

        await messageService.markSeen('conv-id');

        verify(
          () => mockClient.rpc(
            'mark_conversation_seen',
            params: any(named: 'params'),
          ),
        ).called(1);
      });

      test('markDelivered calls mark_conversation_delivered RPC', () async {
        setupBasics();

        when(
          () => mockClient.rpc(
            'mark_conversation_delivered',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => _StubFB<void>(null));

        await messageService.markDelivered('conv-id');

        verify(
          () => mockClient.rpc(
            'mark_conversation_delivered',
            params: any(named: 'params'),
          ),
        ).called(1);
      });
    });
  });
}
