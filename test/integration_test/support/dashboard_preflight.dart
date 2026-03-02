import 'package:flutter/foundation.dart';

import 'dashboard_env.dart';

/// Preflight checks for dashboard integration tests.
/// Use to skip tests when required env/fixtures are missing.
class DashboardPreflight {
  static void log(String tag, String message) {
    debugPrint('[$tag] $message');
  }

  static String? _base() {
    if (!DashboardEnv.stagingConfirmed) {
      return 'Blocked: set IT_STAGING_CONFIRMED=true (staging config required).';
    }
    return null;
  }

  /// Role switch / overview / general dashboard: need login only.
  static String? roleSwitchAndOverview() {
    final base = _base();
    if (base != null) return base;
    if (DashboardEnv.loginEmail.isEmpty || DashboardEnv.loginPassword.isEmpty) {
      return 'Blocked: missing IT_LOGIN_EMAIL / IT_LOGIN_PASSWORD.';
    }
    return null;
  }

  /// Award/pay happy path: need login + optional task/request IDs and wallet.
  static String? awardPayHappyPath() {
    final base = roleSwitchAndOverview();
    if (base != null) return base;
    return null;
  }

  /// Booking accept/decline: need login + optional booking ID.
  static String? bookingAcceptDecline() {
    return roleSwitchAndOverview();
  }
}
