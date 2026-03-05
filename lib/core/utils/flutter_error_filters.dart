import 'package:flutter/foundation.dart';

bool isIgnoredFlutterWebEngineDisposeError(Object error) {
  if (!kIsWeb) {
    return false;
  }

  return error.toString().contains(
    'Trying to render a disposed EngineFlutterView',
  );
}

/// Realtime heartbeat can contain JS interop objects that jsonEncode cannot serialize on web.
bool isIgnoredRealtimeEncodeError(Object error) {
  return error.toString().contains('LegacyJavaScriptObject') ||
      (error.toString().contains('encodable') &&
          error.toString().contains('realtime'));
}

/// Realtime can emit malformed payloads (e.g. null or wrong shape) causing getEnrichedPayload to throw in the client.
bool isIgnoredRealtimePayloadError(Object error) {
  final s = error.toString();
  return (error is NoSuchMethodError && s.contains('payload')) ||
      (s.contains('getEnrichedPayload') && s.contains('non-function'));
}
