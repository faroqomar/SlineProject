import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/services/deep_link_registry.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/chat/services/message_service.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';

/// Registers deep link handlers for chat-related entity types.
///
/// Handles: 'conversation', 'message' (messages route to their conversation).
void registerChatDeepLinks(DeepLinkRegistry registry) {
  const handler = _handleConversation;
  registry.register('conversation', handler);
  registry.register('message', handler);
}

Future<void> _handleConversation(
  BuildContext context,
  String entityId, {
  Map<String, dynamic>? metadata,
}) async {
  AppLogger.d(
    'Deep link: navigating to conversation $entityId',
    tag: 'DeepLink',
  );
  if (!context.mounted) return;
  _showLoading(context);

  try {
    final messageService = MessageService();
    final conversation = await messageService.getConversationById(entityId);
    if (!context.mounted) return;
    _hideLoading(context);

    if (context.mounted) {
      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: conversation),
          ),
        ),
      );
    }
  } on Exception catch (e) {
    AppLogger.e(
      'Deep link: failed to load conversation $entityId: $e',
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
