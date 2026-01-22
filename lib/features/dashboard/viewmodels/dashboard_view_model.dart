import 'package:flutter/foundation.dart';
import '../models/dashboard_enums.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel() {
    // Default to overview tab
    _currentTab = DashboardTab.overview;
    // Default role
    _currentRole = UserRole.freelancer;
    _loadData();
  }

  UserRole _currentRole = UserRole.freelancer;
  UserRole get currentRole => _currentRole;

  DashboardTab _currentTab = DashboardTab.overview;
  DashboardTab get currentTab => _currentTab;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Data Holders
  // Counters, Lists, etc will be added in subsequent phases

  void setRole(UserRole role) {
    if (_currentRole == role) return;
    _currentRole = role;
    notifyListeners();
    _loadData();
  }

  void setTab(int index) {
    final tab = DashboardTab.values[index];
    if (_currentTab == tab) return;
    _currentTab = tab;
    notifyListeners();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    // Simulate fetch
    await Future.delayed(const Duration(milliseconds: 300));

    _isLoading = false;
    notifyListeners();
  }
}
