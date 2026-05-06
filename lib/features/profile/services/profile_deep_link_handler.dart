import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/navigation/main_nav_destinations.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/core/services/deep_link_registry.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/profile/view/public_profile_screen.dart';

/// Registers deep link handlers for profile entity types.
///
/// Handles: 'profile' (own profile tab), 'user' (public profile screen).
void registerProfileDeepLinks(DeepLinkRegistry registry) {
  registry.register('profile', _handleProfile);
  registry.register('user', _handleUserProfile);
}

Future<void> _handleProfile(
  BuildContext context,
  String entityId, {
  Map<String, dynamic>? metadata,
}) async {
  AppLogger.d('Deep link: navigating to profile $entityId', tag: 'DeepLink');
  // Profile is selected through the visible-nav contract so removed tabs do
  // not leave deep links pointing at stale positions.
  if (!context.mounted) return;
  Navigator.popUntil(context, (route) => route.isFirst);
  if (context.mounted) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.setCurrentIndex(MainNavDestinations.profile);
  }
}

Future<void> _handleUserProfile(
  BuildContext context,
  String entityId, {
  Map<String, dynamic>? metadata,
}) async {
  AppLogger.d(
    'Deep link: navigating to user profile $entityId',
    tag: 'DeepLink',
  );
  if (!context.mounted) return;
  unawaited(
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: entityId)),
    ),
  );
}
