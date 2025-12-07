import 'package:flutter/material.dart';

/// A [ChangeNotifier] that manages the current theme mode (light, dark, or system).
///
/// This provider allows the application to switch between different theme modes
/// and notifies its listeners (e.g., [MaterialApp]) about these changes.
class ThemeModeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  /// The currently selected theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Sets the theme mode to [newThemeMode] and notifies listeners.
  void setThemeMode(ThemeMode newThemeMode) {
    if (_themeMode != newThemeMode) {
      _themeMode = newThemeMode;
      notifyListeners();
    }
  }

  /// Toggles the theme mode between light and dark if not currently system.
  /// If it's system, it toggles between light/dark, then back to system.
  void toggleThemeMode() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // If system, toggle to light then dark
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}
