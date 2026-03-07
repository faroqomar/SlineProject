import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/services/supabase_realtime_service.dart';

import '../../helpers/mock_supabase.dart';

/// Unit tests for SupabaseRealtimeService
///
/// Tests:
/// - T50 Service initialization and singleton pattern
/// - T53-T54 Unsubscribe functionality
/// - T56 Active channel tracking
/// - T57 Lifecycle management
/// - T58 Error resilience
/// - T59 Service structure verification
///
/// Note: Full integration tests for subscribe methods require a running
/// Supabase instance. These tests verify the service structure and API.
void main() {
  group('SupabaseRealtimeService T50-T59', () {
    late MockSupabaseClient mockClient;

    setUp(() {
      mockClient = MockSupabaseClient();
      SupabaseRealtimeService.reset();
    });

    tearDown(() {
      SupabaseRealtimeService.reset();
    });

    group('T50 Service initialization', () {
      test('T50a singleton factory returns same instance with same client', () {
        final instance1 = SupabaseRealtimeService(client: mockClient);
        final instance2 = SupabaseRealtimeService(client: mockClient);

        expect(identical(instance1, instance2), isTrue);
      });

      test('T50b reset clears singleton', () {
        final instance1 = SupabaseRealtimeService(client: mockClient);
        SupabaseRealtimeService.reset();
        final instance2 = SupabaseRealtimeService(client: mockClient);

        expect(identical(instance1, instance2), isFalse);
      });

      test('T50c initial state has no active channels', () {
        final service = SupabaseRealtimeService(client: mockClient);

        expect(service.activeChannelCount, equals(0));
        expect(service.activeChannels, isEmpty);
      });

      test('T50d accepts SupabaseClient in factory', () {
        final service = SupabaseRealtimeService(client: mockClient);

        expect(service, isA<SupabaseRealtimeService>());
      });
    });

    group('T51-T52 Subscription API verification', () {
      test('T51 subscribeToTaskRequests method exists', () {
        final service = SupabaseRealtimeService(client: mockClient);

        // Verify the method exists with correct signature
        expect(
          service.subscribeToTaskRequests,
          isA<Stream<Map<String, dynamic>> Function(String, {List<String>? events})>(),
        );
      });

      test('T52 subscribeToBidStatus method exists', () {
        final service = SupabaseRealtimeService(client: mockClient);

        // Verify the method exists with correct signature
        expect(
          service.subscribeToBidStatus,
          isA<Stream<Map<String, dynamic>> Function(String)>(),
        );
      });
    });

    group('T53-T54 Unsubscribe', () {
      test('T53 handles unsubscribe of non-existent channel gracefully', () {
        final service = SupabaseRealtimeService(client: mockClient);

        // Should not throw
        expect(() => service.unsubscribe('non-existent'), returnsNormally);
      });

      test('T54 unsubscribeAll clears channels', () {
        final service = SupabaseRealtimeService(client: mockClient);

        expect(service.activeChannelCount, equals(0));

        service.unsubscribeAll();

        expect(service.activeChannelCount, equals(0));
        expect(service.activeChannels, isEmpty);
      });
    });

    group('T56 Active channel tracking', () {
      test('T56a getters work correctly', () {
        final service = SupabaseRealtimeService(client: mockClient);

        expect(service.activeChannelCount, isA<int>());
        expect(service.activeChannels, isA<List<String>>());
      });
    });

    group('T57 Lifecycle', () {
      test('T57c reset during service lifecycle', () {
        final service = SupabaseRealtimeService(client: mockClient);

        expect(service.activeChannelCount, equals(0));

        SupabaseRealtimeService.reset();
        final newService = SupabaseRealtimeService(client: mockClient);

        expect(newService.activeChannelCount, equals(0));
      });
    });

    group('T58 Error resilience', () {
      test('T58a cleanup does not throw', () {
        final service = SupabaseRealtimeService(client: mockClient);

        expect(() => service.unsubscribeAll(), returnsNormally);
      });

      test('T58b service continues after errors', () {
        final service = SupabaseRealtimeService(client: mockClient);

        expect(() => service.unsubscribe('non-existent'), returnsNormally);
        expect(service.activeChannelCount, equals(0));
      });
    });

    group('T59 Service structure verification', () {
      test('T59a has required methods', () {
        final service = SupabaseRealtimeService(client: mockClient);

        // Verify all required methods exist
        expect(service.subscribeToTaskRequests, isA<Function>());
        expect(service.subscribeToBidStatus, isA<Function>());
        expect(service.unsubscribe, isA<Function>());
        expect(service.unsubscribeAll, isA<Function>());
        expect(SupabaseRealtimeService.reset, isA<Function>());
      });

      test('T59b has required properties', () {
        final service = SupabaseRealtimeService(client: mockClient);

        // Verify all required properties exist
        expect(service.activeChannelCount, isA<int>());
        expect(service.activeChannels, isA<List<String>>());
      });
    });
  });
}
