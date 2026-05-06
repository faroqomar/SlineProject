import 'package:flutter/foundation.dart';

/// Provides the visible bottom-navigation indexes used by the app shell.
///
/// The legacy `NavView` enum contains hidden and retired destinations, so this
/// contract keeps the user-visible four-tab shell aligned across navigation,
/// deep links, and tests.
@immutable
final class MainNavDestinations {
  const MainNavDestinations._();

  /// Home is the default landing tab and the fallback for stale indexes.
  static const int home = 0;

  /// Dashboard is the unified work and account command center.
  static const int dashboard = 1;

  /// Messages opens the conversation inbox.
  static const int messages = 2;

  /// Profile opens the signed-in user's own profile/settings surface.
  static const int profile = 3;

  /// Number of visible destinations in the bottom navigation shell.
  static const int visibleCount = 4;

  /// Returns true when [index] points at a visible bottom-navigation tab.
  static bool isVisibleIndex(int index) =>
      index >= home && index < visibleCount;
}
