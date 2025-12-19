/// What: ChangeNotifier that manages the bottom navigation tab index across the app.
/// Why: Centralizes navigation state so UI widgets can listen via Provider and stay in sync.
library;

import 'package:flutter/material.dart';

/// Provider for managing bottom navigation bar state
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  /// Current selected tab index
  int get currentIndex => _currentIndex;

  /// Set the current tab index and notify listeners
  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Reset to home tab
  void resetToHome() {
    setCurrentIndex(0);
  }
}
