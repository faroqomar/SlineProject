import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/features/chat/services/message_service.dart';
import '../fixtures/chat_fixtures.dart';

// --- Mocks & Fakes ---

// Supabase-1.11.11 declares rpc as non-generic:
//   PostgrestFilterBuilder rpc(String fn, {Map<String, dynamic>? params, FetchOptions options = const FetchOptions()})
//
// We extend Mock but explicitly override rpc so that mocktail's `when()` stubs
// can intercept it AND it always returns a valid non-null value.
class _MC extends Mock implements SupabaseClient {
  @override
  PostgrestFilterBuilder rpc(
    String fn, {
    Map<String, dynamic>? params,
    FetchOptions options = const FetchOptions(),
  }) {
    return (super.noSuchMethod(
          Invocation.method(#rpc, [fn], {#params: params, #options: options}),
        ))
        as PostgrestFilterBuilder;
  }
}

class _MA extends Mock implements GoTrueClient {}

/// A simple stub filterbuilder that holds onto a value and resolves it.
class _StubFB<T> extends Fake
    implements PostgrestFilterBuilder<T>, PostgrestTransformBuilder<T> {
  final T _data;
  _StubFB(T data) : _data = data;

  @override
  PostgrestFilterBuilder<R> select<R>([
    String columns = '*',
    FetchOptions options = const FetchOptions(),
  ]) => _StubFB<R>(_data as R);
  @override
  PostgrestFilterBuilder<T> eq(String column, dynamic value) => this;
  @override
  PostgrestFilterBuilder<T> or(String filters, {String? foreignTable}) => this;
  @override
  PostgrestFilterBuilder<T> is_(String column, dynamic value) => this;
  @override
  PostgrestFilterBuilder<T> lt(String column, dynamic value) => this;
  @override
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? foreignTable,
  }) => this;
  @override
  PostgrestTransformBuilder<T> limit(int count, {String? foreignTable}) => this;
  @override
  PostgrestTransformBuilder<T> single() => this;
  @override
  PostgrestTransformBuilder<T> maybeSingle() => this;
  @override
  Future<T> timeout(
    Duration timeLimit, {
    FutureOr<T> Function()? onTimeout,
  }) async => _data;
  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) =>
      Future.value(_data).then(onValue, onError: onError);
}

// The generic typed version, used for from() stubs
class _FB<T> extends _StubFB<T> {
  _FB(super.data);
}

class _QB extends Fake implements SupabaseQueryBuilder {
  final dynamic next;
  _QB(this.next);

  @override
  PostgrestFilterBuilder<R> select<R>([
    String columns = '*',
    FetchOptions options = const FetchOptions(),
  ]) => next;
  @override
  PostgrestFilterBuilder<Map<String, dynamic>> insert(
    dynamic values, {
    bool defaultToNull = true,
  }) => next;
  @override
  PostgrestFilterBuilder<Map<String, dynamic>> update(
    Map values, {
    FetchOptions options = const FetchOptions(),
  }) => next;
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
      registerFallbackValue(const FetchOptions());
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
            return _QB(_FB<List<Map<String, dynamic>>>([]));
          } else {
            // Second call: return the newly inserted conversation
            return _QB(_FB<Map<String, dynamic>>(existingDirectConversation));
          }
        });

        final result = await messageService.createOrGetConversation(
          user1Id: testClientId,
          user2Id: testFreelancerAId,
        );

        expect(result.id, equals('existing-direct-id'));
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
