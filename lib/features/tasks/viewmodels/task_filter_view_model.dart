import 'package:flutter/foundation.dart';
import '../models/task_model.dart';

/// TaskFilterViewModel — MVVM state holder for filtering/searching tasks
class TaskFilterViewModel extends ChangeNotifier {
  final List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];

  // Basic Filters
  String _searchQuery = '';
  String _selectedCategory = '';

  // Advanced Filters
  double? _minBudget;
  double? _maxBudget;
  List<String> _deliveryTimes = [];
  List<String> _sellerLevels = [];
  String _sortBy = 'Relevance';

  List<Task> get filteredTasks => List.unmodifiable(_filteredTasks);
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Advanced Filter Getters
  double? get minBudget => _minBudget;
  double? get maxBudget => _maxBudget;
  List<String> get deliveryTimes => List.unmodifiable(_deliveryTimes);
  List<String> get sellerLevels => List.unmodifiable(_sellerLevels);
  String get sortBy => _sortBy;

  void setTasks(List<Task> tasks) {
    _allTasks
      ..clear()
      ..addAll(tasks);
    _applyFilters();
  }

  void searchTasks(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void applyAdvancedFilters({
    double? minBudget,
    double? maxBudget,
    List<String>? deliveryTimes,
    List<String>? sellerLevels,
    String? sortBy,
  }) {
    _minBudget = minBudget;
    _maxBudget = maxBudget;
    if (deliveryTimes != null) _deliveryTimes = deliveryTimes;
    if (sellerLevels != null) _sellerLevels = sellerLevels;
    if (sortBy != null) _sortBy = sortBy;
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _minBudget = null;
    _maxBudget = null;
    _deliveryTimes = [];
    _sellerLevels = [];
    _sortBy = 'Relevance';
    _applyFilters();
  }

  void _applyFilters() {
    var results = List<Task>.from(_allTasks);

    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      results = results
          .where(
            (task) =>
                task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                task.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // 2. Category
    if (_selectedCategory.isNotEmpty) {
      // Match category name (e.g., "Design") or category ID
      results = results
          .where(
            (task) =>
                task.category == _selectedCategory ||
                task.categoryName == _selectedCategory,
          )
          .toList();
    }

    // 3. Budget Range
    if (_minBudget != null) {
      results = results.where((task) => task.budget >= _minBudget!).toList();
    }
    if (_maxBudget != null) {
      results = results.where((task) => task.budget <= _maxBudget!).toList();
    }

    // 4. Delivery Time (Mock Logic - Task model needs deadline/duration parsing)
    if (_deliveryTimes.isNotEmpty) {
      // Placeholder: Filter logic would compare task.deadline or task.duration
      // For now, we assume all tasks match if any delivery time is selected
      // as the Task model doesn't strictly store "3 days" as a searchable integer yet.
    }

    // 5. Seller Level (Mock Logic)
    if (_sellerLevels.isNotEmpty) {
      // Placeholder: Logic would check task.userLevel or similar
    }

    // 6. Sorting
    if (_sortBy == 'Price: Low to High') {
      results.sort((a, b) => a.budget.compareTo(b.budget));
    } else if (_sortBy == 'Price: High to Low') {
      results.sort((a, b) => b.budget.compareTo(a.budget));
    } else if (_sortBy == 'Newest') {
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    // 'Relevance' keeps default order (or could be search rank)

    _filteredTasks = results;
    notifyListeners();
  }
}
