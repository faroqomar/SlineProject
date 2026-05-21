/// Pure-function helpers for parsing and normalising QiCard / edge-function
/// response payloads.
///
/// Extracted from [QiCardPaymentService] to keep the service file under the
/// 800-line budget. Every function here is stateless -- no SupabaseClient, no
/// DI, no side-effects.
library;

/// Safely cast a dynamic value to a typed map, or return null.
Map<String, dynamic>? asResponseMap(Object? data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

/// Build a loggable summary of an edge-function response without leaking
/// sensitive fields.
Map<String, dynamic> safePayloadSummary(Map<String, dynamic>? data) {
  final normalizedError = normalizeErrorValue(data?['error']);
  return <String, dynamic>{
    'keys': data?.keys.toList() ?? const <String>[],
    'booking_id': data?['booking_id'],
    'correlation_id': data?['correlation_id'],
    'request_correlation_id': data?['request_correlation_id'],
    'payment_status': data?['payment_status'],
    'recovery_result': data?['recovery_result'],
    'refund_result': data?['refund_result'],
    'error': normalizedError,
  };
}

/// Extract a top-level `error` field from the response map.
String? extractError(Map<String, dynamic>? data) {
  return normalizeErrorValue(data?['error']);
}

/// Extract a `code` / `message` pair from the response (edge-function style).
String? extractErrorFromPayload(Map<String, dynamic>? data) {
  if (data == null) return null;
  final msg = data['message'];
  final code = data['code'];
  if (msg is String && msg.isNotEmpty) {
    return code is String && code.isNotEmpty ? '$code: $msg' : msg;
  }
  if (code is String && code.isNotEmpty) return code;
  return null;
}

/// Normalise an error value that may be a plain String or a Map with `code` /
/// `message` keys.
String? normalizeErrorValue(Object? error) {
  if (error is String && error.isNotEmpty) return error;
  if (error is Map) {
    final message = error['message'];
    final code = error['code'];
    if (code is String && message is String && code.isNotEmpty) {
      return '$code: $message';
    }
    if (message is String && message.isNotEmpty) return message;
    if (code is String && code.isNotEmpty) return code;
  }
  return null;
}

/// Parse an ISO-8601 date string, returning null on failure.
DateTime? parseDateOrNull(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
