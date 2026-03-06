import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
  });

  group('AuthRepository getCurrentUserProfileWithRetry', () {
    test('returns null when currentUser is null', () async {
      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(null);

      final repo = AuthRepository(client: mockClient);
      final result = await repo.getCurrentUserProfileWithRetry(
        maxRetries: 2,
        retryDelay: Duration.zero,
      );

      expect(result, isNull);
    });
  });

  group('AuthRepository getCurrentUserProfile', () {
    test('returns null when currentUser is null', () async {
      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(null);

      final repo = AuthRepository(client: mockClient);
      final result = await repo.getCurrentUserProfile();

      expect(result, isNull);
    });
  });
}
