import 'package:flutter/foundation.dart';

import 't61_t70_env.dart';

class T61T70Preflight {
  static void log(String tag, String message) {
    debugPrint('[$tag] $message');
  }

  static String? _base() {
    if (!T61T70Env.stagingConfirmed) {
      return 'Blocked: set --dart-define=IT_STAGING_CONFIRMED=true after '
          'confirming the hardcoded Supabase config targets staging.';
    }
    return null;
  }

  static String? t64() {
    return _base();
  }

  static String? t65() {
    final base = t64();
    if (base != null) return base;
    if (T61T70Env.loginEmail.isEmpty || T61T70Env.loginPassword.isEmpty) {
      return 'Blocked: missing IT_LOGIN_EMAIL / IT_LOGIN_PASSWORD staging '
          'credentials for T65 login happy path.';
    }
    return null;
  }

  static String? t66() {
    return t65();
  }

  static String? t67() {
    return t65();
  }

  static String? t68() {
    final base = t65();
    if (base != null) return base;
    return 'Blocked: T68 cannot be automated on current code path yet. '
        'PaymentCheckoutScreen requires QiCard web flow, and demo mode '
        '(USE_QICARD_PAYMENT=false) intentionally stops before booking '
        'confirmation. Add a default-preserving test seam or run a seeded '
        'post-booking verification variant.';
  }

  static String? t69() {
    return t65();
  }

  static String? t70() {
    return t65();
  }
}
