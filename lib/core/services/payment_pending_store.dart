import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PendingPaymentContext {
  const PendingPaymentContext({
    required this.bookingId,
    required this.provider,
    required this.startedAt,
    required this.entityType,
    required this.callbackHosts,
    this.correlationId,
  });

  final String bookingId;
  final String? correlationId;
  final String provider;
  final DateTime startedAt;
  final String entityType;
  final Set<String> callbackHosts;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'booking_id': bookingId,
      'correlation_id': correlationId,
      'provider': provider,
      'started_at': startedAt.toUtc().toIso8601String(),
      'entity_type': entityType,
      'callback_hosts': callbackHosts.toList(),
    };
  }

  factory PendingPaymentContext.fromJson(Map<String, dynamic> json) {
    return PendingPaymentContext(
      bookingId: json['booking_id'] as String,
      correlationId: json['correlation_id'] as String?,
      provider: json['provider'] as String? ?? 'unknown',
      startedAt:
          DateTime.tryParse(json['started_at'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      entityType: json['entity_type'] as String? ?? 'booking',
      callbackHosts: Set<String>.from(
        (json['callback_hosts'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>(),
      ),
    );
  }
}

class PaymentPendingStore {
  PaymentPendingStore(this._prefs);

  static const String _pendingPaymentKey = 'pending_payment_context';

  final SharedPreferences _prefs;

  Future<void> save(PendingPaymentContext context) async {
    await _prefs.setString(_pendingPaymentKey, jsonEncode(context.toJson()));
  }

  PendingPaymentContext? load() {
    final encoded = _prefs.getString(_pendingPaymentKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return PendingPaymentContext.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_pendingPaymentKey);
  }
}
