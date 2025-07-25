import 'package:flutter/material.dart';
import 'package:sline_app/app/main_navigation_screen.dart';
import '../services/auth_service.dart';

/// Controller for managing authentication logic
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Login user with email and password
  Future<void> login({
    required State state,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _authService.signIn(email: email, password: password);
      final profile = await _authService.getCurrentUserProfile();
      if (profile != null) {
        debugPrint("User profile loaded: ${profile['full_name']}");
      }
      if (!state.mounted) return;
      final messenger = ScaffoldMessenger.of(state.context);
      messenger.showSnackBar(const SnackBar(content: Text("Login successful")));
      Navigator.pushReplacement(
        state.context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      if (!state.mounted) return;
      final messenger = ScaffoldMessenger.of(state.context);
      messenger.showSnackBar(SnackBar(content: Text("Login failed: $e")));
    } finally {
      _setLoading(false);
    }
  }

  /// Register new user
  Future<void> register({
    required State state,
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setLoading(true);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      if (!state.mounted) return;
      final messenger = ScaffoldMessenger.of(state.context);
      messenger.showSnackBar(const SnackBar(content: Text("Signup successful")));
      Navigator.pushReplacement(
        state.context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      if (!state.mounted) return;
      final messenger = ScaffoldMessenger.of(state.context);
      messenger.showSnackBar(SnackBar(content: Text("Signup failed: $e")));
    } finally {
      _setLoading(false);
    }
  }
}
