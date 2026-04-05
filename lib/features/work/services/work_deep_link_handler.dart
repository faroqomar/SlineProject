import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/deep_link_registry.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/direct_offers/view/direct_offer_details_screen.dart';
import 'package:sline_app/features/work/view/work_item_details_screen.dart';

/// Registers deep link handlers for work item entity types.
///
/// Handles: 'work_item'.
/// Also provides [handleWorkItemNavigation] for the dashboard work-item tap
/// (which needs conversationId passthrough and directOffer routing).
void registerWorkDeepLinks(DeepLinkRegistry registry) {
  registry.register('work_item', _handleWorkItem);
}

Future<void> _handleWorkItem(
  BuildContext context,
  String entityId, {
  Map<String, dynamic>? metadata,
}) async {
  AppLogger.d('Deep link: navigating to work_item $entityId', tag: 'DeepLink');
  if (!context.mounted) return;

  final type = metadata?['type']?.toString().toLowerCase() ?? 'task';

  if (type == 'directoffer') {
    final conversationId = metadata?['conversation_id']?.toString();
    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DirectOfferDetailsScreen(
            offerId: entityId,
            conversationId: conversationId,
          ),
        ),
      ),
    );
    return;
  }

  final workItemType =
      type == 'booking' ? WorkItemType.booking : WorkItemType.task;

  unawaited(
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkItemDetailsScreen(id: entityId, type: workItemType),
      ),
    ),
  );
}
