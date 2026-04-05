import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/services/deep_link_registry.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';

/// Registers deep link handlers for task-related entity types.
///
/// Handles: 'task', 'offer' (offers link to the parent task details).
void registerTaskDeepLinks(DeepLinkRegistry registry) {
  const handler = _handleTask;
  registry.register('task', handler);
  registry.register('offer', handler);
}

Future<void> _handleTask(
  BuildContext context,
  String entityId, {
  Map<String, dynamic>? metadata,
}) async {
  AppLogger.d('Deep link: navigating to task $entityId', tag: 'DeepLink');
  if (!context.mounted) return;
  _showLoading(context);

  try {
    final taskService = TaskService();
    final task = await taskService.getTaskById(entityId);
    if (!context.mounted) return;
    _hideLoading(context);

    if (task != null && context.mounted) {
      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task not found')));
    }
  } on Exception catch (e) {
    AppLogger.e(
      'Deep link: failed to load task $entityId: $e',
      tag: 'DeepLink',
    );
    if (!context.mounted) return;
    _hideLoading(context);
    rethrow;
  }
}

void _showLoading(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}

void _hideLoading(BuildContext context) {
  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
