// AuthViewModel: MVVM state holder for authentication flows
// Consolidates login/register/logout logic using AuthService and ChangeNotifier.

import 'package:flutter/material.dart';
import 'package:sline_app/app/main_navigation_screen.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/auth/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  bool _isLoading = false;

  AuthViewModel({AuthService? authService}) : _authService = authService ?? AuthService();

  bool get isLoading => _isLoading;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

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
        AppLogger.i("User profile loaded: ${profile['full_name']}");
      }
      if (!state.mounted) return;
      final messenger = ScaffoldMessenger.of(state.context);
      messenger.showSnackBar(const SnackBar(content: Text('Login successful')));
      Navigator.pushReplacement(
        state.context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      if (!state.mounted) return;
      final messenger = ScaffoldMessenger.of(state.context);
      messenger.showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required State state,
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setLoading(true);
    try {
      await _authService.signUp(email: email, password: password, fullName: fullName);
      if (!state.mounted) return;
      final messenger = ScaffoldMessenger.of(state.context);
      messenger.showSnackBar(const SnackBar(content: Text('Signup successful')));
      Navigator.pushReplacement(
        state.context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      if (!state.mounted) return;
      final messenger = ScaffoldMessenger.of(state.context);
      messenger.showSnackBar(SnackBar(content: Text('Signup failed: $e')));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout(BuildContext context) async {
    _setLoading(true);
    try {
      await _authService.signOut();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    } finally {
      _setLoading(false);
    }
  }
}
