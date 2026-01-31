import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/app_enums.dart';
import '../../../../core/services/logger_service.dart';
import '../services/search_service.dart';
import '../../tasks/models/task_model.dart';
import '../../profile/models/profile_model.dart';

class SearchViewModel extends ChangeNotifier {
  final SearchService _service;
  Timer? _debounceTimer;

  // State
  SearchTab _activeTab = SearchTab.findWork;
  String _query = '';
  bool _isLoading = false;
  String? _error;

  // Data
  List<Task> _tasks = [];
  List<ProfileModel> _profiles = [];

  // Getters
  SearchTab get activeTab => _activeTab;
  String get query => _query;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<ProfileModel> get profiles => List.unmodifiable(_profiles);

  bool get isTasksTab => _activeTab == SearchTab.findWork;

  SearchViewModel([SearchService? service])
    : _service = service ?? SearchService();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Switch between Find Work and Find Talent tabs
  void setTab(SearchTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;

    // If we have a query, re-run search for the new tab
    if (_query.isNotEmpty) {
      _performSearch(_query);
    } else {
      // Clear results if query is empty
      _tasks = [];
      _profiles = [];
      _error = null;
      notifyListeners();
    }
  }

  /// Update query and trigger debounced search
  void onSearchChanged(String newQuery) {
    if (_query == newQuery) return;
    _query = newQuery;

    _debounceTimer?.cancel();

    if (newQuery.trim().isEmpty) {
      _tasks = [];
      _profiles = [];
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(newQuery);
    });
  }

  Future<void> _performSearch(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_activeTab == SearchTab.findWork) {
        final results = await _service.searchTasks(query: query);
        _tasks = results;
      } else {
        final results = await _service.searchProfiles(query: query);
        _profiles = results;
      }
    } catch (e) {
      _error = 'Failed to search. Please try again.';
      AppLogger.e('Search error', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retry the last search
  void retry() {
    if (_query.isNotEmpty) {
      _performSearch(_query);
    }
  }
}
