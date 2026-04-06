import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/services/deep_link_registry.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/direct_offers/view/direct_offer_details_screen.dart';

/// Registers deep link handlers for direct offer entity types.
///
/// Handles: 'direct_offer', 'directoffer'.
void registerDirectOfferDeepLinks(DeepLinkRegistry registry) {
  const handler = _handleDirectOffer;
  registry.register('direct_offer', handler);
  registry.register('directoffer', handler);
}

Future<void> _handleDirectOffer(
  BuildContext context,
  String entityId, {
  Map<String, dynamic>? metadata,
}) async {
  AppLogger.d(
    'Deep link: navigating to direct_offer $entityId',
    tag: 'DeepLink',
  );
  if (!context.mounted) return;
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
}
