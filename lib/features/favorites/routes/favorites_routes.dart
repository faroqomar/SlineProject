import 'package:flutter/material.dart';
import 'package:sline_app/features/favorites/view/favorites_screen.dart';

/// Simple route helper for Favorites feature.
class FavoritesRoutes {
  static const String routeName = '/favorites';

  static Route<dynamic> route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (_) => const FavoritesScreen(),
    );
  }
}
