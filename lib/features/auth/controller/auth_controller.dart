import 'package:flutter/material.dart';
import 'package:sline_app/features/home/ui/home_screen.dart';
import '../data/auth_repository.dart';

class AuthController {
  final AuthRepository _repo = AuthRepository();

  Future<void> login({
    required State state,
    required String email,
    required String password,
  }) async {
    try {
      await _repo.signIn(email: email, password: password);
      if (!state.mounted) return;
      final messenger = ScaffoldMessenger.of(state.context);
      messenger.showSnackBar(const SnackBar(content: Text("Login successful")));
      Navigator.pushReplacement(
        state.context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!state.mounted) return;
      final messenger = ScaffoldMessenger.of(state.context);
      messenger.showSnackBar(SnackBar(content: Text("Login failed: $e")));
    }
  }

  Future<void> register({
    required State state,
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      if (!state.mounted) return;
      final messenger = ScaffoldMessenger.of(state.context);
      messenger.showSnackBar(const SnackBar(content: Text("Signup successful")));
      Navigator.pushReplacement(
        state.context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!state.mounted) return;
      final messenger = ScaffoldMessenger.of(state.context);
      messenger.showSnackBar(SnackBar(content: Text("Signup failed: $e")));
    }
  }
}