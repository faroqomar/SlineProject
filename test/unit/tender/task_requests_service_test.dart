/// Unit tests for TaskRequestsService
///
/// Tests price validation, error handling, exception types,
/// bid expiration, and helper methods.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import '../../helpers/mock_supabase.dart';
import '../../fixtures/task_request_factory.dart' as fixtures;

void main() {
  group('TaskRequestsService', () {
    late TaskRequestsService service;
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockUser.id).thenReturn('test-user-id');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      service = TaskRequestsService(client: mockClient);
    });

    // ============================================================================
    // Exception Tests
    // ============================================================================

    group('PriceMismatchException', () {
      test('formats user message correctly with dollars', () {
        final exception = PriceMismatchException(
          expectedCents: 45000,
          actualCents: 50000,
        );
        final message = exception.userMessage;
        expect(message, contains('\$450.00'));
        expect(message, contains('\$500.00'));
        expect(message, contains('freelancer updated their offer'));
      });

      test('formats user message with zero cents correctly', () {
        final exception = PriceMismatchException(
          expectedCents: 0,
          actualCents: 0,
        );
        expect(exception.userMessage, contains('\$0.00'));
      });

      test('toString includes cents values', () {
        final exception = PriceMismatchException(
          expectedCents: 12345,
          actualCents: 67890,
        );
        expect(exception.toString(), contains('12345'));
        expect(exception.toString(), contains('67890'));
      });
    });

    group('OfferAlreadyAcceptedException', () {
      test('has correct user message', () {
        final exception = OfferAlreadyAcceptedException();
        expect(exception.userMessage, 'This offer has already been accepted.');
      });

      test('toString includes already accepted', () {
        final exception = OfferAlreadyAcceptedException();
        expect(exception.toString(), contains('already been accepted'));
      });
    });

    // ============================================================================
    // isBidExpired Tests
    // ============================================================================

    group('isBidExpired', () {
      test('returns true for bid older than 24 hours', () {
        final oldBid = fixtures.createTaskRequest(
          id: 'old-bid',
          createdAt: DateTime.now().subtract(const Duration(hours: 25)),
        );
        expect(service.isBidExpired(oldBid), isTrue);
      });

      test('returns false for bid younger than 24 hours', () {
        final recentBid = fixtures.createTaskRequest(
          id: 'recent-bid',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        );
        expect(service.isBidExpired(recentBid), isFalse);
      });

      test('returns true for bid exactly at 24 hours (boundary)', () {
        final exactBid = fixtures.createTaskRequest(
          id: 'exact-bid',
          createdAt: DateTime.now().subtract(const Duration(hours: 24)),
        );
        expect(service.isBidExpired(exactBid), isTrue);
      });

      test('returns false for newly created bid', () {
        final newBid = fixtures.createTaskRequest(
          id: 'new-bid',
          createdAt: DateTime.now(),
        );
        expect(service.isBidExpired(newBid), isFalse);
      });

      test('handles fixture expired bid correctly', () {
        final expiredBid = fixtures.createExpiredBid(id: 'expired-bid');
        expect(service.isBidExpired(expiredBid), isTrue);
      });
    });

    // ============================================================================
    // BidReplaceabilityResult Tests
    // ============================================================================

    group('BidReplaceabilityResult', () {
      test('noExistingBid factory creates correct state', () {
        final result = BidReplaceabilityResult.noExistingBid();
        expect(result.isReplaceable, isTrue);
        expect(result.existingBid, isNull);
      });

      test('canReplace factory creates correct state', () {
        final bid = fixtures.createPendingBid(id: 'bid-123');
        final result = BidReplaceabilityResult.canReplace(bid);
        expect(result.isReplaceable, isTrue);
        expect(result.existingBid, isNotNull);
        expect(result.existingBid!.id, 'bid-123');
        expect(result.existingBid!.isPending, isTrue);
      });

      test('cannotReplace factory creates correct state', () {
        final bid = fixtures.createAcceptedBid(id: 'bid-123');
        final result = BidReplaceabilityResult.cannotReplace(bid);
        expect(result.isReplaceable, isFalse);
        expect(result.existingBid, isNotNull);
        expect(result.existingBid!.id, 'bid-123');
        expect(result.existingBid!.isAccepted, isTrue);
      });
    });

    // ============================================================================
    // Error Mapping Tests
    // ============================================================================

    group('mapErrorToUserMessage', () {
      test('maps PriceMismatchException correctly', () {
        final exception = PriceMismatchException(
          expectedCents: 45000,
          actualCents: 50000,
        );
        final message = service.mapErrorToUserMessage(exception);
        expect(message, contains('updated their offer'));
        expect(message, contains('\$450.00'));
        expect(message, contains('\$500.00'));
      });

      test('maps OfferAlreadyAcceptedException correctly', () {
        final exception = OfferAlreadyAcceptedException();
        final message = service.mapErrorToUserMessage(exception);
        expect(message, contains('already been accepted'));
      });

      test('maps unknown error to generic message', () {
        final message = service.mapErrorToUserMessage('random error');
        expect(message, contains('error occurred'));
      });
    });

    // ============================================================================
    // Exception Properties Tests
    // ============================================================================

    group('Exception properties', () {
      test('PriceMismatchException stores correct values', () {
        final exception = PriceMismatchException(
          expectedCents: 10000,
          actualCents: 15000,
        );
        expect(exception.expectedCents, 10000);
        expect(exception.actualCents, 15000);
      });

      test('OfferAlreadyAcceptedException is an Exception', () {
        final exception = OfferAlreadyAcceptedException();
        expect(exception, isA<Exception>());
        expect(exception.userMessage, isNotEmpty);
      });
    });

    // ============================================================================
    // Service Instantiation Tests
    // ============================================================================

    group('Service instantiation', () {
      test('can be created with mock client', () {
        final testService = TaskRequestsService(client: mockClient);
        expect(testService, isNotNull);
      });

      test('getBidExpirationTime returns null when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);
        final result = await service.getBidExpirationTime('bid-123');
        expect(result, isNull);
      });

      test('isBidReplaceable returns false when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);
        final result = await service.isBidReplaceable('task-123');
        expect(result.isReplaceable, isFalse);
        expect(result.existingBid, isNull);
      });
    });
  });
}
