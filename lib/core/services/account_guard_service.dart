import 'dart:convert';

import 'package:sline_app/core/models/account_guard_state.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads moderation and revocation flags from `profiles` and computes whether
/// the current session should be blocked.
class AccountGuardService {
  AccountGuardService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AccountGuardState> evaluateCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return AccountGuardState.unauthenticated;

    final row = await _client
        .from('profiles')
        .select(
          'account_status, moderation_reason, restriction_scope, force_logout_after',
        )
        .eq('id', user.id)
        .maybeSingle();

    final accountStatus =
        (row?['account_status'] as String?)?.toLowerCase() ?? 'active';
    final moderationReason = row?['moderation_reason'] as String?;
    final restrictionScope = row?['restriction_scope'] as String?;
    final forceLogoutAfterUtc = _parseUtc(row?['force_logout_after']);
    final sessionIssuedAtUtc = _extractSessionIssuedAtUtc(
      _client.auth.currentSession?.accessToken,
    );
    final isRevoked =
        forceLogoutAfterUtc != null &&
        sessionIssuedAtUtc != null &&
        forceLogoutAfterUtc.isAfter(sessionIssuedAtUtc);
    final isRestricted =
        accountStatus == 'suspended' || accountStatus == 'banned';

    return AccountGuardState(
      isAuthenticated: true,
      isRevoked: isRevoked,
      isRestricted: isRestricted,
      accountStatus: accountStatus,
      moderationReason: moderationReason,
      restrictionScope: restrictionScope,
      forceLogoutAfterUtc: forceLogoutAfterUtc,
      sessionIssuedAtUtc: sessionIssuedAtUtc,
    );
  }

  Future<bool> canPerformSensitiveAction() async {
    try {
      final guard = await evaluateCurrentUser();
      return guard.isAuthenticated && !guard.isRevoked && !guard.isRestricted;
    } on Exception catch (e, st) {
      AppLogger.e(
        'Account guard action check failed',
        tag: 'AccountGuard',
        error: e,
        stackTrace: st,
      );
      // Fail closed for sensitive actions.
      return false;
    }
  }

  DateTime? _parseUtc(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  DateTime? _extractSessionIssuedAtUtc(String? accessToken) {
    if (accessToken == null || accessToken.isEmpty) return null;
    try {
      final parts = accessToken.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(normalized)))
              as Map<String, dynamic>;
      final iat = payload['iat'];
      if (iat is int) {
        return DateTime.fromMillisecondsSinceEpoch(iat * 1000, isUtc: true);
      }
      if (iat is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          iat.toInt() * 1000,
          isUtc: true,
        );
      }
      return null;
    } on Exception catch (_) {
      return null;
    }
  }
}
