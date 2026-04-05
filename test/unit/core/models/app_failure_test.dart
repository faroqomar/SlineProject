import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/models/app_failure.dart';

void main() {
  group('AppFailure sealed hierarchy', () {
    test('NetworkFailure stores userMessage and debugMessage', () {
      const failure = NetworkFailure(
        'No internet connection',
        debugMessage: 'SocketException: OS Error',
      );
      expect(failure.userMessage, 'No internet connection');
      expect(failure.debugMessage, 'SocketException: OS Error');
      expect(failure.isTimeout, false);
    });

    test('NetworkFailure with timeout flag', () {
      const failure = NetworkFailure('Request timed out', isTimeout: true);
      expect(failure.isTimeout, true);
    });

    test('AuthFailure stores sessionExpired flag', () {
      const failure = AuthFailure('Session expired', sessionExpired: true);
      expect(failure.userMessage, 'Session expired');
      expect(failure.sessionExpired, true);
    });

    test('AuthFailure defaults sessionExpired to false', () {
      const failure = AuthFailure('Unauthorized');
      expect(failure.sessionExpired, false);
    });

    test('ValidationFailure stores field errors map', () {
      const failure = ValidationFailure(
        'Fix the following errors',
        fieldErrors: {'email': 'Invalid format', 'name': 'Required'},
      );
      expect(failure.fieldErrors, hasLength(2));
      expect(failure.fieldErrors['email'], 'Invalid format');
    });

    test('ValidationFailure defaults to empty fieldErrors', () {
      const failure = ValidationFailure('Invalid input');
      expect(failure.fieldErrors, isEmpty);
    });

    test('BusinessFailure stores domain code', () {
      const failure = BusinessFailure(
        'Booking already exists',
        code: 'BOOKING_ALREADY_EXISTS',
      );
      expect(failure.code, 'BOOKING_ALREADY_EXISTS');
      expect(failure.userMessage, 'Booking already exists');
    });

    test('pattern matching on AppFailure is exhaustive', () {
      const AppFailure failure = NetworkFailure('test');
      final result = switch (failure) {
        NetworkFailure() => 'network',
        AuthFailure() => 'auth',
        ValidationFailure() => 'validation',
        BusinessFailure() => 'business',
      };
      expect(result, 'network');
    });

    test('all subtypes are AppFailure', () {
      const failures = <AppFailure>[
        NetworkFailure('a'),
        AuthFailure('b'),
        ValidationFailure('c'),
        BusinessFailure('d', code: 'X'),
      ];
      expect(failures, hasLength(4));
      for (final f in failures) {
        expect(f, isA<AppFailure>());
        expect(f.userMessage, isNotEmpty);
      }
    });
  });
}
