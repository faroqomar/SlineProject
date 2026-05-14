import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

/// TaskFilterViewModel — MVVM state holder for filtering/searching tasks
class TaskFilterViewModel extends ChangeNotifier {
  static const String sortRelevance = 'Relevance';
  static const String sortNewest = 'Newest';
  static const String sortPriceLowToHigh = 'Price: Low to High';
  static const String sortPriceHighToLow = 'Price: High to Low';

  static const String deliveryUpTo24h = 'Up to 24h';
  static const String deliveryUpTo3Days = 'Up to 3 days';
  static const String deliveryUpTo7Days = 'Up to 7 days';
  static const String deliveryAnytime = 'Anytime';

  static const String sellerTopRated = 'Top Rated Seller';
  static const String sellerLevel2 = 'Level 2';
  static const String sellerLevel1 = 'Level 1';
  static const String sellerNew = 'New Seller';

  static const List<String> deliveryTimeOptions = <String>[
    deliveryUpTo24h,
    deliveryUpTo3Days,
    deliveryUpTo7Days,
    deliveryAnytime,
  ];

  static const List<String> sellerLevelOptions = <String>[
    sellerTopRated,
    sellerLevel2,
    sellerLevel1,
    sellerNew,
  ];

  static const Map<String, String> sellerLevelValueByLabel = <String, String>{
    sellerTopRated: 'top_rated',
    sellerLevel2: 'level_2',
    sellerLevel1: 'level_1',
    sellerNew: 'new_seller',
  };

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
  String _sortBy = sortRelevance;

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
    AppLogger.d(
      'home_search_updated',
      tag: 'HomeFilters',
      json: {
        'search_present': _searchQuery.trim().isNotEmpty,
        'query_length': _searchQuery.trim().length,
        'result_count': _filteredTasks.length,
      },
    );
  }

  /// Clears only the search query while preserving category and advanced filters.
  ///
  /// Tenders and other scoped discovery screens call this when their visible
  /// search field is reset so the controller text and ViewModel filter remain
  /// aligned.
  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    _applyFilters();
    AppLogger.d(
      'home_search_cleared',
      tag: 'HomeFilters',
      json: {'result_count': _filteredTasks.length},
    );
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    AppLogger.d(
      'home_category_changed',
      tag: 'HomeFilters',
      json: {
        'category_present': _selectedCategory.isNotEmpty,
        'selected_category': _selectedCategory.isEmpty
            ? 'all'
            : _selectedCategory,
        'result_count': _filteredTasks.length,
      },
    );
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
    if (deliveryTimes != null) {
      _deliveryTimes = List<String>.from(deliveryTimes);
    }
    if (sellerLevels != null) {
      _sellerLevels = List<String>.from(sellerLevels);
    }
    if (sortBy != null) {
      _sortBy = sortBy;
    }
    _applyFilters();
    _logFilterEvent('home_filters_applied');
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _minBudget = null;
    _maxBudget = null;
    _deliveryTimes = [];
    _sellerLevels = [];
    _sortBy = sortRelevance;
    _applyFilters();
    _logFilterEvent('home_filters_reset');
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

    // 4. Delivery Time
    if (_deliveryTimes.isNotEmpty) {
      final nowUtc = DateTime.now().toUtc();
      final selectedBuckets = _deliveryTimes.toSet();
      results = results
          .where(
            (task) => _matchesDeliveryBucket(task, nowUtc, selectedBuckets),
          )
          .toList();
    }

    // 5. Seller Level
    if (_sellerLevels.isNotEmpty) {
      final selectedLevels = _sellerLevels
          .map((label) => sellerLevelValueByLabel[label])
          .whereType<String>()
          .toSet();
      results = results.where((task) {
        if (task.isTender) return false;
        final authorSellerLevel = task.authorSellerLevel;
        if (authorSellerLevel == null || authorSellerLevel.isEmpty) {
          return false;
        }
        return selectedLevels.contains(authorSellerLevel);
      }).toList();
    }

    // 6. Sorting
    if (_sortBy == sortPriceLowToHigh) {
      results.sort((a, b) => a.budget.compareTo(b.budget));
    } else if (_sortBy == sortPriceHighToLow) {
      results.sort((a, b) => b.budget.compareTo(a.budget));
    } else if (_sortBy == sortNewest) {
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    // 'Relevance' keeps default order (or could be search rank)

    _filteredTasks = results;
    notifyListeners();
  }

  void _logFilterEvent(String eventName) {
    AppLogger.i(
      eventName,
      tag: 'HomeFilters',
      json: {
        'search_present': _searchQuery.trim().isNotEmpty,
        'category_present': _selectedCategory.isNotEmpty,
        'budget_min_present': _minBudget != null,
        'budget_max_present': _maxBudget != null,
        'delivery_bucket_count': _deliveryTimes.length,
        'seller_level_count': _sellerLevels.length,
        'sort_by': _sortBy,
        'result_count': _filteredTasks.length,
      },
    );
  }

  bool _matchesDeliveryBucket(
    Task task,
    DateTime nowUtc,
    Set<String> selectedBuckets,
  ) {
    final estimate = _resolveDeliveryEstimate(task, nowUtc);

    for (final bucket in selectedBuckets) {
      if (bucket == deliveryAnytime) {
        if (estimate == null ||
            estimate <= Duration.zero ||
            estimate > const Duration(days: 7)) {
          return true;
        }
        continue;
      }

      if (estimate == null || estimate <= Duration.zero) {
        continue;
      }

      if (bucket == deliveryUpTo24h && estimate <= const Duration(hours: 24)) {
        return true;
      }
      if (bucket == deliveryUpTo3Days &&
          estimate > const Duration(hours: 24) &&
          estimate <= const Duration(days: 3)) {
        return true;
      }
      if (bucket == deliveryUpTo7Days &&
          estimate > const Duration(days: 3) &&
          estimate <= const Duration(days: 7)) {
        return true;
      }
    }

    return false;
  }

  Duration? _resolveDeliveryEstimate(Task task, DateTime nowUtc) {
    final packageDays = _minimumPackageDeliveryDays(task.packages);
    if (task.isBooking && packageDays != null) {
      return Duration(days: packageDays);
    }

    final deadline = task.deadline?.toUtc();
    if (deadline != null) {
      return deadline.difference(nowUtc);
    }

    return null;
  }

  int? _minimumPackageDeliveryDays(Map<String, dynamic>? packages) {
    if (packages == null || packages.isEmpty) return null;

    int? minDays;
    for (final value in packages.values) {
      if (value is! Map) continue;
      final rawDelivery = value['delivery'];
      final parsedDelivery = _parsePositiveInt(rawDelivery);
      if (parsedDelivery == null) continue;
      if (minDays == null || parsedDelivery < minDays) {
        minDays = parsedDelivery;
      }
    }
    return minDays;
  }

  int? _parsePositiveInt(Object? raw) {
    if (raw is int) {
      return raw > 0 ? raw : null;
    }
    if (raw is num) {
      final value = raw.toInt();
      return value > 0 ? value : null;
    }
    if (raw is String) {
      final match = RegExp(r'^\d+$').firstMatch(raw.trim());
      if (match == null) return null;
      final value = int.tryParse(raw.trim());
      if (value == null || value <= 0) return null;
      return value;
    }
    return null;
  }
}
