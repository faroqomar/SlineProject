import 'package:flutter/foundation.dart';

bool isIgnoredFlutterWebEngineDisposeError(Object error) {
  if (!kIsWeb) {
    return false;
  }

  return error.toString().contains(
    'Trying to render a disposed EngineFlutterView',
  );
}
