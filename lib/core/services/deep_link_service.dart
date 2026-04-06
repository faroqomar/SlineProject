import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/services/deep_link_registry.dart';
import 'package:sline_app/core/services/logger_service.dart';

/// Service to handle deep linking and routing from notifications/activity feed.
///
/// Navigation logic is delegated to [DeepLinkRegistry] handlers registered by
/// each feature module at app startup. This keeps core free of feature imports.
class DeepLinkService {
  final DeepLinkRegistry _registry;

  DeepLinkService({required DeepLinkRegistry registry}) : _registry = registry;

  /// All entity types the registry can currently handle.
  List<String> get supportedEntityTypes =>
      _registry.registeredTypes.toList(growable: false);

  /// Handle tap on a notification item.
  ///
  /// For task_request, routes using metadata: conversation_id first, else task_id.
  /// Callers extract primitives from the notification model before calling this.
  Future<void> handleNotification(
    BuildContext context, {
    required String? entityType,
    required String? entityId,
    Map<String, dynamic> metadata = const {},
  }) async {
    AppLogger.i(
      'handleNotification: entityType=$entityType id=$entityId',
      tag: 'DeepLink',
    );
    final type = entityType?.toLowerCase();
    if (type == 'task_request') {
      final convId = metadata['conversation_id']?.toString();
      final taskId = metadata['task_id']?.toString();
      if (convId != null && convId.isNotEmpty) {
        AppLogger.d(
          'task_request: routing to conversation $convId',
          tag: 'DeepLink',
        );
        await navigateToEntity(context, 'conversation', convId);
      } else if (taskId != null && taskId.isNotEmpty) {
        AppLogger.d('task_request: routing to task $taskId', tag: 'DeepLink');
        await navigateToEntity(context, 'task', taskId);
      } else {
        AppLogger.w(
          'task_request: no conversation_id or task_id in metadata',
          tag: 'DeepLink',
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open this notification.')),
        );
      }
      return;
    }
    await navigateToEntity(context, entityType, entityId);
  }

  /// Handle tap on an activity log item.
  ///
  /// Callers extract entityType and entityId from the activity model before
  /// calling this.
  Future<void> handleActivity(
    BuildContext context, {
    required String? entityType,
    required String? entityId,
  }) async {
    AppLogger.i(
      'Handling activity tap: $entityType - $entityId',
      tag: 'DeepLink',
    );
    await navigateToEntity(context, entityType, entityId);
  }

  /// Open the chat screen for a conversation (e.g. from direct offer details).
  Future<void> openConversation(
    BuildContext context,
    String conversationId,
  ) async {
    await navigateToEntity(context, 'conversation', conversationId);
  }

  /// Handle tap on a dashboard work item.
  ///
  /// Uses [type] as string ("task", "booking", or "directOffer") and [id].
  /// For direct offers, passes [conversationId] via metadata.
  Future<dynamic> handleWorkItem(
    BuildContext context,
    String type,
    String id, {
    String? conversationId,
  }) async {
    AppLogger.i('Handling work item tap: $type - $id', tag: 'DeepLink');
    if (!context.mounted) return;

    final typeLower = type.toLowerCase();

    // Direct offers and work items route through the registry with metadata.
    if (typeLower == 'directoffer') {
      final handled = await _registry.handle(
        context,
        'directoffer',
        id,
        metadata: {'conversation_id': conversationId},
      );
      if (handled) {
        AppLogger.i(
          'deep_link_routed entityType=$type id=$id',
          tag: 'DeepLink',
        );
      }
      return;
    }

    // Booking/task work items route through the work_item handler via
    // the registry, or fall back to the entity-type handler directly.
    if (_registry.canHandle('work_item')) {
      final handled = await _registry.handle(
        context,
        'work_item',
        id,
        metadata: {'type': typeLower, 'conversation_id': conversationId},
      );
      if (handled) {
        AppLogger.i(
          'deep_link_routed entityType=work_item($type) id=$id',
          tag: 'DeepLink',
        );
        return;
      }
    }

    // Fallback: route as plain entity type.
    if (!context.mounted) return;
    await navigateToEntity(context, typeLower, id);
  }

  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Centralized navigation logic based on entity type and ID.
  ///
  /// Delegates to the [DeepLinkRegistry] for all entity types.
  Future<void> navigateToEntity(
    BuildContext context,
    String? type,
    String? id,
  ) async {
    if (id == null || type == null) {
      AppLogger.w('Cannot navigate: ID or Type is null', tag: 'DeepLink');
      return;
    }

    if (!_uuidRegex.hasMatch(id)) {
      AppLogger.w('Invalid entity ID format: $id', tag: 'DeepLink');
      return;
    }

    try {
      final handled = await _registry.handle(context, type, id);
      if (handled) {
        AppLogger.i(
          'deep_link_routed entityType=$type id=$id',
          tag: 'DeepLink',
        );
      } else {
        AppLogger.w(
          'Notification route not supported: entityType=$type',
          tag: 'DeepLink',
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This item type is not supported.')),
        );
      }
    } on Exception catch (e) {
      AppLogger.e('Deep link navigation failed', error: e, tag: 'DeepLink');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open item. Please try again.')),
      );
    }
  }
}
