import 'package:flutter/material.dart';
import '../models/task_model.dart';

/// Controller to manage search and filter operations on tasks
class TaskFilterController extends ChangeNotifier {
  final List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];

  /// Current filtered list of tasks
  List<Task> get filteredTasks => List.unmodifiable(_filteredTasks);

  /// Load initial tasks from HomeController or service
  void setTasks(List<Task> tasks) {
    _allTasks.clear();
    _allTasks.addAll(tasks);
    _filteredTasks = List.from(_allTasks);
    notifyListeners();
  }

  /// Search tasks by query in title or description
  void searchTasks(String query) {
    if (query.isEmpty) {
      _filteredTasks = List.from(_allTasks);
    } else {
      _filteredTasks = _allTasks
          .where((task) =>
              task.title.toLowerCase().contains(query.toLowerCase()) ||
              task.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  /// Filter tasks by category
  void filterByCategory(String category) {
    if (category.isEmpty) {
      _filteredTasks = List.from(_allTasks);
    } else {
      _filteredTasks =
          _allTasks.where((task) => task.category == category).toList();
    }
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _filteredTasks = List.from(_allTasks);
    notifyListeners();
  }
}
