import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/profile/models/role_switch_result.dart';
import '../../fixtures/profiles.dart';

void main() {
  group('RoleSwitchResult', () {
    test('fromJson parses success response correctly', () {
      final result = RoleSwitchResult.fromJson(roleSwitchSuccessResponse);
      
      expect(result.success, isTrue);
      expect(result.newRole, equals('freelancer'));
      expect(result.errorCode, isNull);
      expect(result.message, isNull);
    });

    test('fromJson parses stale_state error response', () {
      final result = RoleSwitchResult.fromJson(roleSwitchStaleStateResponse);
      
      expect(result.success, isFalse);
      expect(result.errorCode, equals('stale_state'));
      expect(result.message, isNotNull);
    });

    test('fromJson parses invalid_role error response', () {
      final result = RoleSwitchResult.fromJson(roleSwitchInvalidRoleResponse);
      
      expect(result.success, isFalse);
      expect(result.errorCode, equals('invalid_role'));
    });

    test('fromJson parses db_error error response', () {
      final result = RoleSwitchResult.fromJson(roleSwitchDbErrorResponse);
      
      expect(result.success, isFalse);
      expect(result.errorCode, equals('db_error'));
    });

    test('fromJson parses session_error error response', () {
      final result = RoleSwitchResult.fromJson(roleSwitchSessionErrorResponse);
      
      expect(result.success, isFalse);
      expect(result.errorCode, equals('session_error'));
    });

    test('fromJson handles missing fields gracefully', () {
      final result = RoleSwitchResult.fromJson({});
      
      expect(result.success, isFalse); // Defaults to false
      expect(result.newRole, isNull);
      expect(result.errorCode, isNull);
    });

    test('toJson serializes correctly', () {
      const result = RoleSwitchResult(
        success: true,
        newRole: 'freelancer',
        errorCode: null,
        message: 'Role switched successfully',
      );
      
      final json = result.toJson();
      
      expect(json['success'], isTrue);
      expect(json['new_role'], equals('freelancer'));
      expect(json['message'], equals('Role switched successfully'));
    });

    test('isSuccess returns true for successful result', () {
      const result = RoleSwitchResult(success: true, newRole: 'freelancer');
      expect(result.isSuccess, isTrue);
      expect(result.hasError, isFalse);
    });

    test('hasError returns true for failed result', () {
      const result = RoleSwitchResult(success: false, errorCode: 'error');
      expect(result.isSuccess, isFalse);
      expect(result.hasError, isTrue);
    });

    group('displayError', () {
      test('returns server message when available', () {
        const result = RoleSwitchResult(
          success: false,
          errorCode: 'custom',
          message: 'Custom server message',
        );
        expect(result.displayError, equals('Custom server message'));
      });

      test('returns stale_state fallback message', () {
        const result = RoleSwitchResult(
          success: false,
          errorCode: 'stale_state',
        );
        expect(result.displayError, contains('already changed'));
      });

      test('returns invalid_role fallback message', () {
        const result = RoleSwitchResult(
          success: false,
          errorCode: 'invalid_role',
        );
        expect(result.displayError, contains('Invalid role'));
      });

      test('returns db_error fallback message', () {
        const result = RoleSwitchResult(
          success: false,
          errorCode: 'db_error',
        );
        expect(result.displayError, contains('Database error'));
      });

      test('returns session_error fallback message', () {
        const result = RoleSwitchResult(
          success: false,
          errorCode: 'session_error',
        );
        expect(result.displayError, contains('Session expired'));
      });

      test('returns generic fallback for unknown error', () {
        const result = RoleSwitchResult(
          success: false,
          errorCode: 'unknown_error',
        );
        expect(result.displayError, contains('Failed to switch role'));
      });
    });

    test('toString returns expected format', () {
      const result = RoleSwitchResult(
        success: true,
        newRole: 'freelancer',
        errorCode: null,
      );
      expect(result.toString(), contains('RoleSwitchResult'));
      expect(result.toString(), contains('success: true'));
    });
  });

  group('RoleSwitchError constants', () {
    test('error codes are defined correctly', () {
      expect(RoleSwitchError.staleState, equals('stale_state'));
      expect(RoleSwitchError.invalidRole, equals('invalid_role'));
      expect(RoleSwitchError.dbError, equals('db_error'));
      expect(RoleSwitchError.sessionError, equals('session_error'));
      expect(RoleSwitchError.rateLimit, equals('rate_limit'));
      expect(RoleSwitchError.teardownError, equals('teardown_error'));
    });
  });
}
