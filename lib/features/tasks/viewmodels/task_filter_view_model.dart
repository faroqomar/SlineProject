import 'package:flutter/foundation.dart';
import '../models/task_model.dart';

/// TaskFilterViewModel — MVVM state holder for filtering/searching tasks
class TaskFilterViewModel extends ChangeNotifier {
  final List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];

  List<Task> get filteredTasks => List.unmodifiable(_filteredTasks);

  void setTasks(List<Task> tasks) {
    _allTasks
      ..clear()
      ..addAll(tasks);
    _filteredTasks = List.from(_allTasks);
    notifyListeners();
  }

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

  void filterByCategory(String category) {
    if (category.isEmpty) {
      _filteredTasks = List.from(_allTasks);
    } else {
      _filteredTasks =
          _allTasks.where((task) => task.category == category).toList();
    }
    notifyListeners();
  }

  void clearFilters() {
    _filteredTasks = List.from(_allTasks);
    notifyListeners();
  }
}
