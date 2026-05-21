/// Repository for role switching operations.
///
/// This repository encapsulates all role switch-related Supabase calls,
/// including the atomic RPC, session refresh, and JWT verification.
library;

import 'dart:convert';

import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/profile/models/role_switch_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for role switching operations.
class RoleSwitchRepository {
  RoleSwitchRepository(SupabaseClient client) : _client = client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  /// Atomically switches user role with race condition protection.
  ///
  /// Calls the `switch_active_role` RPC which:
  /// 1. Verifies the expected old role matches current (atomic guard)
  /// 2. Updates the profile if valid
  /// 3. Logs to audit_logs
  ///
  /// Returns [RoleSwitchResult] with success/error details.
  Future<RoleSwitchResult> switchRole({
    required String expectedOldRole,
    required String newRole,
  }) async {
    AppLogger.i(
      'role_switch_rpc_started',
      tag: 'RoleSwitchRepo',
      json: {'from': expectedOldRole, 'to': newRole},
    );

    try {
      final response = await _client.rpc<dynamic>(
        'switch_active_role',
        params: {'p_expected_old_role': expectedOldRole, 'p_new_role': newRole},
      );

      final result = RoleSwitchResult.fromJson(
        response as Map<String, dynamic>,
      );

      if (result.success) {
        AppLogger.i(
          'role_switch_rpc_success',
          tag: 'RoleSwitchRepo',
          json: {'new_role': result.newRole},
        );
      } else {
        AppLogger.w(
          'role_switch_rpc_failed: ${result.errorCode}',
          tag: 'RoleSwitchRepo',
          json: {'error': result.errorCode, 'message': result.message},
        );
      }

      return result;
    } on Exception catch (e, stackTrace) {
      AppLogger.e(
        'role_switch_rpc_exception',
        tag: 'RoleSwitchRepo',
        error: e,
        stackTrace: stackTrace,
      );
      return RoleSwitchResult(
        success: false,
        errorCode: 'exception',
        message: e.toString(),
      );
    }
  }

  /// Refreshes the session and returns success status.
  ///
  /// This should be called after a successful role switch to ensure
  /// the JWT token contains the updated role claim.
  Future<bool> refreshSession({int maxRetries = 3}) async {
    AppLogger.d('session_refresh_started', tag: 'RoleSwitchRepo');

    for (var i = 0; i < maxRetries; i++) {
      try {
        await _client.auth.refreshSession();
        AppLogger.i('session_refresh_success', tag: 'RoleSwitchRepo');
        return true;
      } on Exception catch (e) {
        AppLogger.w(
          'session_refresh_attempt_${i + 1}_failed',
          tag: 'RoleSwitchRepo',
          error: e,
        );
        if (i < maxRetries - 1) {
          await Future<void>.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      }
    }

    AppLogger.e(
      'session_refresh_failed_after_$maxRetries',
      tag: 'RoleSwitchRepo',
    );
    return false;
  }

  /// Verifies that the JWT token contains the expected role.
  ///
  /// This decodes the current access token and checks the app_metadata
  /// active_role claim against the expected value.
  bool verifyJwtRole(String expectedRole) {
    try {
      final jwt = _client.auth.currentSession?.accessToken;
      if (jwt == null) {
        AppLogger.w('verify_jwt_no_session', tag: 'RoleSwitchRepo');
        return false;
      }

      // Decode JWT payload (base64url encoded)
      final parts = jwt.split('.');
      if (parts.length != 3) {
        AppLogger.w('verify_jwt_invalid_format', tag: 'RoleSwitchRepo');
        return false;
      }

      // Normalize and decode base64url
      var payload = parts[1];
      // Add padding if needed
      final buffer = StringBuffer(payload);
      while (buffer.length % 4 != 0) {
        buffer.write('=');
      }
      payload = buffer.toString();
      // Convert base64url to base64
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      final decoded = utf8.decode(base64.decode(payload));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      final appMetadata = payloadMap['app_metadata'] as Map<String, dynamic>?;
      final jwtRole = appMetadata?['active_role'] as String?;
      final matches = jwtRole == expectedRole;

      AppLogger.d(
        'verify_jwt_result',
        tag: 'RoleSwitchRepo',
        json: {'expected': expectedRole, 'actual': jwtRole, 'matches': matches},
      );

      return matches;
    } on Exception catch (e, stackTrace) {
      AppLogger.e(
        'verify_jwt_exception',
        tag: 'RoleSwitchRepo',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Checks rate limit before attempting role switch.
  ///
  /// Returns true if user is under the rate limit (3 switches per minute).
  Future<bool> checkRateLimit() async {
    try {
      final response = await _client.rpc<dynamic>(
        'check_role_switch_rate_limit',
      );
      final allowed = response as bool? ?? false;

      AppLogger.d(
        'rate_limit_check',
        tag: 'RoleSwitchRepo',
        json: {'allowed': allowed},
      );

      return allowed;
    } on Exception catch (e) {
      AppLogger.e('rate_limit_check_failed', tag: 'RoleSwitchRepo', error: e);
      // Fail closed (deny) — do not allow role switch if rate limit cannot be verified
      return false;
    }
  }
}
