import 'package:sline_app/core/services/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registers FCM/APNs device token in user_devices for push delivery.
/// Plan: .TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md
/// When [fcmToken] is null or empty, skips upsert (no-op) and logs once.
class PushDeviceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tag = 'NotificationRouting';

  /// Upserts device row for current user. Call on login, resume, and token refresh.
  /// [fcmToken] null or empty => no-op (no token in logs).
  /// [platform] must be 'ios' or 'android' per contract.
  Future<void> registerDevice({
    required String? fcmToken,
    required String platform,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.d('registerDevice: no session, skipping', tag: _tag);
      return;
    }
    if (fcmToken == null || fcmToken.isEmpty) {
      AppLogger.d(
        'registerDevice: no token provided, skipping (add firebase_messaging for FCM)',
        tag: _tag,
      );
      return;
    }
    final normalizedPlatform = platform.toLowerCase() == 'ios'
        ? 'ios'
        : 'android';
    try {
      AppLogger.d(
        'registerDevice: upserting for platform=$normalizedPlatform',
        tag: _tag,
      );
      await _supabase.from('user_devices').upsert({
        'user_id': userId,
        'fcm_token': fcmToken,
        'platform': normalizedPlatform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,platform');
      AppLogger.i('registerDevice: success', tag: _tag);
    } catch (e, stack) {
      AppLogger.e(
        'registerDevice: failed',
        error: e,
        stackTrace: stack,
        tag: _tag,
      );
      rethrow;
    }
  }
}
