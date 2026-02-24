import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

PostgrestException _postgrestException({
  required String code,
  required String message,
}) {
  return PostgrestException(message: message, code: code);
}

AuthException _authException(String message, {String? statusCode}) {
  return AuthException(message, statusCode: statusCode);
}

StorageException _storageException(
  String message, {
  String? statusCode,
  String? error,
}) {
  return StorageException(message, statusCode: statusCode, error: error);
}

void main() {
  group('ErrorMapper T36-T39', () {
    test(
      'T36 ErrorMapper.map Postgrest 42501 returns session-expired message',
      () {
        final error = _postgrestException(
          code: '42501',
          message: 'new row violates row-level security policy',
        );

        final mapped = ErrorMapper.map(error);

        expect(mapped, 'Session expired. Please log in again.');
      },
    );

    test(
      'T37 ErrorMapper.map auth invalid credentials returns user-friendly auth message',
      () {
        final error = _authException(
          'Invalid login credentials',
          statusCode: '400',
        );

        final mapped = ErrorMapper.map(error);

        expect(mapped, 'Email or password is incorrect.');
      },
    );

    test(
      'T38 ErrorMapper.map storage payload-too-large returns size message',
      () {
        final error = _storageException(
          'Payload too large',
          statusCode: '413',
          error: 'EntityTooLarge',
        );

        final mapped = ErrorMapper.map(error);

        expect(mapped, 'File is too large. Please choose a smaller file.');
      },
    );

    test(
      'T39 ErrorMapper.isSessionExpired returns true for JWT-expired auth errors',
      () {
        final error = _authException('JWT expired');

        final isExpired = ErrorMapper.isSessionExpired(error);

        expect(isExpired, isTrue);
      },
    );
  });
}
