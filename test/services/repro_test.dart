import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  group('Repro', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
    });

    test('repro bad state', () {
      print('Starting stubbing...');
      when(() => mockClient.auth).thenReturn(mockAuth);
      print('Stubbing primary ok.');
      when(() => mockAuth.currentUser).thenReturn(null);
      print('Stubbing secondary ok.');

      expect(mockClient.auth, equals(mockAuth));
    });
  });
}
