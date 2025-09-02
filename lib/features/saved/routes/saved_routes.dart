import 'package:flutter/material.dart';
import '../presentation/screens/saved_tasks_screen.dart';

class SavedRoutes {
  static const routeName = '/saved';

  static Route<dynamic> route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (_) => const SavedTasksScreen(),
    );
  }
}
