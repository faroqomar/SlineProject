import 'package:flutter/foundation.dart';

import '../models/task_model.dart';
import 'task_filter_view_model.dart';

/// Shared discovery feed contract for Home, Tenders, and Booking discovery.
abstract class DiscoveryFeedViewModelContract implements Listenable {
  List<Task> get featuredTasks;
  bool get isLoading;
  bool get isLoadingMore;
  bool get hasMore;

  Future<void> loadFeaturedTasks({
    TaskFilterViewModel? filterController,
    String surface = 'home',
  });

  Future<void> loadMoreTasks({
    TaskFilterViewModel? filterController,
    String surface = 'home',
  });

  Future<void> refresh({
    required TaskFilterViewModel filterController,
    String surface = 'home',
  });
}
