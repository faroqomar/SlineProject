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
