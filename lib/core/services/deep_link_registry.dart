import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';

/// Callback signature for deep link handlers.
///
/// [context] is the current BuildContext for navigation.
/// [entityId] is the ID of the entity to navigate to.
/// [metadata] is optional extra data (e.g. conversationId for work items).
typedef DeepLinkHandler = Future<void> Function(
  BuildContext context,
  String entityId, {
  Map<String, dynamic>? metadata,
});

/// Registry that maps entity type strings to navigation handlers.
///
/// Feature modules register their handlers at app startup (in main.dart).
/// DeepLinkService delegates navigation to this registry, keeping core free
/// of feature-layer imports.
class DeepLinkRegistry {
  final Map<String, DeepLinkHandler> _handlers = {};

  /// Register a [handler] for the given [entityType] (case-insensitive).
  ///
  /// Throws [StateError] if a handler is already registered for [entityType]
  /// to prevent accidental overwrites.
  void register(String entityType, DeepLinkHandler handler) {
    final key = entityType.toLowerCase();
    if (_handlers.containsKey(key)) {
      throw StateError(
        'Handler already registered for entity type: $key. '
        'Unregister it first or use a different key.',
      );
    }
    _handlers[key] = handler;
    AppLogger.d('Registered handler for: $key', tag: 'DeepLinkRegistry');
  }

  /// Dispatch navigation for [entityType] to its registered handler.
  ///
  /// Returns `true` if a handler was found and invoked, `false` otherwise.
  Future<bool> handle(
    BuildContext context,
    String entityType,
    String entityId, {
    Map<String, dynamic>? metadata,
  }) async {
    final key = entityType.toLowerCase();
    final handler = _handlers[key];
    if (handler == null) {
      AppLogger.w(
        'No handler registered for entity type: $key',
        tag: 'DeepLinkRegistry',
      );
      return false;
    }
    await handler(context, entityId, metadata: metadata);
    return true;
  }

  /// Whether a handler is registered for [entityType].
  bool canHandle(String entityType) {
    return _handlers.containsKey(entityType.toLowerCase());
  }

  /// All registered entity type keys (lowercase).
  Iterable<String> get registeredTypes => _handlers.keys;
}
